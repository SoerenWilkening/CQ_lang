; ModuleID = 'register_update_live.c'
source_filename = "register_update_live.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 4) i32 @register_update_live(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = alloca i8, i64 %3, align 16
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %10

6:                                                ; preds = %2
  %7 = lshr i32 %0, 1
  %8 = zext nneg i32 %7 to i64
  %9 = zext nneg i32 %0 to i64
  br label %22

10:                                               ; preds = %22, %2
  %11 = getelementptr inbounds i8, ptr %4, i64 1
  %12 = load i8, ptr %11, align 1, !tbaa !6, !range !10, !noundef !11
  %13 = trunc nuw i8 %12 to i1
  %14 = load i8, ptr %4, align 16, !tbaa !6, !range !10, !noundef !11
  %15 = icmp ne i8 %12, %14
  %16 = zext i1 %15 to i8
  store i8 %16, ptr %11, align 1, !tbaa !6
  %17 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13) #2
  %18 = zext i1 %17 to i32
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15) #2
  %20 = select i1 %19, i32 2, i32 0
  %21 = or disjoint i32 %20, %18
  ret i32 %21

22:                                               ; preds = %6, %22
  %23 = phi i64 [ 0, %6 ], [ %29, %22 ]
  %24 = icmp uge i64 %23, %8
  %25 = getelementptr inbounds i8, ptr %4, i64 %23
  %26 = zext i1 %24 to i8
  store i8 %26, ptr %25, align 1, !tbaa !6
  %27 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %24, double noundef %1) #3
  %28 = zext i1 %27 to i8
  store i8 %28, ptr %25, align 1, !tbaa !6
  %29 = add nuw nsw i64 %23, 1
  %30 = icmp eq i64 %29, %9
  br i1 %30, label %10, label %22, !llvm.loop !12
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }
attributes #3 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
; EXPECT-ERROR: cq: unimplemented: mem-slots: a register update of a register array whose old rail may still be read after the store (rule 6 Dead)
