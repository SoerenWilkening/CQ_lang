; ModuleID = 'row13x.k3m.s1.ll'
source_filename = "row13x.k3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 2
  %4 = tail call fastcc i32 @slice(i32 noundef %3)
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = icmp slt i32 %0, 1
  br i1 %2, label %68, label %3

3:                                                ; preds = %1
  %4 = zext nneg i32 %0 to i64
  %5 = tail call ptr @llvm.stacksave.p0()
  %6 = alloca i32, i64 %4, align 16
  %7 = zext nneg i32 %0 to i64
  %8 = add nsw i64 %7, -1
  %xtraiter = and i64 %7, 3
  %9 = icmp ult i64 %8, 3
  br i1 %9, label %.unr-lcssa, label %.new

.new:                                             ; preds = %3
  %unroll_iter = sub i64 %7, %xtraiter
  br label %22

.unr-lcssa.loopexit:                              ; preds = %22
  %.unr.ph = phi i64 [ %39, %22 ]
  br label %.unr-lcssa

.unr-lcssa:                                       ; preds = %.unr-lcssa.loopexit, %3
  %.unr = phi i64 [ 0, %3 ], [ %.unr.ph, %.unr-lcssa.loopexit ]
  %lcmp.mod = icmp ne i64 %xtraiter, 0
  br i1 %lcmp.mod, label %.epil.preheader, label %17

.epil.preheader:                                  ; preds = %.unr-lcssa
  br label %10

10:                                               ; preds = %10, %.epil.preheader
  %11 = phi i64 [ %.unr, %.epil.preheader ], [ %15, %10 ]
  %epil.iter = phi i64 [ 0, %.epil.preheader ], [ %epil.iter.next, %10 ]
  %12 = getelementptr inbounds i32, ptr %6, i64 %11
  %13 = trunc i64 %11 to i32
  %14 = add i32 %13, 3
  store i32 %14, ptr %12, align 4, !tbaa !6
  %15 = add nuw nsw i64 %11, 1
  %16 = icmp eq i64 %15, %7
  %epil.iter.next = add i64 %epil.iter, 1
  %epil.iter.cmp = icmp ne i64 %epil.iter.next, %xtraiter
  br i1 %epil.iter.cmp, label %10, label %.epilog-lcssa, !llvm.loop !10

.epilog-lcssa:                                    ; preds = %10
  br label %17

17:                                               ; preds = %.unr-lcssa, %.epilog-lcssa
  %18 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #4
  %19 = icmp ne i32 %18, 0
  %20 = icmp eq i32 %0, 3
  %21 = and i1 %20, %19
  br label %40

22:                                               ; preds = %22, %.new
  %23 = phi i64 [ 0, %.new ], [ %39, %22 ]
  %niter = phi i64 [ 0, %.new ], [ %niter.next.3, %22 ]
  %24 = getelementptr inbounds i32, ptr %6, i64 %23
  %25 = trunc i64 %23 to i32
  %26 = add nuw nsw i32 %25, 3
  store i32 %26, ptr %24, align 4, !tbaa !6
  %27 = add nuw nsw i64 %23, 1
  %28 = getelementptr inbounds i32, ptr %6, i64 %27
  %29 = trunc i64 %27 to i32
  %30 = add i32 %29, 3
  store i32 %30, ptr %28, align 4, !tbaa !6
  %31 = add nuw nsw i64 %23, 2
  %32 = getelementptr inbounds i32, ptr %6, i64 %31
  %33 = trunc i64 %31 to i32
  %34 = add i32 %33, 3
  store i32 %34, ptr %32, align 4, !tbaa !6
  %35 = add nuw nsw i64 %23, 3
  %36 = getelementptr inbounds i32, ptr %6, i64 %35
  %37 = trunc i64 %35 to i32
  %38 = add i32 %37, 3
  store i32 %38, ptr %36, align 4, !tbaa !6
  %39 = add nuw nsw i64 %23, 4
  %niter.next.3 = add i64 %niter, 4
  %niter.ncmp.3 = icmp eq i64 %niter.next.3, %unroll_iter
  br i1 %niter.ncmp.3, label %.unr-lcssa.loopexit, label %22, !llvm.loop !12

40:                                               ; preds = %17
  br i1 %21, label %41, label %44

41:                                               ; preds = %40
  %42 = load i32, ptr %6, align 4, !tbaa !6
  %43 = sub nsw i32 0, %42
  br label %44

44:                                               ; preds = %41, %40
  %45 = phi i32 [ %42, %41 ], [ 0, %40 ]
  %46 = phi i32 [ %43, %41 ], [ 0, %40 ]
  br i1 %21, label %47, label %52

47:                                               ; preds = %44
  %48 = getelementptr inbounds i32, ptr %6, i64 1
  %49 = load i32, ptr %48, align 4, !tbaa !6
  %50 = add nsw i32 %49, %45
  %51 = sub nsw i32 %46, %49
  br label %52

52:                                               ; preds = %47, %44
  %53 = phi i32 [ %50, %47 ], [ %45, %44 ]
  %54 = phi i32 [ %51, %47 ], [ %46, %44 ]
  br i1 %21, label %55, label %60

55:                                               ; preds = %52
  %56 = getelementptr inbounds i32, ptr %6, i64 2
  %57 = load i32, ptr %56, align 4, !tbaa !6
  %58 = add nsw i32 %57, %53
  %59 = sub nsw i32 %54, %57
  br label %60

60:                                               ; preds = %55, %52
  %61 = phi i32 [ %58, %55 ], [ %53, %52 ]
  %62 = phi i32 [ %59, %55 ], [ %54, %52 ]
  %63 = tail call i32 @cq_measure_si32(i32 noundef %18) #4
  %64 = tail call i32 @cq_measure_si32(i32 noundef %61) #4
  %65 = add nsw i32 %64, %63
  %66 = tail call i32 @cq_measure_si32(i32 noundef %62) #4
  %67 = add nsw i32 %65, %66
  tail call void @llvm.stackrestore.p0(ptr %5)
  br label %68

68:                                               ; preds = %60, %1
  %69 = phi i32 [ %67, %60 ], [ 0, %1 ]
  ret i32 %69
}

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !13, !11}
!13 = !{!"llvm.loop.mustprogress"}
