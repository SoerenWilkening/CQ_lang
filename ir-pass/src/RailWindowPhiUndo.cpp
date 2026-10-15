// RailWindowPhiUndo.cpp — bd `test_C_libtooling-01po.19`, design Q6 (a) (owner
// ruling owner-ruling-01po19-rolled-design-2026-10-15): -O1 header φs that
// carry a CELL value across a back edge are mapped back to the cell by SCEV
// address identity, loud when the address cannot be rebuilt. S3 deferred it
// (railwindow_ghz_cnot_walk_pending.ll's header); S5 needs it, because the
// GHZ walk `q[i+1] ^= q[i]` and cnot_then_ry.c carry `q[i]` in
//     %c = phi i8 [ zext(v0), preheader ], [ zext(v'), latch ]
// where `v0` is the value last stored to cell A(0) before the loop and `v'`
// the value last stored, in the trip, to the cell the NEXT trip reads. In the
// handle domain that φ is a loop-carried rail the in-loop machinery refuses
// ("loop-carried tainted value crosses iterations"); as a cell read it is a
// borrowed root of the window (S4) and its update an in-place gate (S5).
//
// THE IDENTITY. For a header φ `P` of loop `L` every incoming must be the
// cell's CONTENT at the end of its block: a value stored into the handle array
// `W` (or a load of `W`), at an address `A_b`, by an access that dominates the
// end of block `b` with no store into `W` after it on any path to that end
// unless the two cells are provably distinct (`railWindowDistinct`). Then there
// is an affine `C` over `L` with `C(0) = A_pre` and `C(k+1) = A_latch(k)`:
// `A_latch` is `{s,+,d}<L>` (or invariant `s`, `d = 0`), and `A_pre == s - d`.
// Memory at the header of trip `k` is then exactly `P`'s value, so `P` is
// replaced by a load of cell `C` placed at the top of the header (expanded by
// `SCEVExpander`, its start invariant), zero-extended back to `P`'s type. The
// rewrite is the identity on values in the classical semantics of the program,
// and on rails it names the rail the cell holds — the materialized handle.
//
// A φ ALL of whose incomings are cell values but which fails the identity is
// loud (`kMsgWindowPhiUndo`): the cell it carries cannot be named. A φ with
// some non-cell incoming is not a cell carrier and is left alone.

#include "RailWindow.h"

#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/Local.h"  // RecursivelyDeleteTriviallyDeadInstructions
#include "llvm/Transforms/Utils/ScalarEvolutionExpander.h"

using namespace llvm;

namespace cq {

namespace {

// Mirrored CHARACTER-FOR-CHARACTER by railwindow_s5_reject_phi_undo.ll.
constexpr char kMsgWindowPhiUndo[] =
    "cq rail window: a loop-carried cell value cannot be mapped back to its "
    "cell";

bool inW(const Value *Ptr, const AllocaInst *W) {
  return getUnderlyingObject(Ptr) == W;
}

// The cell access whose value `V` is (through one `zext` of an `i1` rail): a
// store into `W` of that value, or a load of `W`. Null if none.
Instruction *cellAccessOf(Value *V, const AllocaInst *W, Value *&Rail) {
  Rail = V;
  if (auto *Z = dyn_cast<ZExtInst>(V))
    Rail = Z->getOperand(0);
  if (auto *L = dyn_cast<LoadInst>(Rail); L && inW(L->getPointerOperand(), W))
    return L;
  Instruction *Found = nullptr;
  for (User *U : Rail->users())
    if (auto *S = dyn_cast<StoreInst>(U);
        S && S->getValueOperand() == Rail && inW(S->getPointerOperand(), W)) {
      if (Found)
        return nullptr;  // two stores of one value: no single cell.
      Found = S;
    }
  return Found;
}

// Is the content of `A`'s cell at the end of `B` still the value `A` read or
// wrote: does `A` dominate `B`'s end, with no store into `W` that may hit the
// same cell on any path from `A` to that end?
bool contentAtEnd(Instruction *A, BasicBlock *B, const AllocaInst *W,
                  DominatorTree &DT, ScalarEvolution &SE) {
  if (!DT.dominates(A, B->getTerminator()))
    return false;
  const SCEV *Cell = SE.getSCEV(getLoadStorePointerOperand(A));
  auto Hits = [&](Instruction &I) {
    auto *S = dyn_cast<StoreInst>(&I);
    return S && S != A && inW(S->getPointerOperand(), W) &&
           !railWindowDistinct(SE, Cell, SE.getSCEV(S->getPointerOperand()));
  };
  // Every block on a path from the LAST execution of A to the end of B,
  // walked backward from B. A dominates B, so every backward path meets A's
  // block first; there only the part after A counts (a path wrapping around
  // re-executes A, which is then the last one).
  SmallVector<BasicBlock *, 16> Work{B};
  SmallPtrSet<BasicBlock *, 32> Seen;
  while (!Work.empty()) {
    BasicBlock *X = Work.pop_back_val();
    if (!Seen.insert(X).second)
      continue;
    if (X == A->getParent()) {
      for (auto I = std::next(A->getIterator()); I != X->end(); ++I)
        if (Hits(*I))
          return false;
      continue;
    }
    for (Instruction &I : *X)
      if (Hits(I))
        return false;
    for (BasicBlock *P : predecessors(X))
      Work.push_back(P);
  }
  return true;
}

}  // namespace

bool undoRailWindowHeaderPhis(Function &F, AllocaInst *W) {
  TargetLibraryInfoImpl TLII(Triple(F.getParent()->getTargetTriple()));
  TargetLibraryInfo TLI(TLII);
  DominatorTree DT(F);
  LoopInfo LI(DT);
  AssumptionCache AC(F);
  ScalarEvolution SE(F, TLI, AC, DT, LI);
  Type *RT = W->getAllocatedType();
  struct Undo {
    PHINode *P;
    const SCEV *C;
  };
  SmallVector<Undo, 4> Undos;
  for (Loop *L : LI.getLoopsInPreorder()) {
    BasicBlock *H = L->getHeader(), *Pre = L->getLoopPreheader(),
               *Latch = L->getLoopLatch();
    for (PHINode &P : H->phis()) {
      if (!P.getType()->isIntegerTy())
        continue;
      bool AllCells = true;
      SmallVector<std::pair<BasicBlock *, Instruction *>, 2> Acc;
      for (unsigned i = 0, e = P.getNumIncomingValues(); i != e; ++i) {
        Value *Rail;
        Instruction *A = cellAccessOf(P.getIncomingValue(i), W, Rail);
        if (!A || Rail->getType() != RT) {
          AllCells = false;
          break;
        }
        Acc.push_back({P.getIncomingBlock(i), A});
      }
      if (!AllCells || Acc.empty())
        continue;  // not a cell carrier: the loop machinery owns it.
      auto Loud = [&] {
        F.getContext().diagnose(
            DiagnosticInfoUnsupported(F, kMsgWindowPhiUndo, P.getDebugLoc()));
        return false;
      };
      if (!Pre || !Latch || P.getNumIncomingValues() != 2)
        return Loud();
      Instruction *APre = nullptr, *ALatch = nullptr;
      for (auto &[B, A] : Acc) {
        if (!contentAtEnd(A, B, W, DT, SE))
          return Loud();
        (B == Pre ? APre : ALatch) = A;
      }
      if (!APre || !ALatch)
        return Loud();
      const SCEV *SPre = SE.getSCEV(getLoadStorePointerOperand(APre));
      const SCEV *SLat = SE.getSCEV(getLoadStorePointerOperand(ALatch));
      const SCEV *Start = nullptr, *Step = nullptr;
      if (auto *AR = dyn_cast<SCEVAddRecExpr>(SLat);
          AR && AR->getLoop() == L && AR->isAffine()) {
        Start = AR->getStart();
        Step = AR->getStepRecurrence(SE);
      } else if (SE.isLoopInvariant(SLat, L)) {
        Start = SLat;
        Step = SE.getZero(SE.getEffectiveSCEVType(SLat->getType()));
      }
      if (!Start || !SE.isLoopInvariant(Step, L) ||
          SE.getMinusSCEV(Start, Step) != SPre)
        return Loud();
      Undos.push_back({&P, SE.getAddRecExpr(SPre, Step, L, SCEV::FlagAnyWrap)});
    }
  }
  if (Undos.empty())
    return true;
  // The address is rebuilt in the handle array's own vocabulary (`gep <rail>,
  // W, idx`, what the retype accepts): the cell index is the byte offset from
  // `W` divided exactly by the cell size.
  const DataLayout &DL = F.getParent()->getDataLayout();
  SCEVExpander Exp(SE, DL, "cq.cell");
  const SCEV *Base = SE.getSCEV(W);
  const SCEV *Size = SE.getConstant(SE.getEffectiveSCEVType(Base->getType()),
                                    DL.getTypeAllocSize(RT));
  for (const Undo &U : Undos) {
    BasicBlock *H = U.P->getParent();
    const SCEV *Idx = SE.getUDivExactExpr(SE.getMinusSCEV(U.C, Base), Size);
    if (isa<SCEVCouldNotCompute>(Idx) || !Idx->getType()->isIntegerTy()) {
      F.getContext().diagnose(
          DiagnosticInfoUnsupported(F, kMsgWindowPhiUndo, U.P->getDebugLoc()));
      return false;
    }
    Value *IdxV = Exp.expandCodeFor(Idx, Idx->getType(), H->getFirstNonPHIIt());
    IRBuilder<> B(H, H->getFirstNonPHIIt());
    Value *Ptr = B.CreateGEP(RT, W, IdxV, "cq.cell.addr");
    Value *V = B.CreateLoad(RT, Ptr, U.P->getName() + ".cell");
    if (V->getType() != U.P->getType())
      V = B.CreateZExt(V, U.P->getType());
    U.P->replaceAllUsesWith(V);
  }
  // The incomings' storage casts (`zext` of the stored rail) die with the φ;
  // left behind they would lower to dead copy templates the spine never
  // discharges (a dirty, entangled rail: the r2j3.7 class).
  SmallVector<WeakTrackingVH, 4> Dead;
  for (const Undo &U : Undos) {
    for (Value *In : U.P->incoming_values())
      Dead.push_back(In);
    U.P->eraseFromParent();
  }
  for (WeakTrackingVH &V : Dead)
    if (auto *I = dyn_cast_or_null<Instruction>(V); I && isa<CastInst>(I))
      RecursivelyDeleteTriviallyDeadInstructions(I);
  return true;
}

}  // namespace cq
