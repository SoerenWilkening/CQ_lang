; lowering_control_switch_gated.ll — Phase 4.1 WP18 (PRD §8.5, epic `-aht.3`),
; negative (RED). The one multi-way shape that does NOT fold into the
; switch→select-chain normalization (WP15) or the angle-select-chain (WP16): a
; cascade of arms with ARBITRARY SIDE-EFFECTING gate bodies — distinct gate
; SEQUENCES per case (here case 2 applies TWO `cq_phi`s, case 1 and default
; one), not a single value or rotation angle. There is no value to select; each
; arm's ops must become `_controlled` on its eq-flag (the WP8 symmetric
; two-content-arm diamond generalized to an N-way false-arm chain).
;
; Diagnose-first spike (`-aht.3`, 2026-06-02): confirmed `clang -O1` KEEPS this
; as a `SwitchInst` with gate-body arms reconverging on an N-way `φ` (it does
; NOT reshape to a select chain — the differing gate counts are not a value
; mux). So it is SAFE today: WP15 declines (arms are non-empty), and the WP12
; tainted-`switch` guard diagnoses it (no silent miscompile). This fixture pins
; that safety; it becomes POSITIVE when WP18 lands the N-way controlled
; substitution.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  switch i32 %q, label %dflt [
    i32 1, label %c1
    i32 2, label %c2
  ]
c1:
  %v1 = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)
  br label %merge
c2:
  %v2a = call i32 @cq_phi_si32(i32 %v, double 2.000000e-01)
  %v2b = call i32 @cq_phi_si32(i32 %v2a, double 3.000000e-01)
  br label %merge
dflt:
  %vd = call i32 @cq_phi_si32(i32 %v, double 9.000000e-01)
  br label %merge
merge:
  %vm = phi i32 [ %v1, %c1 ], [ %v2b, %c2 ], [ %vd, %dflt ]
  %m = call i32 @cq_measure_si32(i32 %vm)
  ret i32 %m
}
