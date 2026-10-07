; spec_reject_clone_classical_loop.ll — DECLINE (bd p3kd.7.8, the accept boundary
; of the mechanical Bennett reverse). A lifted body whose loop is PURELY CLASSICAL
; (`c = c*c + i` over a classical `n`; clang -O1 cannot close it) and whose only
; gate is the `add q, c` after the loop. Main's stage list runs on the clone and
; leaves the classical loop as a branch (taint is the only Q/C boundary), so the
; clone stays multi-block, and the Bennett wrap's mechanical reverse needs one
; straight-line block: the `lowerCloneControl` backstop declines LOUDLY.
;
; This is a GAP, not a design limit (R1): only the gate stream must be
; path-independent, and here every gate sits in the exit block, so a reverse placed
; there is exact. Filed as bd p3kd.7.9 (reverse a body whose gates lie on every
; path, outside any loop; the message also names a classical loop "tainted"). The
; same decline before p3kd.7.8 (measured on 4c323c3c). Main compiles the same body
; in the caller.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}in function __cq_q_addsum_01 {{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: define

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @addsum(i32 noundef %q, i32 noundef %n) {
entry:
  %pos = icmp sgt i32 %n, 0
  br i1 %pos, label %loop, label %exit

loop:
  %i = phi i32 [ %inc, %loop ], [ 0, %entry ]
  %c = phi i32 [ %next, %loop ], [ 1, %entry ]
  %sq = mul nsw i32 %c, %c
  %next = add nsw i32 %sq, %i
  %inc = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inc, %n
  br i1 %done, label %exit, label %loop

exit:
  %cf = phi i32 [ 1, %entry ], [ %next, %loop ]
  %r = add nsw i32 %cf, %q
  ret i32 %r
}

define i32 @probe(i32 %x, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %r = call i32 @addsum(i32 %q, i32 %n)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
