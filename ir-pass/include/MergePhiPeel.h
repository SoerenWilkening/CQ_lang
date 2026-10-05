// MergePhiPeel.h — bd `test_C_libtooling-b6ap`: THE MULTI-PHI MERGE PEEL.
//
// An ACCEPT-ONLY IR-to-IR normalisation (the `flattenPredMuxRegions` /
// `lowerByRefInline` / `lowerControlledIOSinks` family): it turns the merge φ a
// tainted control region does NOT define into a tainted-condition `select`, so
// the region's merge is left with the ONE φ `ControlDetect::soleMergePhi`
// requires. It mints NO gate, emits NO runtime symbol and NEVER diagnoses; an
// off-pattern shape is left BYTE-UNTOUCHED for its existing loud owner.
//
// ── WHY IT EXISTS ────────────────────────────────────────────────────────────
//
// `clang -O1` fuses two consecutive source `if`s whose conditions it proves
// equivalent into ONE diamond whose merge block holds SEVERAL φ — one per value
// that differs across the arm. `ControlRegion::Merge` is a single `PHINode *`
// (`ControlPlan.h`) and every downstream classifier and emitter reads exactly
// one, so `soleMergePhi` returns null on a >1-φ merge, `recoverRegion` falls to
// `RegionShape::OffPattern` and `offPatternDisposition`'s catch-all declines
// `control flow` (`ControlDetect.cpp:583`). `soleMergePhi`'s own comment calls
// that "decline generic, never mis-lower" — a Prime-Directive OVER-decline, and
// exactly the thing CLAUDE.md's hcrg bullet warns about: *"before declining a
// shape, ask whether the thing you are protecting is the unitary or the
// emitter's bookkeeping"*. Here it is the bookkeeping.
//
// The φ that block the region are, in every measured member of the population, a
// plain DATA MUX over values that are ALL available at the region's `Pred` —
// `int a = 5; if (b0 == 1) a -= 3;` after `-O1` const-folds both edges. Such a φ
// is a `select` on the region's own condition that `clang -O1` PHI-IFIED, and the
// 4.4 `SelectClassify`/`SelectMergeEmit` substrate has lowered exactly that
// `select` since Phase 4.4. This stage restores the spelling.
//
// ⚠ **THERE IS NO PLAIN-C TWIN AND THAT IS MEASURED, NOT A CONVENIENCE.** Writing
// the mux as a C ternary before OR after the region produces a stage-1 module
// BYTE-IDENTICAL to the fused one (`SCOPE_b6ap.md` §0.1, probes `p20`-`p23` vs
// `p01`/`p09`): `-O1` converts a `select` whose condition is the dominating
// branch's condition, in a 2-predecessor merge block, straight back into a `phi`.
// So this stage is a RESTORATION of a spelling `-O1` destroys, and its
// byte-identity witness must come from HAND IR (a lit fixture pair), never from a
// C twin.
//
// ── THE CONDITION IS CLONED, NEVER SHARED (SCOPE §6, option A) ───────────────
//
// A peeled `select` that REUSES the region's own compare value declines
// `condition data use neither escaped nor measured` — `classifyArms` sees a
// non-`BranchInst` user of the condition and `condDataUseDisposition`
// (ArmClassify.cpp) does not recognize a `SelectInst`, so it ends at its
// `Unowned` catch-all. MEASURED both ways (`h09a`/`h09b` decline; `h09c`/`h09d`
// accept). So each peeled φ gets its OWN `CmpInst` clone in the merge — the
// region and the select then mint, strip and free their own flag on the same
// wire, which is exactly the shipped hcrg sequential-regions shape. Cost: one
// transient flag rail per peeled φ, minted and freed. Widening
// `condDataUseDisposition` instead would be a Rule-13-core change to the ziov
// fence and is recorded as OQ-1, NOT taken here.
//
// A BARE RAIL condition (`isCondRailLeaf` — a `cq_theta_i1` result) needs no
// clone at all: the register IS the condition, and `SelectMergeEmit`'s r9e5
// `CopyRailRoot` path already mints its own CNOT copy of it.
//
// ── IT MUST RUN IN EVERY ROUND (SCOPE §8) ────────────────────────────────────
//
// CLAUDE.md's standing lesson "a stage that runs ONCE has a round-2-FALSE
// premise" (F-L3-1, F-R1-1, F-B1R2-1) applies directly: `repropagateControlMerges`
// re-seeds taint from the 6.5/4.5 `%out` rails and then runs a FULL second round
// of `detectControlRegions`+`lowerControlRegions`, so it creates regions round 1
// never saw. MEASURED customer `p80`: a 6.5 classical-call region followed by a
// fused 2-φ diamond whose condition reads that region's `%out`; classical at
// round 1, tainted at round 2, and its one-φ control `p81` ACCEPTS today.
//
// THE RULE, and it is grep-checkable: **this function is called immediately
// before EVERY `detectControlRegions` call in the tree.** There are three
// (`CQLoweringPass::run`, the second entry point, and the round-2 fixpoint inside
// `TaintPropagation::detectAndLowerOnwardControl`), and a fourth that forgets the
// call re-opens the round-2 window with no diagnostic anywhere — the
// `markBranchPhaseGate` / `markRailCondRead` lesson verbatim.
//
// NOTES §2's stage table owes this stage a row, and the answer is written at the
// definition: the peel's own P3 dominance and P7 clonability proofs ARE computed
// before detection and consumed by it, but they are STRUCTURAL (dominance, block
// shape, `isa<>`), not taint-keyed, so round 2 cannot falsify them for a region
// round 1 already saw. What round 2 changes is WHICH branches are tainted, and
// that is exactly what the third call site covers.
//
// Design of record: `docs/prd/phase-04-swap-route-control/inc1-records/
// session-b6ap/{SCOPE_b6ap,IMPL_b6ap}.md`.

#ifndef CQ_IRPASS_MERGEPHIPEEL_H
#define CQ_IRPASS_MERGEPHIPEEL_H

#include "llvm/ADT/SmallPtrSet.h"

namespace llvm {
class Module;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Peel every P1-P10-passing merge φ of every tainted-condition diamond / if-else
// in `M` into a `select` on a clone of the region's condition (or, for a bare
// rail condition, on the rail itself). Returns true iff the module was mutated.
//
// Maintains `taint.Tainted` EXACTLY and by hand — it does NOT re-`propagate`.
// (The PredMux fixpoint can afford `taint = propagate(M, wd)` because it runs
// before any stage has written bookkeeping into the `TaintSet`; by this slot
// `lowerControlledIOSinks` and `lowerLoops` have, and rebuilding the set would
// silently discard `InPlaceRailOps` / `ClaimedRailRoots` / `InLoopFlattenedPreds`
// / `PreLoopCommittedInPlaceOps`. The peel's taint delta is exactly three edits
// per peeled φ — insert the clone, insert the select iff the φ was tainted, erase
// the φ — and every other `TaintSet` field is structurally incapable of naming a
// source φ at this program point.)
//
// ⚠ `Delta`, and the CALLER'S OBLIGATION it exists for (bd b6ap Rule-13 round-1
// finding F-B6-1, a CONFIRMED plain-C silent miscompile in FIVE consumer
// classes). The peel does not merely RE-SPELL a value — it makes a previously
// CLASSICAL value QUANTUM, and every stage that adjudicates consumers of tainted
// values (`detectSpecializations`, `declineTaintEscapes`, `declineStaleRecordOps`)
// is a PURE-ANALYSIS pre-pass that has already run by this slot. A caller that
// peels and does not adjudicate ships a module where a `store`, an unknown
// callee, a visible-body callee or a stale-mask Phase-6 clone consumes the rail's
// runtime HANDLE TAG as a classical integer, at `opt` exit 0 and STRICT stage-2b
// `0 violation(s)`.
//
// So: when `Delta` is non-null it is filled with the peel's WHOLE taint growth
// (the clones and selects, plus everything `propagateFromSeeds` newly taints),
// and the caller MUST hand it to `adjudicateTaintDelta`
// (`TaintPropagation.h`) — the same four-call sequence `repropagateControlMerges`
// runs for its own delta. The ROUND-2 call site is the ONE exception, and by
// inclusion rather than by omission: it sits inside
// `detectAndLowerOnwardControl`, whose only caller snapshots `Tainted` BEFORE it
// and adjudicates the whole difference afterwards.
//
// ⚠ `Delta` HAS NO DEFAULT ARGUMENT, DELIBERATELY. SCOPE §8's instruction was to
// *"prefer whichever spelling makes the peel impossible to skip"*, citing the
// `markBranchPhaseGate` / `markRailCondRead` lesson — a call a later author can
// forget re-opens the window with no diagnostic anywhere. The same now applies to
// the peel's OWN obligation: a fourth caller that omitted a defaulted `Delta`
// would silently ship F-B6-1 again. Without a default, the compiler makes every
// new caller state which of the two dispositions it has chosen — adjudicate the
// delta, or pass `nullptr` with the written argument for why its caller already
// does.
bool peelIndependentMergePhis(llvm::Module &M, TaintSet &taint,
                              llvm::SmallPtrSetImpl<llvm::Value *> *Delta);

}  // namespace cq

#endif  // CQ_IRPASS_MERGEPHIPEEL_H
