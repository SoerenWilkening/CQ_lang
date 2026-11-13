; ModuleID = 'err_raise.c'
source_filename = "err_raise.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @rs_const(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %4 = tail call ptr @__error() #3
  store i32 0, ptr %4, align 4, !tbaa !6
  %5 = and i32 %3, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %2
  %8 = tail call i32 @raise(i32 noundef 70) #3
  br label %9

9:                                                ; preds = %7, %2
  %10 = phi i32 [ %8, %7 ], [ 5, %2 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %13 = add nsw i32 %12, %11
  %14 = tail call ptr @__error() #3
  %15 = load i32, ptr %14, align 4, !tbaa !6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  %17 = add nsw i32 %13, %16
  ret i32 %17
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare ptr @__error() local_unnamed_addr #1

declare i32 @raise(i32 noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @rs_cls(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  %5 = tail call ptr @__error() #3
  store i32 0, ptr %5, align 4, !tbaa !6
  %6 = and i32 %4, 1
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %11, label %8

8:                                                ; preds = %3
  %9 = xor i32 %1, 70
  %10 = tail call i32 @raise(i32 noundef %9) #3
  br label %11

11:                                               ; preds = %8, %3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %13 = tail call ptr @__error() #3
  %14 = load i32, ptr %13, align 4, !tbaa !6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  %16 = add nsw i32 %15, %12
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @rs_rail(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %4 = tail call ptr @__error() #3
  store i32 0, ptr %4, align 4, !tbaa !6
  %5 = tail call i32 @raise(i32 noundef %3) #3
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #3
  %7 = tail call ptr @__error() #3
  %8 = load i32, ptr %7, align 4, !tbaa !6
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %10 = add nsw i32 %9, %6
  ret i32 %10
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
