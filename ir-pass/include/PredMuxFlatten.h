// PredMuxFlatten.h — 3c6m.14 (L6): general acyclic tainted control via
// block-predicate MUX flattening ("PredMux").
//
// A classical IR-to-IR CFG normalization, NOT a gate emitter: it recovers a
// maximal eligible acyclic tainted-control region (arbitrary-depth nests of
// tainted br/switch over pure speculatable dataflow, DAG reconvergence,
// multi-phi and N-incoming merges) and rewrites it into straight-line code —
// edge predicates as (possibly predicate-inverted) compares composed with
// and/or, merge phis as chained selects. The result is exactly the
// straight-line tainted-select program the shipped substrate already lowers
// (4.4 select merge incl. the kjd1 fp family, the 3c6m.12 Toffoli conjunction
// network, CompareLowering, Phase-5 uncompute). PredMux mints no gate, no
// runtime symbol, and writes no taint bookkeeping — the orchestrator re-runs
// `propagate` after every successful flatten.
//
// ACCEPT-ONLY discipline (the lowerByRefInline / lowerControlledIOSinks
// precedent): an ineligible or off-witness shape is left byte-untouched and
// falls through to the existing loud declines. Design of record:
// docs/prd/phase-07-expressiveness/3c6m.14-L6-control-predication/PRD.md.
//
// ⚠ "PredMux ITSELF NEVER DIAGNOSES" STOOD HERE AND IS NOW FALSE — bd
// `test_C_libtooling-woa0`. `declineConvertedRailPhiLeaves` below is the one
// exception and it is a POSTCONDITION, not a claim gate: the CLAIM path is still
// accept-only (`recoverRegion` only ever `leave`s), and the diagnostic fires from
// the CALLER, after the fixpoint, on a fact the flatten RECORDED rather than on a
// shape it refused. Corrected here rather than in a review record, because a
// correction not applied to the source is not a correction (CLAUDE.md L7).

#ifndef CQ_IRPASS_PREDMUXFLATTEN_H
#define CQ_IRPASS_PREDMUXFLATTEN_H

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/ValueHandle.h"

namespace llvm {
class Function;
class Module;
class PHINode;
class Type;
}  // namespace llvm

namespace cq {

struct TaintSet;

// E7 — a type the select substrate can mux: integer <= 64 bits or the scalar fp
// widths of the kjd1 controlled-copy family. Mirrors the `copyControlledFn` /
// `copyControlledFpFn` envelopes, so a claimed region cannot half-lower.
//
// DECLARED HERE since bd `test_C_libtooling-b6ap` so the MULTI-PHI MERGE PEEL
// (`MergePhiPeel.cpp`, P5) asks the SAME predicate PredMux's own W5/W7 witnesses
// ask, rather than growing a second spelling of "a type the 4.4/kjd1 merge can
// copy" (Rule 14). Pure; mutates nothing. Defined in PredMuxFlatten.cpp.
bool isMuxableType(llvm::Type *Ty);

// bd `test_C_libtooling-woa0` — THE CROSS-CLAIM RECORD, and it exists because
// M4's E6 placement conjunct is a POINT-IN-TIME PROPERTY.
//
// THE QUESTION E6 ASKS. Increment 5a admits a rail φ as a condition-tree leaf
// only where `RPB == S->Entry || !S->InRegion->count(RPB)` — "a φ THIS flatten
// will not convert". `run()` converts `(R.InRegion \ {R.Entry}) ∪ {R.Merge}`, so
// for the region BEING CLAIMED that is very nearly the right set (it over-admits
// exactly `{R.Merge}` — bd `test_C_libtooling-0fly`).
//
// WHY THE ANSWER EXPIRES. `flattenPredMuxRegions` claims ONE region per call
// inside a `while (...)` fixpoint, and NOTHING re-asks E6 about a region that has
// already been emitted. Measured (round 3 F-R3-1): an outer region is correctly
// refused at E6 for an interior rail φ; the INNER region then claims (its φ is at
// its own entry) and flattens, making that block's terminator UNCONDITIONAL; on
// the next pass the outer region's E6 loop — which walks only CONDITIONAL
// terminators — no longer sees the rail φ, claims, and `convertPhis` SELECT-CHAINS
// the very φ the inner region's already-emitted predicate tree was built from.
// That is CLAUDE.md's L1 one stage over: a premise checked once, falsified by a
// later claim rather than by a later taint round.
//
// THE CURE IS CLAUDE.md's STANDING ONE, AND IT IS A PATTERN, NOT A PREDICTION:
// RECORD the question at the site that asks it, RE-ASK it after the fixpoint, in
// BOTH entry points, declining loudly. `Leaves` is the record (committed at CLAIM,
// never at admission — a later gate's `leave` discards the whole `PredMuxRegion`,
// the `BoolAlgPhis` precedent); `Converted` is the OBSERVED violation, set at
// `convertPhis`, which is the only converter and the first point at which the
// conversion is a FACT rather than a forecast; `declineConvertedRailPhiLeaves` is
// the re-ask.
//
// ⚠ IT OBSERVES, IT DOES NOT PREDICT, and that is the whole reason it cannot be
// wrong in either direction: it fires on the SELECT-CHAIN conversion of a φ the
// record holds, not on a re-derivation of where that φ lives. The BOOLEAN-ALGEBRA
// conversion of a recorded φ is deliberately NOT a violation — for an all-constant
// `i1` φ (which `isStructuralRailPhi` also matches) it yields an in-grammar
// and/or tree, and flagging it would re-introduce the exact 2-cell A→D regression
// the M4 reviewer's first spelling produced.
//
// ⚠ `WeakVH`, NOT a raw `PHINode *`. A recorded φ can be erased by a path that is
// not `convertPhis` (a dead-swept predicate cone), and LLVM reuses freed
// `Instruction` memory — a raw pointer would then match a FRESH φ at the same
// address and manufacture a decline out of nothing. `WeakVH` nulls on deletion and
// (unlike `WeakTrackingVH`) does NOT follow RAUW, so it keeps naming the φ across
// `convertPhis`' `replaceAllUsesWith` and stops naming anything the moment the φ
// dies. The set is a handful of entries, so a linear scan is the right container.
struct PredMuxRailPhiRecord {
  // φs that an EMITTED region's condition tree reads as a rail leaf.
  llvm::SmallVector<llvm::WeakVH, 8> Leaves;
  // Set when `convertPhis` select-chains one of `Leaves`. Sticky.
  bool Converted = false;
  // Blame for the diagnostic, captured at the FIRST violation (the φ is erased
  // moments later, so neither it nor its block can be named afterwards).
  //
  // ⚠ `AtFn` IS A RAW POINTER WHERE `Leaves` IS NOT, AND THE ASYMMETRY IS
  // ARGUED, NOT OVERLOOKED. Its window is the few statements between the
  // conversion and the re-ask, and nothing in that window erases a FUNCTION:
  // `flattenPredMuxRegions` erases `BasicBlock`s only, `propagate` is pure
  // analysis, and the unroll / ctlz pre-passes rewrite loop bodies in place. The
  // φ's window, by contrast, spans every later claim, which is exactly why that
  // one needs a handle. RETIREMENT TRIGGER (L8): the day a function-erasing
  // stage runs inside a PredMux fixpoint, or the re-ask is moved later than the
  // fixpoint it belongs to, this must become a handle too — and the null case
  // then needs a loud diagnostic that does not take a `Function &`, because
  // returning true without a message is Rule 1's "third path".
  const llvm::Function *AtFn = nullptr;
  llvm::DebugLoc AtLoc;
};

// The re-ask. Returns true (and emits ONE loud, source-located
// `DiagnosticInfoUnsupported`) iff `rec` observed a recorded rail φ being
// select-chained. Pure with respect to the module.
//
// ⚠ LOUD, NOT AN `assert` (Rule 1): Release has assertions off and Release is the
// build every gate in this tree runs. Same reasoning as
// `declineSurvivingIntrinsicCalls`, which is the model this copies.
bool declineConvertedRailPhiLeaves(const PredMuxRailPhiRecord &rec);

// Flattens AT MOST ONE eligible region per call (so every claim sees fresh
// dominance/taint state) and returns true iff it mutated the module. Drive to
// fixpoint with `while (flattenPredMuxRegions(M, taint, false, &rec))
// taint = propagate(…)`, then call `declineConvertedRailPhiLeaves(rec)`.
// Reads `taint` only BEFORE its single mutation; the caller must re-propagate
// before any other stage consumes taint again.
//
// ⚠ NEITHER PARAMETER HAS A DEFAULT, DELIBERATELY. `claimAll` used to default to
// false and `rec` could have defaulted to null; both defaults are removed so a
// NEW call site must DECIDE about the cross-claim record rather than inherit a
// hole. CLAUDE.md's standing warning is literal here — "a seventh emitter that
// forgets it re-opens the window with NO diagnostic anywhere" — and this file has
// had its call-site count mis-stated twice (two, then five; it is seven).
// Passing `rec == nullptr` is legal and means "this driver does not police the
// cross-claim property"; the only such caller must say why in writing.
//
// `claimAll` (5po2 I2, default false) DROPS the W anti-overlap witness only:
// with it set, ANY acyclic single-entry/single-exit tainted VALUE region is
// claimed (incl. the 2-incoming single-guard diamond), not just the shapes the
// top-level detection declines. It is passed true ONLY by `lowerCloneControl`,
// which drives PredMux with the clone's DISJOINT `cloneTaint`: inside a
// rotation-free Bennett clone the SwapRoute/4.4-select emitters do not run, so
// EVERY tainted diamond must flatten and the anti-overlap witness is irrelevant.
// The correctness gates (E2 acyclic, E3 SESE, E4/E6/E7 speculatable+mux-lowerable)
// are UNCHANGED — `claimAll` relaxes only the witness. Module-level callers keep
// the default so the top-level accept surface is byte-identical.
bool flattenPredMuxRegions(llvm::Module &M, TaintSet &taint, bool claimAll,
                           PredMuxRailPhiRecord *rec);

// bd adia (3c6m.55 Lever C): the pending-spec pure-callee proof (EXACT
// definition — interposable weak/linkonce bodies fail — + non-vararg +
// acyclic CFG + br/ret terminators only + every non-terminator instruction
// speculatable dataflow; inner calls are curated memory(none) intrinsics or
// recursively-proven bodies, call-graph cycles broken by an OnStack set).
// True ⇒ the call is a pure, total, terminating function of its arguments —
// safe to speculate (PredMux E4) and transparent as an fp seed derivation
// (Fp80Union wide mode).
//
// bd 3c6m.14.1: the per-instruction predicate runs with `AdmitI80Compare=true`,
// so a body whose only off-grid instruction is an x86_fp80 BIT-PATTERN compare
// (`icmp <pred> i80` with exactly one ConstantInt operand — provably `_hl`) now
// PASSES. An `icmp` is pure and total at every width, so the old exclusion was
// never about this predicate's question; it was the region walk's grid mirror,
// and it is still enforced where the compare actually lowers (the callee's own
// Phase-6 clone). A Q+Q i80 compare still fails, and so does an i80 op with no
// template row. NOTE what that does NOT say (a Rule-13 lens corrected an earlier,
// over-broad sentence here): the four SHIPPED i80 bitwise rows — and/or/shl/lshr,
// admitted by the operand-blind `i80BinaryInScope` — pass this proof in their Q+Q
// form too and lower to `cq_template_<op>_i80` + `_unc`. That is pre-existing
// bd 3c6m.51 behaviour, unchanged here; only the COMPARE carries a
// one-ConstantInt restriction, and only because the select-leaf flag mint
// (`qqSelectLeafWidth`) fences i80.
bool isSpeculatablePureCallee(const llvm::Function *F);

// bd wve8 — THE STRICT TWIN. Same walk, but it refuses the two clauses whose
// obligation `isSpeculatablePureCallee` DEFERS to a later stage: the
// `qromReadShapeInScope` const-global read (whose BOUNDS proof is the clone
// emitter's job) and the terminator skip (which never asks whether a conditional
// branch's condition can be poison). Use this — never the lax form — from any
// consumer that SPECULATES THE CALL ITSELF without cloning or lowering the
// callee, i.e. one for which no later stage exists to discharge the deferral.
// Its one caller today is `classifyClassicalCallArm` (the Phase-6.5
// classical-call arm, which is clone-ORTHOGONAL and hoists the call to
// unconditional execution). Reaching for the lax form there shipped an
// out-of-bounds read that SIGSEGVed on a source with no UB; the full account is
// at the definition in PredMuxFlatten.cpp.
bool isSpeculatableTotalCallee(const llvm::Function *F);

}  // namespace cq

#endif  // CQ_IRPASS_PREDMUXFLATTEN_H
