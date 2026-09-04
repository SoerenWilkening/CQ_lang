; control_inplace_ry_reject_inloop_j4.ll — DECLINE (PRD §13.2 row R6-2), the
; **j4** shape: an `Rz` written on the PRE-region name of the rotated register,
; after the region, inside the body.
;
;     for (...) { if (q > 5) r = cq_theta(r, .9); d = cq_phi(r_pre, .2); }
;
; `%d` is an ALIAS HOP off the member `%r` (the header phi), and R6's
; per-activation certificate asks the same question of a hop as of a read: every
; `BI -> %d` path must re-execute `%r` first. It does not — `BI -> merge -> %d`
; stays inside one activation — so the record is stale where it is used.
;
; AND THE PHYSICS AGREES, which is why this is a decline and not a bookkeeping
; artefact: `Rz` applied AFTER the controlled `Ry` is a different unitary from `Rz`
; applied before it. Writing `cq_phi(r_pre, ...)` means the SOURCE'S `r` before the
; arm fired; the emitted gate would land on the relabelled register.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
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
  %d     = call i32 @cq_phi_si32(i32 %r, double 2.000000e-01)
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  %n = call i32 @cq_measure_si32(i32 %d)
  %s = add i32 %m, %n
  ret i32 %s
}
