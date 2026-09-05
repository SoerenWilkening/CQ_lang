; control_inplace_ry_reject_stale_diag_alias_two_hop.ll — DECLINE: the stale read
; is TWO diagonal hops off the rotated register (control-in-place-PRD §4 R6; bd
; test_C_libtooling-drbq Inc 1, finding J).
;
;     int mark1 = cq_phi(r, .1);
;     int mark2 = cq_phi(mark1, .2);
;     if (q > 5) r = cq_theta(r, .9);
;     use(cq_measure(mark2));
;
; The closure has to be a FIXED POINT, not one hop: a one-hop fence would see
; `mark1` (a member) and stop, and `mark2` — still the same physical rail, since
; every `cq_phi` lowers in place on its arg-0 handle — would read the relabelled
; register. Measured before the fix: `rz(h1,.1); rz(h1,.2); … ry_controlled(f,h1,
; .9); measure(h1); measure(h1)`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r  = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c  = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %a  = call i32 @cq_measure_si32(i32 %r)
  %b  = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %a, %b
  ret i32 %s
}
