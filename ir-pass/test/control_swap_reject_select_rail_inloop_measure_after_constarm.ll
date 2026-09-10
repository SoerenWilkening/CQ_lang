; control_swap_reject_select_rail_inloop_measure_after_constarm.ll — DECLINE (bd
; test_C_libtooling-r9e5, 1b-B.1; the hand-IR sibling of finding F-B1-1): the
; CONSTANT-arm select `b ? 2 : 5` kept inside a loop body with the measurement
; of `b` after it in the same block. `clang -O1` never produces this module —
; it LICM-hoists a loop-invariant select into the preheader, where the measures
; are genuinely downstream and `..._rail_measure_after.ll` accepts — so this
; pins the rung on the module itself: the same-block measure is AFTER the read
; point in program order and BEFORE its next execution around the back edge.
; Constant arms mean no other loop fence can pre-empt the string (a variant arm
; is in the plain-C sibling).
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc1, %loop ]
  %a = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %a)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %mb to i32
  %t = add i32 %m, %z
  %acc1 = add i32 %acc, %t
  %i1 = add i32 %i, 1
  %c = icmp eq i32 %i1, 3
  br i1 %c, label %exit, label %loop
exit:
  ret i32 %acc1
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
