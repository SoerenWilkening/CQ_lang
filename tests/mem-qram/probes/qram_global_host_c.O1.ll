; C probe for cqcheck user (cq-z7hz): global QRAMs with a non-zero initializer, one of structs (rule 20, qram_alloc_host).
; Source: qram_global_host_c.c; clang-19 -O1 -target x86_64-apple-macosx -I CQ_spec.
; ModuleID = 'gq.c'
source_filename = "gq.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.rec = type { i32, i16 }

@tab = internal unnamed_addr global [4 x i32] [i32 3, i32 5, i32 9, i32 7], align 16
@recs = internal unnamed_addr global [3 x %struct.rec] [%struct.rec { i32 1, i16 2 }, %struct.rec { i32 3, i16 4 }, %struct.rec { i32 5, i16 6 }], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @gq(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %5 = freeze i32 %4
  %6 = and i32 %5, 3
  %7 = urem i32 %5, 3
  %8 = zext nneg i32 %6 to i64
  %9 = getelementptr inbounds [4 x i32], ptr @tab, i64 0, i64 %8
  store i32 %2, ptr %9, align 4, !tbaa !6
  %10 = zext nneg i32 %7 to i64
  %11 = getelementptr inbounds [3 x %struct.rec], ptr @recs, i64 0, i64 %10
  store i32 %2, ptr %11, align 8, !tbaa !10
  %12 = add i32 %5, 1
  %13 = and i32 %12, 3
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds [4 x i32], ptr @tab, i64 0, i64 %14
  %16 = load i32, ptr %15, align 4, !tbaa !6
  %17 = getelementptr inbounds i8, ptr %11, i64 4
  %18 = load i16, ptr %17, align 4, !tbaa !13
  %19 = sext i16 %18 to i32
  %20 = add nsw i32 %16, %19
  %21 = add nuw nsw i32 %7, 1
  %22 = icmp eq i32 %21, 3
  %23 = select i1 %22, i32 0, i32 %21
  %24 = zext nneg i32 %23 to i64
  %25 = getelementptr inbounds [3 x %struct.rec], ptr @recs, i64 0, i64 %24
  %26 = load i32, ptr %25, align 8, !tbaa !10
  %27 = add nsw i32 %20, %26
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #3
  ret i32 %28
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!10 = !{!11, !7, i64 0}
!11 = !{!"rec", !7, i64 0, !12, i64 4}
!12 = !{!"short", !8, i64 0}
!13 = !{!11, !12, i64 4}
