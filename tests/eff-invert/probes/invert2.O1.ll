; ModuleID = 'invert2.c'
source_filename = "invert2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p_inplace(i32 noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  tail call void @__cq_invert_begin() #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !6
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %2) #2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef %3) #2
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !7
  tail call void @__cq_invert_end() #3
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @__cq_invert_begin() local_unnamed_addr #1

declare void @__cq_invert_end() local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_cbr(i32 noundef %0, i32 noundef %1, double noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  %9 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #2
  tail call void @__cq_invert_begin() #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !8
  %10 = icmp sgt i32 %3, 0
  br i1 %10, label %11, label %15

11:                                               ; preds = %7
  %12 = mul nsw i32 %8, %3
  %13 = icmp eq i32 %12, %4
  br i1 %13, label %14, label %20

14:                                               ; preds = %11
  tail call void @cq_phi(double noundef %5) #3
  br label %20

15:                                               ; preds = %7
  %16 = add nsw i32 %8, %3
  %17 = icmp sgt i32 %16, %4
  br i1 %17, label %18, label %20

18:                                               ; preds = %15
  %19 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef %6) #2
  br label %20

20:                                               ; preds = %14, %11, %18, %15
  %21 = phi i32 [ %9, %14 ], [ %9, %11 ], [ %19, %18 ], [ %9, %15 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !9
  tail call void @__cq_invert_end() #3
  %22 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %23 = tail call i32 @cq_measure_si32(i32 noundef %21) #3
  %24 = add nsw i32 %23, %22
  ret i32 %24
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_reg(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %9 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %5) #2
  tail call void @__cq_invert_begin() #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !10
  %10 = icmp sgt i32 %3, 3
  br i1 %10, label %11, label %15

11:                                               ; preds = %7
  %12 = icmp sgt i32 %8, %4
  br i1 %12, label %13, label %20

13:                                               ; preds = %11
  %14 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef %5) #2
  tail call void @cq_phi(double noundef %6) #3
  br label %20

15:                                               ; preds = %7
  %16 = sub nsw i32 %4, %3
  %17 = icmp slt i32 %8, %16
  br i1 %17, label %18, label %20

18:                                               ; preds = %15
  %19 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef %6) #2
  br label %20

20:                                               ; preds = %13, %11, %18, %15
  %21 = phi i32 [ %14, %13 ], [ %9, %11 ], [ %19, %18 ], [ %9, %15 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !11
  tail call void @__cq_invert_end() #3
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #3
  %23 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %24 = add nsw i32 %23, %22
  ret i32 %24
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_cswitch(i32 noundef %0, i32 noundef %1, double noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  %9 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #2
  tail call void @__cq_invert_begin() #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !12
  %10 = mul nsw i32 %8, 3
  %11 = add nsw i32 %10, %4
  switch i32 %3, label %19 [
    i32 0, label %12
    i32 1, label %15
    i32 5, label %24
  ]

12:                                               ; preds = %7
  %13 = icmp eq i32 %11, 7
  br i1 %13, label %14, label %24

14:                                               ; preds = %12
  tail call void @cq_phi(double noundef %5) #3
  br label %24

15:                                               ; preds = %7
  %16 = icmp slt i32 %11, 2
  br i1 %16, label %17, label %24

17:                                               ; preds = %15
  %18 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef %6) #2
  br label %24

19:                                               ; preds = %7
  %20 = and i32 %8, 1
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %24, label %22

22:                                               ; preds = %19
  %23 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef %5) #2
  br label %24

24:                                               ; preds = %7, %14, %12, %17, %15, %22, %19
  %25 = phi i32 [ %23, %22 ], [ %9, %19 ], [ %9, %7 ], [ %18, %17 ], [ %9, %15 ], [ %9, %14 ], [ %9, %12 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !13
  tail call void @__cq_invert_end() #3
  %26 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %27 = tail call i32 @cq_measure_si32(i32 noundef %25) #3
  %28 = add nsw i32 %27, %26
  ret i32 %28
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{i64 2147511725}
!7 = !{i64 2147513811}
!8 = !{i64 2147516695}
!9 = !{i64 2147517765}
!10 = !{i64 2147521406}
!11 = !{i64 2147523490}
!12 = !{i64 2147527132}
!13 = !{i64 2147529216}
