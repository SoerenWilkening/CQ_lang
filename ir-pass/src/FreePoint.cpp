// FreePoint.cpp — see header. Step-3 productionization of the prototype's
// `PostDominatorTree`-driven last-use computation (`archive/prototype/
// cq_pass.cpp:305-329`): post-dom last-use vs φ-nodes (PRD §2.4), measure-sink
// exclusion + post-measure-use reject (§2.5), escape skip-set + loud diagnostics
// for unrecognized escapes / non-reconverging CFGs (§2.6), and the loop-backedge
// guard (§2.9). FreePoint OWNS the exact diagnostic `Msg` strings so fixture
// `CHECK` lines and code cannot drift.

#include "FreePoint.h"

#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"

#include <string>

using namespace llvm;

namespace cq {

namespace {

// The exact diagnostic message strings FreePoint owns (PRD §2.5/§2.6/§2.9). The
// Step-3 negative fixtures mirror each one CHARACTER-FOR-CHARACTER:
//   * lowering_uncompute_escape_unrecognized.ll  → kMsgUnrecognized
//   * lowering_uncompute_postmeasure_use.ll       → kMsgPostMeasure
//   * lowering_uncompute_loop_backedge.ll         → kMsgLoopBackedge
constexpr char kMsgUnrecognized[] =
    "cq uncompute: tainted handle reaches an unrecognized user";
constexpr char kMsgPostMeasure[] =
    "cq uncompute: gate applied to handle after measurement";
constexpr char kMsgLoopBackedge[] =
    "cq uncompute: tainted handle live range crosses a loop backedge";

// Loud `DiagnosticInfoUnsupported(DS_Error)` on `Where`, with its `!dbg` so the
// rejection is SOURCE-LOCATED (`clang`/`opt` then print `file:line:col:`; an
// instruction without debug info falls back to the function-level location).
// Mirrors the `diagnoseEscape` idiom (ControlDetection.cpp:51-56) so the rest of
// the pass and Phase 5 reject on the same surface — `opt` exits non-zero, which
// the negative LIT fixtures invert with `RUN: not`.
void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// A `@cqrt_measure_<W>` sink (the lowered measure form Phase 5 sees; the
// `isMeasureSink` prefix test, TaintPropagation.cpp:80). The front-end
// `@cq_measure_<sfx>` form is gone by Phase 5's slot, so the prefix match
// suffices; a measured handle is a sink, not an ordinary use.
bool isMeasureSink(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_measure_");
}

// A `@cqrt_tape_write_<W>` I/O output-tape sink (Phase 7.6; FreePoint's local
// mirror of ChainWalk::isOutputSink, matching the local isMeasureSink above). A
// tape write READS-and-PRESERVES its src register — it is NOT a collapsing gate.
// It is therefore EXEMPT from the post-measure-use reject below (writing a
// measured, now-classical value to the tape is legitimate, not a gate after
// measurement). It is NOT excluded from the post-dom Users set, though: it stays
// an ordinary `cqrt_` use so a DEAD source's free lands AFTER the write — the
// load-bearing Bennett ordering (excluding it would place the free before the
// write, a use-after-free for tape-then-dead).
bool isOutputSink(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_tape_write_");
}

// Does `U` consume `Terminal` as a RECOGNIZED escape that Phase 5 silently skips
// (no adjoint, no free, no diagnostic — PRD §2.6)?
//   * a `ReturnInst` — the caller owns the handle;
//   * a `@cq_invert_*` call — Phase 7 manual inversion supersedes here.
// (`main` is handled at the function level by the caller, below.)
bool isRecognizedEscapeUser(const User *U) {
  if (isa<ReturnInst>(U))
    return true;
  if (const auto *CI = dyn_cast<CallInst>(U)) {
    const Function *Callee = CI->getCalledFunction();
    if (Callee && Callee->getName().starts_with("cq_invert_"))
      return true;
  }
  return false;
}

// A φ-node that merely MERGES the handle's value across the arms of a classical
// branch (the both-arm live-range join, PRD §2.4): a non-mutating SSA use that
// EXTENDS the live range to the merge block without consuming the register, so
// its BLOCK must enter the post-dominator user set — but the φ itself is never an
// insertion anchor (placement lands after ALL φ-nodes via `getFirstInsertionPt`).
// Recognized as benign ONLY when its result is DEAD (the handle is reverted at
// scope exit with no use past the merge): a φ whose result has downstream users
// keeps the register live PAST any merge free point, so freeing at the merge
// would be a use-after-free — that case falls through to the §2.6 loud reject
// rather than being silently mis-placed.
bool isBenignLiveRangePhi(const Instruction *I) {
  return isa<PHINode>(I) && I->use_empty();
}

// Is `BB` inside a natural loop — i.e. does the tainted handle's live range cross
// a loop backedge (PRD §2.9)? Built from a local `DominatorTree`/`LoopInfo`,
// matching the in-tree direct-construction convention (ControlledLowering.cpp:497
// builds `DominatorTree DT(...)` in place; Phase 5 is the lone consumer, so the
// analysis-manager proxy buys nothing).
bool blockInLoop(BasicBlock *BB, LoopInfo &LI) { return LI.getLoopFor(BB); }

}  // namespace

FreePoint computeFreePoint(Value *Terminal, Function &F, PostDominatorTree &PDT,
                           const TaintSet &taint) {
  // Phase 7.3 Inc 2 (799w.2): is `Terminal` an ITERATION-LOCAL temp — a tainted
  // value born AND dead within one iteration of a recognized Case-B loop (its
  // def block ∈ `IterationLocalBlocks`, the loop `lowerLoops` proved sound-rolled)?
  // If so, the per-iteration in-body recovery is placed AFTER its last
  // in-iteration use, before the backedge — the loop-backedge guard below is
  // lifted for it, BUT the computed insertion point is re-checked to be in-body
  // (a free that escaped the loop would run once-per-function over a register
  // re-allocated each iteration — the central Rule-13 hazard, §2.5/Risk 1).
  const bool TermIterLocal =
      !taint.IterationLocalBlocks.empty() &&
      isa<Instruction>(Terminal) &&
      taint.IterationLocalBlocks.count(cast<Instruction>(Terminal)->getParent());

  // `main` resident → no caller, process exit reclaims the registers: a
  // RECOGNIZED escape for EVERY handle in the function, silently skipped (§2.6).
  if (F.getName() == "main")
    return {FreePointKind::Escaped, nullptr};

  // Classify the handle's users in one pass. The measure sink is EXCLUDED from
  // the post-dominator user set (it is a sink, not an ordinary use, §2.5); a
  // recognized escape (`ret` / `cq_invert_*`) short-circuits to Escaped; any
  // OTHER unrecognized user is a loud reject (§2.6).
  SmallVector<Instruction *, 8> Users;  // ordinary in-function gate users
  SmallVector<BasicBlock *, 4> PhiBlocks;  // both-arm live-range merge blocks
  CallInst *Measure = nullptr;          // the (first) measurement sink, if any
  Instruction *FirstUnrecognized = nullptr;
  bool Escaped = false;

  for (User *U : Terminal->users()) {
    auto *I = dyn_cast<Instruction>(U);
    if (!I)
      continue;  // a constant/metadata use never reaches the runtime
    if (isRecognizedEscapeUser(I)) {
      Escaped = true;
      continue;
    }
    if (auto *CI = dyn_cast<CallInst>(I))
      if (isMeasureSink(CI)) {
        if (!Measure)
          Measure = CI;
        continue;  // a sink, excluded from the post-dom user set (§2.5)
      }
    // A call to a recognized runtime gate (`cqrt_*` / `cq_template_*`) is an
    // ordinary in-function use; anything else is an unrecognized escape (§2.6).
    if (auto *CI = dyn_cast<CallInst>(I)) {
      const Function *Callee = CI->getCalledFunction();
      StringRef N = Callee ? Callee->getName() : StringRef();
      if (N.starts_with("cqrt_") || N.starts_with("cq_template_")) {
        Users.push_back(I);
        continue;
      }
    }
    // A both-arm live-range merge φ (dead result): non-mutating, EXTENDS the live
    // range — its block joins the post-dom set, but the φ is not an insert anchor
    // (placement lands after all φs). A φ with a live result is NOT benign (§2.6).
    if (isBenignLiveRangePhi(I)) {
      PhiBlocks.push_back(I->getParent());
      continue;
    }
    if (!FirstUnrecognized)
      FirstUnrecognized = I;
  }

  // Build the dominator tree once — the post-measure-use order test and the
  // loop-backedge guard both consult it. Direct construction matches the in-tree
  // convention (ControlledLowering.cpp:497); Phase 5 is the lone consumer.
  DominatorTree DT(F);

  // (§2.5) Post-measure use: a gate applied to the handle AFTER its measurement
  // is ill-formed ("measured ⇒ done") — loud reject. A gate is post-measure iff
  // the measurement DOMINATES it (executes first on every path reaching the
  // gate): same block ⇒ the measure comes before the gate; cross-block ⇒
  // `DT.dominates`. An UPSTREAM gate — e.g. the prep rotation in `entry` feeding
  // a measure in a later merge block — is NOT post-measure.
  if (Measure)
    for (Instruction *G : Users) {
      // A 7.6 tape write reads-and-preserves a measured (now-classical) value —
      // it is not a gate applied after measurement, so it is exempt from this
      // reject (it stays in Users for the dead-source placement above).
      if (auto *CI = dyn_cast<CallInst>(G))
        if (isOutputSink(CI))
          continue;
      bool After = (G->getParent() == Measure->getParent())
                       ? Measure->comesBefore(G)
                       : DT.dominates(Measure, G);
      if (After) {
        diagnose(G, kMsgPostMeasure);
        return {FreePointKind::Measured, nullptr};
      }
    }

  // (§2.5) Measurement is a terminator: a measured handle is reclaimed by the
  // measurement, so it gets NO adjoint and NO free — even when prep gates (the
  // upstream rotations feeding the measured value) survive on the handle.
  if (Measure)
    return {FreePointKind::Measured, nullptr};

  // (§2.6) A recognized escape (`ret` / `cq_invert_*`) — the handle LEAVES the
  // function, so the caller (or Phase 7) owns its reversal; skip with no emit and
  // no diagnostic, even if in-function gates (in-place rotations) survive.
  if (Escaped)
    return {FreePointKind::Escaped, nullptr};

  // (§2.6) An unrecognized user (e.g. a capture once a memory model exists) is a
  // HOLE, not a no-op — loud reject, never silently skipped.
  if (FirstUnrecognized) {
    diagnose(FirstUnrecognized, kMsgUnrecognized);
    return {FreePointKind::Escaped, nullptr};
  }

  // A DEAD terminal (the register's last value is never read — the common
  // uncompute case: not measured, not returned) has no ordinary gate user. Its
  // last-use point is its own definition: anchor on the Terminal instruction so
  // the post-dom / loop checks operate on its def block and the adjoint lands
  // right after it. A both-arm φ merge alone still needs the def anchored so the
  // post-dom set spans {def, merge}. A non-instruction terminal cannot be placed.
  if (Users.empty()) {
    auto *TermI = dyn_cast<Instruction>(Terminal);
    if (!TermI)
      return {FreePointKind::Escaped, nullptr};
    Users.push_back(TermI);
  }

  // The post-dom user set is the gate-user blocks PLUS the both-arm merge blocks;
  // each merge block carries a representative (its first instruction) for the
  // loop-backedge guard and the post-dom query.
  SmallVector<Instruction *, 8> UseSites(Users);
  for (BasicBlock *PB : PhiBlocks)
    UseSites.push_back(&*PB->begin());

  // (§2.9) Loop-backedge guard: a use inside a natural loop means the handle's
  // live range crosses a backedge — out of scope for the acyclic phase, loud
  // reject rather than silent miscompile. `LoopInfo` reuses `DT` built above.
  // Phase 7.3 Inc 2 EXCEPTION: an ITERATION-LOCAL temp's every use is, by the
  // `lowerLoops` proof, confined to its recognized Case-B loop body — its DAG is
  // recovered + freed IN-BODY (once per iteration), so a use in that loop is NOT
  // a live range crossing a backedge but the intended per-iteration scratch. The
  // guard still fires for any use NOT in an `IterationLocalBlocks` block (the
  // residual net — a non-iteration-local handle still declines).
  LoopInfo LI(DT);
  for (Instruction *G : UseSites)
    if (blockInLoop(G->getParent(), LI)) {
      if (TermIterLocal && taint.IterationLocalBlocks.count(G->getParent()))
        continue;  // 7.3 Inc 2: an iteration-local use is recovered in-body.
      diagnose(G, kMsgLoopBackedge);
      return {FreePointKind::Escaped, nullptr};
    }

  // Nearest common POST-dominator of every surviving use block — the earliest
  // block reached after all uses, on every path, exactly once (§2.4). A null
  // common post-dominator (a non-reconverging arm) is an unrecognized escape,
  // converted to a loud diagnostic rather than the prototype's silent nullptr.
  BasicBlock *Common = UseSites[0]->getParent();
  for (size_t i = 1; i < UseSites.size(); ++i) {
    Common = PDT.findNearestCommonDominator(Common, UseSites[i]->getParent());
    if (!Common) {
      diagnose(UseSites[i], kMsgUnrecognized);
      return {FreePointKind::Escaped, nullptr};
    }
  }

  // Latest in-block user → insert right after it; else after the block's
  // φ-nodes (`getFirstInsertionPt`, before the terminator — the insertion-point-
  // vs-φ guard, §2.4). `getNextNode()` is non-null for any non-terminator user
  // (a gate/template handle's last use never is).
  Instruction *Latest = nullptr;
  for (Instruction *U : Users)
    if (U->getParent() == Common && (!Latest || Latest->comesBefore(U)))
      Latest = U;

  Instruction *At =
      Latest ? Latest->getNextNode() : &*Common->getFirstInsertionPt();
  if (!At)
    return {FreePointKind::Escaped, nullptr};
  // (§2.5/Risk 1) For an iteration-local temp the insertion point MUST land
  // inside the recognized Case-B loop body (`IterationLocalBlocks`). If the
  // common post-dominator escaped the loop (e.g. a use that does not reconverge
  // in-body), placing the free there would run it ONCE PER FUNCTION over a rail
  // re-allocated each iteration — a use-after-free + (K−1) double-frees. The
  // recognizer proves in-body confinement, but this is the defense-in-depth
  // backstop: a non-in-body point declines loudly rather than mis-place.
  if (TermIterLocal && !taint.IterationLocalBlocks.count(At->getParent())) {
    diagnose(At, kMsgLoopBackedge);
    return {FreePointKind::Escaped, nullptr};
  }
  return {FreePointKind::Insert, At};
}

}  // namespace cq
