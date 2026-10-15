// RailWindowInPlace.cpp — bd `test_C_libtooling-01po.19` S5: in-place cell
// updates (design §4, owner rulings owner-ruling-01po19-rolled-design-2026-10-15
// and owner-ruling-dm7f51-inplace-qq-2026-10-14). Contract in RailWindow.h.
//
// Inside a window `q[i] ^= q[j]` is SSA `x1 = x0 ^ y` with `x0` cell i's entry
// value, whose only later fate is being overwritten by the window store: `x0`
// is dead, so dm7f.51's in-place quantum-source round (InPlaceQQ.h) lowers it
// as `cqrt_cnot(y, rail(x0))` and the store becomes a self-store. This file
// holds the two window-side halves of that interface:
//   (a) the update's operands in either spelling (`xor`/`add`/`sub`, or the
//       `_Bool` compare `icmp ne (zext x), (zext y)` — `boolCompareXor`);
//   (b) the BORROWED-ROOT TARGET: a cell read is user data (InPlaceQQ's E2)
//       and, when it is loaded in the same trip as the update, an in-loop
//       update rewrites exactly the rail the source names (InPlaceQQ's G5).
// Ground truth (R12): BennettVM.jl 23d28e6 `MemoryAssignment`
// (src/ir/memory_instructions.jl:111, forward :146, inverse :181) is Mogensen's
// RSSA `M[a] ⊕= lhs op rhs`, the in-place cell update; its aliasing section
// (:84) forbids operand/address aliasing by discipline, which CQ proves
// instead (S3's distinct classes; `x ^= x` is never an update here, S7).

#include "RailWindow.h"

#include "BoolStorageNarrow.h"  // boolCompareXor — the ONE `_Bool` xor spelling
#include "InPlaceQQ.h"         // railIsUserData
#include "TaintPropagation.h"

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Function.h"

using namespace llvm;

namespace cq {

// Moved from RailWindowPromote.cpp (S5, file budget); unchanged.
void railWindowQuantum(Function &F, const RailWindowAccesses &Acc,
                       const TaintSet &taint, SmallPtrSetImpl<Value *> &QD) {
  SmallVector<Value *, 64> Work(Acc.Loads.begin(), Acc.Loads.end());
  for (Instruction &I : instructions(F))
    if (taint.Tainted.count(&I))
      Work.push_back(&I);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (!QD.insert(V).second)
      continue;
    for (User *U : V->users())
      if (auto *I = dyn_cast<Instruction>(U))
        if (!I->getType()->isVoidTy()) {
          // `cq_measure` is the taint SINK (R3): its result is classical.
          // (S4 found this over-flag: `cq_measure(q[0]) ? 2 : 0` read as a
          // quantum select condition.)
          if (auto *CI = dyn_cast<CallInst>(I))
            if (Function *Fn = CI->getCalledFunction();
                Fn && Fn->getName().starts_with("cq_measure_"))
              continue;
          Work.push_back(I);
        }
  }
}

bool railWindowInPlaceUpdate(Value *V, Value *&X, Value *&Y, bool &Sub) {
  Sub = false;
  if (auto *B = dyn_cast<BinaryOperator>(V)) {
    const auto Op = B->getOpcode();
    if (Op != Instruction::Xor && Op != Instruction::Add &&
        Op != Instruction::Sub)
      return false;
    X = B->getOperand(0);
    Y = B->getOperand(1);
    Sub = Op == Instruction::Sub;
    return true;
  }
  // `q = (q == y)` is the update `q ^= y` followed by a NOT: not one gate.
  bool Neg;
  return boolCompareXor(V, X, Y, Neg) && !Neg;
}

namespace {

// Do two cell addresses of one handle array name the same cell by
// construction (one pointer, or two geps with identical operands)?
bool sameCellAddress(const Value *A, const Value *B) {
  if (A == B)
    return true;
  const auto *GA = dyn_cast<GetElementPtrInst>(A);
  const auto *GB = dyn_cast<GetElementPtrInst>(B);
  if (!GA || !GB || GA->getSourceElementType() != GB->getSourceElementType() ||
      GA->getNumOperands() != GB->getNumOperands())
    return false;
  for (unsigned i = 0, e = GA->getNumOperands(); i != e; ++i)
    if (GA->getOperand(i) != GB->getOperand(i))
      return false;
  return true;
}

}  // namespace

bool railWindowStoredBack(const Value *Result, const Value *Cell) {
  const auto *L = dyn_cast_or_null<LoadInst>(Cell);
  if (!L || !isRailWindowCellRead(L))
    return false;
  SmallVector<const Value *, 8> Work{Result};
  SmallPtrSet<const Value *, 16> Seen;
  while (!Work.empty()) {
    const Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    for (const User *U : V->users()) {
      if (const auto *S = dyn_cast<StoreInst>(U)) {
        if (S->getValueOperand() == V &&
            sameCellAddress(S->getPointerOperand(), L->getPointerOperand()))
          return true;
      } else if (isa<CastInst>(U) || isa<PHINode>(U)) {
        Work.push_back(U);
      }
    }
  }
  return false;
}

bool qqTargetIsUserData(const Value *Result, const Value *Op) {
  return isRailWindowCellRead(Op) ? railWindowStoredBack(Result, Op)
                                  : railIsUserData(Op);
}

bool railWindowSameTripTarget(const Instruction *Site, const Value *P,
                              const DominatorTree &DT) {
  const auto *L = dyn_cast_or_null<LoadInst>(P);
  if (!L || !isRailWindowCellRead(L) || !DT.dominates(L, Site))
    return false;
  // Every re-execution of `Site` re-executes the load first: no path from
  // `Site` back to itself avoids it (the exact block walk, irreducible cycles
  // included).
  SmallPtrSet<const Instruction *, 1> Reload{L};
  return !railWindowReachesAvoiding(Site, Site, Reload);
}

}  // namespace cq
