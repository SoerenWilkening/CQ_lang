; ModuleID = 'seed_overwrite.c'
source_filename = "seed_overwrite.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 -128, 128) i32 @seed_overwrite(ptr nocapture noundef readonly %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #3
  store i32 0, ptr %4, align 4
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %3
  %7 = zext nneg i32 %1 to i64
  br label %15

8:                                                ; preds = %15, %3
  %9 = and i32 %2, 3
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %10
  %12 = load i8, ptr %11, align 1, !tbaa !6
  %13 = tail call signext i8 @cq_measure_c(i8 noundef signext %12) #3
  %14 = sext i8 %13 to i32
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #3
  ret i32 %14

15:                                               ; preds = %6, %15
  %16 = phi i64 [ 0, %6 ], [ %21, %15 ]
  %17 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %16
  store i8 97, ptr %17, align 1, !tbaa !6
  %18 = getelementptr inbounds double, ptr %0, i64 %16
  %19 = load double, ptr %18, align 8, !tbaa !9
  %20 = tail call signext i8 @cq_theta_c(i8 noundef signext 97, double noundef %19) #4
  store i8 %20, ptr %17, align 1, !tbaa !6
  %21 = add nuw nsw i64 %16, 1
  %22 = icmp eq i64 %21, %7
  br i1 %22, label %8, label %15, !llvm.loop !11
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_measure_c(i8 noundef signext) local_unnamed_addr #2

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
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !10, i64 0}
!10 = !{!"double", !7, i64 0}
!11 = distinct !{!11, !12, !13}
!12 = !{!"llvm.loop.mustprogress"}
!13 = !{!"llvm.loop.unroll.disable"}
; CHECK-COUNT seed_overwrite: call void @cqrt_free( 1
; CHECK seed_overwrite: call void @cqrt_free(i32 %{{old}})
