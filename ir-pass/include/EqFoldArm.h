// EqFoldArm.h — The equality-folded `br` diamond accept clause (4.5 WI-5).
//
// `clang -O1` const-folds an `if (q == k) { q = cq_phi(q, θ) … }` arm: inside
// the `q==k`-true block it KNOWS `q` equals the literal `k`, so it rewrites the
// gate's arg-0 handle to the constant — the arm gate becomes `cq_phi(i32 k, θ)`.
// `classifyArms`'s phase spine then bottoms at the `ConstantInt k` instead of the
// routed handle `q`, and the region declines `control flow` (the gap WI-5 fills).
//
// `tryEqFoldArm` is the STRICTLY-ADDITIVE D1–D7 clause that re-recognizes such a
// folded arm as a pure PHASE arm over the icmp's tainted operand, RE-ANCHORING
// the routed handle by SSA identity. It is a PURE PREDICATE (Rule 9, no IR
// mutation, no diagnostics): it returns `true` only on a proven eq-fold phase
// arm (and records the routed handle in `Region.RoutedBase`); on any miss it
// returns `false` so the existing `classifyArms` paths fall through and decline
// exactly as before — it never weakens a decline (a real cross-handle mux still
// declines `control flow`). Once it accepts, the diamond is a normal
// `ControlRegion` and `emitRegion` lowers it (§4D), reading `Region.RoutedBase`
// for the eq-fold IF/ELSE (where the folded-constant base would otherwise be
// routed — see ControlPlan.h `RoutedBase`).

#ifndef CQ_IRPASS_EQ_FOLD_ARM_H_
#define CQ_IRPASS_EQ_FOLD_ARM_H_

namespace llvm {
class BasicBlock;
class Value;
}  // namespace llvm

namespace cq {

struct ControlRegion;
struct TaintSet;

// The D1–D7 equality-folded-diamond accept clause. `Base` is what
// `walkPhaseSpine(ArmIncoming, ArmBB)` bottomed at; `Routed` is the region's
// running routed-handle anchor (null on an if/else's first arm, set on a diamond
// or a subsequent arm) and is RE-ANCHORED by reference on accept. Returns true
// iff `ArmBB` is a pure phase spine whose const-folded base `k` matches an
// equality compare `q == k` / `q != k` whose tainted non-constant operand is the
// routed handle (D1 equality predicate, D2 const-folded base, D3 the icmp's
// non-const operand is the routed handle, D4 literal == folded const, D5 routed
// operand tainted, D6 pure spine, D7 every angle classical). On accept it sets
// `Routed` and `Region.RoutedBase` to that tainted operand; on any miss it
// returns false WITHOUT mutating `Routed`/`Region` (the caller falls through to
// the existing decline paths).
bool tryEqFoldArm(ControlRegion &Region, const llvm::BasicBlock *ArmBB,
                  llvm::Value *ArmIncoming, llvm::Value *Base,
                  llvm::Value *&Routed, TaintSet &Taint);

}  // namespace cq

#endif  // CQ_IRPASS_EQ_FOLD_ARM_H_
