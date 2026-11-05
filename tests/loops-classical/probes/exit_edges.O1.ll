; cq-j5mq: classically bounded loops with several classical exit edges into one exit block (from tests/spine/loop_exit_join.cpp).
source_filename = "exit_edges.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)


define i32 @two_exits(i32 %x0, double %th, i32 %n, i32 %k, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %g = icmp sgt i32 %n, 0
  br i1 %g, label %body, label %exit
exit:
  %r = phi i32 [ 0, %entry ], [ %i1, %latch ], [ 100, %brk ]
  %m = call i32 @cq_measure_si32(i32 %x)
  %s = add i32 %m, %r
  ret i32 %s
body:
  %i = phi i32 [ %i1, %latch ], [ 0, %entry ]
  %c = icmp eq i32 %x, %i
  br i1 %c, label %then, label %brk
then:
  call void @cq_phi(double %phi)
  br label %brk
brk:
  %e = icmp eq i32 %i, %k
  br i1 %e, label %exit, label %latch
latch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %exit, label %body
}


define i32 @arm_exits(i32 %x0, double %th, i32 %n, i32 %k, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %q = icmp eq i32 %x, 3
  br i1 %q, label %body, label %els
els:
  br label %join
body:
  %i = phi i32 [ %i1, %latch ], [ 0, %entry ]
  %c = icmp eq i32 %x, %i
  br i1 %c, label %then, label %brk
then:
  call void @cq_phi(double %phi)
  br label %brk
brk:
  %e = icmp eq i32 %i, %k
  br i1 %e, label %join, label %latch
latch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %join, label %body
join:
  %r = phi i32 [ 5, %els ], [ %i1, %latch ], [ 100, %brk ]
  %m = call i32 @cq_measure_si32(i32 %x)
  %s = add i32 %m, %r
  ret i32 %s
}


define i32 @nested_exits(i32 %x0, double %th, i32 %n, i32 %k, double %phi) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %g = icmp sgt i32 %n, 0
  br i1 %g, label %outer, label %exit
outer:
  %i = phi i32 [ %i1, %olatch ], [ 0, %entry ]
  br label %inner
inner:
  %j = phi i32 [ %j1, %ilatch ], [ 0, %outer ]
  %c = icmp eq i32 %x, %j
  call void @cq_phi(double %phi)
  %j1 = add i32 %j, 1
  %e = icmp eq i32 %j1, %k
  %e2 = icmp eq i32 %j1, %i
  br i1 %e2, label %exit, label %ilatch
ilatch:
  br i1 %e, label %olatch, label %inner
olatch:
  %i1 = add nuw nsw i32 %i, 1
  %d = icmp eq i32 %i1, %n
  br i1 %d, label %exit, label %outer
exit:
  %r = phi i32 [ 0, %entry ], [ %i, %olatch ], [ %i, %inner ]
  %m = call i32 @cq_measure_si32(i32 %x)
  %s = add i32 %m, %r
  ret i32 %s
}
