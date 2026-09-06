; control_angle_select_phase_reject_two_consumers.ll — DECLINE. An angle select
; on the register-free PHASE stem with TWO CONSUMERS.
;
; S2's `Sel->hasOneUse()` is unchanged by the phase stem and is what refuses this.
; The reason is the emitter's, not the classifier's aesthetics: it mints ONE flag
; at ONE consumer, emits that consumer's two gates, then STRIPS and FREES the
; flag. A second consumer would either read a freed flag or need a second
; mint/strip pair whose interleaving with the first was never analysed.
;
; This is also the shape `clang -O1` produces from `if (c) { g1; g2; } else { g3;
; g4; }` — two gates per arm, folded into two selects on ONE compare — which the
; 2b classifier records as a follow-on rather than a defect. Note the CONTRAST
; with `control_phase_kickback_two_calls.ll`: N gates in one DIAMOND arm are an
; accept (one flag, N gates between one mint and one strip); N gates behind one
; SELECT are not, because each select is its own consumer.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  call void @cq_phi(double %ang)
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: rotation angle under quantum control
