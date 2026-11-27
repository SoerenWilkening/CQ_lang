; ModuleID = 'region_inplace.c'
source_filename = "region_inplace.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @rinp_sub(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %2, double noundef %3) #3
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !6
  %9 = sub i32 %7, %8
  %10 = icmp eq i32 %9, %4
  br i1 %10, label %11, label %12

11:                                               ; preds = %6
  tail call void @cq_phi(double noundef %5) #5
  br label %12

12:                                               ; preds = %6, %11
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !7
  tail call void @__cq_invert_end() #4
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %9) #5
  %14 = tail call i32 @cq_measure_ui32(i32 noundef %8) #5
  %15 = add i32 %14, %13
  ret i32 %15
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noduplicate
declare void @__cq_invert_begin() local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: noduplicate
declare void @__cq_invert_end() local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @rinp_old(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !8
  %8 = add i32 %7, %2
  %9 = xor i32 %8, %7
  %10 = icmp eq i32 %9, %3
  br i1 %10, label %11, label %12

11:                                               ; preds = %6
  tail call void @cq_phi(double noundef %4) #5
  br label %12

12:                                               ; preds = %6, %11
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !9
  tail call void @__cq_invert_end() #4
  %13 = add i32 %7, 1
  %14 = icmp eq i32 %13, %3
  br i1 %14, label %15, label %16

15:                                               ; preds = %12
  tail call void @cq_phi(double noundef %5) #5
  br label %16

16:                                               ; preds = %15, %12
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %8) #5
  ret i32 %17
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 256) i32 @rinp_two(i8 noundef zeroext %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !10
  %7 = xor i8 %6, 5
  %8 = icmp ugt i8 %7, %2
  br i1 %8, label %9, label %10

9:                                                ; preds = %5
  tail call void @cq_phi(double noundef %3) #5
  br label %10

10:                                               ; preds = %9, %5
  %11 = add i8 %6, 1
  %12 = icmp ugt i8 %11, %2
  br i1 %12, label %13, label %14

13:                                               ; preds = %10
  tail call void @cq_phi(double noundef %4) #5
  br label %14

14:                                               ; preds = %10, %13
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !11
  tail call void @__cq_invert_end() #4
  %15 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %11) #5
  %16 = zext i8 %15 to i32
  ret i32 %16
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @rinp_tmpl(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %7 = mul i32 %6, 3
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !12
  %8 = add i32 %7, %2
  %9 = icmp eq i32 %8, %3
  br i1 %9, label %10, label %11

10:                                               ; preds = %5
  tail call void @cq_phi(double noundef %4) #5
  br label %11

11:                                               ; preds = %5, %10
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !13
  tail call void @__cq_invert_end() #4
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %8) #5
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %6) #5
  %14 = add i32 %13, %12
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @rinp_meas(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %2, double noundef %3) #3
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !14
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %8) #5
  %10 = add i32 %9, %7
  %11 = icmp eq i32 %10, %4
  br i1 %11, label %12, label %13

12:                                               ; preds = %6
  tail call void @cq_phi(double noundef %5) #5
  br label %13

13:                                               ; preds = %6, %12
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !15
  tail call void @__cq_invert_end() #4
  %14 = tail call i32 @cq_measure_ui32(i32 noundef %10) #5
  %15 = add i32 %14, %9
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 511) i32 @rinp_arm(i8 noundef zeroext %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, i8 noundef zeroext %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3
  %8 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %2, double noundef %3) #3
  %9 = icmp ugt i8 %8, 7
  br i1 %9, label %10, label %11

10:                                               ; preds = %6
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !16
  br label %11

11:                                               ; preds = %10, %6
  %12 = add i8 %7, 3
  %13 = icmp eq i8 %12, %4
  br i1 %13, label %14, label %15

14:                                               ; preds = %11
  tail call void @cq_phi(double noundef %5) #5
  br label %15

15:                                               ; preds = %11, %14
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !17
  tail call void @__cq_invert_end() #4
  %16 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %12) #5
  %17 = zext i8 %16 to i32
  %18 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %8) #5
  %19 = zext i8 %18 to i32
  %20 = add nuw nsw i32 %19, %17
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 511) i32 @rinp_qarm(i8 noundef zeroext %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, i8 noundef zeroext %4, i8 noundef zeroext %5, double noundef %6, double noundef %7) local_unnamed_addr #0 {
  %9 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3
  %10 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %2, double noundef %3) #3
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !18
  %11 = icmp ugt i8 %10, 7
  br i1 %11, label %12, label %14

12:                                               ; preds = %8
  %13 = add i8 %9, %4
  tail call void @cq_phi(double noundef %7) #5
  br label %14

14:                                               ; preds = %12, %8
  %15 = phi i8 [ %13, %12 ], [ %9, %8 ]
  %16 = icmp eq i8 %15, %5
  br i1 %16, label %17, label %18

17:                                               ; preds = %14
  tail call void @cq_phi(double noundef %6) #5
  br label %18

18:                                               ; preds = %14, %17
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !19
  tail call void @__cq_invert_end() #4
  %19 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %15) #5
  %20 = zext i8 %19 to i32
  %21 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %10) #5
  %22 = zext i8 %21 to i32
  %23 = add nuw nsw i32 %22, %20
  ret i32 %23
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 256) i32 @rinp_nest(i8 noundef zeroext %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !20
  %7 = add i8 %6, 5
  %8 = icmp ugt i8 %7, %2
  br i1 %8, label %9, label %10

9:                                                ; preds = %5
  tail call void @cq_phi(double noundef %3) #5
  br label %10

10:                                               ; preds = %5, %9
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !21
  %11 = xor i8 %7, 9
  %12 = icmp ugt i8 %11, %2
  br i1 %12, label %13, label %14

13:                                               ; preds = %10
  tail call void @cq_phi(double noundef %4) #5
  br label %14

14:                                               ; preds = %10, %13
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !22
  tail call void @__cq_invert_end() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !23
  tail call void @__cq_invert_end() #4
  %15 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %11) #5
  %16 = zext i8 %15 to i32
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 256) i32 @rinp_unc(i8 noundef zeroext %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !24
  %7 = xor i8 %6, 5
  %8 = add i8 %6, 1
  %9 = icmp ugt i8 %8, %2
  br i1 %9, label %10, label %11

10:                                               ; preds = %5
  tail call void @cq_phi(double noundef %4) #5
  br label %11

11:                                               ; preds = %10, %5
  %12 = icmp ugt i8 %7, %2
  br i1 %12, label %13, label %14

13:                                               ; preds = %11
  tail call void @cq_phi(double noundef %3) #5
  br label %14

14:                                               ; preds = %11, %13
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !25
  tail call void @__cq_invert_end() #4
  %15 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %8) #5
  %16 = zext i8 %15 to i32
  ret i32 %16
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noduplicate "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { noduplicate nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{i64 2147515299}
!7 = !{i64 2147515355}
!8 = !{i64 2147517982}
!9 = !{i64 2147518038}
!10 = !{i64 2147519907}
!11 = !{i64 2147519963}
!12 = !{i64 2147521832}
!13 = !{i64 2147521888}
!14 = !{i64 2147525530}
!15 = !{i64 2147526344}
!16 = !{i64 2147529228}
!17 = !{i64 2147529284}
!18 = !{i64 2147532926}
!19 = !{i64 2147532982}
!20 = !{i64 2147535609}
!21 = !{i64 2147535686}
!22 = !{i64 2147535742}
!23 = !{i64 2147535817}
!24 = !{i64 2147537686}
!25 = !{i64 2147537742}
