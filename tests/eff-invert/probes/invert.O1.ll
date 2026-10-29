; ModuleID = 'invert.c'
source_filename = "invert.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p_flat(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  tail call void @__cq_invert_begin() #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !6
  tail call void @cq_phi(double noundef %3) #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !7
  tail call void @__cq_invert_end() #3
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #3
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @__cq_invert_begin() local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare void @__cq_invert_end() local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_arms(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  tail call void @__cq_invert_begin() #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !8
  %8 = mul nsw i32 %7, %2
  %9 = icmp eq i32 %8, %3
  %10 = select i1 %9, double %4, double %5
  tail call void @cq_phi(double noundef %10) #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !9
  tail call void @__cq_invert_end() #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_nest(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  tail call void @__cq_invert_begin() #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !10
  %8 = icmp sgt i32 %7, %2
  br i1 %8, label %9, label %12

9:                                                ; preds = %6
  tail call void @cq_phi(double noundef %4) #3
  %10 = icmp slt i32 %7, %3
  br i1 %10, label %11, label %12

11:                                               ; preds = %9
  tail call void @cq_phi(double noundef %5) #3
  br label %12

12:                                               ; preds = %6, %11, %9
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !11
  tail call void @__cq_invert_end() #3
  %13 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_around(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %8 = icmp eq i32 %7, %3
  br i1 %8, label %9, label %10

9:                                                ; preds = %6
  tail call void @cq_phi(double noundef %4) #3
  br label %10

10:                                               ; preds = %6, %9
  tail call void @__cq_invert_begin() #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !12
  %11 = icmp eq i32 %7, %2
  br i1 %11, label %12, label %13

12:                                               ; preds = %10
  tail call void @cq_phi(double noundef %5) #3
  br label %13

13:                                               ; preds = %10, %12
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !13
  tail call void @__cq_invert_end() #3
  %14 = mul nsw i32 %7, 3
  %15 = icmp sgt i32 %14, %3
  br i1 %15, label %16, label %17

16:                                               ; preds = %13
  tail call void @cq_phi(double noundef %4) #3
  br label %17

17:                                               ; preds = %16, %13
  %18 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %18
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_two(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #2
  tail call void @__cq_invert_begin() #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !14
  %8 = add nsw i32 %7, %6
  %9 = icmp sgt i32 %8, 3
  br i1 %9, label %10, label %11

10:                                               ; preds = %5
  tail call void @cq_phi(double noundef %3) #3
  br label %11

11:                                               ; preds = %5, %10
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !15
  tail call void @__cq_invert_end() #3
  tail call void @__cq_invert_begin() #3
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !16
  %12 = xor i32 %7, %6
  %13 = and i32 %12, 1
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %16, label %15

15:                                               ; preds = %11
  tail call void @cq_phi(double noundef %4) #3
  br label %16

16:                                               ; preds = %11, %15
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #3, !srcloc !17
  tail call void @__cq_invert_end() #3
  %17 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  %18 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  %19 = add nsw i32 %18, %17
  ret i32 %19
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
!6 = !{i64 2147511563}
!7 = !{i64 2147511619}
!8 = !{i64 2147513488}
!9 = !{i64 2147513544}
!10 = !{i64 2147515413}
!11 = !{i64 2147515469}
!12 = !{i64 2147517338}
!13 = !{i64 2147517394}
!14 = !{i64 2147520278}
!15 = !{i64 2147520334}
!16 = !{i64 2147520430}
!17 = !{i64 2147520486}
