; control_classical_call_arm_twin_reject_irreducible.ll — DECLINE (batch 053, bd dm7f.27
; decline neighbour). Hand IR: a callee whose CFG cycle has TWO entries (`%a` and
; `%b` are both reached from `%entry`), i.e. no natural loop and no header to carry a
; trip counter. C reaches this shape only through `goto` into a loop body.
; `containsIrreducibleCFG` (TwinTotality.h `loopBounds`) refuses it, so the twin route
; answers Unsafe; the Direct route needs `willreturn`, absent here. The 6.5 arm
; declines loudly.
; HONEST SCOPE: a goal-1 gap, not physics: every path here terminates within 100
; increments. A counter on every cycle entry (or node splitting) would bound it.
; Retire this row when irreducible cycles get a counter. Accept neighbour:
; control_classical_call_arm_twin_accept_loop_callee.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error: {{.*}}in function example i32 (i32, i32): cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @h(i32 noundef %x) #0 {
entry:
  %c = icmp sgt i32 %x, 0
  br i1 %c, label %a, label %b
a:
  %pa = phi i32 [ %x, %entry ], [ %nb, %b ]
  %na = add i32 %pa, 1
  %ca = icmp slt i32 %na, 100
  br i1 %ca, label %b, label %exit
b:
  %pb = phi i32 [ %x, %entry ], [ %na, %a ]
  %nb = add i32 %pb, 2
  %cb = icmp slt i32 %nb, 100
  br i1 %cb, label %a, label %exit
exit:
  %r = phi i32 [ %na, %a ], [ %nb, %b ]
  ret i32 %r
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @h(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind memory(none) }
