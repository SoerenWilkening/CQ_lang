// ArmAnalysis.h — Shared per-arm lineage analyses for swap-route control.
//
// Declares the by-SSA-identity walks `ArmClassify.cpp` uses to classify an arm's
// contribution to the merge `φ` (phase spine / value chain / tainted-angle gate)
// plus the condition-provenance and diagonal-alias closure helpers. De-anonymized
// from `ArmClassify.cpp`'s anonymous namespace (WI-0/MD1) so the 4.3
// `RegionTreeDetect` (criteria-4/5 RAUW-collapse + mint-from-rail) and
// `ArmHomogeneity` (the §12.5 PASS-1 per-arm class split) TUs can reuse them
// rather than re-implement the lineage logic. PURE REFACTOR: the definitions
// still live in `ArmClassify.cpp`, only their linkage changed (anonymous → named
// `cq`); the tiny `isPhiCall`/`isThetaCall`/`isCallToPrefix` predicates stay
// TU-local (they collide with the same-named anon helpers in `SwapRouteEmit.cpp`/
// `WireWalk.cpp` if promoted).
//
// All analysis is pure SSA reading — NO IR is mutated (Rule 9). The per-use arg-1
// angle exclusion (the f64/angle miscompile family, Rule 3) is replicated inside
// `condProvenance`/`taintedAngleGate` verbatim from `TaintPropagation.cpp`. See
// swap-route 4.1/4.2 IMPLEMENTATION §3 and 4.3 IMPLEMENTATION-4.3 §3.

#ifndef CQ_IRPASS_ARM_ANALYSIS_H_
#define CQ_IRPASS_ARM_ANALYSIS_H_

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class BasicBlock;
class CallInst;
class CmpInst;
class Instruction;
class Value;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Walk the PHASE spine WITHIN one arm block: while `V` is a `cq_phi` (Rz) call
// DEFINED IN `ArmBB`, follow its arg-0 handle operand (arg 1 is the classical
// angle). Returns the first value the chain bottoms at — the arm's base handle, a
// value-changing op, OR a `cq_phi` defined OUTSIDE `ArmBB` (a pre-region rotation,
// i.e. the live DERIVED base handle the arm extends). The arm-block bound is
// LOAD-BEARING (an unbounded walk hops past a shared pre-region `cq_phi` to the
// theta source → double-collect/UAF; see the .cpp).
llvm::Value *walkPhaseSpine(llvm::Value *V, const llvm::BasicBlock *ArmBB);

// Backward taint provenance of the branch condition: every tainted value
// reachable by walking operand edges back from `Cond`, stopping at `cq_theta`
// sources. Replicates the per-use arg-1 angle exclusion verbatim — the angle
// operand of a `cq_phi` is classical and must never be collected as a condition
// operand (the f64/angle miscompile family). Only tainted values are recorded.
void condProvenance(llvm::Value *Cond, TaintSet &Taint,
                    llvm::SmallPtrSetImpl<llvm::Value *> &Out);

// The routed base's first DIAGONAL-ALIAS hit in `Prov`, or null. Walks the
// pre-region `cq_phi` arg-0 chain from `Routed`: rotation lowering RAUWs a
// `%qd = cq_phi(%q, ·)` and its `%q` to the SAME i32 handle, so SSA-value
// disjointness from the condition's provenance is NOT wire disjointness. Pure
// reading walk — no collection, so the arm-block bounding discipline (which
// guards COLLECTION) does not apply.
llvm::Value *diagonalAliasHit(llvm::Value *Routed,
                              const llvm::SmallPtrSetImpl<llvm::Value *> &Prov);

// One arm's candidate VALUE chain — the value twin of `walkPhaseSpine`.
struct ValueChain {
  // The chain links in FORWARD (program/base-first) order — the §4 emit order
  // the value emitter replays them in. Collected merge-first, reversed at end.
  llvm::SmallVector<llvm::Instruction *, 6> Ops;
  // The value the walk bottomed at (never itself a link). For a routable arm
  // this must be EXACTLY the routed slot (base-identity — the Defect-2 fix).
  llvm::Value *Base = nullptr;
  // The walk reached an IN-ARM `cq_phi` link: a phase gate inside a value
  // lineage (`if(q>5){rz(p,a); p=p+3}`) → `mixed phase/value arm`. The
  // offending call is stashed for the diagnostic anchor.
  llvm::Instruction *MixedPhi = nullptr;
  // Some link consumed a SECOND tainted operand (a Q+Q link, `p = p + r`) — a
  // recognized value shape not yet routed (defer, PRD §8.3).
  bool HasQQ = false;
};

// Walk the VALUE chain WITHIN one arm block: while `V` is a supported tainted
// integer/fp `BinaryOperator` DEFINED IN `ArmBB`, follow its threaded operand
// (the sole tainted one). Returns the chain and the value it bottoms at.
// ARM-BLOCK-BOUNDED for the same load-bearing reason as `walkPhaseSpine`.
ValueChain walkValueChain(llvm::Value *ArmIncoming, const llvm::BasicBlock *ArmBB,
                          TaintSet &Taint, llvm::Value *RoutedHint);

// The first rotation whose arg-1 ANGLE operand is TAINTED — quantum-derived data
// in the angle slot — among the arm's IN-BLOCK spine gates and (for a derived
// base) the pre-region base `cq_phi` itself. Null if every angle is classical.
// A tainted angle has no fixed unitary (the emitter would replay it as a runtime
// handle tag) — the only sound disposition is a loud decline (Rule 3).
llvm::CallInst *taintedAngleGate(llvm::Value *ArmIncoming,
                                 const llvm::BasicBlock *ArmBB, llvm::Value *Base,
                                 TaintSet &Taint);

// ziov WI-1 / ziov.3: disposition of a tainted CONTROL compare's NON-branch
// (data) uses — the Q/C-boundary question raised when `q>5` is read in BOTH a
// `br` (control) AND a data position (`int f=(q>5)`; clang -O1 CSEs the two to one
// `icmp` with two uses). `ShareOk` = the data lineage is owned downstream (escapes
// via `ret` or is measured AFTER the route) so a phase region can mint ONE flag
// and skip its strip+free; `MeasuredEarly` = the lineage is measured IN
// `RouteBlock`, collapsing the flag BEFORE the route controls on it; `Unowned` =
// the lineage is dead-within-function or reaches an unrecognized hole (a dirty
// entangled rail, no owner). `RouteBlock` is the region's route block (`Region.
// Pred`). The FLAT phase path (`classifyArms`) SHARES on `ShareOk` and declines
// the other two; the NESTED path (`recoverRegionTree`) declines ALL THREE — nested
// flag-SHARING is a later WI (the `ShareOk` arm flips to accept then). Pure forward
// SSA walk, before any mutation (Rule 9). De-anonymized from `ArmClassify.cpp` so
// `RegionTreeDetect` reuses the one predicate (Rule 14); the definition still lives
// in `ArmClassify.cpp`.
// `Unlowerable` = a data op on the condition lineage (a cast to an unsupported
// width / out-of-scope pair, e.g. `sext i1→i128`) has NO template, so accepting
// the region would route+flatten it and only THEN hit `lowerOps`'s loud "no
// template" decline — a mutate-then-decline (Rule 9 violation, ziov.4). Declining
// it in detection keeps detect-before-mutate. The FLAT path declines it; the
// NESTED path declines it too (it declines every cond-data-use disposition).
enum class CondDataDisp { ShareOk, MeasuredEarly, Unowned, Unlowerable };

CondDataDisp condDataUseDisposition(llvm::Instruction *Cond,
                                    const llvm::BasicBlock *RouteBlock);

// Whether a control/data `CmpInst`'s predicate has a lowering template — the
// predicate axis of `compareInScope`, with the icmp/fcmp family derived from the
// instruction. An out-of-scope fcmp predicate (outside {oeq,une,olt,ogt,ole,oge})
// has NO template (test_C_libtooling-jvun); a control region whose CONDITION uses
// one must decline in DETECTION, before emit mints a flag from it. The flat flag
// mint is emit step 1, but a NESTED inner mint follows the outer route/replay, so
// without this pre-mutation gate an out-of-scope inner condition is a
// mutate-then-decline (Rule 9). Shared by `condDataUseDisposition` (data lineage),
// `classifyArms` (flat control condition), and `recoverRegionTree` (nested
// outer+inner conditions).
bool comparePredLowerable(const llvm::CmpInst *Cmp);

}  // namespace cq

#endif  // CQ_IRPASS_ARM_ANALYSIS_H_
