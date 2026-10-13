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
// ran exactly once on every reaching path). A measured intermediate is BORROWED
// (read-only) when the reduced plan proves out, else declines LOUDLY (a free of
// a measured register is a hidden collapse, Rule 5/6; bd ptue); an
// escaped / not-closed / unplaceable DAG is a Rule-6/8 safe-leak (left allocated,
// never a dirty free). Phase-4-owned control rails are subtracted up front
// (DD-4 — `ControlOwnedRails`) so a flag / work / merge out-rail is never walked.

#include "Uncomputation.h"

#include "ChainWalk.h"          // isTerminalHandle
#include "CloneProducer.h"      // bd p3kd.13 — clone results as producers
#include "TerminalGroups.h"     // reverseTerminalGroups / GroupMode (bd p3kd.13)
#include "LoopPlan.h"           // loopExitDischargePoint (bd tu9q P2 — the ONE
                                // spelling, shared with clause (ii-d))
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
#include "llvm/Analysis/CFG.h"       // isPotentiallyReachable (bd 6n1s use side)
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
// free of a measured register is a hidden projective collapse (Rule 5/6).
//
// Since bd ptue the driver first RETRIES with every measured rail borrowed
// (read-only, never adjointed or freed) and declines only when that reduced
// plan cannot be proven — see the retry in `reverseTerminalGroup`. The fixture
// that used to pin this string, lowering_uncompute_dead_sibling_premeasure.ll,
// is now that retry's simplest ACCEPT; the decline pins are (bd 01po.8)
// lowering_reject_uncompute_measured_parent_{moved_dead_record,open_copy,
// open_root_frozen}.ll,
// lowering_reject_uncompute_measured_parent_read_after_measure.ll, (bd 01po.12)
// lowering_reject_uncompute_measured_parent_per_component_read_after_measure.ll and (bd eqti)
// lowering_reject_uncompute_measured_parent_frozen_{taped,copyout,transitive}.ll
// plus lowering_reject_qram_frozen_adjoint_reads_borrowed_array.ll, each
// mirroring this string character-for-character.
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
// Since bd dm7f.2 a gate that merely runs AFTER the terminals' last uses (a
// trailing in-place gate on a walked register, straight-line) moves the point
// past it instead (`planTerminalReversal`), so this message now fires only when
// no such point proves out — a gate on a classical arm
// (lowering_reject_uncompute_trailing_gate_in_arm.ll).
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

// bd p3kd.13, R11 r9: is the rail `R` measured on EVERY path from its definition
// (one measurement sink of R post-dominates it)? Only then does ptue's "a
// measured register is never touched" cover R's own gates in the terminal-union
// probe's `Cut` (TerminalGroups.h): measured on SOME paths, R is a live record on
// the others (spec_intermediate_unc_terminal_union_reject_partial_measure.ll).
// Several measurements that only jointly cover every path do not qualify — an
// over-decline equal to main. A non-instruction rail never qualifies.
bool measuredOnEveryPath(const Value *R, const PostDominatorTree &PDT) {
  const auto *Def = dyn_cast<Instruction>(R);
  if (!Def)
    return false;
  for (const User *U : R->users())
    if (const auto *M = dyn_cast<CallInst>(U))
      if (isMeasureSink(M) && PDT.dominates(M, Def))
        return true;
  return false;
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

// ── THE MULTIPLICITY KEY (bd `test_C_libtooling-tu9q` P1; the gap it closes is
//    recorded verbatim at §4 of `planInteriorComponent` under bd
//    `test_C_libtooling-8h7d.10`) ──────────────────────────────────────────────
//
// `nullptr` means "this block runs AT MOST ONCE per function activation". A
// non-null value is the HEADER of the marked body whose TRIP the block runs once
// per.
//
// WHAT IT IS FOR, IN ONE SENTENCE. §4 and §2.9 each ask ONE endpoint whether IT
// repeats; neither asks whether the forward GATE and the DISCHARGE repeat the
// SAME NUMBER OF TIMES. A pairing that does not is a WRONG UNITARY — K adjoints
// against one forward gate, or one adjoint against K forward gates — and not
// merely a leak, so it is the one hazard in this file that cannot be absorbed by
// the Rule-6 fallback.
//
// `LoopInfo`, NOT `canRepeat`, AND THAT DOES NOT REOPEN bd
// `test_C_libtooling-4p7j`. The repeat ORACLE is still `RepeatOracle` /
// `blockCanRepeat` and is untouched. `LoopInfo` is used here only to build a
// KEY, and only for blocks ALREADY in `IterationLocalBlocks`. An IRREDUCIBLE
// cycle is never marked — both writers of that set are `LoopInfo`-gated
// (`LoopLowering.cpp`'s `markIfIterationLocal` and `markIfRailLocal`, and
// `bodyBlocksMarked`'s own enumeration proves there are exactly two) — so
// `markedHeaderOf` returns `nullptr` for every irreducible block, and the
// PRE-EXISTING `canRepeat` test has already refused it before this one is asked.
//
// ⚠ THE NULL×NULL CELL IS THE ONE TO ATTACK, and it is sound only because of
// tests that run STRICTLY BEFORE it. Two UNMARKED blocks in two DIFFERENT loops
// both key to `nullptr` and compare EQUAL. That is not a claim that they repeat
// alike — it is a claim that the per-endpoint `canRepeat` tests have ALREADY
// refused any repeating unmarked block, so by the time this predicate is asked
// `nullptr` can only mean "runs at most once per activation".
//
// **THE ORDERING IS THE PROOF, SO IT IS MEASURED AND NOT ASSERTED.** At each of
// the three call sites the gate-side test and the `At`-side test both precede
// this one in program order:
//   * `planInteriorComponent` §4  — `canRepeat(G->getParent()) &&
//     !IterationLocalBlocks.count(…)` sits IMMEDIATELY above `multiplicityAgrees`,
//     which sits immediately above `DT.dominates(G, At)`;
//   * `planInteriorComponent` §2.9 — `blockCanRepeat(At->getParent()) &&
//     !IterationLocalBlocks.count(…)` sits IMMEDIATELY above the final-`At` loop;
//   * `reverseTerminalGroup` — the `InLoop` membership re-confirmation and the
//     `blockCanRepeat(At->getParent())` clause both precede the mirror.
// **If either family of tests is ever narrowed, OR REORDERED TO RUN AFTER THIS
// ONE, this predicate becomes an OVER-ACCEPT.** Reordering is the cheaper
// mistake and the one a tidy-up makes, which is why it is named first.
//
// ⚠ RETIREMENT TRIGGER: a THIRD `IterationLocalBlocks.insert` site, or a marker
// that is not `LoopInfo`-gated, invalidates the null-key reading. It is the SAME
// trigger `LoopLowering::bodyBlocksMarked` carries, which is why the two must be
// re-derived together.
const BasicBlock *markedHeaderOf(const BasicBlock *BB, LoopInfo &LI,
                                 const TaintSet &taint) {
  if (!taint.IterationLocalBlocks.count(BB))
    return nullptr;
  // INNERMOST, deliberately. The question here is "how often does THIS block
  // run", and that is the innermost enclosing cycle's trip count. The OTHER walk
  // this increment adds — P2's anchor walk — asks "is the mint inside this cycle
  // AT ALL" and therefore uses `Loop::contains`, which DOES include subloops.
  // Two different questions, two different quantifiers, stated at both sites
  // (`CLAUDE.md` L2; bd `test_C_libtooling-emkg` is the filing that exists
  // because one predicate answered the other's question).
  const Loop *L = LI.getLoopFor(BB);
  return L ? L->getHeader() : nullptr;
}

bool multiplicityAgrees(const Instruction *G, const Instruction *At,
                        LoopInfo &LI, const TaintSet &taint) {
  return markedHeaderOf(G->getParent(), LI, taint) ==
         markedHeaderOf(At->getParent(), LI, taint);
}

// ── THE USE SIDE OF THE DISCHARGE PROOF, FOR A USE THAT NEED NOT EXECUTE
//    (bd `test_C_libtooling-6n1s`, the P1 over-accept of 2026-09-18) ───────────
//
// `provablyBeforePerActivation(U, At, R, DT)` bundles `DT.dominates(U, At)`,
// which asks the USE to run on EVERY path that reaches the discharge. A use
// inside a classical `if` arm of a marked loop body does not, and a rail whose
// uses STRADDLE two body blocks was therefore DROPPED from `Owned` and leaked —
// while conjunct (1) of `LoopLowering::declineDephasingUnmarkedLoopRails` read
// the body's MARKING as a proof that it had discharged. Measured on the
// 2026-09-18 ORACLE `9bd01598d574b344`, `t5j_twoblock_noexit_rot.c`: four
// `cq_template_ashr_i32_hl(h0,k)` mints, ZERO `_unc`, ZERO `cqrt_free`, then
// `cqrt_ry_i32(h0,0.9)` and `cqrt_measure_i32(h0)` — a COHERENT which-path
// record standing at a non-diagonal gate on the register it copies (Rule 8), at
// `opt` exit 0 with only a warning.
//
// WHAT THE DROPPED CONJUNCT WAS ACTUALLY BUYING, AND WHY THE ANSWER IS "NOTHING
// THIS SCAN NEEDS". The obligation at this point is exactly
//
//     (‡) no execution of `U` lies between the discharge `At` and the NEXT
//         execution of the rail's own mint `R`.
//
// A use that did not run cannot violate (‡). A use that DID run violates it only
// by running after `At` without an intervening `R`, and that is precisely what
// the barrier walk refuses. Dominance is a sufficient condition for a DIFFERENT
// statement ("U ran before At on every path to At") which this scan does not owe.
//
// ⚠ THE HALF THAT MAKES IT SAFE LIVES IN §4 AND MUST NOT BE READ AS PART OF THIS
// RELAXATION. Every gate whose ADJOINT will be emitted is re-proved in §4 under
// the FULL `DT.dominates(G, At)` — unchanged by this increment. So a conditional
// in-place gate on the rail (which `recoverDataDag` walks into `D.Calls`) still
// refuses the component outright; what is relaxed here is only a READER the
// reversal never touches. The two are different sets and the file now says so at
// both sites. If §4's dominance test is ever weakened, THIS relaxation must be
// re-derived from scratch rather than kept "for symmetry".
//
// ⚠ SCOPED TO ONE MARKED BODY, DELIBERATELY, AND THE RESIDUAL IS FILED RATHER
// THAN TAKEN. All three of `U`, `At` and `R` must key to the SAME marked header.
// The identical argument would admit an ACYCLIC diamond-use interior rail (minted
// in `entry`, read in both arms, discharged at the merge), which leaks today;
// that is a real over-decline and it is FILED, not fixed here, because it moves
// modules with no loop in them and this increment's witness set is the loop
// family. The scoping also makes the change byte-inert for every acyclic module
// in the tree — measured, not assumed.
//
// ⚠ NEITHER VACUITY TRAP OF `everyPathReExecutes` IS REACHABLE HERE, and both are
// named because its header says every caller must name them. (1) `Barrier == To`
// would be `R == U`; `U` is drawn from `R->users()`, and an instruction is not
// its own operand, so they are distinct. (2) "`From`'s own block entered mid-way"
// is the INTENDED reading — `R` re-executing is exactly what closes the previous
// activation — and `At` is the point whose next activation we are bounding, which
// is the configuration the header calls sound.
// ── P2, THE LOOP-EXIT ANCHOR (bd `test_C_libtooling-tu9q`; closes bd
//    `test_C_libtooling-1m5p` and the `a1_apost` over-accept) ─────────────────
//
// WHERE SHOULD A CONSUMER ANCHOR THE DISCHARGE OF A RAIL THAT WAS MINTED OUTSIDE
// THE CYCLE THE CONSUMER RUNS IN? Not at its own `getNextNode()`: that point
// REPEATS while the forward gate does not, so the adjoint would run K times
// against ONE forward execution — a wrong unitary, not a leak.
//
// ⚠ AND THAT IS NOT WHAT SHIPPED — WHAT SHIPPED IS A SILENT LEAK, which is why
// this had no failing test. The convergence loop below asks
// `provablyBeforePerActivation(U, At, R)` with the rail's own MINT as the
// barrier; for a PREHEADER-minted rail with an in-body consumer and an in-body
// `At`, every path `At ⇝ U` goes round the back edge and never re-executes the
// preheader, so the barrier walk finds a barrier-free path, the helper returns
// false and the rail is DROPPED from `Owned` — it leaks forever. MEASURED on the
// ORACLE `9bd01598d574b344` (`trackT2/probes/m_none_oder_none_none_none.c`, bd
// `1m5p`'s own quarantined class-A cell): the LICM-hoisted `sitofp → fadd → sqrt`
// chain has `h2`/`h3` discharged IN THE PREHEADER and `h4`, the `sqrt` rail the
// body's condition reads, never discharged at all — `h3` is freed while `h4`,
// derived from it, is still live, which is the LIFO inversion bd `1m5p` records.
//
// THE ANSWER IS THE POINT AT WHICH THE CONSUMER IS FINISHED FOR GOOD: the exit of
// the OUTERMOST loop enclosing the consumer that does NOT contain the mint.
//
// ⚠ **OUTERMOST, AND `Loop::contains`, AND BOTH CHOICES ARE LOAD-BEARING IN
// OPPOSITE DIRECTIONS** (`CLAUDE.md` L2; bd `test_C_libtooling-emkg` is the
// filing that exists because one predicate answered another's question).
//   * OUTERMOST, not innermost: a rail minted outside a NEST and read in its
//     innermost body must be discharged after the WHOLE nest. Anchoring at the
//     inner exit would put a once-only discharge on a point that repeats once per
//     OUTER trip — §2.9's `blockCanRepeat(At->getParent())` would then refuse it,
//     which is the right verdict reached as a LEAK instead of as the right
//     placement.
//   * `Loop::contains`, which DOES include subloops, because the question is *"is
//     the mint inside this cycle AT ALL"*. The OTHER walk this increment adds —
//     `markedHeaderOf` — asks *"how often does this block run"* and therefore uses
//     `LI.getLoopFor`, the INNERMOST. Two questions, two quantifiers, and this
//     comment is at one site while the other is at the other.
//
// NOTHING DOWNSTREAM IS RELAXED. The placement simply gets a better CANDIDATE and
// every existing proof is re-run at it: the convergence test, §4's per-gate
// dominance and post-dominance, §2.9's at-most-once, P1's multiplicity and clause
// (d)'s borrowed-parent scan all run unchanged on the new `At`. That is the whole
// safety argument, and it is why this is a dozen lines.
//
// ⚠ A NULL RESULT IS A LEAK, NOT A DIAGNOSTIC. `loopExitDischargePoint` returns
// null for a MULTI-EXIT loop and the caller then abandons the component exactly as
// today. Inventing a multi-exit discharge point is a separate capability with its
// own post-dominance obligation.
//
// ⚠ **DO NOT READ THAT AS "A `break` LOOP IS UNMOVED", WHICH IS THE OBVIOUS AND
// WRONG COROLLARY.** `-O1` IF-CONVERTS a `break` into one extra disjunct on the
// LATCH (measured: `%15 = select i1 %12, i1 true, i1 %14`), leaving **ONE** exit
// block — so a latch-folded break loop is NOT multi-exit and IS reached by this
// walk. `trackT2/probes/t5h_rail_straddles_break_rot.c` moves for exactly that
// reason. The break is a SPELLING, not a cause.
// `loop_pairing_accept_break_latch_folded.ll` and `tu9q.1`'s `r1_break_loop` are
// unmoved for a DIFFERENT reason, and it is worth stating so nobody cites them as
// evidence about multi-exit: their rails (`(y >> k) & 1`) are minted **IN THE
// BODY**, so the condition this walk tests — *the consumer's loop does not contain
// the mint* — is FALSE for them and the anchor is unchanged.
// ⚠ The genuinely MULTI-EXIT path is owed a fixture and has none: three C shapes
// were built for it and `-O1` renormalised or declined every one (recorded in
// `trackT2/IMPL_T3.md` §3 F-R2-1). It is the conservative branch, and it is a
// PREDICTION rather than a test until something reaches it (`8h7d.10`'s lesson).
Instruction *anchorForConsumer(Instruction *U, const Instruction *R,
                               LoopInfo &LI) {
  const Loop *LOut = nullptr;
  for (const Loop *L = LI.getLoopFor(U->getParent()); L; L = L->getParentLoop())
    if (!L->contains(R->getParent()))
      LOut = L;  // keep walking: the LAST one that qualifies is the outermost.
  if (!LOut)
    return U->getNextNode();  // the shipped anchor, byte-inert for every module
                              // whose consumer shares a cycle with its mint (and
                              // for every acyclic one).
  BasicBlock *Exit = loopExitDischargePoint(LOut);
  if (!Exit)
    return nullptr;
  return &*Exit->getFirstInsertionPt();
}

bool useCompleteBeforeDischarge(const Instruction *U, const Instruction *At,
                                const Instruction *R, const DominatorTree &DT,
                                LoopInfo &LI, const TaintSet &taint) {
  if (provablyBeforePerActivation(U, At, R, DT))
    return true;  // the shipped proof, unchanged and asked first.
  const BasicBlock *K = markedHeaderOf(At->getParent(), LI, taint);
  if (!K || markedHeaderOf(U->getParent(), LI, taint) != K ||
      markedHeaderOf(R->getParent(), LI, taint) != K)
    return false;  // outside one marked body — today's behaviour exactly.
  if (!isPotentiallyReachable(At, U, /*ExclusionSet=*/nullptr, &DT))
    return true;  // `U` is unreachable from the discharge — (‡) holds trivially.
  return everyPathReExecutes(At, U, R);
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
// lowering_uncompute_borrowed_operand_free_order.ll. Since bd 5c5b every rail of
// that measured shape is birth-frozen (a hand-written alloc is tainted only through
// a non-constant seed, so it is never provably |0⟩ and never freed); the touch
// keying stays as the structural guarantee for a future null-seeded tainted root.
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
// `opt -verify`. Its one emitter-mintable member was a `@__cq_q_` clone call; since
// bd p3kd.13 an OWNED clone result is a rail (`isCloneProducer`) and an unowned one
// makes the DAG `NotClosed` — intersecting keeps that structural, not argued.
void emitDagReversal(const DataDag &D, Instruction *At, WidthDispatch &wd,
                     TaintSet &taint) {
  materializeCloneTwins(D.Calls, taint);  // bd p3kd.13: each owned clone's twin
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
    // ⚠ ONLY WHILE EVERY REGISTER THAT ADJOINT READS IS DEAD OR REVERSED BY THIS
    // SAME PLAN (bd test_C_libtooling-eqti — the sentence above said it
    // unconditionally and was false the moment a plan BORROWED a live register).
    // A kept rail's adjoint that reads a live register is a controlled gate FROM
    // it onto a leaked, recorded rail, and it changes that register's coherence.
    // The whole-DAG plan is closed and the M-B interior plan keeps no rail, so
    // only the frontier retry can violate it, and `keptRailAdjointReadsBorrowed`
    // refuses that retry when it would.
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
                   // case above, a bd r2j3.3 record-window reader, or (bd 5c5b)
                   // a rail whose BIRTH is not provably |0⟩ — a `cqrt_alloc`
                   // root this reversal returns to |seed⟩, not |0⟩.
      CallInst *Free = B.CreateCall(wd.freeFn(), {FR});
      if (DebugLoc DL = G->getDebugLoc())
        Free->setDebugLoc(DL);
      taint.SpineOps.insert(Free);  // M-A Inc 1 — teardown traffic, not a data use
    }
  }
}

// Defined with the M-B partition below (it is that partition's clause-(d) scan);
// declared here for the dead-terminal driver's QRAM-array retry (bd 01po.4).
// `Moved`, when non-null (bd 01po.8, the frontier fixpoint only), makes the scan
// ask EVERY borrowed parent and collect each one whose window fails, instead of
// stopping at the first; the boolean answer is the same either way.
bool borrowedParentsUnmoved(const DataDag &D,
                            const SmallPtrSetImpl<Value *> &Borrowed,
                            Instruction *At, DominatorTree &DT,
                            const TaintSet &taint, bool AdmitCloneCalls,
                            SmallVectorImpl<Value *> *Moved = nullptr);

// bd test_C_libtooling-ptue — may the frontier retry BORROW these measured rails?
// True iff no measurement of a borrowed measured rail `P` can reach a gate of `D`
// that reads `P`, i.e. every read the reversal replays happened BEFORE `P`'s
// collapse. `borrowedParentsUnmoved` already refuses a measurement strictly
// inside the window (first read, `At`) and admits one after `At`; this refuses
// the remaining position, a measurement BEFORE the first read.
//
// THAT REFUSAL IS AN OVER-DECLINE OF A RULED CAPABILITY, KEPT LOUD AS A GAP. A
// post-measurement read of a name is bd yiid, CLOSED with two owner rulings:
// 2026-09-14 "a capability, not a decline" (the measured name is re-usable by
// re-preparation: a fresh allocation seeded from the outcome) and 2026-09-15 E3
// (b) BROAD (every use positioned after the measurement is fresh/classical) —
// ruled, NOT BUILT; today such a read chains on the collapsed rail. The
// reversal would be exact on that rail, but here it REPLAYS the post-collapse
// read itself (`xor_unc(t, q, …)` after `measure(q)`), and E3 re-targets exactly
// that read to a re-prepared register; the spine's reversal has not been
// composed with E3, so the module keeps its pre-ptue decline rather than pin
// the pre-E3 reading. RETIREMENT TRIGGER (L7): when E3 lands, re-derive this
// predicate and lowering_reject_uncompute_measured_parent_read_after_measure.ll.
//
// SCOPE, deliberately (Rule-11 round 1, F2): only reads by gates of `D` — the
// reads the reversal REPLAYS. A post-collapse read by a BORROWED rail's own
// producer (`mq = measure(q); q2 = q + 1; t = q2 ^ 9; …; measure(q2)`, borrow
// `q2`) is not replayed: the reversal reads `q2`, before `q2`'s collapse, and
// `q2`'s label is m+1 under today's chaining and under E3 alike. That forward
// read lowers on its own without any reversal, so it is accepted
// (lowering_uncompute_measured_parent_derived_after_collapse.ll).
//
// PER ACTIVATION (bd test_C_libtooling-01po.13). `isPotentiallyReachable(M, G)`
// alone answers "can the measurement run before the read", which a back edge
// always makes true — so a FRESH register measured every loop trip (`int q =
// x + i; cq_theta(&q, .25); int t = q ^ 9; cq_theta(&t, .5); acc +=
// cq_measure(q);`) refused: trip i's measurement reaches trip i+1's xor. That
// xor reads the register minted by trip i+1, not the one trip i collapsed. So a
// read is post-collapse only if some path from the measurement reaches it
// WITHOUT re-executing `P`'s definition (`everyPathReExecutes`, the barrier walk
// the per-activation proofs share), and that exemption is taken only when the
// definition MINTS a physically fresh register each time it runs — a
// `cqrt_alloc` mint or a template producer. A register CARRIED across trips (a
// φ, an argument, a mint outside the loop) keeps the old answer: every path round
// the back edge misses its definition, or it is not a mint at all
// (lowering_reject_uncompute_measured_parent_carried_across_iterations.ll).
// Neither vacuity trap of the walk is reachable: `G` reads `P`, so it is not
// `P`'s definition (`Barrier != To`), and `M` re-entering its own block from the
// top through the definition is exactly "re-executes".
bool measuredParentsReadBeforeCollapse(const DataDag &D,
                                       const SmallPtrSetImpl<Value *> &Measured,
                                       const DominatorTree &DT) {
  for (Value *P : Measured) {
    auto *Def = dyn_cast<CallInst>(P);
    const bool FreshMint = Def && (isAllocMint(Def) || isTemplateProducer(Def));
    for (User *U : P->users()) {
      auto *M = dyn_cast<CallInst>(U);
      if (!M || !isMeasureSink(M))
        continue;
      for (CallInst *G : D.Calls)
        for (Value *Op : G->args())
          if (Op == P &&
              isPotentiallyReachable(M, G, /*ExclusionSet=*/nullptr, &DT) &&
              !(FreshMint && everyPathReExecutes(M, G, Def)))
            return false;
    }
  }
  return true;
}

// bd test_C_libtooling-eqti — does the reduced plan reverse-play a rail it will
// NOT free, through a gate that reads a BORROWED register or a rail whose label
// depends on one?
//
// WHY THAT IS A WRONG UNITARY AND NOT A LEAK. `emitDagReversal` emits EVERY
// adjoint, including those of a rail it then keeps (a step-3b frozen rail, a QRAM
// array, a value outside the scanned `Rails`), on the premise that "an adjoint on
// a rail we then leak is harmless — a local unitary on a leaked rail". That holds
// for a rail whose reversal is inexact (it was recorded, so it does not return to
// |0>) only when nothing the adjoint READS stays live: then the adjoint is a
// unitary on registers that are all leaked or reversed together, and no later
// gate can see it. A borrowed register is live by construction — the frontier
// retry borrows it precisely because it is measured (bd ptue) or still holds its
// cells (bd 01po.4), and clause (d) admits non-diagonal gates on it AFTER `At`.
// A kept rail's adjoint controlled by it is then a controlled gate from a live
// register onto a leaked, recorded one: it changes the live register's
// coherence. Measured (bd eqti): `t = !q; cq_theta(&t,.5); printf(t);
// cq_theta(&q,.3); measure(q)` emitted `ry(t,-.5); xor_i1_hl_unc(t, q, 1)` with
// `t` kept, scaling q's coherence by ∓sin(.5) (P(q=1) 0.037181 -> 0.045584).
//
// "DEPENDS ON" IS TRANSITIVE and is closed to a fixpoint over `D.Calls`: a kept
// rail whose gate reads an OWNED rail minted from `q` is controlled by `q` just
// the same once that rail is reversed away. Over-approximating (a read that in
// reverse order precedes the dependence) can only refuse, which keeps today's
// decline.
//
// A reversal whose kept rails' adjoints are all LOCAL (read nothing but the rail)
// is untouched: the bd 01po.4 accept lowering_qram_store_measured_index_nonmain.ll
// keeps `p` (frozen) and reverse-plays only `ry(p, -.5)`.
//
// SCOPE: only the frontier retry can reach this — the whole-DAG plan is CLOSED
// (no borrowed register), and an M-B interior plan keeps no rail (every gate
// passes `preservesBasisUnderRecord`, so steps 3b/3c freeze nothing; it has no
// roots, so 3d freezes nothing; every adjointed rail is `Owned`, a scanned
// template rail). Re-derive this if either stops being true.
bool keptRailAdjointReadsBorrowed(const DataDag &D,
                                  const SmallPtrSetImpl<Value *> &Borrowed) {
  SmallPtrSet<const Value *, 16> Dep(Borrowed.begin(), Borrowed.end());
  auto readsDep = [&](CallInst *G, const Value *Self) {
    for (Value *Op : G->args())
      if (Op != Self && Dep.count(Op))
        return true;
    return false;
  };
  for (bool Grew = true; Grew;) {
    Grew = false;
    for (CallInst *G : D.Calls) {
      Value *R = railOf(G);
      if (R && !Dep.count(R) && readsDep(G, R)) {
        Dep.insert(R);
        Grew = true;
      }
    }
  }
  for (CallInst *G : D.Calls) {
    Value *R = railOf(G);
    const bool Kept = !R || isa<Constant>(R) || !D.Rails.count(R) ||
                      D.FrozenRails.count(R) || isQramArrayHandle(R);
    if (Kept && readsDep(G, R))
      return true;
  }
  return false;
}

// The verdict of `planTerminalReversal` — what the dead-terminal driver does
// with one recovered group (bd test_C_libtooling-01po.4 split the checks out
// of `reverseTerminalGroup` so its QRAM-array retry re-asks EXACTLY them).
enum class TerminalPlan { Emit, Leak, DeclineUninvertible, DeclineDivergent };

// Every post-recovery check of `reverseTerminalGroup`, in its original order,
// as PURE ANALYSIS: each place that used to `return` (a leak) or `diagnose`
// and `return` (a decline) now hands back that verdict, with the culprit gate
// in `Culprit` for a decline. On `Emit`, `At` is the single insertion point and
// every gate of `D` dominates it. The caller owns every diagnostic.
TerminalPlan planTerminalReversal(Function &F, const DataDag &D,
                                  ArrayRef<Instruction *> InsertAts,
                                  TaintSet &taint, DominatorTree &DT,
                                  PostDominatorTree &PDT, LoopInfo &LI,
                                  bool IterLocal, Instruction *&At,
                                  CallInst *&Culprit) {
  if (D.Escaped || D.NotClosed || D.Calls.empty())
    return TerminalPlan::Leak;

  // Invertibility pre-scan (WI-5, PRD §2.12/§2.10).
  CallInst *Uninvertible = nullptr;
  for (CallInst *G : D.Calls)
    if (!isInverseEmittable(G)) {
      Uninvertible = G;
      break;
    }
  if (Uninvertible) {
    Culprit = Uninvertible;
    return TerminalPlan::DeclineUninvertible;
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
      return TerminalPlan::Leak;  // safe leak (acyclic backstop stands)
    for (CallInst *G : D.Calls)
      if (!taint.IterationLocalBlocks.count(G->getParent()))
        return TerminalPlan::Leak;  // a gate escaped the loop body — leak,
                                    // never reverse once.
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
  At = dagInsertPoint(Anchors, PDT);
  if (!At)
    return TerminalPlan::Leak;
  Instruction *BaseAt = dagInsertPoint(InsertAts, PDT);
  // The moved-point clause-(d) test above, as a predicate so the bd dm7f.2
  // trailing-gate placement below asks it of its own point too.
  auto movedPointClean = [&](Instruction *X) {
    if (X == BaseAt)
      return true;
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
                return false;  // clause (d) unprovable at the moved point
    return true;
  };
  if (!movedPointClean(At))
    return TerminalPlan::Leak;  // safe leak

  // Every gate must DOMINATE `At` (acyclic + dominating ⇒ ran exactly once on
  // every reaching path). For an iteration-local group this holds WITHIN the
  // iteration (no value crosses the backedge by construction of L4b); a gate that
  // does not dominate the in-body `At` (a split across a classical in-body
  // diamond) declines LOUDLY rather than reverse a partial chain.
  auto firstNonDominating = [&](Instruction *X) -> CallInst * {
    for (CallInst *G : D.Calls)
      if (!DT.dominates(G, X))
        return G;
    return nullptr;
  };
  CallInst *NonDominating = firstNonDominating(At);
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
  auto runsOnceAt = [&](Instruction *X) {
    if (blockCanRepeat(X->getParent()) &&
        !(IterLocal && taint.IterationLocalBlocks.count(X->getParent())))
      return false;  // never a once-minted reversal on a per-iteration path
    for (CallInst *G : D.Calls)  // the tu9q mirror below, for the dm7f.2 point
      if (!multiplicityAgrees(G, X, LI, taint))
        return false;
    return true;
  };
  if (NonDominating) {
    // bd test_C_libtooling-dm7f.2 — A TRAILING GATE IS NOT A DIVERGENT ARM.
    // The anchors are the terminals' last uses and the preserving sinks; an
    // in-place gate on a walked register that runs AFTER all of them (`_Bool b
    // = u; cq_theta(&b,.5); int v = tbl[b]; printf("%d %d\n", b, v);
    // cq_theta(&b,-.5);` in a non-main function: the trailing Ry is in the DAG
    // because the walk owns `b`) does not dominate that point, and this used
    // to decline with the divergent-arm message on straight-line code. Place
    // the reversal after it instead: every non-dominating gate's next node
    // joins the anchors, and the new point is TAKEN ONLY IF the whole plan
    // proves out there — every gate dominates it, the moved-point clause-(d)
    // test holds, and it runs at most once with matching multiplicity.
    // Reverse program order then undoes the trailing gate FIRST, so every
    // earlier `_unc` reads the label its forward gate read. Anything less keeps
    // today's verdict, a loud decline that now names a real divergent arm:
    // a gate in a classical arm never dominates a point past the merge
    // (lowering_reject_uncompute_trailing_gate_in_arm.ll), and a refused new
    // point is never turned into a silent leak (bd 261j(a) risk 1, below).
    SmallVector<Instruction *, 8> Ext(Anchors.begin(), Anchors.end());
    for (CallInst *G : D.Calls)
      if (!DT.dominates(G, At))
        Ext.push_back(G->getNextNode());  // a call is never a terminator
    Instruction *At2 = dagInsertPoint(Ext, PDT);
    if (At2 && !firstNonDominating(At2) && movedPointClean(At2) &&
        runsOnceAt(At2)) {
      At = At2;
      return TerminalPlan::Emit;
    }
    Culprit = NonDominating;
    return TerminalPlan::DeclineDivergent;
  }

  if (blockCanRepeat(At->getParent()) &&
      !(IterLocal && taint.IterationLocalBlocks.count(At->getParent())))
    return TerminalPlan::Leak;  // safe leak — never a once-minted reversal
                                // on a per-iteration path.
  // bd `test_C_libtooling-tu9q` P1 — THE MULTIPLICITY TEST, MIRRORED HERE AS
  // DEFENCE IN DEPTH, and it is EXPECTED NEVER TO FIRE on this partition. The
  // dead-terminal driver already refuses the same pairing by MEMBERSHIP a few
  // lines up (`if (InLoop) { … !taint.IterationLocalBlocks.count(G->getParent())
  // → Leak; }`), which for an `IterLocal` group forces every recovered gate
  // into a marked block, and the clause directly above forces `At` into one too.
  // Equal keys therefore follow — but "follow" is an argument about two other
  // tests, and this file already makes the same trade for the four ownership sets
  // it re-checks rather than infers. A refusal here is a LEAK (Rule 6), never a
  // diagnostic, so the cost of the redundancy is zero and the cost of being wrong
  // about the inference would be a wrong unitary.
  for (CallInst *G : D.Calls)
    if (!multiplicityAgrees(G, At, LI, taint))
      return TerminalPlan::Leak;
  return TerminalPlan::Emit;
}

// Step 5 of `reverseTerminalGroup`: reverse the planned DAG once at `At` and
// record what this group now owns (the out-params the M-B partition reads).
void emitTerminalReversal(const DataDag &D, Instruction *At, WidthDispatch &wd,
                          TaintSet &taint,
                          SmallPtrSetImpl<const CallInst *> &ReversedGates,
                          SmallPtrSetImpl<Value *> &ReversedRails) {
  emitDagReversal(D, At, wd, taint);
  for (CallInst *G : D.Calls) {
    ReversedGates.insert(G);
    if (Value *R = railOf(G))
      ReversedRails.insert(R);
  }
  for (Value *R : D.Rails)
    ReversedRails.insert(R);
}

// The verdict of the dead-terminal FRONTIER RETRY on one reduced DAG `DR` (bd
// ptue / 01po.4): every check that retry asks, in its original order. Factored
// out by bd test_C_libtooling-01po.12 so the per-component fallback re-asks
// EXACTLY these (Rule 12), and split into verdicts by bd 01po.8 so the frontier
// fixpoint can tell the two refusals it WIDENS on from every other one:
//   * `NotClosed`   — a rail of `DR` has a consumer outside it (`OpenRails`);
//   * `ParentMoved` — clause (d) failed for the borrowed parents in `Moved`;
//   * `Refused`     — anything else, which keeps today's decline.
// `Emit` iff the pre-01po.8 conjunction held: an open rail makes
// `planTerminalReversal` refuse first anyway, and `borrowedParentsUnmoved` gives
// the same answer whether or not it collects. On `Emit`, `At` is the point.
enum class FrontierVerdict { Emit, NotClosed, ParentMoved, Refused };

FrontierVerdict judgeFrontierPlan(Function &F, const DataDag &DR,
                                  ArrayRef<Instruction *> Ats,
                                  const SmallPtrSetImpl<Value *> &Borrowed,
                                  const SmallPtrSetImpl<Value *> &Measured,
                                  TaintSet &taint, DominatorTree &DT,
                                  PostDominatorTree &PDT, LoopInfo &LI,
                                  bool IterLocal, Instruction *&At,
                                  SmallVectorImpl<Value *> &Moved) {
  if (DR.MeasuredUpstream)
    return FrontierVerdict::Refused;
  // An escape, an empty DAG, or a closure refused only by an OWNERSHIP image
  // (no open rail) is not widened: `planTerminalReversal` refuses it below.
  if (DR.NotClosed && !DR.Escaped && !DR.Calls.empty() && !DR.OpenRails.empty())
    return FrontierVerdict::NotClosed;
  CallInst *Unused = nullptr;
  if (planTerminalReversal(F, DR, Ats, taint, DT, PDT, LI, IterLocal, At,
                           Unused) != TerminalPlan::Emit)
    return FrontierVerdict::Refused;
  if (!borrowedParentsUnmoved(DR, Borrowed, At, DT, taint,  // bd p3kd.13: rhk5 (3)
                              /*AdmitCloneCalls=*/true, &Moved))  // for a clone producer
    return Moved.empty() ? FrontierVerdict::Refused
                         : FrontierVerdict::ParentMoved;
  if (!measuredParentsReadBeforeCollapse(DR, Measured, DT) ||
      keptRailAdjointReadsBorrowed(DR, Borrowed))
    return FrontierVerdict::Refused;
  return FrontierVerdict::Emit;
}

struct FrontierComponentPlan {
  DataDag D;
  Instruction *At = nullptr;
};

// bd test_C_libtooling-01po.12 — partition `Terms` by the connectivity of their
// REDUCED DAGs (walked with the borrowed frontier): two terminals are in one
// component iff their DAGs share a gate or a rail, transitively. A shared OWNED
// prefix therefore stays in one component and is reversed once (splitting it
// would make each half `NotClosed` anyway). Components come out in
// first-terminal order (FileCheck-stable emission).
void partitionByReducedDag(ArrayRef<Value *> Terms, ArrayRef<Instruction *> Ats,
                           const InteriorPlan &Frontier, const TaintSet &taint,
                           DominatorTree &DT,
                           SmallVectorImpl<SmallVector<Value *, 4>> &CTerms,
                           SmallVectorImpl<SmallVector<Instruction *, 4>> &CAts) {
  const unsigned N = Terms.size();
  SmallVector<unsigned, 8> Parent(N);
  for (unsigned I = 0; I != N; ++I)
    Parent[I] = I;
  auto find = [&](unsigned I) {
    while (Parent[I] != I)
      I = Parent[I] = Parent[Parent[I]];
    return I;
  };
  DenseMap<Value *, unsigned> FirstWalker;  // walked value -> a terminal walking it
  for (unsigned I = 0; I != N; ++I) {
    DataDag DI = recoverDataDag(Terms[I], taint, DT, &Frontier);
    auto join = [&](Value *V) {
      auto Ins = FirstWalker.try_emplace(V, I);
      if (Ins.second)
        return;
      unsigned A = find(Ins.first->second), B = find(I);
      if (A != B)
        Parent[std::max(A, B)] = std::min(A, B);
    };
    for (CallInst *G : DI.Calls)
      join(G);
    for (Value *R : DI.Rails)  // roots and template rails
      join(R);
  }
  DenseMap<unsigned, unsigned> SlotOf;
  for (unsigned I = 0; I != N; ++I) {
    auto Ins = SlotOf.try_emplace(find(I), CTerms.size());
    if (Ins.second) {
      CTerms.emplace_back();
      CAts.emplace_back();
    }
    CTerms[Ins.first->second].push_back(Terms[I]);
    CAts[Ins.first->second].push_back(Ats[I]);
  }
}

// bd test_C_libtooling-01po.8 review round 2 — can the parent `P` be COLLAPSED
// (fully or partly) before the move `M` runs? Over-approximated, and every
// over-approximation refuses (keeps the decline): walk `P`'s ENTANGLED COMPONENT
// along data edges — a minted register's producer operands, and for every call
// that uses a member, its result and all its operands — and answer true when an
// OBSERVATION of any member (a measurement, or a record into a kept carrier: a
// tape write or a copy-out) can reach `M` (`isPotentiallyReachable`, so a loop
// that could run it first counts), or when a member has a non-call user (a
// phi/select/store/ret alias the walk cannot follow). A collapse of any register
// correlated with `P` can fix `P`'s label, and then a record of `P` is a
// product-state record of the rest — not the program's own entanglement.
// Members are the tainted values plus the minted registers the taint set does
// not carry (a control flag from `lowerCompareToFlag`, a `cqrt_alloc` mint), so
// a correlation routed through a controlled gate is walked too.
bool componentObservedBefore(Value *P, const Instruction *M,
                             const DominatorTree &DT, const TaintSet &taint) {
  SmallVector<Value *, 16> Work{P};
  SmallPtrSet<Value *, 32> Seen;
  Seen.insert(P);
  auto push = [&](Value *V) {
    if (!V || isa<Constant>(V) || Seen.count(V))
      return;
    auto *CI = dyn_cast<CallInst>(V);
    if (!taint.Tainted.count(V) &&
        !(CI && (isTemplateProducer(CI) || isAllocMint(CI))))
      return;
    Seen.insert(V);
    Work.push_back(V);
  };
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (auto *Def = dyn_cast<CallInst>(V))
      for (Value *Op : Def->args())
        push(Op);
    for (User *U : V->users()) {
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI)
        return true;  // an alias the walk cannot follow — unprovable
      if (isMeasureSink(CI) || recordsIntoKeptCarrier(CI, V)) {
        if (isPotentiallyReachable(CI, M, /*ExclusionSet=*/nullptr, &DT))
          return true;
        continue;
      }
      push(CI);
      for (Value *Op : CI->args())
        push(Op);
    }
  }
  return false;
}

// bd test_C_libtooling-01po.8 — is `R`, written by `G` from the borrowed parent
// `P`, a which-path record of `P` that the PROGRAM keeps alive across a move of
// `P` on EVERY path to the reversal point `At`? Owner rule (review round 1): a
// record whose last use PRECEDES the parent's next non-diagonal gate must be
// uncomputed, never leaked; only a record genuinely live across a move on every
// path is left allocated.
//
// True iff some user `M` of `P` is a NON-PERMUTATION in-place gate on it — an
// in-place gate (`isInPlaceGateOn`) that is not a basis permutation
// (`preservesBasisUnderRecord`), which on that surface is exactly the Ry family,
// controlled or not — and some user `U` of `R` follows it, with
// `G` dom `M` dom `U` dom `At`: on every path that reaches the reversal, the
// gate moves `P` after `G` read it and `R` is used after the move. Then any
// schedule that returns `R` to |0> must act on `P` (undo the move, `_unc`,
// redo it) and changes `P`'s statistics, while the source keeps `R` alive across
// the move: leaving `R` allocated is the program's own physics (owner ruling
// lyyf), never adjointed, never freed.
//
// WHAT IS NOT A FORCING MOVE, each a silent miscompile when it was one
// (review round 1, f6984f85):
//   * a MEASUREMENT of `P` (F1). A collapse leaves `P`'s computational-basis
//     label unchanged on the realised branch, and that label is all an `_unc`
//     reads; the dead record is uncomputed in the program's meaning, and
//     leaking it kept a full record of another register across a later
//     rotation (lowering_reject_uncompute_measured_parent_measured_in_window.ll);
//   * a gate on SOME paths only (F2): the record is uncomputable on the others
//     (lowering_reject_uncompute_measured_parent_moved_on_some_paths.ll);
//   * a record whose uses all END before the move (dominance fails), and a
//     basis permutation of `P` (`xorc`/`addc`/a store): conjugating by it would
//     not change `P`'s statistics, so the record is not forced
//     (lowering_reject_uncompute_measured_parent_moved_dead_record.ll).
//   * a move of a parent that is NOT IN SUPERPOSITION when it runs (review
//     round 2): after a collapse the parent is |m> in a product state, the
//     record carries only its OTHER operands, and conjugating by the move
//     leaves the parent's statistics unchanged — so the premise above fails
//     (lowering_reject_uncompute_measured_parent_collapsed_before_move.ll).
//     `componentObservedBefore` refuses a move that an observation of the
//     parent's entangled component can precede, a copy's measurement included
//     (lowering_reject_uncompute_measured_parent_copy_measured_before_move.ll).
// Every refusal keeps the decline. Asked of the IR as it stands (nothing has
// been emitted for this function's terminal groups when it is planned), with
// `DominatorTree::dominates` only — no window collector, so no unprovable user
// can be read as "moved" (finding F4).
bool recordLiveAcrossMove(CallInst *G, Value *R, Value *P, Instruction *At,
                          DominatorTree &DT, const TaintSet &taint) {
  for (User *PU : P->users()) {
    auto *M = dyn_cast<CallInst>(PU);
    if (!M || !isInPlaceGateOn(M, P) || preservesBasisUnderRecord(M) ||
        !DT.dominates(G, M) || componentObservedBefore(P, M, DT, taint))
      continue;
    for (User *RU : R->users()) {
      auto *U = dyn_cast<Instruction>(RU);
      if (U && DT.dominates(M, U) && DT.dominates(U, At))
        return true;
    }
  }
  return false;
}

// THE FRONTIER FIXPOINT — bd test_C_libtooling-01po.12 (per component) and bd
// test_C_libtooling-01po.8 (the general retry). Asked only after the
// whole-group retry refused, so no module that lowered before changes.
//
// PER COMPONENT (01po.12). The group's reversal point is the LATEST anchor of all
// its terminals, and clause (d) checks each borrowed parent over [first DAG
// read, that point]. So a dead temp anchored after `measure(q)` that has nothing
// to do with `q` put the measurement inside q's window and refused the bd ptue
// accept. Each component is planned at its OWN anchors instead and must pass
// every check `judgeFrontierPlan` asks; ALL are planned before ANY is emitted.
// WHY SEPARATE REVERSALS COMPOSE: components share at most a BORROWED register,
// and no reversal writes or frees one — each adjoint writes only its own
// component's rails and only READS a borrowed parent, so it cannot move that
// parent's label for another component's window. The reversals act on disjoint
// written registers and commute. (The other components' adjoints are not in the
// IR when a window is scanned; by the same argument none of them could move it.)
//
// THE FRONTIER GROWS (01po.8). `Frontier.Borrowed` starts as the measured rails
// and the QRAM array roots. A component's refusal WIDENS it in two cases, and
// only where the rail left allocated is one EVERY schedule must leave:
//   * `NotClosed` on an open ROOT — a `cqrt_alloc` register of the reduced DAG
//     has a consumer outside it (bd 01po.13 F3: `q2 = q+1; t = q2^9; u = q^5;`
//     with `q2` measured: `q`'s consumer `q+1` is not in the reduced DAG). The
//     root is BORROWED: never walked, adjointed or freed, like a measured rail,
//     and every check is re-asked with it borrowed — its own clause-(d) window
//     included. Its un-rotation would act on a register entangled with the
//     outside consumer's live result, so no schedule reverses it; the
//     non-measured spine leaves such a group allocated whole (`NotClosed`).
//     An open TEMPLATE rail (a copy) is NOT widened: it could be discharged
//     after its last use, and borrowing it would leave it allocated (the
//     reversal's own `_unc` then keeps M-B off it) — `Refused`.
//   * `ParentMoved` — a borrowed parent P is moved inside its window, so no
//     `_unc` reading P can run at that point. Every DAG gate G reading P stops
//     being reversed: `railOf(G)` joins the frontier (a terminal that lands in it
//     is dropped), PROVIDED `recordLiveAcrossMove` proves R = railOf(G) is used
//     after a non-permutation gate on P on EVERY path to the reversal point — a
//     which-path record the program itself keeps across the move, left
//     ALLOCATED: never freed (Rule 5), never adjointed
//     (lowering_reject_uncompute_measured_parent_moved.ll). A measurement, a
//     move on some paths only, or a record whose uses all end before the move
//     is `Refused` (see that predicate; review round 1, F1/F2).
// Then the components are re-derived and re-planned from scratch. Every other
// refusal (`Refused`: an escape, an ownership-image closure, an in-loop or
// divergent or uninvertible plan, a post-collapse read (bd yiid, pending E3), a
// kept rail whose adjoint reads a borrowed register (bd eqti)) returns false and
// the caller keeps today's decline verbatim. A leaked rail is BORROWED, so the
// eqti test keeps treating it as a live register.
//
// TERMINATION: a round that neither returns nor emits inserts at least one NEW
// value into `Frontier.Borrowed` (an open rail is walked, so it is not yet
// borrowed; `railOf(G)` of a recovered gate is not borrowed, or the walk would
// have stopped before G), and the frontier is bounded by the function's values.
// A round where every terminal is borrowed returns true with NO plan: every
// terminal is a kept record and nothing is reversed or freed.
//
// `Frontier` is IN/OUT (bd p3kd.13, R11 r8): on `true` it is the FINAL frontier
// the plans were judged against. Each member's kind is structural, so it is not
// recorded twice: a QRAM array root (`isQramArrayHandle`, the predicate that
// seeded it), a measured rail (`DataDag::MeasuredRails`), else an open root or a
// forced record. The terminal-union probe exempts from `GroupProbe::Cut` the OWN
// gates of the open roots and forced records, and of a measured rail only when it
// is measured on every path (`measuredOnEveryPath`, R11 r9; TerminalGroups.h).
// Planning stays side-effect-free.
bool planFrontierFixpoint(Function &F, ArrayRef<Value *> InsertTerms,
                          ArrayRef<Instruction *> InsertAts,
                          InteriorPlan &Frontier,
                          const SmallPtrSetImpl<Value *> &Measured,
                          TaintSet &taint, DominatorTree &DT,
                          PostDominatorTree &PDT, LoopInfo &LI, bool IterLocal,
                          SmallVectorImpl<FrontierComponentPlan> &Plans) {
  for (;;) {
    Plans.clear();
    SmallVector<Value *, 8> Terms;
    SmallVector<Instruction *, 8> Ats;
    for (unsigned I = 0, E = InsertTerms.size(); I != E; ++I)
      if (!Frontier.Borrowed.count(InsertTerms[I])) {
        Terms.push_back(InsertTerms[I]);
        Ats.push_back(InsertAts[I]);
      }
    if (Terms.empty())
      return true;
    SmallVector<SmallVector<Value *, 4>, 4> CTerms;
    SmallVector<SmallVector<Instruction *, 4>, 4> CAts;
    partitionByReducedDag(Terms, Ats, Frontier, taint, DT, CTerms, CAts);
    bool Grew = false;
    for (unsigned C = 0, E = CTerms.size(); C != E; ++C) {
      FrontierComponentPlan P;
      P.D = recoverDataDag(CTerms[C], taint, DT, &Frontier);
      SmallVector<Value *, 4> Moved;
      bool New = false;
      switch (judgeFrontierPlan(F, P.D, CAts[C], Frontier.Borrowed, Measured,
                                taint, DT, PDT, LI, IterLocal, P.At, Moved)) {
      case FrontierVerdict::Emit:
        Plans.push_back(std::move(P));
        continue;
      case FrontierVerdict::Refused:
        return false;
      case FrontierVerdict::NotClosed:
        for (Value *R : P.D.OpenRails) {
          if (!llvm::is_contained(P.D.Roots, R))
            return false;  // an open COPY (template rail): see the header
          New |= Frontier.Borrowed.insert(R).second;
        }
        break;
      case FrontierVerdict::ParentMoved:
        for (Value *Pm : Moved)
          for (CallInst *G : P.D.Calls)
            for (Value *Op : G->args())
              if (Op == Pm) {
                Value *R = railOf(G);
                if (!R || isa<Constant>(R) ||
                    !recordLiveAcrossMove(G, R, Pm, P.At, DT, taint))
                  return false;  // not a FORCED record: see the header
                New |= Frontier.Borrowed.insert(R).second;
              }
        break;
      }
      if (!New)
        return false;  // no progress — keep the decline
      Grew = true;
    }
    if (!Grew)
      return true;
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
}  // namespace

// bd p3kd.13: `GroupMode` and the group formation are TerminalGroups.h's; this
// planner stays here beside the helpers it calls. Exported for that one caller.
bool reverseTerminalGroup(Function &F, ArrayRef<CallInst *> Terminals,
                          TaintSet &taint, WidthDispatch &wd, DominatorTree &DT,
                          PostDominatorTree &PDT, LoopInfo &LI, bool IterLocal,
                          SmallPtrSetImpl<const CallInst *> &ReversedGates,
                          SmallPtrSetImpl<Value *> &ReversedRails, GroupMode Mode,
                          GroupProbe *Probe) {
  const bool Loud = Mode == GroupMode::Loud;
  const bool Probing = Mode == GroupMode::Probe || Mode == GroupMode::ProbeAsLoud;
  auto commit = [&](const DataDag &DD, Instruction *A) {  // one plan, per `Mode`
    if (!Loud && Mode != GroupMode::ProbeAsLoud &&
        !cloneTerminalReversalDisjoint(DD, ReversedGates, ReversedRails, taint))
      return false;
    if (Probing) {  // record the plan, emit nothing (TerminalGroups.h)
      Probe->addPlan(DD);
      return true;
    }
    emitTerminalReversal(DD, A, wd, taint, ReversedGates, ReversedRails);
    return true;
  };

  // 2. Classify each terminal (FreePoint owns measure/escape/loud diagnostics).
  SmallVector<Value *, 8> InsertTerms;
  SmallVector<Instruction *, 8> InsertAts;
  bool Suppressed = false;  // a reject FreePoint would have diagnosed
  for (CallInst *Term : Terminals) {
    FreePoint FP = computeFreePoint(Term, F, PDT, taint, Loud ? nullptr : &Suppressed);
    if (FP.Kind != FreePointKind::Insert)
      continue;
    InsertTerms.push_back(Term);
    InsertAts.push_back(FP.At);
  }
  if (InsertTerms.empty() || (Probing && Suppressed))
    return false;

  // 3. Recover the whole forward DAG (union over all Insert terminals).
  DataDag D = recoverDataDag(InsertTerms, taint, DT);
  // R11 r8-r9 — a probe's `Cut` is asked ONCE, of the COMMITTED plans, on every
  // path that commits: what of the whole walk `D` no plan reverse-plays, beyond
  // the own gates of the rails that hold no hazardous record (`GroupProbe::Cut`):
  // the final frontier's forced records and open roots, its measured rails that
  // are measured on EVERY path (r9 F1), and `D`'s register ROOTS (r9 F2: a
  // `cqrt_alloc` root and its in-place gates record no other register). A QRAM
  // array is never exempt, so neither is a store. A final-outcome gate set (L3),
  // so a borrow path added later is covered too.
  auto finish = [&](bool Ok, const SmallPtrSetImpl<Value *> &Borrowed) {
    if (Ok && Probing) {
      SmallPtrSet<Value *, 8> Exempt;
      for (Value *B : Borrowed)
        if (!isQramArrayHandle(B) &&
            (!D.MeasuredRails.count(B) || measuredOnEveryPath(B, PDT)))
          Exempt.insert(B);
      for (Value *R : D.Roots)
        if (isAllocMint(R) && !isQramArrayHandle(R))
          Exempt.insert(R);
      Probe->setCut(D, Exempt);
    }
    return Ok;
  };
  if (D.MeasuredUpstream) {
    // bd test_C_libtooling-01po.4 — THE QRAM-ARRAY FRONTIER RETRY. A load's
    // reversal needs the ARRAY's state at the load (and its index), not the
    // array's history; the whole-DAG walk nevertheless follows a QRAM array root
    // into its stores, and a store's index or value that the user later
    // measures (`arr[b] = 0; v = arr[p]; cq_theta(&b, -.5); measure(b)`)
    // declined the whole module — an over-decline (the same body lowers in
    // `main`). Retry ONCE with every QRAM array root BORROWED: the walk stops
    // at the array (its stores are not reversed, its cells stay as they are —
    // the owner-ruled-deferred array-record class, exactly `main`'s stream — and
    // an array handle is never freed anyway), and the borrowed array must hold
    // its load-time value at the reversal (`borrowedParentsUnmoved`, the M-B
    // clause-(d) scan, one spelling). Every other check is re-asked verbatim
    // (`planTerminalReversal`). ANY refusal keeps today's decline, character for
    // character, at the original measure — so no module that lowered before
    // changes, and the retry only ever turns a decline into an emitted reversal.
    //
    // WHY BORROWING CANNOT RE-INTRODUCE THE MEASURED REGISTER: it was reachable
    // only THROUGH the array's stores. A measured rail the reduced DAG still
    // reads directly (the load's own index measured) used to keep the decline;
    // since bd ptue it is borrowed as well (below), and
    // lowering_reject_qram_store_measured_index_load_idx_measured.ll is that
    // retry's QRAM accept.
    //
    // bd test_C_libtooling-ptue — THE MEASURED RAILS JOIN THE FRONTIER (the
    // measured-rail half of bd 01po.8). The decline protected the SPINE'S PLAN,
    // not the unitary (L5): the whole-DAG walk OWNS every rail it reaches, so a
    // dead copy `t = q ^ 9` of a measured `q` dragged `q`'s `cqrt_alloc` root
    // and prep Ry into the reversal, which would then un-rotate `q` and act on
    // it ahead of the user's measurement. `t`'s reversal never needs that — it
    // needs `q`'s LABEL, read-only. So every rail the scan saw measured
    // (`D.MeasuredRails`, recorded where `MeasuredUpstream` is decided) is
    // borrowed too: never walked, never adjointed, never freed, so no measured
    // register can be touched by the reversal at all. What CAN go wrong is the
    // label the adjoints read, and that is asked, not assumed:
    //   * `borrowedParentsUnmoved` (clause (d), one spelling): no gate moves a
    //     borrowed rail between the first DAG gate that reads it and `At`. A
    //     measurement there is refused by `preservesBorrowedParent` too
    //     (lowering_reject_uncompute_measured_parent_moved.ll pins a Ry there:
    //     the whole-group retry refuses, and since bd 01po.8 the frontier
    //     fixpoint leaves that record allocated instead of declining);
    //   * `measuredParentsReadBeforeCollapse`: no measurement of a borrowed
    //     measured rail can PRECEDE a DAG read of it. That is bd yiid, a RULED
    //     capability (2026-09-14, E3 (b) BROAD 2026-09-15) not yet built, so
    //     the refusal is a loud over-decline kept until E3 lands — see the
    //     predicate's header
    //     (lowering_reject_uncompute_measured_parent_read_after_measure.ll).
    //   * `keptRailAdjointReadsBorrowed` (bd eqti): no rail the plan reverse-
    //     plays but KEEPS (frozen by a record, an array) has an adjoint
    //     controlled by a borrowed register — that adjoint would act on the LIVE
    //     register's coherence (lowering_reject_uncompute_measured_parent_
    //     frozen_{taped,copyout}.ll). It covers the ARRAY borrow too, and that
    //     half was a PRE-EXISTING silent miscompile of the bd 01po.4 retry
    //     (lowering_reject_qram_frozen_adjoint_reads_borrowed_array.ll).
    // MONOTONE for the measured-rail borrow, so no module that lowered before
    // ptue changes through it: this branch is reached only on the way to the
    // decline below, and adding measured rails to a QRAM-only frontier that
    // already succeeded is a no-op (that DAG reached no measured rail, or it
    // would have been `MeasuredUpstream`, and a frontier member the walk never
    // reaches neither cuts it nor is scanned). The eqti conjunct is NOT
    // monotone and is not meant to be: it turns the pre-existing 01po.4
    // miscompile above from an rc-0 accept into the decline. Every refusal
    // keeps today's decline, character for character — EXCEPT that since bd
    // 01po.12/01po.8 a whole-group refusal is re-planned per component with a
    // growing frontier (`planFrontierFixpoint`), which may end with a FORCED
    // record left allocated instead of the decline (an open root, or a rail the
    // program itself keeps live across a move of its borrowed parent).
    InteriorPlan Frontier;
    for (Value *R : D.Roots)
      if (isQramArrayHandle(R))
        Frontier.Borrowed.insert(R);
    for (Value *R : D.MeasuredRails)
      Frontier.Borrowed.insert(R);
    if (!Frontier.Borrowed.empty()) {
      DataDag DR = recoverDataDag(InsertTerms, taint, DT, &Frontier);
      Instruction *AtR = nullptr;
      SmallVector<Value *, 4> Ignored;  // whole-group retry: no widening
      if (judgeFrontierPlan(F, DR, InsertAts, Frontier.Borrowed,
                            D.MeasuredRails, taint, DT, PDT, LI, IterLocal, AtR,
                            Ignored) == FrontierVerdict::Emit) {
        return finish(commit(DR, AtR), Frontier.Borrowed);
      }
      // bd test_C_libtooling-01po.12 / 01po.8 — the whole group refused; plan
      // again PER COMPONENT of the reduced DAG, each at its own reversal point,
      // growing the borrowed frontier on an open rail or a moved parent (see
      // `planFrontierFixpoint`). Reached only on the way to the decline, so no
      // module that lowered before changes. An empty plan set means every
      // terminal is a kept record: nothing is reversed, freed or diagnosed.
      SmallVector<FrontierComponentPlan, 4> Plans;
      if (planFrontierFixpoint(F, InsertTerms, InsertAts, Frontier,
                               D.MeasuredRails, taint, DT, PDT, LI, IterLocal,
                               Plans)) {
        bool All = !Plans.empty();
        for (FrontierComponentPlan &P : Plans)
          All = commit(P.D, P.At) && All;
        return finish(All, Frontier.Borrowed);  // the FINAL frontier (r8)
      }
    }
    if (Loud)
      diagnose(D.UpstreamMeasure, kMsgLineageMeasured);
    return false;
  }

  Instruction *At = nullptr;
  CallInst *Culprit = nullptr;
  switch (planTerminalReversal(F, D, InsertAts, taint, DT, PDT, LI, IterLocal,
                               At, Culprit)) {
  case TerminalPlan::Leak:
    return false;
  case TerminalPlan::DeclineUninvertible:
    if (Loud)
      diagnose(Culprit, kMsgUninvertible);
    return false;
  case TerminalPlan::DeclineDivergent:
    if (Loud)
      diagnose(Culprit, kMsgDivergentArm);
    return false;
  case TerminalPlan::Emit:
    break;
  }

  // 5. Reverse the whole DAG once at `At`.
  return finish(commit(D, At), SmallPtrSet<Value *, 1>());
}

namespace {

// ── M-B INTERIOR PARTITION (bd test_C_libtooling-6uqc Inc 5a) ────────────────

// Does `M` — a user of the BORROWED parent `P` — leave P's BASIS LABEL alone?
//
// FAILS CLOSED, and that is the whole design: the shapes below — (1)/(1b) a
// diagonal rotation, (2) a forward producer, since bd rhk5 (3) a Phase-6 clone
// call PROVEN read-only on `P`, and since bd 7xsh (4) a recorded Phase-4 flag
// strip reading `P` outside its written slot — are the ONLY ones admitted, and everything else
// counts as a mutation, a `cqrt_measure_*` included. (This sentence said "exactly
// two shapes" from Inc 5a until bd rhk5; clause (1b) had already made it three.)
// Clause (d) of the record invariant (bd memory
// [record-freeze-invariant-2026-08-10]) requires every register an adjoint reads
// to hold the value it held WHEN THE FORWARD GATE RAN; the interior partition
// cannot deliver that by reverse program order the way the whole-DAG spine does,
// because a borrowed parent is by construction NOT walked and NOT adjointed. So
// it must be proven un-mutated over the interval instead.
bool preservesBorrowedParent(const CallInst *M, const Value *P,
                             const TaintSet &taint, bool AdmitCloneCalls) {
  const Function *Callee = M->getCalledFunction();
  StringRef N = Callee ? Callee->getName() : StringRef();
  // (1) A DIAGONAL rotation. `cqrt_rz_<W>(P, θ)` writes a phase and never a basis
  //     label, so the `_unc`'s recomputation of f(P) is unaffected and the phase
  //     commutes past the XOR it applies. (This is the same reason the flag-strip
  //     is `Rz`-transparent — bd memory [rz-diag-flag-strip-invariant].)
  //
  //     ⚠ THIS ROW DELIBERATELY ADMITS A RECORDED BRANCH-PHASE (KICKBACK) GATE,
  //     AND IT MUST NOT BE NARROWED "FOR SYMMETRY" WITH THE THREE PREDICATES
  //     THAT REFUSE ONE — bd test_C_libtooling-3qlq Inc 1, Rule-13 round-2
  //     finding F-R1-4. A kickback gate is EXACTLY `cqrt_rz_i1(Flag, θ)`: prefix
  //     `cqrt_rz_`, not `_controlled`, arity 2, handle at arg 0 — so this NAME
  //     test says `true` for the same instruction `ChainWalk::isInPlaceGateOn`,
  //     `preservesBasisUnderRecord` and `EmitInverse::isInverseEmittable` were
  //     taught to refuse BY MEMBERSHIP (`!cq.branchphase`) in that same
  //     increment. Two predicates, one gate, opposite answers — and BOTH are
  //     right, because they ask different questions. Those three ask "may the
  //     spine ADJOINT this gate?", and the answer is no: its meaning is the
  //     program's answer kicked back onto an ancilla, and the adjoint cancels it
  //     exactly (F-L7-1, a CONFIRMED miscompile). This one asks "does this gate
  //     DISTURB the borrowed parent's basis label?", and the answer is no for
  //     the reason above — the gate is diagonal, whoever emitted it. It is
  //     REACHED, not hypothetical: `int f=(q>5); if (q>5){cq_phi(.25);
  //     cq_phi(.75);} else {cq_phi(.125);} return cq_measure(q+f);` discharges
  //     the `zext` rail with the FLAG as borrowed parent while that flag carries
  //     three `cqrt_rz_i1` gates and a `cqrt_x` bracket. Narrowing this row to
  //     "match" the other three would silently take that discharge away — and
  //     for the controlled twin, clause (1b) below records that the identical
  //     narrowing cost NINE modules their whole interior discharge.
  if (N.starts_with("cqrt_rz_") && !N.ends_with("_controlled") &&
      M->arg_size() == 2 && M->getArgOperand(0) == P)
    return true;
  // (1b) THE CONTROLLED DIAGONAL ROTATION `cqrt_rz_<W>_controlled(f, P, θ)` — bd
  //     drbq Inc 2a; VACUOUS since 3qlq (nothing mints it). This row WAS REQUIRED
  //     BY THAT INCREMENT, not an opportunistic widening. MEASURED: without it, nine
  //     modules lost their whole M-B interior discharge the moment the §6a
  //     peephole replaced the swap route (`lowering_mc_late_sub_after.ll` &c —
  //     the condition chain's `_unc` + `cqrt_free` pair vanished and an in-place
  //     M-C `sub` reverted to an out-of-place template), each announcing itself
  //     only as a NEW M-A warning on an otherwise rc-0 module.
  //
  //     WHY THE ROUTE DID NOT NEED IT, which is the whole point: the pre-2a
  //     stream's mutation of `P` was a `cqrt_cswap` PAIR, refused by this
  //     predicate and exempted one level up by `routeGroupFullyInside`
  //     (`TaintSet::RestoringRoutes`, M-B Increment 6 clause (d2)) — "the GROUP
  //     restores P's basis label, so an adjoint after it reads the wire the
  //     forward chain read". Control-in-place emits no group, so the exemption
  //     has to be made where the gate is, and here it is STRONGER than the
  //     group's: a controlled Rz is `diag(1, e^{iθ})` on the `f=1` branch and `I`
  //     on the `f=0` branch — DIAGONAL EITHER WAY — so P's basis label is not
  //     restored-after-being-moved, it is NEVER MOVED. Clause (d) holds
  //     pointwise, for one gate, with no group membership to prove.
  //
  //     THE HANDLE IS AT ARG 1 AND THE FENCE IS THE bd 1fim ONE. Arg 0 is the
  //     control FLAG, so reading arg 0 would answer this question about the wrong
  //     register (the widened-one-set-not-the-other hole); VOID + arity-3 keeps a
  //     non-void or off-arity same-named fake out, exactly as `isInPlaceGateOn`
  //     and `preservesBasisUnderRecord` do for their `_controlled` arms.
  //     `ends_with`, never `contains`, keeps the `_controlled_inv` reserve out.
  //
  //     The `ry` twin is NOT admitted and must never be: a controlled Ry relabels
  //     P on the `f=1` branch, which is precisely the mutation clause (d) exists
  //     to refuse.
  if (N.starts_with("cqrt_rz_") && N.ends_with("_controlled") &&
      M->getType()->isVoidTy() && M->arg_size() == 3 &&
      M->getArgOperand(1) == P)
    return true;
  // (2) A FORWARD reassigning producer. `cq_template_*` / `cqrt_qram_load_<W>`
  //     READ every operand and mint a FRESH result rail; there is no mutating
  //     slot. This is the shape every recovered gate of the interior DAG has, so
  //     the group's own forward gates are admitted here without a special case.
  if (isTemplateProducer(M))
    return true;
  // (3) A PHASE-6 CLONE CALL whose callee body PROVABLY never writes the formal
  //     it binds `P` to — bd test_C_libtooling-rhk5, and the reason is (2)'s,
  //     one call deep. `s = h(m, q)` with `h(a,k){return k+1;}` sat between a
  //     derived chain (`p = q*3; u = p^q`) and the chain's kickback consumer; this
  //     predicate refused the call as a mutation of the borrowed parent `q`, the
  //     component leaked, and `3q`, `3q^q` stood allocated and ENTANGLED across
  //     the later `@cq_theta_*(q, .7)` (Rule 8; `opt` exit 0 with the lyyf-(B)
  //     warning). The hand-inlined twin puts `cq_template_add_i32_hl(q, 1)` in the
  //     same place — admitted by (2) — and discharged both rails. The call's
  //     effect on `P` is NOT assumed from the name or from the Bennett wrap's
  //     design: `cloneCallPreservesArg` (ChainWalk.h) walks the callee body and
  //     fails closed, keyed on the specializer's record. What it proves is exactly
  //     what clause (d) needs — `P`'s LABEL after the call is its label before —
  //     and nothing about position, which a user that never moves the label does
  //     not need (it is harmless anywhere in the window, like (1)/(2)). Every
  //     OTHER user of `P` is still scanned by the caller exactly as before.
  //
  //     GATED BY `AdmitCloneCalls` (bd rhk5 round 2): OFF is the pre-rhk5
  //     planner verbatim, which `collectInteriorPlans` runs beside the ON mode so
  //     that no discharge the pre-rhk5 planner made can be lost.
  if (AdmitCloneCalls && cloneCallPreservesArg(M, P, taint))
    return true;
  // (4) AN EMITTER-RECORDED PHASE-4 FLAG STRIP THAT READS `P` IN A HANDLE SLOT —
  //     bd test_C_libtooling-7xsh, and the reason is (2)'s, read in reverse. The
  //     strip `cq_template_<cmp>_<W>_hl_unc(flag, P, k)` XORs `cmp(P, k)` onto
  //     its slot-0 flag and READS every other slot: it is Σ_p |p><p|_P ⊗
  //     X_flag^{cmp(p,k)}, block-diagonal in P's computational basis, so P's
  //     LABEL after it is its label before — all clause (d) asks of a gate in
  //     the window (the `_unc`s this partition emits are label-only readers;
  //     see `routeGroupFullyInside`'s header). MEASURED customer: a depth-2
  //     phase nest whose INNER compare reads the outer chain's source `q`
  //     (`d = q*3; if (d > 5) { cq_phi(b); if (q < 9) cq_phi(a); }`) puts the
  //     inner strip `icmp_slt_i32_hl_unc(f2, q, 9)` inside the outer chain's
  //     window, and refusing it left `q*3` allocated and entangled with `q`
  //     (stage 2b: 1 template rail left dirty; control_swap_nested_phase_
  //     derived.ll, which this row now discharges).
  //
  //     ⚠ IT HAS A SECOND CUSTOMER, AND THIS ROW WIDENED IT TOO (Rule-11 round 1,
  //     finding F1 — disclosed here, L9). `borrowedParentsUnmoved` is also
  //     asked by the dead-terminal FRONTIER RETRY in `reverseTerminalGroup`
  //     (bd 01po.4's array borrow, bd ptue's measured-rail borrow). A dead copy
  //     `t = q ^ 9` of a measured `q`, minted BEFORE a phase region on `q`, has
  //     the region's recorded strip inside its window; it declined before this
  //     row and now lowers, correct by the same algebra
  //     (lowering_uncompute_measured_parent_strip_in_window.ll, with its trace).
  //     The retry's own fences (`measuredParentsReadBeforeCollapse`,
  //     `keptRailAdjointReadsBorrowed`) are asked after this scan, unchanged.
  //
  //     THE SAME PREDICATE AS `isInteriorConsumer`'s clause (c), asked, not
  //     re-spelt (`isRecordedStripReaderOf`), and its three fences are this
  //     row's fences:
  //       * SLOT 0 REFUSED: a strip whose FLAG is `P` writes `P` (it zeroes it),
  //         which is exactly the mutation clause (d) exists to refuse. It is
  //         UNREACHABLE today, stated so a green suite is not read as a test of
  //         it: a borrowed parent must be in `taint.Tainted`, and every recorder
  //         (AngleSelect / SwapRoute / SwitchRoute) strips a flag it minted
  //         through `lowerCompareToFlag`, which never enters `Tainted` (the one
  //         tainted-flag minter, `GuardedStoreArmEmit`, records nothing). The
  //         tainted flag clause (1) cites — the `zext(flag)` rail of
  //         `int f=(q>5); if (q>5){…} return cq_measure(q+f);` — is the
  //         condition's own DATA compare, and is never stripped (measured). The
  //         fence is the shared `isUncHandleSlot` one, defence in depth, and no
  //         mutant of it can be killed until a recorder strips a tainted flag;
  //       * a `_controlled_unc` or literal slot: `isUncHandleSlot` fails closed;
  //       * MEMBERSHIP: an unrecorded `_unc` — a spine adjoint, a 7.4
  //         reverse-play, a hand-written call — is NOT admitted, though the same
  //         algebra holds for any out-first `_unc`; kept out until a customer is
  //         measured, because those are adjoints another owner is still
  //         executing (clause (c)'s reason). Pinned by
  //         lowering_uncompute_interior_leak_unrecorded_strip_reads_parent.ll.
  if (isRecordedStripReaderOf(M, P, taint))
    return true;
  // Everything else is a mutation for this purpose: `cqrt_ry_` (the chained
  // theta) and `cqrt_ry_<W>_controlled` (the drbq Inc-1 control-in-place arm —
  // NON-diagonal, it really does relabel P on the `f=1` branch),
  // `cqrt_addc/xorc_` and `cqrt_qram_store_` (in-place relabelling),
  // `cqrt_x` / `cqrt_cswap` / `cqrt_cnot` / `cqrt_toffoli` (routes and targets),
  // a `cqrt_copy_*` destination, every `_unc`/`_inv` adjoint OTHER than a
  // recorded strip reading `P` purely (row (4)), a `cqrt_free`, and
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
// WHY THE PRE-2a PHASE-ARM ROUTE RESTORED THE LABEL. `SwapRouteEmit`'s phase path
// emitted, per content arm, one `cqrt_cswap(flag, P, rail)` to route in and the SAME call
// again to route back (RSSA: the join is the literal adjoint of the split). If
// the flag is set `P` and the rail exchange and exchange back; if it is clear
// neither call moves anything. In the if/else shape the second arm's pair is
// bracketed by `cqrt_x(flag)` so it fires on the complement, and at most one of
// the two pairs is ever active, so they commute. Either way `P` leaves the group
// holding the label it entered with.
//
// WHAT SAT BETWEEN THE HALVES, LISTED FROM THAT EMITTER'S STREAM RATHER THAN
// FROM A SLOGAN. Three kinds of gate, and none of them changes `P`'s label:
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
// arm's ANSWER, so `P`'s label genuinely changes — which is why that (pre-3qlq)
// emitter recorded nothing.
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
// ⚠ THIS FUNCTION HAS NO LIVE CUSTOMER AT HEAD, AND THE REASON IS THE POINT (bd
// test_C_libtooling-drbq Inc 2a). `TaintSet::RestoringRoutes` had exactly ONE
// writer — `SwapRouteEmit::emitRegion`'s phase path — and Inc 2a replaced that
// path's `cqrt_cswap` route with a single `cqrt_rz_<W>_controlled`, so the set is
// now permanently EMPTY and the loop below never iterates. Nothing else records a
// group: the one remaining `emitRoute` caller, the 7.2 abort park, does not (nor
// did the pre-3qlq 4.3 nest, 4.5 switch and method-B value arm, the last
// deliberately — its route-back carried the arm's ANSWER, not a restoring group).
//
// AT Inc 2a THE EXEMPTION MOVED TO THE GATE, and got STRONGER there: clause
// (d)'s phase-path customers (`lowering_uncompute_interior_region_*.ll`) were
// served by clause (1b); since 3qlq the kickback puts no gate on `P` at all (its
// `cqrt_rz_i1` lands on the flag). (1b): a controlled Rz is `diag(1, e^{iθ})` on
// the `f=1` branch and `I` on `f=0`, DIAGONAL EITHER WAY, so `P`'s basis label is
// not restored-after-being-moved, it is NEVER MOVED. That holds POINTWISE, with
// no group membership and no atomicity fence to prove. MEASURED: every one of
// those fixtures keeps its discharge at the same position, and the whole 1358-
// fixture corpus is diagnostic-identical to the pre-2a binary. (1358, not 1356 —
// re-measured `ls ir-pass/test/*.ll | wc -l` at the Inc-2a round-1 review, L3 F7.
// The number is a MEASURED claim inside a Rule-13 justification; re-measure it
// rather than carrying it forward.)
//
// IT IS KEPT, NOT DELETED, and this comment is the price of keeping it. Deleting
// it would remove the only written statement of WHY a route pair may be read
// across (the F4a / Increment-6 argument), and the route is still emitted by
// the 7.2 abort park (`AbortParkEmit`), which could start recording. If you
// re-enable a writer, re-read the atomicity and homogeneity fences below FIRST;
// they are unchanged and still correct. If you delete it, delete
// `RestoringRoutes` and its scrub in `SwapRouteEmit::scrubTaint` together.
// (`lowering_uncompute_interior_leak_route_in_interval.ll` was this function's
// leak pin; its route retired with drbq Inc 2a, its strip became the refuser,
// and since bd 7xsh row (4) of `preservesBorrowedParent` admits that strip, so
// the file is an ACCEPT and pins nothing here.)
bool routeGroupFullyInside(const CallInst *M, const Value *P, CallInst *First,
                           Instruction *At, const DominatorTree &DT,
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
  // `cqrt_cswap(flag, a, b)` is physically symmetric in `a`/`b`. The read was safe
  // because the convention had exactly ONE owner — the pre-2a `emitRegion` phase
  // path, the only writer `RestoringRoutes` ever had, which built `{Flag, Q,
  // Rail}` and asserted it at the record site. An emitter that records a group
  // with the base in arg 2 must update both places.
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

}  // namespace

// THE WINDOW SCAN — "does any gate move `P`'s basis label strictly inside
// `(First, At)`?" — hoisted out of `borrowedParentsUnmoved` VERBATIM by bd
// test_C_libtooling-cmr9 so the M-A live-record guard's clause 4
// (`RotationLowering`'s `recordIsExemptAt`) asks the SAME question about a
// measured record (Rule 12, one spelling). Declared in Uncomputation.h, where the
// contract is stated; the argument for each leg is at the leg, below.
//
// PRECONDITION, met by every caller before asking: `First` DOMINATES `At` and
// `First != At` (`borrowedParentsUnmoved` proves both from §4; the clause-4
// caller from `provablyBeforePerActivation(First, At, …)` and a measurement
// never being a rotation).
bool railUnmovedInWindow(Value *P, CallInst *First, Instruction *At,
                         const DominatorTree &DT, const TaintSet &taint,
                         bool AdmitCloneCalls, const Instruction *Opener) {
  // Proven ONCE per (`First`, `At`) pair and read by `routeGroupFullyInside`'s
  // `At`-barriered leg 1 below — see `WireWalk.h`'s `intervalAlternates` for
  // the window argument, and for why the `First`-barriered legs (that leg's
  // sibling, and (W2) here) do not need it. The dominance half it assumes
  // (`First` dominates `At`) is the PRECONDITION above.
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
    // The window's own opening event, which the caller vouches does not move
    // `P` (bd cmr9: clause 4's measurement of `P`). Asked of it, (W2) below is
    // `everyPathReExecutes(First, At, First)`, which starts its walk AFTER
    // `First` and so fails on every straight path: the window is OPEN at
    // `First`, and the opener is not inside it. `borrowedParentsUnmoved` passes
    // null and is unchanged — its `First` is a DAG gate that may write `P`.
    if (M == Opener)
      continue;
    if (!DT.isReachableFromEntry(M->getParent()))
      continue;  // a mutation that can never execute cannot move P. Vacuous
                 // truth is the SAFE direction here — unlike in the anchor
                 // scan, where it would have hidden a missing proof — but it is
                 // made explicit so the two uses of reachability are not read
                 // as one rule.
    if (preservesBorrowedParent(M, P, taint, AdmitCloneCalls))
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
    //   * the ROLLED LEADING GATE (F-4). `for(…){ cq_theta(&q,a);
    //     if((q&3)==1){…} cq_theta(&q,b); }` — the NEXT iteration's leading
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
  return true;
}

namespace {

// CLAUSE (d) FOR A BORROWED FRONTIER (§5 of `planInteriorComponent`, hoisted
// VERBATIM into a function by bd test_C_libtooling-01po.4 so the dead-terminal
// driver's QRAM-array retry asks the SAME question — Rule 14, one spelling).
// True iff every borrowed parent `P` in `Borrowed` that some gate of `D` reads
// holds, at every emitted `_unc`, the value it held when that gate ran: every
// user of `P` is proven label-preserving (`preservesBorrowedParent`) or outside
// the window `(First, At)` (the (W2) certificate) or a complete recorded route
// (clause (d2)). The per-user scan is `railUnmovedInWindow` (above; bd cmr9
// moved it out verbatim so the M-A guard can ask it too).
//
// PRECONDITION, and both callers meet it before asking: every gate of `D`
// DOMINATES `At` — §4's `DT.dominates(G, At)` scan in the interior planner, the
// `NonDominating` test in `reverseTerminalGroup`. The `First != At` note below
// relies on it; "§4 above" in that note means whichever of the two ran.
bool borrowedParentsUnmoved(const DataDag &D,
                            const SmallPtrSetImpl<Value *> &Borrowed,
                            Instruction *At, DominatorTree &DT,
                            const TaintSet &taint, bool AdmitCloneCalls,
                            SmallVectorImpl<Value *> *Moved) {
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
    if (!railUnmovedInWindow(P, First, At, DT, taint, AdmitCloneCalls,
                             /*Opener=*/nullptr)) {
      if (!Moved)
        return false;
      Moved->push_back(P);
    }
  }
  return !Moved || Moved->empty();
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
                           LoopInfo &LI, RepeatOracle &canRepeat,
                           const SmallPtrSetImpl<const CallInst *> &ReversedGates,
                           const SmallPtrSetImpl<Value *> &ReversedRails,
                           DataDag &D, Instruction *&At,
                           SmallPtrSetImpl<Value *> &BorrowedOut,
                           bool AdmitCloneCalls) {
  SmallPtrSet<Value *, 16> Owned(Comp.begin(), Comp.end());
  bool Converged = false;
  for (unsigned Round = 0; Round < 8 && !Owned.empty(); ++Round) {
    SmallVector<Instruction *, 16> Anchors;
    for (CallInst *R : Comp) {
      if (!Owned.count(R))
        continue;
      for (User *U : R->users()) {
        // bd `test_C_libtooling-tu9q` P2 — see `anchorForConsumer`. For a
        // consumer that shares a cycle with the mint (and for every acyclic
        // module) this IS `U->getNextNode()`, expression for expression.
        Instruction *A = anchorForConsumer(cast<Instruction>(U), R, LI);
        if (!A)
          return false;  // no usable once-per-mint point — LEAK (Rule 6).
        Anchors.push_back(A);
      }
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
        //
        // bd `test_C_libtooling-6n1s` — ASKED THROUGH `useCompleteBeforeDischarge`
        // SINCE 2026-09-18, which opens with this exact call and then admits ONE
        // further shape: a use that need not EXECUTE, inside the SAME marked body
        // as the mint and the discharge. See that helper for why dominance is not
        // the obligation here, and for the §4 half that keeps the ADJOINTED gates
        // under the full test.
        if (!useCompleteBeforeDischarge(cast<Instruction>(U), At, R, DT, LI,
                                        taint)) {
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
  IP.AdmitCloneCalls = AdmitCloneCalls;
  BorrowedOut.insert(Borrowed.begin(), Borrowed.end());  // P0's ordering check.
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
    if (!cloneGatePreservesBasis(G, taint))  // bd p3kd.13: a clone producer too
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
    // ── THE MULTIPLICITY TEST (bd `test_C_libtooling-tu9q` P1, 2026-09-18) ────
    //
    // ⚠⚠ **THE PARAGRAPH THAT STOOD HERE PREDICTED THIS CODE AND IS NOW
    // SUPERSEDED BY IT** (bd `test_C_libtooling-8h7d.5` round-5 cleanup wrote it;
    // bd `test_C_libtooling-8h7d.10` tracked it). It said, correctly: the test
    // above and §2.9's twin below each ask ONE endpoint whether IT repeats, never
    // whether the two repeat the SAME NUMBER OF TIMES — a recovered gate `G` in
    // the loop PREHEADER passes here (a preheader does not repeat) while `At`
    // sits in an ITERATION-LOCAL body and passes §2.9 (a marked body is the
    // affirmative exception), and the adjoint would then run K times against ONE
    // forward execution of `G`: an over-reversed rail, a WRONG UNITARY, not
    // merely a leak. It then said the pairing could not arise because
    // `markIfRailLocal` refuses to mark a body that reads an outside-`L` tainted
    // non-rail value, and ended: *"If you are here because you relaxed it, the
    // obligation is a real multiplicity test (same enclosing marked body, or
    // equal trip multiplicity), not a re-reading of these two."*
    //
    // We are here because of that, twice over. bd `tu9q`'s P2 loop-EXIT anchor
    // creates the MIRROR pairing the old note did not name — a body gate `G` with
    // an `At` at the loop EXIT, i.e. ONE adjoint against K forward executions —
    // and bd `tu9q`'s clause (ii-d) widens the marking the old argument leaned on.
    // Both directions are refused by ONE line, which is the multiplicity test the
    // note asked for, spelled as "same enclosing marked body" via a NULLABLE key.
    //
    // ⚠ IT IS A BACKSTOP, NOT THE PLACEMENT. A refusal here LEAKS the component
    // (Rule 6's fallback), which is the safe direction and never a diagnostic;
    // the correct placement is P2's business. Read the two together: P2 proposes
    // a point, this refuses every pairing whose endpoints do not repeat alike.
    //
    // ⚠ THE PREHEADER DIRECTION IS STILL UNREACHABLE TODAY, and that is stated so
    // nobody reads a green suite as evidence the test is dead: the convergence
    // loop above DROPS a preheader-minted rail whose consumer is in the body
    // (`provablyBeforePerActivation` succeeds on the back-edge path, the helper
    // returns false, `Owned.erase`), so the pairing never reaches §4. P2 changes
    // that for the rails it re-anchors, which is why the two land together.
    if (!multiplicityAgrees(G, At, LI, taint))
      return false;
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
  // bd `test_C_libtooling-tu9q` P1 — THE SAME MULTIPLICITY TEST ON THE FINAL
  // `At`, against every recovered gate. §4 above ran it too, but `At` is
  // re-derived by the convergence loop and a component that converged on a
  // SMALLER `Owned` set can reach here with a different point than the one §4
  // saw, so the property is re-asked where it is FINAL. The "affirmative
  // exception" the clause above grants is exactly the one this narrows: a marked
  // `At` is admissible only against gates that repeat with it.
  for (CallInst *G : D.Calls)
    if (!multiplicityAgrees(G, At, LI, taint))
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
  //             Symptom when it is missed: `for(…){ cq_theta(&q,a);
  //             if((q&3)==1){cq_phi(PI);} cq_theta(&q,b); }` leaves the
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
  //    `clang -O1` ROUTINELY SINKS a derived chain PAST a control region.
  //    Source order `x = sqrt(a+3.0); if (a > 2) { … }` arrives with the whole
  //    `x` chain AFTER the region (measured: `a9b_after_region.c`), so `First`
  //    is after the region and whatever it wrote on the wire is to `First`'s
  //    LEFT — admitted by LEFT, not RIGHT. (Measured pre-3qlq on the swap route,
  //    sound because its `cqrt_cswap` pair self-cancels: the second restores the
  //    basis label the first exchanged.) What is NOT admitted is a label
  //    MUTATION strictly inside the interval — that satisfies neither disjunct
  //    and leaks (lowering_uncompute_interior_leak_parent_ry_between.ll; the
  //    route-in-interval pin that used to stand here accepts since bd 7xsh,
  //    because its in-interval user is now a recorded strip, row (4) of
  //    `preservesBorrowedParent`). The interval, not the source line, is what
  //    this scan reasons about.
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
  if (!borrowedParentsUnmoved(D, Borrowed, At, DT, taint, AdmitCloneCalls))
    return false;  // unprovable ⇒ this component leaks (Rule 6).

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
  // bd `test_C_libtooling-tu9q` P0 — the component's BORROWED frontier, carried
  // out of `planInteriorComponent` so the cross-plan ordering check below can ask
  // *"does this plan's adjoint READ a rail another plan will free?"* without
  // re-deriving the frontier (Rule 14: one spelling, computed where it is proved).
  SmallPtrSet<Value *, 8> Borrowed;
};

// A plan's DISCHARGED set: the rails it will adjoint AND free (a frozen rail is
// adjointed but kept — `emitDagReversal` — so it does not count as freed).
void addDischargedRails(const ComponentPlan &P, SmallPtrSetImpl<Value *> &Into) {
  for (Value *R : P.D.Rails)
    if (!P.D.FrozenRails.count(R))
      Into.insert(R);
}

// `AdmitCloneCalls` (bd rhk5): ON, a Phase-6 clone call proven read-only is an
// interior consumer (`isInteriorConsumer` (b′)) and a harmless user of a borrowed
// parent (`preservesBorrowedParent` (3)); OFF, this function is the pre-rhk5
// planner verbatim. `collectInteriorPlans` below runs both — see its note.
void collectInteriorPlansMode(Function &F, TaintSet &taint, DominatorTree &DT,
                              PostDominatorTree &PDT, LoopInfo &LI,
                              const SmallPtrSetImpl<const CallInst *> &ReversedGates,
                              const SmallPtrSetImpl<Value *> &ReversedRails,
                              SmallVectorImpl<ComponentPlan> &Plans,
                              bool AdmitCloneCalls) {
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
      if (!isInteriorTerminalHandle(H, taint, AdmitCloneCalls))
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
  // The component partition, as a function of the rail set it may use. The
  // ALLOWED set is `Anchorable` for the primary partition; bd rhk5 round 2 (bd
  // `kyy1`) also asks it of a component MINUS its (b′)-admitted rails — the
  // pre-rhk5 partition of that component — so the SAME linking rules produce
  // both, one spelling (Rule 14).
  auto buildComponents = [&](const SmallPtrSetImpl<Value *> &Allowed,
                             SmallVectorImpl<SmallVector<CallInst *, 8>> &Components) {
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
      if (!Allowed.count(R))
        continue;
      // ── P0 (bd `test_C_libtooling-tu9q`): DO NOT MERGE ACROSS A MULTIPLICITY
      //    BOUNDARY, and this ARGUES WITH the written invariant twelve lines up
      //    rather than waiving it ────────────────────────────────────────────
      //
      // That invariant says *"NEVER FINER THAN A COMPONENT. Two rails joined by a
      // producer edge share a DAG and may share a borrowed parent whose interval
      // is the UNION of theirs; splitting them would let one be freed while the
      // other's adjoint still reads it (Rule 8's shared prefix)."* The partition
      // below IS finer, so the hazard it names must be DISCHARGED, not ignored —
      // it is, by the cross-plan ORDERING CHECK after the planning loop, and that
      // check is what licenses this line.
      //
      // WHY THE SPLIT IS NEEDED AT ALL. Piece P3 admits a hoisted `cq_template_*`
      // rail as a Root, which lets `markIfRailLocal` mark the body — and then a
      // body-minted rail and a PREHEADER-minted one land in ONE component with ONE
      // `At`, for which there is no right point: the preheader rail ran ONCE and
      // the body rail ran K times. P1's multiplicity test then refuses the whole
      // component and BOTH leak — which is §0.1(b)'s over-accept, since the
      // marking has meanwhile silenced conjunct (1) of
      // `declineDephasingUnmarkedLoopRails`. Split on the SAME key P1 refuses on
      // (`markedHeaderOf`, ONE spelling, two customers — Rule 14) and each half
      // gets the point that is right for it: the body half per trip, the preheader
      // half once at the loop exit.
      //
      // ⚠ THE KEY IS THE MINT BLOCK'S, NOT THE GATE'S. Two rails belong together
      // iff they REPEAT together, which is a property of where they are MINTED.
      auto sameMultiplicity = [&](const Value *A, const Value *B) {
        const auto *AI = dyn_cast<Instruction>(A);
        const auto *BI = dyn_cast<Instruction>(B);
        if (!AI || !BI)
          return false;  // unclassifiable — do not merge (the finer, and here the
                         // conservative, direction: an unmerged pair is planned
                         // separately and each half re-proves everything).
        return markedHeaderOf(AI->getParent(), LI, taint) ==
               markedHeaderOf(BI->getParent(), LI, taint);
      };
      auto link = [&](const CallInst *G) {
        for (Value *Op : G->args())
          if (Op != R && Allowed.count(Op) && sameMultiplicity(R, Op))
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
      if (!Allowed.count(R))
        continue;
      unsigned Id = CompOf[R];
      auto It = Slot.find(Id);
      if (It == Slot.end())
        It = Slot.insert({Id, Components.size()}).first, Components.emplace_back();
      Components[It->second].push_back(R);
    }
  };
  SmallVector<SmallVector<CallInst *, 8>, 4> Components;
  buildComponents(Anchorable, Components);

  // Plan EVERY component before ANY of them emits — see the note above.
  //
  // ── bd rhk5 round 2 (bd `kyy1`, r1B F-r1B-1, a P1): THE PER-COMPONENT
  //    FALLBACK TO THE PRE-rhk5 PARTITION ─────────────────────────────────────
  //
  // Clause (b′) makes a rail whose consumer is a clone call an OWNED interior
  // member. That rail then joins its siblings' component, and the component's
  // ONE discharge point is anchored after ALL consumers of ALL owned rails —
  // including the clone call. When that call sits after a non-diagonal gate on
  // the component's borrowed parent, clause (d) refuses the WHOLE component and
  // a DEAD sibling the pre-rhk5 planner discharged alone now leaks, entangled:
  // `p = q & 3; u = p + q; if (u == 10) cq_phi(PI); q2 = q; cq_theta(&q2, .7);
  // s = h(m, p);` — the oracle discharges `u` before the Ry, round 1 left it
  // standing (the user's phase oracle erased; r1B's `b2n`).
  //
  // The fix plans the component both ways and keeps whichever discharges MORE:
  // the (b′) component as one plan, or the pre-rhk5 partition of the same
  // component — its rails minus the (b′)-admitted ones (`isInteriorTerminalHandle`
  // asked with (b′) OFF, the ONE owner), linked by the SAME rules
  // (`buildComponents`), each piece planned on its own, the (b′) rails left as
  // borrowed parents. The (b′) plan wins only when its discharged set is a
  // SUPERSET of the fallback's, so no rail the pre-rhk5 partition discharges is
  // lost PER COMPONENT. (Every pre-rhk5 component lies inside exactly one (b′)
  // component, because (b′) only ADDS rails and therefore only ADDS links.)
  //
  // ⚠ PER COMPONENT IS NOT THE WHOLE GUARANTEE, and the whole one is not made
  // here: the cross-plan ordering check below can DROP a plan because of another,
  // and clause (3) can make a piece plan exist that the pre-rhk5 planner refused —
  // which can then drop an OUTER plan that planner kept. The function-level
  // guarantee is `collectInteriorPlans`' comparison of the two FINAL plan sets.
  // This per-component step exists so that one (b′) regression does not cost the
  // (b′) wins elsewhere in the same function.
  //
  // ⚠ It compares exactly TWO candidates — every (b′) rail owned, or none — and
  // searches no subset. A mixed plan (demote only the (b′) rail whose clone consumer
  // lies past the non-diagonal gate) can satisfy clause (d) where both candidates
  // fail; it is then a MISSED WIN, never a regression (r2A F-r2A-3, probe `f2.c`,
  // byte-identical to the oracle; filed as bd `test_C_libtooling-ezyg`).
  //
  // What this does NOT fix, stated: the hand-inlined TWIN of `b2n` (`s = p + 1`)
  // leaks `u` the same way on BOTH binaries — its `p` is interior through a
  // template consumer, with no (b′) involved. That granularity defect is
  // PRE-EXISTING and stays filed under bd `kyy1`; this fallback only guarantees
  // that (b′) never makes a program worse than the pre-rhk5 planner made it.
  for (SmallVector<CallInst *, 8> &Comp : Components) {
    ComponentPlan P;
    P.At = nullptr;
    const bool Ok =
        planInteriorComponent(Comp, taint, DT, PDT, LI, canRepeat, ReversedGates,
                              ReversedRails, P.D, P.At, P.Borrowed,
                              AdmitCloneCalls);
    if (AdmitCloneCalls) {
      SmallPtrSet<Value *, 16> PreRhk5;  // the component's non-(b′) rails
      for (CallInst *R : Comp)
        if (isInteriorTerminalHandle(R, taint, /*AdmitCloneCalls=*/false))
          PreRhk5.insert(R);
      if (PreRhk5.size() != Comp.size()) {
        SmallVector<SmallVector<CallInst *, 8>, 4> Pieces;
        buildComponents(PreRhk5, Pieces);
        SmallVector<ComponentPlan, 4> PiecePlans;
        SmallPtrSet<Value *, 16> PieceRails;
        for (SmallVector<CallInst *, 8> &Piece : Pieces) {
          ComponentPlan Q;
          Q.At = nullptr;
          if (planInteriorComponent(Piece, taint, DT, PDT, LI, canRepeat,
                                    ReversedGates, ReversedRails, Q.D, Q.At,
                                    Q.Borrowed, AdmitCloneCalls)) {
            addDischargedRails(Q, PieceRails);
            PiecePlans.push_back(std::move(Q));
          }
        }
        SmallPtrSet<Value *, 16> FullRails;
        if (Ok)
          addDischargedRails(P, FullRails);
        bool FullWins = Ok;
        if (FullWins)
          for (Value *R : PieceRails)
            if (!FullRails.count(R)) {
              FullWins = false;
              break;
            }
        if (!FullWins) {
          for (ComponentPlan &Q : PiecePlans)
            Plans.push_back(std::move(Q));
          continue;
        }
      }
    }
    if (Ok)
      Plans.push_back(std::move(P));
  }

  // ── P0's OBLIGATION (bd `test_C_libtooling-tu9q`): THE CROSS-PLAN ORDERING
  //    CHECK THAT DISCHARGES "NEVER FINER THAN A COMPONENT" ──────────────────
  //
  // The multiplicity split above lets one rail be planned separately from a rail
  // it BORROWS. The invariant it argues with names exactly one hazard: *"splitting
  // them would let one be freed while the other's adjoint still reads it (Rule 8's
  // shared prefix)"*. Concretely, for `int p = y*3; for(k) if ((p>>k)&1) …`: the
  // BODY plan's per-trip `and_unc(h2, h1, …)` READS `h1`, and the PREHEADER plan's
  // `cqrt_free(h1)` must follow EVERY execution of it. The split does not make
  // that true; this check PROVES it, and DROPS the outer plan where it cannot.
  //
  // ⚠ IT IS `provablyBefore`, AND IT IS **NOT** "THE EXIT POST-DOMINATES THE
  // BODY". That sentence is true here and it is NOT the property being relied on.
  // A zero-trip guarded loop's body does not dominate its exit — and that case is
  // FINE, because a body that never runs mints no rail for the outer adjoint to
  // read. What is needed is the other direction: IF the inner adjoint runs, it
  // runs BEFORE the outer one, and the outer one cannot get back to it. That is
  // `DT.dominates(At_inner, At_outer) && !isPotentiallyReachable(At_outer,
  // At_inner)` — `provablyBefore` exactly — and the code must say which property
  // it relies on, because the two are confusable and only one is sound.
  //
  // ⚠ THE DROP IS THE **OUTER** PLAN, and the direction is not arbitrary: the
  // outer plan is the one whose free would strand a live reader. Dropping it
  // leaves that rail ALLOCATED (Rule 6's fallback) while the inner plan still
  // discharges — strictly better than abandoning both, and never a dirty free.
  //
  // ⚠ WHY IT IS SAFE TO ASK AFTER PLANNING AND BEFORE EMISSION, and why a
  // "plan, emit, then re-plan the dropped rails" spelling was CONSIDERED AND
  // REJECTED (recorded so the next agent does not re-derive it as an
  // optimisation): "PLAN ALL, THEN EMIT ALL" is what makes the split legal at all
  // — at plan time the body plan's clause-(d) scan over `h1` sees only the FORWARD
  // `and`, not the preheader plan's not-yet-emitted `mul_unc`/`free`. A second
  // planning pass would see the first pass's `_unc`s as users of `h1` and refuse.
  SmallPtrSet<const ComponentPlan *, 4> Dropped;
  for (const ComponentPlan &Outer : Plans) {
    for (const ComponentPlan &Inner : Plans) {
      if (&Inner == &Outer || Dropped.count(&Outer))
        continue;
      // Does `Inner`'s adjoint READ a rail `Outer` owns and will free?
      bool Reads = false;
      for (Value *B : Inner.Borrowed)
        if (Outer.D.Rails.count(B)) {
          Reads = true;
          break;
        }
      if (!Reads)
        continue;
      if (!provablyBefore(Inner.At, Outer.At, DT))
        Dropped.insert(&Outer);
    }
  }
  if (!Dropped.empty()) {
    SmallVector<ComponentPlan, 4> Kept;
    for (ComponentPlan &P : Plans)
      if (!Dropped.count(&P))
        Kept.push_back(std::move(P));
    Plans = std::move(Kept);
  }
}

// ── bd rhk5 round 2 (bd `kyy1`, r1B F-r1B-1, a P1): NEVER WORSE THAN PRE-rhk5,
//    CHECKED ON THE FINAL PLAN SETS ────────────────────────────────────────────
//
// The interior planner is run twice — ON (clone calls admitted, with the
// per-component fallback) and OFF (the pre-rhk5 planner verbatim) — and ON is
// used only when the rails it discharges are a SUPERSET of the rails OFF
// discharges; otherwise OFF is used, i.e. the function lowers exactly as it did
// before rhk5. Both runs are pure analysis (plan all, then emit — the note at
// `collectInteriorPlansMode`'s component loop), so asking twice changes nothing
// but the cost, and the comparison is on the FINAL sets, after the cross-plan
// ordering check, which is the only place a plan can be lost to another.
//
// It is a BACKSTOP to the per-component fallback, not a replacement: that step
// makes ON a superset in the common case (r1B's `b2n` family, measured), and
// this one makes "never worse" a checked property rather than an argued one.
// Granularity is the FUNCTION, so where ON loses a discharge OFF makes, every
// rhk5 win in the same function is given up too — the safe direction, and a
// candidate for a finer rule if a customer ever shows up (none measured).
//
// ⚠ SCOPE OF "CHECKED" (bd rhk5 Rule-13 r2A F-r2A-4, L7): the comparison is made on
// the module THIS CALL sees. `planInteriorDischarges` calls this same wrapper in the
// M-C late round (`ArithLowering`, arm (d2)), one stage EARLIER, on the module BEFORE
// M-C converts a reassignment in place; the OFF run inside `uncompute` then plans on
// a module the pre-rhk5 compiler would not have produced. So "never worse than
// pre-rhk5" is checked per call, not end to end. Why that is still safe is ARGUED
// (r2A, not constructed; two probes never reached a conversion): M-C converts only
// when every prior reader is discharged by the chosen plan provably before the
// in-place gate; a later flip to OFF leaves that record live — a leak with the
// out-of-place spelling's entanglement, never a dirty free — and every plan re-runs
// clause (d) against the new in-place gate, so no `_unc` reads a relabelled register.
//
// ⚠ THIS LAYER IS UNPINNED (r2A F-r2A-1, P2, disclosed). Mutant R9 (the comparison
// removed) moves 0 of 3,384 corpus modules and fails no fixture. Its customer, argued
// in TRACK_RHK5.md §R2.2, is a clause-(3)-enabled PIECE plan that, as an INNER plan
// reading an OUTER plan's rail, makes the cross-plan ordering check drop the outer
// plan — which needs a multiplicity split (a marked loop body) and a loop exit the
// body's discharge point does not dominate. r2A wrote 13 C programs for it
// (`review_r2A_rhk5/probes/src/l2a.c`…`l2m.c`): every spelling that makes the
// ordering check fire DECLINES EARLIER on both binaries — at the P4 cross-block gap
// (`condition predates a non-diagonal gate`, any guard or `break` between the hoisted
// rail and the body's condition) or at clause (ii-d), which refuses a hoisted rail
// with any out-of-loop user (`rolled body leaks a rail entangled with a rotated
// register`). It fails safe: it can only choose OFF, the pre-rhk5 plan.
// RETIREMENT TRIGGER (L8): the day P4 admits a guarded / `break`-exited loop over a
// hoisted rail, or (ii-d) admits a hoisted rail with an out-of-loop user, this layer
// gains a customer — the bd tu9q P0 split plus a clone consumer — and owes a fixture
// that fails with it removed (mutant R9 in rhk5_probes/tools/mutants_r2.py).
void collectInteriorPlans(Function &F, TaintSet &taint, DominatorTree &DT,
                          PostDominatorTree &PDT, LoopInfo &LI,
                          const SmallPtrSetImpl<const CallInst *> &ReversedGates,
                          const SmallPtrSetImpl<Value *> &ReversedRails,
                          SmallVectorImpl<ComponentPlan> &Plans) {
  SmallVector<ComponentPlan, 4> On, Off;
  collectInteriorPlansMode(F, taint, DT, PDT, LI, ReversedGates, ReversedRails,
                           On, /*AdmitCloneCalls=*/true);
  collectInteriorPlansMode(F, taint, DT, PDT, LI, ReversedGates, ReversedRails,
                           Off, /*AdmitCloneCalls=*/false);
  SmallPtrSet<Value *, 16> OnRails, OffRails;
  for (const ComponentPlan &P : On)
    addDischargedRails(P, OnRails);
  for (const ComponentPlan &P : Off)
    addDischargedRails(P, OffRails);
  bool OnIsSuperset = true;
  for (Value *R : OffRails)
    if (!OnRails.count(R)) {
      OnIsSuperset = false;
      break;
    }
  for (ComponentPlan &P : OnIsSuperset ? On : Off)
    Plans.push_back(std::move(P));
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
      if (!H || !taint.Tainted.count(H) || !(isDataProducer(H) || isCloneProducer(H, taint)))
        continue;  // bd p3kd.13: an owned clone result is a producer too
      AnyTaintedProducer = true;
      if (taint.ControlOwnedRails.count(H))
        continue;  // DD-4: Phase-4 owns this rail
      if (taint.OutputRails.count(H))
        continue;  // 7.6: kept I/O output rail — never a data terminal
                   // (PRD-7.6 §2.5). Defensive: a tape-write out_handle is not
                   // a data producer, so it never reaches here, but the
                   // explicit image is load-bearing, like ControlOwnedRails.
      if (railCarriesControlledRotation(H))
        continue;  // bd drbq Inc 1: a register a `cqrt_ry_<W>_controlled`
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
    //    benign, MINUS Phase-4-owned control rails (DD-4 — never select a merge
    //    out-rail or other rail a control emitter owns and leaves allocated;
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

    // The dead-terminal groups (TerminalGroups.h: the regular group and one per
    // Phase-7.3 iteration-local loop; bd p3kd.13's clone-result terminals).
    SmallPtrSet<const CallInst *, 16> ReversedGates;  // what the groups reversed,
    SmallPtrSet<Value *, 16> ReversedRails;           // for single ownership (Rule 8)
    reverseTerminalGroups(F, Terminals, taint, wd, DT, PDT, LI, ReversedGates,
                          ReversedRails);

    // M-B (bd 6uqc Inc 5): the INTERIOR rails — dead after their last forward
    // use, but never a terminal, so nothing above ever saw them. Runs LAST so it
    // sees the settled module (its clause-(d) scan reads the emitted traffic) and
    // so the dead-terminal groups keep first claim on every rail they can reach.
    reverseInteriorGroup(F, taint, wd, DT, PDT, LI, ReversedGates,
                         ReversedRails);
  }

  // ── bd `test_C_libtooling-tu9q` clause (ii-d)'s POSTCONDITION ──────────────
  // Contract in `LoopPlan.h`; the argument for why it exists is at the ledger's
  // definition in `LoopLowering.cpp`.
  //
  // ⚠ THIS SLOT IS THE CONTRACT, not a convenience. It is the FIRST program point
  // at which "was the hoisted rail discharged?" is a FACT: everything above it in
  // this function is what PRODUCES the answer, and everything in `LoopLowering` —
  // where the grant was made — ran stages earlier, over facts that were not final.
  // It is also inside the MODULE-scoped `uncompute` rather than a new stage in
  // `CQLoweringPass::run`, deliberately: a new stage would have to be added to BOTH
  // entry points, and a fence added to one of two entry points is a hole with no
  // diagnostic (`CLAUDE.md` L1's cure names "in BOTH entry points" for exactly
  // this reason). Living here it inherits both call sites for free.
  //
  // ⚠ IT RUNS AFTER THE LOOP, NOT PER FUNCTION: the ledger is module-scoped and
  // `declineUndischargedExitObligations` CLEARS it, so a per-function call would
  // read an emptied ledger from the second function onwards and report success.
  // RETIREMENT TRIGGER: if this call is ever moved inside the `for (Function &F)`
  // above, the postcondition becomes vacuous for every module with more than one
  // quantum function — and bd `1yeu` records that every corpus in this tree is
  // effectively one function per module, so nothing here would go red.
  declineUndischargedExitObligations(M);
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
