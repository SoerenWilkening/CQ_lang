; control_swap_reject_tainted_angle_underived.ll — DECLINE: quantum-derived
; ANGLE, un-derived (plain theta) base.
;
; The un-derived twin of control_swap_reject_tainted_angle.ll: arms rotate the
; theta result %q directly, but the arm gate's angle is `sitofp(%q)` — tainted.
; This shape was ACCEPTED (and silently mis-lowered) even BEFORE the derived-
; base change — the angle-classicality hole predates it; the
; test_C_libtooling-9hh §8 adversarial review (2026-06-10) found it while
; probing the derived variant. The taintedAngleGate guard closes both at the
; region level. (The straight-line no-control-flow tainted-angle hole remains a
; separate, loud-but-ugly failure — tracked in its own bd issue.)
;
; PRODUCER CHOICE (test_C_libtooling-bxv re-shape): the original opaque-call
; producer (`call double @ext(i32 %q)`) now declines EARLIER at the module-wide
; taint-escape guard (pinned by lowering_reject_taint_escape_opaque_call.ll);
; a sitofp producer is not an escape, keeping this fixture pointed at the
; region ARM-gate angle check over an UN-DERIVED base it exists to pin.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang = sitofp i32 %q to double                 ; TAINTED angle producer
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %ang)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK: error{{.*}}rotation angle under quantum control
