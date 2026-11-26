; ModuleID = 'invert_inplace_register.c'
source_filename = "invert_inplace_register.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 513) i32 @invert_prepare(i8 noundef zeroext %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3
  %8 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %2, double noundef %3) #3
  %9 = icmp ugt i8 %7, 4
  br i1 %9, label %10, label %13

10:                                               ; preds = %6
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %4) #3
  %12 = zext i1 %11 to i8
  br label %13

13:                                               ; preds = %10, %6
  %14 = phi i8 [ %12, %10 ], [ 0, %6 ]
  %15 = trunc nuw i8 %14 to i1
  %16 = select i1 %15, i8 -5, i8 0
  %17 = add i8 %16, %7
  %18 = select i1 %15, i8 18, i8 0
  %19 = add i8 %18, %8
  %20 = icmp ugt i8 %17, 8
  br i1 %20, label %21, label %24

21:                                               ; preds = %13
  %22 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %4) #3
  %23 = zext i1 %22 to i8
  br label %24

24:                                               ; preds = %21, %13
  %25 = phi i8 [ %23, %21 ], [ 0, %13 ]
  %26 = trunc nuw i8 %25 to i1
  %27 = select i1 %26, i8 -9, i8 0
  %28 = add i8 %27, %17
  %29 = select i1 %26, i8 27, i8 0
  %30 = add i8 %19, %29
  %31 = icmp ugt i8 %30, 40
  br i1 %31, label %32, label %33

32:                                               ; preds = %24
  tail call void @cq_phi(double noundef %5) #4
  br label %33

33:                                               ; preds = %24, %32
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !6
  %34 = icmp ugt i8 %28, 4
  br i1 %34, label %35, label %38

35:                                               ; preds = %33
  %36 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef %4) #3
  %37 = zext i1 %36 to i8
  br label %38

38:                                               ; preds = %35, %33
  %39 = phi i8 [ %37, %35 ], [ %14, %33 ]
  %40 = trunc nuw i8 %39 to i1
  %41 = select i1 %40, i8 -5, i8 0
  %42 = add i8 %41, %28
  %43 = icmp ugt i8 %42, 8
  br i1 %43, label %44, label %47

44:                                               ; preds = %38
  %45 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %26, double noundef %4) #3
  %46 = zext i1 %45 to i8
  br label %47

47:                                               ; preds = %44, %38
  %48 = phi i8 [ %46, %44 ], [ %25, %38 ]
  %49 = select i1 %40, i8 18, i8 0
  %50 = add i8 %49, %30
  %51 = trunc nuw i8 %48 to i1
  %52 = select i1 %51, i8 -9, i8 0
  %53 = add i8 %52, %42
  %54 = select i1 %51, i8 27, i8 0
  %55 = add i8 %50, %54
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !7
  tail call void @__cq_invert_end() #5
  %56 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %53) #4
  %57 = zext i8 %56 to i32
  %58 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %55) #4
  %59 = zext i8 %58 to i32
  %60 = add nuw nsw i32 %59, %57
  %61 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %40) #4
  %62 = zext i1 %61 to i32
  %63 = add nuw nsw i32 %60, %62
  %64 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %51) #4
  %65 = zext i1 %64 to i32
  %66 = add nuw nsw i32 %63, %65
  ret i32 %66
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: noduplicate
declare void @__cq_invert_begin() local_unnamed_addr #2

; Function Attrs: noduplicate
declare void @__cq_invert_end() local_unnamed_addr #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @invert_old_value(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !8
  %8 = add i32 %7, %2
  %9 = mul i32 %8, %7
  %10 = icmp eq i32 %9, %3
  br i1 %10, label %11, label %12

11:                                               ; preds = %6
  tail call void @cq_phi(double noundef %4) #4
  br label %12

12:                                               ; preds = %6, %11
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !9
  tail call void @__cq_invert_end() #5
  %13 = icmp eq i32 %7, %3
  br i1 %13, label %14, label %15

14:                                               ; preds = %12
  tail call void @cq_phi(double noundef %5) #4
  br label %15

15:                                               ; preds = %14, %12
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %8) #4
  ret i32 %16
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @invert_cell(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %2, double noundef %3) #3
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !10
  %7 = load i32, ptr @g, align 4, !tbaa !11
  %8 = add i32 %7, %5
  store i32 %8, ptr @g, align 4, !tbaa !11
  %9 = xor i32 %6, %5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !15
  tail call void @__cq_invert_end() #5
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #4
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %5) #4
  %12 = add i32 %11, %10
  ret i32 %12
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
!6 = !{i64 2147516053}
!7 = !{i64 2147518441}
!8 = !{i64 2147522602}
!9 = !{i64 2147522658}
!10 = !{i64 2147525542}
!11 = !{!12, !12, i64 0}
!12 = !{!"int", !13, i64 0}
!13 = !{!"omnipotent char", !14, i64 0}
!14 = !{!"Simple C/C++ TBAA"}
!15 = !{i64 2147525598}
