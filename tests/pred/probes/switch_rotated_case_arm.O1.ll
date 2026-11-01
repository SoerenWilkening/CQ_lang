; ModuleID = 'p1.c'
source_filename = "switch_rotated_case_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define i32 @pp(i32 %x0) #0 {
s0:
  br label %start
start:
  %x = call i32 @cq_theta_si32(i32 %x0, double 0.5) #2
  %s = and i32 %x, 3
  switch i32 %x, label %E [ i32 1, label %A
                            i32 2, label %J ]
A:
  %x2 = call i32 @cq_theta_si32(i32 %x, double 0.7) #2
  br label %J
J:
  %xj = phi i32 [ %x, %start ], [ %x2, %A ]
  call void @cq_phi(double 0.3) #3
  call void @cq_phi(double 0.1) #3
  br label %E
E:
  %r = phi i32 [ %x, %start ], [ %xj, %J ]
  ret i32 %r
}
declare i32 @cq_theta_si32(i32 noundef, double noundef) #1
declare void @cq_phi(double noundef) #1
declare i32 @cq_measure_si32(i32 noundef) #1
declare void @abort() #4
attributes #0 = { nounwind }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
attributes #4 = { noreturn nounwind }
