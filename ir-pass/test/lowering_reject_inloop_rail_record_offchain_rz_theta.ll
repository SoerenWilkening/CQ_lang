; lowering_reject_inloop_rail_record_offchain_rz_theta.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 2, finding F-1 — the DIAGONAL HOP).
;
;     int mark = q;
;     q = cq_phi(q, 1.0);        /* Rz: in place, DIAGONAL, not a gate */
;     q = cq_theta(q, 0.125);    /* Ry: in place, a gate — but its arg-0 is the Rz */
;     return cq_measure(mark) + cq_measure(q);
;
; WHY THIS IS A SEPARATE FIXTURE FROM THE STRAIGHT-LINE TWIN, AND WHY IT IS THE
; ONE THAT SETTLES THE SHAPE OF THE FIX. The obvious repair for F-1 — "also count
; every DIRECT in-place `cq_theta` user of a chain member" — does not fire here:
; the Ry's arg-0 is `%rz`, which is on no chain, so the Ry is not a direct user of
; any member and the record collapses stale anyway. Measured at the round-2 HEAD:
; `opt` exit 0, `cqrt_rz_i32(%h,1.0); cqrt_ry_i32(%h,0.125); measure(%h); measure(%h)`.
;
; So the rail is extended FORWARD through every in-place mutation of the same
; handle — INCLUDING the diagonal ones, which are followed but never counted as
; gates (Rz is diagonal; bd memory `rz-diag-flag-strip-invariant` and the reason
; control_swap_inloop_diamond.ll's pure-Rz rail still lowers). Following the
; non-gate hop is exactly what turns the Ry behind it into a visible gate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %g = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %g, %mid ], [ %q, %loop ]
  %qn = call i32 @cq_theta_si32(i32 %qm, double -5.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %rz = call i32 @cq_phi_si32(i32 %qn, double 1.000000e+00)      ; diagonal hop
  %post = call i32 @cq_theta_si32(i32 %rz, double 1.250000e-01)  ; arg-0 is NOT a member
  %m0 = call i32 @cq_measure_si32(i32 %qn)                       ; the STALE record
  %m1 = call i32 @cq_measure_si32(i32 %post)
  %s = add i32 %m0, %m1
  ret i32 %s
}
