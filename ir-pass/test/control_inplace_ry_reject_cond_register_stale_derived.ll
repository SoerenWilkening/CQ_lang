; control_inplace_ry_reject_cond_register_stale_derived.ll — DECLINE since bd test_C_libtooling-57ch.1 and 57ch.3 (batch 053;
; the diagnostic changed: the stale read is placed, a different hazard remains).
;
; The stale `add` is now PLACED (57ch.1/.3) at the end of `entry`, before the
; tainted region. What still declines is the region itself: its in-place Ry rotates
; the CONDITION register `q` under its own control (`2c`). The read-first twin (the
; `add` written in `entry`, batch-053 L3 probe) declines with the same string on the
; pre-053 binary.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: error: {{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; control_inplace_ry_reject_cond_register_stale_derived.ll — DECLINE: the
; adversarial neighbour of the dm7f.4 accept. A value DERIVED from the condition
; register is read AFTER the gate through the register's pre-Ry name.
;
;     int q = u; cq_theta(&q, .5);
;     int d = q + 1;
;     if (d > 5) cq_theta(&q, .3);
;     return cq_measure(q) + cq_measure(d);
;
; `-O1` folds the condition to q > 4 and SINKS `d = q + 1` below the region, so
; the `add` reads `%q`, the PRE-Ry SSA name, after the controlled Ry has
; relabelled q's rail. C says d is q_pre + 1; the lowered `add` would read the
; rotated register. That is the wrong-value class (bd 0njv), not the dephasing
; class the dm7f.4 warning covers, so it must stay LOUD. The IR below is the
; `-O1` output, verbatim.
;
; WHICH FENCE SPEAKS: the pass-wide stale-record guard (`declineStaleRecordOps`)
; runs before control detection and fires first; R6 in `classifyArms` would
; refuse the same read (`%q` is a member of the rotated base's wire and the
; `add` is not provably before the region). Measured identical on `main`
; 7b4e6359, where the region itself still declined.
;

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 4
  br i1 %c, label %arm, label %merge
arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %arm ], [ %q, %entry ]
  %d  = add nsw i32 %q, 1
  %m1 = call i32 @cq_measure_si32(i32 %qm)
  %m2 = call i32 @cq_measure_si32(i32 %d)
  %s  = add nsw i32 %m2, %m1
  ret i32 %s
}
