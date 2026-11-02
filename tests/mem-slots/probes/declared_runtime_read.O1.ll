; ModuleID = '../cq-e5lj/tests/mem-slots/probes/declared_runtime_read.c'
source_filename = "../cq-e5lj/tests/mem-slots/probes/declared_runtime_read.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @decl_rt(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #3
  %5 = zext i32 %1 to i64
  br label %8

6:                                                ; preds = %8
  %7 = icmp eq i32 %0, 3
  br i1 %7, label %17, label %18

8:                                                ; preds = %3, %8
  %9 = phi i64 [ 0, %3 ], [ %15, %8 ]
  %10 = add nuw i64 %9, %5
  %11 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %9
  %12 = trunc i64 %10 to i32
  store i32 %12, ptr %11, align 4, !tbaa !6
  %13 = trunc i64 %10 to i32
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef %2) #4
  store i32 %14, ptr %11, align 4, !tbaa !6
  %15 = add nuw nsw i64 %9, 1
  %16 = icmp eq i64 %15, 4
  br i1 %16, label %6, label %8, !llvm.loop !10

17:                                               ; preds = %6
  call void @ext_mod(ptr noundef nonnull %4) #3
  br label %18

18:                                               ; preds = %17, %6
  %19 = and i32 %0, 3
  %20 = zext nneg i32 %19 to i64
  %21 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %20
  %22 = load i32, ptr %21, align 4, !tbaa !6
  %23 = call i32 @cq_measure_si32(i32 noundef %22) #3
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #3
  ret i32 %23
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare void @ext_mod(ptr noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @decl_rt1(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #3
  %5 = zext i32 %1 to i64
  br label %12

6:                                                ; preds = %12
  call void @ext_mod(ptr noundef nonnull %4) #3
  %7 = and i32 %0, 3
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %8
  %10 = load i32, ptr %9, align 4, !tbaa !6
  %11 = call i32 @cq_measure_si32(i32 noundef %10) #3
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #3
  ret i32 %11

12:                                               ; preds = %3, %12
  %13 = phi i64 [ 0, %3 ], [ %19, %12 ]
  %14 = add nuw i64 %13, %5
  %15 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %13
  %16 = trunc i64 %14 to i32
  store i32 %16, ptr %15, align 4, !tbaa !6
  %17 = trunc i64 %14 to i32
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef %2) #4
  store i32 %18, ptr %15, align 4, !tbaa !6
  %19 = add nuw nsw i64 %13, 1
  %20 = icmp eq i64 %19, 4
  br i1 %20, label %6, label %12, !llvm.loop !13
}

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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
; CHECK-COUNT decl_rt: call void @__cq_q_ext_mod_001_unc( 1
; CHECK-COUNT decl_rt1: call void @__cq_q_ext_mod_001_unc( 1
