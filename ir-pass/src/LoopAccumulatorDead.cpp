// LoopAccumulatorDead.cpp — the dead-accumulator postcondition of the seeded
// quantum accumulator (bd test_C_libtooling-01po.19.18; LoopAccumulator.h).

#include "LoopAccumulator.h"

#include "InPlaceQQ.h"         // isInPlaceQQGate
#include "TaintPropagation.h"  // TaintSet

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ValueTracking.h"  // getUnderlyingObject
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

// ── THE DEAD-ACCUMULATOR POSTCONDITION ──────────────────────────────────────
//
// The register is never reversed (that needs the post-loop reverse loop, bd
// 8h7d.20), so after its last read it is a DEAD RECORD of every rail its
// sources read. The dead-record ruling (`dead-record-live-across-move-ruling`,
// `owner-ruling-r2j3-7-main-dead-record-2026-10-16`) allows no such record to
// stand at a later non-diagonal gate on one of those rails: it dephases them (a
// wrong unitary, measured on `int c=0; for(..) { if (c==1) cq_phi(.5);
// c += a; } cq_theta(&a,.7)`: P(a=1) 0.293 against the program's 0.531). A
// record still READ on every path after the gate is the program's own
// entanglement (lyyf) and stands. Left allocated with no such gate it changes
// no measured statistic (R5: never freed, it is not provably |0⟩).
//
// Asked on the EMITTED stream (the slot of M-A and Q4), per register `H`:
//   * the STEPS are its tagged in-place QQ gates, in loop `L`;
//   * the LINEAGE is every root rail the steps' sources were computed from
//     (template operands, walked back; a cell read stands for its whole array,
//     the Q4 granularity, since a runtime index cannot be told apart);
//   * a GATE is a non-diagonal move of a lineage rail (`cqrt_ry*`, `cqrt_h*`,
//     the cswap pair, or a call into a defined function that is handed one);
//   * the module fails loudly if some gate runs after a step WITHOUT another
//     trip intervening (the same trip, or after the loop: the last trip's step
//     is the register's final write) and some path from the gate reaches the
//     function's end without reading `H` again.
namespace {

const char kMsgDeadAccumulatorMoved[] =
    "cq loop lowering: dead loop accumulator records a register moved after "
    "its last read";

// The target rails a call MOVES non-diagonally (empty for anything else).
void movedRails(CallInst *C, SmallVectorImpl<Value *> &Out) {
  Function *Fn = C->getCalledFunction();
  if (!Fn)
    return;
  StringRef N = Fn->getName();
  if (N.starts_with("cqrt_ry_") || N == "cqrt_h" || N == "cqrt_h_controlled") {
    bool Ctl = N.ends_with("_controlled");
    if (C->arg_size() > (Ctl ? 1u : 0u))
      Out.push_back(C->getArgOperand(Ctl ? 1 : 0));
    return;
  }
  if (N == "cqrt_cswap" && C->arg_size() == 3) {
    Out.push_back(C->getArgOperand(1));
    Out.push_back(C->getArgOperand(2));
    return;
  }
  if (!Fn->isDeclaration())  // a lifted body may move what it is handed
    for (Value *A : C->args())
      Out.push_back(A);
}

// Does `G` run after `S` with no further entry to `Hdr` in between (the same
// trip after `S`, or after the loop)? A plain block walk from `S`'s position
// that never enters `Hdr` (null: an unbounded walk).
bool runsAfterInTrip(const Instruction *S, const Instruction *G,
                     const BasicBlock *Hdr) {
  for (const Instruction *I = S->getNextNode(); I; I = I->getNextNode())
    if (I == G)
      return true;
  SmallVector<const BasicBlock *, 16> W(succ_begin(S->getParent()),
                                        succ_end(S->getParent()));
  SmallPtrSet<const BasicBlock *, 16> Seen;
  while (!W.empty()) {
    const BasicBlock *B = W.pop_back_val();
    if (B == Hdr || !Seen.insert(B).second)
      continue;
    if (B == G->getParent())
      return true;
    W.append(succ_begin(B), succ_end(B));
  }
  return false;
}

const Value *cellArray(const Value *V) {
  auto *LD = dyn_cast<LoadInst>(V);
  return LD ? getUnderlyingObject(LD->getPointerOperand()) : nullptr;
}

}  // namespace

bool declineDeadAccumulatorMoves(Module &M, const TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    SmallVector<Instruction *, 2> Regs;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (taint.AccumulatorRails.count(&I))
          Regs.push_back(&I);
    if (Regs.empty())
      continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    for (Instruction *H : Regs) {
      SmallVector<CallInst *, 2> Steps;
      SmallPtrSet<const Instruction *, 8> Reads;
      for (User *U : H->users())
        if (auto *C = dyn_cast<CallInst>(U); C && isInPlaceQQGate(C) &&
                                             C->getArgOperand(1) == H)
          Steps.push_back(C);
        else if (auto *UI = dyn_cast<Instruction>(U))
          Reads.insert(UI);
      if (Steps.empty())
        continue;
      // The lineage roots and cell arrays.
      SmallPtrSet<const Value *, 16> Roots, Arrays;
      SmallVector<Value *, 16> Work;
      for (CallInst *S : Steps)
        Work.push_back(S->getArgOperand(0));
      SmallPtrSet<Value *, 32> Seen;
      while (!Work.empty()) {
        Value *V = Work.pop_back_val();
        if (!Seen.insert(V).second)
          continue;
        if (const Value *A = cellArray(V)) {
          Arrays.insert(A);
          continue;
        }
        auto *C = dyn_cast<CallInst>(V);
        Function *Fn = C ? C->getCalledFunction() : nullptr;
        if (Fn && Fn->getName().starts_with("cq_template_")) {
          for (Value *A : C->args())
            if (A->getType()->isIntegerTy(32) && !isa<Constant>(A))
              Work.push_back(A);
          continue;
        }
        Roots.insert(V);
      }
      auto inLineage = [&](const Value *T) {
        if (Roots.count(T))
          return true;
        const Value *A = cellArray(T);
        return A && Arrays.count(A);
      };
      // Some path from `G` to a function exit reads `H` nowhere.
      auto deadAfter = [&](Instruction *G) {
        for (Instruction *I = G->getNextNode(); I; I = I->getNextNode())
          if (Reads.count(I))
            return false;
        SmallVector<BasicBlock *, 16> BW(succ_begin(G->getParent()),
                                         succ_end(G->getParent()));
        if (BW.empty())
          return true;
        SmallPtrSet<BasicBlock *, 16> BSeen;
        while (!BW.empty()) {
          BasicBlock *B = BW.pop_back_val();
          if (!BSeen.insert(B).second)
            continue;
          bool Reads_ = false;
          for (Instruction &I : *B)
            if (Reads.count(&I)) {
              Reads_ = true;
              break;
            }
          if (Reads_)
            continue;
          if (succ_empty(B))
            return true;
          BW.append(succ_begin(B), succ_end(B));
        }
        return false;
      };
      for (CallInst *S : Steps) {
        const Loop *L = LI.getLoopFor(S->getParent());
        const BasicBlock *Hdr = L ? L->getHeader() : nullptr;
        for (BasicBlock &BB : F)
          for (Instruction &I : BB) {
            auto *G = dyn_cast<CallInst>(&I);
            if (!G || G == S)
              continue;
            SmallVector<Value *, 2> Moved;
            movedRails(G, Moved);
            if (none_of(Moved, inLineage))
              continue;
            if (!runsAfterInTrip(S, G, Hdr))
              continue;
            if (!deadAfter(G))
              continue;
            F.getContext().diagnose(DiagnosticInfoUnsupported(
                F, kMsgDeadAccumulatorMoved, G->getDebugLoc()));
            return true;
          }
      }
    }
  }
  return false;
}

}  // namespace cq
