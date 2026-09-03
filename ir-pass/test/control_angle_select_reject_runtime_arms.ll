; control_angle_select_reject_runtime_arms.ll — DECLINE (S1, the ARM-VALUE
; fence): BOTH select arms are genuine RUN-TIME classical values (function
; parameters), so no compile-time difference exists and the by-difference
; lowering's preconditions cannot be established.
;
;     int f(double x, double y) { ... if (q == 5) r = cq_theta(r, x);
;                                     else       r = cq_theta(r, y); }
;
; *** THIS FILE REPLACES `control_angle_select_ry_arg_angles.ll`, WHICH WAS AN
; *** ACCEPT FIXTURE FOR EXACTLY THIS SHAPE. The flip is the Rule-12 red-green of
; *** the Increment-2b CLEARANCE ruling (bd `test_C_libtooling-drbq`, the
; *** independent Rule-13 clearance review, finding F-11 / blocker B1, graded
; *** CONFIRMED-MISCOMPILE and BLOCKING; orchestrator decision: ship option (2),
; *** the accept narrows to CONSTANT arms).
;
; WHY THE SHAPE IS REFUSED, in the clearance's own terms. The by-difference
; identity `R(A) = R(B)·R(A−B)` is exact over the REALS. What the machine realizes
; on the TRUE edge is `B + fl(A−B)`, and for RUN-TIME arms the compiler
; SYNTHESIZES the `fsub` — an arithmetic operation the SOURCE NEVER WROTE. Two
; consequences ride on it and NEITHER is fenceable at compile time:
;
;   (i)  ROUNDING, UNBOUNDED IN ABSOLUTE RADIANS. `|delta| <= 1/2 ulp(A−B)`,
;        which is `2^-54` rad for the flagship `0.9/0.3` and `0.858` rad for
;        `pi / 1e16`. Measured by the clearance from PLAIN C with the two angles
;        as `volatile double`s (`clearance2b/p3/r01_rt_pi_sel.c`): the emitted
;        stream is `cqrt_ry_i32(h1, 0x1.1c37937e08p+53)` then
;        `cqrt_ry_i32_controlled(h2, h1, -0x1.1c37937e07ffep+53)`, i.e. a realized
;        true-arm angle of **4.0 rad where the source wrote `Ry(pi)`**.
;   (ii) NON-FINITENESS, WHICH IS NOT A ROUNDING OF ANYTHING. `fl(A−B)` can be
;        `inf` or `NaN` from two perfectly ORDINARY FINITE arms
;        (`clearance2b/p3/r02_rt_ovf_sel.c`, A = +8.98846567431158e307, B = −A →
;        `cqrt_ry_i32_controlled(h2, h1, inf)`), and a run-time NaN arm reaches
;        the slot directly (`r03_rt_nan_sel.c`). The clearance also reproduced
;        both on the **Rz** stem (`r04_rt_rz_pi_sel.c`) and on a mul-DERIVED base
;        (`r05_rt_ovf_mul_meas_sel.c`).
;
; THE CONSTANT SPELLINGS OF THE SAME PAIRS ALREADY DECLINED
; (`control_angle_select_reject_rounding_pi_1e16.ll`, `reject_inf_arm.ll`,
; `reject_overflow_difference.ll`) — so before this change the *fence depended on
; how the user spelled the angle*, and the PRE-2b binary declined the run-time
; spelling LOUDLY as well. Prime Directive: a DISPROVEN precondition declines.
;
; THE "IT IS THE SAME ARITHMETIC THE MANUAL TWIN PERFORMS" DEFENCE DOES NOT APPLY
; HERE, AND THAT IS THE FACT THAT DECIDED IT (clearance observation 1). The
; natural manual by-difference twin `r = R(r,B); if (c) r = R(r, A−B);` with
; RUN-TIME arms **DECLINES `control flow under quantum control` on BOTH binaries**
; — measured five ways (`r01_twn`, `r06` with the `fsub` hoisted before the
; branch, `r07_twn` even at delta = 0, `rt/t_param_twin`, `c30/c31_twn`): `clang
; -O1` SINKS the `fsub` into the arm block and `inPlaceRotationArmTheta` refuses a
; stray op there. The only compilable "twin" is `tools/angle_select_twin_matrix.py`'s
; `args` cells, which take the difference in as a PARAMETER and therefore perform
; no subtraction at all. So the residual was reachable ONLY through 2b: it is not
; inherited from a shape the compiler already accepted.
;
; WIDENING BACK IS THE OWNER'S CALL, AND IT IS ONE LINE. Option (1) of the
; three-way owner-desk item (notes §9 / PRD §12.3) accepts run-time arms with the
; residual documented: `angleSelectArmsAdmissible`'s run-time branch returns
; `true` again, this fixture and its two siblings flip back to accepts, and the
; twin matrix's `args` cells leave the EXPECTED-DECLINE-RUNTIME-ARMS class. It
; requires an explicit ruling that round-to-nearest angle arithmetic AND
; non-finite angle arithmetic are both IN the semantic model. Option (3), the
; two-controlled form `x(f)·R_c(f,h,B)·x(f)·R_c(f,h,A)`, performs no subtraction
; at all and is exact for run-time arms too.
;
; NO NEW DIAGNOSTIC STRING: S1 returns `NotApplicable`, so `SelectClassify`'s
; gate-3 `rotation angle` decline fires — byte-identical to the PRE-2b
; disposition of this exact module.
;
; ORACLE DISPOSITION: the pre-2b binary declines this module with the SAME string.
; It is therefore NOT red-green against the oracle; its red-green is against the
; PREVIOUS state of THIS tree, where `control_angle_select_ry_arg_angles.ll`
; asserted the accepted stream line for line.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, double %x, double %y) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double %x, double %y
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; NOTHING OF THE 2b STREAM IS EMITTED — not the synthesized difference, not the
; unconditional twin, not the flag. `opt` exits non-zero and lowers nothing, so
; these run over the diagnostic text rather than over a module; they are here to
; make a REGRESSION to the accepted stream loud rather than to re-assert the
; decline (which the CHECK above owns).
; CHECK-NOT: fsub double
; CHECK-NOT: cqrt_ry_i32_controlled
