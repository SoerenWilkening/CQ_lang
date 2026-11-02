; ModuleID = 'share_ru_other.c'
source_filename = "share_ru_other.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 4) i32 @share_ru_other(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 1
  %4 = alloca [2 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #3
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %4) #3
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e+00) #4
  %6 = zext i1 %5 to i8
  %7 = and i32 %0, 3
  store i8 %6, ptr %3, align 1, !tbaa !6
  %8 = getelementptr inbounds i8, ptr %3, i64 1
  store i8 0, ptr %8, align 1, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %3, i64 2
  store i8 1, ptr %9, align 1, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %3, i64 3
  store i8 0, ptr %10, align 1, !tbaa !6
  store i8 %6, ptr %4, align 1, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %4, i64 1
  store i8 %6, ptr %11, align 1, !tbaa !6
  %12 = icmp eq i32 %7, 0
  br i1 %12, label %15, label %13

13:                                               ; preds = %2
  %14 = zext nneg i32 %7 to i64
  br label %28

15:                                               ; preds = %28, %2
  %16 = and i32 %1, 1
  %17 = load i8, ptr %3, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = trunc nuw i8 %17 to i1
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %18) #3
  %20 = zext i1 %19 to i32
  %21 = zext nneg i32 %16 to i64
  %22 = getelementptr inbounds [2 x i8], ptr %4, i64 0, i64 %21
  %23 = load i8, ptr %22, align 1, !tbaa !6, !range !10, !noundef !11
  %24 = trunc nuw i8 %23 to i1
  %25 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %24) #3
  %26 = select i1 %25, i32 2, i32 0
  %27 = or disjoint i32 %26, %20
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %4) #3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #3
  ret i32 %27

28:                                               ; preds = %13, %28
  %29 = phi i64 [ 0, %13 ], [ %30, %28 ]
  %30 = add nuw nsw i64 %29, 1
  %31 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %30
  %32 = load i8, ptr %31, align 1, !tbaa !6, !range !10, !noundef !11
  %33 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %29
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !10, !noundef !11
  %35 = icmp ne i8 %34, %32
  %36 = zext i1 %35 to i8
  store i8 %36, ptr %33, align 1, !tbaa !6
  %37 = icmp eq i64 %30, %14
  br i1 %37, label %15, label %28, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

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
; x stays shared by q[0], p[0] and p[1] (nothing rotates a holder). The register update's old rail may be x,
; which p still holds and reads after it: rule 6 does not clean it (not dead), so nothing is freed.
; CHECK-COUNT share_ru_other: call void @cqrt_copy_i1( 0
; CHECK-COUNT share_ru_other: call void @cqrt_free( 0
; CHECK-COUNT share_ru_other: call i32 @cq_template_xor_i1( 1
; USERCHECK share_ru_other
