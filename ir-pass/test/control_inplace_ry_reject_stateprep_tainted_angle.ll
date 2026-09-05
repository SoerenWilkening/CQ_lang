; control_inplace_ry_reject_stateprep_tainted_angle.ll — DECLINE (R2): the
; state-prep theta's ANGLE is quantum-derived.
;
;     int r = 0;  if (q == 5) r = cq_theta(0, (double)q);
;
; Rule 3: the arg-1 angle operand is CLASSICAL, always. A quantum-derived angle
; has no fixed unitary and the emitter would replay it as a handle tag. R2 is
; asked in the rotation clause (not by `taintedAngleGate`, which walks a `cq_phi`
; SPINE and never inspects a theta at the arm incoming) and is UNCHANGED by
; Inc 4 — it runs BEFORE the state-prep block, so a tainted angle is refused on
; the angle, never on the seed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ad = sitofp i32 %q to double
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double %ad)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
