; Rule 22 (cq-k65d): a run-time-length memset into a global QRAM under a quantum predicate (its stores never
; popped, rule 20): the loop's guards are and_i1 with the predicate. cqcheck user (27 samples): PASS.
; CHECK lp_glob: call i32 @cq_template_and_i1(
; CHECK lp_glob: call void @cqrt_qram_store_i32_hl_controlled(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global [8 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define i32 @lp_glob(i32 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %4, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr @g, i64 0, i64 %6
  store i32 9, ptr %7, align 4, !tbaa !6
  %8 = icmp ugt i32 %5, 3
  br i1 %8, label %9, label %12

9:                                                ; preds = %3
  %10 = shl i64 %2, 2
  %11 = and i64 %10, 28
  tail call void @llvm.memset.p0.i64(ptr nonnull align 4 getelementptr inbounds (i8, ptr @g, i64 4), i8 -1, i64 %11, i1 false)
  br label %12

12:                                               ; preds = %9, %3
  %13 = load i32, ptr %7, align 4, !tbaa !6
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  %15 = load i32, ptr getelementptr inbounds (i8, ptr @g, i64 8), align 8, !tbaa !6
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #4
  %17 = add nsw i32 %16, %14
  ret i32 %17
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
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
