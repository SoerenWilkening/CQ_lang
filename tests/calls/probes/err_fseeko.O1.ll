; ModuleID = 'err_fseeko.c'
source_filename = "err_fseeko.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdoutp = external local_unnamed_addr global ptr, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @fo_const(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %4 = tail call ptr @__error() #4
  store i32 0, ptr %4, align 4, !tbaa !6
  %5 = and i32 %3, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %2
  %8 = load ptr, ptr @__stdoutp, align 8, !tbaa !10
  %9 = tail call i32 @fseeko(ptr noundef %8, i64 noundef 0, i32 noundef 7)
  br label %10

10:                                               ; preds = %7, %2
  %11 = phi i32 [ %9, %7 ], [ 5, %2 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  %14 = add nsw i32 %13, %12
  %15 = tail call ptr @__error() #4
  %16 = load i32, ptr %15, align 4, !tbaa !6
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #4
  %18 = add nsw i32 %14, %17
  ret i32 %18
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare ptr @__error() local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare noundef i32 @fseeko(ptr nocapture noundef, i64 noundef, i32 noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @fo_cls(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  %5 = tail call ptr @__error() #4
  store i32 0, ptr %5, align 4, !tbaa !6
  %6 = load ptr, ptr @__stdoutp, align 8, !tbaa !10
  %7 = sext i32 %4 to i64
  %8 = xor i32 %1, 3
  %9 = tail call i32 @fseeko(ptr noundef %6, i64 noundef %7, i32 noundef %8)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %11 = tail call ptr @__error() #4
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  %14 = add nsw i32 %13, %10
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @fo_rail(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %4 = tail call ptr @__error() #4
  store i32 0, ptr %4, align 4, !tbaa !6
  %5 = load ptr, ptr @__stdoutp, align 8, !tbaa !10
  %6 = tail call i32 @fseeko(ptr noundef %5, i64 noundef 0, i32 noundef %3)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %8 = tail call ptr @__error() #4
  %9 = load i32, ptr %8, align 4, !tbaa !6
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %11 = add nsw i32 %10, %7
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @fo_unread(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %4 = tail call ptr @__error() #4
  store i32 0, ptr %4, align 4, !tbaa !6
  %5 = load ptr, ptr @__stdoutp, align 8, !tbaa !10
  %6 = tail call i32 @fseeko(ptr noundef %5, i64 noundef 0, i32 noundef %3)
  %7 = tail call ptr @__error() #4
  %8 = load i32, ptr %7, align 4, !tbaa !6
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  ret i32 %9
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

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
!10 = !{!11, !11, i64 0}
!11 = !{!"any pointer", !8, i64 0}
