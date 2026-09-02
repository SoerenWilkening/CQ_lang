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
#include "WireWalk.h"          // provablyBefore (the ONE position-aware proof)
#include "WidthDispatch.h"      // freeFn

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"   // is_contained
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

// `blockCanRepeat` — "is `BB` reachable from ITSELF" — is declared in FreePoint.h
// and DEFINED in FreePoint.cpp. It lived here, in this anonymous namespace, until
// bd test_C_libtooling-4p7j's Rule-13 RE-review (finding G1) found a FOURTH
// consumer that had been left on the blind `LoopInfo` predicate:
// `FreePoint::blockInLoop`, the guard behind the LOUD `kMsgLoopBackedge`. So the
// natural-loop spelling of a backedge-crossing live range declined loudly while
// the irreducible spelling silently leaked. One definition, two modules, no
// re-spelt DFS (Rule 14 — the `railOf` / `isAbiQramStore` drift hazard).

// `blockCanRepeat` with the natural-loop FAST PATH in front and one DFS per
// distinct block, so the two drivers below can afford to ask it PER GATE rather
// than once per group.
//
// WHY IT IS ASKED PER GATE AT ALL (bd test_C_libtooling-4p7j Rule-13 round,
// finding F1). Both drivers used `LoopInfo::getLoopFor` for their acyclic
// backstops and only the FINAL-`At` test used `blockCanRepeat`. `LoopInfo` sees
// NATURAL loops only, so an IRREDUCIBLE cycle (two entries, no dominating
// header) returned null for its blocks while executing them K times — and an
// in-place gate inside such a cycle was adjointed ONCE at the exit, leaving the
// rail at `f(h) + (K-1)·δ` when `cqrt_free` reset it: a hidden measurement
// (Rule 6), `opt` rc=0 and verify-clean, on BOTH partitions (the dead-terminal
// spine's instance pre-dates M-B — `lowering_uncompute_leak_irreducible_dead_spine.ll`).
//
// `blockCanRepeat` is a strict SUPERSET of `LoopInfo::getLoopFor != null` (every
// block of a natural loop is reachable from itself), so nothing that lowered
// before stops lowering: the only behaviour that changes is the irreducible
// case, which no `clang -O1` output in the tree contains (zero goldens moved).
// The `LoopInfo` call is kept in front purely as the O(1) answer for the common
// case.
class RepeatOracle {
public:
  explicit RepeatOracle(LoopInfo &LI) : LI(LI) {}
  bool operator()(BasicBlock *BB) {
    if (LI.getLoopFor(BB))
      return true;
    auto It = Cache.find(BB);
    if (It != Cache.end())
      return It->second;
    bool R = blockCanRepeat(BB);
    Cache[BB] = R;
    return R;
  }

private:
  LoopInfo &LI;
  DenseMap<BasicBlock *, bool> Cache;
};

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
//
// `ReversedGates` / `ReversedRails` are OUT-params, written ONLY when this group
// actually emits (bd 6uqc Inc 5a). The M-B interior partition runs after every
// dead-terminal group and must never touch a rail one of them already adjointed
// or freed: two owners for one rail double-uncompute the shared prefix (Rule 8 —
// a use-after-free plus a double free, and `opt -verify` sees neither).
//
// The two partitions are ALSO disjoint by construction, and the argument is worth
// recording because it is what makes the bookkeeping a backstop rather than the
// whole fence: a successful dead-terminal group is CLOSED, so every rail in it has
// all of its consumers inside it. An interior rail R (which by definition has a
// consumer outside any set that owns it) can therefore not be in such a group, and
// a BORROWED parent P of R cannot either — P's consumer is R's producer, which is
// outside, so the group would have been `NotClosed` and emitted nothing. The
// explicit sets are the load-bearing image of that argument, in the same spirit as
// `ControlOwnedRails` / `OutputRails` / `GraveyardRails`: do not rest on the
// coincidence.
void reverseTerminalGroup(Function &F, ArrayRef<CallInst *> Terminals,
                          TaintSet &taint, WidthDispatch &wd, DominatorTree &DT,
                          PostDominatorTree &PDT, LoopInfo &LI, bool IterLocal,
                          SmallPtrSetImpl<const CallInst *> &ReversedGates,
                          SmallPtrSetImpl<Value *> &ReversedRails) {
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
  //
  // THE PREDICATE IS `canRepeat`, NOT `LoopInfo` (bd 4p7j Rule-13 finding F1):
  // an IRREDUCIBLE cycle is not a natural loop, `getLoopFor` returns null for
  // its blocks, and a gate inside one was reversed ONCE for K executions —
  // measured on `main`, `opt` rc=0 and verify-clean, freeing a rail holding
  // `5h + 7(K-1)` (`lowering_uncompute_leak_irreducible_dead_spine.ll`). The
  // new test is a strict superset of the old one, so the natural-loop
  // behaviour — including the 7.3 exception below, whose blocks are in a
  // natural loop either way — is unchanged.
  RepeatOracle canRepeat(LI);
  bool InLoop = false;
  for (CallInst *G : D.Calls)
    if (canRepeat(G->getParent())) {
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
  for (CallInst *G : D.Calls) {
    ReversedGates.insert(G);
    if (Value *R = railOf(G))
      ReversedRails.insert(R);
  }
  for (Value *R : D.Rails)
    ReversedRails.insert(R);
}

// ── M-B INTERIOR PARTITION (bd test_C_libtooling-6uqc Inc 5a) ────────────────

// Does `M` — a user of the BORROWED parent `P` — leave P's BASIS LABEL alone?
//
// FAILS CLOSED, and that is the whole design: exactly two shapes are PROVEN
// read-only and everything else counts as a mutation, a `cqrt_measure_*`
// included. Clause (d) of the record invariant (bd memory
// [record-freeze-invariant-2026-08-10]) requires every register an adjoint reads
// to hold the value it held WHEN THE FORWARD GATE RAN; the interior partition
// cannot deliver that by reverse program order the way the whole-DAG spine does,
// because a borrowed parent is by construction NOT walked and NOT adjointed. So
// it must be proven un-mutated over the interval instead.
bool preservesBorrowedParent(const CallInst *M, const Value *P) {
  const Function *Callee = M->getCalledFunction();
  StringRef N = Callee ? Callee->getName() : StringRef();
  // (1) A DIAGONAL rotation. `cqrt_rz_<W>(P, θ)` writes a phase and never a basis
  //     label, so the `_unc`'s recomputation of f(P) is unaffected and the phase
  //     commutes past the XOR it applies. (This is the same reason the flag-strip
  //     is `Rz`-transparent — bd memory [rz-diag-flag-strip-invariant].) The
  //     `_controlled` twin is excluded: it is a Phase-4 gate on a rail Phase 4
  //     owns, and its own arg-0 is a flag, not the rotated handle.
  if (N.starts_with("cqrt_rz_") && !N.contains("_controlled") &&
      M->arg_size() == 2 && M->getArgOperand(0) == P)
    return true;
  // (2) A FORWARD reassigning producer. `cq_template_*` / `cqrt_qram_load_<W>`
  //     READ every operand and mint a FRESH result rail; there is no mutating
  //     slot. This is the shape every recovered gate of the interior DAG has, so
  //     the group's own forward gates are admitted here without a special case.
  if (isTemplateProducer(M))
    return true;
  // Everything else is a mutation for this purpose: `cqrt_ry_` (the chained
  // theta), `cqrt_addc/xorc_` and `cqrt_qram_store_` (in-place relabelling),
  // `cqrt_x` / `cqrt_cswap` / `cqrt_cnot` / `cqrt_toffoli` (routes and targets),
  // a `cqrt_copy_*` destination, every `_unc`/`_inv` adjoint, a `cqrt_free`, and
  // `cqrt_measure_*` (a collapse — sound to read past in principle, refused here
  // because "in principle" is what this project's history says not to trust).
  //
  // "REFUSED HERE" IS NOT "REFUSED" (bd 4p7j Rule-13 finding F6). This function
  // only decides whether a user is PROVEN read-only, i.e. whether the caller may
  // skip the positional test; a user it refuses still gets the two-disjunct
  // interval scan. A `cqrt_measure_*` of the parent AFTER `At` is admitted by
  // the RIGHT disjunct, and soundly: the adjoints are inserted before `At`, and
  // `provablyBefore(At, M)` says every path to the collapse runs through `At`
  // and never returns, so the whole reversal has already executed when the
  // measurement happens. Nothing reads a register across a collapse. Pinned by
  // lowering_uncompute_interior_qram_parent_measured_after.ll (a 7.5 QROM load
  // rail as the borrowed parent), which is also the only fixture exercising
  // RIGHT over a user that is neither a rotation nor a route.
  return false;
}

// CLAUSE (d2) — THE EMITTER-RECORDED RESTORING ROUTE (bd test_C_libtooling-160a,
// M-B Increment 6). `M` is a `cqrt_cswap` user of the borrowed parent `P` that
// neither straight-line disjunct could place. Is it a member of a recorded route
// group on `P` EVERY member of which lies strictly inside the interval
// `(First, At)`?
//
// WHAT AN `_unc` ACTUALLY NEEDS, and saying it precisely is the whole argument.
// The adjoint of `X = f(P, …)` is `f_unc(X, P, …)`: it RECOMPUTES `f` from `P`'s
// COMPUTATIONAL-BASIS LABEL and XORs the result onto `X`. It is a LABEL-ONLY
// READER. It does not read, and cannot be disturbed by, any phase `P` has
// picked up in the meantime — a diagonal factor commutes with a label-controlled
// permutation and cancels against the record. So clause (d) — "every register an
// adjoint reads holds the value it held when the forward gate ran" — is a
// statement about the LABEL, and nothing weaker or stronger.
//
// WHY THE PHASE-ARM ROUTE RESTORES THE LABEL. `SwapRouteEmit`'s phase path emits,
// per content arm, one `cqrt_cswap(flag, P, rail)` to route in and the SAME call
// again to route back (RSSA: the join is the literal adjoint of the split). If
// the flag is set `P` and the rail exchange and exchange back; if it is clear
// neither call moves anything. In the if/else shape the second arm's pair is
// bracketed by `cqrt_x(flag)` so it fires on the complement, and at most one of
// the two pairs is ever active, so they commute. Either way `P` leaves the group
// holding the label it entered with.
//
// WHAT SITS BETWEEN THE HALVES, LISTED FROM THE EMITTER'S ACTUAL STREAM RATHER
// THAN FROM A SLOGAN. Three kinds of gate, and none of them changes `P`'s label:
//   * `cqrt_rz_<W>(rail, θ)` — the arm body. DIAGONAL, and on the WORK RAIL, not
//     on `P`.
//   * `cqrt_x(flag)` brackets — NON-diagonal, but on the FLAG rail. They exist so
//     the second cswap sees the same flag value the first one did, and the
//     emitter always opens and closes them in the same step (`emitRoute`), so the
//     flag is back to its own value before the next member of the group runs.
//   * gates on entirely unrelated rails, which are irrelevant regardless of
//     diagonality.
// The route pair deliberately does NOT restore `P`'s PHASE — the arm's `Rz` is
// the answer the region computed, carried on `P` through the exchange — and by
// the label-only-reader argument above that is exactly what makes the discharge
// legal rather than what would break it.
//
// THE GROUP IS TRUSTED AS A UNIT, AND IS NEVER RE-INFERRED HERE. Pairing,
// bracket closure and "the join is the adjoint of the split" are the EMITTER's
// invariants; scanning the IR for two cswaps and calling them a pair would be a
// second, weaker spelling of a property that already has an owner (Rule 14), and
// it would silently claim the value arm's route — whose route-back swaps in the
// arm's ANSWER, so `P`'s label genuinely changes — which is why that emitter
// records nothing.
//
// ATOMICITY IS THE FENCE. Half a pair inside the interval is NOT restoring: `P`
// then holds |0> or |x> depending on the flag, and the `_unc` would recompute
// `f(0)` on one branch — a verify-clean wrong answer. So EVERY member must be
// inside; a mixed group falls through and the component leaks. A group entirely
// LEFT, entirely RIGHT, or straddling the interval (route-in left, route-back
// right — `P`'s label is then constant ACROSS the interval, for the opposite
// reason) is already admitted per gate by the two straight-line disjuncts and
// never reaches this function.
//
// EVERY OTHER USER OF `P` IS STILL PROVEN SEPARATELY. This function exempts the
// ROUTE and nothing else, so an `cqrt_addc(P, 5)` or a `cqrt_ry(P, θ)` sitting
// between the two halves still has to clear LEFT or RIGHT on its own — and
// cannot — and the component leaks. "Nothing else writes `P` between the halves"
// is therefore enforced by the caller's scan, not assumed here.
bool routeGroupFullyInside(const CallInst *M, const Value *P, CallInst *First,
                           Instruction *At, DominatorTree &DT,
                           const TaintSet &taint, bool Alternates) {
  // The routed base is `cqrt_cswap(flag, base, rail)`'s ARG 1, read HERE and
  // never stored at emission time — see the `RestoringRoutes` comment in
  // TaintPropagation.h: arg 1 is a USE and follows `lowerRotations`' RAUW of the
  // `@cq_theta` result to its `cqrt_alloc` handle, whereas a captured `Value *`
  // would be both stale and DANGLING by the time `uncompute` asks (measured —
  // the first draft stored it and every group silently failed to match, which
  // reads exactly like a missing recording).
  //
  // ARG 1 IS A CONVENTION, NOT AN ABI FACT (bd 160a Rule-13 finding F6):
  // `cqrt_cswap(flag, a, b)` is physically symmetric in `a`/`b`. The read is safe
  // because the convention has exactly ONE owner — `SwapRouteEmit::emitRegion`,
  // the sole writer of `RestoringRoutes`, which always builds `{Flag, Q, Rail}`
  // and ASSERTS it at the record site. An emitter that records a group with the
  // base in arg 2 must update both places.
  auto baseOf = [](const CallInst *G) -> const Value * {
    return G->arg_size() >= 2 ? G->getArgOperand(1) : nullptr;
  };
  for (const auto &Gates : taint.RestoringRoutes) {
    if (!llvm::is_contained(Gates, M))
      continue;
    for (const CallInst *G : Gates) {
      // HOMOGENEITY: every member must route the SAME base this scan is
      // reasoning about. A group whose members disagree is not a statement about
      // `P` at all, and treating it as one would exempt a swap that moved some
      // other register into or out of `P`'s rail.
      if (baseOf(G) != P)
        return false;
      auto *GI = const_cast<CallInst *>(G);
      // bd 8h7d.5 — PER ACTIVATION, and THE TWO LEGS TAKE DIFFERENT BARRIERS.
      // Both ask "is `GI` inside THIS activation's interval [`First`, `At`]?",
      // and each leg's barrier is the OTHER endpoint — the instruction whose
      // execution ends the activation the leg is reasoning about (WireWalk.h:
      // the barrier must be what RE-ESTABLISHES the premise, never the premise's
      // own subject):
      //   * leg 1, "`First` ran before `GI`": the residual worry is a `GI`
      //     instance that reaches `First` again around the back edge. Every such
      //     path leaves the body through the discharge point `At` first, so `At`
      //     is the barrier that says "that `First` opens the NEXT interval".
      //   * leg 2, "`GI` ran before `At`": symmetrically, every path from `At`
      //     back to `GI` re-enters the body through `First`.
      // Leg 1 PASSED `First` (== the subject `A`) until the Rule-13 round-1
      // review of 2026-08-30 (finding P1). That is the vacuous configuration
      // `provablyBeforePerActivation` now refuses outright: `reachesWithout
      // Barrier` cut at the instruction it was trying to reach, so the call
      // collapsed to `DT.dominates(First, GI)` and the "GI never runs again
      // after First" half of the old acyclic `provablyBefore(First, GI)` was
      // deleted with no diagnostic. Not exploitable at the time — every
      // recorded route group lives in one straight-line flattened body, where
      // leg 1's plain reachability half already succeeds — but it is a
      // load-bearing proof and it was not proving anything.
      //
      // AND LEG 1 IS THE `At`-BARRIERED ONE, so it carries the ALTERNATION
      // premise `intervalAlternates` proves (Rule-13 round 4, F-4): its
      // contradiction is a second `At` inside the window, not a second `First`.
      // Leg 2's barrier IS `First` and needs no such premise. Unproven
      // alternation ⇒ leg 1 is refused and the group falls through to the
      // caller's leak (Prime Directive direction), which is what the old
      // straight-line-only reading effectively did.
      if (!Alternates || !provablyBeforePerActivation(First, GI, At, DT) ||
          !provablyBeforePerActivation(GI, At, First, DT))
        return false;
    }
    return true;
  }
  return false;
}

// PLAN one interior COMPONENT: the positional half (§2), the borrowed-parent
// frontier (§3), the DAG recovery and its re-proofs (§4) and clause (d) (§5).
// PURE ANALYSIS — it emits nothing. `true` fills `D`/`At` with a plan the caller
// may emit; `false` means this component LEAKS (Rule 6's fallback), and every
// `return false` below is one such unprovable step.
//
// SPLIT OUT OF `reverseInteriorGroup` when the driver went per-component (bd
// test_C_libtooling-if1e): a leak must abandon ONE component, not the function,
// and expressing that as an early `return` from a helper is the only spelling
// that stays correct inside the nested scans below (a `continue` in the
// borrowed-parent loop would abandon the PARENT, not the group — a silent
// over-accept).
bool planInteriorComponent(SmallVectorImpl<CallInst *> &Comp, TaintSet &taint,
                           DominatorTree &DT, PostDominatorTree &PDT,
                           RepeatOracle &canRepeat,
                           const SmallPtrSetImpl<const CallInst *> &ReversedGates,
                           const SmallPtrSetImpl<Value *> &ReversedRails,
                           DataDag &D, Instruction *&At) {
  SmallPtrSet<Value *, 16> Owned(Comp.begin(), Comp.end());
  bool Converged = false;
  for (unsigned Round = 0; Round < 8 && !Owned.empty(); ++Round) {
    SmallVector<Instruction *, 16> Anchors;
    for (CallInst *R : Comp) {
      if (!Owned.count(R))
        continue;
      for (User *U : R->users())
        Anchors.push_back(cast<Instruction>(U)->getNextNode());
    }
    if (Anchors.empty())
      return false;
    At = dagInsertPoint(Anchors, PDT);
    if (!At)
      return false;  // the consumers do not reconverge — leak.
    bool Dropped = false;
    for (CallInst *R : Comp) {
      if (!Owned.count(R))
        continue;
      for (User *U : R->users())
        // bd 8h7d.5 — PER ACTIVATION, with the rail's own MINT (`R`) as the
        // barrier. `R` is a `cqrt_alloc`/template call: re-executing it hands
        // back a FRESH handle, so a consumer that reaches `At` only around a
        // back edge is reading the NEXT iteration's rail and says nothing about
        // this one's discharge. Outside a loop the barrier walk is never
        // consulted (the plain reachability half already succeeds), so this is
        // byte-inert for every acyclic module.
        if (!provablyBeforePerActivation(cast<Instruction>(U), At, R, DT)) {
          Owned.erase(R);  // reachable by construction — the anchor scan above
                           // returns outright on an unreachable or non-instruction
                           // user, so this `cast` cannot be the vacuous case.
          Dropped = true;
          break;
        }
    }
    if (!Dropped) {
      Converged = true;
      break;
    }
  }
  if (!Converged || Owned.empty() || !At)
    return false;

  // 3. THE BORROWED-PARENT FRONTIER. Every tainted operand of an owned rail's
  //    producer (and of its in-place gates) that is not itself owned. These are
  //    READ-ONLY: never walked, never adjointed, never freed. The canonical
  //    member is the `cqrt_alloc`-minted source wire, whose `cqrt_ry` MINTED the
  //    superposition — no adjoint returns it to |0⟩ once a downstream record
  //    exists, which is exactly the situation every interior rail is in.
  SmallPtrSet<Value *, 8> Borrowed;
  auto borrow = [&](const CallInst *G, Value *Self) {
    for (Value *Op : G->args())
      if (Op != Self && taint.Tainted.count(Op) && !Owned.count(Op))
        Borrowed.insert(Op);
  };
  for (CallInst *R : Comp) {
    if (!Owned.count(R))
      continue;
    borrow(R, R);
    for (User *U : R->users())
      if (auto *G = dyn_cast<CallInst>(U))
        if (isInPlaceGateOn(G, R))
          borrow(G, R);
  }
  for (Value *B : Borrowed)
    if (ReversedRails.count(B))
      return false;  // an earlier group already reversed/freed it — leak.

  // 4. Recover the interior DAG under that frontier and re-prove everything the
  //    dead-terminal driver proves, silently.
  InteriorPlan IP;
  IP.Owned = Owned;
  IP.Borrowed = Borrowed;
  SmallVector<Value *, 16> Terms;
  for (CallInst *R : Comp)
    if (Owned.count(R))
      Terms.push_back(R);
  D = recoverDataDag(Terms, taint, DT, &IP);
  if (D.MeasuredUpstream || D.Escaped || D.NotClosed || D.Calls.empty())
    return false;
  if (!D.Roots.empty())
    return false;  // the frontier should have stopped every root — leak if it did not.
  for (CallInst *G : D.Calls) {
    if (ReversedGates.count(G))
      return false;  // single ownership backstop.
    if (!isInverseEmittable(G))
      return false;
    // THE 261j INVARIANT, APPLIED UNIVERSALLY RATHER THAN BY SEED — and this is
    // the load-bearing soundness fence of the whole increment. An interior rail
    // is one whose forward consumer stays LIVE and outside the reversal; that
    // consumer's own rail is a record of this one, taken by a carrier the
    // reversal never touches. That is precisely `recordsIntoKeptCarrier`'s
    // situation, so the same algebra applies: freeing the rail is Rule-6-legal
    // only if its whole forward chain is a BASIS PERMUTATION of live conditions
    // (bd 261j(a), owner ruling 2026-08-10). `cq_template_*` producers, `Rz`,
    // `addc`/`xorc` pass; `cqrt_ry_<W>` does not, which is exactly why an
    // alloc-minted source wire is borrowed and never owned. Seeding the freeze
    // instead would reach the same verdict on today's shapes and would rest on
    // `recordsIntoKeptCarrier` naming a surface (`tape`/`copy`) that has nothing
    // to do with why THIS rail is recorded.
    if (!preservesBasisUnderRecord(G))
      return false;
    // The GROUP-LEVEL at-most-once backstop over every recovered gate — the
    // third statement of the property, after the candidate MINT block (§1) and
    // the per-rail in-place-gate scan (§2). `canRepeat`, not `LoopInfo`: bd 4p7j
    // Rule-13 finding F1 (irreducible cycles are not natural loops). Kept even
    // though §1/§2 cover every gate the walk can reach today, so a future
    // widening of `recoverDataDag` degrades to a leak instead of a dirty free.
    // bd 8h7d.5 carries the ITERATION-LOCAL exception here too, and it is the
    // THIRD site to state it: a recovered gate inside a marked body runs once
    // per trip and its adjoint is emitted in-body once per trip. An irreducible
    // cycle is never marked (the marker is `LoopInfo`-gated), so `canRepeat`'s
    // superset behaviour over `LoopInfo` is preserved for exactly the case bd
    // 4p7j measured.
    if (canRepeat(G->getParent()) &&
        !taint.IterationLocalBlocks.count(G->getParent()))
      return false;
    // THE MULTIPLICITY THIS CHECK DOES *NOT* CATCH, AND WHY IT IS CURRENTLY
    // UNREACHABLE — a STRUCTURAL COINCIDENCE, not an invariant anyone stated
    // (bd 8h7d.5, Rule-13 round-5 cleanup; tracked as its own issue). The test
    // above and §2.9's twin below each ask ONE endpoint whether IT repeats. They
    // do not ask whether the two endpoints repeat the SAME NUMBER OF TIMES. A
    // recovered gate `G` in the loop PREHEADER passes here (a preheader does not
    // repeat) while `At` sits in an ITERATION-LOCAL body and passes §2.9 (a
    // marked body is the affirmative exception) — and the adjoint would then be
    // emitted in-body and run K times against ONE forward execution of `G`: an
    // over-reversed rail, i.e. a wrong unitary, not merely a leak.
    //
    // Nothing here refuses that pairing. It cannot arise today for a reason that
    // lives in ANOTHER FILE: `markIfRailLocal` (`LoopLowering.cpp`) refuses to
    // mark any body that reads a tainted value DEFINED OUTSIDE `L` and not on the
    // rail — "an accumulating loop-invariant tainted input" — so a preheader-
    // defined `G` feeding an in-body component means the body is never marked,
    // `At`'s block is not iteration-local, and §2.9 leaks instead. WIDEN THAT
    // MARKING AND THIS BECOMES REACHABLE with no test to catch it. If you are
    // here because you relaxed it, the obligation is a real multiplicity test
    // (same enclosing marked body, or equal trip multiplicity), not a re-reading
    // of these two.
    if (!DT.dominates(G, At))
      return false;  // a gate on one arm of a diamond — Phase 4's job, not this one.
    // ...AND `At` MUST POST-DOMINATE THE GATE. Dominance alone says the gate ran
    // before the discharge on every path that REACHES the discharge; it says
    // nothing about the paths that do not. `dagInsertPoint` post-dominates the
    // ANCHORS (the consumers), which is a weaker set than the GATES: a rail
    // minted in `entry` whose only consumer sits inside a classical `if` arm
    // yields an `At` inside that arm, and the reversal then runs on one path
    // while the mint ran on both. Nothing is freed dirty there — the other path
    // simply leaks — but "the rail is dead on EVERY path at the discharge" is
    // the property the post-dominator discipline exists to deliver, and a
    // one-armed reversal does not have it. Leak instead.
    if (!PDT.dominates(At->getParent(), G->getParent()))
      return false;
    if (!Owned.count(railOf(G)))
      return false;  // no gate may be adjointed whose rail this group does not own.
  }
  // (§2.9) AT-MOST-ONCE on the FINAL point, `blockCanRepeat` rather than
  // `LoopInfo` (an irreducible cycle is not a natural loop but still repeats).
  // bd 8h7d.5: an ITERATION-LOCAL body is the affirmative exception — the
  // discharge lands in-body and runs once per trip against a once-per-trip
  // forward stream. An IRREDUCIBLE cycle can never be marked (the marker is
  // `LoopInfo`-gated), so it still falls through to the leak.
  if (blockCanRepeat(At->getParent()) &&
      !taint.IterationLocalBlocks.count(At->getParent()))
    return false;

  // 5. CLAUSE (d) — the straight-line no-mutation scan (d1). Every borrowed
  //    parent must hold, at each emitted `_unc`, the value it held when the
  //    forward gate that reads it ran. The whole-DAG spine gets that free from
  //    reverse program order because it adjoints EVERY gate it walked; a borrowed
  //    parent is deliberately not walked, so the property is proven instead.
  //
  //    A mutation `M` of `P` is harmless iff it is provably OUTSIDE the interval
  //    [first recovered gate reading P, At], and there are exactly two ways out:
  //
  //      LEFT   `provablyBefore(M, First)` — M ran before the interval opened,
  //             and by the reachability half it can never run again inside it, so
  //             P's value at `First` already includes M's effect and holds until
  //             `At`. This is what admits the SOURCE Ry that mints the wire.
  //
  //             READ THIS BULLET WITH THE ROLLED LOOP IN MIND; it described only
  //             the acyclic shape for two rounds and that omission WAS the bug
  //             (Rule-13 round 4, F-4). In a loop "before the interval opened"
  //             is a PER-ACTIVATION statement, and the mutation it must excuse is
  //             the *next* iteration's LEADING gate — a `cqrt_ry` / `addc` /
  //             `xorc` that sits textually BEFORE `First` in the body, so a
  //             forward walk from `First` reaches it around the back edge without
  //             re-entering `First`. It is outside the window all the same,
  //             because every such path leaves through the discharge `At` first.
  //             That is LEFT-b at the scan below; the barrier is `At`, and the
  //             reason a `First` barrier cannot see it is the whole finding.
  //             Symptom when it is missed: `for(…){ q=cq_theta(q,a);
  //             if((q&3)==1){q=cq_phi(q,PI);} q=cq_theta(q,b); }` leaves the
  //             `and` record allocated and ENTANGLED across the trailing Ry —
  //             `opt` exit 0, strict stage-2b clean, and (with no leading Rz to
  //             trip the M-A guard) not one warning. The hand-unrolled twin of
  //             the same source discharges it, which is the witness this
  //             increment is built on.
  //
  //      RIGHT  `provablyBefore(At, M)` — M runs only after `At`. Every path to
  //             M goes through `At`, and `At` is not reachable from M, so M
  //             cannot execute before the adjoints, which are inserted BEFORE
  //             `At` and therefore strictly earlier still. This is Inc 5b, and
  //             it is what makes bd 6uqc's P4 lower: the chained `cq_theta` on
  //             the source wire is a mutation of a borrowed parent that happens
  //             entirely after the discharge, so the `_unc`s read the PRE-Ry
  //             basis — which is exactly the basis the forward gates read.
  //
  //    READ THE LEFT DISJUNCT WITH THIS FACT IN HAND, or the next reader will
  //    "fix" a correct accept into a leak (bd 4p7j Rule-13 finding F6):
  //    `clang -O1` ROUTINELY SINKS a derived chain PAST a swap-route region.
  //    Source order `x = sqrt(a+3.0); if (a > 2) { … }` arrives with the whole
  //    `x` chain AFTER the region (measured: `a9b_after_region.c`), so `First`
  //    is after the emitter's route-back and the region's `cqrt_cswap` pair is
  //    to its LEFT — the discharge then reads the wire AFTER route-back and is
  //    admitted by LEFT, not by RIGHT. That is sound because the route pair is
  //    self-cancelling: the second `cswap` restores the basis label the first
  //    exchanged, so a read after the pair sees the pre-region label. What is
  //    NOT admitted is a route STRICTLY INSIDE the interval — that satisfies
  //    neither disjunct and leaks
  //    (lowering_uncompute_interior_leak_route_in_interval.ll). The interval,
  //    not the source line, is what this scan reasons about.
  //
  //    THE TWO DISJUNCTS ARE NOT SYMMETRIC IN WHAT THEY PROTECT, and the
  //    difference is the owner's clause-(d) ruling of 2026-08-27: "a discharge
  //    scheduled AFTER a non-diagonal wire gate is itself unsound (the `_unc`
  //    would read a post-Ry basis) — the spine must never place one there." The
  //    RIGHT disjunct does not schedule the discharge after the Ry; it proves the
  //    Ry is after the discharge. A mutation strictly INSIDE the interval
  //    satisfies neither and leaks
  //    (lowering_uncompute_interior_leak_parent_ry_between.ll).
  //
  //    AND THAT ORDER IS WHAT THE M-A GUARD THEN READS. `recordIsExemptAt`'s
  //    clause 2 exempts a record whose own discharge is `provablyBefore` the
  //    gate; the `_unc`(out=R, …) and `cqrt_free(R)` emitted here are exactly the
  //    shape `isDischargeOf` matches, and they now land before the chained Ry —
  //    so P4 goes from a loud decline to an accept WITHOUT relaxing one clause of
  //    the guard. The division of labour holds: M-B moved the physics, M-A only
  //    re-read it.
  for (Value *P : Borrowed) {
    CallInst *First = nullptr;
    for (CallInst *G : D.Calls) {  // forward program order (recoverDataDag §2)
      bool Reads = false;
      for (Value *Op : G->args())
        if (Op == P)
          Reads = true;
      if (Reads) {
        First = G;
        break;
      }
    }
    if (!First)
      continue;  // borrowed but never read by an adjoint — nothing to prove.
    // `First != At`, AND IT IS §4 THAT PROVES IT — stated here because the leg
    // that used to be justified by the opposite claim was deleted in this commit
    // (bd 8h7d.5, Rule-13 round-5 cleanup). `First` is drawn from `D.Calls`, and
    // §4 above ran `if (!DT.dominates(G, At)) return false;` over EVERY
    // `G ∈ D.Calls`; LLVM's `dominates(I, I)` is FALSE by definition ("an
    // instruction doesn't dominate a use in itself"), so a `First` equal to `At`
    // was already rejected before this scan began. Measured, not only argued:
    // instrumenting `First == At` over all 1293 fixtures gives 0 hits. The
    // Release-mode `return false` is the conservative branch (leak, Rule 6) for
    // the impossible case, so a future §4 widening degrades to a leak rather
    // than to a vacuous certificate.
    assert(First != At && "§4 dominance already rejects First == At");
    if (First == At)
      return false;
    // Proven ONCE per (`First`, `At`) pair and read by `routeGroupFullyInside`'s
    // `At`-barriered leg 1 below — see `WireWalk.h`'s `intervalAlternates` for
    // the window argument, and for why the `First`-barriered legs (that leg's
    // sibling, and (W2) here) do not need it. The dominance half it assumes
    // (`First` dominates `At`) is proven for every recovered gate in §4 above,
    // `First` included.
    //
    // RULE-12 GAP, RECORDED RATHER THAN PAPERED OVER (bd 8h7d.5 round-5
    // cleanup). Mutating this call to a constant `true` leaves all 1293 fixtures
    // GREEN. That is not evidence the premise is dead — it is evidence the suite
    // exercises it only in its CONSERVATIVE direction (every shape that reaches
    // `routeGroupFullyInside`'s leg 1 today already alternates, so forcing the
    // premise true changes no verdict), and there is no discriminating fixture: a
    // recorded route group inside a CFG cycle through `At` that misses `First`.
    // Do NOT read the green suite as licence to drop the premise; the F-4 round
    // showed the loop shapes that break it exist. A fixture that goes RED under
    // the constant-`true` mutant is owed.
    const bool Alternates = intervalAlternates(First, At);
    for (User *U : P->users()) {
      auto *M = dyn_cast<CallInst>(U);
      if (!M)
        return false;  // a φ/select ROUTES the same physical rail (bd tayx), a `store`
                 // escapes it, and none of them is a gate whose position this
                 // scan can reason about — leak rather than guess.
      if (!DT.isReachableFromEntry(M->getParent()))
        continue;  // a mutation that can never execute cannot move P. Vacuous
                   // truth is the SAFE direction here — unlike in the anchor
                   // scan, where it would have hidden a missing proof — but it is
                   // made explicit so the two uses of reachability are not read
                   // as one rule.
      if (preservesBorrowedParent(M, P))
        continue;
      // ── THE WINDOW LEMMA (bd 8h7d.5, Rule-13 ROUND 4, finding F-4) ────────
      //
      // Fix one execution of the discharge at trace time `T_At`, and let
      // `T_First` be the LAST execution of `First` before it (it exists: §4
      // proved `First` dominates `At`). Everything this scan owes clause (d1) is
      //
      //     (†)  NO execution of `M` lies strictly inside `W = (T_First, T_At)`.
      //
      // `M` before `T_First` is harmless — `P`'s value at `T_First` already
      // includes it and the `_unc`s read the same one. `M` after `T_At` is
      // harmless — the adjoints are inserted BEFORE `At`, so they have already
      // run. Only the inside is a wrong unitary.
      //
      // THE CERTIFICATE IS A SINGLE BARRIER WALK, AND IT NEEDS NO DOMINANCE
      // PREMISE:
      //
      //   (W2) every path `M`⇝`At` re-executes `First`.  Assume `t_M ∈ W`; the
      //        trace from `t_M` to `T_At` is such a path, so a `First` runs in
      //        `(t_M, T_At) ⊂ W` — contradicting the MAXIMALITY of `T_First`. ∎
      //        (This is Inc 5b's RIGHT leg, "M runs only after the discharge",
      //        with the premise it never used removed.)
      //
      // TWO OTHER CERTIFICATES ARE SOUND AND BOTH ARE REDUNDANT — a theorem, not
      // an omission, and the reason this scan ships ONE walk instead of three:
      //
      //   (W1) "every path `First`⇝`M` re-executes `First`" (an `M ∈ W` puts a
      //        `First` in `W`). IMPLIES (W2): suppose some path `P: M ⇝ At`
      //        avoids `First`. `First` dominates `At`, so every entry⇝`At` walk
      //        executes `First` (a walk avoiding it would contain a simple path
      //        avoiding it); prefixing `P` with any entry⇝`M` path gives such a
      //        walk, and `P` has no `First`, so every entry⇝`M` path does. Take
      //        the LAST `First` on one before `M`: that `First`⇝`M` segment
      //        re-executes no `First`, contradicting (W1). ∎
      //
      //   (W3) "every path `First`⇝`M` passes through `At`, read under
      //        `intervalAlternates`" — the shape the round-4 reviewer measured as
      //        the fix (an `M ∈ W` puts a second `At` in `W`, and two `At`s with
      //        no `First` between them contradict alternation). ALSO IMPLIES
      //        (W2): with the same `P`, the same argument gives a `First`⇝`M`
      //        path with no intermediate `First`; by (W3) it carries an `At`, so
      //        `At ⇝ M ⇝ At` is an `At`⇝`At` walk with no `First` on it,
      //        contradicting alternation. ∎
      //
      // Measured as well as proved: disabling (W1) and disabling (W3) each leave
      // all 1293 fixtures green, and the 234-program probe sweep unmoved.
      //
      // NEITHER (W1) NOR (W3) IS SHIPPED. (W2) is the sole certificate, and the
      // deletion of (W1) is itself a round-5 finding rather than a tidy-up
      // (bd 8h7d.5). (W1) shipped for one stated reason: `everyPathReExecutes`
      // tests barrier membership BEFORE the endpoint, so with `Barrier == To` it
      // cuts at the very instruction it is trying to reach and hands back a
      // certificate that proves nothing (the P1 vacuity trap of round 1), and
      // (W2) was said to be the leg where that happens — at `First == At`, where
      // (W1)'s own barrier is its start and its proof never mentions `At`.
      //
      // THAT JUSTIFICATION WAS FALSE, because `First == At` CANNOT HAPPEN: §4
      // proves it (see the assert above), and it was measured at 0 hits over all
      // 1293 fixtures. So (W1) was guarding a degeneracy that never arrives,
      // while the one configuration in which it could still fire on its own
      // (`M == First`, also measured at 0 hits) makes its certificate VACUOUS in
      // exactly the P1 way it was supposed to avoid — `everyPathReExecutes(First,
      // First, First)` is `Barrier == From == To`. A disjunct that can only
      // return a vacuous `true` is not a weaker proof, it is a hole waiting for a
      // widening to reach it. Removing a DISJUNCT can only ADD refusals (the safe
      // direction, Rule 6): confirmed by 1293/1293 lit green, the 234-program
      // sweep byte-identical, and the 120-cell rolled≡unrolled twin matrix
      // unchanged.
      //
      // WHAT THIS REPLACES. Rounds 1–3 asked both legs through
      // `provablyBeforePerActivation`, which is `DT.dominates(A,B) AND
      // (plain-unreachability OR the barrier walk)`. That helper answers a
      // DIFFERENT question — "did A run before B on this activation" — and its
      // dominance conjunct is load-bearing there. It is no step of the proof
      // above, and bundling it made the scan refuse two shapes it can prove:
      //   * the ROLLED LEADING GATE (F-4). `for(…){ q=cq_theta(q,a);
      //     if((q&3)==1){…} q=cq_theta(q,b); }` — the NEXT iteration's leading
      //     `cqrt_ry` sits BEFORE `First` in the body, so it does not dominate
      //     anything the old legs asked about, and the whole condition chain
      //     leaked, ENTANGLED, across the trailing Ry: `opt` exit 0, strict
      //     stage-2b clean, and — with no leading Rz to trip the M-A guard — not
      //     one warning. Measured over a 100-cell prefix × region × suffix
      //     matrix: 11 rolled cells whose traces differed from their
      //     hand-unrolled twins', 5 of them silent
      //     (lowering_inloop_derived_cond_leading_gate.ll,
      //     tools/loop_twin_matrix.py).
      //   * `M == At`, which is REACHABLE (`At` is the `getNextNode()` of a
      //     consumer of an owned rail, and that can be a `cqrt_ry` on the parent).
      //     `DT.dominates(I, I)` is FALSE by definition in LLVM ("an instruction
      //     doesn't dominate a use in itself"), so the old RIGHT leg refused
      //     every one of them; (W2)'s walk cannot reach `At` from `At` in an
      //     acyclic region and admits it
      //     (lowering_live_record_dead_compare_flag_discharged.ll).
      // STRICTLY MORE PERMISSIVE, PROVABLY — AND STILL SO WITH (W1) DELETED,
      // which is why the deletion cannot leak a shape that used to discharge:
      //   * old RIGHT was `DT.dominates(At,M) AND (!isPotentiallyReachable(M,At)
      //     OR (W2))`. `!isPotentiallyReachable(M, At)` makes (W2)'s walk
      //     vacuously succeed, so old RIGHT ⊆ (W2).
      //   * old LEFT was `DT.dominates(M,First) AND (!isPotentiallyReachable
      //     (First,M) OR (W1))` — its barrier-walk half IS (W1) verbatim
      //     (`WireWalk.cpp`'s `provablyBeforePerActivation` says so). (W1) ⇒ (W2)
      //     by the theorem above. And `!isPotentiallyReachable(First, M)` ⇒ (W2)
      //     directly: §4 gives `First` dominates `At`, so every entry⇝`At` walk
      //     carries a `First`; none can lie in an entry⇝`M` prefix (that would be
      //     `First` reaching `M`), so every `M`⇝`At` suffix carries one. So old
      //     LEFT ⊆ (W2) too.
      // Nothing that discharged before can leak now.
      if (everyPathReExecutes(M, At, First))
        continue;  // (W2) — M runs only after the discharge (Inc 5b). The SOLE
                   // window certificate; the `First != At` conjunct that used to
                   // guard it is proven above, not tested here.
      if (routeGroupFullyInside(M, P, First, At, DT, taint, Alternates))
        continue;  // INSIDE — a COMPLETE emitter-recorded Phase-4 route, the
                   // identity on P's basis LABEL over the interval (Inc 6,
                   // clause (d2)).
      return false;  // unprovable ⇒ this component leaks (Rule 6).
    }
  }

  return true;
}

// Reverse the M-B INTERIOR group of `F`: the rails that are dead after their last
// forward use but are NOT dead terminals, so the whole-DAG spine never saw them.
//
// LEAK-FIRST, WITHOUT EXCEPTION. Every unprovable step below is a `return` — the
// rail is LEFT ALLOCATED (Rule 6's fallback), never freed dirty and never a loud
// decline. Loudness for a record still standing at a non-diagonal gate belongs to
// the LATE M-A guard (`warnLiveRecordRotations`), which runs after this and
// reads the discharges this function emits as FACTS (`isDischargeOf` matches the
// out-first `_unc` and the `cqrt_free`, both of which `emitDagReversal` mints in
// exactly that shape). That division of labour is the design, not an accident:
// two owners for one diagnostic is how a decline and an accept end up disagreeing
// about the same program.
//
// SPLIT INTO PLAN + EMIT (bd test_C_libtooling-x67f, Increment 7a). Everything
// down to the `Plans` vector is PURE ANALYSIS and is now `collectInteriorPlans`;
// `reverseInteriorGroup` is that call plus the emission loop, and
// `planInteriorDischarges` is that call with the dead-terminal superset
// subtracted. ONE spelling of the accept predicate, asked twice (Rule 14) — the
// M-C late round must never re-derive "will this rail discharge, and where".
struct ComponentPlan {
  DataDag D;
  Instruction *At;
};

void collectInteriorPlans(Function &F, TaintSet &taint, DominatorTree &DT,
                          PostDominatorTree &PDT, LoopInfo &LI,
                          const SmallPtrSetImpl<const CallInst *> &ReversedGates,
                          const SmallPtrSetImpl<Value *> &ReversedRails,
                          SmallVectorImpl<ComponentPlan> &Plans) {
  // 1. STRUCTURAL candidates (ChainWalk::isInteriorTerminalHandle), minus every
  //    rail another owner holds. The subtractions mirror terminal selection's,
  //    one for one, because an interior rail is selected by a DIFFERENT predicate
  //    and would otherwise slip past images that are load-bearing there.
  RepeatOracle canRepeat(LI);
  SmallVector<CallInst *, 16> Cand;  // program order — FileCheck-stable
  for (BasicBlock &BB : F) {
    // (§2.9) The acyclic backstop, applied PER CANDIDATE rather than per group: a
    // rail minted inside a loop is re-minted every iteration, so one reversal at
    // a function-scope point would adjoint a K-times gate once and reset a
    // re-allocated rail K−1 times too many. Inc 5 leaves every loop rail
    // allocated; the 7.3 iteration-local group is the only in-loop reversal and
    // it has its own affirmative proof.
    //
    // `canRepeat`, NOT `LoopInfo` (bd 4p7j Rule-13 finding F1): a rail minted
    // inside an IRREDUCIBLE cycle is re-minted per trip exactly as a loop rail
    // is, while `getLoopFor` returns null for it
    // (`lowering_uncompute_interior_leak_irreducible_mint.ll`).
    //
    // THE ONE EXCEPTION, and it is the SAME one the dead-terminal driver has
    // carried since Increment 2 (bd test_C_libtooling-8h7d.5 extends it here):
    // a block affirmatively proved ITERATION-LOCAL. There the rail IS re-minted
    // every trip and the reversal IS re-emitted every trip, one adjoint per
    // forward gate — the exact pairing the backstop is protecting, achieved by
    // placing the discharge in-body instead of at function scope. Everything
    // that follows re-verifies it per activation rather than trusting the mark:
    // the anchor scan, the convergence test, the final-`At` fence and clause (d)
    // each take a barrier-cut reading (`provablyBeforePerActivation`) whose
    // barrier is the very mint / interval-opening gate this exception assumes is
    // re-executed. Not marking is always safe (the rail leaks); the mark only
    // ever grants.
    if (canRepeat(&BB) && !taint.IterationLocalBlocks.count(&BB))
      continue;
    // REACHABILITY FIRST — the same trap the M-A guard's Rule-13 round hit (its
    // F3 finding). `provablyBefore` is `DT.dominates(A, B) &&
    // !isPotentiallyReachable(B, A)`, and BOTH halves are VACUOUSLY TRUE for an
    // instruction in a block with no entry path: LLVM's dominator tree treats an
    // unreachable block as dominated by everything, and nothing is reachable
    // from it. So without this test a rail in a dead block would pass the whole
    // positional proof for free, and — worse — its consumer's `getNextNode()`
    // would join the anchor set and could place the entire reversal inside a
    // block that never executes, silently dropping every adjoint and every free
    // the group was supposed to emit. Skip such blocks; the group's owned rails
    // are then all reachable, and the user scan below rejects any rail whose
    // consumer is not.
    if (!DT.isReachableFromEntry(&BB))
      continue;
    for (Instruction &I : BB) {
      auto *H = dyn_cast<CallInst>(&I);
      if (!H)
        continue;
      // BELT-AND-BRACES, MEASURED AS SUCH (bd 4p7j Rule-13 finding F4g). Every
      // rail in these four sets already fails `isInteriorTerminalHandle` on its
      // own: each of them has a user `isInteriorConsumer` refuses — a
      // `cqrt_cswap` route or a `_controlled` gate for a Phase-4 flag / work /
      // merge rail, a `cqrt_tape_write_*` for an output rail, a `cqrt_free` or
      // an `_unc` for a graveyard one. So the subtraction removes nothing today
      // and no fixture discriminates it.
      //
      // It is kept because the ALTERNATIVE failure is silent: these sets are the
      // shipped statement of "another owner holds this rail", the interior
      // predicate is a DIFFERENT predicate from terminal selection (which
      // subtracts them for real), and a future widening of `isInteriorConsumer`
      // — admitting `cqrt_x`, say, or a controlled copy — would hand this
      // partition a rail Phase 4 is still routing, with no diagnostic anywhere.
      // Two lines of subtraction against that is the right trade; do not
      // "simplify" them away on the grounds that they never fire.
      if (taint.ControlOwnedRails.count(H) || taint.OutputRails.count(H) ||
          taint.GraveyardRails.count(H) || taint.UntaintedMergeRails.count(H) ||
          railCarriesControlledRotation(H))
        continue;
      if (ReversedRails.count(H) || ReversedGates.count(H))
        continue;  // single ownership — see reverseTerminalGroup's note.
      if (!isInteriorTerminalHandle(H, taint))
        continue;
      Cand.push_back(H);
    }
  }
  if (Cand.empty())
    return;

  // 2. THE POSITIONAL HALF. The discharge point is the nearest common
  //    POST-dominator of the point right after every consumer of every owned
  //    rail — the same `dagInsertPoint` discipline the dead-terminal groups use,
  //    with the anchor set built from CONSUMERS instead of from `FreePoint`
  //    (there is no free point to compute: an interior rail is not a terminal, so
  //    `computeFreePoint` would classify it from an empty user scan).
  //
  //    Then every consumer must be PROVABLY BEFORE that point:
  //    `DT.dominates(U, At)` — if control reaches `At` the consumer has run — AND
  //    `!isPotentiallyReachable(At, U)` — it never runs again, which is what
  //    stops a back edge from re-reading a rail this reversal already zeroed.
  //    A candidate that fails is DROPPED, which can only move `At` earlier, which
  //    can only break more candidates — hence the bounded fixpoint. Failure to
  //    converge leaks the whole group (never a wrong placement).
  // PRE-FILTER, PER RAIL: a rail whose consumer cannot anchor is dropped here
  // rather than killing the group, so the discrimination stays per rail like
  // every other refusal in this partition. Three ways a consumer cannot anchor:
  //   * it is not an `Instruction` — (I3) already guarantees it is a `CallInst`,
  //     but the check is kept so a future widening of that predicate degrades to
  //     a leak instead of undefined behaviour in a release build;
  //   * its block is UNREACHABLE — `provablyBefore` is vacuously true there
  //     (the M-A guard's F3 trap, reached from the other side), and its
  //     `getNextNode()` could drag the nearest common post-dominator into a block
  //     that never executes, silently dropping the whole reversal;
  //   * it sits in terminator position, so there is no next node to anchor on.
  //
  // AND, PER RAIL, THE AT-MOST-ONCE PROPERTY OF EVERY IN-PLACE GATE ON IT (bd
  // 4p7j Rule-13 finding F1). The §1 skip above covers the rail's own MINT
  // block; an in-place `cqrt_addc`/`xorc`/`rz` on the rail is a WRITE that the
  // group will adjoint exactly once, so it must run exactly once too. Measured
  // hole: `mul -> %h_op` in `entry`, `cqrt_addc_i32(%h_op, 7)` inside an
  // IRREDUCIBLE cycle, one `cqrt_addc_i32(%h_op, -7)` at the exit, then
  // `cqrt_free(%h_op)` on a rail holding `5h + 7(K-1)` — `opt` rc=0,
  // verify-clean, a hidden measurement (Rule 6);
  // `lowering_uncompute_interior_leak_irreducible_gate.ll`.
  //
  // THE FENCE KEYS ON WRITES, NEVER ON READS, and that asymmetry is the whole
  // reason it lives here rather than beside the anchor test. A forward consumer
  // that merely READS the rail K times leaves it exactly as it found it, so the
  // once-only discharge after the cycle is still correct — that is the shipped
  // accept `lowering_uncompute_interior_loop_consumer_and_after.ll` (a producer
  // in a dominating block, a consumer inside a 3-trip loop, another after it).
  // Refusing repeated readers as well would leak that shape for no physics.
  //
  // A dropped candidate is not lost work: it becomes a BORROWED parent of any
  // group that reads it, whose clause-(d) scan then proves the interval is
  // mutation-free from the other side. Both irreducible fixtures keep their
  // compare rail's discharge for exactly that reason.
  SmallPtrSet<Value *, 16> Anchorable;
  for (CallInst *R : Cand) {
    bool Ok = true;
    for (User *U : R->users()) {
      auto *UI = dyn_cast<Instruction>(U);
      if (!UI || !DT.isReachableFromEntry(UI->getParent()) ||
          !UI->getNextNode()) {
        Ok = false;
        break;
      }
      auto *G = dyn_cast<CallInst>(UI);
      if (G && isInPlaceGateOn(G, R) && canRepeat(G->getParent()) &&
          !taint.IterationLocalBlocks.count(G->getParent())) {
        // bd 8h7d.5 — an in-place WRITE inside an iteration-local body runs
        // exactly once per trip and is adjointed exactly once per trip (the
        // reversal is emitted in-body), so the at-most-once obligation is met
        // per activation rather than per function. Outside such a body the
        // fence is unchanged: a K-times write with one adjoint is bd 4p7j's
        // measured hidden measurement.
        Ok = false;
        break;
      }
    }
    if (Ok)
      Anchorable.insert(R);
  }
  if (Anchorable.empty())
    return;

  // 1c. CONNECTED COMPONENTS (bd test_C_libtooling-if1e — the Rule-13 reviewer's
  //     recommendation from Increment 5, landed here because Increment 6's own
  //     customer needs it). Two owned rails are in the SAME component iff one is a
  //     producer operand of the other, i.e. iff a single recovered DAG can hold
  //     both. Everything below runs PER COMPONENT: its own `At`, its own borrowed
  //     frontier, its own clause-(d) interval.
  //
  //     NOT A REFINEMENT — A REQUIREMENT, and here is the measured shape. One `At`
  //     per function is the nearest common post-dominator of EVERY consumer of
  //     EVERY interior rail, so two unrelated chains drag each other's discharge
  //     to the LATER point, and the earlier chain then has the later chain's gates
  //     inside its borrowed parent's interval. A TWO-ITERATION Grover with a
  //     derived-condition oracle is exactly that: iteration 1's chain would anchor
  //     after iteration 2's flag strip, with iteration 1's S-dagger `cqrt_ry` on
  //     the shared wire strictly INSIDE the interval. Clause (d) refuses it — and
  //     must (the owner's 2026-08-27 ruling: an `_unc` scheduled after a
  //     non-diagonal wire gate reads a post-Ry basis) — so the WHOLE function
  //     leaked and the program declined at the M-A guard. Per component, each
  //     chain anchors at its own region's strip and both discharge.
  //
  //     NEVER FINER THAN A COMPONENT. Two rails joined by a producer edge share a
  //     DAG and may share a borrowed parent whose interval is the UNION of theirs;
  //     splitting them would let one be freed while the other's adjoint still
  //     reads it (Rule 8's shared prefix).
  //
  //     PLAN ALL, THEN EMIT ALL — the order is load-bearing. Emitting component A
  //     before PLANNING component B would put A's `_unc`s, which READ shared
  //     borrowed parents, INSIDE B's interval, where B's clause-(d) scan (which
  //     cannot tell an adjoint's reads from its writes) refuses them and leaks B
  //     for no physics. Planning is pure analysis, and every emission writes and
  //     frees only rails its own component owns, so all-then-all is sound.
  SmallVector<SmallVector<CallInst *, 8>, 4> Components;
  {
    DenseMap<Value *, unsigned> CompOf;  // rail -> component id
    auto merge = [&](unsigned A, unsigned B) {
      if (A == B)
        return;
      for (auto &KV : CompOf)
        if (KV.second == B)
          KV.second = A;
    };
    auto idOf = [&](Value *V) {
      auto It = CompOf.find(V);
      if (It != CompOf.end())
        return It->second;
      unsigned Fresh = CompOf.size();
      CompOf[V] = Fresh;
      return Fresh;
    };
    for (CallInst *R : Cand) {  // program order — FileCheck-stable
      if (!Anchorable.count(R))
        continue;
      auto link = [&](const CallInst *G) {
        for (Value *Op : G->args())
          if (Op != R && Anchorable.count(Op))
            merge(idOf(R), idOf(Op));
      };
      idOf(R);
      link(R);  // the rail's own producer operands
      for (User *U : R->users())
        if (auto *G = dyn_cast<CallInst>(U))
          if (isInPlaceGateOn(G, R))
            link(G);  // and every in-place gate's other tainted operands
    }
    DenseMap<unsigned, unsigned> Slot;  // component id -> slot in `Components`
    for (CallInst *R : Cand) {
      if (!Anchorable.count(R))
        continue;
      unsigned Id = CompOf[R];
      auto It = Slot.find(Id);
      if (It == Slot.end())
        It = Slot.insert({Id, Components.size()}).first, Components.emplace_back();
      Components[It->second].push_back(R);
    }
  }

  // Plan EVERY component before ANY of them emits — see the note above.
  for (SmallVector<CallInst *, 8> &Comp : Components) {
    ComponentPlan P;
    P.At = nullptr;
    if (planInteriorComponent(Comp, taint, DT, PDT, canRepeat, ReversedGates,
                              ReversedRails, P.D, P.At))
      Plans.push_back(std::move(P));
  }
}

void reverseInteriorGroup(Function &F, TaintSet &taint, WidthDispatch &wd,
                          DominatorTree &DT, PostDominatorTree &PDT, LoopInfo &LI,
                          const SmallPtrSetImpl<const CallInst *> &ReversedGates,
                          const SmallPtrSetImpl<Value *> &ReversedRails) {
  SmallVector<ComponentPlan, 4> Plans;
  collectInteriorPlans(F, taint, DT, PDT, LI, ReversedGates, ReversedRails,
                       Plans);
  for (ComponentPlan &P : Plans)
    emitDagReversal(P.D, P.At, wd, taint);
}

// Terminal-handle selection, hoisted out of `uncompute`'s driver loop so the
// plan-only entry point below asks the SAME question (Rule 14). Returns the
// candidates in program order; `AnyTaintedProducer` reports the driver's cheap
// early-out separately because it is weaker than "there is a terminal".
void collectTerminalCandidates(Function &F, const TaintSet &taint,
                               SmallVectorImpl<CallInst *> &Terminals,
                               bool &AnyTaintedProducer) {
  AnyTaintedProducer = false;
  for (BasicBlock &BB : F)
    for (Instruction &I : BB) {
      auto *H = dyn_cast<CallInst>(&I);
      if (!H || !taint.Tainted.count(H) || !isDataProducer(H))
        continue;
      AnyTaintedProducer = true;
      if (taint.ControlOwnedRails.count(H))
        continue;  // DD-4: Phase-4 owns this rail
      if (taint.OutputRails.count(H))
        continue;  // 7.6: kept I/O output rail — never a data terminal
                   // (PRD-7.6 §2.5). Defensive: a tape-write out_handle is not
                   // a data producer, so it never reaches here, but the
                   // explicit image is load-bearing, like ControlOwnedRails.
      if (railCarriesControlledRotation(H))
        continue;  // bd drbq Inc 1: a register a `cqrt_{ry,rz}_<W>_controlled`
                   // fired on. FROZEN — its adjoint needs a control flag the
                   // region already stripped and freed, so no point at or after
                   // this terminal can reverse it (Rule 6: leave it allocated).
                   // Asked STRUCTURALLY of the emitted gate (see
                   // `railCarriesControlledRotation`): the Inc-1 `Value *` set
                   // was keyed on a pre-`lowerOps` SSA value that `lowerOps`
                   // erases for every DERIVED base — a confirmed silent
                   // miscompile, round-1 review L3 §1 / L5 §1.
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
    bool AnyTaintedProducer = false;  // cheap gate: no tainted rail ⇒ no work
    collectTerminalCandidates(F, taint, Terminals, AnyTaintedProducer);
    // THE `Terminals.empty()` EARLY-OUT IS NOW KEYED ON `AnyTaintedProducer`
    // INSTEAD (bd 6uqc Inc 5a). The M-B interior partition below has its OWN
    // candidate predicate — an interior rail is by definition NOT a terminal —
    // so bailing on "no dead terminal" would have made the whole increment
    // unreachable in exactly the functions it exists for (P1's chain ends at a
    // measured `zext` rail; had that rail been returned instead, `Terminals`
    // would be empty and every interior rail invisible). The replacement gate is
    // strictly weaker and still costs a module with no tainted data nothing.
    if (!AnyTaintedProducer)
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

    // Every rail/gate a dead-terminal group actually reversed, so the M-B
    // interior partition below can prove single ownership (Rule 8).
    SmallPtrSet<const CallInst *, 16> ReversedGates;
    SmallPtrSet<Value *, 16> ReversedRails;

    reverseTerminalGroup(F, Regular, taint, wd, DT, PDT, LI, /*IterLocal=*/false,
                         ReversedGates, ReversedRails);
    for (Loop *L : IterLoops)
      reverseTerminalGroup(F, IterByLoop[L], taint, wd, DT, PDT, LI,
                           /*IterLocal=*/true, ReversedGates, ReversedRails);

    // M-B (bd 6uqc Inc 5): the INTERIOR rails — dead after their last forward
    // use, but never a terminal, so nothing above ever saw them. Runs LAST so it
    // sees the settled module (its clause-(d) scan reads the emitted traffic) and
    // so the dead-terminal groups keep first claim on every rail they can reach.
    reverseInteriorGroup(F, taint, wd, DT, PDT, LI, ReversedGates,
                         ReversedRails);
  }
}

InteriorDischargePlan planInteriorDischarges(Function &F, TaintSet &taint) {
  InteriorDischargePlan Plan;
  if (F.isDeclaration())
    return Plan;

  DominatorTree DT(F);
  PostDominatorTree PDT(F);
  LoopInfo LI(DT);

  // THE DEAD-TERMINAL SUPERSET (see the header). At emit the terminal groups run
  // FIRST and hand the interior partition a `ReversedGates`/`ReversedRails` pair
  // listing what they ACTUALLY reversed; here nothing has run, so instead every
  // gate the dead-terminal spine could POSSIBLY reach is withheld from the
  // published plan: one `recoverDataDag` over EVERY terminal candidate, with no
  // `FreePoint` filter and no regard for the bails (`MeasuredUpstream` /
  // `Escaped` / `NotClosed` / in-loop / non-dominating) that might stop the
  // group emitting.
  //
  // THAT IS A SUPERSET OF THE EMIT-TIME SET, and the direction is the whole
  // point. `FreePoint` only ever REMOVES terminals and `recoverDataDag` is a
  // backward closure, so a smaller terminal set yields a smaller gate set. The
  // consumer therefore never trusts a gate the terminal spine might claim — and
  // it must not, because that spine places its adjoints at a post-dominating
  // FREE POINT with no clause-(d) scan behind it. An interior mis-prediction
  // degrades to a leak; a terminal one would not.
  //
  // IT IS WITHHELD PER GATE, NOT SUBTRACTED FROM THE PLANNER. Feeding the
  // superset in as `ReversedGates`/`ReversedRails` was the first draft and it is
  // WRONG in the useless direction: `planInteriorComponent` refuses a whole
  // component whose BORROWED parent is in `ReversedRails`, and `D.Roots` — every
  // `cqrt_alloc` source wire — is in `D.Rails`, so a single measured terminal
  // anywhere on the wire emptied the plan (measured on
  // `lowering_mc_late_sub_after.ll`). A root is not a claim: the
  // terminal spine never adjoints or frees one. What has to be excluded is a
  // GATE whose adjoint that spine might emit, and that is exactly what is done
  // below.
  //
  // Calling `recoverDataDag` here is also why this function must stay silent:
  // the recovery RECORDS `MeasuredUpstream` rather than diagnosing it, and the
  // one loud owner of that verdict is `reverseTerminalGroup`, which runs later
  // on the real terminal set.
  SmallVector<CallInst *, 8> Terminals;
  bool AnyTaintedProducer = false;
  collectTerminalCandidates(F, taint, Terminals, AnyTaintedProducer);
  SmallPtrSet<const CallInst *, 16> TermGates;
  if (!Terminals.empty()) {
    SmallVector<Value *, 8> TermVals(Terminals.begin(), Terminals.end());
    DataDag TD = recoverDataDag(TermVals, taint, DT);
    for (CallInst *G : TD.Calls)
      TermGates.insert(G);
    // A template producer in `Rails` is by construction also in `Calls`, so this
    // adds nothing today; it is the same load-bearing explicit image the driver
    // keeps at terminal selection — if `Rails` ever names a gate `Calls` does
    // not, the plan must still withhold it.
    for (Value *R : TD.Rails)
      if (auto *G = dyn_cast<CallInst>(R))
        TermGates.insert(G);
  }

  // The planner is asked with EMPTY ownership sets, which is the emit-time state
  // whenever the dead-terminal groups bail — the common case for exactly the
  // programs this plan exists for (a measured terminal on the wire). Asking
  // optimistically is safe because a plan that does not survive to emit costs a
  // LEAK, never a misplaced adjoint (see the header); the one hazard that would
  // NOT degrade that way is withheld per gate, above.
  SmallPtrSet<const CallInst *, 16> NoGates;
  SmallPtrSet<Value *, 16> NoRails;
  SmallVector<ComponentPlan, 4> Plans;
  collectInteriorPlans(F, taint, DT, PDT, LI, NoGates, NoRails, Plans);
  for (ComponentPlan &P : Plans)
    for (CallInst *G : P.D.Calls)
      if (!TermGates.count(G))
        Plan.GateAt[G] = P.At;
  return Plan;
}

}  // namespace cq
