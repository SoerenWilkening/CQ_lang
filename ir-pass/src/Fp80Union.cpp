// Fp80Union.cpp — the x86_fp80 union-promotion pass (bd 3c6m.51; multi-block
// canonicalize + PromoteMemToReg since Inc 3). See Fp80Union.h for the idiom,
// the placement, and the §4 padding fence.
//
// PURE structural rewrite in two steps: (1) CANONICALIZE every provable union
// access to a full-width `x86_fp80` load/store on a fresh promotable alloca —
// an integer word load becomes `load x86_fp80` + `bitcast -> i80` + lshr/trunc/
// zext (padding read as 0), an integer field-insert store-back becomes
// `load x86_fp80` + `bitcast -> i80` + and-clear + zext/shl/or + `bitcast ->
// x86_fp80` + `store x86_fp80` (inserted bits landing at storage positions
// >= 80 are DROPPED into the modelled-zero padding) — then (2) hand the fresh
// alloca to LLVM's own PromoteMemToReg to build the SSA (merge phis are
// `phi x86_fp80`, never i80: the i80 extract/insert stays local around each
// access by construction). It emits STANDARD LLVM ops only (the extraction is
// byte-identical to LLVM's own SROA output for the within-value loads — proven
// against the -O2 fdiml IR), so it is not a bespoke lowering. Every gate is
// load-bearing: an off-pattern union is left untouched (falls to kMsgStore); a
// matched-but-unsound padding observation LOUD-declines (a wrong "padding = 0"
// fold would be a verify-clean silent miscompile — undefined bytes read as a
// definite value the real program never commits to).
//
// THE §4.1 FENCE (widened in Inc 3 from the every-user-masks rule to a per-bit
// padding-taint walk): modelling the padding bytes [10,16) as 0 is sound iff no
// OBSERVABLE value can differ between the model and any real padding content.
// The walk computes, for every SSA value reachable from a padding-straddling
// word load, the bitmask of positions where model and reality may diverge —
//   · a straddle load taints its bits at storage positions >= 80 (this also
//     covers written-then-read padding: a field-insert's dropped bits are
//     re-tainted at the next straddle read, whatever wrote them);
//   · `and` clears through a 0 mask bit; `or` clears through a 1; `xor` unions;
//   · add/sub/mul carry the taint upward from the lowest diverged bit;
//   · trunc/zext/sext/shl/lshr/ashr shift the mask (sext/ashr smear the sign);
//   · a field-insert lands the stored word's diverged bits at byte-offset
//     positions — landings >= 80 drop into padding, landings < 80 taint the
//     union CONTENT, which every later load of those bytes inherits;
//   · an OBSERVABLE — icmp/fcmp, a branch/switch condition, a call (incl.
//     cq_measure), a return, an fp80 reload of diverged content, a store
//     outside the candidate unions, any op the walk cannot model — with a
//     diverged bit LOUD-declines (kMsgFp80Padding).
// Poison-flag guard: an `add`/`sub`/`mul`/`shl` carrying nsw/nuw (or an `exact`
// shift/div) over a DIVERGED operand also declines — the model's zeros can flip
// signed-overflow poison where the real program is defined (e.g. a negative
// real operand whose diverged high bits read 0 turns a defined signed add into
// a model-side nsw overflow). Exactly three zero-monotone flags are accepted,
// each with proof: model operands equal the real ones except diverged bits
// read 0, so a model-side `or disjoint` overlap / `trunc nuw|nsw` dropped-bit
// / `zext nneg` negative-input violation implies the real one — model poison
// ⊆ real poison, a sound refinement. Every `exact` shift/division on a
// diverged operand DECLINES (over-safe; the zero-monotone argument would also
// cover `lshr exact`, but the code keeps the uniform decline).
//
// THE §4.4 PACK GATE (bd 3c6m.55 Lever A.1d): a second accepted idiom — the
// INTEGER-SEEDED reconstruct pack (floorl SET_LDBL_WORDS: no fp80 seed store;
// word inserts build the value from scratch; the fp80 reload is the terminal).
// Definedness is proven structurally by packDefinednessOk (P1: every reload's
// significant bits covered by DOMINATING inserts; P2: a word load's uncovered
// significant bits must die in a constant `and` mask in every user), while the
// §4.1 walk keeps owning divergence exactly as above. Packs always classify
// OPPORTUNISTIC — a walk failure drops them silently, never a new loud
// decline. Seed admissibility (fpSeedValueOk) itself is widened per bd 3c6m.55
// Lever A.1a/1b/1c: curated pure fp intrinsics (both modes), const-global fp
// loads + the pure-dataflow reload web (widened mode only).

#include "Fp80Union.h"

#include "LiteralIntegrity.h"  // removeUnreachableBlocksChecked (bd 7udx)

#include "IntrinsicLowering.h"  // isCuratedReversibleIntrinsic
#include "OpcodeSupport.h"      // abiWidthFromType
#include "PredMuxFlatten.h"     // isSpeculatablePureCallee (adia seed widening)
#include "TaintPropagation.h"   // TaintSet

#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/Analysis/CFG.h"  // isPotentiallyReachable
#include "llvm/Transforms/Utils/Local.h"  // ConstantFoldTerminator, removeUnreachableBlocks
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"

using namespace llvm;

namespace cq {

namespace {

// The x86_fp80 significant width. Its 80 bits occupy bytes [0,10) of a padded
// 16-byte (align-16) storage slot; bytes [10,16) — bits [80,128) — are undefined
// padding the promotion models as 0 (sound only under the §4.1 walk).
constexpr unsigned kFp80Bits = 80;

// The loud decline for a matched fp80 union whose padding can reach an
// observable (the central §4.1 fence). The negative fixtures mirror this string
// character-for-character (Rule 12): lowering_reject_fp80_union_padding.ll,
// lowering_reject_fp80_union_padding_{carry,insert}.ll.
constexpr char kMsgFp80Padding[] =
    "cq fp80 union: padding byte observed without a mask";

// The Inc-3 safety fence: an i80 value must never cross a control merge (there
// is no i80 controlled copy — the >64 fence). The promotion keeps i80 local by
// construction (the fresh alloca is x86_fp80-typed, so PromoteMemToReg only
// builds f80 phis); this diagnostic is the defensive invariant scan behind that
// construction. Fixture: lowering_reject_fp80_union_i80_merge.ll.
constexpr char kMsgFp80I80Merge[] =
    "cq fp80 union: i80 value crosses a control merge";

void diagnoseFp80(Instruction *I, const char *Msg) {
  I->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *I->getFunction(), Msg, I->getDebugLoc()));
}

// One integer word access on the union, with its constant byte offset.
struct WordLoad {
  LoadInst *Load;
  uint64_t ByteOff;
  unsigned Bits;
};
struct WordStore {
  StoreInst *Store;
  uint64_t ByteOff;
  unsigned Bits;
  bool Dead = false;  // no overlapping load ever reads it — erased, not packed.
};

// One structurally-proven candidate union alloca and its complete access set.
struct UnionCand {
  AllocaInst *A = nullptr;
  SmallVector<StoreInst *, 2> FpStores;  // x86_fp80 stores @0 (seed + re-seeds)
  SmallVector<LoadInst *, 3> FpLoads;    // x86_fp80 reloads @0 (`return u.e`)
  SmallVector<WordLoad, 4> Loads;        // iN loads at const byte offsets
  SmallVector<WordStore, 2> Inserts;     // iN store-backs (LIVE field-inserts OK)
  SmallVector<GetElementPtrInst *, 4> Geps;
  SmallVector<IntrinsicInst *, 4> Lifetimes;
  // bd 3c6m.55 Inc 1 (Lever A.1d): an integer-seeded SET_LDBL reconstruct pack
  // — NO fp80 seed store; the words build the value from scratch and the fp80
  // reload is the terminal (openlibm floorl `SET_LDBL(u, manl, manh, expsign)`
  // then `return u.e`). Gated by packDefinednessOk (P1/P2) instead of
  // accessesSeedDominated, and ALWAYS classified opportunistic.
  bool Reconstruct = false;
};

// ---------------------------------------------------------------------------
// Structural analysis (pure, pre-mutation)
// ---------------------------------------------------------------------------

// Analyze one alloca as a candidate x86_fp80 bit-pattern union. Returns false
// (leave byte-untouched → the existing kMsgStore decline for a tainted seed)
// on ANY off-pattern user: a call reading the address, ptrtoint, an icmp/phi/
// select on the pointer, a non-constant gep, the address stored as a VALUE, a
// volatile/atomic access, an access at an off-grid width or offset. Block
// structure is NOT constrained — PromoteMemToReg owns the SSA construction.
bool analyzeStructure(AllocaInst *A, const DataLayout &DL, UnionCand &C) {
  C.A = A;
  const unsigned PtrBits = DL.getIndexTypeSizeInBits(A->getType());
  SmallVector<Value *, 8> Work{A};
  SmallPtrSet<Value *, 16> Seen;
  auto offsetFromA = [&](Value *Ptr, uint64_t &Off) -> bool {
    APInt AP(PtrBits, 0);
    Value *Base = Ptr->stripAndAccumulateConstantOffsets(DL, AP,
                                                         /*AllowNonInbounds=*/true);
    if (Base != A || AP.isNegative() || AP.getActiveBits() > 63)
      return false;
    Off = AP.getZExtValue();
    return true;
  };
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        return false;  // a constexpr user of a stack slot — bail.
      if (auto *LI = dyn_cast<LoadInst>(I)) {
        if (!LI->isSimple())
          return false;
        uint64_t Off;
        if (!offsetFromA(LI->getPointerOperand(), Off))
          return false;
        if (LI->getType()->isX86_FP80Ty()) {
          if (Off != 0)
            return false;  // a misaligned fp80 read is not the idiom.
          C.FpLoads.push_back(LI);
          continue;
        }
        if (!LI->getType()->isIntegerTy())
          return false;
        unsigned Bits = LI->getType()->getIntegerBitWidth();
        // Only word widths the trunc/zext grid can extract (≤ 64, a shipped
        // int width). For a padding straddle the intermediate meaningful width
        // must ALSO be shipped (the `trunc i80 -> i<meaningful>` template).
        if (Bits > 64 || abiWidthFromType(LI->getType()).empty())
          return false;
        unsigned BitOff = static_cast<unsigned>(Off * 8);
        unsigned Meaningful =
            BitOff >= kFp80Bits ? 0 : std::min(Bits, kFp80Bits - BitOff);
        if (Meaningful != 0 && Meaningful != Bits &&
            abiWidthFromType(IntegerType::get(A->getContext(), Meaningful))
                .empty())
          return false;
        C.Loads.push_back({LI, Off, Bits});
      } else if (auto *SI = dyn_cast<StoreInst>(I)) {
        // The address must be the POINTER operand, never the stored VALUE (an
        // address escape), and the store must be simple (no volatile/atomic).
        if (SI->getValueOperand() == V || SI->getPointerOperand() != V ||
            !SI->isSimple())
          return false;
        uint64_t Off;
        if (!offsetFromA(SI->getPointerOperand(), Off))
          return false;
        Type *VT = SI->getValueOperand()->getType();
        if (VT->isX86_FP80Ty()) {
          if (Off != 0)
            return false;  // an fp80 store not at offset 0 is not the idiom.
          C.FpStores.push_back(SI);  // MULTIPLE fp stores OK (seed + re-seeds).
        } else if (VT->isIntegerTy()) {
          unsigned Bits = VT->getIntegerBitWidth();
          // The field-insert zero-extends the word to i80 — the source width
          // must be on the shipped zext grid ({i1..i64} -> i80).
          if (Bits > 64 || abiWidthFromType(VT).empty())
            return false;
          C.Inserts.push_back({SI, Off, Bits});
        } else {
          return false;  // storing a non-fp80/non-int (e.g. a vector).
        }
      } else if (auto *GEP = dyn_cast<GetElementPtrInst>(I)) {
        uint64_t Off;
        if (!offsetFromA(GEP, Off))  // rejects non-constant / aliasing geps.
          return false;
        C.Geps.push_back(GEP);
        if (Seen.insert(GEP).second)
          Work.push_back(GEP);
      } else if (auto *II = dyn_cast<IntrinsicInst>(I);
                 II && II->isLifetimeStartOrEnd()) {
        C.Lifetimes.push_back(II);
      } else {
        return false;  // any other user escapes the address.
      }
    }
  }
  // Two accepted idioms. (1) fp80-SEEDED: at least one full-width fp80 store —
  // every access is then value-defined via accessesSeedDominated. (2) Lever
  // A.1d integer-seeded RECONSTRUCT PACK: no fp80 store at all; word inserts
  // build the value from scratch and an fp80 reload is the terminal
  // (floorl/lroundl SET_LDBL_WORDS). The pack carries its own definedness
  // proof (packDefinednessOk P1/P2) in place of seed domination. An alloca
  // with neither shape (a pure integer scratch slot, or a read-only union
  // never written) is not the fp80 bit-pattern idiom.
  if (!C.FpStores.empty())
    return true;
  if (!C.FpLoads.empty() && !C.Inserts.empty()) {
    C.Reconstruct = true;
    return true;
  }
  return false;
}

// Blocks that sit on any CFG cycle (any non-trivial SCC, or a self-loop).
// Twin of PredMuxFlatten.cpp collectCycleBlocks (kept local — both live in
// anonymous namespaces; 6 lines, cross-referenced so they cannot drift apart
// silently). The Inc-3 accept surface is ACYCLIC: a union access inside a
// cycle would put the promoted value on a loop-carried path, which is Phase
// 7.3 territory (the 19 loop-gated ld80 cells) and — the Rule-13 clearance
// finding — makes any lexical-order deadness reasoning unsound. A candidate
// with a cyclic access is left byte-untouched (tainted seed → kMsgStore).
void collectCycleBlocks(Function &F, SmallPtrSetImpl<BasicBlock *> &OnCycle) {
  for (scc_iterator<Function *> It = scc_begin(&F); !It.isAtEnd(); ++It) {
    const std::vector<BasicBlock *> &SCC = *It;
    if (SCC.size() > 1 || It.hasCycle())
      OnCycle.insert(SCC.begin(), SCC.end());
  }
}

// The Inc-3 scope gate: every union access must live in an acyclic block that
// is REACHABLE from entry. scc_begin only visits reachable blocks, so an
// unreachable (possibly self-looping) block evades OnCycle — and unreachable
// accesses reach PromoteMemToReg with no defined reaching-store semantics.
// Dropping the candidate is free: unreachable code never executes.
bool accessesAcyclic(const UnionCand &C,
                     const SmallPtrSetImpl<BasicBlock *> &OnCycle,
                     const DominatorTree &DT) {
  auto Ok = [&](const Instruction *I) {
    return !OnCycle.count(I->getParent()) &&
           DT.isReachableFromEntry(I->getParent());
  };
  return llvm::all_of(C.FpStores, Ok) && llvm::all_of(C.FpLoads, Ok) &&
         llvm::all_of(C.Loads,
                      [&](const WordLoad &W) { return Ok(W.Load); }) &&
         llvm::all_of(C.Inserts,
                      [&](const WordStore &W) { return Ok(W.Store); });
}

// Every non-seed access must be DOMINATED by some fp80 store, so the promoted
// value is fully defined at every read/RMW point (this is what keeps the
// integer-first packs out and makes the mem2reg result undef-free).
bool accessesSeedDominated(const UnionCand &C, const DominatorTree &DT) {
  auto dominatedBySeed = [&](const Instruction *I) {
    for (const StoreInst *S : C.FpStores)
      if (S != I && DT.dominates(S, I))
        return true;
    return false;
  };
  for (const WordLoad &W : C.Loads)
    if (!dominatedBySeed(W.Load))
      return false;
  for (const WordStore &W : C.Inserts)
    if (!dominatedBySeed(W.Store))
      return false;
  for (const LoadInst *L : C.FpLoads)
    if (!dominatedBySeed(L))
      return false;
  return true;
}

// Lever A.1d — the §4.4 definedness proof for a RECONSTRUCT pack (the
// replacement for accessesSeedDominated, which packs cannot satisfy: there is
// no fp80 seed store). The fp80 reload observes ALL 80 significant bits, and a
// partially-written pack reaching it would read undefined bytes as a definite
// value — the silent-miscompile core this proof exists to fence. Two legs:
//
//   P1 (all-words-defined-before-reload): for EVERY fp80 reload, the
//   significant bits [0,80) must be fully covered by word inserts that
//   DOMINATE the reload (instruction-level dominance — every execution
//   reaching the reload has run every covering store). The model value the
//   promoted reload produces is then exactly the packed real value; the
//   monotone §4.1 walk independently catches any DIVERGED word landing in the
//   pack (an insert whose value carries padding taint marks ContentD and the
//   reload declines), so P1 only needs definedness, not divergence.
//
//   P2 (masked pre-load): a word LOAD of the pack may read significant bits
//   no dominating insert has defined (the floorl RMW pre-load of the
//   expsign word: `load i64 @8; and -65536` keeps only the would-be padding).
//   Real execution reads stack garbage there; the promoted model reads the
//   mem2reg reaching value (undef). Sound only if the bits can never be
//   observed: every USER of such a load must be an `and` with a constant mask
//   that zeroes EVERY uncovered significant bit — the divergence dies in the
//   mask (0 in both model and real), before any flag-carrying or observable
//   op. Anything else declines the pack (stays in memory, existing declines).
//   NOTE this refinement (`and undef, C == and garbage, C` on the masked
//   bits) relies on PromoteMemToReg materializing the never-stored pre-state
//   as UNDEF, not POISON (`and poison, C` would stay poison). True on the
//   MANDATORY LLVM 19 (mem2reg inserts UndefValue; CMake FATAL_ERRORs on any
//   other LLVM) — re-verify this if the toolchain floor ever moves.
//
// Bits at storage positions >= 80 are NOT P2's concern: those are the padding
// bytes the §4.1 walk already taints at every straddle read (always-on).
bool packDefinednessOk(const UnionCand &C, const DominatorTree &DT) {
  // P1 — every fp80 reload fully covered by dominating inserts.
  for (const LoadInst *L : C.FpLoads) {
    APInt Cov = APInt::getZero(kFp80Bits);
    for (const WordStore &S : C.Inserts) {
      unsigned Lo = static_cast<unsigned>(S.ByteOff * 8);
      if (Lo >= kFp80Bits || !DT.dominates(S.Store, L))
        continue;
      Cov.setBits(Lo, std::min(Lo + S.Bits, kFp80Bits));
    }
    if (!Cov.isAllOnes())
      return false;
  }
  // P2 — uncovered significant bits of any word load die in every user's mask.
  for (const WordLoad &W : C.Loads) {
    unsigned BitOff = static_cast<unsigned>(W.ByteOff * 8);
    if (BitOff >= kFp80Bits)
      continue;  // pure-padding read — straddle-tainted, the walk owns it.
    unsigned Sig = std::min(W.Bits, kFp80Bits - BitOff);  // significant window
    APInt Uncov = APInt::getBitsSet(W.Bits, 0, Sig);
    for (const WordStore &S : C.Inserts) {
      if (!DT.dominates(S.Store, W.Load))
        continue;
      unsigned SLo = static_cast<unsigned>(S.ByteOff * 8), SHi = SLo + S.Bits;
      // Clear the overlap of the insert's field with the load window, in the
      // loaded value's bit coordinates.
      for (unsigned i = 0; i < Sig; ++i)
        if (BitOff + i >= SLo && BitOff + i < SHi)
          Uncov.clearBit(i);
    }
    if (Uncov.isZero())
      continue;
    for (const User *U : W.Load->users()) {
      auto *BO = dyn_cast<BinaryOperator>(U);
      if (!BO || BO->getOpcode() != Instruction::And)
        return false;
      Value *Other = BO->getOperand(BO->getOperand(0) == W.Load ? 1 : 0);
      auto *CM = dyn_cast<ConstantInt>(Other);
      if (!CM || !(CM->getValue() & Uncov).isZero())
        return false;
    }
  }
  return true;
}

// DEAD field-insert detection (Inc-1 parity): a store-back that no load ever
// observes is ERASED rather than canonicalized into an RMW pack. A load
// OBSERVES the store iff execution can flow from the store to the load —
// tested with LLVM's own `isPotentiallyReachable` (conservative-TRUE on its
// walk limit, so uncertainty keeps the store LIVE = the safe direction).
// NEVER use lexical order here: the first Rule-13 clearance round CONFIRMED a
// verify-clean silent miscompile from a comesBefore-based test — a loop-body
// load lexically BEFORE the store reads the PREVIOUS iteration's store via the
// back-edge, so lexical deadness erased a live loop-carried RMW. (The acyclic
// access gate independently keeps such candidates out; this test is sound on
// its own regardless.) Sound both ways: the model drops a store no model-load
// can observe (real observation needs the same store→load path), and the
// store's padding-byte writes are covered by the walk's always-on straddle
// re-taint. This is what keeps fdiml's dead `mask_nbit_l` store-back out of
// the trace — and with it every shipped i80 literal inside the 64-bit faithful
// print range (the abi_codegen __int128 trace label truncates above 64 bits by
// design).
void markDeadInserts(UnionCand &C, const DominatorTree &DT) {
  for (WordStore &S : C.Inserts) {
    uint64_t SB = S.ByteOff, SE = S.ByteOff + (S.Bits + 7) / 8;
    auto liveAgainst = [&](const Instruction *L, uint64_t LB, uint64_t LE) {
      if (LB >= SE || SB >= LE)
        return false;  // disjoint ranges never observe the store.
      return isPotentiallyReachable(S.Store, L, /*ExclusionSet=*/nullptr, &DT);
    };
    bool Live = false;
    for (const WordLoad &W : C.Loads)
      if (liveAgainst(W.Load, W.ByteOff, W.ByteOff + (W.Bits + 7) / 8)) {
        Live = true;
        break;
      }
    if (!Live)
      for (const LoadInst *L : C.FpLoads)
        if (liveAgainst(L, 0, (kFp80Bits + 7) / 8)) {
          Live = true;
          break;
        }
    S.Dead = !Live;
  }
}

// bd 3c6m.55 Inc 1 (Lever A.1b): a scalar-fp load from READ-ONLY CONSTANT
// GLOBAL memory (the openlibm `__polevll` Horner coefficient tables `@P`/`@Q`)
// is a constant-rooted classical value — morally a `Constant` that LLVM merely
// cannot fold because the element index is dynamic (the loop-carried
// `phi ptr [@P,..],[gep i8 %p,16,..]`). The load's pointer must resolve —
// through gep (any classical indices) / phi / select, cycle-safe — ONLY to
// `GlobalVariable` roots that are `isConstant()` with a definitive initializer
// (immutable by LLVM semantics: no store can alias them, so no diverged union
// content and no re-interpreted bit pattern can ever flow through the load).
// A TAINTED such load (the 7.5 QROM read at a quantum index) short-circuits at
// the taint check above long before this leaf, so the QROM lowering path is
// untouched; volatile/atomic loads are excluded (`isSimple`) — the volatile
// const-global fold runs earlier and owns those.
bool isConstGlobalFpLoad(const LoadInst *L) {
  if (!L->isSimple() || !L->getType()->isFloatingPointTy())
    return false;
  SmallVector<const Value *, 8> Work{L->getPointerOperand()};
  SmallPtrSet<const Value *, 8> Seen;
  while (!Work.empty()) {
    const Value *P = Work.pop_back_val();
    if (!Seen.insert(P).second)
      continue;
    P = P->stripPointerCastsAndAliases();
    if (auto *GV = dyn_cast<GlobalVariable>(P)) {
      if (!GV->isConstant() || !GV->hasDefinitiveInitializer())
        return false;
      continue;
    }
    if (auto *GEP = dyn_cast<GEPOperator>(P)) {
      Work.push_back(GEP->getPointerOperand());
      continue;
    }
    if (auto *Phi = dyn_cast<PHINode>(P)) {
      for (const Value *In : Phi->incoming_values())
        Work.push_back(In);
      continue;
    }
    if (auto *Sel = dyn_cast<SelectInst>(P)) {
      Work.push_back(Sel->getTrueValue());
      Work.push_back(Sel->getFalseValue());
      continue;
    }
    return false;  // any other pointer producer — not provably constant memory.
  }
  return true;
}

// Whether an fp80-store VALUE is admissible: tainted (the theta-derived
// quantum cell), a Constant (the classical isnan(const) union — folds to dead
// code after promotion), or derived purely from scalar fp dataflow over fp80
// reloads of the function's candidate unions (the scalbnl re-seed
// `u.e *= 0x1p+128`: its `load x86_fp80` operand is NOT tainted pre-promotion
// because taint never flows through memory; the caller's re-propagate re-taints
// it post-promotion). A runtime-classical seed from an unknown call result is
// NOT the bit-pattern idiom — the candidate is dropped.
//
// bd vqlq widening (`AdmitArgDerived`): a seed derived from function ARGUMENTS
// (an Argument root, reached directly or through an int->fp `sitofp`/`uitofp`)
// is admissible as an OPPORTUNISTIC candidate — the Phase-6 clone-on-taint case
// (`int qpack(int a) { u.e = (long double)a; … }`): the original callee is
// untainted when this fixpoint runs (pre-specialization), yet must reach
// `detectSpecializations` in register form (scanBody admits no alloca/load/
// store), and the clone's seeded params re-taint the whole cone. Promoting an
// untainted union is fence-sound classically — the §4.1 walk is a pure
// value-flow bit-divergence analysis (taint-independent): every observable
// (return/call/compare/out-store) carrying a diverged bit refuses the
// promotion. The caller keeps opportunistic candidates SEPARATE: a walk
// failure drops them silently (today's outcome — the memory form rides the
// classical execution or the existing loud declines) instead of widening the
// loud kMsgFp80Padding surface.
bool fpSeedValueOk(Value *Root, TaintSet &taint,
                   const SmallPtrSetImpl<const LoadInst *> &CandFpLoads,
                   bool AdmitArgDerived, const Value **WhyNot = nullptr) {
  SmallVector<Value *, 8> Work{Root};
  SmallPtrSet<Value *, 16> Seen;
  auto fail = [&](const Value *V) {
    if (WhyNot)
      *WhyNot = V;
    return false;
  };
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    if (taint.Tainted.count(V) || isa<Constant>(V))
      continue;
    if (AdmitArgDerived && isa<Argument>(V))
      continue;  // vqlq: a function-parameter root (see above).
    if (auto *L = dyn_cast<LoadInst>(V)) {
      if (CandFpLoads.count(L))
        continue;
      // Lever A.1b (see isConstGlobalFpLoad above): a coefficient-table read
      // from immutable constant-global memory. Widened mode only — the strict
      // predicate stays byte-identical to the shipped rule, so a walk failure
      // on such a candidate drops it silently (today's outcome) instead of
      // widening the loud kMsgFp80Padding surface.
      if (AdmitArgDerived && isConstGlobalFpLoad(L))
        continue;
      return fail(V);
    }
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      return fail(V);  // an Argument (strict mode) or other non-instruction root.
    switch (I->getOpcode()) {
    case Instruction::SIToFP:
    case Instruction::UIToFP:
      // vqlq: the int->fp seed conversion (`(long double)a`). Widened mode
      // only — the strict predicate stays byte-identical to the shipped rule.
      if (!AdmitArgDerived)
        return fail(V);
      for (Value *Op : I->operands())
        Work.push_back(Op);
      break;
    case Instruction::FAdd:
    case Instruction::FSub:
    case Instruction::FMul:
    case Instruction::FDiv:
    case Instruction::FRem:
    case Instruction::FNeg:
    case Instruction::FPExt:
    case Instruction::FPTrunc:
    case Instruction::PHI:
    case Instruction::Select:
    case Instruction::Freeze:
      for (Value *Op : I->operands())
        Work.push_back(Op);
      break;
    case Instruction::Call:
      // bd 3c6m.55 Inc 1 (Lever A.1a): a curated pure fp intrinsic
      // (fmuladd/fma/sqrt/fabs/copysign/floor/…, the openlibm Horner/polynomial
      // reduction that feeds `u.e = fmuladd(x, c, c)`) is a transparent
      // fp-derivation op — a pure total producer of admissible operands is a
      // legitimate fp value, EXACTLY like the `FMul`/`FAdd` above (NOT an
      // arg-only widening like `sitofp`, so admitted in BOTH modes). Membership
      // is the exported `isCuratedReversibleIntrinsic` (accept-set = the
      // lowered-set: the same intrinsics `lowerOps` reversibilizes), so a
      // NON-curated call (a transcendental `@llvm.sin`, an opaque `@foo`, an
      // fp128/vector width) is NOT admitted and rides the existing seed-drop.
      // A trailing i1 immarg (abs/ctlz) is a Constant → short-circuits.
      if (auto *CI = dyn_cast<CallInst>(I)) {
        if (isCuratedReversibleIntrinsic(CI)) {
          for (Value *Op : CI->args())
            Work.push_back(Op);
          break;
        }
        // bd adia (3c6m.55 Lever C) (Lever C compose): in WIDENED mode only, a direct
        // call to a VISIBLE, acyclic, all-speculatable PURE body (the
        // pending-specialization callee class — the SAME `isSpeculatablePure-
        // Callee` proof PredMux's E4 speculates on, Rule 14) is a transparent
        // fp-derivation op: a pure total terminating function of its operands
        // (olm_expl's `px = olm_floorl(...)` seed cone at the plain -O1
        // floor, where floorl stays outlined). The proof only passes AFTER
        // the callee's own unions promoted (its body must be load/store-free)
        // — an earlier fixpoint round, so the cascade converges naturally.
        // Wide-admitted candidates classify OPPORTUNISTIC (strict predicate
        // byte-identical; walk failure = today's silent drop).
        //
        // bd 3c6m.14.1 (S3 of the pure-callee widening): that proof now admits
        // a body whose only off-grid instruction is an fp80 BIT-PATTERN compare
        // (`icmp i80` with one ConstantInt), so callees of the openlibm
        // `GET_LDBL_MAN`-test shape become transparent here and their unions
        // promote. This module makes an INDEPENDENT accept decision on the
        // shared proof — it is not a PredMux surface — so it carries its own
        // fixture (lowering_fp80_union_seed_purecall_i80cmp.ll, which measured
        // as a genuine red-green: the alloca survives on the pre-change plugin
        // and is gone after).
        //
        // *** TWO THINGS THAT ARE NOT TRUE OF THIS WIDENING, both written here
        // first and both falsified with a run by the Rule-13 seed-cone lens. ***
        // Keep them written down: the tempting summary is "it can only add a
        // promotion", and that summary is wrong in BOTH directions.
        //   (1) IT CAN CREATE A NEW LOUD DECLINE — just not a `kMsgFp80Padding`
        //       one. The §4.1 walk/opportunistic-drop argument below is sound as
        //       far as it goes, but a newly promoted union reaches the
        //       POST-promotion i80-phi scan, so a pre-existing i80 phi in the
        //       same function can now draw `kMsgFp80I80Merge` where the
        //       pre-change plugin exited 0.
        //   (2) IT CAN REMOVE A PROMOTION. A walk failure drops the WHOLE
        //       opportunistic class, so a walk-FAILING pure-callee-seeded
        //       candidate admitted only by this widening can drag down a
        //       walk-CLEAN arg-seeded (bd vqlq) sibling that promoted before.
        // Both directions are SAFE (a loud decline and a memory-form
        // over-decline respectively — never a silent miscompile), which is why
        // they are recorded rather than fixed here; but neither is pinned by a
        // fixture, and "opportunistic ⇒ invisible" must not be repeated as if it
        // were an invariant. What IS true is the narrow statement: a §4.1
        // PADDING violation on an opportunistic candidate drops the
        // opportunistic set and re-runs strict (below) rather than diagnosing.
        if (AdmitArgDerived && isSpeculatablePureCallee(CI->getCalledFunction())) {
          for (Value *Op : CI->args())
            Work.push_back(Op);
          break;
        }
      }
      return fail(V);
    default:
      // bd 3c6m.55 Inc 1 (Lever A.1c reload-web): in WIDENED mode only, any
      // pure dataflow op — binary arithmetic/logic, cast, compare — is
      // transparent. This is the post-promotion extract web of a SIBLING
      // union: once union A promotes (an earlier fixpoint round), union B's
      // seed cone reads A's exponent word through `bitcast f80->i80` +
      // `lshr/trunc/zext/and` + `icmp` feeding a `select` condition (the
      // openlibm expl k-scaling / ldexpl exponent tests). Each is a pure total
      // function of its operands, so admissibility reduces to the operands —
      // the SAME cleared argument as `FMul`/`fmuladd` (the seed gate is a
      // scope classifier; promotion never moves or duplicates the op; the
      // §4.1 walk owns padding soundness and is monotone-safe under a larger
      // candidate set). The STRICT predicate stays byte-identical: every
      // wide-admitted candidate classifies OPPORTUNISTIC, so a walk failure
      // drops it silently (today's outcome) — never a new loud decline.
      // Memory/control/call ops (load handled above, store/br/invoke/...) are
      // never BinaryOperator/CastInst/CmpInst, so they still fail here.
      if (AdmitArgDerived &&
          (isa<BinaryOperator>(I) || isa<CastInst>(I) || isa<CmpInst>(I))) {
        for (Value *Op : I->operands())
          Work.push_back(Op);
        break;
      }
      return fail(V);
    }
  }
  return true;
}

// ---------------------------------------------------------------------------
// The §4.1 padding-taint walk (pure, pre-mutation)
// ---------------------------------------------------------------------------

class PaddingWalk {
public:
  explicit PaddingWalk(ArrayRef<UnionCand> Cands) {
    for (const UnionCand &C : Cands) {
      for (const WordLoad &W : C.Loads)
        LoadAt[W.Load] = {C.A, W.ByteOff};
      for (const WordStore &W : C.Inserts) {
        if (W.Dead)
          DeadStores.insert(W.Store);  // erased, never lands — a walk no-op.
        else
          InsertAt[W.Store] = {C.A, W.ByteOff};
      }
      for (const LoadInst *L : C.FpLoads)
        ReloadOf[L] = C.A;
      for (const StoreInst *S : C.FpStores)
        FpSeeds.insert(S);
      LoadsOf[C.A].assign(C.Loads.begin(), C.Loads.end());
      for (LoadInst *L : C.FpLoads)
        FpLoadsOf[C.A].push_back(L);
    }
  }

  // Runs the forward fixpoint. Returns nullptr if the promotion is sound, else
  // the instruction where a diverged bit becomes observable / unmodellable.
  const Instruction *run() {
    for (auto &KV : LoadAt)
      enqueue(const_cast<LoadInst *>(KV.first));
    while (!WL.empty()) {
      Instruction *I = WL.pop_back_val();
      InQueue.erase(I);
      if (const Instruction *Bad = eval(I))
        return Bad;
    }
    return nullptr;
  }

private:
  DenseMap<const LoadInst *, std::pair<AllocaInst *, uint64_t>> LoadAt;
  DenseMap<const StoreInst *, std::pair<AllocaInst *, uint64_t>> InsertAt;
  DenseMap<const LoadInst *, AllocaInst *> ReloadOf;
  SmallPtrSet<const StoreInst *, 4> FpSeeds;
  SmallPtrSet<const StoreInst *, 4> DeadStores;
  DenseMap<const AllocaInst *, SmallVector<WordLoad, 4>> LoadsOf;
  DenseMap<const AllocaInst *, SmallVector<LoadInst *, 3>> FpLoadsOf;
  DenseMap<const AllocaInst *, APInt> ContentD;  // 80-bit content divergence
  DenseMap<const Value *, APInt> D;              // per-SSA-value divergence
  SmallVector<Instruction *, 16> WL;
  SmallPtrSet<Instruction *, 16> InQueue;

  void enqueue(Instruction *I) {
    if (InQueue.insert(I).second)
      WL.push_back(I);
  }

  APInt getD(const Value *V, unsigned W) const {
    auto It = D.find(V);
    if (It == D.end())
      return APInt::getZero(W);
    assert(It->second.getBitWidth() == W && "divergence width mismatch");
    return It->second;
  }

  // Monotone update; on growth, re-enqueue every instruction user.
  void setD(Value *V, const APInt &M) {
    auto It = D.find(V);
    if (It == D.end()) {
      if (M.isZero())
        return;
      D.try_emplace(V, M);
    } else {
      APInt Merged = It->second | M;
      if (Merged == It->second)
        return;
      It->second = Merged;
    }
    for (User *U : V->users())
      if (auto *UI = dyn_cast<Instruction>(U))
        enqueue(UI);
  }

  APInt contentSlice(const AllocaInst *A, uint64_t ByteOff, unsigned W) const {
    APInt Out = APInt::getZero(W);
    auto It = ContentD.find(A);
    if (It == ContentD.end())
      return Out;
    unsigned BitOff = static_cast<unsigned>(ByteOff * 8);
    for (unsigned i = 0; i < W; ++i)
      if (BitOff + i < kFp80Bits && It->second[BitOff + i])
        Out.setBit(i);
    return Out;
  }

  // Evaluate one instruction's divergence transfer. Returns the instruction on
  // an observation/unmodellable use of a diverged bit, nullptr otherwise.
  const Instruction *eval(Instruction *I) {
    if (auto *LI = dyn_cast<LoadInst>(I)) {
      if (auto It = LoadAt.find(LI); It != LoadAt.end()) {
        unsigned W = LI->getType()->getIntegerBitWidth();
        unsigned BitOff = static_cast<unsigned>(It->second.second * 8);
        APInt M = contentSlice(It->second.first, It->second.second, W);
        for (unsigned i = 0; i < W; ++i)
          if (BitOff + i >= kFp80Bits)
            M.setBit(i);  // straddle: every padding read diverges.
        setD(LI, M);
        return nullptr;
      }
      if (auto It = ReloadOf.find(LI); It != ReloadOf.end()) {
        // An fp80 reload OBSERVES the whole 80-bit content (it feeds fp
        // arithmetic / escapes as data) — any content divergence is unsound.
        auto CIt = ContentD.find(It->second);
        if (CIt != ContentD.end() && !CIt->second.isZero())
          return LI;
        return nullptr;
      }
      return nullptr;  // a load from unrelated memory never carries divergence.
    }

    if (auto *SI = dyn_cast<StoreInst>(I)) {
      Value *Val = SI->getValueOperand();
      unsigned W = Val->getType()->isIntegerTy()
                       ? Val->getType()->getIntegerBitWidth()
                       : 0;
      APInt Dv = W ? getD(Val, W) : APInt::getZero(1);
      if (auto It = InsertAt.find(SI); It != InsertAt.end()) {
        if (Dv.isZero())
          return nullptr;
        // Land the diverged bits: positions >= 80 drop into the modelled-zero
        // padding (the next straddle read re-taints them); positions < 80
        // taint the union CONTENT every later load inherits.
        unsigned BitOff = static_cast<unsigned>(It->second.second * 8);
        AllocaInst *A = It->second.first;
        APInt &CD =
            ContentD.try_emplace(A, APInt::getZero(kFp80Bits)).first->second;
        APInt Before = CD;
        for (unsigned i = 0; i < W; ++i)
          if (Dv[i] && BitOff + i < kFp80Bits)
            CD.setBit(BitOff + i);
        if (CD != Before) {
          for (const WordLoad &WLd : LoadsOf[A])
            enqueue(WLd.Load);
          for (LoadInst *FL : FpLoadsOf[A])
            enqueue(FL);
        }
        return nullptr;
      }
      if (FpSeeds.count(SI) || DeadStores.count(SI))
        return nullptr;  // fp80 values never diverge; a dead insert is erased.
      return Dv.isZero() ? nullptr : I;  // diverged value escapes to memory.
    }

    if (auto *BO = dyn_cast<BinaryOperator>(I)) {
      unsigned W = BO->getType()->isIntegerTy()
                       ? BO->getType()->getIntegerBitWidth()
                       : 0;
      if (!W)
        return nullptr;  // fp binops: fp operands never carry divergence.
      APInt Da = getD(BO->getOperand(0), W);
      APInt Db = getD(BO->getOperand(1), W);
      if (Da.isZero() && Db.isZero()) {
        setD(BO, APInt::getZero(W));
        return nullptr;
      }
      // Poison-flag guard (see file header): nsw/nuw arithmetic and exact
      // shifts/divs over a diverged operand can flip poison model-side.
      if (auto *OBO = dyn_cast<OverflowingBinaryOperator>(BO))
        if (OBO->hasNoSignedWrap() || OBO->hasNoUnsignedWrap())
          return I;
      if (auto *PE = dyn_cast<PossiblyExactOperator>(BO))
        if (PE->isExact())
          return I;
      auto nzBits = [&](Value *V) {  // bits that can possibly be 1
        if (auto *C = dyn_cast<ConstantInt>(V))
          return C->getValue();
        return APInt::getAllOnes(W);
      };
      auto oneBits = [&](Value *V) {  // bits that are definitely 1
        if (auto *C = dyn_cast<ConstantInt>(V))
          return C->getValue();
        return APInt::getZero(W);
      };
      APInt Out(W, 0);
      switch (BO->getOpcode()) {
      case Instruction::And:
        Out = (Da & nzBits(BO->getOperand(1))) | (Db & nzBits(BO->getOperand(0)));
        break;
      case Instruction::Or:
        Out = (Da & ~oneBits(BO->getOperand(1))) |
              (Db & ~oneBits(BO->getOperand(0)));
        break;
      case Instruction::Xor:
        Out = Da | Db;
        break;
      case Instruction::Add:
      case Instruction::Sub:
      case Instruction::Mul: {
        // A diverged bit perturbs its own position and every higher one (carry
        // / borrow / partial products) — taint [lowest diverged, W).
        unsigned Lo = (Da | Db).countTrailingZeros();
        Out = APInt::getBitsSetFrom(W, Lo);
        break;
      }
      case Instruction::Shl:
        if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(1))) {
          if (!Db.isZero())
            return I;
          Out = C->getValue().uge(W) ? APInt::getZero(W)
                                     : Da.shl(C->getValue().getZExtValue());
        } else if (!Db.isZero()) {
          return I;  // a diverged shift AMOUNT is unmodellable.
        } else {
          Out = Da.isZero()
                    ? APInt::getZero(W)
                    : APInt::getBitsSetFrom(W, Da.countTrailingZeros());
        }
        break;
      case Instruction::LShr:
      case Instruction::AShr:
        if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(1))) {
          if (!Db.isZero())
            return I;
          uint64_t Amt = C->getValue().uge(W) ? W : C->getValue().getZExtValue();
          Out = BO->getOpcode() == Instruction::AShr ? Da.ashr(Amt)
                                                     : Da.lshr(Amt);
        } else if (!Db.isZero()) {
          return I;
        } else {
          Out = Da.isZero() ? APInt::getZero(W) : APInt::getAllOnes(W);
        }
        break;
      default:
        return I;  // udiv/sdiv/urem/srem/… on a diverged operand — decline.
      }
      setD(BO, Out);
      return nullptr;
    }

    if (auto *CI = dyn_cast<CastInst>(I)) {
      Value *Src = CI->getOperand(0);
      if (!Src->getType()->isIntegerTy())
        return nullptr;  // fp/ptr sources never carry divergence.
      unsigned SW = Src->getType()->getIntegerBitWidth();
      APInt Ds = getD(Src, SW);
      if (Ds.isZero()) {
        if (CI->getType()->isIntegerTy())
          setD(CI, APInt::getZero(CI->getType()->getIntegerBitWidth()));
        return nullptr;
      }
      if (!CI->getType()->isIntegerTy())
        return I;  // a diverged word crossing into fp/ptr — unmodellable.
      unsigned DW = CI->getType()->getIntegerBitWidth();
      switch (CI->getOpcode()) {
      case Instruction::Trunc:
        // trunc nuw/nsw stays sound: model dropped bits read 0 ⊆ real dropped
        // bits, so model poison ⊆ real poison (zero-monotone; header proof).
        setD(CI, Ds.trunc(DW));
        return nullptr;
      case Instruction::ZExt:
        setD(CI, Ds.zext(DW));
        return nullptr;
      case Instruction::SExt:
        setD(CI, Ds.sext(DW));  // APInt::sext smears a diverged sign bit.
        return nullptr;
      case Instruction::BitCast:
        setD(CI, Ds.zextOrTrunc(DW));  // same-width int<->int relabel.
        return nullptr;
      default:
        return I;
      }
    }

    if (auto *Cmp = dyn_cast<CmpInst>(I)) {
      Type *OT = Cmp->getOperand(0)->getType();
      if (!OT->isIntegerTy())
        return nullptr;
      unsigned W = OT->getIntegerBitWidth();
      if (!getD(Cmp->getOperand(0), W).isZero() ||
          !getD(Cmp->getOperand(1), W).isZero())
        return I;  // a compare OBSERVES every bit of both operands.
      setD(Cmp, APInt::getZero(1));
      return nullptr;
    }

    if (auto *P = dyn_cast<PHINode>(I)) {
      unsigned W = P->getType()->isIntegerTy()
                       ? P->getType()->getIntegerBitWidth()
                       : 0;
      if (!W)
        return nullptr;
      APInt Out(W, 0);
      for (Value *In : P->incoming_values())
        Out |= getD(In, W);
      setD(P, Out);
      return nullptr;
    }

    if (auto *Sel = dyn_cast<SelectInst>(I)) {
      if (!getD(Sel->getCondition(), 1).isZero())
        return I;  // a diverged condition is control divergence.
      unsigned W = Sel->getType()->isIntegerTy()
                       ? Sel->getType()->getIntegerBitWidth()
                       : 0;
      if (!W)
        return nullptr;
      setD(Sel, getD(Sel->getTrueValue(), W) | getD(Sel->getFalseValue(), W));
      return nullptr;
    }

    if (auto *Fr = dyn_cast<FreezeInst>(I)) {
      if (Fr->getType()->isIntegerTy()) {
        unsigned W = Fr->getType()->getIntegerBitWidth();
        setD(Fr, getD(Fr->getOperand(0), W));
      }
      return nullptr;
    }

    if (auto *Br = dyn_cast<BranchInst>(I)) {
      if (Br->isConditional() && !getD(Br->getCondition(), 1).isZero())
        return I;  // diverged control.
      return nullptr;
    }
    if (auto *Sw = dyn_cast<SwitchInst>(I)) {
      Type *CT = Sw->getCondition()->getType();
      if (CT->isIntegerTy() &&
          !getD(Sw->getCondition(), CT->getIntegerBitWidth()).isZero())
        return I;
      return nullptr;
    }

    // Any other user of a diverged value — a call (incl. cq_measure), a
    // return, a gep index, anything unmodelled — is an observation. (This
    // instruction is only ever enqueued because an operand's mask grew.)
    for (Value *Op : I->operands())
      if (Op->getType()->isIntegerTy() &&
          !getD(Op, Op->getType()->getIntegerBitWidth()).isZero())
        return I;
    return nullptr;
  }
};

// ---------------------------------------------------------------------------
// Canonicalization + promotion (mutating)
// ---------------------------------------------------------------------------

// Build the register-resident extraction of the word `[byteOff, byteOff+bits)`
// from the i80 value `Bc`: `[lshr i80 Bc, byteOff*8] + trunc i80 -> iN`, or, for a
// padding straddle, `+ trunc i80 -> i<meaningful> + zext -> iN` (padding = 0).
Value *extractWord(IRBuilder<> &B, Value *Bc, uint64_t ByteOff, unsigned Bits) {
  LLVMContext &Ctx = Bc->getContext();
  Type *I80 = Bc->getType();
  unsigned BitOff = static_cast<unsigned>(ByteOff * 8);
  unsigned Meaningful = BitOff >= kFp80Bits ? 0 : std::min(Bits, kFp80Bits - BitOff);
  Type *DstTy = IntegerType::get(Ctx, Bits);
  if (Meaningful == 0)
    return ConstantInt::get(DstTy, 0);  // wholly padding (walk proved masked) —
                                        // return BEFORE minting the shift: a
                                        // BitOff >= 80 lshr would be a dead
                                        // poison-producing instruction.
  Value *Sh = Bc;
  if (BitOff > 0)
    Sh = B.CreateLShr(Bc, ConstantInt::get(I80, BitOff), "u_hi");
  if (Meaningful >= Bits)
    return B.CreateTrunc(Sh, DstTy, "u_word");
  Value *M = B.CreateTrunc(Sh, IntegerType::get(Ctx, Meaningful), "u_mean");
  return B.CreateZExt(M, DstTy, "u_word");  // padding bits modelled as 0.
}

// Rewrite one proven union onto a fresh promotable `alloca x86_fp80`: every
// access becomes a full-width x86_fp80 load/store with the i80 extract/insert
// LOCAL around it, and the original memory is erased. `Bcs` collects the
// emitted `bitcast x86_fp80 -> i80` instructions for the post-mem2reg CSE.
void canonicalize(UnionCand &C, SmallVectorImpl<Instruction *> &Bcs,
                  SmallVectorImpl<AllocaInst *> &Fresh) {
  LLVMContext &Ctx = C.A->getContext();
  Type *F80 = Type::getX86_FP80Ty(Ctx);
  Type *I80 = IntegerType::get(Ctx, kFp80Bits);
  IRBuilder<> AB(C.A);
  AllocaInst *NA = AB.CreateAlloca(F80, nullptr, C.A->getName() + ".f80");
  NA->setAlignment(Align(16));
  Fresh.push_back(NA);

  auto keepDbg = [](Value *V, Instruction *From) {
    if (auto *VI = dyn_cast<Instruction>(V))
      if (DebugLoc DL = From->getDebugLoc())
        VI->setDebugLoc(DL);
  };

  // Full-width fp80 accesses: retarget in place (order + !dbg preserved).
  for (StoreInst *S : C.FpStores)
    S->setOperand(StoreInst::getPointerOperandIndex(), NA);
  for (LoadInst *L : C.FpLoads)
    L->setOperand(LoadInst::getPointerOperandIndex(), NA);

  // Integer word loads: load the whole value, relabel to i80, extract.
  for (const WordLoad &W : C.Loads) {
    IRBuilder<> B(W.Load);
    Value *V = B.CreateAlignedLoad(F80, NA, Align(16), "u_val");
    Value *Bc = B.CreateBitCast(V, I80, "u_bits");
    Value *Word = extractWord(B, Bc, W.ByteOff, W.Bits);
    keepDbg(V, W.Load);
    keepDbg(Bc, W.Load);
    keepDbg(Word, W.Load);
    if (auto *BcI = dyn_cast<Instruction>(Bc))
      Bcs.push_back(BcI);
    W.Load->replaceAllUsesWith(Word);
  }

  // Integer field-inserts: read-modify-write the whole value through i80.
  // The inserted field is bits [pos, min(pos+N,80)); value bits landing at
  // storage positions >= 80 drop into the modelled-zero padding (walk-proven
  // unobservable), so `zext` + `shl` (which truncates past bit 79) place
  // exactly the surviving field and `and ~field` clears its old content.
  for (const WordStore &W : C.Inserts) {
    if (W.Dead)
      continue;  // a dead insert — erased below, no pack emitted.
    unsigned Pos = static_cast<unsigned>(W.ByteOff * 8);
    if (Pos >= kFp80Bits) {
      continue;  // a pure-padding write — erased below, nothing survives.
    }
    unsigned Hi = std::min(Pos + W.Bits, kFp80Bits);
    IRBuilder<> B(W.Store);
    Value *V = B.CreateAlignedLoad(F80, NA, Align(16), "u_val");
    Value *Bc = B.CreateBitCast(V, I80, "u_bits");
    APInt Keep = ~APInt::getBitsSet(kFp80Bits, Pos, Hi);
    Value *Clr = B.CreateAnd(Bc, ConstantInt::get(I80, Keep), "u_keep");
    Value *Z = B.CreateZExt(W.Store->getValueOperand(), I80, "u_ins");
    Value *Sh = Pos ? B.CreateShl(Z, ConstantInt::get(I80, Pos), "u_pos") : Z;
    Value *Ins = B.CreateOr(Clr, Sh, "u_set");
    Value *Fp = B.CreateBitCast(Ins, F80, "u_pack");
    B.CreateAlignedStore(Fp, NA, Align(16));
    for (Value *NV : {V, Bc, Clr, Z, Sh, Ins, Fp})
      keepDbg(NV, W.Store);
    if (auto *BcI = dyn_cast<Instruction>(Bc))
      Bcs.push_back(BcI);
  }

  // Erase the original memory: word accesses (RAUW'd / replaced), lifetime
  // markers, then geps (their only users were those), then the alloca.
  for (const WordLoad &W : C.Loads)
    W.Load->eraseFromParent();
  for (const WordStore &W : C.Inserts)
    W.Store->eraseFromParent();
  for (IntrinsicInst *LM : C.Lifetimes)
    LM->eraseFromParent();
  // Gep chains erase children-first: a parent gep is only use-free once its
  // dependent geps are gone, so iterate to a fixpoint (discovery order lists
  // parents before children — one pass would leak the parents).
  SmallVector<GetElementPtrInst *, 4> Geps(C.Geps.begin(), C.Geps.end());
  bool Erased = true;
  while (Erased) {
    Erased = false;
    for (size_t i = 0; i < Geps.size(); ++i)
      if (Geps[i]->use_empty()) {
        Geps[i]->eraseFromParent();
        Geps.erase(Geps.begin() + i);
        Erased = true;
        break;
      }
  }
  if (C.A->use_empty())
    C.A->eraseFromParent();
}

// Dominance-based CSE over the emitted `bitcast x86_fp80 -> i80` relabels.
// After mem2reg the per-access loads collapse to shared SSA values, so sibling
// extracts of the same value mint identical bitcasts; keeping one per
// dominating position restores the Inc-1 single-relabel shape (one bitcast,
// fanned out — the DAG-dedup-cleared form) and keeps the fdiml golden stable.
void cseBitcasts(SmallVectorImpl<Instruction *> &Bcs, const DominatorTree &DT) {
  // Emission order follows the alloca's user list, not program order, so the
  // dominance test must run BOTH ways; only dominance-incomparable duplicates
  // (sibling arms) survive.
  SmallVector<Instruction *, 8> Live(Bcs.begin(), Bcs.end());
  bool Changed = true;
  while (Changed) {
    Changed = false;
    for (size_t i = 0; i < Live.size() && !Changed; ++i)
      for (size_t j = i + 1; j < Live.size() && !Changed; ++j) {
        Instruction *A = Live[i], *B = Live[j];
        if (A->getOperand(0) != B->getOperand(0))
          continue;
        if (DT.dominates(A, B)) {
          B->replaceAllUsesWith(A);
          B->eraseFromParent();
          Live.erase(Live.begin() + j);
          Changed = true;
        } else if (DT.dominates(B, A)) {
          A->replaceAllUsesWith(B);
          A->eraseFromParent();
          Live.erase(Live.begin() + i);
          Changed = true;
        }
      }
  }
}

// Fold the all-constant cone a CLASSICAL (const-seed) union promotion exposes,
// and collapse the resulting constant-conditioned branch — the `isnan(0.5L)` ->
// dead-branch fold the PRD §5 depends on. This is EXACTLY the instcombine/
// simplifycfg cleanup the f64 sibling gets for free at clang -O1 (SROA promotes
// its union there, so the branches fold before cq-lowering ever runs); the fp80
// union stays in memory past clang -O1, so the promotion must do it. Constant
// folding is semantics-preserving and touches ONLY all-constant instructions —
// a tainted (theta-derived) value is never all-constant, so the tainted isnan/
// exponent control is left byte-untouched; only the classical dead branch
// collapses, so PredMux's E6 (every internal terminator TAINTED) then holds.
bool foldConstantConeAndBranches(Function &F, const DataLayout &DL) {
  bool Any = false;
  bool Changed = true;
  while (Changed) {
    Changed = false;
    // Fold every all-constant-operand instruction to its constant value.
    for (BasicBlock &BB : F)
      for (Instruction &I : llvm::make_early_inc_range(BB)) {
        if (isa<PHINode>(&I) || I.isTerminator())
          continue;  // phis fold via the terminator pass; terminators below.
        if (Constant *C = ConstantFoldInstruction(&I, DL)) {
          I.replaceAllUsesWith(C);
          if (llvm::isInstructionTriviallyDead(&I))
            I.eraseFromParent();
          Changed = Any = true;
        }
      }
    // Collapse any now-constant-conditioned branch (deletes the dead edge +
    // updates the dead successor's phis).
    for (BasicBlock &BB : llvm::make_early_inc_range(F))
      if (ConstantFoldTerminator(&BB, /*DeleteDeadConditionalBranches=*/true))
        Changed = Any = true;
  }
  if (Any) {
    // bd 7udx — `removeUnreachableBlocks` reaps blocks with
    // `BasicBlock::eraseFromParent()`, whose destructor RAUWs every
    // `BlockAddress` of a destroyed block to `inttoptr (i32 1 to ptr)`
    // MODULE-WIDE. That silently rewrites a compared-against address (and any
    // classical `store ptr blockaddress ...` anywhere in the module) to 1, on a
    // WELL-DEFINED source with no UB and no refinement argument to excuse it.
    // MEASURED corrupting here (census row `Fp80Union removeUnreachableBlocks`,
    // `lowering_fp80_union_multiblock.ll` + a holder: `%sub` and `%norm` corrupt).
    // Reached from `promoteFp80Union` AND from `foldConstantConesInFunction`,
    // which PredMux calls after every flatten — so this is not an fp80-only path.
    // The overload names LLVM's own deletion set (unreachable-from-entry), so a
    // SURVIVING address-taken block still lowers.
    // Anchor the `!dbg` on the entry's first instruction (a better source
    // location than a terminator), but never dereference `begin()` on an empty
    // block — pass null and let the overload fall back to the offending block.
    BasicBlock &EB = F.getEntryBlock();
    Instruction *Anchor = EB.empty() ? nullptr : &*EB.begin();
    // Drop-in for `removeUnreachableBlocks(F)` that also holds the bd 7udx
    // invariant. It OBSERVES which blocks the utility actually deleted rather than
    // predicting them — `markAliveBlocks` mutates first, so any prediction is a
    // strict under-estimate (see LiteralIntegrity.h). Return value is unused here
    // for the same reason the bare call's was: `Any` already records the change.
    removeUnreachableBlocksChecked(F, Anchor);
  }
  return Any;
}

}  // namespace

bool foldConstantConesInFunction(Function &F) {
  return foldConstantConeAndBranches(F, F.getParent()->getDataLayout());
}

bool promoteFp80Union(Module &M, TaintSet &taint) {
  const DataLayout &DL = M.getDataLayout();
  // Debug lever (bd 3c6m.55; env-gated, no behavior change): per-alloca
  // candidate/seed/walk trace for the fp80-union frontier work.
  const bool Dbg2 = ::getenv("CQ_FP80_DBG2") != nullptr;
  // bd szpr hardening — the whole promotion's byte arithmetic (the offset-8
  // expsign straddle, the [10,16) padding range, the 128-bit canonical slot)
  // assumes the x86-64 f80:128 layout: x86_fp80 stored in a 16-byte slot with
  // 6 padding bytes. On any other datalayout (i386 f80:32/96, or a target
  // where long double is fp128) the offsets are WRONG — promote NOTHING and
  // let every union ride the existing loud kMsgStore decline (over-declining
  // is safe; a mis-offset promotion would be a silent bit-pattern miscompile).
  if (DL.getTypeAllocSize(Type::getX86_FP80Ty(M.getContext())) != 16)
    return false;
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Collect candidate allocas up front (analysis + rewrite mutate the IR).
    SmallVector<AllocaInst *, 8> Allocas;
    for (Instruction &I : F.getEntryBlock())
      if (auto *A = dyn_cast<AllocaInst>(&I))
        Allocas.push_back(A);
    if (Allocas.empty())
      continue;

    DominatorTree DT(F);
    SmallPtrSet<BasicBlock *, 16> OnCycle;
    collectCycleBlocks(F, OnCycle);

    // Structural pass: keep only provable fp80 bit-pattern unions.
    SmallVector<UnionCand, 4> Cands;
    for (AllocaInst *A : Allocas) {
      UnionCand C;
      bool Struct = analyzeStructure(A, DL, C);
      bool Acyc = Struct && accessesAcyclic(C, OnCycle, DT);
      // The value-definedness gate matches the idiom class: seed domination
      // for the fp80-seeded shape, the P1/P2 pack proof for a reconstruct.
      bool Defined = Acyc && (C.Reconstruct ? packDefinednessOk(C, DT)
                                            : accessesSeedDominated(C, DT));
      if (Dbg2 && A->getAllocatedType()->isStructTy()) {
        errs() << "[FP80DBG2] " << F.getName() << " alloca ";
        A->printAsOperand(errs(), /*PrintType=*/false);
        errs() << " struct=" << Struct << " acyclic=" << Acyc
               << " defined=" << Defined << " pack=" << C.Reconstruct << "\n";
      }
      if (Defined) {
        markDeadInserts(C, DT);
        Cands.push_back(std::move(C));
      }
    }

    // Seed gate (fixpoint: dropping a candidate removes its reloads from the
    // admissible cone of the others' re-seed values). bd vqlq: each surviving
    // candidate is classified STRICT (every seed admissible under the shipped
    // tainted/Constant/candidate-reload rule) or OPPORTUNISTIC (needs the
    // argument-derived widening for >= 1 seed). `AdmitArgDerived=false` drops
    // opportunistic candidates too — the strict-only re-run below.
    SmallPtrSet<const AllocaInst *, 4> Opportunistic;
    auto seedClass = [&](const UnionCand &C,
                         const SmallPtrSetImpl<const LoadInst *> &Rel) -> int {
      // 2 = strict, 1 = opportunistic, 0 = inadmissible.
      // Lever A.1d: a reconstruct pack has NO fp80 seed store to classify —
      // the seed loop below would be vacuously strict. Packs are ALWAYS
      // opportunistic: they were not candidates before this widening, so a
      // §4.1 walk failure must drop them silently (reproducing today's
      // outcome — memory form, existing declines), never widen the loud
      // kMsgFp80Padding surface; and the strict-only re-run must not keep
      // them (a strict sibling seeded through a pack reload then re-drops via
      // the rebuilt candidate-reload set — drop-then-rerun stays equal to
      // strict-from-scratch).
      if (C.Reconstruct)
        return 1;
      bool NeedsWide = false;
      for (StoreInst *S : C.FpStores) {
        if (fpSeedValueOk(S->getValueOperand(), taint, Rel,
                          /*AdmitArgDerived=*/false))
          continue;
        if (!fpSeedValueOk(S->getValueOperand(), taint, Rel,
                           /*AdmitArgDerived=*/true))
          return 0;
        NeedsWide = true;
      }
      return NeedsWide ? 1 : 2;
    };
    auto runSeedFixpoint = [&](bool AdmitArgDerived) {
      Opportunistic.clear();
      bool Dropped = true;
      SmallPtrSet<const LoadInst *, 8> CandFpLoads;
      while (Dropped && !Cands.empty()) {
        Dropped = false;
        CandFpLoads.clear();
        for (const UnionCand &C : Cands)
          for (const LoadInst *L : C.FpLoads)
            CandFpLoads.insert(L);
        for (size_t i = 0; i < Cands.size(); ++i) {
          int K = seedClass(Cands[i], CandFpLoads);
          if (K == 0 || (K == 1 && !AdmitArgDerived)) {
            if (Dbg2) {
              errs() << "[FP80DBG2] " << F.getName() << " DROP-seed ";
              Cands[i].A->printAsOperand(errs(), false);
              errs() << " class=" << K;
              for (StoreInst *S : Cands[i].FpStores) {
                const Value *Why = nullptr;
                fpSeedValueOk(S->getValueOperand(), taint, CandFpLoads,
                              /*AdmitArgDerived=*/true, &Why);
                errs() << " seed={";
                S->getValueOperand()->printAsOperand(errs(), true);
                errs() << "} blocker={";
                if (Why)
                  errs() << *Why;
                errs() << "}";
              }
              errs() << "\n";
            }
            Cands.erase(Cands.begin() + i);
            Dropped = true;
            break;
          }
        }
      }
      for (const UnionCand &C : Cands)
        if (seedClass(C, CandFpLoads) == 1)
          Opportunistic.insert(C.A);
    };
    runSeedFixpoint(/*AdmitArgDerived=*/true);
    if (Dbg2) {
      errs() << "[FP80DBG2] " << F.getName()
             << " candidates=" << Cands.size()
             << " opportunistic=" << Opportunistic.size() << " {";
      for (const UnionCand &C : Cands) {
        C.A->printAsOperand(errs(), false);
        errs() << " ";
      }
      errs() << "}\n";
    }
    if (Cands.empty())
      continue;

    // The §4.1 fence: one whole-function walk over every candidate at once
    // (divergence flows ACROSS unions — a word extracted from one union can be
    // field-inserted into another, as in copysignl). A violation declines the
    // WHOLE function's promotion, loudly; nothing is mutated. bd vqlq: if any
    // OPPORTUNISTIC candidate is present, a violation first drops them ALL and
    // re-runs the strict-only fixpoint + walk — an opportunistic union was not
    // a candidate before the widening, so its failure must reproduce today's
    // outcome (memory form, silent) rather than widen the loud-decline
    // surface; a strict-only violation keeps today's loud decline exactly.
    // (Strict-from-scratch equals drop-opportunistic-then-strict: the seed
    // gate is monotone in the candidate-reload set.)
    if (const Instruction *Bad = PaddingWalk(Cands).run()) {
      if (Dbg2)
        errs() << "[FP80DBG2] " << F.getName() << " WALK-BAD " << *Bad << "\n";
      if (!Opportunistic.empty()) {
        llvm::erase_if(Cands, [&](const UnionCand &C) {
          return Opportunistic.count(C.A);
        });
        runSeedFixpoint(/*AdmitArgDerived=*/false);
        Bad = Cands.empty() ? nullptr : PaddingWalk(Cands).run();
      }
      if (Bad) {
        diagnoseFp80(const_cast<Instruction *>(Bad), kMsgFp80Padding);
        continue;
      }
      if (Cands.empty())
        continue;
    }

    // Canonicalize every candidate, then let LLVM's own mem2reg build the SSA.
    SmallVector<Instruction *, 8> Bcs;
    SmallVector<AllocaInst *, 4> Fresh;
    for (UnionCand &C : Cands)
      canonicalize(C, Bcs, Fresh);
    assert(llvm::all_of(Fresh,
                        [](AllocaInst *A) { return isAllocaPromotable(A); }) &&
           "canonicalized fp80 union alloca must be promotable");
    PromoteMemToReg(Fresh, DT);
    cseBitcasts(Bcs, DT);
    Changed = true;

    // Inc-3 safety fence: no i80 value may cross a control merge (there is no
    // i80 controlled copy). The f80-typed fresh alloca makes this impossible
    // for mem2reg-built phis by construction; the scan is the defensive
    // invariant behind that construction and also catches a pre-existing
    // hand-written i80 phi in a function we just promoted. Diagnose loudly —
    // opt exits non-zero, so the mutated module never ships.
    bool I80Merge = false;
    for (BasicBlock &BB : F) {
      for (PHINode &P : BB.phis())
        if (P.getType()->isIntegerTy(kFp80Bits)) {
          diagnoseFp80(&P, kMsgFp80I80Merge);
          I80Merge = true;
          break;
        }
      if (I80Merge)
        break;
    }
    if (I80Merge)
      continue;

    // Collapse the classical-union dead branch (isnan(const) -> dead), so the
    // residual tainted control is PredMux-eligible (E6: all terminators tainted).
    foldConstantConeAndBranches(F, DL);
  }
  return Changed;
}

}  // namespace cq
