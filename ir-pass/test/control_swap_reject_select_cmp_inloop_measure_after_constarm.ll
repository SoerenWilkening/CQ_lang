; control_swap_reject_select_cmp_inloop_measure_after_constarm.ll — DECLINE
; (Track A.1, bd test_C_libtooling-r10v). HAND IR, deliberately: the same program
; as `..._reject_select_cmp_inloop_measure_after.ll` with a CONSTANT arm, with
; the select KEPT INSIDE THE BODY. `clang -O1` will not produce this — it
; LICM-hoists a loop-invariant select into the entry block, which is the
; legitimate accept `control_swap_select_cmp_inloop_hoisted_measure_after.ll` —
; so the shape is written by hand to pin the predicate rather than the scheduler:
; what makes the program wrong is the READ POINT being on the cycle, not the
; arm's value. The rail twin
; (`control_swap_reject_select_rail_inloop_measure_after_constarm.ll`) is hand IR
; for exactly the same reason.

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %b = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %b, 1
  br label %body

body:
  %acc = phi i32 [ 0, %entry ], [ %acc2, %body ]
  %i = phi i32 [ 0, %entry ], [ %inext, %body ]
  %a = select i1 %c, i32 7, i32 5
  %m1 = call i32 @cq_measure_si32(i32 %a)
  %m2 = call i32 @cq_measure_si32(i32 %b)
  %s1 = add i32 %m1, %acc
  %acc2 = add i32 %s1, %m2
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %body

exit:
  ret i32 %acc2
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
