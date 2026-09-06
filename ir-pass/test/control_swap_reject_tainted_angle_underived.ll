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
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: rotation angle under quantum control
; NEW: cq controlled lowering: rotation angle under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang = sitofp i32 %q to double                 ; TAINTED angle producer
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %ang)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: rotation angle under quantum control
