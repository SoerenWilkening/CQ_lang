// EqFoldArm.h — The equality-folded `br` diamond accept clause (4.5 WI-5).
//
// Pre-3qlq, `clang -O1` const-folded a register-form `if (q == k) { q =
// cq_phi(q, θ) … }` arm: inside the `q==k`-true block it KNOWS `q` equals `k`, so
// it rewrote the gate's arg-0 handle to the constant, `cq_phi(i32 k, θ)`, and the
// phase spine bottomed at the `ConstantInt k` instead of `q`. `tryEqFoldArm` is
// the STRICTLY-ADDITIVE D1–D8 clause that re-recognized such an arm as a pure
// PHASE arm over the icmp's tainted operand, re-anchoring the base by SSA
// identity in `Region.RoutedBase`. It is a PURE PREDICATE (Rule 9, no IR
// mutation, no diagnostics); on any miss it returns `false` and `classifyArms`
// declines exactly as before.
//
// ⚠ STRUCTURALLY UNREACHABLE SINCE bd 3qlq: D2 needs a spine bottoming at a
// `ConstantInt`, which only the retired `@cq_phi_<sfx>` arg-0 ever produced, and
// that spelling is now a loud reserved-name error. A register-free
// `if (q == k) cq_phi(θ);` has nothing to fold and lowers as an ordinary
// `PhaseKickback` region (see the header of `control_swap_eqfold_diamond.ll`).

#ifndef CQ_IRPASS_EQ_FOLD_ARM_H_
#define CQ_IRPASS_EQ_FOLD_ARM_H_

namespace llvm {
class BasicBlock;
class Value;
}  // namespace llvm

namespace cq {

struct ControlRegion;
struct TaintSet;

// The D1–D8 equality-folded-diamond accept clause. `Base` is what
// `walkPhaseSpine(ArmIncoming, ArmBB)` bottomed at; `Routed` is the region's
// running routed-handle anchor (null on an if/else's first arm, set on a diamond
// or a subsequent arm) and is RE-ANCHORED by reference on accept. Returns true
// iff `ArmBB` is a pure phase spine whose const-folded base `k` matches an
// equality compare `q == k` / `q != k` whose tainted non-constant operand is the
// routed handle (D1 equality predicate, D2 const-folded base, D3 the icmp's
// non-const operand is the routed handle, D4 literal == folded const, D5 routed
// operand tainted, D6 pure spine, D7 every angle classical, D8 POLARITY — the
// arm sits on the successor where the equality HOLDS, `eq`-true / `ne`-false, so
// the fold `H → k` is a theorem there and not its negation). On accept it sets
// `Routed` and `Region.RoutedBase` to that tainted operand; on any miss it
// returns false WITHOUT mutating `Routed`/`Region` (the caller falls through to
// the existing decline paths).
bool tryEqFoldArm(ControlRegion &Region, const llvm::BasicBlock *ArmBB,
                  llvm::Value *ArmIncoming, llvm::Value *Base,
                  llvm::Value *&Routed, TaintSet &Taint);

}  // namespace cq

#endif  // CQ_IRPASS_EQ_FOLD_ARM_H_
