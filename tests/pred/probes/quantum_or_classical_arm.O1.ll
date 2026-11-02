; ModuleID = 'quantum_or_classical_arm.c'
source_filename = "quantum_or_classical_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define noundef i32 @h(i32 noundef returned %0) local_unnamed_addr #0 {
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !6
  ret i32 %0
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #4
  %4 = icmp sgt i32 %3, 100
  br i1 %4, label %8, label %5

5:                                                ; preds = %2
  %6 = tail call i32 @h(i32 noundef %1)
  %7 = icmp sgt i32 %1, 100
  br i1 %7, label %8, label %10

8:                                                ; preds = %5, %2
  tail call void @cq_phi(double noundef 5.000000e-01) #3
  %9 = add nsw i32 %3, %1
  br label %12

10:                                               ; preds = %5
  %11 = mul nsw i32 %3, 3
  br label %12

12:                                               ; preds = %10, %8
  %13 = phi i32 [ %9, %8 ], [ %11, %10 ]
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  %15 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %16 = add nsw i32 %15, %14
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @g(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #4
  %5 = icmp sgt i32 %4, 100
  br i1 %5, label %9, label %6

6:                                                ; preds = %3
  %7 = tail call i32 @h(i32 noundef %1)
  %8 = icmp sgt i32 %1, 100
  br i1 %8, label %9, label %11

9:                                                ; preds = %6, %3
  %10 = add nsw i32 %4, %1
  br label %18

11:                                               ; preds = %6
  %12 = tail call i32 @h(i32 noundef %2)
  %13 = icmp sgt i32 %2, 5
  br i1 %13, label %14, label %16

14:                                               ; preds = %11
  %15 = sub nsw i32 %4, %2
  br label %18

16:                                               ; preds = %11
  %17 = mul nsw i32 %4, 3
  br label %18

18:                                               ; preds = %14, %16, %9
  %19 = phi i32 [ %10, %9 ], [ %15, %14 ], [ %17, %16 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  %21 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %22 = add nsw i32 %21, %20
  ret i32 %22
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{i64 376}
