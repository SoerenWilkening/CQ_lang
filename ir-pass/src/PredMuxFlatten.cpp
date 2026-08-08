// PredMuxFlatten.cpp — 3c6m.14 (L6): general acyclic tainted control via
// block-predicate MUX flattening ("PredMux"). See PredMuxFlatten.h and the
// PRD (docs/prd/phase-07-expressiveness/3c6m.14-L6-control-predication/) for
// the design of record; the correctness argument is PRD §6 (per-basis-state
// classical IR equivalence + reduction to the Rule-13-cleared select
// substrate).
//
// The one non-negotiable here is the ACCEPT-ONLY discipline: every check
// below LEAVES the region untouched on failure — the existing detection
// declines it loudly exactly as today. Over-declining stays safe; PredMux can
// only widen the accept surface, never replace a decline with silence.
//
// Eligibility (PRD §4.2, E-ladder) in brief:
//   W  — claim witnesses: only shapes today's detection DECLINES are claimed
//        (nested tainted terminators; multi-phi / >2-incoming br merges; —
//        W5, bd vyqi — the flat sole-2-incoming SCALAR-FP-phi diamond with
//        distinct incomings, which ArmClassify's fp fence categorically
//        declines; and — W7, bd 0rwu — the flat sole-2-incoming INTEGER-phi
//        diamond whose ENTRY-edge incoming is a ConstantInt and whose other
//        incoming is a region-INTERIOR instruction, the fdlibm __isnanl tail).
//        Every OTHER flat sole-2-incoming-phi INTEGER diamond (a non-constant
//        straight-through — the 4.2 routed method-B accepts — and the a8c0
//        empty-arm const-fold re-anchor), a straight-line-arm switch, and the
//        depth-2 homogeneous-phase nest (its arms hold cq_phi CALLS, excluded
//        by E4) all stay with their shipped owners byte-identically.
//   E2 — acyclic: no region block (incl. entry) on any CFG cycle.
//   E3 — single-entry/single-exit: successors ⊆ region ∪ {merge}; merge preds
//        ⊆ region; no side entry; only br/switch terminators inside.
//   E4 — pure speculatable dataflow at TEMPLATE-SUPPORTED widths:
//        arithmetic/bit/compare/cast/select/fneg/freeze/phi + curated
//        memory(none) intrinsics; int division only by a nonzero (and, for
//        signed, non-minus-one) constant. No loads (v1), no stores, no other
//        calls (any @cq_* call therefore excludes the shape). The width gate
//        on INTERMEDIATE ops (not just merges/conditions) is a Rule-13
//        clearance hardening: an fp128 arm op would only decline loudly
//        post-flatten at lowerOps; gating it here keeps the whole ladder
//        detect-before-mutate (a claimed region can never half-lower).
//   E6 — every internal conditional terminator is tainted AND its condition
//        is a supported compare/and/or tree (so the false-edge literal can be
//        built by leaf predicate inversion — the no-NOT invariant).
//   E7 — every phi being converted has a mux-lowerable scalar type.
//
// The flatten (PRD §4.3–4.6): process region blocks in topological order,
// moving instructions before the entry terminator (poison flags dropped —
// speculation discipline; bit-semantics and template selection unaffected,
// Rule 15), converting each phi to a chained select over edge predicates
// EP(e) = BP(src) ∧ lit(e), with BP(b) = ∨ EP(in-edges) materialized lazily.
// undef/poison incomings freeze to the type's zero constant (the incoming is
// dead on every basis state that selects it — clang emits undef precisely
// because the source never reads it on that path). Then the entry terminator
// becomes an unconditional branch to the merge and the arm blocks are erased
// in one coordinated teardown (identities captured up front; one region per
// call, so nothing is ever cached across an erasure — Rule 9 / the
// block-lifetime SIGSEGV family).

#include "PredMuxFlatten.h"

#include "Fp80Union.h"      // foldConstantConesInFunction (adia fold residue)
#include "IntrinsicLowering.h"
#include "OpcodeSupport.h"  // abiWidthFromType, binaryStem, castInScope, i80BinaryInScope
#include "QramLowering.h"
#include "TaintPropagation.h"

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/ScopeExit.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/MathExtras.h"  // isPowerOf2_64 (bd 20xt.7 Provable-pow2 mask)
#include "llvm/Transforms/Utils/Local.h"  // RecursivelyDeleteTriviallyDeadInstructions

using namespace llvm;

namespace cq {

namespace {

// ---------------------------------------------------------------------------
// Eligibility predicates (pure — detect-before-mutate, Rule 9)
// ---------------------------------------------------------------------------

// A tainted conditional terminator: the only two shapes PredMux roots or
// admits inside a region. (Everything else — ret/unreachable/invoke/… — fails
// E3 and leaves.)
bool isTaintedCtrlTerm(const Instruction *T, const TaintSet &Taint) {
  if (const auto *BI = dyn_cast<BranchInst>(T))
    return BI->isConditional() && Taint.Tainted.count(BI->getCondition());
  if (const auto *SI = dyn_cast<SwitchInst>(T))
    return Taint.Tainted.count(SI->getCondition());
  return false;
}

// E7 — a type the select substrate can mux: integer ≤ 64 bits or the scalar
// fp widths of the kjd1 controlled-copy family. (Mirrors copyControlledFn /
// copyControlledFpFn envelopes so a claimed region cannot half-lower —
// detect-before-mutate.)
bool isMuxableType(Type *Ty) {
  if (auto *IT = dyn_cast<IntegerType>(Ty))
    return IT->getBitWidth() <= 64;
  return Ty->isHalfTy() || Ty->isFloatTy() || Ty->isDoubleTy() ||
         Ty->isX86_FP80Ty();
}

// The wider gate for INTERMEDIATE arm values (they never cross a merge, so
// they only need a forward template, not a controlled copy): the
// opcode-table width surface — integers up to 64 bits plus the Tier-1 i128,
// and the four scalar fp widths. fp128/ppc_fp128, pointers, and everything
// exotic fail here and the region is LEFT (a Rule-13 clearance hardening —
// previously such an arm flattened and then declined loudly at lowerOps).
bool isTemplateWidthType(Type *Ty) {
  if (auto *IT = dyn_cast<IntegerType>(Ty)) {
    unsigned W = IT->getBitWidth();
    return W <= 64 || W == 128;
  }
  return Ty->isHalfTy() || Ty->isFloatTy() || Ty->isDoubleTy() ||
         Ty->isX86_FP80Ty();
}

// A compare whose flag the substrate can mint (icmp on int ≤ 64 / fcmp on the
// scalar fp widths; never vectors or pointers).
bool isSupportedCompareLeaf(const CmpInst *Cmp) {
  // NO SELF-OPERAND / ALIASED-OPERAND FENCE HERE, DELIBERATELY (bd big5,
  // 2026-07-31 — the revert of bd 7q3s / dd2c103). DO NOT RE-ADD ONE. An
  // aliased condition compare is CASE A (aliased INPUTS, FRESH output flag
  // rail) = a realizable unary function of the shared operand, not a defect;
  // the full refutation is at the `collectCondTree` leaf slot in
  // SelectClassify.cpp. Adding one back here would ALSO re-open the posture
  // problem in the opposite direction: PredMux would decline the CLAIM for a
  // region the downstream select now happily lowers.
  Type *OpTy = Cmp->getOperand(0)->getType();
  if (OpTy->isPointerTy() || OpTy->isVectorTy())
    return false;
  if (auto *IT = dyn_cast<IntegerType>(OpTy))
    return IT->getBitWidth() <= 64;
  return OpTy->isHalfTy() || OpTy->isFloatTy() || OpTy->isDoubleTy() ||
         OpTy->isX86_FP80Ty();
}

// bd 3c6m.14.2 — a literal `undef`/`poison` is NOT a defined leaf, however
// deeply it is buried in a constant aggregate/expression. `PoisonValue` derives
// from `UndefValue`, so the `isa` catches both spellings. The walk carries a
// visited set rather than a depth budget on purpose: a budget inside a yes/no
// predicate makes the ANSWER depend on the cut-off (bd memory
// [[budget-in-a-memo-and-probes-with-no-power-2026-08-08]]), and constants form
// a finite DAG that a visited set terminates on structurally.
//
// KNOWN INCOMPLETENESS, deliberately not closed here and filed instead: this
// tests for a CONTAINED `UndefValue`, so a constant expression that GENERATES
// poison without containing one — e.g. an out-of-bounds
// `ptrtoint (ptr getelementptr inbounds (...) to i64)` — still reads as a
// defined leaf. Measured PRE-EXISTING and BASE-identical, and a Constant is
// state-INDEPENDENT, so the flatten adds no observation the shielded select had
// not already made. (The Rule-13 round's headline evidence for it — a trace that
// differs between two runs of the same binary — was refuted: that is ASLR of a
// relocated global address, reproducible with a provably-DEFINED
// `ptrtoint (ptr @g to i64)` and with PredMux absent from the module entirely.)
bool constantCarriesUndef(const Constant *C,
                          SmallPtrSetImpl<const Constant *> &Seen) {
  if (isa<UndefValue>(C))
    return true;
  if (!Seen.insert(C).second)
    return false;
  for (const Value *Op : C->operands())
    if (const auto *CO = dyn_cast<Constant>(Op))
      if (constantCarriesUndef(CO, Seen))
        return true;
  return false;
}

bool valueCarriesUndef(const Value *V) {
  const auto *C = dyn_cast<Constant>(V);
  if (!C)
    return false;
  SmallPtrSet<const Constant *, 8> Seen;
  return constantCarriesUndef(C, Seen);
}

// bd 3c6m.14.2 — the three curated intrinsics that can return POISON, and the
// reason they cannot be handled the way every other poison source here is.
//
// `llvm.ctlz(x, is_zero_poison)` / `llvm.cttz(x, is_zero_poison)` return poison
// for x==0, and `llvm.abs(x, is_int_min_poison)` returns poison for INT_MIN,
// when the trailing `i1` is true. That `i1` is an **immarg** — an OPERAND, not
// an annotation. `Instruction::hasPoisonGeneratingAnnotations()` does not see
// it, no `drop*` API can strip it, and it is a `ConstantInt`, so
// `valueCarriesUndef` does not see it either. Every mechanism this file has for
// neutralising poison structurally misses it, so the only sound handling is to
// REFUSE — conservatively, including when the immarg is not a ConstantInt.
//
// This was found by the bd 3c6m.14.2 Rule-13 round, on the FIRST draft of that
// ticket's own fix, and reproduced by the orchestrator: a shielded cone over
// `ctlz(0, true)` was claimed and flattened with `opt` exit 0, `opt -verify`
// clean and `free_pairing_check` STRICT 6/6, and the linked trace fired
// `cq_template_icmp_sgt_i32_hl(h32, 0)` — a gate on a rail index `cqrt_alloc_*`
// never returned. Every OTHER member of the curated set is genuinely total:
// bswap/bitreverse/ctpop, smin/smax/umin/umax, the four `*_sat`, fshl/fshr (the
// rotate amount is taken modulo the width), and the p119 hardware fp survivors
// (which return NaN, never poison). See `intrinsicStem` in IntrinsicLowering.cpp
// for the authoritative set — these two lists are coupled with nothing
// mechanical holding them together, so re-read it when either moves.
bool curatedIntrinsicCanBePoison(const CallInst *CI) {
  const Function *F = CI->getCalledFunction();
  if (!F)
    return true;
  Intrinsic::ID Id = F->getIntrinsicID();
  if (Id != Intrinsic::ctlz && Id != Intrinsic::cttz && Id != Intrinsic::abs)
    return false;
  const auto *Flag = CI->arg_size() >= 2
                         ? dyn_cast<ConstantInt>(CI->getArgOperand(1))
                         : nullptr;
  return !Flag || !Flag->isZero();
}

// bd 3c6m.14.2 — the per-instruction core of the shielded-cone definedness
// proof, given a name because the fence it draws is referenced from three
// comments and was previously buried inside the walk. Calls are NOT decided
// here; `coneDefinedAfterFlagDrop` owns that.
//
// STRICTER than the `isSpeculatableDataflow` families, because this asks
// DEFINEDNESS, not speculation safety:
//   * icmp/fcmp (FMF dropped), add/sub/mul/and/or/xor (nsw/nuw dropped),
//     udiv/sdiv/urem/srem by the isSpeculatableDataflow-safe CONSTANT only;
//   * shl/lshr/ashr ONLY by an in-range ConstantInt amount (a runtime
//     amount >= bit width is INHERENT poison — no flag to drop);
//   * the defined casts zext/sext/trunc/fpext/fptrunc/sitofp/uitofp/bitcast
//     (fptosi/fptoui are inherent poison on out-of-range inputs — fail);
//   * select/phi/freeze.
// Everything else — loads, geps, fneg, and every call — fails HERE. Those are
// over-declines and they are safe; `fneg` in particular is total and could be
// admitted, but nothing measured needs it and widening a definedness proof is
// not what this ticket is for (Rule 17).
bool definedOpAfterFlagDrop(const Instruction &I) {
  if (isa<CmpInst>(&I) || isa<SelectInst>(&I) || isa<PHINode>(&I) ||
      isa<FreezeInst>(&I))
    return true;
  if (const auto *BO = dyn_cast<BinaryOperator>(&I)) {
    switch (BO->getOpcode()) {
    case Instruction::Add:
    case Instruction::Sub:
    case Instruction::Mul:
    case Instruction::And:
    case Instruction::Or:
    case Instruction::Xor:
    case Instruction::FAdd:
    case Instruction::FSub:
    case Instruction::FMul:
    case Instruction::FDiv:
    case Instruction::FRem:
      return true;
    case Instruction::Shl:
    case Instruction::LShr:
    case Instruction::AShr:
      // `APInt::ult`, NOT `getZExtValue() <` (bd 3c6m.14.2 Rule-13 round). In a
      // Release plugin the `getZExtValue` assert is compiled out and it returns
      // the LOW WORD, so `shl i128 %w, 1<<100` — whose low word is 0 — read as
      // an in-range amount of 0 and was ADMITTED, while the same shift by 200
      // correctly declined. Measured on the shipped plugin before the fix.
      if (const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1)))
        return C->getValue().ult(BO->getType()->getScalarSizeInBits());
      return false;
    case Instruction::UDiv:
    case Instruction::SDiv:
    case Instruction::URem:
    case Instruction::SRem: {
      const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1));
      return C && !C->isZero() &&
             !((BO->getOpcode() == Instruction::SDiv ||
                BO->getOpcode() == Instruction::SRem) &&
               C->isMinusOne());
    }
    default:
      return false;
    }
  }
  if (const auto *CI = dyn_cast<CastInst>(&I)) {
    switch (CI->getOpcode()) {
    case Instruction::ZExt:
    case Instruction::SExt:
    case Instruction::Trunc:
    case Instruction::FPExt:
    case Instruction::FPTrunc:
    case Instruction::SIToFP:
    case Instruction::UIToFP:
    case Instruction::BitCast:
      return true;
    default:  // fptosi/fptoui/ptr casts — inherent poison / out of scope.
      return false;
    }
  }
  return false;
}

// bd adia: is every instruction in `V`'s backward cone TOTAL (defined on all
// inputs) once its poison-generating annotations are dropped? The admissibility
// proof for canonicalizing a poison-shielded short-circuit select-form into a
// plain and/or (which observes the shielded operand on basis states the original
// never did). The per-instruction whitelist is `definedOpAfterFlagDrop`; leaves
// are:
//   * Argument — assumed runtime-defined (the same leaf assumption every
//     existing flatten makes);
//   * Constant — defined UNLESS it carries `undef`/`poison` (see
//     `valueCarriesUndef`);
//   * a `cq_theta`/`cq_phi` rotation result — runtime data, never poison;
//   * a curated `memory(none)` intrinsic that is not one of the three
//     poison-immarg cells (see `curatedIntrinsicCanBePoison`).
// Anything else fails and the select-form stays unclaimed (accept-only).
bool coneDefinedAfterFlagDrop(const Value *Root) {
  SmallPtrSet<const Value *, 16> Seen;
  SmallVector<const Value *, 16> WL;
  WL.push_back(Root);
  while (!WL.empty()) {
    const Value *V = WL.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    if (valueCarriesUndef(V))
      return false;  // bd 3c6m.14.2 — an undef/poison leaf is not defined.
    const auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;  // Constant / Argument leaf — defined.
    bool Ok = false;
    if (const auto *Call = dyn_cast<CallInst>(I)) {
      // A cq_theta/cq_phi rotation result is RUNTIME DATA minted by the
      // runtime ABI — a defined leaf, never poison (do not recurse into the
      // classical seed/angle operands: the result's definedness does not
      // depend on them being poison-free in this proof's sense — the
      // rotation call itself would be the UB-observing consumer, which the
      // original program already executed unconditionally here).
      const Function *CF = Call->getCalledFunction();
      if (CF && (CF->getName().starts_with("cq_theta_") ||
                 CF->getName().starts_with("cq_phi_"))) {
        continue;  // defined leaf — skip operand recursion.
      }
      // *** THIS CLAUSE ADMITS ONLY THE PROJECT'S OWN CURATED SET. IT USED TO
      // ADMIT ANY `isSpeculatablePureCalleeBody` CALLEE, AND THAT WAS A SILENT
      // MISCOMPILE (bd 3c6m.14.2). ***
      //
      // The purity proof answers "pure + total + terminating". That is NOT
      // "returns a defined value", in two independent ways: it reaches its
      // verdict through `isSpeculatableDataflow`, which admits a variable-amount
      // `shl/lshr/ashr` and `fptosi/fptoui` UNCONDITIONALLY — the very ops
      // `definedOpAfterFlagDrop` refuses inline, because their poison is
      // INHERENT and `stripPoisonCone` walks only `I->operands()` and so never
      // enters a callee body — and it SKIPS TERMINATORS, so a body of just
      // `ret i32 poison` passes VACUOUSLY. Exhibited end-to-end: the emitted
      // Bennett clone returned literal poison AS AN i32 QUBIT HANDLE, which at
      // the shipped -O0 stage 3 materialised as the `%q` rail itself, so the
      // circuit computed `(q>3) ∧ (q>0)` instead of `(q>3) ∧ (leaf(q)>0)` —
      // `opt` exit 0, `opt -verify` clean, `free_pairing_check` STRICT 6/6.
      //
      // WHY DELETION RATHER THAN A SECOND PROOF (the ticket offered both, and
      // asked for the measurement first). MEASURED: the pure-callee disjunct is
      // reached by 1 of 949 ir-pass fixtures and 0 of 238 e2e slices; and of the
      // 39 poison-shielded select-forms `clang -O1` emits across 248 real
      // openlibm TUs, the 5 with a call in the shielded cone carry ONLY curated
      // intrinsics. Its real-code population is EMPTY. The ticket's reason for
      // keeping it — "the plain -O1 expl→floorl shape" — is a DIFFERENT surface:
      // that accept is S1, `recoverRegion`'s E4 call admission, where the call
      // sits in an ARM and this proof never sees it (pinned by
      // lowering_predmux_speccall_flatten.ll, which still passes).
      //
      // A definedness proof over an arbitrary callee body WAS written first, and
      // the Rule-13 round found a fresh verify-clean silent miscompile inside it
      // (the immarg cell below) plus an unsound shift-width check, in ~40 lines
      // serving zero measured inputs. Nobody set out to build "an arbitrary pure
      // callee inside a poison-shielded `&&`" — it was an incidental widening of
      // a SPECULATION clause into a context carrying a strictly stronger
      // obligation — so Rule 17 does not protect it, and the Prime Directive says
      // an unproven, unpopulated accept surface should not exist.
      //
      // The curated disjunct STAYS: those are the project's own set, their
      // totality is a fact about code we ship rather than an inference about
      // user code, and they are the only call shape with any measured
      // population. `curatedIntrinsicCanBePoison` carves out the three cells
      // whose poison rides an immarg no drop can reach.
      Ok = isCuratedReversibleIntrinsic(Call) && Call->doesNotAccessMemory() &&
           !curatedIntrinsicCanBePoison(Call);
    } else {
      Ok = definedOpAfterFlagDrop(*I);
    }
    if (!Ok)
      return false;
    for (const Value *Op : I->operands())
      WL.push_back(Op);
  }
  return true;
}

// bd q2wk (Inc 5) — the claim-time context a PATH-PREDICATED PHI condition
// needs (PRD §4.4b rule (A)). `InRegion`/`Entry` decide whether the flatten
// will actually convert the phi (`run()` converts every region block's phis
// EXCEPT the entry's), and `Recorded` collects the phis the claim PROVED
// convertible so `convertPhis` can take the boolean-algebra path for exactly
// those — claim and emit share one decision instead of re-deriving it, which
// is what makes a depth-budget or already-converted-incoming difference
// between the two impossible. Null scope = no phi is admissible (every
// non-claim caller keeps today's grammar byte-identically).
//
// `Entry == nullptr` means NO ENTRY FENCE, and that is a real contract, not an
// accident of a default: the bd oudq W6 witness uses it to ask "would this phi
// convert if its block were a MERGE?" and pairs it with a second scope whose
// `Entry` IS that block, so the two answers differ exactly on the entry-phi
// rule. Every other caller passes a real region entry. A future refinement that
// dereferences `Entry` (a dominance test, an assert) must keep this case alive
// or it silently turns W6 off — or, worse, on for a genuine entry phi. NOTE the
// fence is spelled `PB == S->Entry`, so a DETACHED phi (null parent) also reads
// as fenced under a null `Entry` — the safe direction (both scopes then answer
// false and W6 cannot fire), and unreachable in practice since any phi in a
// verified terminator's condition cone is parented.
struct PhiCondScope {
  const SmallPtrSetImpl<BasicBlock *> *InRegion = nullptr;
  const BasicBlock *Entry = nullptr;
  SmallPtrSetImpl<PHINode *> *Recorded = nullptr;
};

bool isBooleanCondTree(const Value *V, unsigned Depth,
                       const PhiCondScope *S = nullptr);

// bd q2wk (Inc 5) — is this i1 phi one the flatten will convert to boolean
// algebra, so that its value can serve as a branch-condition tree node? All
// four conditions are load-bearing (PRD §4.4b):
//   1. i1 type and 3. >1 UNIQUE incoming block — `convertPhis`' own BoolAlg
//      gate, mirrored exactly (its `In` list dedups by incoming BLOCK).
//   2. parent inside the region but NOT the entry — `run()` skips
//      `R.Entry`, so an entry phi survives the flatten AS A PHI and
//      `buildNegation` would run its terminal `cast<BinaryOperator>` on a
//      `PHINode`: an assert in a `+Asserts` build and an unchecked bad cast in
//      the shipped Release build, not merely invalid IR `-verify` would catch.
//   4. every incoming inside the STRICT substrate grammar (`isBooleanCondTree`,
//      extended with this same phi rule). Deliberately NOT the permissive
//      `isSupportedCondTree`: an incoming admitted only by the permissive
//      grammar (xor-true, a select-form short-circuit) is composed straight
//      INTO the boolean-algebra tree as an OFF-GRAMMAR LEAF (`and(EP, %xor)`,
//      `and(EP, %trunc)`) — because a RECORDED phi bypasses `convertPhis`'
//      grammar re-check — and `literal()` then hands `buildNegation` a tree
//      whose leaf is neither cmp/and/or/xor nor constant, hitting the same
//      `cast<BinaryOperator>`. (The q2wk Rule-13 round corrected this comment:
//      it used to describe a SELECT-CHAIN fallback, which the BoolAlgPhis
//      record makes unreachable for exactly the phis this condition guards.)
// undef/poison incomings are admitted because `convertPhis` freezes them to the
// type's zero (an i1 constant) BEFORE its own grammar check — mirroring that
// freeze here is what keeps claim and emit in step.
bool isConvertiblePhiCond(const PHINode *P, const PhiCondScope *S,
                          unsigned Depth) {
  if (!S || !S->InRegion || !P->getType()->isIntegerTy(1))
    return false;
  BasicBlock *PB = const_cast<BasicBlock *>(P->getParent());
  if (PB == S->Entry || !S->InRegion->count(PB))
    return false;
  SmallPtrSet<BasicBlock *, 8> SeenPreds;
  for (unsigned I = 0, N = P->getNumIncomingValues(); I != N; ++I)
    SeenPreds.insert(P->getIncomingBlock(I));
  if (SeenPreds.size() < 2)
    return false;
  for (unsigned I = 0, N = P->getNumIncomingValues(); I != N; ++I) {
    const Value *IV = P->getIncomingValue(I);
    if (isa<UndefValue>(IV))
      continue;  // frozen to i1 false by convertPhis before its grammar check.
    if (!isBooleanCondTree(IV, Depth + 1, S))
      return false;
  }
  if (S->Recorded)
    S->Recorded->insert(const_cast<PHINode *>(P));
  return true;
}

// E6 — a branch condition PredMux can take BOTH polarities of: a supported
// compare, an and/or tree over such conditions, an xor-true (not), an i1
// constant, or (Inc 5) a path-predicated i1 phi the flatten will convert. The
// false-edge literal is built by pushing the negation to the leaves (De
// Morgan), so every emitted predicate tree stays inside the 3c6m.12-cleared
// and/or-over-compare-leaves shape (the no-NOT invariant).
bool isSupportedCondTree(const Value *V, unsigned Depth,
                         const PhiCondScope *S = nullptr) {
  if (Depth > 8)
    return false;
  if (const auto *P = dyn_cast<PHINode>(V))
    return isConvertiblePhiCond(P, S, Depth);  // Inc 5 (bd q2wk)
  if (isa<ConstantInt>(V))
    return true;
  if (const auto *Cmp = dyn_cast<CmpInst>(V))
    return isSupportedCompareLeaf(Cmp);
  if (const auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (BO->getOpcode() == Instruction::And ||
        BO->getOpcode() == Instruction::Or)
      return isSupportedCondTree(BO->getOperand(0), Depth + 1, S) &&
             isSupportedCondTree(BO->getOperand(1), Depth + 1, S);
    if (BO->getOpcode() == Instruction::Xor)
      if (const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1)))
        if (C->isOne())
          return isSupportedCondTree(BO->getOperand(0), Depth + 1, S);
  }
  // bd adia: clang -O1's poison-shielded short-circuit forms —
  // `select i1 a, i1 b, false` (a && b) and `select i1 a, true, i1 b`
  // (a || b, the coshl `ex < K || (ex == K && mx < M)` exponent ladder). The
  // flatten canonicalizes them to plain and/or (see canonicalizePred), which
  // OBSERVES the shielded operand on basis states where the original select
  // did not — sound ONLY when that operand is provably DEFINED there. The
  // admissibility proof is coneDefinedAfterFlagDrop: every instruction in
  // the shielded operand's backward cone must be total once its
  // poison-generating flags/metadata are dropped (the drop happens in
  // stripPoisonCone at flatten time). Ops whose poison is INHERENT — a shift
  // by a runtime amount that may reach the bit width, the out-of-range
  // fp->int casts — have no flag to drop and fail the proof (the adia
  // Rule-13 board's inherent-poison note), leaving the region for the
  // existing loud declines.
  if (const auto *Sel = dyn_cast<SelectInst>(V)) {
    if (!Sel->getType()->isIntegerTy(1))
      return false;
    if (const auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue()))
      if (FC->isZero())
        return coneDefinedAfterFlagDrop(Sel->getTrueValue()) &&
               isSupportedCondTree(Sel->getCondition(), Depth + 1, S) &&
               isSupportedCondTree(Sel->getTrueValue(), Depth + 1, S);
    if (const auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue()))
      if (TC->isOne())
        return coneDefinedAfterFlagDrop(Sel->getFalseValue()) &&
               isSupportedCondTree(Sel->getCondition(), Depth + 1, S) &&
               isSupportedCondTree(Sel->getFalseValue(), Depth + 1, S);
  }
  return false;
}

// Inc 2 — the SUBSTRATE-grammar condition tree (a strict subset of
// isSupportedCondTree): compare leaves and distinct-operand `and i1`/`or i1`
// nodes only — no xor-true, no trunc/freeze/select, no compares OVER i1
// operands. This mirrors `collectCondTree` (SelectClassify.cpp) plus its
// self-operand and i1-operand-leaf fences, because an i1 phi converted to
// boolean algebra composes its incomings INTO a select condition the 3c6m.12
// flag-mint must accept verbatim. i1 constants are additionally admitted —
// they never reach the tree (the composer folds ∧true/∧false away). Anything
// off-grammar falls back to the Inc-1 select chain (same loud decline at the
// consuming select as today — posture unchanged).
//
// bd q2wk (Inc 5): with a `PhiCondScope` (the CLAIM-time caller only) a
// convertible i1 phi is also a node — a chained short-circuit
// (`phi i1 [ %p, %a ], [ false, %b ]` where `%p` is itself such a phi) must be
// admissible as a whole, because at EMIT time the inner phi has already been
// RAUW'd to its and/or tree and would pass this grammar anyway. Without a scope
// (the emit-time caller in `convertPhis`) the phi case is off and the grammar is
// byte-identical to Inc 2's.
bool isBooleanCondTree(const Value *V, unsigned Depth, const PhiCondScope *S) {
  if (Depth > 16)
    return false;
  if (const auto *C = dyn_cast<ConstantInt>(V))
    return C->getType()->isIntegerTy(1);
  if (const auto *P = dyn_cast<PHINode>(V))
    return isConvertiblePhiCond(P, S, Depth);  // Inc 5 (bd q2wk); null S ⇒ false
  if (const auto *Cmp = dyn_cast<CmpInst>(V))
    return isSupportedCompareLeaf(Cmp) &&
           !Cmp->getOperand(0)->getType()->isIntegerTy(1);
  if (const auto *BO = dyn_cast<BinaryOperator>(V))
    if (BO->getType()->isIntegerTy(1) &&
        (BO->getOpcode() == Instruction::And ||
         BO->getOpcode() == Instruction::Or))
      // Self-operand NODE fence — the mirror of `collectCondTree`'s (see the
      // corrected rationale there, SelectClassify.cpp: the original "no backend
      // can realize it" premise is RETRACTED — this is CASE A and the network is
      // already alias-correct — but the fence is KEPT as a scoped conservative
      // decline because the shape is reachable from neither -O1 C nor rail
      // aliasing). The LEAF axis carries no such fence, deliberately (bd big5).
      return BO->getOperand(0) != BO->getOperand(1) &&
             isBooleanCondTree(BO->getOperand(0), Depth + 1, S) &&
             isBooleanCondTree(BO->getOperand(1), Depth + 1, S);
  return false;
}

// E4 — one instruction of pure speculatable dataflow at template-supported
// widths. The ONLY memory op admitted is a const-global QROM READ (and its
// single-use address gep) via the taint-blind `qromReadShapeInScope` (bd 20xt.4
// Inc 2, blocker c) — a pure, side-effect-free load of an immutable table; every
// store/atomic/volatile-load excludes the region. ANY call other than a curated
// memory(none) intrinsic — including every @cq_* front-end intrinsic, so
// phase/value-rotation arms and 6.5 classical-call arms structurally stay with
// their shipped owners — excludes it too. NOTE the QROM-read cases are reached
// ONLY from the pending-spec pure-callee proof (`isSpeculatablePureCalleeBody`);
// `recoverRegion`'s E4 body walk handles load/gep by the STRICTER, taint-aware
// `classifyQromReadUnderControl` BEFORE it ever falls through to here.
//
// `AdmitI80Compare` (bd 3c6m.61) — THE PARAMETER EXISTS BECAUSE THIS PREDICATE
// HAS EXACTLY TWO CALL SITES THAT WANT DIFFERENT ANSWERS. Both are named here;
// keep this list in sync with `grep -n isSpeculatableDataflow` or it rots:
//
//   * `recoverRegion`'s E4 REGION-BODY walk passes `!ClaimAll` — an arm-resident
//     i80 compare enters the flattened SELECT PROGRAM of the region being
//     walked, and only the TOP-LEVEL substrate is reviewed for that. Clone mode
//     keeps the blanket exclusion (pinned: reject_i80_cmp_clonemode.ll).
//   * `isSpeculatablePureCalleeBodyImpl` passes TRUE (bd 3c6m.14.1). There the
//     predicate answers a DIFFERENT question — "is this callee a pure, total,
//     terminating function of its arguments?" — and an `icmp` is pure and total
//     at every width, so the width exclusion was never about that question. The
//     compare stays INSIDE the callee: it is lowered by the callee's own
//     Phase-6 clone, never by the caller's flatten. Stated precisely, because a
//     Rule-13 lens correctly rejected the first wording ("the pass does no
//     inlining"): the pass DOES have one body-splicer, `lowerByRefInline`
//     (ByRefInline.cpp), and it admits `isa<CmpInst>` at any width — but it runs
//     at CQLoweringPass.cpp step ~87, BEFORE the PredMux fixpoint at ~178, so it
//     cannot introduce callee instructions into a region after a claim.
//     Specialization's `CloneFunctionInto` only mints new functions. MEASURED in
//     every accepting probe: the original callee is byte-untouched in the output
//     and the caller's clone contains only the CALL. Its own lowering
//     obligation is discharged separately and it still declines when unmet
//     (reject_i80_cmp_purecallee_armdiamond.ll: the callee's OWN tainted diamond
//     hits the clone-mode `!ClaimAll` fence above and loud-declines).
//
// WHAT THE PURE-CALLEE `true` WIDENS — FOUR call paths as of bd 3c6m.14.2, and
// STATE THE COUNTING UNIT, because that is what a future agent re-derives and
// the previous unit was not uniform. There are THREE textual call sites plus one
// recursion; S1/S2 are the SAME site (:1812-ish) counted twice because its
// answer is context-sensitive (`ClaimAll` threaded from Specialization.cpp).
// Re-derive by grep over ALL of ir-pass/, never inherit the number — bd 3c6m.61's
// comment and bd memory [[predmux-shared-predicate-leak-3c6m61]] both said
// THREE and both were wrong:
//   S1 E4 CALL admission, top-level  (under !ClaimAll)
//   S2 E4 CALL admission, CLONE mode (same site under ClaimAll — the call site
//      has NO context gate; deliberately widened, see the note there)
//   S3 `isSpeculatablePureCallee` -> `Fp80Union.cpp`'s AdmitArgDerived seed cone
//   S5 the proof's own recursion — a clean outer callee over a compare-bearing
//      inner one.
// Each has a red-green fixture and each was measured to split against a pinned
// pre-change plugin before bd 3c6m.14.1 was written.
//
// *** S4 IS GONE — DELIBERATELY, AND IT IS THE POINT OF bd 3c6m.14.2. *** S4 was
// `coneDefinedAfterFlagDrop`'s shielded-cone CALL admission: this PURITY proof
// being used as a DEFINEDNESS proof, at a surface nobody had enumerated when the
// clause was widened. It produced a verify-clean silent miscompile (a Bennett
// clone returning literal poison as a qubit handle). The clause was DELETED
// rather than reinforced, because its measured population was empty. Do not
// re-add it: if a future ticket wants a call admitted in a shielded cone, the
// obligation is DEFINEDNESS OF THE RETURN VALUE on states the source shielded,
// which this predicate does not and cannot answer.
bool isSpeculatableDataflow(const Instruction &I, bool AdmitI80Compare = false) {
  // No vector lane and no non-template width anywhere — such an op would only
  // decline loudly post-flatten at lowerOps/castInScope; gate it here so a
  // claimed region can never half-lower (detect-before-mutate).
  if (I.getType()->isVectorTy())
    return false;
  for (const Value *Op : I.operands())
    if (Op->getType()->isVectorTy())
      return false;
  if (isa<PHINode>(I))
    return true;  // converted to a select chain, never moved as-is (E7 gates
                  // its type separately)
  if (isa<ICmpInst>(I) || isa<FCmpInst>(I)) {
    Type *OpTy = I.getOperand(0)->getType();
    if (OpTy->isPointerTy())
      return false;
    // i80 (bd 3c6m.61): the x86_fp80 bit-pattern compare — hypotl's
    // `manh == LDBL_NBIT && manl == 0` NaN test, which clang -O1 fuses into
    // `icmp eq i80 (and i80 %bits, 0xFFFF'FFFF'FFFF'FFFF), 0x8000'0000'0000'0000`
    // INSIDE the Inf/NaN arm. This is the shape the old blanket
    // `isTemplateWidthType` exclusion here declared impossible ("the canonical
    // promotion never puts those inside an arm") — a claim hypotl falsifies.
    //
    // ADMIT ONLY THE PROVABLY-`_hl` SHAPE (detect mirrors lower, Rule 12/13).
    // i80 ships the `_hl` compare row for all 10 predicates plus its `_inv`/
    // `_unc` twins. It ALSO ships a QQ row — so, precisely (this was measured;
    // an earlier draft of this comment named the wrong fence and a Rule-13 lens
    // caught it):
    //   * a Q+Q `icmp i80` in the DATA position LOWERS fine, straight through
    //     `lowerCompareImpl` to `cq_template_icmp_<pred>_i80`;
    //   * a Q+Q `icmp i80` used as a SELECT CONDITION cannot mint a flag —
    //     `qqSelectLeafWidth` (CompareLowering.cpp) fences `i80` out of the
    //     select-leaf grid — so a claimed region containing one would flatten
    //     and only THEN decline: verify-clean, loud, but POST-MUTATION, the
    //     detect-before-mutate half-lower the Inc-1 fp128 finding closed.
    // PredMux cannot cheaply tell those two positions apart pre-flatten (the
    // consuming select may not exist yet, and `valueWillTaintAfterFlatten`
    // makes a taint query unreliable here anyway), so ONE conservative gate
    // covers both: exactly one `ConstantInt` operand. That is TAINT-BLIND and
    // MONOTONE — a constant is never tainted, before or after the flatten, so
    // the `_hl` classification cannot drift. Admitting the data-position Q+Q
    // form would be a separate, deliberate widening (bd 3c6m.14.1); declining it
    // here is an over-decline, always safe.
    //
    // WHAT THIS DOES *NOT* EXCLUDE (stated because the natural reading is
    // wrong): a `Constant` that is not a `ConstantInt` — `undef`, `poison`, a
    // `ConstantExpr` — paired with a ConstantInt PASSES this test, and such a
    // compare is CLASSICAL, so the region is claimed and flattens before
    // declining downstream (`declineClassicalMuxes` / SelectClassify GATE-2).
    // That is NOT new and NOT i80-specific: `icmp i32` behaves identically
    // today and always has (measured, exact parity), and it is the residual
    // class PRD §4.4b already documents for classical leaves inside a tainted
    // region. Making i80 the ONE width that also fenced this would be
    // inconsistent, not safer.
    //
    // i80 `select`/`freeze` stay UNCLAIMED (`isTemplateWidthType` excludes
    // i80): a merged i80 value would need `cqrt_copy_i80_controlled`, which
    // does not exist. i80 as a BRANCH condition also stays unclaimed —
    // `isSupportedCompareLeaf` (E6's `isSupportedCondTree` leaf) is NOT
    // widened here; no measured cell needs it and over-declining a shape we
    // did not set out to build is correct (Rule 17).
    // The `!=` (exactly one ConstantInt) rather than `||` (at least one) IS
    // LOAD-BEARING, and the story of how that was established is worth keeping
    // because it is a methodology trap, not an i80 one.
    //
    // The bd 3c6m.14.1 arm-kill matrix flipped this to `||` — which changes
    // behaviour for the const/const shape ALONE, since Q+Q fails both spellings
    // — and the whole suite stayed green. The first explanation written here was
    // that the shape is unreachable, because `flattenPredMuxRegions` calls
    // `foldConstantConesInFunction(F)` and returns on any fold before
    // `recoverRegion` runs. *** THAT EXPLANATION IS FALSE AT THE PURE-CALLEE
    // CALL SITE, and two independent Rule-13 lenses falsified it with a run. ***
    // The folder is applied only to functions that CARRY TAINTED CONTROL, and
    // only to the function being flattened; `isSpeculatablePureCalleeBodyImpl`
    // walks the CALLEE's body, which pre-specialization has neither taint nor a
    // tainted terminator and is therefore never folded. The two probes behind
    // the wrong explanation were both written at the REGION walk — they could
    // not reach the site being defended, which is exactly the
    // probe-with-no-power failure bd memory
    // [[budget-in-a-memo-and-probes-with-no-power-2026-08-08]] is about.
    //
    // What the spelling actually buys, measured on both plugins: under `!=` the
    // proof fails AT THE COMPARE, nothing is claimed and nothing is mutated;
    // under `||` the region is claimed and FLATTENED and the clone is built,
    // and a different diagnostic fires from inside `@__cq_q_leaf_1` — a
    // POST-MUTATION decline, the detect-before-mutate class the Inc-1 fp128
    // finding closed. Pinned by
    // control_predmux_reject_i80_cmp_purecallee_constconst.ll.
    if (OpTy->isIntegerTy(80))
      return AdmitI80Compare && (isa<ConstantInt>(I.getOperand(0)) !=
                                 isa<ConstantInt>(I.getOperand(1)));
    return isTemplateWidthType(OpTy);
  }
  if (isa<SelectInst>(I) || isa<FreezeInst>(I))
    return !I.getType()->isPointerTy() && isTemplateWidthType(I.getType());
  if (const auto *UO = dyn_cast<UnaryOperator>(&I))
    return UO->getOpcode() == Instruction::FNeg &&
           isTemplateWidthType(UO->getType());
  if (const auto *CI = dyn_cast<CastInst>(&I)) {
    if (CI->getType()->isPointerTy() || CI->getSrcTy()->isPointerTy())
      return false;
    // i80 (bd 3c6m.51 Inc 3): the promoteFp80Union canonical extract/insert
    // ops (`bitcast f80<->i80`, `trunc i80 -> iN`, `zext iN -> i80`) land
    // INSIDE claimed arms (scalbnl's field-insert packs live in the normal/
    // subnormal arms). Gate them by `castInScope` ITSELF — the exact predicate
    // castInScope-lowering enforces — so detection mirrors lowering (bd 6-4)
    // and a claimed region still can never half-lower. Every other i80 cast
    // (sext, cross-domain) fails castInScope and leaves the region.
    if (CI->getType()->isIntegerTy(80) || CI->getSrcTy()->isIntegerTy(80))
      return castInScope(CI->getOpcodeName(), abiWidthFromType(CI->getSrcTy()),
                         abiWidthFromType(CI->getType()));
    return isTemplateWidthType(CI->getType()) &&
           isTemplateWidthType(CI->getSrcTy());
  }
  if (const auto *BO = dyn_cast<BinaryOperator>(&I)) {
    // i80 (bd 3c6m.51 Inc 3): admit exactly the four shipped i80 bitwise rows
    // (and/lshr/or/shl — the shared i80BinaryInScope, mirroring the
    // ArithLowering fence); add/sub/mul/xor/ashr/div/rem at i80 have no
    // template and leave the region (detect-before-mutate). NOTE the mirror is
    // one-directional by design elsewhere: select/freeze at i80 stay
    // conservatively UNCLAIMED here (isTemplateWidthType excludes i80) — a
    // merged i80 value has no `cqrt_copy_i80_controlled`. i80 `icmp` USED to
    // ride that same blanket over-decline on the claim that "the canonical
    // promotion never puts those inside an arm"; bd 3c6m.61 (hypotl's
    // `manh == LDBL_NBIT && manl == 0` NaN test) falsified it, so the icmp case
    // above now admits the provably-`_hl` (one-ConstantInt-operand) shape and
    // only that.
    if (BO->getType()->isIntegerTy(80))
      return i80BinaryInScope(binaryStem(BO->getOpcode()));
    if (!isTemplateWidthType(BO->getType()))
      return false;
    switch (BO->getOpcode()) {
    case Instruction::Add:
    case Instruction::Sub:
    case Instruction::Mul:
    case Instruction::And:
    case Instruction::Or:
    case Instruction::Xor:
    case Instruction::Shl:
    case Instruction::LShr:
    case Instruction::AShr:
    case Instruction::FAdd:
    case Instruction::FSub:
    case Instruction::FMul:
    case Instruction::FDiv:
    case Instruction::FRem:
      return true;
    case Instruction::UDiv:
    case Instruction::SDiv:
    case Instruction::URem:
    case Instruction::SRem: {
      // Speculating an integer division is UB on a zero divisor (and on
      // INT_MIN / -1 for the signed forms) — admit only the provably-safe
      // constant case (cbrt's hx/3). Anything else leaves.
      const auto *C = dyn_cast<ConstantInt>(BO->getOperand(1));
      if (!C || C->isZero())
        return false;
      if ((BO->getOpcode() == Instruction::SDiv ||
           BO->getOpcode() == Instruction::SRem) &&
          C->isMinusOne())
        return false;
      return true;
    }
    default:
      return false;
    }
  }
  // bd 20xt.4 Inc 2 (blocker c) — a const-global QROM read (and its single-use
  // address gep) is pure speculatable dataflow FOR THE PENDING-SPEC PURE-CALLEE
  // PROOF (`isSpeculatablePureCalleeBodyImpl`). The table is a `constant` global
  // (immutable) and the load has no side effect, so admitting it proves the
  // CALLEE BODY is a pure total terminating function — which is all that is
  // needed to hoist its CALL straight-line under quantum control (the callee's
  // OWN control flow stays intact after the hoist, so the read still executes
  // only on the in-bounds indices the source reaches; nothing is speculated OUT
  // of the callee here). The read's bounds/mask obligation is the CLONE's job:
  // when Phase-6 later flattens the clone body, the region walk's E4' LoadInst
  // case masks a NeedsMask index (`classifyQromReadUnderControl`). TAINT-BLIND
  // `qromReadShapeInScope` — the SAME structural shape the emitter's
  // `classifyQromRead` proves (Rule 14, carve/emit non-divergence) — because the
  // callee body is not in module taint (taint stops at the caller→callee
  // boundary). NOTE this case is unreachable from `recoverRegion`'s E4 walk
  // (which handles load/gep BEFORE its `isSpeculatableDataflow` fallthrough), so
  // it only widens the pure-callee proof, never the region flatten.
  if (const auto *LI = dyn_cast<LoadInst>(&I))
    return qromReadShapeInScope(LI);
  if (const auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
    if (GEP->hasOneUse())
      if (const auto *LU = dyn_cast<LoadInst>(GEP->user_back()))
        if (LU->getPointerOperand() == GEP && qromReadShapeInScope(LU))
          return true;  // the QROM read's address gep (the load re-checks shape).
    return false;
  }
  if (const auto *Call = dyn_cast<CallInst>(&I))
    // Curated pure keep-set intrinsics (fmuladd/fabs/copysign/sqrt/…) are
    // already first-class straight-line citizens of the pass; memory(none)
    // is required so nothing observable moves. (The bd adia pending-spec
    // pure-callee admit is handled at the REGION walk, where the tainted-arg
    // anti-overlap fence has taint in scope; inside a pure-callee proof the
    // inner-call case is handled by isSpeculatablePureCalleeBodyImpl itself.)
    return isCuratedReversibleIntrinsic(Call) && Call->doesNotAccessMemory();
  return false;
}

// bd adia (3c6m.55 Lever C): a direct call to a VISIBLE, acyclic, all-speculatable pure
// body — the pending-specialization callee under tainted control. Every block
// must end in br/ret, sit on no CFG cycle (termination), and every
// non-terminator instruction must itself be speculatable dataflow (phis
// included). Inner calls: curated memory(none) intrinsics, or — recursively —
// another body passing this same proof (the plain -O1 expl→floorl nesting);
// `OnStack` breaks call-graph cycles (a recursive callee has no termination
// bound → false).
//
// bd 3c6m.14.1: the per-instruction predicate runs with `AdmitI80Compare=true`.
// READ THAT AS A SCOPE STATEMENT ABOUT THIS FUNCTION, not as a general lift —
// what this proof asserts is purity/totality/termination, and `icmp` has all
// three at every width. Two call SITES ride this — the E4 call admission in
// both contexts (S1/S2) and S3 `Fp80Union`'s seed cone — plus the recursion
// below (S5); each has a fixture.
//
// bd 3c6m.14.2 — *** DO NOT READ THIS AS A DEFINEDNESS PROOF, AND DO NOT WIRE IT
// TO ONE. *** It asserts pure + total + terminating, and it gets there through
// `isSpeculatableDataflow`, which admits a variable-amount `shl/lshr/ashr` and
// `fptosi/fptoui` unconditionally; it also skips terminators, so a body of just
// `ret i32 poison` passes VACUOUSLY. `coneDefinedAfterFlagDrop` used to consume
// it (the deleted S4) and that was a verify-clean silent miscompile. The three
// surviving consumers are sound because they SPECULATE THE CALL into a program
// that already executed it — they never observe its RESULT on a state the source
// shielded, which is the strictly stronger obligation S4 carried and this
// predicate cannot discharge.
bool isSpeculatablePureCalleeBodyImpl(
    const Function *F, SmallPtrSetImpl<const Function *> &OnStack) {
  // hasExactDefinition: a body this proof reads must be the body that LINKS —
  // an INTERPOSABLE definition (weak_any/linkonce_any/common/extern_weak) may be
  // replaced by the linker, so a purity/termination proof over the module-local
  // body would be baked into the speculated hoist and the Bennett clone while a
  // different function runs at stage 3 (the adia Rule-13 board's confirmed fence
  // gap; the ByRefInline hasLocalLinkage precedent). NOTE (bd gxhi, empirically
  // verified against LLVM 19): `hasExactDefinition()` is `!isDeclaration() &&
  // !mayBeDerefined()`, and `mayBeDerefined()` is TRUE for weak_odr/linkonce_odr/
  // available_externally — so this predicate ALSO declines those ODR variants,
  // NOT only the arbitrary-replacement interposable set. That is a SAFE
  // over-decline (Prime Directive) with zero corpus cost (openlibm has no weak
  // symbols); admitting the ODR variants would be a deliberate `!isInterposable()`
  // widening, a separate ticket. Declarations fail here too.
  if (!F || !F->hasExactDefinition() || F->isVarArg())
    return false;
  if (!OnStack.insert(F).second)
    return false;  // call-graph cycle: termination unprovable
  auto pop = llvm::make_scope_exit([&] { OnStack.erase(F); });
  for (scc_iterator<const Function *> It = scc_begin(F); !It.isAtEnd(); ++It)
    if (It->size() > 1 || It.hasCycle())
      return false;  // a CFG cycle: termination unprovable
  for (const BasicBlock &BB : *F) {
    const Instruction *Term = BB.getTerminator();
    if (!isa<BranchInst>(Term) && !isa<ReturnInst>(Term))
      return false;
    for (const Instruction &I : BB) {
      if (I.isTerminator())
        continue;
      if (const auto *CI2 = dyn_cast<CallInst>(&I)) {
        if (isCuratedReversibleIntrinsic(CI2) && CI2->doesNotAccessMemory())
          continue;
        if (isSpeculatablePureCalleeBodyImpl(CI2->getCalledFunction(), OnStack))
          continue;
        if (::getenv("CQ_PREDMUX_DBG"))
          llvm::errs() << "CQ_PREDMUX_DBG: pure-callee " << F->getName()
                       << " fails at call: " << I << "\n";
        return false;
      }
      // bd 3c6m.14.1 — TRUE, deliberately, and it is the whole functional
      // change of that increment. See the `AdmitI80Compare` block on
      // `isSpeculatableDataflow` for why this question ("pure + total") is not
      // the region walk's question ("speculatable into THIS select program"),
      // and for the full S1..S5 list of what one `true` here widens.
      if (!isSpeculatableDataflow(I, /*AdmitI80Compare=*/true)) {
        if (::getenv("CQ_PREDMUX_DBG"))
          llvm::errs() << "CQ_PREDMUX_DBG: pure-callee " << F->getName()
                       << " fails at: " << I << "\n";
        return false;
      }
    }
  }
  return true;
}

bool isSpeculatablePureCalleeBody(const Function *F) {
  SmallPtrSet<const Function *, 8> OnStack;
  return isSpeculatablePureCalleeBodyImpl(F, OnStack);
}

// ---------------------------------------------------------------------------
// Region recovery
// ---------------------------------------------------------------------------

struct PredMuxRegion {
  BasicBlock *Entry = nullptr;   // block whose tainted terminator roots the claim
  BasicBlock *Merge = nullptr;   // immediate post-dominator of Entry
  SmallVector<BasicBlock *, 16> Topo;  // region blocks, topological, Entry first
  SmallPtrSet<BasicBlock *, 16> InRegion;
  // Inc 3 — claimable QROM reads whose index is NOT known-bits-provable but
  // whose pow2 table admits the `and idx, N-1` mask (QromClaim::NeedsMask);
  // the flatten rewrites each gep index before the speculation is final.
  // (load, table element count) pairs, captured at E4-analysis time
  // (detect-before-mutate: analysis decides, the flatten only executes).
  SmallVector<std::pair<LoadInst *, uint64_t>, 4> MaskLoads;
  // Inc 5 (bd q2wk) — the i1 phis the E6 claim PROVED convertible as
  // path-predicated branch-condition tree nodes (PRD §4.4b rule (A)).
  // `convertPhis` takes the boolean-algebra path for exactly these regardless
  // of its own grammar re-check, so claim and emit cannot diverge (a fall-back
  // select chain under a branch literal is a broken module, not a decline).
  // Populated during E6, i.e. AFTER W/E2/E3 and interleaved with E4/E7 — a
  // later `leave` discards the whole `PredMuxRegion` (one fresh `R` per
  // candidate terminator), so a partial record can never reach the flatten.
  SmallPtrSet<PHINode *, 8> BoolAlgPhis;
};

// Blocks that sit on any CFG cycle (any non-trivial SCC, or a self-loop).
// Self-contained (PredMux runs before lowerLoops and cannot lean on it).
void collectCycleBlocks(Function &F, SmallPtrSetImpl<BasicBlock *> &OnCycle) {
  for (scc_iterator<Function *> It = scc_begin(&F); !It.isAtEnd(); ++It) {
    const std::vector<BasicBlock *> &SCC = *It;
    bool Cyclic = SCC.size() > 1 || It.hasCycle();
    if (Cyclic)
      OnCycle.insert(SCC.begin(), SCC.end());
  }
}

// Kahn topological order of the region subgraph (edges into Merge ignored).
// Returns false on any anomaly (should be unreachable once E2/E3 hold).
bool topoOrderRegion(PredMuxRegion &R) {
  DenseMap<BasicBlock *, unsigned> InDeg;
  for (BasicBlock *B : R.InRegion)
    InDeg.try_emplace(B, 0);
  for (BasicBlock *B : R.InRegion)
    for (BasicBlock *S : successors(B))
      if (R.InRegion.count(S))
        ++InDeg[S];
  SmallVector<BasicBlock *, 16> Work;
  if (InDeg[R.Entry] != 0)
    return false;  // side edge into Entry from within the region: not SESE
  Work.push_back(R.Entry);
  while (!Work.empty()) {
    BasicBlock *B = Work.pop_back_val();
    R.Topo.push_back(B);
    for (BasicBlock *S : successors(B)) {
      if (!R.InRegion.count(S))
        continue;
      if (--InDeg[S] == 0)
        Work.push_back(S);
    }
  }
  return R.Topo.size() == R.InRegion.size();
}

// bd 20xt.5 (d) — the merge for an entry `E` whose STANDARD post-dominator is
// the PDT virtual root PURELY because some path from `E` reaches an
// `unreachable` block (a switch default `clang -O1` proved dead — e.g. atan2l's
// exhaustive quadrant `switch i32 %m` over a 2-bit sign pack, whose
// `default.unreachable` LLVM's PostDominatorTree treats as a SECOND function
// exit alongside `ret`, giving every switch-reaching block a virtual-root
// ipdom). `unreachable` is UB: no basis state with defined behaviour ever
// enters it (Rule 5 — the source ASSERTS the path is dead), so for
// post-dominance it is NOT a real exit. We recompute the immediate
// post-dominator over the CFG-VIEW where every `unreachable`-terminated block
// (and the edges into it) is removed and the `ret` blocks are the sole exits —
// exactly the "convert unreachable→br-merge then post-dominate" experiment, but
// as PURE ANALYSIS (no mutation; Rule 9 detect-before-mutate). Returns nullptr
// (→ leave; the caller keeps today's silent virtual-root bail) unless a single
// real merge exists — over-declining is safe (Prime Directive). Downstream E2
// (acyclic) / E3 (single-exit, now unreachable-tolerant) VALIDATE the returned
// merge structurally, so a wrong answer here can only LEAVE, never miscompile.
BasicBlock *mergeIgnoringUnreachable(BasicBlock *E) {
  auto isUnreach = [](BasicBlock *B) {
    return isa<UnreachableInst>(B->getTerminator());
  };
  if (isUnreach(E))
    return nullptr;
  // Forward-reachable node set from E, EXCLUDING unreachable blocks (edges into
  // an unreachable block are dropped — they are never taken).
  SmallVector<BasicBlock *, 32> Order;  // discovery order = a valid RPO seed.
  SmallPtrSet<BasicBlock *, 32> Nodes;
  Nodes.insert(E);
  Order.push_back(E);
  for (unsigned I = 0; I < Order.size(); ++I)
    for (BasicBlock *S : successors(Order[I])) {
      if (isUnreach(S))
        continue;
      if (Nodes.insert(S).second)
        Order.push_back(S);
    }
  // Exits = ret blocks with no in-Node successor. A non-ret node with NO
  // in-Node successor (all its successors were unreachable) is an off-pattern
  // dead-end → bail (over-decline). Multiple rets simply fail to reconverge and
  // yield a nullptr merge below (no virtual bottom needed — the intersection
  // excludes disjoint-exit suffixes on its own).
  DenseMap<BasicBlock *, unsigned> Idx;
  for (unsigned I = 0; I < Order.size(); ++I)
    Idx[Order[I]] = I;
  unsigned N = Order.size();
  auto inNodeSuccs = [&](BasicBlock *B, SmallVectorImpl<BasicBlock *> &Out) {
    for (BasicBlock *S : successors(B))
      if (Nodes.count(S))
        Out.push_back(S);
  };
  for (BasicBlock *B : Order) {
    SmallVector<BasicBlock *, 4> Succ;
    inNodeSuccs(B, Succ);
    if (Succ.empty() && !isa<ReturnInst>(B->getTerminator()))
      return nullptr;
  }
  // Iterative post-dominator SETS (BitVector over Nodes): PostDom(exit)={exit};
  // PostDom(B) = {B} ∪ ⋂_{S ∈ in-Node succ} PostDom(S). Fixpoint (small F).
  SmallVector<BitVector, 32> PD(N, BitVector(N, true));
  for (unsigned I = 0; I < N; ++I) {
    SmallVector<BasicBlock *, 4> Succ;
    inNodeSuccs(Order[I], Succ);
    if (Succ.empty()) {  // an exit (ret): post-dominated only by itself.
      PD[I].reset();
      PD[I].set(I);
    }
  }
  bool Changed = true;
  while (Changed) {
    Changed = false;
    for (unsigned I = 0; I < N; ++I) {
      SmallVector<BasicBlock *, 4> Succ;
      inNodeSuccs(Order[I], Succ);
      if (Succ.empty())
        continue;  // exit: fixed.
      BitVector Meet(N, true);
      for (BasicBlock *S : Succ)
        Meet &= PD[Idx[S]];
      Meet.set(I);  // {B} ∪ ⋂
      if (Meet != PD[I]) {
        PD[I] = std::move(Meet);
        Changed = true;
      }
    }
  }
  // ipdom(E) = the member of PostDom(E)\{E} with the LARGEST post-dom set
  // (post-dominators form a strict chain E ≺ D1 ≺ … ≺ ret, and PostDom(D1) ⊋
  // PostDom(D2) ⊋ …, so D1 — the immediate one — has the max popcount). Empty
  // ⇒ no reconvergence before exit ⇒ nullptr.
  unsigned EI = Idx[E];
  int Best = -1;
  unsigned BestPop = 0;
  for (unsigned J = PD[EI].find_first(); J != (unsigned)-1;
       J = PD[EI].find_next(J)) {
    if (J == EI)
      continue;
    unsigned Pop = PD[J].count();
    if (Best < 0 || Pop > BestPop) {
      Best = (int)J;
      BestPop = Pop;
    }
  }
  return Best < 0 ? nullptr : Order[Best];
}

// The full E-ladder. Pure analysis; returns false to LEAVE (never diagnoses).
bool recoverRegion(Instruction *T, PostDominatorTree &PDT, DominatorTree &DT,
                   LoopInfo &LInfo, const SmallPtrSetImpl<BasicBlock *> &OnCycle,
                   const TaintSet &Taint, PredMuxRegion &R, bool ClaimAll) {
  BasicBlock *E = T->getParent();
  auto *Node = PDT.getNode(E);
  BasicBlock *Mg = nullptr;
  if (Node && Node->getIDom() && Node->getIDom()->getBlock()) {
    Mg = Node->getIDom()->getBlock();  // standard path — byte-identical today.
  } else {
    // bd 20xt.5 (d) — virtual-root ipdom (an `unreachable`/non-returning exit
    // poisons post-dominance). Retry the merge ignoring unreachable exits. This
    // path fires ONLY where today's code silently bailed (return false above):
    // a standard-ipdom region can NEVER contain a reachable `unreachable` block
    // (a successorless block reachable from E without crossing Mg would
    // contradict Mg post-dominating E), so BOTH this recompute and the E3
    // `UnreachableInst` tolerance are dead code on the standard path. Hence every
    // existing ACCEPT and every real-ipdom DECLINE is byte-identical; the ONLY
    // behaviour change is the virtual-root decline subset, where an
    // unreachable-poisoned region may now flatten (fully E-ladder-gated) — the
    // intended feature — or still leave. (The helper also runs on non-unreachable
    // virtual roots — infinite loops, disjoint multi-ret — but E2 declines the
    // former and `mergeIgnoringUnreachable` returns nullptr for the latter.)
    Mg = mergeIgnoringUnreachable(E);
    if (!Mg)
      return false;
  }
  // bd adia debug lever (env-gated, byte-neutral). CONTRACT (bd oudq): the
  // `gate=<name>` string and the named `entry=`/`merge=` blocks ARE pinned by
  // fixtures (`ir-pass/test/control_predmux_leave_w6_*.ll` check them through
  // `env CQ_PREDMUX_DBG=1 … --check-prefix=DBG`), so renaming a gate is not a
  // byte-neutral cleanup. The trailing `at: <instruction>` operand is NOT
  // contractual and must never be pinned — its SSA slot numbers are unstable
  // run-to-run even for one unchanged plugin (measured on slice_libm_real_coshl:
  // three runs, three different slot numbers, identical lowered IR).
  auto leave = [&](const char *Why, const Instruction *At = nullptr) {
    if (::getenv("CQ_PREDMUX_DBG")) {
      llvm::errs() << "CQ_PREDMUX_DBG: leave @" << E->getParent()->getName()
                   << " entry=" << E->getName() << " merge=" << Mg->getName()
                   << " gate=" << Why;
      if (At)
        llvm::errs() << " at: " << *At;
      llvm::errs() << "\n";
    }
    return false;
  };

  // Collect region blocks: everything reachable from E without crossing Mg.
  R.Entry = E;
  R.Merge = Mg;
  R.InRegion.insert(E);
  SmallVector<BasicBlock *, 16> Work(succ_begin(E), succ_end(E));
  while (!Work.empty()) {
    BasicBlock *B = Work.pop_back_val();
    if (B == Mg || !R.InRegion.insert(B).second)
      continue;
    Work.append(succ_begin(B), succ_end(B));
  }

  // --- W: claim witnesses (anti-overlap with the shipped emitters) ---------
  bool NestedTainted = false;
  for (BasicBlock *B : R.InRegion) {
    if (B == E)
      continue;
    const Instruction *Term = B->getTerminator();
    if ((isa<BranchInst>(Term) && cast<BranchInst>(Term)->isConditional()) ||
        isa<SwitchInst>(Term))
      if (isTaintedCtrlTerm(Term, Taint))
        NestedTainted = true;
  }
  unsigned NumMergePhis = 0;
  unsigned SolePhiIncomings = 0;
  const PHINode *SoleMergePhi = nullptr;
  for (const PHINode &P : Mg->phis()) {
    ++NumMergePhis;
    SolePhiIncomings = P.getNumIncomingValues();
    SoleMergePhi = &P;
  }
  // W4 (Inc 3) — a claimable const-global QROM read inside an arm is its own
  // claim witness: no shipped owner accepts a load-bearing arm (ArmClassify's
  // walkValueChain breaks on LoadInst; the 4.5 data-mux is all-ConstantInt),
  // so claiming the flat read-mux diamond (exp's `ln2HI[xsb]`, the folded
  // jumptable) steals nothing (anti-overlap preserved).
  bool ClaimableRead = false;
  for (BasicBlock *B : R.InRegion) {
    if (B == E)
      continue;
    for (Instruction &I : *B)
      if (auto *LI2 = dyn_cast<LoadInst>(&I))
        if (classifyQromReadUnderControl(LI2, Taint, DT, LInfo,
                                         /*OutCount=*/nullptr,
                                         &R.InRegion) != QromClaim::No) {
          ClaimableRead = true;
          break;
        }
    if (ClaimableRead)
      break;
  }
  bool Claim = false;
  if (isa<SwitchInst>(T)) {
    // Straight-line-arm switches are 4.5 territory (route/value/data-mux/
    // eq-fold) — claim only when an arm hosts further tainted control (or a
    // claimable read, which 4.5 never accepts).
    Claim = NestedTainted || ClaimableRead;
  } else {
    // W5 (bd vyqi) — a br-rooted flat region whose merge holds EXACTLY ONE
    // 2-incoming SCALAR-FP (muxable) phi with DISTINCT incomings: the
    // distilled log10l `z` accumulator diamond/triangle the zco4 promotion
    // exposed. No shipped owner ever ACCEPTS this shape — ArmClassify's 4.2
    // value path categorically declines an fp-typed merge (the fp-angle
    // fence), and every fp-merge shape the swap-route owners DO accept
    // (phase arms, the eq-fold and a8c0 re-anchor diamonds) holds a
    // `cq_phi`/`cq_theta` CALL inside an arm, which E4 excludes from any
    // PredMux claim; the 6.5 classical-call arm is i32-only. The
    // distinct-incomings fence keeps the degenerate empty-arm identity phi
    // (`phi [%q,%arm],[%q,%entry]`, an ACCEPTED empty phase arm) with its
    // owner. INTEGER sole-phi diamonds are not claimed HERE — the 4.2 value
    // emitter owns their accepts (routed method-B), and the two-base integer
    // mux stays the owner-declined 65wb.5 surface; W7 below claims the ONE
    // integer subset that provably has no such owner (a `ConstantInt`
    // straight-through, which no accept path can match). So W5
    // claims only currently-DECLINING shapes: containment (every existing
    // accept byte-identical) holds by construction, and the flattened
    // select is adjudicated by the kjd1 six-gate ladder (angle fence,
    // stale-condition wire guard, phase-carrier/downstream-rotation
    // declines) exactly like every other PredMux-minted select.
    const bool FpSolePhiMux =
        NumMergePhis == 1 && SolePhiIncomings == 2 && SoleMergePhi &&
        SoleMergePhi->getType()->isFloatingPointTy() &&
        isMuxableType(SoleMergePhi->getType()) &&
        SoleMergePhi->getIncomingValue(0) != SoleMergePhi->getIncomingValue(1);
    // W7 (bd 0rwu) — the CONST-FALLTHROUGH INTEGER sole-phi diamond: a flat br
    // region whose merge holds EXACTLY ONE 2-incoming muxable INTEGER phi with
    // DISTINCT incomings, whose ENTRY-edge incoming is a `ConstantInt`, and whose
    // other incoming is an instruction defined in a region INTERIOR block. This
    // is the fdlibm `__isnanl` tail — `s_isnan.c:63`'s
    // `exp == 32767 && (manl != 0 || manh != 0)` short-circuit, which at the f80
    // ship floor is `%isnan = phi i32 [ 0, %entry ], [ %zext, %arm ]` — and it is
    // the ONLY multi-cell compiler lever left in the libm injection census
    // (`expl.f80` + `log10l.f80`), and both reach `opt` exit 0 once the diamond is
    // flattened. MEASURED 2026-07-30 by re-running the full census under both
    // plugins and diffing CELL BY CELL: exactly 2 of the 123 cells changed status,
    // zero regressed. Do NOT restate that as "only 2 cells decline-anchor at
    // ArmClassify.cpp:1171, so the radius is 2" — the Rule-13 round showed that
    // inference is unsound (W7's predicate says nothing about a decline anchor;
    // a W7-shaped diamond declining `non-routable value multiplexer` moves too),
    // and the census bounds the census alone: three committed e2e goldens also
    // moved by claim-order churn, which only the e2e layer surfaced. The gap was never the merge MECHANICS
    // but only the `br`-CFG SPELLING of them: write the SAME two-base integer mux
    // as a tainted `select` and the 4.4/kjd1 controlled-XOR copy merge has lowered
    // it since kjd1. The Rule-13 round made that concrete rather than plausible —
    // it built the `select` spelling of the value-arm fixture's program and the
    // lowered gate stream is IDENTICAL instruction-for-instruction to the
    // flattened `br` spelling's, so a PredMux claim is exactly the missing
    // adapter and W7 reuses the cleared substrate verbatim.
    // (An earlier draft justified this by claiming the same idiom "arrives as a
    // `select` in `nexttowardf` because it fits SimplifyCFG's one-instruction
    // speculation budget". That is FALSE and was refuted in the Rule-13 round:
    // `ld80/s_nexttowardf.c` never calls `isnan` at all — it hand-writes the NaN
    // test as `(iy >= 0x7fff && ((hy|ly) != 0))`, one `or` plus one `icmp`, a
    // DIFFERENT idiom from `__isnanl`'s two OR-ed compares. Do not reinstate it.)
    //
    // W5 above deliberately claimed only the SCALAR-FP sole-phi diamond and left
    // every INTEGER one to the 4.2 value emitter, which owns their accepts. W7
    // re-admits only the subset no shipped `br` owner CAN accept, and — as with
    // every other witness — that disjointness is BY CONSTRUCTION out of
    // `ArmClassify::classifyArms`, not by measurement. Its `Routed` for a diamond
    // is exactly `StraightThrough`, the ENTRY-edge merge incoming, which clause
    // (c) pins to a `ConstantInt`:
    //   * the 4.2 VALUE path requires `Chain.Base == Routed`, but `walkValueChain`
    //     threads only the TAINTED operand of a tainted `BinaryOperator`, so
    //     `Chain.Base` is always a tainted value and never a `ConstantInt` — the
    //     region declines `non-routable value multiplexer`;
    //   * the 4.1 PHASE path requires `Base == Routed` where
    //     `Base = walkPhaseSpine(ArmIncoming, ArmBB)`, and that walk steps ONLY
    //     through IN-ARM `cq_phi_*` calls, which E4 excludes (an external
    //     declaration fails the pure-callee proof). Under clause (d) `Base` is the
    //     interior instruction itself, never a `ConstantInt`;
    //   * `straightThroughConstFoldHandle` (a8c0) is the ONLY path that accepts a
    //     `ConstantInt` straight-through at all, and it demands `H == Base` where
    //     `H` is the non-constant operand of the ENTRY block's equality condition
    //     — hence defined in the entry or earlier, NEVER in an interior block.
    //     *** CLAUSE (d) IS LOAD-BEARING FOR THE *EMPTY*-ARM ROW, WHERE NOTHING
    //     ELSE COVERS IT. *** An a8c0 EMPTY arm (`phi [k, E], [%q, arm]`, arm a
    //     bare `br`) holds no call for clause (e) and nothing for E4 to reject,
    //     and it satisfies (a)-(c) — so without (d) this clause would STEAL A
    //     SHIPPED ACCEPT; measured, that shape compiles today. Pinned from that
    //     side by control_predmux_leave_int_diamond_constfall_prereg.ll. The
    //     NON-empty a8c0 arm and the 4.5 `tryEqFoldArm` twin hold an in-arm
    //     `cq_phi` CALL and are fenced by clause (e)
    //     (control_swap_straightthrough_constfold.ll). Note for whoever edits
    //     this: the Rule-13 round measured that those rows' W7 witness DOES fire,
    //     i.e. they were relying on a single fence, which is why (e) exists and
    //     does not defer to E4;
    //   * the 4.2 IF/ELSE value accept anchors `Routed` on arm 1's chain
    //     PRECISELY BECAUSE it has no entry-edge phi incoming — clause (b)'s
    //     `getBasicBlockIndex(E) >= 0` excludes it (and the pre-existing
    //     control_predmux_leave_int_diamond_solephi.ll pins that direction);
    //   * every CALL-BASED owner — the 6.5 classical-call arm, a bd-adia
    //     pending-specialization call, `lowerControlledIOSinks`' sink call,
    //     `classifyAbortPark`'s noreturn call, and the a8c0 / 4.5 `tryEqFoldArm`
    //     NON-empty arms' in-arm `cq_phi` — is fenced by clause (e) below, WHICH
    //     DOES NOT DELEGATE TO E4. An earlier draft claimed E4 fenced them
    //     ("admits a call only with >= 1 TAINTED argument"); the Rule-13 round
    //     REFUTED that with a reproducer, because E4's first call clause is
    //     taint-blind for curated readnone intrinsics. See clause (e);
    //   * `classifyGuardedStoreArm` needs a STORE, which E4 genuinely does reject
    //     (`isSpeculatableDataflow` is false for a `StoreInst`); `classifyAbortPark`
    //     additionally needs an `unreachable` arm, which leaves `preds(Mg) = {E}`
    //     so no 2-incoming merge phi exists at all, failing clause (a).
    // Switch owners are unreachable from this `br` arm of the witness, and E2
    // excludes every loop owner. So W7, like every other witness, claims only
    // shapes that decline today — with ONE deliberate exception recorded in
    // control_predmux_accept_straightthrough_value_arm.ll: the a8c0 VALUE-arm sibling
    // (`if (q != 0) q1 = q + 1` merged against the folded literal) was an
    // OVER-decline, and it now flattens and lowers. That is a real accept-surface
    // widening inside W7's own shape class, not a leak: the §3c clobber hazard
    // that motivated its decline is a SWAP-ROUTE hazard (route the register in,
    // rewrite it in place, then strip a flag that must re-read the same basis),
    // and the flattened form never rewrites `%q` at all — it writes a FRESH out
    // rail and strips against the untouched `%q`. The Rule-13 round strengthened
    // that from an inspection of one region to a STRUCTURAL fact: E4's region-body
    // walk admits only pure speculatable dataflow (a `StoreInst` fails
    // `isSpeculatableDataflow`; `cq_phi`/`cq_theta` are external declarations that
    // fail the pure-callee proof; every `cq_template_*` is out-of-place), so NO
    // W7-claimed region can write ANY pre-existing rail — the flag-strip operand
    // cone is untouched by construction, for the whole witness class.
    //
    // MEASURED CLAIM-ORDER CHURN — 3 committed e2e goldens moved, and they were
    // REGENERATED DELIBERATELY (bd `8dwo` class; never regenerate a golden by
    // reflex, Rule 12). `slice_libm_real_{erfl,erfcl,sinhl}` inline `olm_expl`
    // ALWAYS_INLINE, so `expl`'s `__isnanl` diamond lands at top level in each and
    // W7 now claims it. Before W7 those regions were LEFT at `W-witness`
    // (measured: erfl left 15 such regions; with W7, ZERO remain) and were then
    // absorbed into a LARGER enclosing `NestedTainted` claim on a later fixpoint
    // round, whose whole-nest edge-predicate algebra is far more expensive than
    // flattening the inner diamonds first. Result: each trace got ~300 lines
    // SHORTER (2480→2182, 2686→2374, 2703→2447). The change was adjudicated, not
    // assumed — for all three: `opt` exit 0, verify-clean, deterministic, ZERO
    // residual `@cq_*`, stage 2b STRICT pass, Rule 5 intact (1 `cqrt_ry_f80` + 1
    // `cqrt_measure_f80`), every compare-stem delta PAIRED with its `_unc` strip,
    // ZERO `cqrt_cswap` in BOTH streams (so no 4.2 method-B accept existed to
    // steal), IDENTICAL `cqrt_copy_{i32,f80}_controlled` counts (same data muxes),
    // and — the decisive check — ZERO arithmetic/data stems differing: every
    // changed stem is flag/conjunction machinery (compare mints+strips,
    // `cqrt_alloc_i1`, `cqrt_toffoli`, `cqrt_cnot`, `cqrt_free`). The computation
    // is byte-identical; only the control ENCODING got cheaper. `coshl` is
    // deliberately unaffected because its `olm_expl` is plain `static` and rides
    // the Phase-6 clone + `claimAll` path instead.
    //
    // *** i1 IS DELIBERATELY EXCLUDED — this is a SCOPE fence, not a soundness
    // one, and it is measured. *** The anti-overlap argument above is
    // width-independent, and an i1 sole-phi const-fallthrough diamond is a real
    // shape (the f64 spelling of this very `__isnanl` tail is
    // `phi i1 [ false, %entry ], [ %lo, %chk ]`). Admitting it is nonetheless
    // wrong for THIS increment on two measured grounds. (1) PAYOFF: zero. The
    // census's f64/f32 isnan prologues already compile; re-measured 2026-07-30,
    // admitting i1 moves no cell that i32 does not already move. (2) COST: i1
    // merge phis are W6's OWN design territory — W6 exists precisely to claim an
    // i1 merge phi that strands a downstream cond tree — so an i1 W7 claim makes
    // two witnesses race for the same region in the most silent-miscompile-prone
    // file in the project. Measured, it CLAIMED the upstream diamond in all four
    // `control_predmux_leave_w6_*` fixtures, which still declined (no
    // over-accept) but with a different string, destroying the "left at
    // `gate=W-witness`" observable those pins are built on — i.e. it would have
    // cost four W6 pins to buy nothing. Claim-order churn of exactly the bd
    // `8dwo` kind, and here it is NOT in the favourable direction. Whoever lifts
    // this must re-pin the W6 family on a different observable first.
    // KNOWN RESIDUAL, filed as bd `tzfg` and deliberately NOT fixed here:
    // `isMuxableType` admits ANY integer width <= 64, but the runtime family is
    // only `cqrt_copy_i{1,8,16,32,64}_controlled`. So an off-family width (i24,
    // i48, ...) CLAIMS, the flatten rewrites the CFG, and the emitter only then
    // declines — which contradicts the E4 width gate's own "a claimed region can
    // never half-lower" comment. Measured harmless (`opt` exit 1, ZERO module
    // bytes written on a DS_Error, so the user sees a plain loud decline), and
    // PRE-EXISTING: the W5 fp path shares the helper. Left to its own increment
    // because a fix moves W5's claim surface too and needs its own Rule-12 pair.
    bool IntConstFallthroughMux = false;
    if (NumMergePhis == 1 && SolePhiIncomings == 2 && SoleMergePhi &&
        SoleMergePhi->getType()->isIntegerTy() &&
        !SoleMergePhi->getType()->isIntegerTy(1) &&
        isMuxableType(SoleMergePhi->getType()) &&
        SoleMergePhi->getIncomingValue(0) != SoleMergePhi->getIncomingValue(1)) {
      // (b) DIAMOND: the merge is a direct successor of the entry, so the phi
      // carries an entry-edge incoming — `ArmClassify`'s `StraightThrough`.
      const int EIdx = SoleMergePhi->getBasicBlockIndex(E);
      // (c) that incoming is a `ConstantInt` — the whole disjointness argument.
      if (EIdx >= 0 && isa<ConstantInt>(SoleMergePhi->getIncomingValue(EIdx))) {
        // (d) the other incoming is defined in a region INTERIOR block. A
        // degenerate `br i1 %c, label %Mg, label %Mg` leaves BOTH incoming
        // blocks equal to `E`, so `getParent() != E` rejects it here too (and
        // `R.InRegion == {E}` rejects it independently).
        auto *OtherI = dyn_cast<Instruction>(
            SoleMergePhi->getIncomingValue(EIdx == 0 ? 1 : 0));
        IntConstFallthroughMux = OtherI && OtherI->getParent() != E &&
                                 R.InRegion.count(OtherI->getParent()) != 0;
        // (e) NO CALL anywhere in the region INTERIOR — the anti-overlap fence
        // for every CALL-BASED owner, and it must NOT be delegated to E4.
        //
        // *** THIS CLAUSE EXISTS BECAUSE THE RULE-13 ROUND REFUTED THE FIRST
        // DRAFT'S CONTAINMENT ARGUMENT WITH A WORKING REPRODUCER. *** That draft
        // fenced the 6.5 classical-call arm by claiming "E4 admits a call only
        // with >= 1 TAINTED argument". E4 does no such thing: its call handling
        // (see `isCuratedReversibleIntrinsic(CI) && CI->doesNotAccessMemory()`
        // below) has a FIRST, TAINT-BLIND clause that admits any curated readnone
        // intrinsic — `bswap bitreverse fshl fshr ctpop ctlz cttz abs
        // smin smax umin umax *_sat lrint llrint` + the fp keep-set — regardless
        // of its arguments' taint. An ALL-CLASSICAL curated intrinsic in the arm
        // is EXACTLY `classifyClassicalCallArm`'s admission criterion, so without
        // this clause W7 and the 6.5 owner both claim it and W7 wins: measured on
        // `if (q > 5) y = llvm.smax(x, 11);` merged against a folded literal, both
        // plugins exit 0 but emit DIFFERENT streams (inverted flag predicate,
        // swapped copy order) — a trace-observable stolen accept. Every shipped
        // 6.5 accept fixture already satisfies (a)-(d) and survives only because
        // its callee is an external `declare`; swap one for `@llvm.bswap.i64` and
        // the theft reproduces. Two further decline->accept flips rode the same
        // hole: the 6.5 WI-5.8 arm-size fence (`Region.Arm->size() != 2`, which
        // deliberately declines a larger arm because the flatten would ERASE the
        // extra instruction) was bypassed, reachable from ordinary C at -O1 via
        // `if (q > 5) y = __builtin_popcountll(t);`; and a bd-adia
        // pending-specialization call as the arm's merge value flipped to an
        // accept that routes quantum data through a Phase-6 Bennett clone.
        // No wrong unitary was found in any of them — but a stolen accept is a
        // silent GOLDEN divergence and a scope widening past this increment's
        // reviewed surface, and the Prime Directive says narrow.
        //
        // Interior-only is the right scope: `E`'s instructions are never
        // speculated or erased, and `classifyClassicalCallArm` requires its call
        // in the ARM. This subsumes what the draft wrongly attributed to E4 — the
        // a8c0 / 4.5 `tryEqFoldArm` NON-empty arms (an in-arm `cq_phi` CALL,
        // whose W7 witness genuinely does fire, so E4 was their single point of
        // failure), `lowerControlledIOSinks`' sink call, and `classifyAbortPark`'s
        // noreturn call — and it costs the target cells nothing: `__isnanl`'s arm
        // is `and`/`icmp`/`or`/`zext`, call-free by construction.
        if (IntConstFallthroughMux)
          for (BasicBlock *B : R.InRegion) {
            if (B == E)
              continue;
            for (Instruction &I : *B)
              if (isa<CallInst>(&I)) {
                IntConstFallthroughMux = false;
                break;
              }
            if (!IntConstFallthroughMux)
              break;
          }
      }
    }
    // W6 (bd oudq) — the MERGE block's own TAINTED conditional branch reads one
    // of the merge's i1 phis as an and/or cond-tree NODE. That downstream region
    // (rooted at `Mg`) can NEVER be claimed while the phi lives: rule (A)
    // condition 2 refuses a phi whose parent is the region ENTRY, because
    // `RegionFlattener::run()` skips the entry — so `isSupportedCondTree` cannot
    // build its false-edge literal and it leaves at `E6-condtree` forever
    // (nothing else in the pipeline removes an entry phi). Claiming THIS region
    // is the fix: the phi is a MERGE phi here, `convertPhis(R.Merge)` rewrites it
    // to the Inc-2 boolean algebra ∨ᵢ(EPᵢ ∧ vᵢ), and the downstream branch becomes
    // an ordinary cond tree over compare leaves on the next fixpoint round. This
    // is the fdlibm `__isnanl` early-exit chain — `s_isnan.c:63` inlined, which
    // at the log1pl.f80 ship floor is `%16 = phi i1 [ false, %0 ], [ %14, %10 ]`
    // OR-ed into `isinf || iszero` in that same block — and it is what blocks
    // log1pl/log2l/logl.f80.
    //
    // ANTI-OVERLAP (the W witness' whole job) holds by construction, not by
    // measurement: a br region whose MERGE ends in a tainted conditional branch
    // is categorically DECLINED by every shipped br owner. `ControlDetect`'s
    // `recoverRegion` tests `hasTaintedCondBranch` on BOTH successors before any
    // shape match — and a diamond's merge IS a successor of the entry — then
    // repeats the test explicitly on the if/else merge `M`; either way it returns
    // `RegionShape::Nested`, and `recoverRegionTree` declines it too — as a
    // PROOF, not a shape observation (the Rule-13 judge's strengthening):
    // `isConvertiblePhiCond` demands ≥ 2 UNIQUE incoming blocks, so W6 can only
    // fire when `Mg` has ≥ 2 predecessors, and the merge-as-`Mid` candidate's
    // `getSinglePredecessor()` is therefore structurally null. When no interior
    // block carries a tainted branch it declines one criterion earlier still, at
    // `T0 == T1` — what that function's own comment calls the "sequential
    // if/else; if" case. The same ≥ 2-predecessor fact makes W6 disjoint from the
    // abort park by construction: an `unreachable` arm leaves `preds(Mg) = {E}`,
    // so no merge phi can have two unique incoming blocks at all.
    // `classifyAbortPark` and `classifyGuardedStoreArm` run BEFORE
    // `recoverRegion` and require a noreturn-sink CALL / a STORE, neither of
    // which E4 admits; `classifyClassicalCallArm` runs AFTER it, i.e. only on a
    // Diamond/IfElse whose merge `recoverRegion` has already proven does NOT end
    // in a tainted cond branch. The two tainted-`br` owners OUTSIDE that family
    // are fenced independently, and by something other than this witness (both
    // verified by probe in the same round): `lowerControlledIOSinks` needs its
    // arm's recognized SINK CALL, which E4 excludes (a declaration fails the
    // pure-callee proof); and a loop-header merge always has a latch predecessor
    // outside the region, so the region leaves at `E3-mergepred` — AFTER this
    // witness, not before it (two delta lenses caught an earlier draft asserting
    // the opposite ordering; the conclusion is unaffected because the whole
    // E-ladder runs before anything is emitted, but this file is the primary
    // written record). So W6 claims only shapes that decline today.
    // DELIBERATELY NARROW: gated on the phi actually CONVERTING to boolean
    // algebra (a select-chain phi would leave the downstream branch just as
    // unclaimable) and on the phi being read at a cond-tree NODE (an i1 phi
    // behind an `icmp` is an opaque leaf that never stranded anything). NOTE what
    // that does and does not buy (Rule-13 lens 7, with a reproducer): it removes
    // the reason the downstream branch is UNUSABLE, but it does not make the
    // downstream region claimable — that region may still leave on its own
    // W-witness, in which case the only visible change is which decline fires.
    // Claim-order churn of exactly the bd `8dwo` kind is therefore possible here;
    // measured, it is in the favourable (shorter-stream) direction.
    //
    // HOW THE STRANDING IS TESTED — by asking the DOWNSTREAM question itself,
    // not a proxy for it (bd oudq Rule-13, lens 3: the first draft used a
    // hand-rolled tree walk that was strictly more permissive than
    // `isSupportedCondTree` — general `select i1`, off-grammar SIBLINGS, no
    // `coneDefinedAfterFlagDrop`, its own depth budget — and measurably fired
    // ~7:1 against the one stranding it exists to unblock, churning three
    // already-verified goldens for nothing). Run the SHIPPED predicate twice
    // over `Mg`'s branch condition, with scopes that differ in exactly one
    // thing — whether a phi of `Mg` counts as convertible:
    //   * `Convertible` (no entry fence): does the condition become a supported
    //     cond tree once this claim converts `Mg`'s phis?
    //   * `Downstream` (entry fence = `Mg`, i.e. the scope the region rooted at
    //     `Mg` will build for itself): is it supported WITHOUT that conversion?
    // `Convertible && !Downstream` therefore says precisely "a phi of `Mg` is
    // what makes the downstream condition unusable, and converting it is what
    // makes it usable" — Rule 14, one question with one answer, so the claim
    // cannot drift from the E6 gate it is predicting. Everything the old walk
    // over-admitted collapses out: a non-phi off-grammar node fails BOTH calls,
    // a phi behind an `icmp` (the q2wk shield) passes BOTH, and a phi whose
    // incomings leave the strict `isBooleanCondTree` grammar — i.e. one
    // `convertPhis` would send down its select-CHAIN path — fails the first.
    //
    // *** THE `BranchInst` TEST BELOW IS LOAD-BEARING, NOT A CONVENIENCE. *** The
    // anti-overlap argument rests on `ControlDetect`'s `hasTaintedCondBranch`,
    // which is `dyn_cast<BranchInst>` + `isConditional()` + tainted — it is FALSE
    // for a block ending in a tainted `switch`. Generalizing this to the
    // switch-aware `isTaintedCtrlTerm` (used one screen up, so the edit looks
    // harmless) would silently void the whole paragraph above: a merge ending in
    // a tainted switch is 4.5 `SwitchClassify` territory, NOT a categorical
    // decline. That shape is a deliberate residual, filed as bd `ih70`.
    bool StrandedCondPhi = false;
    if (auto *MgBI = dyn_cast<BranchInst>(Mg->getTerminator()))
      // `Mg` phi-less ⇒ the two scopes are indistinguishable (no phi node is
      // reachable, so nothing scope-sensitive fires), both calls return the same
      // value and the conjunction is false — skip two unmemoized depth-8 walks
      // that can descend whole callee bodies through `coneDefinedAfterFlagDrop`.
      // Behaviour-identical by that argument, not by measurement.
      if (MgBI->isConditional() && !Mg->phis().empty() &&
          Taint.Tainted.count(MgBI->getCondition())) {
        // Scope block set = {Mg} alone. A phi of a region-INTERIOR block cannot
        // appear in `Mg`'s condition cone anyway: it would have to dominate
        // `Mg`, hence post-dominate `E`, making IT — not `Mg` — the immediate
        // post-dominator (lens 3's dead-code argument), so the merge's own phis
        // are the entire reachable surface.
        SmallPtrSet<BasicBlock *, 1> MergeOnly;
        MergeOnly.insert(Mg);
        const PhiCondScope Convertible{&MergeOnly, /*Entry=*/nullptr, nullptr};
        const PhiCondScope Downstream{&MergeOnly, /*Entry=*/Mg, nullptr};
        StrandedCondPhi =
            isSupportedCondTree(MgBI->getCondition(), 0, &Convertible) &&
            !isSupportedCondTree(MgBI->getCondition(), 0, &Downstream);
      }
    Claim = NestedTainted || ClaimableRead || NumMergePhis >= 2 ||
            (NumMergePhis == 1 && SolePhiIncomings > 2) || FpSolePhiMux ||
            IntConstFallthroughMux || StrandedCondPhi;
  }
  // ClaimAll (5po2 I2): inside a Bennett clone the anti-overlap witness is
  // irrelevant (no top-level emitter runs there), so claim ANY acyclic SESE
  // tainted value region — incl. the 2-incoming single-guard diamond a
  // normalized single-early-return reduces to. The E2/E3/E4 gates below still
  // apply, so a claimed region can never half-lower.
  if (!ClaimAll && !Claim)
    return leave("W-witness");

  // --- E2: acyclic, not in/around a loop ------------------------------------
  for (BasicBlock *B : R.InRegion)
    if (OnCycle.count(B))
      return leave("E2-cycle");

  // --- E3: single-entry / single-exit ---------------------------------------
  for (BasicBlock *B : R.InRegion) {
    const Instruction *Term = B->getTerminator();
    // bd 20xt.5 (d) — an `unreachable` arm terminator is TOLERATED: it is a
    // dead sink (UB in the source, no basis state enters it — Rule 5), erased
    // by the flatten with NO merge-phi incoming (it has no successors, so no phi
    // lists it). Its body (if any): an impure instruction (store/non-curated
    // call) is excluded by E4 below (→ leave); a pure instruction is hoisted by
    // `moveBody` but is provably dead — a successorless block dominates nothing
    // outside itself, so its SSA values have zero external uses — and `sweepDead`
    // erases the whole cone before `lowerOps` (Rule-13 clearance: verified inert
    // on a non-empty pure dead body; `control_predmux_accept_unreachable_dead_body.ll`).
    // `ret`/`indirectbr`/`invoke`/`callbr` remain real multi-exits and still leave.
    if (!isa<BranchInst>(Term) && !isa<SwitchInst>(Term) &&
        !isa<UnreachableInst>(Term))
      return leave("E3-multiexit", Term);  // ret/invoke/… inside: multi-exit
    for (const BasicBlock *S : successors(B))
      if (S != Mg && !R.InRegion.count(S))
        return leave("E3-escape", Term);  // escapes the region without reconverging
    if (B == E)
      continue;
    for (const BasicBlock *P : predecessors(B))
      if (!R.InRegion.count(P))
        return leave("E3-sideentry");  // side entry
  }
  for (const BasicBlock *P : predecessors(Mg))
    if (!R.InRegion.count(P))
      return leave("E3-mergepred");  // a reaching edge PredMux does not predicate

  // --- E4 + E6 + E7 over the region body ------------------------------------
  // Inc 5 (bd q2wk) — the claim-time phi context (PRD §4.4b rule (A)).
  const PhiCondScope Scope{&R.InRegion, R.Entry, &R.BoolAlgPhis};
  for (BasicBlock *B : R.InRegion) {
    // E6: every conditional terminator tainted, with an invertible condition.
    const Instruction *Term = B->getTerminator();
    if (const auto *BI = dyn_cast<BranchInst>(Term)) {
      if (BI->isConditional()) {
        // bd adia (3c6m.55 Lever C): a CONSTANT-condition br (a fold residue the fp80
        // promotion or an earlier flatten materialized late) is degenerate —
        // no runtime classical/quantum mixing; the literal machinery folds
        // ∧true/∧false natively (isSupportedCondTree admits ConstantInt).
        //
        // bd q2wk (Inc 5, PRD §4.4b rule (B)): a condition the FLATTEN ITSELF
        // will taint is not classical control either — it is the region's own
        // tainted decision re-materialized. Every region edge predicate is
        // tainted (the entry terminator is tainted by construction), so a
        // region-internal-phi-derived condition becomes tainted the moment
        // `convertPhis` rewires that phi onto the edge predicates. This is the
        // all-constant `phi i1 [true,%a],[false,%b],[false,%entry]` clang -O1
        // emits for a short-circuit it did not if-convert (log1p's
        // `hx > 0 || hx <= 0xbfd2bec4`), and hypotf's `icmp eq i32 %k, 0` over
        // the phi-merged scale accumulator. SHARED predicate with the Inc-3
        // QROM index gate (Rule 14) — one question, one answer — and `R.Entry`
        // is passed so the two phi shapes the flatten does NOT convert to a
        // tainted value (an ENTRY-block phi; a phi whose incoming values are
        // all one Value) answer honestly instead of on a false promise.
        //
        // WHERE THE RESIDUAL ACTUALLY LANDS, corrected by the q2wk Rule-13
        // round (the original claim here named the wrong guard): a condition
        // that nonetheless stays classical does NOT become a classical-condition
        // select, because every edge predicate is `and(BP, lit)` with BP derived
        // from the tainted entry condition — so the select condition is tainted
        // and `declineClassicalMuxes` can never fire. The classical value
        // survives as an UNTAINTED COMPARE LEAF inside a tainted cond tree, and
        // the load-bearing backstop is `SelectClassify`'s GATE-2 per-leaf taint
        // check, which declines `control flow under quantum control`. That gate
        // is explicitly staged for a future "hybrid classical∧quantum
        // conjunction" widening — whoever lifts it MUST re-derive this
        // argument. And the decline is not universal: a region that mints no
        // select (an i1 merge phi takes the boolean-algebra path) compiles
        // silently, which is SOUND only because a classical runtime operand
        // occupies the sanctioned `_hl` literal slot and is never promoted to a
        // qubit handle (the §5.2 non-negotiable). The SWITCH scrutinee gate
        // below is deliberately NOT widened: no measured cell needs it and
        // over-declining is safe.
        if (!Taint.Tainted.count(BI->getCondition()) &&
            !isa<ConstantInt>(BI->getCondition()) &&
            !valueWillTaintAfterFlatten(BI->getCondition(), Taint, R.InRegion,
                                        R.Entry))
          return leave("E6-classicalbr", BI);  // classical control inside a tainted region: mixed
        if (!isSupportedCondTree(BI->getCondition(), 0, &Scope))
          return leave("E6-condtree", BI);
      }
    } else if (const auto *SI = dyn_cast<SwitchInst>(Term)) {
      if (!Taint.Tainted.count(SI->getCondition()))
        return leave("E6-classicalswitch", SI);
      Type *ScrTy = SI->getCondition()->getType();
      if (!isMuxableType(ScrTy))
        return leave("E6-switchwidth", SI);  // eq/ne flags must be mintable at this width
    }
    if (B == E)
      continue;  // E's own instructions are not moved
    for (Instruction &I : *B) {
      if (isa<PHINode>(I)) {
        if (!isMuxableType(I.getType()))
          return leave("E7-phi", &I);  // E7
        continue;
      }
      if (I.isTerminator())
        continue;
      // E4' (Inc 3) — a claimable const-global QROM read (and its single-use
      // address gep) is speculatable dataflow: the table is immutable, the
      // width has a qram cell, and the index is provable or pow2-maskable
      // (`classifyQromReadUnderControl` — the SAME predicate the carve
      // defers on, so claim and carve can never diverge). A NeedsMask read
      // is recorded for the flatten to rewrite its gep index. Every other
      // load — and any volatile/atomic access (isSimple gates them) — leaves.
      if (auto *LI2 = dyn_cast<LoadInst>(&I)) {
        uint64_t Count = 0;
        // bd 20xt.5.2: `ClaimAll` is the Bennett-clone signal (set only by
        // `lowerCloneControl`); it bypasses the coherent-escape fence so an
        // arm-resident QROM read whose value flows to the clone ret is claimable
        // (the wrap copies-out + reverse-plays the whole stream — the same bypass
        // `lowerQramReads(inBennettClone=true)` applies at the emitter, Rule 14).
        bool IndexBecomesOpaque = false;
        QromClaim QC = classifyQromReadUnderControl(
            LI2, Taint, DT, LInfo, &Count, &R.InRegion,
            /*inBennettClone=*/ClaimAll, &IndexBecomesOpaque);
        if (QC == QromClaim::No)
          return leave("E4-load", &I);
        // bd 20xt.7: a PROVABLE clone read on a pow2 table whose index BECOMES
        // OPAQUE after the flatten ALSO gets the (identity) mask, not only a
        // NeedsMask one. `and idx, N-1` is the IDENTITY on a provable-in-bounds
        // index (Provable ⟹ known-bits max < N = 2^k ⟹ idx fits in k bits ⟹
        // `and idx, N-1` == idx at runtime), so it is semantically inert — its SOLE
        // effect is to carry the flatten's bounds proof to the EMITTER. The index
        // becomes opaque iff it is region-internal-phi-derived (currently untainted,
        // admitted only via `indexWillTaintAfterFlatten`): the flatten +
        // `lowerCloneSelect` lower it to a `cqrt_alloc_i64` handle whose known-bits
        // `lowerQramReads`' `qromIndexKnownInBounds` re-proof cannot see, so it would
        // else loud-decline `kMsgQramCloneUnbounded` (a safe-but-confusing claim/emit
        // divergence). A CURRENTLY-TAINTED Provable index (a source `& 3` straight-
        // line computation) keeps its RAW op at the gep, which the emitter re-proves
        // directly — masking THAT would be a redundant double-`and` that drifts its
        // golden (Rule 14; the e2e slice_spec_qrom_read_arm_escape regression this
        // guard fixes). Gated on `ClaimAll` (clone-only): a top-level Provable read
        // is a faithful source access, bounds the source's obligation, left UNMASKED.
        // A non-pow2 Provable clone read stays unmasked here and, in a clone, still
        // declines at the emitter (rare; the safe residual over-decline).
        if (QC == QromClaim::NeedsMask ||
            (QC == QromClaim::Provable && ClaimAll && IndexBecomesOpaque &&
             Count != 0 && isPowerOf2_64(Count)))
          R.MaskLoads.push_back({LI2, Count});
        continue;
      }
      if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
        if (GEP->hasOneUse())
          if (auto *LU = dyn_cast<LoadInst>(GEP->user_back()))
            if (LU->getPointerOperand() == GEP &&
                classifyQromReadUnderControl(LU, Taint, DT, LInfo,
                                             /*OutCount=*/nullptr, &R.InRegion,
                                             /*inBennettClone=*/ClaimAll) !=
                    QromClaim::No)
              continue;  // the claimable read's address gep (load re-checked).
        return leave("E4-gep", &I);
      }
      // bd adia (Lever C) — a PENDING-SPECIALIZATION call is speculatable
      // dataflow: DIRECT, ≥1 TAINTED argument (an all-classical pure call in
      // an arm stays with its 6.5 classical-call-arm owner — anti-overlap),
      // a template-width result, and a callee body passing the pure/acyclic/
      // all-speculatable proof (a pure total terminating function of its
      // arguments — the same class Phase-6 clones; under quantum control the
      // call executes on every basis state, exactly as every other
      // speculated arm op). An off-proof call still excludes the region.
      if (auto *CI = dyn_cast<CallInst>(&I)) {
        if (isCuratedReversibleIntrinsic(CI) && CI->doesNotAccessMemory())
          continue;
        bool TaintedArg = false;
        for (Value *A : CI->args())
          if (Taint.Tainted.count(A)) {
            TaintedArg = true;
            break;
          }
        //
        // CLONE MODE IS DELIBERATELY NOT FENCED HERE (bd 3c6m.14.1) — this line
        // has no `ClaimAll` gate and that is a DECISION, not an oversight. The
        // pure-callee proof now admits an i80 `_hl` compare, so as of that
        // increment this site accepts, in BOTH contexts, a call whose callee
        // carries one. MEASURED before deciding, against a pinned pre-change
        // plugin: the shape is reachable in clone mode (fixture
        // accept_i80_cmp_purecallee_clonecall.ll — the region claimed inside
        // `@__cq_q_mid_1` and the compare landed in the transitively-specialized
        // `@__cq_q_inner_1`).
        //
        // The reason it is not fenced, in one sentence: the callee's compare
        // NEVER ENTERS THIS REGION'S FLATTENED PROGRAM — only the CALL moves —
        // so the walk's own top-level/clone context is causally unrelated to how
        // that compare is lowered, and a `!ClaimAll` here would be a fence with
        // no correctness content. The compare's lowering obligation is
        // discharged where it lives, by the callee's own clone, under gates that
        // still bite: straight-line it lowers to the frozen
        // `cq_template_icmp_<pred>_i80_hl` (a shape that already lowers today
        // with NO region involved — measured on the pre-change plugin); inside
        // the callee's OWN tainted diamond it hits the `!ClaimAll` bare-compare
        // fence one screen down and loud-declines. Both pinned, and the second
        // one was reproduced on real C as well as on hand-written IR.
        //
        // A THIRD discharge path exists and the first draft of this comment did
        // not name it (found by the Rule-13 clone-mode lens): if the callee takes
        // a TAINTED argument of a width the specialization ABI cannot carry —
        // i80 among them — the proof passes, the ClaimAll region claims AND
        // FLATTENS, and only then does `SpecializeReject`'s site-ABI gate
        // decline. That is a post-mutation decline, and it is PRE-EXISTING
        // (reachable on the pre-change plugin through a compare-free i80-arg
        // callee), but this widening enlarges its reachable set. Filed, not
        // fixed here — see the bd follow-up; do not read the two paths above as
        // exhaustive.
        //
        // This does NOT lift that bare-compare fence below, and the asymmetry is
        // real but principled: there the compare joins the clone's select
        // program, here it does not. `reject_i80_cmp_clonemode.ll` still
        // declines, with a byte-identical message, DBG leave line and exit code
        // (diffed, not assumed).
        if (TaintedArg && isTemplateWidthType(CI->getType()) &&
            isSpeculatablePureCalleeBody(CI->getCalledFunction()))
          continue;
        return leave("E4-dataflow", &I);
      }
      // The `!ClaimAll` half of the `AdmitI80Compare` story (bd 3c6m.61), and
      // as of bd 3c6m.14.1 the ONLY site that still passes anything but `true`:
      //
      //  * `recoverRegion` runs in TWO contexts, the TOP-LEVEL region flatten
      //    and the `ClaimAll` Bennett-CLONE body flatten (threaded from
      //    `Specialization.cpp`). Only the top-level one is in scope and only
      //    it has an i80 fixture family, so clone mode keeps the old blanket
      //    exclusion.
      //  * The pure-callee proof above now passes TRUE (bd 3c6m.14.1) — it
      //    answers "pure + total", not "speculatable into THIS select program",
      //    and its compare never reaches this region. That is a different
      //    clause, not a lift of this one; see the call-admission note above.
      //
      // THE CLONE CONTEXT IS REACHABLE — do not re-derive otherwise. A first
      // draft of this comment claimed it was unreachable and listed three
      // measured fences (fp80 args laundered to i32 handles; the fp-copy
      // specialization fence; the quantum-lift fence). The Rule-13 JUDGE
      // falsified all three with one probe that evades them simultaneously: an
      // i32 parameter (no fp80 anywhere), i80 reached via the in-grid
      // `zext i32 -> i80`, inside a callee carrying its own tainted diamond.
      // Un-gated, that CLAIMED in clone mode and emitted
      // `cq_template_icmp_eq_i80_hl` + its `_unc` inside `@__cq_q_leaf_1`.
      // The judge audited that emission and found it SOUND — so this gate is a
      // SCOPE decision, not a correctness one: it is a new accept surface in
      // the Phase-6 clone + Bennett-wrap path rather than the reviewed select
      // substrate, and Rule 12 wants its own probe family before it ships.
      // bd 3c6m.14.1 CONSIDERED AND KEPT IT (that ticket scopes (A)+(B) only;
      // this is the bare-compare-into-a-clone-select-program axis, a different
      // construct from the widened pure-callee CALL). Pinned by
      // control_predmux_reject_i80_cmp_clonemode.ll, which after 3c6m.14.1 still
      // declines with a byte-identical message, DBG line and exit code.
      //
      // NOTE FOR WHOEVER LIFTS THIS: that is now TWICE this clause has carried
      // a false "this shape cannot occur here" claim — the first being "the
      // canonical promotion never puts those inside an arm", which hypotl
      // falsified and which is the entire reason bd 3c6m.61 exists. Measure;
      // do not reason about reachability here.
      if (!isSpeculatableDataflow(I, /*AdmitI80Compare=*/!ClaimAll))
        return leave("E4-dataflow", &I);  // E4
    }
  }
  // E7 for the merge phis (they all convert: preds(Mg) ⊆ region).
  for (const PHINode &P : Mg->phis())
    if (!isMuxableType(P.getType()))
      return leave("E7-mergephi", &P);

  return topoOrderRegion(R);
}

// ---------------------------------------------------------------------------
// The flatten
// ---------------------------------------------------------------------------

class RegionFlattener {
public:
  RegionFlattener(PredMuxRegion &R, IRBuilder<> &B) : R(R), B(B) {}

  void run() {
    // Process arm blocks in topological order: convert phis to select
    // chains, then move the straight-line body before the entry terminator.
    for (BasicBlock *D : R.Topo) {
      if (D == R.Entry)
        continue;
      convertPhis(D);
      moveBody(D);
    }
    convertPhis(R.Merge);
    // Inc 3 — mask the NeedsMask reads' gep indices (`and idx, N-1`): the
    // speculated read must be in-bounds on EVERY basis state. The mask is the
    // IDENTITY exactly on the in-bounds indices (idx ∈ [0,N)); it only changes
    // an OUT-OF-BOUNDS index — and `tbl[idx]` out of bounds is UB in the source,
    // so that basis state is obligation-free (the original program had no
    // defined result to preserve). Soundness thus rests on OOB-read-is-UB, not
    // on the guard bounding the index (the guard may be unrelated to it); the
    // masked garbage-row value, where it survives the merge predicate, only ever
    // replaces an undefined one. The claim gate (classifyQromReadUnderControl)
    // keeps the index at the pointer-index width, so `and idx, N-1` (N ≤ 2^63)
    // yields a non-negative in-range offset for every bit pattern. Inserted AT
    // the (already-moved) gep so the index dominates textually; the And is
    // tainted by the caller's re-propagate and lowers as an ordinary hl template.
    for (auto &ML : R.MaskLoads) {
      auto *GEP = cast<GetElementPtrInst>(ML.first->getPointerOperand());
      unsigned IdxNo = GEP->getNumOperands() - 1;
      Value *Idx = GEP->getOperand(IdxNo);
      IRBuilder<> MB(GEP);
      MB.SetCurrentDebugLocation(GEP->getDebugLoc());
      Value *Masked = MB.CreateAnd(
          Idx, ConstantInt::get(Idx->getType(), ML.second - 1));
      GEP->setOperand(IdxNo, Masked);
      track(Masked);
    }
    // Entry terminator → unconditional branch to the merge; erase the arms.
    // The entry terminator's own condition/scrutinee joins the sweep set (a
    // Rule-13 clearance follow-up): it normally stays live as a predicate
    // leaf, but if every consuming edge-predicate was dead-swept it would
    // otherwise linger as a dead tainted producer for lowerOps to lower.
    Instruction *T = R.Entry->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional())
        track(BI->getCondition());
    } else if (auto *SI = dyn_cast<SwitchInst>(T)) {
      track(SI->getCondition());
    }
    B.SetInsertPoint(T);
    B.CreateBr(R.Merge);
    T->eraseFromParent();
    for (BasicBlock *D : R.Topo)
      if (D != R.Entry)
        D->dropAllReferences();
    for (BasicBlock *D : R.Topo)
      if (D != R.Entry)
        D->eraseFromParent();
    sweepDead();
  }

private:
  PredMuxRegion &R;
  IRBuilder<> &B;
  DenseMap<BasicBlock *, Value *> BlockPred;   // nullptr = ⊤ (entry)
  DenseMap<std::pair<BasicBlock *, unsigned>, Value *> LitCache;
  SmallVector<WeakTrackingVH, 32> MaybeDead;

  // lit(e) for successor slot Idx of S's terminator: the branch condition in
  // the taken polarity (false edges via leaf-inverted De Morgan negation) or
  // the switch case-equality (default = ∧ of ne). Memoized per (S, Idx).
  Value *literal(BasicBlock *S, unsigned Idx) {
    auto Key = std::make_pair(S, Idx);
    auto It = LitCache.find(Key);
    if (It != LitCache.end())
      return It->second;
    Instruction *Term = S->getTerminator();
    Value *L = nullptr;
    if (auto *BI = dyn_cast<BranchInst>(Term)) {
      assert(BI->isConditional() && "unconditional edge has no literal");
      L = Idx == 0 ? canonicalizePred(BI->getCondition())
                   : buildNegation(BI->getCondition());
    } else {
      auto *SI = cast<SwitchInst>(Term);
      if (Idx == 0) {  // default: ∧ of (scrut != case_k)
        for (const auto &Case : SI->cases()) {
          Value *Ne = B.CreateICmpNE(SI->getCondition(), Case.getCaseValue());
          track(Ne);
          L = L ? track(B.CreateAnd(L, Ne)) : Ne;
        }
        if (!L)  // a switch with no cases is an unconditional edge
          L = ConstantInt::getTrue(SI->getContext());
      } else {
        ConstantInt *CV = SI->case_begin()
                              .operator+(Idx - 1)
                              ->getCaseValue();
        L = track(B.CreateICmpEQ(SI->getCondition(), CV));
      }
    }
    LitCache[Key] = L;
    return L;
  }

  // bd adia (Lever C): strip poison-generating flags AND metadata over the
  // full backward cone of a select-form's SHIELDED operand. The rewrite below
  // turns `select(a,b,false)` into `and(a,b)`: in the ORIGINAL program `b` is
  // never observed when `a` is false (the clang short-circuit shield), so a
  // poison `b` on an a=false basis state was harmless there but would poison
  // the rewritten `and`. The claim-time proof `coneDefinedAfterFlagDrop`
  // already restricted the cone to ops that are TOTAL once flags are gone
  // (inherent-poison ops — variable-amount shifts, fp->int casts — never
  // reach here); this strip performs the drop, so the cone is then defined
  // on every basis state. Flag/metadata-stripping only widens definedness,
  // so every other user of a cone value is unaffected.
  void stripPoisonCone(Value *V) {
    SmallPtrSet<Instruction *, 16> Seen;
    SmallVector<Instruction *, 16> WL;
    if (auto *I = dyn_cast<Instruction>(V)) {
      Seen.insert(I);
      WL.push_back(I);
    }
    while (!WL.empty()) {
      Instruction *I = WL.pop_back_val();
      // bd 3c6m.14.2 — this drops TWO of LLVM 19's THREE poison-generating
      // annotation families. `Instruction::hasPoisonGeneratingAnnotations()`
      // names three — flags, metadata, and CALL RETURN ATTRIBUTES
      // (`range`/`nonnull`/`align`) — so the claim's promise ("defined AFTER the
      // drop") is not literally kept for the third. Switching to
      // `dropPoisonGeneratingAnnotations()` was TRIED and REVERTED. The reason
      // is stated carefully, because the Rule-13 round FALSIFIED the first
      // draft of this note and the wrong version read more confidently than the
      // right one:
      //
      //  * WRONG (do not restore it): "no admitted call can carry a return
      //    attribute into emission — a tainted curated intrinsic is replaced by
      //    its `cq_template_*`, and a classical one declines downstream." The
      //    first half holds. THE SECOND HALF IS FALSE, on real C as well as on
      //    hand-written IR: a CLASSICAL curated call in a MIXED compare leaf
      //    (`icmp sgt i32 %q_tainted, %r_classical`) is neither replaced nor
      //    declined — it survives verbatim into the emitted module, attribute
      //    and all. MEASURED: a `call range(i32 8, 9) i32 @llvm.ctpop.i32(...)`
      //    comes out the far side still carrying `range(i32 8, 9)`.
      //  * RIGHT, and it is why the revert still stands: (i) the surviving
      //    value lands ONLY in an `_hl` template's LITERAL slot, never in a rail
      //    HANDLE slot — which is the categorical difference from the round-one
      //    `ctlz` finding, where poison became the handle a gate fired on — and
      //    the forward call and its `_unc` twin read the SAME literal, so the
      //    adjoint stays paired; no `and i1` survives at all (the predicate
      //    becomes `cqrt_toffoli` over per-leaf rails, which reconstructs the
      //    shield physically), and stage 3 is deliberately -O0 (bd szpr pin), so
      //    nothing downstream can refine the two uses differently. (ii) THIS
      //    WALK PROVABLY EXCEEDS THE PROOF'S WALK: it recurses past the
      //    `cq_theta`/`cq_phi` leaf — where `coneDefinedAfterFlagDrop`
      //    `continue`s WITHOUT operand recursion — into the classical seed
      //    subtree, and strips `nsw`/`nuw` off instructions the whitelist
      //    refuses and the proof never visited. Widening the DROP without first
      //    narrowing the WALK makes that over-reach worse.
      // The accept itself is PRE-EXISTING and BASE-identical (byte-for-byte), so
      // nothing here is a regression of this change. Both halves are filed
      // together; FIX THE WALK FIRST, then revisit the third family.
      I->dropPoisonGeneratingFlags();
      I->dropPoisonGeneratingMetadata();
      for (Value *Op : I->operands())
        if (auto *OI = dyn_cast<Instruction>(Op))
          if (Seen.insert(OI).second)
            WL.push_back(OI);
    }
  }

  // bd adia (Lever C): rewrite the poison-shielded short-circuit select forms
  // (`select(a,b,false)` = a&&b, `select(a,true,b)` = a||b — the clang -O1
  // compound-condition lowering of coshl's `ex < K || (ex == K && mx < M)`
  // range ladder) into plain and/or nodes so the emitted predicate trees stay
  // inside the cleared and/or-over-compare-leaves grammar (collectCondTree /
  // the 3c6m.12 flag mint). Identity on every other supported shape. The
  // shielded operand's cone is flag-stripped first (see stripPoisonCone) so
  // the rewrite is basis-state-equivalent: a defined `b` makes
  // `and(a,b) == select(a,b,false)` on every input.
  Value *canonicalizePred(Value *V) {
    if (auto *Sel = dyn_cast<SelectInst>(V)) {
      if (auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue()))
        if (FC->isZero()) {
          stripPoisonCone(Sel->getTrueValue());
          return track(B.CreateAnd(canonicalizePred(Sel->getCondition()),
                                   canonicalizePred(Sel->getTrueValue())));
        }
      if (auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue()))
        if (TC->isOne()) {
          stripPoisonCone(Sel->getFalseValue());
          return track(B.CreateOr(canonicalizePred(Sel->getCondition()),
                                  canonicalizePred(Sel->getFalseValue())));
        }
      return V;  // unreachable past isSupportedCondTree
    }
    if (auto *BO = dyn_cast<BinaryOperator>(V)) {
      if (BO->getOpcode() == Instruction::And ||
          BO->getOpcode() == Instruction::Or) {
        Value *L = canonicalizePred(BO->getOperand(0));
        Value *Rr = canonicalizePred(BO->getOperand(1));
        if (L != BO->getOperand(0) || Rr != BO->getOperand(1))
          return track(BO->getOpcode() == Instruction::And ? B.CreateAnd(L, Rr)
                                                           : B.CreateOr(L, Rr));
      }
    }
    return V;
  }

  // ¬V with the negation pushed to the leaves (PRD §4.3, the no-NOT
  // invariant). Shapes are pre-checked by isSupportedCondTree.
  Value *buildNegation(Value *V) {
    if (auto *C = dyn_cast<ConstantInt>(V))
      return C->isZero() ? ConstantInt::getTrue(C->getContext())
                         : ConstantInt::getFalse(C->getContext());
    if (auto *Cmp = dyn_cast<CmpInst>(V))
      return track(B.CreateCmp(Cmp->getInversePredicate(), Cmp->getOperand(0),
                               Cmp->getOperand(1)));
    // bd adia: select-form short-circuit nodes (see canonicalizePred; the
    // shielded operand's cone is flag-stripped before negation, same
    // basis-state-equivalence argument). ¬(a&&b) = ¬a ∨ ¬b ;
    // ¬(a||b) = ¬a ∧ ¬b — leaf-inverted De Morgan (the no-NOT invariant).
    if (auto *Sel = dyn_cast<SelectInst>(V)) {
      if (auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue());
          FC && FC->isZero()) {
        stripPoisonCone(Sel->getTrueValue());
        return track(B.CreateOr(buildNegation(Sel->getCondition()),
                                buildNegation(Sel->getTrueValue())));
      }
      auto *TC = cast<ConstantInt>(Sel->getTrueValue());
      (void)TC;
      stripPoisonCone(Sel->getFalseValue());
      return track(B.CreateAnd(buildNegation(Sel->getCondition()),
                               buildNegation(Sel->getFalseValue())));
    }
    auto *BO = cast<BinaryOperator>(V);
    if (BO->getOpcode() == Instruction::Xor)
      return BO->getOperand(0);  // xor-true: ¬¬x = x
    Value *L = buildNegation(BO->getOperand(0));
    Value *Rr = buildNegation(BO->getOperand(1));
    return track(BO->getOpcode() == Instruction::And ? B.CreateOr(L, Rr)
                                                     : B.CreateAnd(L, Rr));
  }

  // BP(D) = ∨ over in-edges of EP(e); ⊤ (nullptr) for the entry. Lazy +
  // memoized; recursion terminates on the region DAG.
  Value *blockPred(BasicBlock *D) {
    if (D == R.Entry)
      return nullptr;
    auto It = BlockPred.find(D);
    if (It != BlockPred.end())
      return It->second;
    Value *BP = nullptr;
    for (BasicBlock *S : predecessors(D)) {
      Value *EP = edgePred(S, D);
      BP = BP ? track(B.CreateOr(BP, EP)) : EP;
    }
    BlockPred[D] = BP;
    return BP;
  }

  // EP(S→D) = BP(S) ∧ lit(S→D), OR-folded over duplicate edges (a switch may
  // reach the same successor through several cases).
  Value *edgePred(BasicBlock *S, BasicBlock *D) {
    Instruction *Term = S->getTerminator();
    Value *Lit = nullptr;
    if (auto *BI = dyn_cast<BranchInst>(Term)) {
      if (!BI->isConditional())
        Lit = nullptr;  // unconditional edge: EP = BP(S)
      else if (BI->getSuccessor(0) == D && BI->getSuccessor(1) == D)
        Lit = ConstantInt::getTrue(BI->getContext());
      else
        Lit = literal(S, BI->getSuccessor(0) == D ? 0 : 1);
    } else {
      auto *SI = cast<SwitchInst>(Term);
      for (unsigned Idx = 0, N = SI->getNumSuccessors(); Idx != N; ++Idx) {
        if (SI->getSuccessor(Idx) != D)
          continue;
        Value *L = literal(S, Idx);
        Lit = Lit ? track(B.CreateOr(Lit, L)) : L;
      }
    }
    Value *BP = blockPred(S);
    if (!BP)
      return Lit ? Lit : ConstantInt::getTrue(S->getContext());
    if (!Lit)
      return BP;
    return track(B.CreateAnd(BP, Lit));
  }

  // Replace every phi of D with a chained select over its in-edge
  // predicates: sel(EP(e₁), v₁, sel(EP(e₂), v₂, … v_m)). The last incoming
  // is the fallback (its predicate is implied when the merge is reached; when
  // an INTERNAL merge is not on the taken path the chain yields garbage that
  // every downstream consumer excludes via its own ∧-with-block-predicate —
  // PRD §4.4/§6.1).
  void convertPhis(BasicBlock *D) {
    SmallVector<PHINode *, 4> Phis;
    for (PHINode &P : D->phis())
      Phis.push_back(&P);
    for (PHINode *P : Phis) {
      // Unique incoming blocks in order (duplicate blocks carry the same
      // value by LLVM's phi rules).
      SmallVector<std::pair<BasicBlock *, Value *>, 8> In;
      SmallPtrSet<BasicBlock *, 8> Seen;
      for (unsigned I = 0, N = P->getNumIncomingValues(); I != N; ++I)
        if (Seen.insert(P->getIncomingBlock(I)).second)
          In.emplace_back(P->getIncomingBlock(I), P->getIncomingValue(I));
      // undef/poison incomings freeze to zero (dead on every selecting path).
      for (auto &IV : In)
        if (isa<UndefValue>(IV.second))
          IV.second = Constant::getNullValue(P->getType());
      // Inc 2 — an i1 phi whose incomings all sit inside the substrate
      // condition-tree grammar converts to BOOLEAN ALGEBRA, ∨ᵢ (EP(eᵢ) ∧ vᵢ)
      // (the iw81.14 / Bennett `_compute_block_pred!` form), instead of a
      // select chain: a select-of-i1 feeding a downstream select CONDITION is
      // off the 3c6m.12 flag-mint grammar (the tanh s_expm1.c:168 decline),
      // while and/or-over-compare-leaves stays mintable. Exactly one EP is
      // true when the merge is on the taken path (acyclic single-visit), so
      // the ∨ picks that edge's value; off-path the result is `false` —
      // garbage excluded downstream by the same ∧-with-block-predicate
      // argument as the chain's fallback garbage (PRD §4.4/§6.1). ∧true/
      // ∧false fold away so i1 constants never reach the emitted tree; the
      // EP==v and Acc==Term guards keep the substrate's self-operand fence
      // unreachable (x∧x = x, x∨x = x). Off-grammar incomings (trunc/xor/…)
      // keep the Inc-1 select chain — the consuming select declines loudly
      // exactly as today.
      bool BoolAlg = P->getType()->isIntegerTy(1) && In.size() > 1;
      // bd q2wk (Inc 5) — a phi the E6 claim RECORDED is a path-predicated
      // BRANCH condition: `literal()`/`buildNegation` will read its converted
      // value as a cond tree, so the select-chain fallback is not available
      // (a general `select i1` there is a broken module, not a decline). The
      // claim proved the same grammar this loop re-checks — over the ORIGINAL
      // incomings, where a nested convertible phi is still a phi and this
      // scope-less grammar would reject it, and where a deeper already-
      // converted incoming may also exceed the depth budget. Trusting the
      // recorded decision is what removes both divergences; it is never
      // weaker, because `isConvertiblePhiCond` requires exactly this grammar
      // (extended only by the recursive phi case) plus i1 and >1 unique
      // incoming block. The algebra itself is total for any i1 incoming — the
      // grammar exists only to keep the RESULT flag-mintable.
      if (BoolAlg && !R.BoolAlgPhis.count(P))
        for (auto &IV : In)
          if (!isBooleanCondTree(IV.second, 0)) {
            BoolAlg = false;
            break;
          }
      Value *Acc = nullptr;
      if (BoolAlg) {
        for (auto &IV : In) {
          Value *EP = edgePred(IV.first, D);
          Value *Term = nullptr;
          if (auto *C = dyn_cast<ConstantInt>(IV.second))
            Term = C->isOne() ? EP : nullptr;  // ∧true = EP; ∧false drops.
          else if (EP == IV.second)
            Term = EP;  // x ∧ x = x (never mint a self-operand node).
          else
            Term = track(B.CreateAnd(EP, IV.second));
          if (!Term)
            continue;
          if (!Acc)
            Acc = Term;
          else if (Acc != Term)  // x ∨ x = x.
            Acc = track(B.CreateOr(Acc, Term));
        }
        if (!Acc)  // every incoming was constant-false/frozen-undef.
          Acc = ConstantInt::getFalse(P->getContext());
      } else {
        Acc = In.back().second;
        for (unsigned I = In.size() - 1; I-- > 0;) {
          // bd adia (3c6m.55 Lever C): select(EP, x, x) = x — never mint the degenerate
          // same-arm mux (the value-chain mirror of the BoolAlg x∨x guard).
          if (In[I].second == Acc)
            continue;
          Value *EP = edgePred(In[I].first, D);
          Acc = track(B.CreateSelect(EP, In[I].second, Acc));
        }
      }
      P->replaceAllUsesWith(Acc);
      P->eraseFromParent();
    }
  }

  // Move D's straight-line body before the entry terminator, dropping
  // poison-generating flags (nsw/nuw/exact/nneg/disjoint + fp poison FMF) —
  // the standard speculation discipline; bit-semantics and template
  // selection are unaffected (signedness lives in the opcode, Rule 15).
  void moveBody(BasicBlock *D) {
    Instruction *T = R.Entry->getTerminator();
    for (Instruction &I : llvm::make_early_inc_range(*D)) {
      if (I.isTerminator())
        continue;
      I.dropPoisonGeneratingFlags();
      I.moveBefore(T);
      track(&I);
    }
  }

  Value *track(Value *V) {
    MaybeDead.push_back(V);
    return V;
  }

  // Erase any moved/minted instruction that ended up unused (e.g. the unused
  // fallback edge-predicate) so no dead tainted producer reaches lowerOps.
  // All tracked values are pure, so this is a plain use_empty fixpoint.
  void sweepDead() {
    bool Changed = true;
    while (Changed) {
      Changed = false;
      for (WeakTrackingVH &H : MaybeDead) {
        auto *I = dyn_cast_or_null<Instruction>(H.operator Value *());
        if (I && I->use_empty()) {
          I->eraseFromParent();
          H = nullptr;
          Changed = true;
        }
      }
    }
  }
};

}  // namespace

// bd adia (3c6m.55 Lever C): exported wrapper — the pending-spec pure-callee proof
// (visible + non-vararg + acyclic CFG + br/ret terminators + every
// non-terminator speculatable dataflow; inner calls curated memory(none)
// intrinsics only). Shared with the Fp80Union seed walk (Rule 14).
bool isSpeculatablePureCallee(const Function *F) {
  return isSpeculatablePureCalleeBody(F);
}

// bd 20xt.5.1 blocker (e): fold the constant-fold RESIDUES the flatten's
// `foldConstantConeAndBranches` leaves behind. `ConstantFoldInstruction` is
// all-or-nothing — it RAUWs an all-constant operand to its value but cannot
// finish a PARTIAL-constant binop whose other operand is tainted, so a dead
// classical arm (e.g. atan2l's `x==1.0` special-case or its `2*sign(x)`
// quadrant term with x a positive classical constant) leaves `and i1 false,%t`
// / `or i32 0,%t` behind. Those wedge SelectClassify: `collectCondTree` hits
// the `false` ConstantInt leaf and declines "control flow under quantum
// control", even though the select is dead (`select false,a,b`) or a no-op
// (`select c,a,a`).
//
// SCOPE — ONLY the residue shapes that WEDGE SelectClassify, NEVER a general
// InstSimplify sweep:
//   * an i1 and/or with a ConstantInt operand — the CONDITION-CONE logic
//     residue (X∧false=false, X∧true=X, X∨true=true, X∨false=X). This is what
//     `collectCondTree` chokes on (the `false` ConstantInt leaf). The and/or
//     fold is deliberately restricted to i1: a WIDER `or i32/i64 0,X` fold is a
//     DATA residue that does NOT block detection (it is a compare operand /
//     select arm, not a tree node) — and the fp80-union promotion mints exactly
//     that shape (`or i64 0,%w` in the union reconstruction), so folding it
//     drifts the cbrtl/exp2l/erfl real-source goldens by one gate + a handle
//     renumber cascade for zero detection benefit. Leave it.
//   * select with a ConstantInt condition (const ? a : b) — collapses the dead
//     special-case arm the flatten straight-lined (atan2l's `select i1 false`).
//   * select with syntactically-equal arms (c ? a : a = a).
// A legit cond-tree node (`and/or i1` of two RUNTIME compares) and a genuine
// data select have NO constant operand and unequal arms, so they are never
// touched — that keeps every existing golden's toffoli/copy-gate emission
// byte-identical (a full `simplifyInstruction` sweep folds legit and/or-over-
// compares via deeper reasoning and drifts ~29 verified libm real-source
// goldens: it drops the very toffolis that realize the cond tree). InstSimplify
// is reused ONLY to COMPUTE the fold of a gated residue (Rule 14) — it returns
// an existing value or a Constant, never mints new IR, so no NOT/De-Morgan
// leaks into the no-NOT and/or-over-compare-leaves grammar. Sound: InstSimplify
// is value-preserving and the taint lowering faithfully emulates LLVM value
// semantics, so a folded residue lowers to the identical unitary (the dead arm
// carried zero amplitude / was source-UB — see
// quantum-ub-unreachable-sharp-edge-20xt5). Fixpoint: a fold exposes the next
// (`%27→false` ⇒ `and i1 %43,%27 → and i1 %43,false`).
static bool isFlattenResidue(const Instruction &I) {
  if (auto *BO = dyn_cast<BinaryOperator>(&I)) {
    if ((BO->getOpcode() == Instruction::And ||
         BO->getOpcode() == Instruction::Or) &&
        BO->getType()->isIntegerTy(1))
      return isa<ConstantInt>(BO->getOperand(0)) ||
             isa<ConstantInt>(BO->getOperand(1));
    return false;
  }
  if (auto *Sel = dyn_cast<SelectInst>(&I))
    return isa<ConstantInt>(Sel->getCondition()) ||
           Sel->getTrueValue() == Sel->getFalseValue();
  return false;
}

static bool simplifyFlattenResiduesInFunction(Function &F) {
  const DataLayout &DL = F.getParent()->getDataLayout();
  SimplifyQuery SQ(DL);
  bool Any = false, Changed = true;
  while (Changed) {
    Changed = false;
    // TWO-PASS per round: COLLECT the residue instructions first (pure
    // analysis, no mutation), then fold + DCE over the worklist. The mutation
    // pass must NOT run inside a block iterator, because the recursive DCE below
    // can delete an instruction that FOLLOWS the fold site: a LOOP PHI's
    // back-edge incoming value need not dominate the phi (it dominates only the
    // incoming block terminator), so folding `and i1 %loopphi, false` can
    // orphan the phi and cascade to its back-edge operand `%J = getNextNode()`
    // — dangling a `make_early_inc_range` lookahead cursor (a UAF crash on valid
    // IR; the "operands dominate I" proof holds for straight-line SSA but not
    // across a loop back-edge). Iterating a WeakTrackingVH worklist instead is
    // deletion-safe: a cascade-deleted entry nulls out and is skipped.
    SmallVector<WeakTrackingVH, 16> Worklist;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (isFlattenResidue(I))
          Worklist.push_back(&I);
    for (WeakTrackingVH &H : Worklist) {
      auto *I = dyn_cast_or_null<Instruction>(H.operator Value *());
      if (!I || !isFlattenResidue(*I))
        continue;  // cascade-deleted, or no longer a residue after an RAUW.
      Value *V = simplifyInstruction(I, SQ);
      if (!V)
        continue;
      I->replaceAllUsesWith(V);
      // Erase I AND recursively any operand cone it just ORPHANED. Unlike
      // ConstantFold (which folds only ALL-constant ops, so an erased op's
      // operands are Constants), this fold collapses PARTIAL-constant residues
      // whose non-constant operand is TAINTED — e.g. folding `and i1 false, %t3`
      // drops the ONLY use of `%t3 = icmp eq %q,3`. Left un-DCE'd that dead
      // tainted compare would lower to a forward `cq_template_icmp_*` gate never
      // uncomputed / never freed — an entangled which-path flag left dangling on
      // a live rail (Rule 6/8 garbage; harmless to the measured answer but a
      // coherence hazard, and trivially avoidable since the op is DEAD).
      // RecursivelyDelete removes only pure, use-free instructions (never a
      // cq_theta/phi/measure call — those have side effects — nor a value with
      // other live uses).
      RecursivelyDeleteTriviallyDeadInstructions(I);
      Changed = Any = true;
    }
  }
  return Any;
}

bool flattenPredMuxRegions(Module &M, TaintSet &Taint, bool ClaimAll) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    bool HasTaintedCtrl = false;
    for (BasicBlock &BB : F)
      if (isTaintedCtrlTerm(BB.getTerminator(), Taint))
        HasTaintedCtrl = true;
    if (!HasTaintedCtrl)
      continue;

    // bd adia (3c6m.55 Lever C): collapse constant-fold residues FIRST (an all-constant
    // compare feeding a branch — materialized late by an earlier flatten's
    // select folding or a cross-function promotion round — reads as
    // "classical control inside a tainted region" and wedges E6). Taint-safe
    // (only all-constant instructions fold; a theta-derived value is never
    // Constant). A fold is a mutation: report it so the driver re-propagates
    // before the next claim reads the region.
    if (foldConstantConesInFunction(F))
      return true;

    PostDominatorTree PDT;
    PDT.recalculate(F);
    DominatorTree DT(F);
    LoopInfo LInfo(DT);  // for the Inc-3 QROM-read claim (shared carve predicate)
    SmallPtrSet<BasicBlock *, 16> OnCycle;
    collectCycleBlocks(F, OnCycle);

    for (BasicBlock &BB : F) {
      Instruction *T = BB.getTerminator();
      if (!isTaintedCtrlTerm(T, Taint))
        continue;
      PredMuxRegion R;
      if (!recoverRegion(T, PDT, DT, LInfo, OnCycle, Taint, R, ClaimAll))
        continue;  // leave: today's loud declines own it
      IRBuilder<> Builder(T);
      Builder.SetCurrentDebugLocation(T->getDebugLoc());
      RegionFlattener(R, Builder).run();
      // bd adia (3c6m.55 Lever C): collapse fold residues the flatten materialized
      // (a select chain over constant incomings folds to a constant, leaving
      // a constant-operand compare feeding a "classical" branch that would
      // wedge the next claim's E6 walk). Taint-safe: only all-constant
      // instructions fold; the caller re-derives taint before the next claim.
      foldConstantConesInFunction(F);
      // bd 20xt.5.1(e): fold the partial-constant / degenerate-select residues
      // ConstantFold left in the flattened region so SelectClassify sees the
      // collapsed (dead-arm-free) select chain, not an `and i1 false` leaf.
      simplifyFlattenResiduesInFunction(F);
      return true;  // one region per call; caller re-propagates
    }
  }
  return false;
}

}  // namespace cq
