// AngleSelectEmit.h — ANGLE SELECT (control-in-place-PRD §12.3, bd drbq Inc 2b).
// Ry stem in the X-BRACKET form (bd dm7f.6, owner ruling 2026-10-13
// `owner-ruling-angle-select-xbracket`); the `cq_phi` stem by KICKBACK (3qlq
// Inc 1 P2).
//
// Dispatched from `SwapRouteEmit::lowerControlRegions` on
// `R.Kind == AngleSelectRegion`, which `ArmClassify::classifyAngleSelect` pushes
// (via `SelectClassify`'s gate 3). Runs AFTER detection and BEFORE
// `lowerRotations`, exactly like every other Phase-4 emitter.
//
// THE INPUT, which is what `clang -O1` makes of the C the user writes:
//   * Ry STEM (`cq_theta`): `include/CQ.h` puts `nomerge` on every `cq_theta_*`
//     (bd fmt3, 2026-09-28), so `if (q == 5) cq_theta(&r, A); else
//     cq_theta(&r, B);` stays an if/else and lowers through the in-place Ry arm.
//     The C spelling that reaches THIS emitter is the select written out,
//     `cq_theta(&r, (q == 5) ? A : B);` (`slice_control_angle_select_ry*_ternary.c`).
//   * PHASE STEM (`cq_phi`): no `nomerge`, so `if (c) cq_phi(A); else
//     cq_phi(B);` is merged into ONE call with a `select` on the ANGLE and the
//     branch CFG is gone before the pass runs (Rule 9).
//
//     %c = icmp eq i32 %q, 5
//     %a = select i1 %c, double A, double B            ; A, B CLASSICAL: constants
//                                                      ; or RUN-TIME values
//     %t = call i32 @cq_theta_si32(i32 %r, double %a)  ; %r TAINTED, %a only arg-1
//
// THE Ry OUTPUT, positional around `%t`:
//
//     %f  = cq_template_icmp_eq_i32_hl(i32 %q, i32 5)  ; flag mint
//     %ta = call i32 @cq_theta_si32(i32 %r, double A)  ; NEW, recorded controlled
//     cqrt_x(i32 %f)
//     %t  = call i32 @cq_theta_si32(i32 %ta, double B) ; REWIRED, recorded controlled
//     cqrt_x(i32 %f)
//     cq_template_icmp_eq_i32_hl_unc(i32 %f, i32 %q, i32 5)  ; flag strip
//     cqrt_free(i32 %f)
//
// `lowerRotations` then mints `cqrt_ry_<W>_controlled(f, h, ·)` for both recorded
// gates (drbq Inc 1, `taint.ControlledRotations`). The result is BYTE-IDENTICAL to
// what the if/else in-place Ry arm emits for the same program
// (`ry_c(f,h,A); x(f); ry_c(f,h,B); x(f)`), which the e2e gates
// `e2e-angle-select-ry{,-ne,-forward-loop}-twin-identical` pin. The register is
// then FROZEN (it carries a controlled Ry): never reverse-played, never freed.
//
// WHY IT IS EXACT: f = 1 fires `Ry(A)` and nothing else; the `cqrt_x` pair inverts
// the ANCILLA so f = 0 fires `Ry(B)` and nothing else. Each arm's double reaches
// exactly ONE gate slot, verbatim (ruling item (1)): no arithmetic, no freeze (no
// arm is read twice), and a non-finite arm never touches the other branch. There
// is NO polarity case — `select %c, A, B` always means "A when the flag is 1" —
// so a `!=` source (which `clang` canonicalizes to `icmp eq` with the select
// operands SWAPPED) needs nothing special. The bracket is on the compiler-owned
// flag, never on a user register.
//
// THE HISTORY THIS REPLACES: drbq Inc 2b emitted `Ry(B)` then one controlled
// `Ry(fl(A−B))`, which realized `B + fl(A−B)` on the true edge (0.858 rad wrong on
// `pi / 1e16`, `inf` from the finite arms `±DBL_MAX`) and so admitted only
// CONSTANT arms under a placeholder 2^-40 rad residual bound; the dm7f.6 round-1
// draft (`Ry(B); Ry_c(−B); Ry_c(A)`) read `B` twice. Both are retired.
//
// WHY THE `cq_theta` SPELLING AND NOT `cqrt_ry_<W>` DIRECTLY: the register is
// still a `cq_*` SSA value at this point (for an f64 register it is
// `double`-typed, so a direct `cqrt_*` call would be ill-typed), and every
// PRE-`lowerRotations` wire walker recognizes a gate by the `@cq_theta_`
// spelling with the wire at arg 0 (PRD §6, the hoist-and-defer rationale).
//
// Ry stem: NO CFG surgery, NO hoist, NO `RegionFlatten`, NO `cqrt_alloc` beyond a
// runtime-base state prep's own, NO `cqrt_cswap`, NO reverse-play. The only
// rails are the user's register and the one flag.
//
// Correctness rests on analytic reasoning and the byte twins, NOT on
// `opt -verify` (Rule 2). Mutates the module IR and `taint`.

#ifndef CQ_IRPASS_ANGLE_SELECT_EMIT_H_
#define CQ_IRPASS_ANGLE_SELECT_EMIT_H_

namespace cq {

class WidthDispatch;
struct ControlRegion;
struct TaintSet;

// Lower one accepted `AngleSelectRegion`. Every DECLINE is LOUD
// (`diagnoseUnderControl`) and precedes the FIRST emitted instruction: step 0
// re-validates the plan by SSA identity, step 0b re-asks S4's SEMANTIC half
// (exactly one TAINTED compare operand and a mintable flag — a preceding
// `SwitchDataMux` region's RAUW can turn the compare Q+Q; bd drbq Inc 2b
// round-1 lenses L4-1/L1-1). The later `return` (mint null) is UNREACHABLE, by
// that re-ask AND by `DS_Error` calling `exit(1)`.
void emitAngleSelectRegion(const ControlRegion &R, WidthDispatch &wd,
                           TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_ANGLE_SELECT_EMIT_H_
