// Uncomputation.cpp — see header. The whole-DAG LIFO uncompute driver (Phase 5
// WI-4, PRD §2.1/§2.11). Selects each tainted DATA terminal handle
// (ChainWalk::isTerminalHandle), recovers the whole forward DAG over the SET of
// terminals (DagTraversal::recoverDataDag — fan-out and QQ are DAG shapes, not
// bails), and reverses it ONCE: a single reverse-topological pass adjoints each
// gate exactly once (void in-place `_unc`, EmitInverse) and frees each rail after
// its last reverse-use.
//
// The reversal is sound only for a CLOSED, non-measured, non-escaped DAG whose
// gates all dominate the single insertion point (acyclic + dominating ⇒ each gate
// ran exactly once on every reaching path). A measured intermediate declines
// LOUDLY (a free of a measured register is a hidden collapse, Rule 5/6); an
// escaped / not-closed / unplaceable DAG is a Rule-6/8 safe-leak (left allocated,
// never a dirty free). Phase-4-owned control rails are subtracted up front
// (DD-4 — `ControlOwnedRails`) so a flag / work / merge out-rail is never walked.

#include "Uncomputation.h"

#include "ChainWalk.h"          // isTerminalHandle
#include "DagTraversal.h"       // recoverDataDag / DataDag
#include "EmitInverse.h"        // emitInverseCall
#include "FreePoint.h"          // computeFreePoint
#include "TaintPropagation.h"   // TaintSet
#include "WidthDispatch.h"      // freeFn

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// The uncompute-spine diagnostic FreePoint does NOT own (test_C_libtooling-3h8): a
// NON-terminal DAG rail is read by a measurement sink. FreePoint inspects only the
// terminal's own users, so it never sees the upstream measure; DagTraversal (which
// recovers the whole DAG) flags it and the driver rejects here. LOUD reject — a
// free of a measured register is a hidden projective collapse (Rule 5/6). The
// negative fixture lowering_uncompute_dead_sibling_premeasure.ll mirrors this
// string character-for-character.
constexpr char kMsgLineageMeasured[] =
    "cq uncompute: dead chain would free a measured register";

// WI-5 silent→loud flips (PRD §2.12; the Prime Directive — an unprovable shape
// declines, never silently leaks a dirty rail). The negative fixtures mirror
// each string CHARACTER-FOR-CHARACTER (Rule 12):
//   * lowering_uncompute_uninvertible.ll   → kMsgUninvertible
//   * lowering_uncompute_divergent_arm.ll  → kMsgDivergentArm
//
// A recovered gate Phase 5 has NO in-place adjoint for (a permutation primitive
// like `cqrt_cnot`, a controlled callee — outside `isInverseEmittable`). Pre-WI-5
// the driver IGNORED `emitInverseCall`'s `false` and still freed the rail =
// a dirty free (a hidden collapse, Rule 6/8). DD-1: the driver owns this message.
constexpr char kMsgUninvertible[] =
    "cq uncompute: dead chain contains an un-invertible primitive";

// A MUTATING gate that does not DOMINATE the single merge free point: it ran on
// only some exclusive paths, so one unconditional adjoint at the merge would fire
// on paths the forward gate never took (the reverted-543bd85 divergent-arm
// miscompile). Per-arm reverse-play is Phase 4's job; Phase 5 declines (§2.4).
constexpr char kMsgDivergentArm[] =
    "cq uncompute: dead chain spans divergent control-flow arms";

// Loud `DiagnosticInfoUnsupported(DS_Error)` on `Where`, with its `!dbg` so the
// rejection is SOURCE-LOCATED (mirrors FreePoint::diagnose). `opt` exits non-zero,
// which the negative LIT fixture inverts with `RUN: not`.
void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// A data-register producer we own: a tainted `cqrt_alloc_<W>` mint or an
// UNCONTROLLED `cq_template_*` result. Controlled results are Phase-4 scratch;
// rotations are void and never terminals.
bool isDataProducer(const CallInst *H) {
  const Function *Callee = H->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  if (N.starts_with("cqrt_alloc_"))
    return true;
  // Phase 7.5 Inc 2: a QRAM array handle (`cqrt_qram_alloc_<W>`) backing an
  // ALLOCA mutable array is an in-place-mutated register the spine reverses — a
  // DEAD scratch array (its only users are stores) is a data terminal whose
  // stores reverse in LIFO (EmitInverse `cqrt_qram_store_<W>_unc`), the array
  // handle itself left allocated (never freed; §2.9). A const-global QROM array
  // handle (Inc 1) is NOT tainted, so it never reaches terminal selection here.
  if (N.starts_with("cqrt_qram_alloc_"))
    return true;
  // Phase 7.5: a QRAM load result is a reversible data producer (copy-out) — a
  // dead loaded value is a data terminal the spine reverses via its `_unc`
  // (EmitInverse) exactly like a `cq_template_*` producer. The `_unc` twin is not
  // a forward producer.
  if (N.starts_with("cqrt_qram_load_") && !N.ends_with("_unc"))
    return true;
  return N.starts_with("cq_template_") && !N.contains("_controlled");
}

// A QRAM array handle (`cqrt_qram_alloc_<W>` result) — a CLASSICAL resource token
// the reversal NEVER frees (its stores reverse, but a `cqrt_free` on it would be a
// hidden measurement of the restored cells; §2.9, Inc 1 "array-handle-never-freed").
bool isQramArrayHandle(const Value *V) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_qram_alloc_");
}

// `railOf` (the rail a gate creates — the value its adjoint zeroes and the driver
// then frees) lives in `ChainWalk` (Rule 14). The freeze DECISION (`DagTraversal`
// step 3b) and this emission driver must agree on which rail a gate owns, so the
// definition is shared, not duplicated per-TU — the same hoist `LiteralIntegrity`
// applied to `valueCarriesUndef` "so cone proof and guard cannot drift".

// Can `BB` execute more than once — i.e. is it reachable from ITSELF? A plain
// successor DFS, deliberately NOT `LoopInfo::getLoopFor` (§2.9's at-most-once
// guard used that at first). `LoopInfo` recognizes only NATURAL loops — a single
// back edge to a header that dominates the body — so an IRREDUCIBLE cycle (two
// entries, no dominating header) returns null from it while still executing its
// blocks repeatedly. Emitting the once-only whole-DAG reversal there applies every
// adjoint K times and resets every rail K times (Rules 5/6). `clang -O1` rarely
// builds an irreducible CFG, but the pass accepts hand-written IR, and "the
// frontend probably won't" is not a proof. This test is a strict superset of the
// natural-loop one and costs one DFS per reversed group.
bool blockCanRepeat(BasicBlock *BB) {
  SmallPtrSet<BasicBlock *, 16> Seen;
  SmallVector<BasicBlock *, 16> Work(succ_begin(BB), succ_end(BB));
  while (!Work.empty()) {
    BasicBlock *B = Work.pop_back_val();
    if (B == BB)
      return true;
    if (!Seen.insert(B).second)
      continue;
    Work.append(succ_begin(B), succ_end(B));
  }
  return false;
}

// The single insertion point for the whole-DAG reversal: the nearest common
// POST-dominator of every terminal's last-use anchor, after the latest anchor in
// that block (else its first insertion point, after φ-nodes). Null if the anchors
// do not reconverge (a non-reconverging multi-terminal shape — skip).
Instruction *dagInsertPoint(ArrayRef<Instruction *> Ats, PostDominatorTree &PDT) {
  BasicBlock *Common = Ats.front()->getParent();
  for (Instruction *A : Ats.drop_front()) {
    Common = PDT.findNearestCommonDominator(Common, A->getParent());
    if (!Common)
      return nullptr;
  }
  Instruction *Latest = nullptr;
  for (Instruction *A : Ats)
    if (A->getParent() == Common && (!Latest || Latest->comesBefore(A)))
      Latest = A;
  if (Latest)
    return Latest;
  BasicBlock::iterator FI = Common->getFirstInsertionPt();
  return FI == Common->end() ? nullptr : &*FI;
}

// Emit the whole-DAG adjoint at `At` (PRD §2.11): each gate's void `_unc` once, in
// reverse program order; each rail freed right after the adjoint of the earliest
// forward gate that TOUCHES it — which, in reverse, is the LAST of its
// reverse-touches, so the free lands after every reverse-read of the rail.
//
// "TOUCHES" MEANS READS-OR-WRITES, AND THE DISTINCTION IS LOAD-BEARING (bd
// test_C_libtooling-uow0 Rule-13 round). This used to key on the earliest gate whose
// `railOf` IS the rail — i.e. only the gates that WRITE it. A rail is also
// reverse-touched by every gate that merely READS it as a borrowed operand (a QRAM
// store's flag / idx / val), and such a gate's `_unc` reads it too. If a rail's
// first WRITE comes after a gate that READS it, keying on writes alone puts the
// free ahead of that gate's `_unc`: a use-after-free.
//
// MEASURED, and it is why this is not a theoretical tidy-up. A tainted `cqrt_alloc_`
// root used as a guarded store's flag and rotated only AFTER the store:
//     %z = cqrt_alloc_i32(%q2) ; qram_store_ctl(%z,%h,3,4) ; ry(%z,0.75)
// emitted `cqrt_free(%z)` BEFORE `cqrt_qram_store_i32_controlled_unc(%z, ...)`
// (`opt` rc=0, verify-clean; stage 2b: `VIOLATION F2-use-after-free`). The same
// hole exists for the PLAIN store's borrowed `idx`/`val` and PRE-DATES uow0 — uow0
// merely stopped an unrelated mis-attribution from accidentally papering over the
// guarded-flag instance of it. Fixture:
// lowering_uncompute_borrowed_operand_free_order.ll.
//
// THIS RE-KEYING DOES NOT CHANGE THE FREED SET — only positions, and only LATER. A
// rail is freeable iff some recovered gate WRITES it (`Freeable`), exactly as
// before; the touch map decides WHERE, never WHETHER. First-touch is at or before
// first-write in forward order, so in reverse the free moves later or stays put.
// Non-register operands (a classical angle, a literal) are skipped: they can never
// be a rail, and an off-ABI `cqrt_qram_store_*` with a literal in its array slot
// would otherwise reach `cqrt_free(i32 5)`.
//
// SAY THAT PRECISELY, BECAUSE THE UNQUALIFIED VERSION IS FALSE. It holds for the
// re-keying IN ISOLATION. Combined with the bd uow0 `railOf` correction it does NOT:
// `railOf` of a guarded QRAM store moved from the arg-0 flag to the arg-1 array, so
// `Freeable` loses that flag and gains the array — and the array is then dropped by
// `isQramArrayHandle` anyway. A flag rail with no OTHER writing gate in the DAG
// therefore stops being freed at all. That is the Rule-6 fallback (left allocated,
// never freed dirty) and no shipped shape reaches it — `GuardedStoreArmEmit` always
// mints its flag as a `cq_template_icmp_*` producer, which is its own writing gate —
// but "the freed set is unchanged" full stop was an over-claim, and this file is
// where the next agent would have read it (bd uow0 Rule-13 round 2).
//
// `Freeable` IS INTERSECTED WITH THE CLOSURE-SCANNED RAIL SET, and that is a
// correctness fence, not tidiness. `recoverDataDag`'s step-3 scan — which sets
// `MeasuredUpstream`, `NotClosed`, `Escaped` and now `PreservingSinks` — iterates
// `D.Rails` (roots ∪ template producers), while `Freeable` is built from
// `railOf(G)` over `D.Calls`. Those sets are not equal, and a member of the
// difference would be FREED having never been measure-, closure- or sink-scanned:
// a free of a possibly-measured, possibly-still-read register (Rule 6), invisible to
// `opt -verify`. The one emitter-mintable member is a `@__cq_q_<callee>_<mask>`
// specialization-clone call, which `isInverseEmittable` accepts. It is unreachable
// today (both routes decline loudly — a hand-written `__cq_q_` declaration hits
// `cq taint escape`, and the real specializer route hits the 7.6 continued-lineage
// decline), but "unreachable" was the prior justification and it was recorded
// WRONGLY, as "a downstream guard removes it". Intersecting makes it structural.
void emitDagReversal(const DataDag &D, Instruction *At, WidthDispatch &wd,
                     TaintSet &taint) {
  DenseMap<Value *, CallInst *> FirstTouch;  // rail → earliest gate reading OR writing it
  SmallPtrSet<Value *, 8> Freeable;          // rails some recovered gate WRITES
  SmallVector<std::pair<CallInst *, Value *>, 16> TouchOrder;  // deterministic
  for (CallInst *G : D.Calls) {              // D.Calls is forward program order
    auto note = [&](Value *V) {
      if (!V || isa<Constant>(V))
        return;
      if (FirstTouch.try_emplace(V, G).second)
        TouchOrder.emplace_back(G, V);  // first occurrence wins
    };
    Value *R = railOf(G);
    note(R);
    if (R && !isa<Constant>(R) && D.Rails.count(R))
      Freeable.insert(R);  // closure-scanned rails only — see the header note
    for (Value *Op : G->args())
      note(Op);
  }
  // gate → the rails freed right after its adjoint, in first-touch order (a
  // `DenseMap` walk would be non-deterministic and de-stabilize every FileCheck).
  DenseMap<CallInst *, SmallVector<Value *, 2>> FreeAt;
  for (const auto &P : TouchOrder)
    if (Freeable.count(P.second))
      FreeAt[P.first].push_back(P.second);

  IRBuilder<> B(At);
  SmallPtrSet<CallInst *, 16> Seen;
  for (int i = (int)D.Calls.size() - 1; i >= 0; --i) {
    CallInst *G = D.Calls[i];
    if (!Seen.insert(G).second)
      continue;  // a shared-prefix gate already adjointed (once-per-gate)
    // M-A Inc 1 (bd 6uqc): record the adjoint into `taint.SpineOps` so the late
    // live-record guard reads "the compiler is undoing ITSELF here" as a FACT
    // rather than inferring it from the callee name (a re-emitted self-inverse
    // gate is textually identical to a forward one — see EmitInverse.h).
    emitInverseCall(B, G, wd, /*CurHandle=*/nullptr, &taint.SpineOps);
    // bd 261j(a) — a FROZEN rail: RECORDED into a kept carrier (an output tape)
    // AND carrying a gate that is not a basis permutation of live conditions, so
    // its forward chain does NOT return it to |0⟩ (`DagTraversal` step 3b proves
    // this). It gets NO `cqrt_free`: it is LEFT ALLOCATED, the Rule-6 fallback for
    // a rail that is not provably |0⟩. Not a decline — no diagnostic, no new
    // symbol — and PER-RAIL: every non-frozen rail in the same DAG still frees
    // (lowering_io_tape_derived_uncompute.ll is the discrimination pin).
    //
    // THE FREEZE SUPPRESSES THE FREE, NEVER THE ADJOINT — and that distinction is
    // the whole soundness argument, learned the hard way. Skipping the frozen
    // rail's `emitInverseCall` as well (the first implementation of this ruling)
    // is a SILENT MISCOMPILE, MEASURED four independent ways in the Rule-13 round:
    // a surviving non-frozen rail's `_unc` READS the frozen rail, and it needs it
    // at the value it held when the forward producer ran — not at its final
    // forward value. Those differ exactly when a skipped non-diagonal gate on the
    // frozen rail sits AFTER the reader's producer, e.g.
    //     ry(%h,0.5); %op = add(%h,2); ry(%h,0.25); tape(%op)
    // (six lines of ordinary C — a chained `cq_theta` lowers to an in-place `ry`
    // on the EXISTING handle). Dropping `ry(%h,-0.25)` leaves `add_unc(%op,%h,2)`
    // recomputing from a scrambled %h, so %op is NOT zeroed and `cqrt_free(%op)`
    // becomes a hidden measurement — curing one Rule-6 violation by introducing
    // another, on a rail that was previously freed SOUNDLY. Same mechanism reached
    // the QRAM surface through `cqrt_qram_load_unc`'s idx slot.
    //
    // Emitting every adjoint keeps the gate stream BYTE-IDENTICAL to the
    // pre-261j stream, so no ordering, dominance or use-after-free hazard can be
    // introduced at all: the change is purely the removal of some `cqrt_free`s.
    // Applying an adjoint to a rail we then leak is harmless — every adjoint is
    // unitary, and `cqrt_free` is the only measurement-class op in the surface.
    // On the kept carrier it is not even observable: a local unitary on a leaked
    // rail cannot change the tape's reduced state.
    //
    // The suppression is SUBTRACTIVE and lands HERE, at the last step, rather than
    // pruning `D.Calls` in recovery: the invertibility pre-scan, the InLoop
    // backstop and the dominance scan above all iterate `D.Calls`, so a prune
    // would silently convert their loud declines into rc-0 accepts (risk 1/2;
    // lowering_reject_uncompute_uninvertible_taped.ll pins that it does not).
    for (Value *FR : FreeAt.lookup(G)) {
      if (isQramArrayHandle(FR) || D.FrozenRails.count(FR))
        continue;  // a QRAM array handle is a classical resource token whose
                   // stores reverse (LIFO) but which is NEVER freed — a
                   // `cqrt_free` on it would be a hidden measurement of the
                   // (now-restored) classical cells (§2.9, Inc 1
                   // "array-handle-never-freed"); a frozen rail is the bd 261j(a)
                   // case above.
      CallInst *Free = B.CreateCall(wd.freeFn(), {FR});
      if (DebugLoc DL = G->getDebugLoc())
        Free->setDebugLoc(DL);
      taint.SpineOps.insert(Free);  // M-A Inc 1 — teardown traffic, not a data use
    }
  }
}

// Classify + recover + reverse ONE group of data terminals at a single insertion
// point (PRD §2.11; the body of the per-function driver, factored out so the
// regular straight-line group and each Phase-7.3 ITERATION-LOCAL loop group are
// reversed independently — a shared union insertion point across a loop boundary
// would place an in-body free at a function-scope point, the Risk-1 hazard).
//
// `IterLocal` ⇒ the group's terminals were proven by `lowerLoops` to be
// iteration-local temps of ONE recognized Case-B loop (FreePoint already lifted
// its backedge guard for them, returning an IN-BODY insertion point). The §2.9
// acyclic InLoop backstop is then lifted — BUT only after re-confirming every
// recovered gate sits in an `IterationLocalBlocks` block (defense-in-depth: a DAG
// that escaped the loop is leaked, never reversed once over a K-times rail). For
// the regular group (`IterLocal=false`) the backstop stands exactly as before —
// a loop-resident gate leaves the whole DAG allocated (a safe leak).
void reverseTerminalGroup(Function &F, ArrayRef<CallInst *> Terminals,
                          TaintSet &taint, WidthDispatch &wd, DominatorTree &DT,
                          PostDominatorTree &PDT, LoopInfo &LI, bool IterLocal) {
  if (Terminals.empty())
    return;

  // 2. Classify each terminal (FreePoint owns measure/escape/loud diagnostics).
  SmallVector<Value *, 8> InsertTerms;
  SmallVector<Instruction *, 8> InsertAts;
  for (CallInst *Term : Terminals) {
    FreePoint FP = computeFreePoint(Term, F, PDT, taint);
    if (FP.Kind != FreePointKind::Insert)
      continue;
    InsertTerms.push_back(Term);
    InsertAts.push_back(FP.At);
  }
  if (InsertTerms.empty())
    return;

  // 3. Recover the whole forward DAG (union over all Insert terminals).
  DataDag D = recoverDataDag(InsertTerms, taint, DT);
  if (D.MeasuredUpstream) {
    diagnose(D.UpstreamMeasure, kMsgLineageMeasured);
    return;
  }
  if (D.Escaped || D.NotClosed || D.Calls.empty())
    return;

  // Invertibility pre-scan (WI-5, PRD §2.12/§2.10).
  CallInst *Uninvertible = nullptr;
  for (CallInst *G : D.Calls)
    if (!isInverseEmittable(G)) {
      Uninvertible = G;
      break;
    }
  if (Uninvertible) {
    diagnose(Uninvertible, kMsgUninvertible);
    return;
  }

  // §2.9 acyclic backstop. A loop-carried tainted live range is loudly declined
  // UPSTREAM; defense-in-depth here: a single adjoint cannot undo a gate that ran
  // once per iteration, so if ANY recovered gate sits inside a natural loop,
  // leave the DAG allocated (a safe leak) — UNLESS this is an affirmatively-
  // recognized Phase-7.3 ITERATION-LOCAL group, whose gates all sit in
  // `IterationLocalBlocks` and whose recovery point is IN-BODY (once per
  // iteration). The explicit re-confirmation that every gate is in an
  // iteration-local block is the Rule-13 backstop (a DAG that walked outside the
  // loop is leaked, never reversed).
  bool InLoop = false;
  for (CallInst *G : D.Calls)
    if (LI.getLoopFor(G->getParent())) {
      InLoop = true;
      break;
    }
  if (InLoop) {
    if (!IterLocal)
      return;  // safe leak (acyclic backstop stands)
    for (CallInst *G : D.Calls)
      if (!taint.IterationLocalBlocks.count(G->getParent()))
        return;  // a gate escaped the loop body — leak, never reverse once.
  }

  // 4. Single insertion point (in-body for an iteration-local group — FreePoint
  //    returned the per-iteration anchor; for the regular group, the function
  //    post-dominator).
  //
  //    THE ANCHOR SET INCLUDES EVERY SOURCE-PRESERVING SINK ON EVERY RAIL (bd
  //    8gi5(3) + bd e4zs). `computeFreePoint` is called per TERMINAL and scans
  //    `Terminal->users()`, so it sees a tape write / method-B copy only when the
  //    rail it reads happens to BE a terminal. A preserving sink on an UPSTREAM
  //    rail was invisible to it, and the reversal — including that rail's
  //    `cqrt_free` — could be placed BEFORE the read. MEASURED on both surfaces
  //    (`opt` rc=0, verify-clean, stage 2b `F2-use-after-free`); the fixtures are
  //    lowering_uncompute_tape_nonterminal_rail.ll and
  //    lowering_uncompute_copy_nonterminal_rail.ll.
  //
  //    A sink anchors at its NEXT node because `dagInsertPoint` treats anchors as
  //    insert-BEFORE points (that is the convention `computeFreePoint` already
  //    uses: it returns `Latest->getNextNode()`). A `cqrt_*` sink is a CallInst and
  //    never a terminator, so the next node always exists.
  //
  //    "MOVING `At` LATER CAN ONLY ADD REVERSE-READS THAT ALREADY HAPPENED" IS
  //    FALSE, and it was this comment's first claim. It can also move the reversal
  //    past a WRITE. Clause (d) of the record invariant (bd memory
  //    [record-freeze-invariant-2026-08-10]) requires every register an adjoint
  //    reads to hold the value it held when the forward gate ran, and reverse
  //    program order delivers that only for gates the DAG WALKED. `recoverDataDag`
  //    walks operands in `taint.Tainted` only, so an in-place gate on an UNTAINTED
  //    live register is invisible to it — and if the anchors move `At` past such a
  //    gate, an adjoint recomputes from a relabelled register. MEASURED: with
  //    `cqrt_ry_i32(%idx, 0.9)` sitting between the old and new points,
  //    `cqrt_qram_load_i32_unc(%L, %arr, %idx)` pops the wrong cell and
  //    `cqrt_free(%L)` becomes a hidden measurement (stage 2b
  //    `UNPROVEN T2-operand-mutated`), where HEAD was clean.
  //
  //    So the extension is CONDITIONAL: if the sinks actually move the point, every
  //    register the adjoints will read must be free of in-place gates this DAG does
  //    not own. That test is function-global rather than span-based on purpose —
  //    a span between two blocks is exactly the kind of reasoning this ticket's
  //    history says not to trust, and the conservative direction is a leak.
  //
  //    The two remaining hazards are re-proved on the FINAL `At` below, never
  //    assumed here: the every-gate-dominates-`At` scan, and at-most-once (§2.9).
  SmallVector<Instruction *, 8> Anchors(InsertAts.begin(), InsertAts.end());
  for (CallInst *S : D.PreservingSinks)
    if (Instruction *N = S->getNextNode())
      Anchors.push_back(N);
  Instruction *At = dagInsertPoint(Anchors, PDT);
  if (!At)
    return;
  if (At != dagInsertPoint(InsertAts, PDT)) {
    SmallPtrSet<Value *, 16> ReadByAdjoints;
    for (CallInst *G : D.Calls)
      for (Value *Op : G->args())
        if (!isa<Constant>(Op))
          ReadByAdjoints.insert(Op);
    SmallPtrSet<const CallInst *, 16> InDag(D.Calls.begin(), D.Calls.end());
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (!InDag.count(CI))
            for (Value *Op : CI->args())
              if (ReadByAdjoints.count(Op) && isInPlaceGateOn(CI, Op))
                return;  // clause (d) unprovable at the moved point — safe leak.
  }

  // Every gate must DOMINATE `At` (acyclic + dominating ⇒ ran exactly once on
  // every reaching path). For an iteration-local group this holds WITHIN the
  // iteration (no value crosses the backedge by construction of L4b); a gate that
  // does not dominate the in-body `At` (a split across a classical in-body
  // diamond) declines LOUDLY rather than reverse a partial chain.
  CallInst *NonDominating = nullptr;
  for (CallInst *G : D.Calls)
    if (!DT.dominates(G, At)) {
      NonDominating = G;
      break;
    }
  // (§2.9) AT-MOST-ONCE. Dominance says every gate ran before `At`; it says NOTHING
  // about how many TIMES `At` itself runs. If `At` sits in a natural loop, one
  // emitted reversal executes K times: the adjoint of a once-run `cqrt_ry_i32(%h,
  // +0.5)` is applied K times (the wrong unitary), and every `cqrt_free` resets a
  // rail K times — iterations 2..K resetting a rail that is provably NOT |0⟩, i.e.
  // K-1 hidden measurements plus a double free (Rules 5/6). Leave the DAG allocated
  // instead (a safe leak), exactly as the acyclic backstop above does for a
  // loop-resident GATE.
  //
  // THE TEST IS THE FINAL `At`'s BLOCK — and it is `blockCanRepeat`, a
  // reachable-from-itself DFS, not `LoopInfo`: an IRREDUCIBLE cycle is not a
  // natural loop and `getLoopFor` returns null for it while its blocks still run
  // repeatedly (see that helper). Neither the `D.Calls` backstop above nor a test
  // on the preserving SINKS is
  // sufficient: `dagInsertPoint` takes the nearest common POST-dominator of the
  // anchors, and the nearest common post-dominator of two divergent non-loop arms is
  // routinely a LOOP-BODY block that both arms branch into. So `At` can land in a
  // loop with no sink and no recovered gate in one. MEASURED two ways: a
  // sink-anchored module whose reversal moved from an arm into `%loop` (the bd
  // 8gi5/e4zs anchors' own regression, found by their Rule-13 round), and — with NO
  // sink anchors at all — a terminal whose two tape-write uses sit in divergent
  // arms, where `computeFreePoint`'s own NCA already put `cqrt_free` inside `%loop`
  // at HEAD 1ec8c45. The second is PRE-EXISTING and this guard is what closes it.
  //
  // AFTER the dominance scan, deliberately. A pre-emptive placement swallows the
  // loud `kMsgDivergentArm` decline into a silent rc-0 leak — bd 261j(a) risk 1,
  // measured on the first draft of this guard.
  //
  // The 7.3 EXCEPTION is affirmative, not incidental: an ITERATION-LOCAL group is
  // reversed IN-BODY once per iteration BY DESIGN, over rails re-minted each
  // iteration, and `FreePoint` already re-checked that its anchor is in-body.
  if (NonDominating) {
    diagnose(NonDominating, kMsgDivergentArm);
    return;
  }

  if (blockCanRepeat(At->getParent()) &&
      !(IterLocal && taint.IterationLocalBlocks.count(At->getParent())))
    return;  // safe leak — never a once-minted reversal on a per-iteration path.

  // 5. Reverse the whole DAG once at `At`.
  emitDagReversal(D, At, wd, taint);
}

}  // namespace

void uncompute(Module &M, WidthDispatch &wd, TaintSet &taint) {
  // Module-scoped walk. In the `runOnFunction` shim only the requested F's ops
  // were lowered, so only F yields candidates (the target set reads the
  // module-wide taint).
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;

    // 1. Collect terminal candidates: tainted data producers whose only users are
    //    benign, MINUS Phase-4-owned control rails (DD-4 — never select a flag /
    //    work / merge out-rail the swap-route emitter owns and leaves allocated;
    //    its reversal-or-leak is Phase 4's, not the data-uncompute driver's).
    SmallVector<CallInst *, 8> Terminals;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *H = dyn_cast<CallInst>(&I);
        if (!H || !taint.Tainted.count(H) || !isDataProducer(H))
          continue;
        if (taint.ControlOwnedRails.count(H))
          continue;  // DD-4: Phase-4 owns this rail
        if (taint.OutputRails.count(H))
          continue;  // 7.6: kept I/O output rail — never a data terminal
                     // (PRD-7.6 §2.5). Defensive: a tape-write out_handle is not
                     // a data producer, so it never reaches here, but the
                     // explicit image is load-bearing, like ControlOwnedRails.
        if (taint.GraveyardRails.count(H))
          continue;  // 7.2 Inc 3: a parked abort/exit graveyard rail (or the
                     // abort flag) — kept frozen + entangled, NEVER reversed or
                     // freed (Rule 6, plan §2-A). The cswap-into-graveyard already
                     // makes `isTerminalHandle` false, but the explicit image is
                     // load-bearing — the SAME discipline as OutputRails above.
        if (!isTerminalHandle(H, taint))
          continue;  // collapse the reassignment DAG to its terminals (§2.1)
        Terminals.push_back(H);
      }
    if (Terminals.empty())
      continue;

    DominatorTree DT(F);
    PostDominatorTree PDT(F);
    LoopInfo LI(DT);

    // Partition the terminals into the REGULAR straight-line group and one group
    // per recognized Phase-7.3 ITERATION-LOCAL loop (a terminal whose def block
    // ∈ `IterationLocalBlocks`). The groups are reversed at INDEPENDENT insertion
    // points: a regular straight-line terminal at the function post-dominator, an
    // iteration-local temp IN-BODY (once per iteration). A single union point
    // across that boundary would place an in-body free at a function-scope point
    // (the Risk-1 hazard). Loops are kept in first-seen (BB) order for
    // FileCheck-stable emission.
    SmallVector<CallInst *, 8> Regular;
    SmallVector<Loop *, 4> IterLoops;
    DenseMap<Loop *, SmallVector<CallInst *, 4>> IterByLoop;
    for (CallInst *Term : Terminals) {
      Loop *L = LI.getLoopFor(Term->getParent());
      if (L && !taint.IterationLocalBlocks.empty() &&
          taint.IterationLocalBlocks.count(Term->getParent())) {
        if (!IterByLoop.count(L))
          IterLoops.push_back(L);
        IterByLoop[L].push_back(Term);
      } else {
        Regular.push_back(Term);
      }
    }

    reverseTerminalGroup(F, Regular, taint, wd, DT, PDT, LI, /*IterLocal=*/false);
    for (Loop *L : IterLoops)
      reverseTerminalGroup(F, IterByLoop[L], taint, wd, DT, PDT, LI,
                           /*IterLocal=*/true);
  }
}

}  // namespace cq
