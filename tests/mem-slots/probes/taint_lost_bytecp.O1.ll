; ModuleID = 'taint_lost_bytecp.c'
source_filename = "taint_lost_bytecp.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@H = global ptr null, align 8
@G = local_unnamed_addr global ptr null, align 8
@xg = global i32 0, align 4

; Function Attrs: nofree noinline norecurse nounwind ssp memory(readwrite, argmem: none) uwtable
define void @cp() local_unnamed_addr #0 {
  br label %2

1:                                                ; preds = %2
  ret void

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = getelementptr inbounds i8, ptr @G, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6
  %6 = getelementptr inbounds i8, ptr @H, i64 %3
  store volatile i8 %5, ptr %6, align 1, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 8
  br i1 %8, label %1, label %2, !llvm.loop !9
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable
define i32 @get() local_unnamed_addr #1 {
  %1 = load ptr, ptr @H, align 8, !tbaa !12
  %2 = load i32, ptr %1, align 4, !tbaa !14
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @taint_lost_bytecp(i32 noundef %0, double noundef %1) local_unnamed_addr #2 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  store i32 %3, ptr @xg, align 4, !tbaa !14
  store ptr @xg, ptr @G, align 8, !tbaa !12
  tail call void @cp()
  %4 = tail call i32 @get()
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  ret i32 %5
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

attributes #0 = { nofree noinline norecurse nounwind ssp memory(readwrite, argmem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = !{!13, !13, i64 0}
!13 = !{!"any pointer", !7, i64 0}
!14 = !{!15, !15, i64 0}
!15 = !{!"int", !7, i64 0}
; EXPECT-ERROR: cq: unimplemented: mem-slots: a classical pointer into
