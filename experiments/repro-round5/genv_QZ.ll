; ModuleID = 'experiments/gsl/build/repro/eigen/linked.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str.1.106 = external hidden unnamed_addr constant [25 x i8], align 1
@.str.10.115 = external hidden unnamed_addr constant [30 x i8], align 1
@.str.11 = external hidden unnamed_addr constant [30 x i8], align 1

declare void @gsl_error(ptr noundef, ptr noundef, i32 noundef, i32 noundef) local_unnamed_addr #0

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #1

; Function Attrs: nounwind ssp uwtable
declare i32 @gsl_eigen_genv(ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr noundef, ptr nocapture noundef readonly) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @gsl_eigen_genv_QZ(ptr noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %5, ptr noundef %6, ptr nocapture noundef %7) local_unnamed_addr #2 {
  %9 = icmp eq ptr %5, null
  br i1 %9, label %19, label %10

10:                                               ; preds = %8
  %11 = load i64, ptr %0, align 8, !tbaa !6
  %12 = load i64, ptr %5, align 8, !tbaa !6
  %13 = icmp eq i64 %11, %12
  br i1 %13, label %14, label %18

14:                                               ; preds = %10
  %15 = getelementptr inbounds i8, ptr %5, i64 8
  %16 = load i64, ptr %15, align 8, !tbaa !13
  %17 = icmp eq i64 %11, %16
  br i1 %17, label %19, label %18

18:                                               ; preds = %14, %10
  tail call void @gsl_error(ptr noundef nonnull @.str.10.115, ptr noundef nonnull @.str.1.106, i32 noundef 268, i32 noundef 19) #3
  br label %34

19:                                               ; preds = %14, %8
  %20 = icmp eq ptr %6, null
  br i1 %20, label %30, label %21

21:                                               ; preds = %19
  %22 = load i64, ptr %0, align 8, !tbaa !6
  %23 = load i64, ptr %6, align 8, !tbaa !6
  %24 = icmp eq i64 %22, %23
  br i1 %24, label %25, label %29

25:                                               ; preds = %21
  %26 = getelementptr inbounds i8, ptr %6, i64 8
  %27 = load i64, ptr %26, align 8, !tbaa !13
  %28 = icmp eq i64 %22, %27
  br i1 %28, label %30, label %29

29:                                               ; preds = %25, %21
  tail call void @gsl_error(ptr noundef nonnull @.str.11, ptr noundef nonnull @.str.1.106, i32 noundef 272, i32 noundef 19) #3
  br label %34

30:                                               ; preds = %25, %19
  %31 = getelementptr inbounds i8, ptr %7, i64 56
  store ptr %5, ptr %31, align 8, !tbaa !14
  %32 = getelementptr inbounds i8, ptr %7, i64 64
  store ptr %6, ptr %32, align 8, !tbaa !16
  %33 = tail call i32 @gsl_eigen_genv(ptr noundef %0, ptr noundef %1, ptr noundef %2, ptr noundef %3, ptr noundef %4, ptr noundef %7)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %31, i8 0, i64 16, i1 false)
  br label %34

34:                                               ; preds = %30, %29, %18
  %35 = phi i32 [ 19, %18 ], [ 19, %29 ], [ %33, %30 ]
  ret i32 %35
}

attributes #0 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !8, i64 0}
!7 = !{!"", !8, i64 0, !8, i64 8, !8, i64 16, !11, i64 24, !11, i64 32, !12, i64 40}
!8 = !{!"long", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!"any pointer", !9, i64 0}
!12 = !{!"int", !9, i64 0}
!13 = !{!7, !8, i64 8}
!14 = !{!15, !11, i64 56}
!15 = !{!"", !8, i64 0, !11, i64 8, !11, i64 16, !11, i64 24, !11, i64 32, !11, i64 40, !11, i64 48, !11, i64 56, !11, i64 64, !11, i64 72}
!16 = !{!15, !11, i64 64}
