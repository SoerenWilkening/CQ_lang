// CtlzIdiomPrepass.cpp — bd ww4c Increment 1: the shift-count loop ->
// `llvm.ctlz` idiom recognizer. See CtlzIdiomPrepass.h for the Z1-Z9 fence
// contract, the closed form and its provenance, and the three non-optional
// emission rules; see docs/prd/phase-07-expressiveness/PRD-ww4c-ctlz-idiom.md
// for the design of record.
//
// Placement (CQLoweringPass.cpp, both entry points — twin-pipeline parity is
// MANDATORY, WI-1.12): immediately after the `unrollConstTripLoops` fixpoint and
// before `detectSpecializations`. One item at a time, all four reasons load-
// bearing:
//   * AFTER the promoteFp80Union + PredMux fixpoints — Z8 must read taint that
//     has SETTLED through those two fixpoints, because the taint reaching one of
//     these recurrences arrives through the ld80 union promotion;
//     *** BUT NOT "the SAME settled taint the rest of the pipeline reads", which
//     is how this line read until bd ww4c.4 measured it FALSE. Z8 reads a
//     STRICTLY SMALLER set than `lowerLoops`/`tryCaseA` do: ARGUMENT taint is
//     minted later, by `detectSpecializations`, which runs AFTER this fixpoint
//     and never re-triggers it. The measured consequence is a real accept-set
//     boundary: an idiom loop hosted in a CALLEE, whose taint arrives only
//     through the call argument, is NEVER CLAIMED — it declines loudly instead
//     with `cq specialization: callee contains tainted control flow under
//     quantum lift` on the clone. Safe (over-decline), coverage-limiting, and
//     tracked; do not quote this placement as giving Z8 pipeline-wide taint. ***
//   * BEFORE `detectSpecializations` — the spec-scan and any later clone must
//     see the rewritten body;
//   * BEFORE `lowerLoops` — a claimed loop is gone before Q1 would decline it;
//   * a FIXPOINT with a full re-propagate, and a NESTED PredMux fixpoint,
//     because the claim mints tainted SSA and because the enclosing region was
//     CYCLIC (PredMux never claims a region containing a loop) and becomes
//     claimable the moment the loop is gone. That sequencing is what makes the
//     guard disappear AFTER the rewrite — which is exactly why neither the
//     closed form nor the bd k02s argument is allowed to depend on it.
//
// WHY THIS IS NOT bd k02s. k02s says a "shift-until-normalized" recognizer would
// recover a GUARD-CONDITIONAL bound, and that this is the R1 class
// QramLowering.cpp:703-708 exists to prevent: the speculated read runs on every
// basis state, so the fact must hold UNCONDITIONALLY, not merely on the
// originally-guarded path. This design relies on no guard at any point:
//   * definedness is unconditional — `shl`, `ctlz(_, false)`, `and` and `sub`
//     with no poison flags are TOTAL on the entire type domain, with a FIXED
//     gate count, which discharges the reachability obligation structurally
//     rather than by proving reachability;
//   * value equality is unconditional — 0 mismatches over 2^32, not over the
//     reachable subset. That is why PRD §3.2's discovery that two of the three
//     target loops are UNGUARDED drove the choice of closed form.
// The distinction worth carrying: a VALUE only correct on the reachable domain
// is at least arguable, because the flattener preserves the path predicate that
// selects it — but a TRIP BOUND only valid on the reachable domain never is,
// because gate count is not a per-basis-state quantity and no select can discard
// a circuit that was never finite. This pass substitutes a value with a fixed
// gate count; SCOPING-L3 §6 item 1 and bd m57l substitute a STRUCTURE whose size
// depends on a bound. k02s binds those and not this — and this file does not
// lean on that argument anyway, because it takes the stronger whole-domain
// position.

#include "CtlzIdiomPrepass.h"

#include "TaintPropagation.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

#include <cstdlib>

using namespace llvm;

namespace cq {

namespace {

// One recognized loop, captured by SSA-value identity BEFORE any mutation
// (Rule 9). Every field is filled by `fencePasses` and consumed by
// `emitClosedForm`; nothing is cached across an erasure.
struct CtlzIdiom {
  Loop *L = nullptr;
  BasicBlock *Header = nullptr;  // == the sole latch == the sole exiting block
  BasicBlock *Preheader = nullptr;
  BasicBlock *Exit = nullptr;
  PHINode *ShiftPhi = nullptr;
  PHINode *CountPhi = nullptr;
  BinaryOperator *Shl = nullptr;  // the shift recurrence's latch value
  BinaryOperator *Dec = nullptr;  // the counter's latch value — the escapee
  ICmpInst *Cmp = nullptr;
  BranchInst *Latch = nullptr;
  Value *EntryVal = nullptr;   // ShiftPhi's preheader incoming — OPAQUE (§5.4)
  ConstantInt *C0 = nullptr;   // CountPhi's preheader incoming
  IntegerType *Ty = nullptr;   // the recurrence type; the mask comes from HERE
};

// Z9 — the widths `tools/intrinsic_table.yaml:136` actually ships `ctlz` at.
// Deliberately an explicit set rather than "is a power of two": the mask
// reasoning is width-generic, the TEMPLATE is not.
bool isShippedCtlzWidth(unsigned Bits) {
  return Bits == 8 || Bits == 16 || Bits == 32 || Bits == 64;
}

// Every use of `I` is inside `L`.
//
// The `!UI` branch is DEFENSIVE ONLY and is UNREACHABLE — corrected bd ww4c.4,
// which found this comment previously claimed it "answers PRD §7 item 3"
// conservatively. It answers nothing, because none of the classes it names can
// appear in an Instruction's `users()` list: a Constant may only reference other
// Constants in LLVM, so a ConstantExpr cannot use an Instruction; metadata uses
// go through `ValueAsMetadata`, not the use-list; and a `BlockAddress` names a
// BasicBlock, never an Instruction. LLVM-19 debug records are likewise NOT users
// and NOT instructions (see Z6). The branch is kept because it costs one
// predicate and an unreachable decline is free — but it must not be cited as the
// mitigation for anything. PRD §7 item 3's actual mitigation is Z6's exact
// six-instruction identity check plus Z7's escape requirement.
bool noEscapingUse(Instruction *I, Loop *L) {
  for (User *U : I->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI || !L->contains(UI))
      return false;
  }
  return true;
}

// The Z1-Z9 fence. PURE ANALYSIS by SSA-value identity on the still-unmutated
// IR; a false return leaves the loop byte-untouched for its existing owner.
bool fencePasses(Loop *L, const TaintSet &taint, DominatorTree &DT,
                 CtlzIdiom &R) {
  // ── Z1 — the rotated do-while shape ────────────────────────────────────
  // TOP-LEVEL, not merely innermost. `getParentLoop()` is the stricter half and
  // it is deliberate: every target loop measured in PRD §3.1 is top-level, so
  // admitting a NESTED one buys no coverage and opens an unreviewed class. After
  // a claim the substituted chain would sit inside the outer loop with the
  // escaping counter feeding an outer accumulator — turning a shape that
  // declines loudly today (Q1, on the inner tainted exit) into an outer loop
  // carrying tainted values across iterations, adjudicated by owners nobody
  // looked at for this. See lowering_ctlz_idiom_reject_nested_in_outer_loop.ll.
  if (L->getParentLoop() || !L->isInnermost() || L->getNumBlocks() != 1)
    return false;
  BasicBlock *H = L->getHeader();
  if (L->getLoopLatch() != H || L->getExitingBlock() != H)
    return false;
  // The unique OUT-OF-LOOP PREDECESSOR — deliberately `getLoopPredecessor` and
  // NOT `getLoopPreheader`. Measured (bd ww4c Inc 1, red-green): the guarded
  // target loop `s_ilogb.c:40` has NO DEDICATED PREHEADER at -O1, because its
  // guard block ends in the two-way `br i1 %g, label %loop, label %merge` whose
  // other edge runs straight to the return merge (PRD §3.1 loop A). Requiring
  // loop-simplify form would have declined one of the three cells this pass
  // exists to reach — Rule 17's exact failure mode — and running `simplifyLoop`
  // to manufacture a preheader would MUTATE loops the fence goes on to reject,
  // breaking the accept-only contract that every off-fence loop is left
  // byte-untouched.
  //
  // Nothing is lost by the weaker requirement, because nothing is ever inserted
  // into that block: the substituted chain goes in the HEADER. The predecessor
  // is needed only to name the phis' entry incomings, and uniqueness is what
  // makes `EntryVal` dominate the header — every path into the loop runs
  // through it.
  BasicBlock *PH = L->getLoopPredecessor();
  BasicBlock *Ex = L->getExitBlock();
  if (!PH || !Ex || Ex == H || PH == H)
    return false;

  auto *BI = dyn_cast<BranchInst>(H->getTerminator());
  if (!BI || !BI->isConditional())
    return false;
  // The two successors must be exactly {header, exit}, and WHICH ONE is the
  // back edge decides the polarity normalisation below. Matching the branch as
  // WRITTEN, ignoring this, would accept `icmp sgt %sh, 0` with the loop as the
  // FALSE successor — a loop that continues while %sh <= 0 and never terminates
  // (lowering_ctlz_idiom_reject_inverted_successors.ll).
  bool ContinueOnTrue;
  if (BI->getSuccessor(0) == H && BI->getSuccessor(1) == Ex)
    ContinueOnTrue = true;
  else if (BI->getSuccessor(1) == H && BI->getSuccessor(0) == Ex)
    ContinueOnTrue = false;
  else
    return false;

  // ── Z2 — exactly two header phis, each two-in from {preheader, latch} ───
  SmallVector<PHINode *, 4> Phis;
  for (PHINode &P : H->phis())
    Phis.push_back(&P);
  if (Phis.size() != 2)
    return false;
  for (PHINode *P : Phis)
    if (P->getNumIncomingValues() != 2 || P->getBasicBlockIndex(PH) < 0 ||
        P->getBasicBlockIndex(H) < 0)
      return false;

  // ── Z3 / Z4 — classify the two phis by their LATCH values ──────────────
  // Which phi is which is derived from the recurrence itself, never from
  // position or type: the shift recurrence is the one whose latch value is
  // `shl <it>, 1`, the counter the one whose latch value is `add <it>, -1`.
  // Exactly one of each is required, so a loop with two shifts or two counters
  // is ambiguous and declines.
  for (PHINode *P : Phis) {
    auto *BO = dyn_cast<BinaryOperator>(P->getIncomingValueForBlock(H));
    // The latch value must be computed IN the loop. A loop-invariant latch
    // incoming defined in the preheader would otherwise slip past Z6, which
    // only inspects instructions that ARE in the header.
    if (!BO || BO->getParent() != H)
      return false;
    if (BO->getOpcode() == Instruction::Shl) {
      auto *Amt = dyn_cast<ConstantInt>(BO->getOperand(1));
      if (R.ShiftPhi || BO->getOperand(0) != P || !Amt || !Amt->isOne())
        return false;
      R.ShiftPhi = P;
      R.Shl = BO;
    } else if (BO->getOpcode() == Instruction::Add) {
      // `add` is commutative, so the phi may sit in either operand.
      Value *Step = nullptr;
      if (BO->getOperand(0) == P)
        Step = BO->getOperand(1);
      else if (BO->getOperand(1) == P)
        Step = BO->getOperand(0);
      auto *SC = dyn_cast_or_null<ConstantInt>(Step);
      if (R.CountPhi || !SC || !SC->isMinusOne())
        return false;
      R.CountPhi = P;
      R.Dec = BO;
    } else {
      return false;
    }
  }
  if (!R.ShiftPhi || !R.CountPhi)
    return false;

  // Z4 (seed) — C0 constant, because the emitted `sub` folds (C0 - 1) to a
  // LITERAL (the `_lh` template shape). The asymmetry with the SHIFT
  // recurrence's preheader incoming is deliberate and is PRD §5.4: that one is
  // an OPAQUE Value the fence never inspects, which is precisely what makes the
  // `s_ilogb.c:42` / `s_ilogbf.c:35` preheader pre-shift invisible here. The
  // closed form is exact for ANY v on the whole domain, so there is nothing to
  // look through — and an implementation that tried to FOLD the pre-shift into
  // the constant would get the constant wrong.
  R.C0 = dyn_cast<ConstantInt>(R.CountPhi->getIncomingValueForBlock(PH));
  if (!R.C0)
    return false;

  // ── Z9 — a shipped ctlz width, counter at the same width ───────────────
  R.Ty = dyn_cast<IntegerType>(R.ShiftPhi->getType());
  if (!R.Ty || !isShippedCtlzWidth(R.Ty->getBitWidth()) ||
      R.CountPhi->getType() != R.Ty)
    return false;

  // ── Z5 — the exit test, on the recurrence's OWN latch value ────────────
  auto *Cmp = dyn_cast<ICmpInst>(BI->getCondition());
  if (!Cmp || Cmp->getParent() != H || Cmp->getOperand(0) != R.Shl)
    return false;
  auto *Zero = dyn_cast<ConstantInt>(Cmp->getOperand(1));
  if (!Zero || !Zero->isZero())
    return false;
  CmpInst::Predicate Pred = Cmp->getPredicate();
  if (!ContinueOnTrue)
    Pred = CmpInst::getInversePredicate(Pred);
  if (Pred != CmpInst::ICMP_SGT)
    return false;
  R.Cmp = Cmp;

  // ── Z6 — the loop contains these six instructions and no seventh ───────
  // Note this is an IDENTITY check, not a classification: every instruction must
  // BE one of the five already recognized plus the branch. So a `store`, a call,
  // an `alloca`, a gep or a second compare all decline without needing their own
  // clause.
  //
  // DEBUG INFO IS INVISIBLE HERE, IN BOTH SPELLINGS — corrected bd ww4c.4, and
  // found independently by three lenses. This comment used to add "or an
  // old-format `llvm.dbg.value` intrinsic" to that list and assert that "the old
  // intrinsic spelling declines, which is over-safe and correct." MEASURED
  // FALSE: LLVM 19 auto-upgrades `llvm.dbg.value`/`llvm.dbg.declare` into
  // `#dbg_value` DbgVariableRecords at .ll-parse and bitcode-read time, BEFORE
  // any pass runs, so the old spelling never reaches this walk as a seventh
  // instruction and a loop carrying it is CLAIMED, not declined.
  //
  // That outcome is SOUND, and is the reason this is a documentation fix rather
  // than a code one: debug records carry no semantics, and LLVM's own erase-time
  // salvage handles them — measured on a loop with records on both recurrences,
  // the erased `%sh` becomes `#dbg_value(i32 undef, ...)` (the standard
  // "optimized out") and the counter phi becomes its RAUW'd incoming, with
  // `opt -passes=verify` clean. It is arguably BETTER than the documented
  // behaviour, since no coverage is lost in a debug build.
  // What must not survive is the framing: Z6 is DEBUG-BLIND BY CONSTRUCTION and
  // may not be quoted as declining anything on debug-info grounds.
  unsigned Seen = 0;
  for (Instruction &I : *H) {
    if (&I != R.ShiftPhi && &I != R.CountPhi && &I != R.Shl && &I != R.Dec &&
        &I != R.Cmp && &I != BI)
      return false;
    ++Seen;
  }
  if (Seen != 6)
    return false;

  // ── Z7 — exactly one escapee, and it is the counter's latch value ──────
  if (!noEscapingUse(R.ShiftPhi, L) || !noEscapingUse(R.CountPhi, L) ||
      !noEscapingUse(R.Shl, L) || !noEscapingUse(R.Cmp, L))
    return false;
  bool CounterEscapes = false;
  for (User *U : R.Dec->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI)
      return false;
    if (!L->contains(UI))
      CounterEscapes = true;
  }
  // Require the escape rather than merely tolerating it: if nothing left the
  // loop the substituted chain would be DEAD tainted arithmetic, and a dead
  // tainted op is a forward gate nobody uncomputes (memory
  // [[orphaned-emitted-gates-three-producers-2026-08-17]]). A loop nobody reads
  // is also nobody's coverage.
  if (!CounterEscapes)
    return false;

  // ── Z8 — quantum relevance ─────────────────────────────────────────────
  R.EntryVal = R.ShiftPhi->getIncomingValueForBlock(PH);
  if (!taint.Tainted.count(R.EntryVal))
    return false;
  // The entry value must live OUTSIDE the loop. Well-formed IR gives this for
  // free — a phi's incoming from PH must dominate PH's terminator, and the loop
  // does not dominate its own predecessor — but the substituted chain USES this
  // value while ERASING the loop's, so "it dominates the insertion point" is
  // load-bearing and is made structural here rather than inferred.
  if (auto *EI = dyn_cast<Instruction>(R.EntryVal))
    if (L->contains(EI))
      return false;

  // The header's address must not be taken. Z2 already covers the real hazard
  // (an `indirectbr` target is an extra predecessor, so the phis would carry a
  // third incoming and decline), but this mirrors `LoopUnrollPrepass`'s U8 and
  // costs one predicate — defence in depth is the deliberate posture here (PRD
  // §5.1), given a loop campaign that is 3-for-3 at finding over-accepts.
  if (H->hasAddressTaken())
    return false;

  // ── Z1(c) — NOT INSIDE ANY CYCLE, not merely "top-level per LoopInfo" ──
  // THIS CLAUSE IS THE bd ww4c.4 OVER-ACCEPT FIX, and it is the fourth
  // consecutive adversarial round in the loop campaign to find one. Z1's
  // `getParentLoop()` test above is a LOOPINFO property, and LoopInfo models
  // only NATURAL loops — a back edge u->v where v dominates u. An IRREDUCIBLE
  // cycle has no back edge, so LoopInfo reports no loop for it at all:
  // `getParentLoop()` returns null and `isInnermost()` is true even though the
  // header sits inside a cycle. Measured witness (bd ww4c.4,
  // lowering_ctlz_idiom_reject_irreducible_cycle.ll): with `entry` branching to
  // BOTH `A` and `B` neither dominates the other, so the cycle
  // A -> pre -> scan -> out -> B -> A is irreducible, `opt -passes=print<loops>`
  // reports exactly "Loop at depth 1 containing: %scan", and the fence claimed
  // it — putting the four emitted gates INSIDE the cycle, re-executed and
  // re-allocating a rail on every traversal. That is precisely the class Z1's
  // own comment above declares unreviewed ("an outer loop carrying tainted
  // values across iterations, adjudicated by owners nobody looked at for this"),
  // and the A/B twin proves the transition is real: changing `shl 1` to `shl 2`
  // — one token, taking the loop off-fence — makes the SAME module decline
  // loudly at Q1. A claim that converts a loud decline into an unreviewed accept
  // is the Prime Directive's one unforgivable direction.
  //
  // Reachability is the exact test rather than a proxy: H's only predecessors
  // are PH and H itself (Z1/Z2), so H is inside some larger cycle IFF control
  // THE CLAUSE IS EXACT, NOT CONSERVATIVE, and the reason is worth naming because
  // the informal argument below does not: `preds(H) = {PH, H}` is STRUCTURALLY
  // PINNED by Z2's phi-arity check — LLVM requires exactly one phi entry per
  // predecessor EDGE, and Z2 demands exactly two incomings indexed at PH and H —
  // while `getExitBlock()` being non-null makes `H -> Ex` the only way out. So H
  // can be re-executed only via a path `Ex ->* H`, which is precisely what this
  // tests. Equivalence, not approximation.
  // It also fails SAFE where it is approximate: `isPotentiallyReachable` gives up
  // after a bounded search (Limit=32) and answers TRUE conservatively, so a long
  // irreducible cycle declines rather than slipping through — measured on a
  // 40-block cycle (bd ww4c.4).
  //
  // can get from the exit back to the header. `isPotentiallyReachable` answers
  // that on the CFG itself, so it is blind to nothing — deliberately WITHOUT
  // `LoopInfo`, since LoopInfo's natural-loop blindness is the entire defect
  // (passing `LI` here would reintroduce it). `DT` is exact and only speeds the
  // query. A genuine parent loop is caught here too, redundantly with
  // `getParentLoop()` — belt and braces, and it costs one bounded CFG walk on a
  // candidate that has already passed every other clause.
  if (isPotentiallyReachable(Ex, H, /*ExclusionSet=*/nullptr, &DT))
    return false;

  R.L = L;
  R.Header = H;
  R.Preheader = PH;
  R.Exit = Ex;
  R.Latch = BI;
  return true;
}

// The §4.6 mutation — deliberately the smallest one that works, and NO BLOCK IS
// ERASED. The header keeps its preheader edge and becomes straight-line.
//
// Three consequences, each a hazard avoided rather than a stylistic preference:
//   * no block erase means no eighth site for the `LiteralIntegrity`
//     declineAddressTakenBlocks / removeUnreachableBlocksChecked discipline, so
//     no BlockAddress can be RAUW'd to `inttoptr (i32 1 to ptr)` behind us;
//   * the exit phi stays valid — for the guarded shape the merge keeps two
//     DISTINCT predecessors, [C0, preheader-side] and [%c, header]. A design
//     that deleted the loop and rewired the guard straight to the merge would
//     give one block two edges into a phi with different values;
//   * the guard, if any, is never touched: it stays ordinary tainted control
//     flow, which PredMux can now claim because the region became ACYCLIC.
void emitClosedForm(CtlzIdiom &R) {
  const unsigned N = R.Ty->getBitWidth();
  IRBuilder<> B(R.Header, R.Header->getFirstNonPHIIt());

  // The four ops. No nsw/nuw/exact anywhere (emission rule 2), the immarg is
  // the literal `i1 false` (rule 1), and the mask is N-1 from the RECURRENCE'S
  // OWN TYPE (rule 3). `EntryVal` is the preheader incoming, so this chain has
  // no dependence on the phis it is about to replace — and the preheader
  // dominates the header, so it dominates this insertion point.
  Value *S1 = B.CreateShl(R.EntryVal, ConstantInt::get(R.Ty, 1), "cq.ctlz.s1");
  Value *Z = B.CreateIntrinsic(Intrinsic::ctlz, {R.Ty},
                               {S1, ConstantInt::getFalse(B.getContext())},
                               /*FMFSource=*/nullptr, "cq.ctlz.z");
  Value *Mk = B.CreateAnd(Z, ConstantInt::get(R.Ty, N - 1), "cq.ctlz.m");
  // c_exit = (C0 - 1) - m. The APInt subtraction wraps in the counter's own
  // width, which is what the 2^32 oracle modelled.
  Value *C = B.CreateSub(ConstantInt::get(R.Ty, R.C0->getValue() - 1), Mk,
                         "cq.ctlz.c");

  // Drop the back edge. The header keeps its single edge to the exit block, so
  // the exit's phis need no update: the header was already a predecessor of the
  // exit exactly once, and still is.
  R.Latch->eraseFromParent();
  IRBuilder<>(R.Header).CreateBr(R.Exit);

  // The header's phis now have one incoming each.
  R.ShiftPhi->removeIncomingValue(R.Header, /*DeletePHIIfEmpty=*/false);
  R.CountPhi->removeIncomingValue(R.Header, /*DeletePHIIfEmpty=*/false);

  // Rewrite the escaping counter. Done AFTER the incoming removal so the only
  // remaining users are the out-of-loop ones Z7 accounted for.
  R.Dec->replaceAllUsesWith(C);

  // Erase the five dead values IN DEPENDENCY ORDER, by pointer, with no
  // traversal of any kind. This is deliberately stronger than PRD §4.6 step 5's
  // collect-then-mutate WeakTrackingVH worklist: Z6 proved the loop holds
  // exactly these six instructions and Z7 proved where their uses are, so the
  // dead set is known exactly and nothing has to be discovered by walking. The
  // hazard the worklist exists to dodge — memory
  // [[dce-under-block-iterator-loopphi-uaf]], where an inline
  // RecursivelyDeleteTriviallyDeadInstructions under a block iterator crashes
  // across a loop-phi back edge because the operand is not a dominator — cannot
  // arise here because there is no iterator and no recursion.
  //   cmp : sole user was the erased branch
  //   shl : users were cmp (gone) and ShiftPhi's now-removed latch incoming
  //   dec : users were CountPhi's now-removed latch incoming + the RAUW'd escapes
  //   phis: users were shl / dec, both gone by this point
  R.Cmp->eraseFromParent();
  R.Shl->eraseFromParent();
  R.Dec->eraseFromParent();
  R.ShiftPhi->replaceAllUsesWith(R.ShiftPhi->getIncomingValue(0));
  R.CountPhi->replaceAllUsesWith(R.CountPhi->getIncomingValue(0));
  R.ShiftPhi->eraseFromParent();
  R.CountPhi->eraseFromParent();
}

}  // namespace

bool recognizeCtlzIdiomLoops(Module &M, TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // The LoopLowering.cpp / LoopUnrollPrepass.cpp direct-construction idiom.
    // No ScalarEvolution: this fence is purely structural, and bd ww4c's 40-cell
    // grid measured SCEV's shift-compare FIRING RULE, which is a different
    // question from this recognizer's spec — the two must not be assumed to
    // coincide.
    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;

    for (Loop *L : LI.getLoopsInPreorder()) {
      CtlzIdiom R;
      if (!fencePasses(L, taint, DT, R))
        continue;
      if (::getenv("CQ_CTLZ_DBG"))
        errs() << "CQ_CTLZ_DBG: claiming shift-count loop in @" << F.getName()
               << " (i" << R.Ty->getBitWidth() << ", C0=" << *R.C0 << ")\n";
      emitClosedForm(R);
      // One claim per call; the caller re-propagates. `taint` now holds
      // dangling entries for the five erased values and none for the four new
      // ones, so NOTHING may read it before that — which is why this returns
      // immediately rather than continuing the scan.
      return true;
    }
  }
  return false;
}

}  // namespace cq
