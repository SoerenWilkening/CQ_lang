; control_inplace_ry_reject_stale_diag_alias_backward.ll — DECLINE: the rotated
; base IS the diagonal alias, and the wire's EARLIER name is measured after the
; region (control-in-place-PRD §4 R6; bd test_C_libtooling-drbq Inc 1, finding J).
;
;     int q = cq_theta(0,.7); int r = cq_theta(0,.3);
;     int mark = cq_phi(r, .1);
;     if (q == 5) mark = cq_theta(mark, .9);   // R == `mark`
;     return cq_measure(r) + cq_measure(mark) + cq_measure(q);
;
; The BACKWARD half of the same hole, and it is a separate fixture because it
; evades a different way: `mark`'s own direct users all pass R6 (the arm theta and
; the merge φ), while the stale read hangs off `r` — `mark`'s arg-0, one hop
; BEHIND the base. Measured before the fix: `ry_controlled(f,h1,.9)` followed by
; two `measure(h1)`, the first of which the source spells `r`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r    = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %mark = call i32 @cq_phi_si32(i32 %r, double 1.000000e-01)
  %c    = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %mark, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %mark, %entry ]
  %a  = call i32 @cq_measure_si32(i32 %r)
  %b  = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %a, %b
  ret i32 %s
}
