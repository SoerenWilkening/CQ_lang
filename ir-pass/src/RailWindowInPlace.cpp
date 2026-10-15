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
#include "RailWindowAlias.h"

#include "BoolStorageNarrow.h"  // boolCompareXor — the ONE `_Bool` xor spelling
#include "ChainWalk.h"         // isNonPermutationMove
#include "InPlaceQQ.h"         // railIsUserData
#include "WireWalk.h"          // provablyBefore
#include "TaintPropagation.h"

#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"
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

// Does `V` derive from `U` (backward through every non-load operand: casts,
// φs, selects, the quantum ops that continue the update chain)? Bounded.
bool derivesFrom(const Value *V, const Instruction *U) {
  SmallVector<const Value *, 16> Work{V};
  SmallPtrSet<const Value *, 32> Seen;
  while (!Work.empty()) {
    const Value *X = Work.pop_back_val();
    if (X == U)
      return true;
    const auto *I = dyn_cast<Instruction>(X);
    if (!I || isa<LoadInst>(I) || !Seen.insert(X).second || Seen.size() > 256)
      continue;
    for (const Value *Op : I->operands())
      Work.push_back(Op);
  }
  return false;
}

}  // namespace

bool railWindowWritesBack(const Instruction *U, const Value *CellPtr) {
  const auto *W =
      CellPtr ? dyn_cast<AllocaInst>(getUnderlyingObject(CellPtr)) : nullptr;
  if (!W || !U)
    return false;
  // (1) ONE CELL: every store of the result (through casts and φs) is into
  // THIS cell, and the result escapes nowhere else (a second cell, other
  // memory, a return): an in-place gate makes the result the cell's own rail,
  // so a copy of it elsewhere would be two names for one rail (R7).
  SmallVector<const Value *, 8> Work{U};
  SmallPtrSet<const Value *, 16> Seen;
  while (!Work.empty()) {
    const Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    for (const User *Us : V->users()) {
      if (const auto *S = dyn_cast<StoreInst>(Us)) {
        if (S->getValueOperand() == V &&
            !sameCellAddress(S->getPointerOperand(), CellPtr))
          return false;
      } else if (isa<ReturnInst>(Us)) {
        return false;
      } else if (isa<CastInst>(Us) || isa<PHINode>(Us)) {
        Work.push_back(Us);
      }
    }
  }
  // (2) A MUST WRITE-BACK: every path from `U` stores a value derived from it
  // into THIS cell before it reaches a read of a cell that may be this one,
  // another store into this cell, `U` again (a cycle) or a return. On the
  // path that skips the write-back, C keeps the cell's old value, which the
  // in-place gate has already overwritten.
  const Function &F = *U->getFunction();
  DominatorTree DT(const_cast<Function &>(F));
  LoopInfo LI(DT);
  AssumptionCache AC(const_cast<Function &>(F));
  TargetLibraryInfoImpl TLII(Triple(F.getParent()->getTargetTriple()));
  TargetLibraryInfo TLI(TLII);
  ScalarEvolution SE(const_cast<Function &>(F), TLI, AC, DT, LI);
  const SCEV *CellS = SE.getSCEV(const_cast<Value *>(CellPtr));
  auto inW = [&](const Value *P) { return getUnderlyingObject(P) == W; };
  // Returns 1 = write-back (path done), -1 = violation, 0 = continue.
  auto step = [&](const Instruction &I) -> int {
    if (&I == U || isa<ReturnInst>(I))
      return -1;
    if (const auto *S = dyn_cast<StoreInst>(&I); S && inW(S->getPointerOperand())) {
      if (!sameCellAddress(S->getPointerOperand(), CellPtr))
        return railWindowDistinct(SE, CellS,
                                  SE.getSCEV(const_cast<Value *>(
                                      S->getPointerOperand())), &I, &DT)
                   ? 0
                   : -1;
      return derivesFrom(S->getValueOperand(), U) ? 1 : -1;
    }
    if (const auto *Ld = dyn_cast<LoadInst>(&I); Ld && inW(Ld->getPointerOperand()))
      return railWindowDistinct(SE, CellS,
                                SE.getSCEV(const_cast<Value *>(
                                    Ld->getPointerOperand())), &I, &DT)
                 ? 0
                 : -1;
    return 0;
  };
  for (auto It = std::next(U->getIterator()); It != U->getParent()->end(); ++It)
    if (int R = step(*It)) {
      if (R < 0)
        return false;
      return true;
    }
  SmallVector<const BasicBlock *, 16> Blocks(succ_begin(U->getParent()),
                                             succ_end(U->getParent()));
  SmallPtrSet<const BasicBlock *, 32> Visited;
  if (Blocks.empty())
    return false;  // no successor and no write-back: the path ends unwritten.
  while (!Blocks.empty()) {
    const BasicBlock *B = Blocks.pop_back_val();
    if (!Visited.insert(B).second)
      continue;
    bool Done = false;
    for (const Instruction &I : *B)
      if (int R = step(I)) {
        if (R < 0)
          return false;
        Done = true;
        break;
      }
    if (Done)
      continue;
    if (succ_empty(B))
      return false;  // `unreachable` or a non-returning end, unwritten.
    Blocks.append(succ_begin(B), succ_end(B));
  }
  return true;
}

bool railWindowDerived(const Value *V) {
  SmallVector<const Value *, 8> Work{V};
  SmallPtrSet<const Value *, 16> Seen;
  while (!Work.empty()) {
    const Value *X = Work.pop_back_val();
    if (isRailWindowCellRead(X))
      return true;
    const auto *I = dyn_cast<Instruction>(X);
    if (!I || isa<LoadInst>(I) || isa<CallBase>(I) || !Seen.insert(X).second ||
        Seen.size() > 64)
      continue;
    for (const Value *Op : I->operands())
      Work.push_back(Op);
  }
  return false;
}

// InPlaceQQ's predicate, kept here for the file budget (moved from
// InPlaceQQ.cpp). bd 01po.19 S6: a quantum-array CELL READ is user DATA (the
// array owns its rail, the spine never discharges it, whatever this spelling
// carries) — asked by G7's arm (c′), the postcondition and `dependsOnTarget`.
// Whether a cell read may be an in-place TARGET is a different question, asked
// by `qqTargetIsUserData` (E2): it also needs `railWindowWritesBack`.
bool railIsUserData(const Value *P) {
  if (isRailWindowCellRead(P))
    return true;
  for (const User *U : P->users())
    if (const auto *G = dyn_cast<CallInst>(U); G && isNonPermutationMove(G, P))
      return true;
  return false;
}

bool qqTargetIsUserData(const Value *Result, const Value *Op) {
  if (!isRailWindowCellRead(Op))
    return railIsUserData(Op);
  const auto *U = dyn_cast<Instruction>(Result);
  return U && railWindowWritesBack(U, cast<LoadInst>(Op)->getPointerOperand());
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

bool railWindowBeforeInTrip(const Instruction *X, const Instruction *Site,
                            const Value *P, const DominatorTree &DT) {
  if (provablyBefore(X, Site, DT))
    return true;
  const auto *L = dyn_cast_or_null<LoadInst>(P);
  if (!L || !railWindowSameTripTarget(Site, P, DT) || !DT.dominates(X, Site))
    return false;
  SmallPtrSet<const Instruction *, 1> Reload{L};
  return !railWindowReachesAvoiding(Site, X, Reload);
}

void railWindowTripDistinctCells(const Value *P, ArrayRef<Value *> Family,
                                 const Instruction *First,
                                 const Instruction *At,
                                 SmallPtrSetImpl<const Value *> &Out) {
  const auto *LP = dyn_cast_or_null<LoadInst>(P);
  if (!LP || !isRailWindowCellRead(LP))
    return;
  Function &F = const_cast<Function &>(*LP->getFunction());
  DominatorTree DT(F);
  LoopInfo LI(DT);
  AssumptionCache AC(F);
  TargetLibraryInfoImpl TLII(Triple(F.getParent()->getTargetTriple()));
  TargetLibraryInfo TLI(TLII);
  ScalarEvolution SE(F, TLI, AC, DT, LI);
  const Loop *L = LI.getLoopFor(LP->getParent());
  // One activation only: the window's opener and discharge sit in `P`'s own
  // loop body, the opener dominating the discharge (no back edge between).
  if (!First || !At || LI.getLoopFor(First->getParent()) != L ||
      LI.getLoopFor(At->getParent()) != L || !DT.dominates(First, At))
    return;
  const SCEV *SP = SE.getSCEV(const_cast<Value *>(LP->getPointerOperand()));
  for (Value *A : Family) {
    const auto *LA = dyn_cast<LoadInst>(A);
    if (!LA || LA == LP || LI.getLoopFor(LA->getParent()) != L ||
        getUnderlyingObject(LA->getPointerOperand()) !=
            getUnderlyingObject(LP->getPointerOperand()))
      continue;
    const SCEV *SA = SE.getSCEV(const_cast<Value *>(LA->getPointerOperand()));
    if (railWindowDistinct(SE, SP, SA))
      Out.insert(A);
  }
}

}  // namespace cq
