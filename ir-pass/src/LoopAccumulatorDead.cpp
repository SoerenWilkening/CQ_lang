// LoopAccumulatorDead.cpp — the dead-accumulator postcondition of the seeded
// quantum accumulator (bd test_C_libtooling-01po.19.18; LoopAccumulator.h).

#include "LoopAccumulator.h"

#include "ChainWalk.h"         // isInPlaceGateOn, isNonPermutationMove
#include "InPlaceQQ.h"         // isInPlaceQQGate
#include "MergeStreamGates.h"  // streamGateWrites, controlSlots
#include "TaintPropagation.h"  // TaintSet

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/CFG.h"  // isPotentiallyReachable
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/ValueTracking.h"  // getUnderlyingObjects
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

namespace cq {

// ── THE DEAD-ACCUMULATOR POSTCONDITION ──────────────────────────────────────
//
// The register is never reversed (that needs the post-loop reverse loop, bd
// 8h7d.20), so after its last read it is a DEAD RECORD of every rail its
// sources read. The dead-record ruling (`dead-record-live-across-move-ruling`,
// `owner-ruling-r2j3-7-main-dead-record-2026-10-16`) allows no such record to
// stand at a later non-diagonal gate on one of those rails: it dephases them
// (measured on `int c=0; for(..) { if (c==1) cq_phi(.5); c += a; }
// cq_theta(&a,.7)`: P(bit 0 of a = 1) 0.293 against the program's 0.564, per
// qubit with Ry on every qubit, backend.md §11.3). A record still
// READ on every path after the gate is the program's own entanglement (lyyf).
// Left allocated with no such gate it changes no measured statistic (R5).
//
// Asked on the EMITTED stream (the slot of M-A and Q4), per register `H`
// (delegated ruling `ruling-01po19-18-dead-accumulator-leak-warn-2026-10-16`,
// option (a); R11 round 1 fixes in brackets):
//   * the STEPS are its tagged in-place QQ gates, in loop `L`; they WRITE `H`
//     and are not reads of it ([rA1B-F3]: the last trip's step is no reader);
//   * the LINEAGE is every root rail the steps' sources were computed from
//     (template operands, walked back); a cell read stands for its arrays,
//     every underlying object of its address ([rA1B-F4], an unidentified one
//     fails closed); and it GROWS through any runtime/template call that
//     writes a lineage rail from another one ([rA1B-F5]: `a += r` makes `r`
//     recorded);
//   * a MOVE is a non-diagonal gate on a lineage rail, asked of the owning
//     predicate `isNonPermutationMove` ([rA1B-F6]), with an unknown Ry/H
//     spelling failing closed, the cswap pair, or a defined callee handed one;
//   * an ESCAPE is `ret`, a foreign store, `cq_invert_*`, an unknown callee, any
//     other carrier of a lineage handle, or any pointer escape of a lineage
//     array (a `memcpy`, a stored pointer, an integer cast);
//   * a hazard is a move or escape on some path to the function's end without
//     a read of `H` that runs (i) after a step with no trip between, or (ii) in
//     a LATER trip, before that trip's step ([rA1B-F3]): for a root always, for
//     a cell only if an EARLIER trip's step may have recorded that very cell
//     (`cellMayBeRecorded`, SCEV over `L`; a cell of the gate's own trip that
//     the step reads after it is not yet recorded — F5's shape). That per-cell
//     exemption reasons WITHIN ONE ENTRY of `L` (R11 round 2 rA2-F4);
//   * PER ENTRY ([rA2-F1], the silent bd r2j3.44): when a path leads from the
//     loop's exit back to the mint without a read of `H`, each entry mints a new
//     register under the same SSA name and the previous one is dead at
//     re-entry, so every move of a lineage rail reachable from the mint is a
//     hazard, with no per-cell exemption (`reachesAvoiding`).
// No hazard and `H` dead after its loop: left allocated (R5) and REPORTED, a
// lyyf-class DS_Warning `kMsgDeadAccumulatorLeft`; `opt` exits 0.
// RETIREMENT TRIGGER: bd 8h7d.20's post-loop reverse loop uncomputes the
// register; then the warning and both refusals give way to the discharge.
namespace {

const char kMsgDeadAccumulatorEscaped[] =
    "cq loop lowering: dead loop accumulator records a register that escapes "
    "after its last read";

const char kMsgDeadAccumulatorLeft[] =
    "cq loop lowering: dead loop accumulator left allocated; its sources are "
    "only measured afterwards";

const char kMsgDeadAccumulatorMoved[] =
    "cq loop lowering: dead loop accumulator records a register moved after "
    "its last read";

// The rails a call MOVES non-diagonally.
void movedRails(CallInst *C, SmallVectorImpl<Value *> &Out) {
  Function *Fn = C->getCalledFunction();
  if (!Fn)
    return;
  for (Value *A : C->args())
    if (isNonPermutationMove(C, A))
      Out.push_back(A);
  StringRef N = Fn->getName();
  // A rotation/Hadamard spelling the owning predicate does not classify (e.g.
  // `_controlled_inv`): every handle slot but the known control slots.
  if (Out.empty() && (N.starts_with("cqrt_ry_") || N.starts_with("cqrt_h"))) {
    SmallVector<unsigned, 2> Ctl = controlSlots(C);
    for (unsigned I = 0, E = C->arg_size(); I != E; ++I)
      if (!is_contained(Ctl, I) && C->getArgOperand(I)->getType()->isIntegerTy(32))
        Out.push_back(C->getArgOperand(I));
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

// Same trip after `S`, or after the loop (no entry to `Hdr` in between)?
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

// The arrays a cell read may read: every underlying object of its address;
// `Unknown` when one is not an identified object.
void cellArrays(const Value *V, SmallPtrSetImpl<const Value *> &Out,
                bool &Unknown) {
  auto *LD = dyn_cast<LoadInst>(V);
  if (!LD)
    return;
  SmallVector<const Value *, 4> Objs;
  getUnderlyingObjects(LD->getPointerOperand(), Objs);
  for (const Value *O : Objs) {
    if (!isa<AllocaInst>(O) && !isa<GlobalVariable>(O))
      Unknown = true;
    Out.insert(O);
  }
}

// Some path from `G` to a function exit reads `H` nowhere (never entering
// `Excl`).
bool deadAfter(Instruction *G, const SmallPtrSetImpl<const Instruction *> &Reads,
               const BasicBlock *Excl = nullptr) {
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
    if (B == Excl || !BSeen.insert(B).second)
      continue;
    if (any_of(*B, [&](Instruction &I) { return Reads.count(&I) != 0; }))
      continue;
    if (succ_empty(B))
      return true;
    BW.append(succ_begin(B), succ_end(B));
  }
  return false;
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
    AssumptionCache AC(F);
    TargetLibraryInfoImpl TLII(Triple(M.getTargetTriple()));
    TargetLibraryInfo TLI(TLII);
    ScalarEvolution SE(F, TLI, AC, DT, LI);
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
      // The lineage: roots, the cell reads the steps' sources came from, and
      // their arrays.
      SmallPtrSet<const Value *, 16> Roots, Arrays;
      SmallVector<const Value *, 4> SrcCells;
      bool UnknownArray = false;
      SmallVector<Value *, 16> Work;
      for (CallInst *S : Steps)
        Work.push_back(S->getArgOperand(0));
      SmallPtrSet<Value *, 32> Seen;
      while (!Work.empty()) {
        Value *V = Work.pop_back_val();
        if (!Seen.insert(V).second)
          continue;
        if (isa<LoadInst>(V)) {
          cellArrays(V, Arrays, UnknownArray);
          SrcCells.push_back(V);
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
      auto isCell = [&](const Value *T) {
        if (!isa<LoadInst>(T))
          return false;
        if (UnknownArray && !Arrays.empty())
          return true;
        SmallPtrSet<const Value *, 4> TA;
        bool Unk = false;
        cellArrays(T, TA, Unk);
        if (Unk && !Arrays.empty())
          return true;
        return any_of(TA, [&](const Value *A) { return Arrays.count(A) != 0; });
      };
      auto inLineage = [&](const Value *T) {
        return Roots.count(T) != 0 || isCell(T);
      };
      // [rA1B-F5] grow the lineage through calls that write a lineage rail.
      for (bool Grew = true; Grew;) {
        Grew = false;
        for (BasicBlock &BB : F)
          for (Instruction &I : BB) {
            auto *C = dyn_cast<CallInst>(&I);
            Function *Fn = C ? C->getCalledFunction() : nullptr;
            if (!Fn || (isInPlaceQQGate(C) && C->getArgOperand(1) == H))
              continue;
            SmallVector<Value *, 2> Mv;
            movedRails(C, Mv);
            if (!Mv.empty())
              continue;  // a move: adjudicated below
            SmallVector<unsigned, 2> WS;
            bool Writes = false;
            for (Value *A : C->args())
              if (inLineage(A) && isInPlaceGateOn(C, A))
                Writes = true;
            if (!Writes && streamGateWrites(C, WS))
              for (unsigned Sl : WS)
                Writes |= inLineage(C->getArgOperand(Sl));
            if (!Writes)
              continue;
            for (Value *A : C->args()) {
              if (!A->getType()->isIntegerTy(32) || isa<Constant>(A) || A == H ||
                  inLineage(A))
                continue;
              // [rA2-F3] a cell read joins as its ARRAYS (any read of the cell
              // is the same rail), a register as itself.
              if (isa<LoadInst>(A)) {
                cellArrays(A, Arrays, UnknownArray);
                SrcCells.push_back(A);
                Grew = true;
              } else if (Roots.insert(A).second) {
                Grew = true;
              }
            }
          }
      }
      auto hazardOf = [&](Instruction &I) -> const char * {
        if (auto *C = dyn_cast<CallInst>(&I)) {
          SmallVector<Value *, 2> Moved;
          movedRails(C, Moved);
          if (any_of(Moved, inLineage))
            return kMsgDeadAccumulatorMoved;
          Function *Fn = C->getCalledFunction();
          if (!Fn || Fn->getName().starts_with("cq_invert_"))
            return kMsgDeadAccumulatorEscaped;
          StringRef N = Fn->getName();
          if (N.starts_with("cqrt_") || N.starts_with("cq_template_") ||
              Fn->isIntrinsic())
            return nullptr;
          return kMsgDeadAccumulatorEscaped;
        }
        if (auto *St = dyn_cast<StoreInst>(&I)) {
          SmallVector<const Value *, 4> Objs;
          getUnderlyingObjects(St->getPointerOperand(), Objs);
          if (!Objs.empty() &&
              all_of(Objs, [&](const Value *O) { return Arrays.count(O) != 0; }))
            return nullptr;  // parked back in a lineage array: its loads are lineage
        }
        return kMsgDeadAccumulatorEscaped;  // ret, a foreign store, a cast...
      };
      auto diag = [&](const char *Msg, const DebugLoc &DL) {
        F.getContext().diagnose(DiagnosticInfoUnsupported(F, Msg, DL));
        return true;
      };
      // [rA1B-F4] a lineage array whose address escapes.
      bool DeadAfterLoop = false;
      for (CallInst *S : Steps) {
        const Loop *L = LI.getLoopFor(S->getParent());
        DeadAfterLoop |= deadAfter(S, Reads, L ? L->getHeader() : nullptr);
      }
      if (DeadAfterLoop)
        for (const Value *A : Arrays)
          if (arrayEscapes(A))
            return diag(kMsgDeadAccumulatorEscaped, H->getDebugLoc());
      // [rA2-F1] PER ENTRY: when a path leads from the loop's exit back to the
      // register's mint without reading it, the loop is RE-ENTERED with a new
      // register under the same name and the previous one is a dead record
      // from then on; every move of a lineage rail (root or cell — no per-cell
      // exemption, which reasons within one entry) reachable from the mint is
      // a hazard. Loud until bd 8h7d.20 can reverse each entry's register.
      for (CallInst *S : Steps) {
        const Loop *L = LI.getLoopFor(S->getParent());
        if (!L || !reachesAvoiding(L, H->getParent(), Reads))
          continue;
        for (BasicBlock &BB : F)
          for (Instruction &I : BB) {
            auto *G = dyn_cast<CallInst>(&I);
            if (!G)
              continue;
            SmallVector<Value *, 2> Moved;
            movedRails(G, Moved);
            if (any_of(Moved, inLineage) && isPotentiallyReachable(H, G))
              return diag(kMsgDeadAccumulatorMoved, G->getDebugLoc());
          }
      }
      for (CallInst *S : Steps) {
        const Loop *L = LI.getLoopFor(S->getParent());
        const BasicBlock *Hdr = L ? L->getHeader() : nullptr;
        for (BasicBlock &BB : F)
          for (Instruction &I : BB) {
            if (&I == S || (isa<PHINode>(I) && Hdr == I.getParent()) ||
                none_of(I.operands(),
                        [&](const Use &U) { return inLineage(U.get()); }))
              continue;
            const char *Msg = hazardOf(I);
            if (!Msg)
              continue;
            bool After = runsAfterInTrip(S, &I, Hdr);
            if (!After) {
              // (ii) a later trip, before that trip's step: a move only, on a
              // root, or on a cell an earlier trip may have recorded.
              if (!L || !L->contains(I.getParent()) || Msg != kMsgDeadAccumulatorMoved)
                continue;
              auto *C = cast<CallInst>(&I);
              SmallVector<Value *, 2> Moved;
              movedRails(C, Moved);
              bool Hit = false;
              for (Value *T : Moved)
                if (Roots.count(T) ||
                    (isCell(T) && cellMayBeRecorded(T, SrcCells, L, SE)))
                  Hit = true;
              if (!Hit)
                continue;
            }
            if (deadAfter(&I, Reads))
              return diag(Msg, I.getDebugLoc());
          }
      }
      if (DeadAfterLoop)
        F.getContext().diagnose(DiagnosticInfoUnsupported(
            F, kMsgDeadAccumulatorLeft, H->getDebugLoc(), DS_Warning));
    }
  }
  return false;
}

}  // namespace cq
