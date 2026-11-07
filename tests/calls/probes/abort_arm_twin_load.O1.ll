; ModuleID = 'm5.c'
source_filename = "m5.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global [4 x i32] zeroinitializer, align 16

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 3
  %3 = zext nneg i32 %2 to i64
  %4 = getelementptr inbounds [4 x i32], ptr @g, i64 0, i64 %3
  %5 = load i32, ptr %4, align 4, !tbaa !6
  %6 = icmp eq i32 %5, 3
  br i1 %6, label %7, label %8

7:                                                ; preds = %1
  tail call void @abort() #4
  unreachable

8:                                                ; preds = %1
  %9 = add nsw i32 %5, %0
  ret i32 %9
}

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @e() local_unnamed_addr #2 {
  %1 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 5.000000e-01) #5
  %2 = sext i8 %1 to i32
  %3 = tail call i32 @f(i32 noundef %2)
  %4 = mul nsw i32 %3, %3
  store i32 %4, ptr getelementptr inbounds (i8, ptr @g, i64 4), align 4, !tbaa !6
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #6
  %6 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 8), align 8, !tbaa !6
  %7 = add nsw i32 %6, %5
  ret i32 %7
}

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { cold noreturn nounwind }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

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
