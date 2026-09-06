; control_angle_select_phase_reject_empty_arm_phi.ll — DECLINE, and it is a
; RECORDED OVER-DECLINE with its cause measured (bd test_C_libtooling-3qlq Inc 1).
;
; The merge-tail angle phi (`control_phase_kickback_ifelse_tail_phi.ll`) is
; accepted when the region's arms carry gates. THIS variant — both arms genuinely
; EMPTY, the whole content being the muxed angle — NEVER REACHES THAT CLASSIFIER,
; and the reason is a stage 120 lines earlier in the pipeline:
;
;   `flattenPredMuxRegions` (CQLoweringPass.cpp:199, before `detectControlRegions`
;   at :322) claims any region whose arms are pure straight-line, RAUWs the merge
;   φ to a `select` chain and linearizes — but leaves the select and its consumer
;   in DIFFERENT blocks. `classifyAngleSelect`'s PRE-EXISTING S6 position clause
;   (`Sel->getParent() != BB || Cond->getParent() != BB`) then refuses it, and
;   gate 3 renders the generic `rotation angle` message.
;
; MEASURED, not inferred: the failing gate was localized by instrumenting all 22
; `NotApplicable` returns of `classifyAngleSelect` (it is #20 = S6); the
; instrumentation was reverted.
;
; ⚠ NOT REACHABLE FROM PLAIN C, which is why it is filed rather than fixed:
; `if (c) cq_phi(A); else cq_phi(B);` is MEASURED to arrive as a ONE-BLOCK
; `select`, which ACCEPTS (`control_angle_select_phase_constants.ll`). This module
; is hand-written IR. Widening S6 is a change to a positional fence in the Rule-13
; lowering core and belongs to its own increment with its own adversarial round —
; over-declining is safe; over-accepting is the unforgivable bug.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm1, label %arm2
arm1:
  br label %merge
arm2:
  br label %merge
merge:
  %a = phi double [ 9.000000e-01, %arm1 ], [ 3.000000e-01, %arm2 ]
  call void @cq_phi(double %a)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: rotation angle under quantum control
