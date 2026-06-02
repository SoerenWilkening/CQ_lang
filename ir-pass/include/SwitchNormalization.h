// SwitchNormalization.h — Phase 4.1 WP15 (PRD §8.2, epic `-aht.1`). A
// normalization step wedged BETWEEN taint propagation and control-region
// detection: a tainted-scrutinee `SwitchInst` whose arms are a clean
// VALUE-merge (`break`-terminated, empty arms reconverging on a common merge
// `φ`) is rewritten into `icmp eq` flags + a nested data-flow `select` chain.
// The existing select-mux path (`detectControlRegions` → `dissolveSelect` /
// `reduceClassicalMux`) then lowers it with ZERO new lowering code.
//
// This supersedes the Family E `-lowerswitch` default (PRD §7.1): the select
// form never produces `br`-diamonds, so it sidesteps the pivot-tree
// shared-multi-pred-merge crash, needs no N-way `φ` dissolution (the `φ`
// collapses to binary selects), and needs no new ABI.
//
// A switch the normalizer DECLINES (non-value-merge: side-effecting/gated arms,
// no merge `φ`, an extra non-arm merge predecessor, or a classical scrutinee)
// is left untouched — the WP12 tainted-`switch` diagnostic in
// `detectControlRegions` remains the safety fallback for those shapes.

#ifndef CQ_IRPASS_SWITCH_NORMALIZATION_H_
#define CQ_IRPASS_SWITCH_NORMALIZATION_H_

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Rewrite every tainted-scrutinee value-merge `switch` in `M` into eq-flags +
// a nested `select` chain (PRD §8.2). Runs after `propagate` and before
// `detectControlRegions`. The minted `icmp eq` flags are inserted into
// `taint.Tainted` so detection recognizes the resulting selects as
// tainted-condition (quantum-controlled) selects. Switches that do not match
// the value-merge shape are left untouched for the WP12 diagnostic.
void normalizeTaintedSwitches(llvm::Module &M, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_SWITCH_NORMALIZATION_H_
