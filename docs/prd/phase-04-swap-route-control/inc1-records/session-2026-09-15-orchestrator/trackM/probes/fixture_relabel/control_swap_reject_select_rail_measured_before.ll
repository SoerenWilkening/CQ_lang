; control_swap_reject_select_rail_measured_before.ll — DECLINE (bd
; test_C_libtooling-r9e5, Inc 1b-B.1, PRD §14.3 rung 2): the `_Bool` register is
; MEASURED before the select that reads it, in the SAME BLOCK. A measured
; register is classical from there on, so controlling the copy merge on it would
; mean CNOT-copying an already-collapsed rail into the flag and routing `%out` on
; a classical bit the source never asked for — the rail mirror of the compare
; path's `MeasuredEarly` (bd atk9), Rule 6's loud-reject class.
;
; RED-GREEN: on `main` 87d0699 this module declined `bare i1 register condition`
; (the blanket 1b-B decline); the string it fires now is the one the rung owns.
; ITS DISCRIMINATOR IS ONE LINE AWAY — move the measure BELOW the select and it
; ACCEPTS (`control_swap_select_rail_measure_after.ll`), which is the whole
; reason `railMeasuredBeforeReadPoint` takes a read POINT rather than a block.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %m = call i1 @cq_measure_i1(i1 %b)
  %a = select i1 %m, i32 2, i32 5
  %n = call i32 @cq_measure_si32(i32 %a)
  %z = zext i1 %m to i32
  %r = add i32 %n, %z
  ret i32 %r
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
