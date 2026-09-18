; control_predmux_accept_inloop_rail_leaf_twin.ll — the ALREADY-SHIPPED spelling
; and the baseline its `br` sibling inherits clearance from (bd fn1q increment 3,
; Rule-13 round 1 F-8).
;
; The same program written with plain `select`s. It accepts on the PRE-INCREMENT
; ORACLE (measured, exit 0) and on the subject with an identical stream.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; The loop is still ROLLED.
; CHECK: br i1 %{{.*}}, label %exit, label %head
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @probe() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %in, %latch ]
  %x = phi i32 [ 5, %entry ], [ %a4, %latch ]
  %y = phi i32 [ 6, %entry ], [ %b5, %latch ]
  %x1 = add i32 %x, -3
  %y1 = add i32 %y, -4
  %a4 = select i1 %b, i32 %x1, i32 %x
  %b5 = select i1 %b, i32 %y1, i32 %y
  br label %latch
latch:
  %in = add i32 %i, 1
  %d = icmp eq i32 %in, 3
  br i1 %d, label %exit, label %head
exit:
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %mb to i32
  %s1 = add i32 %m1, %m2
  %s = add i32 %s1, %z
  ret i32 %s
}
