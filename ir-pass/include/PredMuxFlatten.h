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
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Flattens AT MOST ONE eligible region per call (so every claim sees fresh
// dominance/taint state) and returns true iff it mutated the module. Drive to
// fixpoint with `while (flattenPredMuxRegions(M, taint)) taint = propagate(…)`.
// Reads `taint` only BEFORE its single mutation; the caller must re-propagate
// before any other stage consumes taint again.
bool flattenPredMuxRegions(llvm::Module &M, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_PREDMUXFLATTEN_H
