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
// falls through to the existing loud declines. PredMux itself never
// diagnoses. Design of record: docs/prd/phase-07-expressiveness/
// 3c6m.14-L6-control-predication/PRD.md.

#ifndef CQ_IRPASS_PREDMUXFLATTEN_H
#define CQ_IRPASS_PREDMUXFLATTEN_H

namespace llvm {
class Function;
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Flattens AT MOST ONE eligible region per call (so every claim sees fresh
// dominance/taint state) and returns true iff it mutated the module. Drive to
// fixpoint with `while (flattenPredMuxRegions(M, taint)) taint = propagate(…)`.
// Reads `taint` only BEFORE its single mutation; the caller must re-propagate
// before any other stage consumes taint again.
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
bool flattenPredMuxRegions(llvm::Module &M, TaintSet &taint,
                           bool claimAll = false);

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

}  // namespace cq

#endif  // CQ_IRPASS_PREDMUXFLATTEN_H
