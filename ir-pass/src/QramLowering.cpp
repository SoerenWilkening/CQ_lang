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

// Is `LI` control-dependent on a tainted-condition branch? CONSERVATIVE (Prime
// Directive): true if ANY block strictly dominating `LI`'s block ends in a
// tainted-condition `br`/`switch`. 7.5 lowers STRAIGHT-LINE memory only (§2.11);
// a read inside a tainted-control region (e.g. the const `@switch.table` gep/load
// of a clang-folded jump table, control_swap_reject_switch_jumptable.ll) is NOT
// ours and must keep declining at the escape guard. Over-declining a
// straight-line read that merely sits after an unrelated tainted diamond is safe.
bool loadUnderTaintedControl(const LoadInst *LI, const TaintSet &taint,
                             DominatorTree &DT) {
  DomTreeNode *Node = DT.getNode(const_cast<BasicBlock *>(LI->getParent()));
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
  if (loadUnderTaintedControl(LI, taint, DT))
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

}  // namespace cq
