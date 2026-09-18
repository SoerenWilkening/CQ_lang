; control_swap_value_reject_arm_cone_angle_select_consumer.ll — DECLINE, and it is
; one half of the RE-PROOF bd `test_C_libtooling-fn1q` increment 1 owed to
; `SwapRouteEmit.cpp`'s cross-region select pre-flight (Rule-13 round 1, F-2).
;
; THE OBLIGATION. That pre-flight's comment argued that an `AngleSelectRegion`'s
; select can never sit in a block another region ERASES, because "every region
; kind that erases an arm constrains that arm to a shape a `select` cannot
; satisfy", naming `valueArmIsPureChain`. Increment 1 made that FALSE: a `select`
; is now admissible in a value arm as a CLASSICAL CONE member. The comment's own
; retirement trigger demanded a re-proof, and this pair IS it.
;
; THIS HALF: the angle select's consumer is INSIDE the arm. The `cq_theta` call is
; a non-intrinsic `CallInst`, which cone conjunct **(K5)** refuses — so the ARM
; declines and nothing erases it. Its sibling
; control_swap_value_reject_arm_cone_angle_select_escape.ll is the
; consumer-outside-the-arm half, refused by **(K3)**.
;
; ⚠ IDENTICAL ON THE PRE-INCREMENT ORACLE (cq-opt 3368af1262695d7e4c…), which is
; the point: the increment did not open this and does not close it either — it
; moved WHICH conjunct holds it shut, and that is what the re-proof records.
;
; ⚠ A DECLINE FIXTURE'S PROPERTY IS PINNED BY THE `not` INVERSION, NOT BY ITS
; CHECKS: a `DS_Error` decline writes 0 bytes to stdout (Rule 12 hygiene defect
; (b)), so the message match on stderr and the non-zero exit are the assertion.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %ac = icmp slt i32 %q, 9              ; TAINTED condition
  %ang = select i1 %ac, double 1.0, double 2.0   ; the ANGLE select
  %r = call i32 @cq_theta_si32(i32 %p, double %ang)
  %v1 = add i32 %r, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
