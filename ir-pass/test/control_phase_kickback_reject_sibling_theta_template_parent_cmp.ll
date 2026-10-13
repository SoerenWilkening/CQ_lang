; control_phase_kickback_reject_sibling_theta_template_parent_cmp.ll — DECLINE since bd test_C_libtooling-57ch.3 (batch 053;
; the diagnostic changed: the stale read is placed, a different hazard remains).
;
; The stale `zext %b` is now PLACED (57ch.3) before `%c`. What still declines is
; the condition wire: `%cmp` derives from `%b`, whose rail `%c` relabels (the fan-out
; of `%t`) before the kickback consumes the condition — the condition-wire fence
; (`2c`). The read-first twin (the `zext` written before `%c`, batch-053 L3 probe)
; declines with the same string on the pre-053 binary.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; control_phase_kickback_reject_sibling_theta_template_parent_cmp.ll — DECLINE
; (bd 3qlq.4, F-1b-1's COMPARE twin — the PRE-EXISTING half): the same two
; sibling in-place Ry on a template parent, with the branch on `zext(b) == 1`.
; This program ACCEPTED on `main` 170ede1 with the same wrong stream (the
; compare's positional prong starts at the COMPARE, after the sibling, and the
; walker's ancestry stopped at the template parent). It declines now — in the
; OPCODE layer, because the `zext` in data position is the first stale read the
; pass-wide `declineStaleRecordOps` guard (which runs before control detection)
; sees; the control layer's `condWireDisposition` would refuse the same program
; one stage later. Pinned on the string that fires.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %t = trunc i32 %q to i1
  %b = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %c = call i1 @cq_theta_i1(i1 %t, double 9.000000e-01)
  %z = zext i1 %b to i32
  %cmp = icmp eq i32 %z, 1
  br i1 %cmp, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %c)
  %zz = zext i1 %m to i32
  ret i32 %zz
}
