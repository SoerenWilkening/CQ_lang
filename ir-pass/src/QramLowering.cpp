// QramLowering.cpp — see header. Phase 7.5 Increment 1: tainted-index const-global
// READ (QROM-shaped) lowering.
//
// `classifyQromRead` is the single structural classifier; both the carve predicates
// (`isAcceptedQromLoad`/`isAcceptedQromGep`, consulted by `declineTaintEscapes`) and
// the emitter (`lowerQramReads`) go through it, so the carve and the emit can never
// diverge. The structural accept is NARROW; an accepted-shape read with an element
// width that has no reversible copy (fp/i128 cell) is loud-declined IN the emitter,
// so a carve is never a silent accept (Prime Directive; PRD-7.5 §6.9).

#include "QramLowering.h"

#include "OpcodeSupport.h"      // abiWidthFromType / widthHasReversibleCopy
#include "TaintPropagation.h"   // TaintSet
#include "WidthDispatch.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"

#include <optional>
#include <utility>

using namespace llvm;

namespace cq {

namespace {

// The exact diagnostic string the QRAM read emitter owns (PRD-7.5 §3 deliverable
// 5; the element-width gate). The negative LIT fixtures mirror it CHARACTER-FOR-
// CHARACTER (Rule 12):
//   * lowering_reject_qram_fp_cell.ll    → kMsgQramCell (a `[N x double]` cell)
//   * lowering_reject_qram_i128_cell.ll  → kMsgQramCell (a `[N x i128]` cell)
constexpr char kMsgQramCell[] =
    "cq QRAM read: array element is not a reversible integer cell";

// The exact diagnostic strings the Shadow (alloca-backed store/load) emitter owns
// (Phase 7.5 Inc 2; PRD-7.5 §2.8). The negative LIT fixtures mirror each one
// CHARACTER-FOR-CHARACTER (Rule 12):
//   * lowering_reject_qram_mixed_access.ll → kMsgQramMixed  (§6.6)
//   * lowering_reject_qram_alloca_escape.ll → kMsgQramEscape (§2.8(iv))
//   * lowering_reject_qram_mid_seq.ll      → kMsgQramMidSeq  (§2.8(iii))
// (dynamic-N alloca, fp/i128 cell, in-loop, inttoptr ride the existing generic
// decline: a flat / non-array-decay / fp gep fails the structural classifier and
// falls through to kMsgOther / kMsgQramCell — no dedicated string needed.)
constexpr char kMsgQramMixed[] =
    "cq QRAM store: alloca array mixes a tainted-index and a classical access";
constexpr char kMsgQramEscape[] =
    "cq QRAM store: alloca array escapes to an unsupported user";
constexpr char kMsgQramMidSeq[] =
    "cq QRAM store: array is observed before its last store";

// Loud `DiagnosticInfoUnsupported(DS_Error)` with the offending load's `!dbg`
// (source-located; `opt` exits non-zero, which the negative fixtures invert with
// `RUN: not`). Same idiom as `diagnoseEscape` / `FreePoint::diagnose`.
void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// The recovered structural shape of an accepted QROM read. `ElemAbi` may name an
// UNSUPPORTED width (fp/i128) — the structural shape still matches; the emitter
// performs the `widthHasReversibleCopy` gate and loud-declines.
struct QromRead {
  GetElementPtrInst *Gep;
  GlobalVariable *GV;
  StringRef ElemAbi;   // element ABI width (may be unsupported — emitter gates)
  uint64_t Count;      // array length N
  Value *RawIndex;     // the gep's last (tainted) index operand
};

// Is `I` control-dependent on a tainted-condition branch? CONSERVATIVE (Prime
// Directive): true if ANY block strictly dominating `I`'s block ends in a
// tainted-condition `br`/`switch`. 7.5 lowers STRAIGHT-LINE memory only (§2.11);
// an access inside a tainted-control region (e.g. the const `@switch.table`
// gep/load of a clang-folded jump table, control_swap_reject_switch_jumptable.ll)
// is NOT ours and must keep declining at the escape guard. Over-declining a
// straight-line access that merely sits after an unrelated tainted diamond is
// safe. Takes any memory instruction (load or store — Inc 2 reuses it).
bool instUnderTaintedControl(const Instruction *I, const TaintSet &taint,
                             DominatorTree &DT) {
  DomTreeNode *Node = DT.getNode(const_cast<BasicBlock *>(I->getParent()));
  if (!Node)
    return true;  // unreachable / no node — decline conservatively.
  for (DomTreeNode *D = Node->getIDom(); D; D = D->getIDom()) {
    const Instruction *T = D->getBlock()->getTerminator();
    if (const auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional() &&
          taint.Tainted.count(const_cast<Value *>(BI->getCondition())))
        return true;
    } else if (const auto *SI = dyn_cast<SwitchInst>(T)) {
      if (taint.Tainted.count(const_cast<Value *>(SI->getCondition())))
        return true;
    }
  }
  return false;
}

// Structural classifier — the SINGLE truth for carve + emit. A simple `load`
// whose pointer is a single-use `getelementptr` directly off a `constant`
// GlobalVariable of array type `[N x scalar]`, canonical array-decay form (exactly
// two indices: a constant-zero, then the tainted element index), NOT under tainted
// control. Returns nullopt for any non-match (those keep their existing decline).
// Takes a non-const `LoadInst*` so the recovered gep/global are mutable for the
// emitter; the const carve predicates const_cast at their boundary (the analysis
// itself mutates nothing).
std::optional<QromRead> classifyQromRead(LoadInst *LI, const TaintSet &taint,
                                         DominatorTree &DT, LoopInfo &LInfo) {
  if (!LI->isSimple())
    return std::nullopt;  // atomic / volatile is off-pattern.
  auto *GEP = dyn_cast<GetElementPtrInst>(LI->getPointerOperand());
  if (!GEP || !GEP->hasOneUse())
    return std::nullopt;  // single gep, sole-use (its only user is this load).
  // Canonical array-decay: `[N x scalar]` source element type, two indices, a
  // constant-zero leading index, a tainted trailing element index.
  auto *AT = dyn_cast<ArrayType>(GEP->getSourceElementType());
  if (!AT || GEP->getNumIndices() != 2)
    return std::nullopt;
  auto *First = dyn_cast<ConstantInt>(GEP->getOperand(1));
  if (!First || !First->isZero())
    return std::nullopt;
  Value *RawIndex = GEP->getOperand(GEP->getNumOperands() - 1);
  if (!taint.Tainted.count(RawIndex))
    return std::nullopt;  // a classical-index access on a surviving array stays
                          // classical (no spurious taint) — not ours.
  // Single PtrOrigin: the gep base is the constant global DIRECTLY (the fuller
  // provenance walk — gep chains / pointer phi-select — is Inc 3).
  auto *GV = dyn_cast<GlobalVariable>(GEP->getPointerOperand());
  if (!GV || !GV->isConstant() || !GV->hasInitializer())
    return std::nullopt;
  // A QROM cell is a SCALAR (integer or fp); a struct/array/vector element is not
  // a cell at all (structural reject → generic decline, not the cell message).
  Type *ElemTy = AT->getElementType();
  if (!ElemTy->isIntegerTy() && !ElemTy->isFloatingPointTy())
    return std::nullopt;
  if (instUnderTaintedControl(LI, taint, DT))
    return std::nullopt;  // straight-line only (§2.11).
  if (LInfo.getLoopFor(LI->getParent()))
    return std::nullopt;  // a QRAM access inside a loop needs 7.3 bounded-loop
                          // unroll — decline until then (§5/§6). A loop read is
                          // NOT under tainted control when the bound is classical,
                          // so the dominator check above does not catch it; this
                          // closes that over-accept (Prime Directive).
  return QromRead{GEP, GV, abiWidthFromType(ElemTy), AT->getNumElements(),
                  RawIndex};
}

// ── Phase 7.5 Increment 2: alloca-backed mutable array (Shadow-shaped) ──────────
//
// The recovered structural shape of ONE well-formed tainted-index access (a load
// or a store) through an `alloca [N x iW]`. The PER-ACCESS check below is what the
// carve consults; the alloca-WIDE invariants (mixed access, pointer escape,
// mid-sequence observation §2.8(iii)) are the emitter's, which loud-declines an
// unhealthy alloca whose per-access-well-formed accesses were already carved (the
// Inc-1 carve/emit-consistency discipline, §6.9 — opt exits non-zero either way).
struct ShadowAccess {
  Instruction *MemOp;       // the load or the store
  GetElementPtrInst *Gep;   // its sole-use array-decay address-gen
  AllocaInst *Alloca;       // the single PtrOrigin (Inc 2: a direct alloca base)
  StringRef ElemAbi;        // element ABI width (may be unsupported — emitter gates)
  uint64_t Count;           // array length N
  Value *RawIndex;          // the gep's last (tainted) index operand
  Value *StoreVal;          // the stored value (store only; null for a load)
  bool IsStore;
};

// Recover the well-formed Shadow access shape of a `load`/`store`, or nullopt for
// any non-match (those keep their existing decline). A simple memory op whose
// pointer is a single-use `getelementptr` in canonical array-decay form
// (`[N x iW], ptr %alloca, 0, %taintedidx`) directly off an `alloca [N x iW]`
// (const N), NOT under tainted control, NOT in a loop. The element width may be
// unsupported (fp/i128) — the STRUCTURAL shape still matches; the emitter performs
// the `widthHasReversibleCopy` gate and loud-declines. A dynamic-N alloca has a
// SCALAR allocated type (or a non-constant array-size operand), so the ArrayType /
// `isArrayAllocation` gates below reject it → it rides the generic decline.
std::optional<ShadowAccess> classifyShadowAccess(Instruction *MemOp,
                                                 const TaintSet &taint,
                                                 DominatorTree &DT,
                                                 LoopInfo &LInfo) {
  Value *PtrOp = nullptr;
  Value *StoreVal = nullptr;
  bool IsStore;
  if (auto *LI = dyn_cast<LoadInst>(MemOp)) {
    if (!LI->isSimple())
      return std::nullopt;  // atomic / volatile is off-pattern.
    PtrOp = LI->getPointerOperand();
    IsStore = false;
  } else if (auto *SI = dyn_cast<StoreInst>(MemOp)) {
    if (!SI->isSimple())
      return std::nullopt;
    PtrOp = SI->getPointerOperand();
    StoreVal = SI->getValueOperand();
    IsStore = true;
  } else {
    return std::nullopt;
  }
  auto *GEP = dyn_cast<GetElementPtrInst>(PtrOp);
  if (!GEP || !GEP->hasOneUse())
    return std::nullopt;  // single gep, sole-use (its only user is this memop).
  auto *AT = dyn_cast<ArrayType>(GEP->getSourceElementType());
  if (!AT || GEP->getNumIndices() != 2)
    return std::nullopt;  // not canonical array-decay (a flat VLA gep fails here).
  auto *First = dyn_cast<ConstantInt>(GEP->getOperand(1));
  if (!First || !First->isZero())
    return std::nullopt;
  Value *RawIndex = GEP->getOperand(GEP->getNumOperands() - 1);
  if (!taint.Tainted.count(RawIndex))
    return std::nullopt;  // a classical-index access stays classical — not ours
                          // (the carve fires only on index-or-value taint, §2.2).
  // Single PtrOrigin: the gep base is the alloca DIRECTLY (Inc 1 handles the
  // const-global base; the fuller phi/select provenance walk is Inc 3).
  auto *AI = dyn_cast<AllocaInst>(GEP->getPointerOperand());
  if (!AI || AI->isArrayAllocation())
    return std::nullopt;  // dynamic-N (non-constant array-size operand) → rides the
                          // generic decline (it is not a known compile-time shape).
  if (AI->getAllocatedType() != AT)
    return std::nullopt;  // the gep's array type must BE the alloca's type.
  Type *ElemTy = AT->getElementType();
  if (!ElemTy->isIntegerTy() && !ElemTy->isFloatingPointTy())
    return std::nullopt;  // a struct/array/vector cell is not a cell (generic decline).
  if (instUnderTaintedControl(MemOp, taint, DT))
    return std::nullopt;  // straight-line only (§2.11).
  if (LInfo.getLoopFor(MemOp->getParent()))
    return std::nullopt;  // a QRAM access inside a loop needs 7.3 unroll (§5/§6).
  return ShadowAccess{MemOp,  GEP,      AI,       abiWidthFromType(ElemTy),
                      AT->getNumElements(), RawIndex, StoreVal, IsStore};
}

// §2.8(iii): is the value `V` (a loaded cell value) OBSERVED — does it flow,
// through any chain of tainted SSA users, into a `@cq_measure_<sfx>` sink or a
// `ret`? An observation between two stores reads an INTERMEDIATE array state that a
// later store-reversal would corrupt; the emitter loud-declines that shape rather
// than silently leak (owner decision 6 — an unprovable reversal invariant is a
// loud decline). At emitter time (pre-`lowerMeasures`) a measure is still the
// front-end `@cq_measure_*` call. CONSERVATIVE: an unrecognized observation path is
// not a problem here (the spine's closure check leaks it safely anyway, §6.7), so a
// missed transitive case is not a miscompile — only a missed loud diagnostic.
bool isObservedValue(Value *V) {
  SmallVector<Value *, 8> Work{V};
  SmallPtrSet<Value *, 16> Seen;
  while (!Work.empty()) {
    Value *X = Work.pop_back_val();
    if (!Seen.insert(X).second)
      continue;
    for (User *U : X->users()) {
      if (isa<ReturnInst>(U))
        return true;
      if (auto *CI = dyn_cast<CallInst>(U)) {
        const Function *Callee = CI->getCalledFunction();
        if (Callee && Callee->getName().starts_with("cq_measure_"))
          return true;
      }
      if (auto *I = dyn_cast<Instruction>(U))
        Work.push_back(I);  // follow every SSA user (forward reachability).
    }
  }
  return false;
}

}  // namespace

bool isAcceptedQromLoad(const LoadInst *LI, const TaintSet &taint,
                        DominatorTree &DT, LoopInfo &LInfo) {
  return classifyQromRead(const_cast<LoadInst *>(LI), taint, DT, LInfo)
      .has_value();
}

bool isAcceptedQromGep(const GetElementPtrInst *GEP, const TaintSet &taint,
                       DominatorTree &DT, LoopInfo &LInfo) {
  if (!GEP->hasOneUse())
    return false;
  const auto *LI = dyn_cast<LoadInst>(GEP->user_back());
  return LI && classifyQromRead(const_cast<LoadInst *>(LI), taint, DT, LInfo)
                   .has_value();
}

void lowerQramReads(Module &M, WidthDispatch &wd, TaintSet &taint) {
  // 1. Collect accepted reads (pure analysis; do not mutate while walking the IR).
  struct Accepted {
    LoadInst *Load;
    GetElementPtrInst *Gep;
    GlobalVariable *GV;
    StringRef ElemAbi;
    uint64_t Count;
    Value *RawIndex;
  };
  SmallVector<Accepted, 8> Reads;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::optional<DominatorTree> DT;
    std::optional<LoopInfo> LInfo;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          if (!DT) {
            DT.emplace(F);
            LInfo.emplace(*DT);
          }
          if (auto QR = classifyQromRead(LI, taint, *DT, *LInfo))
            Reads.push_back({LI, QR->Gep, QR->GV, QR->ElemAbi, QR->Count,
                             QR->RawIndex});
        }
  }
  if (Reads.empty())
    return;

  Type *I32 = Type::getInt32Ty(M.getContext());
  // Lazy array-handle birth, ONE per (function, global): a const table read N
  // times in a function shares one array handle (PRD-7.5 §2.6). The handle is a
  // CLASSICAL resource token — NOT tainted (the uncompute spine ignores it).
  DenseMap<std::pair<Function *, GlobalVariable *>, Value *> ArrayHandle;
  SmallVector<Instruction *, 16> ToErase;

  for (Accepted &R : Reads) {
    // Element-width gate — the carve accepted the structural shape; an fp/i128
    // cell has no reversible copy and DECLINES LOUDLY here, so the carve is never
    // a silent accept (§6.9). `widthHasReversibleCopy` is the {i1,i8,i16,i32,i64}
    // set (the f64/angle + i128-no-clone fences, §2.10).
    if (!widthHasReversibleCopy(R.ElemAbi)) {
      diagnose(R.Load, kMsgQramCell);
      continue;
    }
    FunctionCallee AllocFn = wd.qramAllocFn(R.ElemAbi);
    FunctionCallee LoadFn = wd.qramLoadFn(R.ElemAbi);
    if (!AllocFn || !LoadFn) {
      // widthHasReversibleCopy already proved a supported width, so a null here
      // is unreachable — guard defensively rather than mint a null call.
      diagnose(R.Load, kMsgQramCell);
      continue;
    }

    Function *F = R.Load->getFunction();
    auto Key = std::make_pair(F, R.GV);
    Value *Arr = ArrayHandle.lookup(Key);
    if (!Arr) {
      IRBuilder<> AB(&*F->getEntryBlock().getFirstInsertionPt());
      CallInst *A = AB.CreateCall(AllocFn, {ConstantInt::get(I32, R.Count)}, "arr");
      if (DebugLoc DL = R.Load->getDebugLoc())
        A->setDebugLoc(DL);
      Arr = A;
      ArrayHandle[Key] = A;
    }

    // Resolve the index handle: strip the mandatory `-O1` widening sext/zext so
    // the index is the i32 handle (Rule 15 — the widening is irrelevant to the
    // symbol). The cross-type RAUW launders the operand to its i32 handle later,
    // EXACTLY like the I/O tape-write `src` (RotationLowering §1). If the cast is
    // single-use (the gep was its only user) it dies here; otherwise it is left
    // for `lowerOps` and the source value is still the right index.
    Value *Idx = R.RawIndex;
    Instruction *DeadCast = nullptr;
    if (auto *CI = dyn_cast<CastInst>(R.RawIndex))
      if ((isa<SExtInst>(CI) || isa<ZExtInst>(CI)) &&
          taint.Tainted.count(CI->getOperand(0))) {
        Idx = CI->getOperand(0);
        if (CI->hasOneUse())
          DeadCast = CI;
      }

    IRBuilder<> B(R.Load);
    CallInst *Out = B.CreateCall(LoadFn, {Arr, Idx});
    if (DebugLoc DL = R.Load->getDebugLoc())
      Out->setDebugLoc(DL);
    // The loaded value is a tainted data producer (a copy-out): record its element
    // width (the 7.1 HandleWidth discipline) and a BirthOrder slot for stable LIFO
    // uncompute ordering, exactly like a `cq_template_*` result.
    taint.Tainted.insert(Out);
    taint.HandleWidth[Out] = R.ElemAbi;
    taint.BirthOrder[Out] = taint.NextBirth++;

    R.Load->replaceAllUsesWith(Out);
    ToErase.push_back(R.Load);  // erased first — drops the gep's only use
    ToErase.push_back(R.Gep);   // then the now-dead address-gen
    if (DeadCast) {
      taint.Tainted.erase(DeadCast);
      taint.BirthOrder.erase(DeadCast);
      ToErase.push_back(DeadCast);  // then the now-dead widening cast
    }
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

namespace {

// Lower (or loud-decline) ONE candidate alloca-backed array and all its accepted
// tainted-index accesses (Phase 7.5 Inc 2). `Accesses` are in program order. The
// alloca-WIDE invariants — element width (§2.10), single-origin / no aliasing
// escape + classical initializer modeling (§2.6, §2.8(iv)), and the §2.8(iii)
// mid-sequence-observation guard — are checked here; any failure loud-declines the
// WHOLE alloca (its per-access-well-formed accesses were already carved, so opt
// exits non-zero regardless — the Inc-1 carve/emit-consistency discipline, §6.9).
void processShadowAlloca(AllocaInst *AI, ArrayRef<ShadowAccess> Accesses,
                         WidthDispatch &wd, TaintSet &taint, DominatorTree &DT) {
  StringRef ElemAbi = Accesses.front().ElemAbi;
  uint64_t Count = Accesses.front().Count;
  Instruction *Anchor = Accesses.front().MemOp;  // a real access for the !dbg.

  // Element-width gate (§2.10): an fp/i128 cell has no reversible copy → loud
  // decline, so the carve is never a silent accept (§6.9). `widthHasReversibleCopy`
  // is the {i1,i8,i16,i32,i64} set (the f64/angle + i128-no-clone fences).
  if (!widthHasReversibleCopy(ElemAbi)) {
    diagnose(Anchor, kMsgQramCell);
    return;
  }
  FunctionCallee AllocFn = wd.qramAllocFn(ElemAbi);
  FunctionCallee LoadFn = wd.qramLoadFn(ElemAbi);
  FunctionCallee StoreFn = wd.qramStoreFn(ElemAbi);
  if (!AllocFn || !LoadFn || !StoreFn) {
    diagnose(Anchor, kMsgQramCell);  // unreachable past the width gate; defensive.
    return;
  }

  SmallPtrSet<Value *, 8> AccessGeps;
  for (const ShadowAccess &A : Accesses)
    AccessGeps.insert(A.Gep);

  // §2.8(iv) provenance / no-aliasing + §2.6 initializer modeling: EVERY use of the
  // alloca must be one of (a) an accepted tainted-index access gep, (b) the
  // classical initializer (`llvm.memset` — its contents are classical metadata,
  // only the count reaches the alloc), or (c) a lifetime marker. A classical-index
  // gep on the SAME alloca is a mixed access (§6.6) — the stub model cannot keep a
  // quantum array register and a classical pointer view of the same memory
  // coherent, so DECLINE (a fully-classical SEPARATE array is never a candidate and
  // is left untouched — the "no spurious taint" property). Any other use (the
  // alloca pointer captured by a call, `ptrtoint`, a non-memset initializer) →
  // pointer/heap escape, DECLINE.
  SmallVector<Instruction *, 4> InitErase;
  for (User *U : AI->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI) {
      diagnose(AI, kMsgQramEscape);
      return;
    }
    if (isa<GetElementPtrInst>(UI)) {
      if (AccessGeps.count(UI))
        continue;  // an accepted tainted-index access.
      diagnose(UI, kMsgQramMixed);  // a classical-index / unaccepted gep.
      return;
    }
    if (auto *II = dyn_cast<IntrinsicInst>(UI)) {
      Intrinsic::ID Id = II->getIntrinsicID();
      if (Id == Intrinsic::memset || Id == Intrinsic::lifetime_start ||
          Id == Intrinsic::lifetime_end) {
        InitErase.push_back(II);
        continue;
      }
    }
    diagnose(UI, kMsgQramEscape);
    return;
  }

  // §2.8(iii) mid-sequence observation: a load whose value is OBSERVED (measured /
  // returned) with a store to this array AFTER it (program order) reads an
  // intermediate state a later store-reversal would corrupt → loud decline (owner
  // decision 6 — an unprovable reversal invariant is a loud decline, never a silent
  // leak). The array may Escape ONLY after its last store.
  for (const ShadowAccess &L : Accesses) {
    if (L.IsStore || !isObservedValue(L.MemOp))
      continue;
    for (const ShadowAccess &S : Accesses) {
      if (!S.IsStore)
        continue;
      bool After = (S.MemOp->getParent() == L.MemOp->getParent())
                       ? L.MemOp->comesBefore(S.MemOp)
                       : DT.dominates(L.MemOp, S.MemOp);
      if (After) {
        diagnose(S.MemOp, kMsgQramMidSeq);
        return;
      }
    }
  }

  // All invariants hold → emit. Array-handle birth: ONE `cqrt_qram_alloc_<W>(N)` at
  // entry. TAINTED — an alloca-backed mutable array is an in-place-mutated register
  // the whole-DAG uncompute spine reverses (a dead scratch array's stores reverse
  // in LIFO; an escaped/measured array reverses nothing); the handle is a CLASSICAL
  // resource token NEVER freed (§2.9; unlike a const-global QROM array, Inc 1, this
  // one is tainted so the spine treats it as a register).
  Module &M = *AI->getModule();
  Type *I32 = Type::getInt32Ty(M.getContext());
  IRBuilder<> AB(&*AI->getFunction()->getEntryBlock().getFirstInsertionPt());
  CallInst *Arr = AB.CreateCall(AllocFn, {ConstantInt::get(I32, Count)}, "arr");
  if (DebugLoc DL = Anchor->getDebugLoc())
    Arr->setDebugLoc(DL);
  taint.Tainted.insert(Arr);
  taint.BirthOrder[Arr] = taint.NextBirth++;

  SmallVector<Instruction *, 16> ToErase;
  for (const ShadowAccess &A : Accesses) {
    // Resolve the index handle: strip the mandatory `-O1` widening sext/zext so the
    // index is the i32 handle (Rule 15) — the cross-type RAUW launders it later,
    // EXACTLY like Inc 1's read and the I/O tape-write `src`.
    Value *Idx = A.RawIndex;
    Instruction *DeadCast = nullptr;
    if (auto *CI = dyn_cast<CastInst>(A.RawIndex))
      if ((isa<SExtInst>(CI) || isa<ZExtInst>(CI)) &&
          taint.Tainted.count(CI->getOperand(0))) {
        Idx = CI->getOperand(0);
        if (CI->hasOneUse())
          DeadCast = CI;
      }

    IRBuilder<> B(A.MemOp);
    if (A.IsStore) {
      // Resolve the value handle. A tainted value is its OWN handle (RAUW'd to i32
      // later). A classical value is materialized into a basis-state handle via
      // `cqrt_alloc_<W>` so the (arr, idx, val) trace stays all-handles (the
      // resolved OPEN decision, §2.5); that handle is a CLASSICAL resource token
      // (untainted) — left allocated, never freed (a bounded safe-leak, like the
      // array handle itself, §2.9).
      Value *Val = A.StoreVal;
      if (!taint.Tainted.count(Val)) {
        FunctionCallee Alloc = wd.allocFn(ElemAbi);
        CallInst *VH = B.CreateCall(Alloc, {Val}, "qval");
        if (DebugLoc DL = A.MemOp->getDebugLoc())
          VH->setDebugLoc(DL);
        Val = VH;
      }
      CallInst *St = B.CreateCall(StoreFn, {Arr, Idx, Val});
      if (DebugLoc DL = A.MemOp->getDebugLoc())
        St->setDebugLoc(DL);
      ToErase.push_back(A.MemOp);  // the store
    } else {
      CallInst *Out = B.CreateCall(LoadFn, {Arr, Idx});
      if (DebugLoc DL = A.MemOp->getDebugLoc())
        Out->setDebugLoc(DL);
      // A loaded value is a tainted reversible data producer (copy-out): record its
      // width + a BirthOrder slot, exactly like a `cq_template_*` result and Inc 1.
      taint.Tainted.insert(Out);
      taint.HandleWidth[Out] = ElemAbi;
      taint.BirthOrder[Out] = taint.NextBirth++;
      A.MemOp->replaceAllUsesWith(Out);
      ToErase.push_back(A.MemOp);  // the load
    }
    ToErase.push_back(A.Gep);  // the now-dead address-gen
    if (DeadCast) {
      taint.Tainted.erase(DeadCast);
      taint.BirthOrder.erase(DeadCast);
      ToErase.push_back(DeadCast);  // the now-dead widening cast
    }
  }

  // Erase memops + geps + dead casts FIRST (drops the alloca's gep uses), then the
  // initializer (memset / lifetime markers), then the alloca LAST (no uses remain).
  for (Instruction *I : ToErase)
    I->eraseFromParent();
  for (Instruction *I : InitErase)
    I->eraseFromParent();
  AI->eraseFromParent();
}

}  // namespace

bool isAcceptedShadowGep(const GetElementPtrInst *GEP, const TaintSet &taint,
                         DominatorTree &DT, LoopInfo &LInfo) {
  if (!GEP->hasOneUse())
    return false;
  const auto *MemOpC = dyn_cast<Instruction>(GEP->user_back());
  if (!MemOpC || (!isa<LoadInst>(MemOpC) && !isa<StoreInst>(MemOpC)))
    return false;
  return classifyShadowAccess(const_cast<Instruction *>(MemOpC), taint, DT, LInfo)
      .has_value();
}

bool isAcceptedShadowLoad(const LoadInst *LI, const TaintSet &taint,
                          DominatorTree &DT, LoopInfo &LInfo) {
  return classifyShadowAccess(const_cast<LoadInst *>(LI), taint, DT, LInfo)
      .has_value();
}

bool isAcceptedShadowStore(const StoreInst *SI, const TaintSet &taint,
                           DominatorTree &DT, LoopInfo &LInfo) {
  return classifyShadowAccess(const_cast<StoreInst *>(SI), taint, DT, LInfo)
      .has_value();
}

void lowerShadowMemory(Module &M, WidthDispatch &wd, TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::optional<DominatorTree> DT;
    std::optional<LoopInfo> LInfo;
    // Collect every well-formed tainted-index access, grouped by its origin alloca,
    // in program order. First-seen alloca order keeps the emission deterministic
    // (FileCheck-stable), and the per-alloca vector is in program order because the
    // BB/instruction walk is.
    SmallVector<AllocaInst *, 4> Order;
    DenseMap<AllocaInst *, SmallVector<ShadowAccess, 8>> ByAlloca;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        if (!isa<LoadInst>(&I) && !isa<StoreInst>(&I))
          continue;
        if (!DT) {
          DT.emplace(F);
          LInfo.emplace(*DT);
        }
        if (auto A = classifyShadowAccess(&I, taint, *DT, *LInfo)) {
          if (!ByAlloca.count(A->Alloca))
            Order.push_back(A->Alloca);
          ByAlloca[A->Alloca].push_back(*A);
        }
      }
    for (AllocaInst *AI : Order)
      processShadowAlloca(AI, ByAlloca[AI], wd, taint, *DT);
  }
}

}  // namespace cq
