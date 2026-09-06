; control_phase_nest_reject_tainted_angle.ll — DECLINE. A QUANTUM-DERIVED angle
; in a nest arm's `cq_phi` (Rule 3: the angle operand is classical, per
; operand-use).
;
; The emitted gate would be `cqrt_rz_i1(g, <i32 runtime handle>)` — a fixed
; per-run tag standing in for a value in superposition, which admits no fixed
; unitary. It is the f64/angle miscompile family, and it declines in the SAME
; dialect and with the SAME string the retired suffixed family used, so no
; fixture learns a new spelling for an unchanged rule.
;
; The check is per ARM and covers BOTH levels; this module puts the tainted angle
; on the INNER arm specifically, because the inner arm is the one whose gate
; rides the conjunction ancilla rather than a leaf flag.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)

define i32 @example(i32 %u0, double %a0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang = call double @cq_theta_f64(double %a0, double 1.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double 2.500000e-01)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %inner, label %merge
inner:
  call void @cq_phi(double %ang)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: rotation angle under quantum control
