; control_inplace_ry_reject_inloop_j4.ll — DECLINE (PRD §13.2 row R6-2), the
; **j4** shape: the PRE-region name of the rotated register read after the
; region.
;
;     for (...) { if (q > 5) cq_theta(&r, .9); }
;     return cq_measure(r) + cq_measure(r_pre);   // r_pre: the header phi `%r`
;
; Pre-3qlq the body also wrote `d = cq_phi(r_pre, .2)`, an Rz ALIAS HOP off the
; member `%r`, and the exit measured `%d`; 3qlq deleted that uncontrolled phase,
; so the exit now reads `%r` itself. R6's per-activation certificate asks the
; same question of that read: every `BI -> use` path must re-execute `%r` first.
; It does not — `BI -> merge -> exit` stays inside one activation — so the record
; is stale where it is used: it names the SOURCE'S `r` before the arm fired, and
; the register has since been relabelled.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  %n = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %m, %n
  ret i32 %s
}
