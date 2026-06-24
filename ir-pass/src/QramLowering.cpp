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
//   * lowering_reject_qram_nonzero_init.ll → kMsgQramInit    (§2.6/§6.5, Inc 3)
constexpr char kMsgQramMixed[] =
    "cq QRAM store: alloca array mixes a tainted-index and a classical access";
constexpr char kMsgQramEscape[] =
    "cq QRAM store: alloca array escapes to an unsupported user";
constexpr char kMsgQramMidSeq[] =
    "cq QRAM store: array is observed before its last store";
// §2.6/§6.5 (Inc 3 — the Rule-13 initializer-mis-modeling fix): the trace runtime
// models a fresh QRAM array as |0⟩ cells (`cqrt_qram_alloc_<W>` records only the
// COUNT). A `memset` with a NON-ZERO (or non-constant) fill byte seeds classical
// contents the stub cannot represent — a later `load` of an un-overwritten cell
// would read 0 in the model while the true value is the fill (verify-clean WRONG
// DATA, PRD §6 risk #5). Only a ZERO-fill memset matches the model; any other
// initializer loud-declines (the QROM read path, Inc 1, carries real const
// contents through the const-global origin instead).
constexpr char kMsgQramInit[] =
    "cq QRAM store: alloca array has a non-zero initializer the trace model cannot represent";

// Phase 7.5 Increment 3 — the pattern-naming decline matrix (PRD-7.5 §2.8(iv),
// §5/§6; the Bennett signpost model). Each names the EXACT off-pattern the
// provenance walk could not prove a single statically-shaped origin for; the
// negative LIT fixtures mirror each one CHARACTER-FOR-CHARACTER (Rule 12). These
// are fired in `declineTaintEscapes` via `classifyQramCarve` (per-access info
// suffices); the alloca-WIDE declines (mixed/escape/mid-seq above) stay in the
// emitter. What stays rejected after 7.5 is forbidden by no-cloning / linearity
// ([[pointer-boundary-linearity-bennett]]), not a CQ shortcut.
//   * lowering_reject_qram_multi_origin.ll   → kMsgQramMultiOrigin
//   * lowering_reject_qram_inttoptr.ll       → kMsgQramProvenance
//   * lowering_reject_qram_ptrtoint.ll       → kMsgQramProvenance
//   * lowering_reject_qram_addrspacecast.ll  → kMsgQramAddrSpace
//   * lowering_reject_qram_dynamic_n.ll      → kMsgQramDynN
//   * lowering_reject_qram_heap.ll           → kMsgQramHeap
//   * lowering_reject_qram_aliasing.ll       → kMsgQramAlias
//   * lowering_reject_qram_in_loop.ll        → kMsgQramLoop
constexpr char kMsgQramMultiOrigin[] =
    "cq QRAM access: pointer resolves to multiple array origins";
constexpr char kMsgQramProvenance[] =
    "cq QRAM access: pointer has no static array provenance";
constexpr char kMsgQramAddrSpace[] =
    "cq QRAM access: pointer crosses an address space";
constexpr char kMsgQramDynN[] =
    "cq QRAM access: array has no compile-time shape (dynamic-size alloca)";
constexpr char kMsgQramHeap[] =
    "cq QRAM access: array has no compile-time shape (heap allocation)";
constexpr char kMsgQramAlias[] =
    "cq QRAM access: array address has aliasing fan-out";
constexpr char kMsgQramLoop[] =
    "cq QRAM access: tainted-index memory access inside a loop";
// The coherent-return no-cloning fence (bug test_C_libtooling-l6xk + the sxuk
// direct-return / Inc-1 QROM-return regressions; VERIFIED physics 2026-06-24,
// memory 7-5-qram-coherent-return-nocloning). A qRAM LOAD at a superposed index
// produces a value ENTANGLED with that index (`arr[p] = [p==q]·v`, a function of
// the load AND store addresses). When such a value flows COHERENTLY (through
// tainted reversible ops, NOT through a measure/tape collapse sink) into a
// `ret` / `cq_invert` of a NON-`main` function, the whole-DAG reversal uncomputes
// and FREES the LOCAL (`cq_theta`) index rails it is entangled with — a dirty free
// (= hidden measurement, Rule 6) that DEPHASES the returned carrier to a classical
// mixture (off-diagonal coherence exactly 0; reduced ρ = diag(2c²s², c⁴+s⁴)). By
// no-cloning/monogamy NO reversible circuit can return a clean coherent `arr[p]`
// once its local address is erased — leaving the index allocated only DEFERS the
// collapse (the carrier is mixed the instant the copy-out fires). So the ONLY
// correct action is a LOUD DECLINE. A MEASURE collapses the value first (immune —
// the index-free is unobservable and the diagonal IS the correct distribution);
// `main`'s `ret` is the process-exit observation. The negative LIT fixtures mirror
// this CHARACTER-FOR-CHARACTER:
//   * lowering_reject_qram_coherent_return.ll       → kMsgQramCohEscape (Shadow)
//   * lowering_reject_qram_read_coherent_return.ll  → kMsgQramCohEscape (QROM)
constexpr char kMsgQramCohEscape[] =
    "cq QRAM load: coherently escaping value is entangled with a local index (no-cloning)";

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

// ── Phase 7.5 Increment 2: alloca-backed mutable array (Shadow-shaped) ──────────
// The recovered structural shape of ONE well-formed tainted-index access (a load
// or a store) through an `alloca [N x iW]`. The alloca-WIDE invariants (mixed
// access, pointer escape, mid-sequence observation §2.8(iii)) are the emitter's.
struct ShadowAccess {
  Instruction *MemOp;       // the load or the store
  GetElementPtrInst *Gep;   // its sole-use array-decay / flat address-gen
  AllocaInst *Alloca;       // the single PtrOrigin
  StringRef ElemAbi;        // element ABI width (may be unsupported — emitter gates)
  uint64_t Count;           // array length N
  Value *RawIndex;          // the gep's trailing (tainted) index operand
  Value *StoreVal;          // the stored value (store only; null for a load)
  bool IsStore;
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

// ── Phase 7.5 Increment 3: the single-PtrOrigin provenance walk ─────────────────
//
// A recognized heap allocator (`malloc`/`calloc`/`realloc`/`aligned_alloc`/C++
// `operator new` mangled forms) — a pointer with NO compile-time shape (the heap
// reject, [[pointer-boundary-linearity-bennett]]). EXACT-name membership (never a
// `starts_with` accept) so a user `malloc_helper` is not mistaken for the libc
// allocator; any OTHER call origin rides the generic no-provenance reject anyway.
bool isAllocatorCall(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return N == "malloc" || N == "calloc" || N == "realloc" ||
         N == "aligned_alloc" || N == "reallocf" || N == "valloc" ||
         N == "_Znwm" || N == "_Znam";  // operator new / new[]
}

// The resolved base object of a pointer chain, OR a named decline reason. `Msg`
// is non-null exactly when `Kind == Bad` (the pattern-naming diagnostic the
// carve fires; PRD-7.5 §2.8(iv)).
struct OriginResult {
  enum K { Alloca, Global, Bad } Kind;
  AllocaInst *AI = nullptr;
  GlobalVariable *GV = nullptr;
  const char *Msg = nullptr;
};

OriginResult originAlloca(AllocaInst *AI) { return {OriginResult::Alloca, AI, nullptr, nullptr}; }
OriginResult originGlobal(GlobalVariable *GV) { return {OriginResult::Global, nullptr, GV, nullptr}; }
OriginResult originBad(const char *M) { return {OriginResult::Bad, nullptr, nullptr, M}; }

// Do two origins name the SAME base object? (phi/select single-origin proof.)
bool sameOrigin(const OriginResult &A, const OriginResult &B) {
  if (A.Kind != B.Kind)
    return false;
  return A.Kind == OriginResult::Alloca ? A.AI == B.AI
       : A.Kind == OriginResult::Global ? A.GV == B.GV
                                        : false;
}

// The recursion-depth ceiling for the pointer-provenance walks. Real `-O1`
// pointer chains are a handful of nodes; a chain deeper than this is pathological
// (or a loop-carried-phi cycle) → conservatively decline rather than recurse
// forever. Depth-bounding (vs a visited-set) avoids a FALSE cycle when a value is
// legitimately reachable from BOTH arms of a phi/select (diamond reconvergence —
// the degenerate single-origin proof).
constexpr unsigned kPtrWalkMaxDepth = 32;

// Resolve `P` to its unique statically-shaped base object, following `bitcast`,
// `getelementptr` bases (gep chains), and pointer `phi`/`select` (ALL arms must
// resolve to the SAME origin). Returns a named `Bad` for any shape that is not a
// single statically-shaped origin — the Bennett signpost decline matrix.
// Mutation-free.
OriginResult walkPtrOrigin(Value *P, unsigned Depth = 0) {
  if (Depth > kPtrWalkMaxDepth)
    return originBad(kMsgQramMultiOrigin);  // pathological / cyclic (loop) chain.
  if (auto *AI = dyn_cast<AllocaInst>(P)) {
    if (AI->isArrayAllocation() || !isa<ArrayType>(AI->getAllocatedType()))
      return originBad(kMsgQramDynN);  // VLA / scalar alloca — no compile-time shape.
    return originAlloca(AI);
  }
  if (auto *GV = dyn_cast<GlobalVariable>(P)) {
    if (!isa<ArrayType>(GV->getValueType()))
      return originBad(kMsgQramProvenance);  // a non-array global is not a table.
    return originGlobal(GV);
  }
  if (auto *GEP = dyn_cast<GetElementPtrInst>(P))
    return walkPtrOrigin(GEP->getPointerOperand(), Depth + 1);  // gep chain.
  if (auto *BC = dyn_cast<BitCastInst>(P))
    return walkPtrOrigin(BC->getOperand(0), Depth + 1);
  if (isa<AddrSpaceCastInst>(P))
    return originBad(kMsgQramAddrSpace);
  if (isa<IntToPtrInst>(P))
    return originBad(kMsgQramProvenance);  // a forged address (inttoptr/ptrtoint).
  if (auto *Phi = dyn_cast<PHINode>(P)) {
    OriginResult Acc = originBad(kMsgQramMultiOrigin);
    bool First = true;
    for (Value *In : Phi->incoming_values()) {
      OriginResult R = walkPtrOrigin(In, Depth + 1);
      if (R.Kind == OriginResult::Bad)
        return R;  // propagate the most specific reason.
      if (First) { Acc = R; First = false; continue; }
      if (!sameOrigin(Acc, R))
        return originBad(kMsgQramMultiOrigin);  // ≥2 distinct origins.
    }
    return First ? originBad(kMsgQramProvenance) : Acc;
  }
  if (auto *Sel = dyn_cast<SelectInst>(P)) {
    OriginResult T = walkPtrOrigin(Sel->getTrueValue(), Depth + 1);
    if (T.Kind == OriginResult::Bad)
      return T;
    OriginResult F = walkPtrOrigin(Sel->getFalseValue(), Depth + 1);
    if (F.Kind == OriginResult::Bad)
      return F;
    return sameOrigin(T, F) ? T : originBad(kMsgQramMultiOrigin);
  }
  if (auto *CI = dyn_cast<CallInst>(P))
    return originBad(isAllocatorCall(CI) ? kMsgQramHeap : kMsgQramProvenance);
  return originBad(kMsgQramProvenance);  // Argument / unknown → no provenance.
}

// Is `P` a DIRECT origin pointer — `Origin` with a provable ZERO net offset? True
// iff `P`, stripping `bitcast`, IS the origin object, OR a `phi`/`select` ALL of
// whose arms are themselves direct. A gep-with-offset, or a same-origin-but-
// different-offset phi/select, is NOT direct (the index would not be cleanly the
// trailing gep operand — decline, Prime Directive). This is the offset-cleanliness
// half of the §2.8(iv) accept; `walkPtrOrigin` proves the single origin, this
// proves the clean index.
bool isDirectOriginPtr(Value *P, const OriginResult &Origin, unsigned Depth = 0) {
  if (Depth > kPtrWalkMaxDepth)
    return false;  // pathological / cyclic chain — conservatively not direct.
  if (auto *BC = dyn_cast<BitCastInst>(P))
    return isDirectOriginPtr(BC->getOperand(0), Origin, Depth + 1);
  if (Origin.Kind == OriginResult::Alloca && P == Origin.AI)
    return true;
  if (Origin.Kind == OriginResult::Global && P == Origin.GV)
    return true;
  if (auto *Phi = dyn_cast<PHINode>(P)) {
    for (Value *In : Phi->incoming_values())
      if (!isDirectOriginPtr(In, Origin, Depth + 1))
        return false;
    return Phi->getNumIncomingValues() > 0;
  }
  if (auto *Sel = dyn_cast<SelectInst>(P))
    return isDirectOriginPtr(Sel->getTrueValue(), Origin, Depth + 1) &&
           isDirectOriginPtr(Sel->getFalseValue(), Origin, Depth + 1);
  return false;  // a gep (offset) or anything else → not a direct origin pointer.
}

// The accessed-cell shape recovered from a memop's address gep: the trailing
// (tainted) index, the cell scalar type, and the gep itself. Returns false for a
// non-canonical gep (multi-index struct gep, non-zero leading index, a tainted
// NON-trailing index). Handles BOTH array-decay (`[N x E], base, 0, idx`) and the
// flat element form (`E, base, idx`) clang -O1 emits for pointer-indirected
// access (Inc 3, the realistic phi/select shape).
bool matchAddressGep(GetElementPtrInst *GEP, const TaintSet &taint,
                     Value *&RawIndex, Type *&CellTy) {
  Type *Src = GEP->getSourceElementType();
  if (auto *AT = dyn_cast<ArrayType>(Src)) {
    // Array-decay: exactly (const-zero, trailing index).
    if (GEP->getNumIndices() != 2)
      return false;
    auto *First = dyn_cast<ConstantInt>(GEP->getOperand(1));
    if (!First || !First->isZero())
      return false;
    CellTy = AT->getElementType();
  } else if (Src->isIntegerTy() || Src->isFloatingPointTy()) {
    // Flat element gep: exactly one index.
    if (GEP->getNumIndices() != 1)
      return false;
    CellTy = Src;
  } else {
    return false;  // a struct / vector / aggregate source element is not a cell.
  }
  RawIndex = GEP->getOperand(GEP->getNumOperands() - 1);
  return taint.Tainted.count(RawIndex);  // the trailing index must be tainted.
}

// The SINGLE structural ACCEPT — the shared truth for the carve AND both emitters
// (carve/emit can never diverge; the Inc 1 discipline). A simple `load`/`store`
// whose pointer is a single-use gep (array-decay OR flat) with a tainted trailing
// index, whose base resolves to a SINGLE statically-shaped origin (`walkPtrOrigin`)
// reached with a provable ZERO offset (`isDirectOriginPtr`), of array type
// `[N x E]` with a SCALAR cell `E` matching the gep, NOT under tainted control and
// NOT in a loop. The element width may be unsupported (fp/i128) — the structural
// shape still matches; the emitter width-gates it to kMsgQramCell (a carve is never
// a silent accept). Returns the resolved origin + shape, or nullopt.
struct QramMatch {
  Instruction *MemOp;
  GetElementPtrInst *Gep;
  OriginResult Origin;     // Alloca (Shadow) or Global (QROM read)
  StringRef ElemAbi;
  uint64_t Count;
  Value *RawIndex;
  Value *StoreVal;         // store only
  bool IsStore;
};

std::optional<QramMatch> matchQramAccess(Instruction *MemOp,
                                         const TaintSet &taint, DominatorTree &DT,
                                         LoopInfo &LInfo) {
  Value *PtrOp = nullptr;
  Value *StoreVal = nullptr;
  bool IsStore;
  if (auto *LI = dyn_cast<LoadInst>(MemOp)) {
    if (!LI->isSimple())
      return std::nullopt;
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
    return std::nullopt;  // single-use address gep (sole user is this memop).
  Value *RawIndex = nullptr;
  Type *CellTy = nullptr;
  if (!matchAddressGep(GEP, taint, RawIndex, CellTy))
    return std::nullopt;  // non-canonical / classical-index gep — not ours.
  Value *Base = GEP->getPointerOperand();
  OriginResult Origin = walkPtrOrigin(Base);
  if (Origin.Kind == OriginResult::Bad)
    return std::nullopt;  // not a single statically-shaped origin (carve names it).
  if (!isDirectOriginPtr(Base, Origin))
    return std::nullopt;  // dynamic / non-zero base offset — index not clean.
  Type *OriginArrTy = Origin.Kind == OriginResult::Alloca
                          ? Origin.AI->getAllocatedType()
                          : Origin.GV->getValueType();
  auto *OT = dyn_cast<ArrayType>(OriginArrTy);
  if (!OT || OT->getElementType() != CellTy)
    return std::nullopt;  // shape mismatch — the gep cell must be the origin cell.
  if (OT->getNumElements() == 0)
    return std::nullopt;  // a `[0 x iW]` array has no cell — any index is OOB (a
                          // degenerate/UB shape). Decline (Rule-13 Finding 2).
  Type *E = OT->getElementType();
  if (!E->isIntegerTy() && !E->isFloatingPointTy())
    return std::nullopt;
  if (Origin.Kind == OriginResult::Global &&
      (!Origin.GV->isConstant() || !Origin.GV->hasInitializer()))
    return std::nullopt;  // a QROM table must be a constant initialized global.
  if (instUnderTaintedControl(MemOp, taint, DT))
    return std::nullopt;  // straight-line only (§2.11).
  if (LInfo.getLoopFor(MemOp->getParent()))
    return std::nullopt;  // a QRAM access in a loop needs 7.3 unroll (§5/§6).
  return QramMatch{MemOp,  GEP,      Origin,   abiWidthFromType(E),
                   OT->getNumElements(), RawIndex, StoreVal, IsStore};
}

// QROM-read wrapper: an accepted access whose origin is a constant GLOBAL (Inc 1).
std::optional<QromRead> classifyQromRead(LoadInst *LI, const TaintSet &taint,
                                         DominatorTree &DT, LoopInfo &LInfo) {
  auto M = matchQramAccess(LI, taint, DT, LInfo);
  if (!M || M->Origin.Kind != OriginResult::Global)
    return std::nullopt;
  return QromRead{M->Gep, M->Origin.GV, M->ElemAbi, M->Count, M->RawIndex};
}

// Shadow wrapper: an accepted access whose origin is an ALLOCA (Inc 2).
std::optional<ShadowAccess> classifyShadowAccess(Instruction *MemOp,
                                                 const TaintSet &taint,
                                                 DominatorTree &DT,
                                                 LoopInfo &LInfo) {
  auto M = matchQramAccess(MemOp, taint, DT, LInfo);
  if (!M || M->Origin.Kind != OriginResult::Alloca)
    return std::nullopt;
  return ShadowAccess{M->MemOp,  M->Gep,   M->Origin.AI, M->ElemAbi,
                      M->Count,  M->RawIndex, M->StoreVal, M->IsStore};
}

// The carve verdict for `declineTaintEscapes` (Inc 3). A tainted-pointer
// load/store is in QRAM's domain: it is Accepted (the emitter lowers it),
// loud-Declined with a pattern-naming message (fired HERE — per-access info
// suffices; the alloca-WIDE declines stay in the emitter), or NotQram (falls to
// the generic loud decline). A tainted address-gen GEP is carved so only its
// memop renders the verdict. TOTALITY: every tainted-pointer memop is Accept,
// Decline, or NotQram (→ generic kMsgOther/kMsgStore) — never a silent gap.
// (`QramCarve` is declared in QramLowering.h — the carve consumer's enum.)
QramCarve classifyQramCarve(const Instruction *I, const TaintSet &taint,
                            DominatorTree &DT, LoopInfo &LInfo,
                            const char *&Msg) {
  // A tainted address-gen GEP whose users are all pointer consumers (load/store/
  // gep) is carved — suppress its generic decline; its memop owns the verdict. An
  // escaping use (the gep captured as a value / ptrtoint'd) or a control-region
  // gep falls to the generic decline. (Avoids a duplicate message on the gep.)
  if (auto *GEP = dyn_cast<GetElementPtrInst>(I)) {
    if (!taint.Tainted.count(const_cast<GetElementPtrInst *>(GEP)))
      return QramCarve::NotQram;
    if (instUnderTaintedControl(GEP, taint, DT))
      return QramCarve::NotQram;
    for (const User *U : GEP->users()) {
      if (const auto *LU = dyn_cast<LoadInst>(U))
        if (LU->getPointerOperand() == GEP)
          continue;
      if (const auto *SU = dyn_cast<StoreInst>(U))
        if (SU->getPointerOperand() == GEP)
          continue;
      if (const auto *GU = dyn_cast<GetElementPtrInst>(U))
        if (GU->getPointerOperand() == GEP)
          continue;
      return QramCarve::NotQram;  // the address escapes as a value — generic.
    }
    return QramCarve::Accept;  // pure address-gen — carve it.
  }

  Value *PtrOp = nullptr;
  if (auto *LI = dyn_cast<LoadInst>(I))
    PtrOp = const_cast<Value *>(LI->getPointerOperand());
  else if (auto *SI = dyn_cast<StoreInst>(I))
    PtrOp = const_cast<Value *>(SI->getPointerOperand());
  else
    return QramCarve::NotQram;

  if (!taint.Tainted.count(PtrOp))
    return QramCarve::NotQram;  // classical-address access (value-tainted store →
                                // generic kMsgStore; out of QRAM scope).
  if (instUnderTaintedControl(I, taint, DT))
    return QramCarve::NotQram;  // ControlDetect/generic domain (jumptable kMsgOther).
  if (LInfo.getLoopFor(I->getParent())) {
    Msg = kMsgQramLoop;
    return QramCarve::Decline;
  }
  if (matchQramAccess(const_cast<Instruction *>(I), taint, DT, LInfo))
    return QramCarve::Accept;  // the emitter lowers it (or width-gates fp/i128).

  // Tainted-pointer access we cannot accept → name the decline via the chain.
  if (auto *GEP = dyn_cast<GetElementPtrInst>(PtrOp)) {
    if (!GEP->hasOneUse()) {
      Msg = kMsgQramAlias;  // a shared address gep — aliasing fan-out (§6.3).
      return QramCarve::Decline;
    }
    OriginResult O = walkPtrOrigin(GEP->getPointerOperand());
    if (O.Kind == OriginResult::Bad) {
      Msg = O.Msg;
      return QramCarve::Decline;
    }
    // A clean single origin that failed the offset/shape cleanliness (e.g. a
    // dynamic byte offset, sel_single) → generic loud decline (safe, not silent).
    return QramCarve::NotQram;
  }
  // Pointer is not a gep (inttoptr / addrspacecast / phi / argument …) — walk it.
  OriginResult O = walkPtrOrigin(PtrOp);
  if (O.Kind == OriginResult::Bad) {
    Msg = O.Msg;
    return QramCarve::Decline;
  }
  return QramCarve::NotQram;
}

// §2.8(iii): is the value `V` (a loaded cell value) OBSERVED — does it flow,
// through any chain of tainted SSA users, into a sink that reads the intermediate
// array state? An observation between two stores reads an INTERMEDIATE array state
// that a later store-reversal would corrupt; the emitter loud-declines that shape
// rather than silently leak (owner decision 6 — an unprovable reversal invariant is
// a loud decline). Three sinks, all present at emitter time (after `lowerIOSinks`,
// before `lowerMeasures`/`lowerRotations`):
//   * a `ret` (the value leaves the function);
//   * a `@cq_measure_<sfx>` front-end measurement sink (not yet lowered here);
//   * a `@cqrt_tape_write_<W>` I/O OUTPUT sink (Inc 3 — `lowerIOSinks` already
//     lowered a `printf(arr[p])` to a tape write; WITHOUT this the output-observed
//     load lowered + then tripped the CONFUSING spine `kMsgDivergentArm` instead of
//     the clean `kMsgQramMidSeq`. bd 7z9k.3 over-decline hardening #1).
// CONSERVATIVE: an unrecognized observation path is not a miscompile here (the
// spine's closure check leaks it safely anyway, §6.7) — only a missed diagnostic.
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
        StringRef N = Callee ? Callee->getName() : StringRef();
        if (N.starts_with("cq_measure_") || N.starts_with("cqrt_tape_write_"))
          return true;
      }
      if (auto *I = dyn_cast<Instruction>(U))
        Work.push_back(I);  // follow every SSA user (forward reachability).
    }
  }
  return false;
}

// Does the loaded value `V` flow COHERENTLY into a `ret` / `cq_invert` escape —
// i.e. through tainted reversible ops, WITHOUT first passing a collapse/observe
// sink? This is the precondition for the kMsgQramCohEscape decline (the no-cloning
// fence above). The walk STOPS at a `@cq_measure_*` measurement sink or a
// `@cqrt_tape_write_*` I/O sink (both COLLAPSE/observe the value — its coherence is
// already gone, so anything downstream is classical, not a coherent escape); it
// returns true the moment it reaches a `ret` or a `@cq_invert_*` escape by any
// other path. CONSERVATIVE (Prime Directive): following every SSA user can only
// over-detect an escape, which over-declines (safe), never under-declines. Runs at
// emitter time (after `lowerIOSinks`, before `lowerMeasures`/`lowerOps`), so the
// arithmetic chain is still raw LLVM and `cq_measure_` is still the front-end form.
bool coherentlyEscapesToReturn(Value *V) {
  SmallVector<Value *, 8> Work{V};
  SmallPtrSet<Value *, 16> Seen;
  while (!Work.empty()) {
    Value *X = Work.pop_back_val();
    if (!Seen.insert(X).second)
      continue;
    for (User *U : X->users()) {
      if (isa<ReturnInst>(U))
        return true;  // a coherent return of the (transformed) loaded value.
      if (auto *CI = dyn_cast<CallInst>(U)) {
        const Function *Callee = CI->getCalledFunction();
        StringRef N = Callee ? Callee->getName() : StringRef();
        if (N.starts_with("cq_invert_"))
          return true;  // manual-inversion escape (Phase 8) — same no-cloning wall.
        if (N.starts_with("cq_measure_") || N.starts_with("cqrt_tape_write_"))
          continue;  // a COLLAPSE/observe sink — coherence already gone; do not
                     // descend through its (void/classical) result. This `continue`
                     // only skips THIS user; the loop still examines the value's
                     // OTHER users, so a value that is BOTH taped/measured AND
                     // coherently returned still trips the `ret` below (verified) —
                     // the stop cannot hide a coherent escape.
      }
      if (auto *I = dyn_cast<Instruction>(U))
        Work.push_back(I);  // follow the forward tainted-reversible chain.
    }
  }
  return false;
}

}  // namespace

// The single carve entry point for `declineTaintEscapes` (Inc 3, replacing the
// per-family `isAccepted*` predicates). For a tainted-pointer `load`/`store`/`gep`
// returns Accept (the emitter owns it), Decline (with `outMsg`, a pattern-naming
// diagnostic the caller fires source-located), or NotQram (fall to the generic
// taint-escape decline). The emitter classifiers (`classifyQromRead` /
// `classifyShadowAccess`) share the same `matchQramAccess`, so carve and emit can
// never diverge.
QramCarve qramCarveVerdict(const llvm::Instruction *I, const TaintSet &taint,
                           DominatorTree &DT, LoopInfo &LInfo,
                           const char *&outMsg) {
  return classifyQramCarve(I, taint, DT, LInfo, outMsg);
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
    // Coherent-return no-cloning fence (Inc-1 QROM regression; memory
    // 7-5-qram-coherent-return-nocloning): `return tbl[q]` (non-`main`) returns a
    // value entangled with the LOCAL index `q`; with `q` uncomputed/leaked the
    // returned carrier is dephased to a classical mixture (verify-clean silent
    // miscompile). DECLINE — a coherent qRAM-load value cannot escape once its
    // local address is erased. A MEASURE collapses it first (immune); `main`'s ret
    // is the process-exit observation.
    if (R.Load->getFunction()->getName() != "main" &&
        coherentlyEscapesToReturn(R.Load)) {
      diagnose(R.Load, kMsgQramCohEscape);
      continue;
    }
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

// Phase 7.5 (bug sxuk): method-B copy-out for a load result whose SOLE, DIRECT user
// is a `cq_measure_*` sink in a non-`main` function. WITHOUT it the load result is
// the SOLE tainted data terminal, FreePoint classifies it Measured, and the
// whole-DAG reversal — INCLUDING the LOCAL array's stores — is skipped (the
// `InsertTerms.empty()` bail): the measured value stays entangled with the leaked
// local scratch array. The copy makes `Out` a NON-escaped terminal whose load+store
// chain uncomputes via the EXISTING dead-array reversal (the spine treats
// `cqrt_copy` reading src as a source-preserving sink, ChainWalk::isCopyOutSink),
// while the copy DESTINATION is the kept measured carrier — and the local array's
// stores reverse to |0>. The reversal frees the LOCAL index rails, which is sound
// HERE precisely because the value is MEASURED: the collapse makes the index-free
// unobservable and the diagonal is the correct measurement distribution (memory
// 7-5-qram-coherent-return-nocloning). A COHERENT `ret`/`cq_invert` escape is NOT
// handled here — it is loud-declined upstream (kMsgQramCohEscape) since no-cloning
// forbids returning a clean coherent `arr[p]` once its local index is erased.
//
// Scope: `Out`'s SOLE, DIRECT user is a `cq_measure_*`. A taped load
// (cqrt_tape_write) already uncomputes (isOutputSink), so its sole user is not a
// measure here; `main` escapes anyway (process exit reclaims); an indirect
// (cast/arith-then-measure) or fan-out measure is left as-is (a Rule-6 safe leak —
// correct under measurement immunity, just not resource-cleaned). Runs AFTER the
// load's RAUW so `Out` carries the original users.
void emitCopyOutIfDirectMeasure(CallInst *Out, StringRef ElemAbi, WidthDispatch &wd,
                                TaintSet &taint) {
  if (Out->getFunction()->getName() == "main" || !Out->hasOneUse())
    return;
  auto *CI = dyn_cast<CallInst>(*Out->user_begin());
  if (!CI)
    return;  // a coherent `ret` user is declined upstream (kMsgQramCohEscape).
  const Function *Callee = CI->getCalledFunction();
  if (!Callee || !Callee->getName().starts_with("cq_measure_"))
    return;  // only a direct measure sink — measurement immunity makes the reversal
             // (and its index frees) sound; everything else leaks safely.
  Instruction *U = CI;
  FunctionCallee Alloc = wd.allocFn(ElemAbi);
  FunctionCallee Copy = wd.copyFn(ElemAbi);
  Type *RailTy = wd.llvmWidthType(ElemAbi);
  if (!Alloc || !Copy || !RailTy)
    return;  // no reversible copy at this width — leave as-is (the caller already
             // proved widthHasReversibleCopy, so this is a defensive guard).
  IRBuilder<> B(U);  // the carrier alloc + copy land right before the escape.
  CallInst *Ret = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "qret");
  CallInst *Cp = B.CreateCall(Copy, {Out, Ret});
  if (DebugLoc DL = U->getDebugLoc()) {
    Ret->setDebugLoc(DL);
    Cp->setDebugLoc(DL);
  }
  taint.Tainted.insert(Ret);
  taint.HandleWidth[Ret] = ElemAbi;
  taint.BirthOrder[Ret] = taint.NextBirth++;
  U->replaceUsesOfWith(Out, Ret);  // the escape now carries the copy, not Out.
}

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
      if (Id == Intrinsic::lifetime_start || Id == Intrinsic::lifetime_end) {
        InitErase.push_back(II);
        continue;
      }
      if (Id == Intrinsic::memset) {
        // §2.6/§6.5 (Rule-13 fix): the model is |0⟩-init, so ONLY a constant
        // ZERO-fill memset is representable; a non-zero / non-constant fill seeds
        // classical contents `cqrt_qram_alloc_<W>` (count-only) drops → a later
        // load of an un-overwritten cell reads 0 in the trace while the true value
        // is the fill (verify-clean WRONG DATA). Decline loudly (over-declining is
        // safe; the silent drop is the unforgivable bug). `memset.inline` shares
        // the same arg-1 fill-byte ABI.
        auto *Fill = dyn_cast<ConstantInt>(II->getArgOperand(1));
        if (!Fill || !Fill->isZero()) {
          diagnose(II, kMsgQramInit);
          return;
        }
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

  // Coherent-return no-cloning fence (bug test_C_libtooling-l6xk + the sxuk
  // direct-return regression; VERIFIED physics, memory
  // 7-5-qram-coherent-return-nocloning). A loaded value that flows COHERENTLY
  // (`coherentlyEscapesToReturn` — through tainted reversible ops, NOT through a
  // measure/tape collapse sink) into a `ret`/`cq_invert` of a NON-`main` function
  // is entangled with this array's LOCAL (`cq_theta`) index. The whole-DAG reversal
  // would uncompute and FREE that index rail — a dirty free (hidden measurement,
  // Rule 6) that DEPHASES the returned carrier (verify-clean silent miscompile). By
  // no-cloning a clean coherent `arr[p]` is impossible once its local address is
  // erased, and leaving the index allocated only DEFERS the collapse — so DECLINE
  // the whole alloca. A MEASURE collapses the value first (immune — the load+store
  // DAG still uncomputes via the direct-measure copy-out below); `main`'s `ret` is
  // the process-exit observation. (Mirrors the §2.8(iii) mid-seq guard structure.)
  if (AI->getFunction()->getName() != "main")
    for (const ShadowAccess &A : Accesses)
      if (!A.IsStore && coherentlyEscapesToReturn(A.MemOp)) {
        diagnose(A.MemOp, kMsgQramCohEscape);
        return;
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
      //
      // Inc 3 (bd 7z9k.3 over-decline hardening #2): re-read the value operand
      // FRESH from the original store, NOT the captured `A.StoreVal`. When an
      // EARLIER-processed load access to this array RAUW'd its original load to the
      // new `cqrt_qram_load` (and queued the original for erase), `A.StoreVal` — the
      // store's value captured at classify time — is the STALE pre-RAUW load; the
      // new store would then reference a soon-erased value (a dangling operand:
      // a verify-fail / crash masked as `kMsgDivergentArm`, the `arr[p]=arr[q]`
      // dead-load-then-store case). Reading the live operand picks up the RAUW so
      // the new store consumes the NEW load — §6.2 ACCEPT.
      Value *Val = cast<StoreInst>(A.MemOp)->getValueOperand();
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
      // sxuk: if this loaded value's sole direct user is a `cq_measure` in a
      // non-main fn, copy it out to a kept carrier so the LOCAL array's stores
      // uncompute (measurement immunity makes the index frees sound). No-op for the
      // dead / taped / main / indirect cases; a COHERENT return was declined above.
      emitCopyOutIfDirectMeasure(Out, ElemAbi, wd, taint);
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
