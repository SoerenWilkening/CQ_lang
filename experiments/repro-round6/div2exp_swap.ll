; ModuleID = 'div2exp.O1.ll'
source_filename = "div2exp.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@limbs = local_unnamed_addr global [4 x i64] [i64 0, i64 0, i64 5, i64 8], align 16

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @f(i32 noundef %arg, i32 noundef %arg1, double noundef %arg2) local_unnamed_addr #0 {
bb:
  %i = tail call i32 @cq_theta_si32(i32 noundef %arg, double noundef %arg2) #3
  %i3 = tail call i32 @cq_theta_ui32(i32 noundef %arg1, double noundef %arg2) #3
  %i4 = lshr i32 %i3, 2
  %i5 = tail call i32 @llvm.abs.i32(i32 %i, i1 true)
  %i6 = icmp ult i32 %i4, %i5
  br i1 %i6, label %bb7, label %bb9

bb9:                                              ; preds = %bb
  %i10 = icmp eq i32 %i, 0
  br label %bb32

bb7:                                              ; preds = %bb
  %i8 = icmp ult i32 %i3, 4
  br i1 %i8, label %bb21, label %bb14

bb11:                                             ; preds = %bb14
  %i12 = add nuw nsw i32 %i15, 1
  %i13 = icmp eq i32 %i12, %i4
  br i1 %i13, label %bb21, label %bb14, !llvm.loop !6

bb14:                                             ; preds = %bb11, %bb7
  %i15 = phi i32 [ %i12, %bb11 ], [ 0, %bb7 ]
  %i16 = and i32 %i15, 3
  %i17 = zext nneg i32 %i16 to i64
  %i18 = getelementptr inbounds [4 x i64], ptr @limbs, i64 0, i64 %i17
  %i19 = load i64, ptr %i18, align 8, !tbaa !9
  %i20 = icmp eq i64 %i19, 0
  br i1 %i20, label %bb11, label %bb32

bb21:                                             ; preds = %bb11, %bb7
  %i22 = and i32 %i4, 3
  %i23 = zext nneg i32 %i22 to i64
  %i24 = getelementptr inbounds [4 x i64], ptr @limbs, i64 0, i64 %i23
  %i25 = load i64, ptr %i24, align 8, !tbaa !9
  %i26 = and i32 %i3, 3
  %i27 = zext nneg i32 %i26 to i64
  %i28 = shl nsw i64 -1, %i27
  %i29 = xor i64 %i28, -1
  %i30 = and i64 %i25, %i29
  %i31 = icmp eq i64 %i30, 0
  br label %bb32

bb32:                                             ; preds = %bb21, %bb14, %bb9
  %i33 = phi i1 [ %i10, %bb9 ], [ %i31, %bb21 ], [ false, %bb14 ]
  %i34 = zext i1 %i33 to i32
  ret i32 %i34
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = !{!10, !10, i64 0}
!10 = !{!"long", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
