// ArmAngleHoist.h — bd test_C_libtooling-dm7f.77 (found by dm7f.51 step 2 on
// dicke.c): HOIST A ROTATION ARM'S CLASSICAL ANGLE CONE INTO THE PRED.
//
// `if (a) cq_theta(&b, 2.0 * acos(sqrt(1.0 / 3)));` reaches the pass with the
// angle computed INSIDE the arm (`clang -O1` folds the sqrt, not the
// `llvm.acos` intrinsic, and does not speculate it), so the arm is
// `%x = call double @llvm.acos.f64(…); %y = fmul %x, 2.0; %r = cq_theta(%b, %y)`.
// Every in-place rotation clause demands that the theta be the WHOLE arm
// (`inPlaceRotationArmTheta`: "a stray op the flatten would drop"), so the
// program declined `control flow` on main 27aaf1e1 — and the identical program
// with a literal angle lowered. That is an over-decline (R1), not a hazard: the
// cone is classical and pure.
//
// THE REWRITE. For each tainted conditional `br` and each arm block whose only
// predecessor is the branch block, when the arm holds exactly ONE `cq_theta_*`
// call `T` and every other non-terminator instruction `I` is
//   (H1) untainted,
//   (H2) `isSafeToSpeculativelyExecute(I)` — LLVM's own answer (L4), and
//   (H3) in `T`'s ANGLE cone: every user of `I` is `T`'s angle operand or another
//        cone member (so nothing in the arm but the gate reads it),
// those instructions move, in order, to just before the branch. Moving a
// speculatable, side-effect-free classical computation to a dominating point
// is the identity on every value and every effect, so the unitary is unchanged;
// the arm then has the theta-only shape every clause already lowers.
//
// L1: runs before EVERY `detectControlRegions` (with the register-condition
// commit). A cone member that becomes TAINTED at round 2 makes the rotation
// angle quantum, which the tainted-angle guard refuses loudly (R3); the hoist
// never decides anything about a tainted value.
#ifndef CQ_IRPASS_ARM_ANGLE_HOIST_H_
#define CQ_IRPASS_ARM_ANGLE_HOIST_H_

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;

// Returns true if anything moved.
bool hoistArmAngleCones(llvm::Module &M, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_ARM_ANGLE_HOIST_H_
