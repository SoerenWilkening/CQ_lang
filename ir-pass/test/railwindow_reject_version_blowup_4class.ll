; railwindow_reject_version_blowup_4class.ll — DECLINE (bd `test_C_libtooling-01po.19` S7,
; ruling `ruling-01po19-s7-version-bound-2026-10-15`).
;
; Four runtime indices a, b, c, d in one window, every pair unproven: the
; consistent alias partitions alone are Bell(4) = 15 > 8 (this mechanism would
; make 12 copies). Loud at the eighth versioning, nothing lowered.
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int f(int a, int b, int c, int d) {
;     bool q[4] = {0};
;     a &= 3; b &= 3; c &= 3; d &= 3;
;     cq_theta(&q[a], .1); cq_theta(&q[b], .2); cq_theta(&q[c], .3);
;     cq_theta(&q[d], .4); cq_theta(&q[a], .5);
;     int r = 0;
;     for (int k = 0; k < 4; k++) r = 2 * r + cq_measure(q[k]);
;     return r;
;   }
;   int main(int argc, char **argv) { (void)argv; return f(argc, argc + 1, argc + 2, argc + 3); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='quantum array not lowered yet'
; CHECK: error: {{.*}}in function f i32 (i32, i32, i32, i32): cq rail window: index alias versioning would copy one window more than 8 times

source_filename = "bound4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #4
  store i32 0, ptr %5, align 4
  %6 = and i32 %0, 3
  %7 = and i32 %1, 3
  %8 = and i32 %2, 3
  %9 = and i32 %3, 3
  %10 = zext nneg i32 %6 to i64
  %11 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %10
  %12 = load i8, ptr %11, align 1, !tbaa !6, !range !10, !noundef !11
  %13 = trunc nuw i8 %12 to i1
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef 1.000000e-01) #5
  %15 = zext i1 %14 to i8
  store i8 %15, ptr %11, align 1, !tbaa !6
  %16 = zext nneg i32 %7 to i64
  %17 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %16
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = trunc nuw i8 %18 to i1
  %20 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %19, double noundef 2.000000e-01) #5
  %21 = zext i1 %20 to i8
  store i8 %21, ptr %17, align 1, !tbaa !6
  %22 = zext nneg i32 %8 to i64
  %23 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %22
  %24 = load i8, ptr %23, align 1, !tbaa !6, !range !10, !noundef !11
  %25 = trunc nuw i8 %24 to i1
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %25, double noundef 3.000000e-01) #5
  %27 = zext i1 %26 to i8
  store i8 %27, ptr %23, align 1, !tbaa !6
  %28 = zext nneg i32 %9 to i64
  %29 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %28
  %30 = load i8, ptr %29, align 1, !tbaa !6, !range !10, !noundef !11
  %31 = trunc nuw i8 %30 to i1
  %32 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %31, double noundef 4.000000e-01) #5
  %33 = zext i1 %32 to i8
  store i8 %33, ptr %29, align 1, !tbaa !6
  %34 = load i8, ptr %11, align 1, !tbaa !6, !range !10, !noundef !11
  %35 = trunc nuw i8 %34 to i1
  %36 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %35, double noundef 5.000000e-01) #5
  %37 = zext i1 %36 to i8
  store i8 %37, ptr %11, align 1, !tbaa !6
  br label %39

38:                                               ; preds = %39
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #4
  ret i32 %48

39:                                               ; preds = %4, %39
  %40 = phi i64 [ 0, %4 ], [ %49, %39 ]
  %41 = phi i32 [ 0, %4 ], [ %48, %39 ]
  %42 = shl nsw i32 %41, 1
  %43 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %40
  %44 = load i8, ptr %43, align 1, !tbaa !6, !range !10, !noundef !11
  %45 = trunc nuw i8 %44 to i1
  %46 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %45) #4
  %47 = zext i1 %46 to i32
  %48 = or disjoint i32 %42, %47
  %49 = add nuw nsw i64 %40, 1
  %50 = icmp eq i64 %49, 4
  br i1 %50, label %38, label %39, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %0, 1
  %4 = add nsw i32 %0, 2
  %5 = add nsw i32 %0, 3
  %6 = tail call i32 @f(i32 noundef %0, i32 noundef %3, i32 noundef %4, i32 noundef %5)
  ret i32 %6
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

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
