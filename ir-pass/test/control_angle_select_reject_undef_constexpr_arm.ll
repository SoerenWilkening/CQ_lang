; control_angle_select_reject_undef_constexpr_arm.ll — DECLINE (S1, the ARM-VALUE
; fence): the TRUE arm is a `ConstantExpr` that CARRIES `undef` without BEING one.
;
; *** THIS FILE'S BODY WAS WRONG AT ROUND 1 AND WAS REPLACED, NOT DELETED ***
; (bd drbq Inc 2b, ROUND-2 Rule-13 review, lens R1 item 4). It shipped as
;
;     %ang = select i1 %c, double bitcast (i64 undef to double), double 3.0e-01
;
; with a header claiming it was "the only fixture that can tell `valueCarriesUndef`
; and a bare `isa<UndefValue>` apart". MEASURED FALSE: the LLVM-19 *parser* folds
; `bitcast (i64 undef to double)` to a plain `double undef` before the pass ever
; runs (`llvm-as | llvm-dis` round-trip), so `isa<UndefValue>` is TRUE of what the
; classifier actually sees and the cheap implementation stayed green. The same
; fold takes `extractelement (<2 x double> <double undef, ...>, i32 0)` and
; `bitcast (<1 x i64> undef to double)`.
;
; THE SHAPE BELOW SURVIVES LLVM-19 FOLDING. The arm is the reinterpreted ADDRESS
; of `@gu`, and `@gu`'s INITIALIZER carries `undef`:
;
;     @gu = global { i32, [4 x i8] } { i32 3, [4 x i8] undef }
;     %ang = select i1 %c, double bitcast (i64 ptrtoint (ptr @gu to i64) to double), ...
;
; `valueCarriesUndef` (`LiteralIntegrity.h`) is the NON-global-skipping predicate,
; so it descends through the `bitcast`, the `ptrtoint` and into the global's
; initializer and reports true; a bare `isa<UndefValue>` on the arm reports false.
;
; *** WHAT THIS FIXTURE PINS (rewritten for bd dm7f.6). The round-2 clause (1b),
; which refused every non-`ConstantFP` constant arm and so subsumed this one, was
; retired with the by-difference subtraction: a link-time constant arm now
; ACCEPTS (`control_angle_select_ry_constexpr_arm.ll`). That leaves
; `angleSelectArmsDefined`'s `valueCarriesUndef` as the ONLY clause that refuses
; this module, so this file is again its red-green witness: drop the undef
; question and this arm, a `ConstantExpr` carrying `undef`, would land verbatim in
; an emitted gate slot. The
; miscompile derivation is in `control_angle_select_reject_undef_arm.ll`; the
; predicate's comment is above `angleSelectArmsDefined` in
; `ir-pass/src/ArmClassify.cpp`.
;
; Reproducers: the original at round 1 from lens L7
; (`review2b/L7/ll/y3_undef_via_constexpr.ll`), the replacement from the round-2
; lens R1 (`review2b_r2/R1/probes/ce2/ce_undefglobal.ll`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

@gu = global { i32, [4 x i8] } { i32 3, [4 x i8] undef }

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double bitcast (i64 ptrtoint (ptr @gu to i64) to double), double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}
