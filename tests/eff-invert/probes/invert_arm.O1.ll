; ModuleID = 'invert_arm.c'
source_filename = "invert_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p_armpair(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %8 = icmp eq i32 %7, %2
  br i1 %8, label %9, label %11

9:                                                ; preds = %6
  tail call void @cq_phi(double noundef %3) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !6
  %10 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef %4) #3
  tail call void @cq_phi(double noundef %4) #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !7
  tail call void @__cq_invert_end() #5
  br label %12

11:                                               ; preds = %6
  tail call void @cq_phi(double noundef %5) #4
  br label %12

12:                                               ; preds = %11, %9
  %13 = phi i32 [ %10, %9 ], [ %7, %11 ]
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: noduplicate
declare void @__cq_invert_begin() local_unnamed_addr #2

; Function Attrs: noduplicate
declare void @__cq_invert_end() local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_armbegin(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5, double noundef %6, double noundef %7, double noundef %8) local_unnamed_addr #0 {
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %11 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #3
  %12 = icmp eq i32 %10, %4
  br i1 %12, label %13, label %15

13:                                               ; preds = %9
  tail call void @cq_phi(double noundef %5) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !8
  %14 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef %6) #3
  br label %17

15:                                               ; preds = %9
  %16 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef %7) #3
  br label %17

17:                                               ; preds = %15, %13
  %18 = phi i32 [ %14, %13 ], [ %16, %15 ]
  %19 = tail call i32 @cq_theta_si32(i32 noundef %18, double noundef %8) #3
  %20 = icmp sgt i32 %19, 2
  br i1 %20, label %21, label %22

21:                                               ; preds = %17
  tail call void @cq_phi(double noundef %8) #4
  br label %22

22:                                               ; preds = %17, %21
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !9
  tail call void @__cq_invert_end() #5
  %23 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef %5) #3
  %24 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  %25 = tail call i32 @cq_measure_si32(i32 noundef %23) #4
  %26 = add nsw i32 %25, %24
  ret i32 %26
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_armend(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5, double noundef %6, double noundef %7, double noundef %8) local_unnamed_addr #0 {
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %11 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #3
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !10
  %12 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef %5) #3
  %13 = icmp eq i32 %10, %4
  br i1 %13, label %14, label %16

14:                                               ; preds = %9
  %15 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef %6) #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !11
  tail call void @__cq_invert_end() #5
  tail call void @cq_phi(double noundef %6) #4
  br label %18

16:                                               ; preds = %9
  %17 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef %7) #3
  br label %18

18:                                               ; preds = %16, %14
  %19 = phi i32 [ %15, %14 ], [ %17, %16 ]
  %20 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef %8) #3
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_armnest(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5, double noundef %6, double noundef %7, double noundef %8) local_unnamed_addr #0 {
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %11 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #3
  %12 = icmp sgt i32 %10, %4
  br i1 %12, label %13, label %20

13:                                               ; preds = %9
  %14 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef %6) #3
  %15 = icmp slt i32 %14, %5
  br i1 %15, label %16, label %18

16:                                               ; preds = %13
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !12
  %17 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef %7) #3
  br label %18

18:                                               ; preds = %16, %13
  %19 = phi i32 [ %17, %16 ], [ %10, %13 ]
  tail call void @cq_phi(double noundef %8) #4
  br label %20

20:                                               ; preds = %18, %9
  %21 = phi i32 [ %19, %18 ], [ %10, %9 ]
  %22 = phi i32 [ %14, %18 ], [ %11, %9 ]
  %23 = tail call i32 @cq_theta_si32(i32 noundef %22, double noundef %8) #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !13
  tail call void @__cq_invert_end() #5
  %24 = tail call i32 @cq_measure_si32(i32 noundef %21) #4
  %25 = tail call i32 @cq_measure_si32(i32 noundef %23) #4
  %26 = add nsw i32 %25, %24
  ret i32 %26
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noduplicate "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
attributes #5 = { noduplicate nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{i64 2147512357}
!7 = !{i64 2147513427}
!8 = !{i64 2147516311}
!9 = !{i64 2147519409}
!10 = !{i64 2147524065}
!11 = !{i64 2147526149}
!12 = !{i64 2147531317}
!13 = !{i64 2147533401}
