; railwindow_version_bound_two_proven_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19` S7).
;
; Four classes q[a], q[a+1], q[c], q[c+1]: SCEV proves the two disjoint pairs
; (a != a+1, c != c+1) and S7 versions only the four cross pairs. Measured: 6
; versionings = 7 copies <= 8, accepted (the coordinator's model count was 7).
; A proven pair is never versioned: the WIN-COUNT pins exactly 6.
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int f(int a, int c) {
;     bool q[8] = {0};
;     a &= 3; c &= 3;
;     cq_theta(&q[a], .1); cq_theta(&q[a + 1], .2); cq_theta(&q[c], .3);
;     cq_theta(&q[c + 1], .4); cq_theta(&q[a], .5);
;     int r = 0;
;     for (int k = 0; k < 8; k++) r = 2 * r + cq_measure(q[k]);
;     return r;
;   }
;   int main(int argc, char **argv) { (void)argv; return f(argc, argc + 2); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
;
; WIN: CQ_RAILWINDOW_DBG: @f claims
; WIN-COUNT-6: CQ_RAILWINDOW_DBG: version region
; WIN-NOT: CQ_RAILWINDOW_DBG: version region

source_filename = "bound4p2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [8 x i8], align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #4
  store i64 0, ptr %3, align 8
  %4 = and i32 %0, 3
  %5 = and i32 %1, 3
  %6 = zext nneg i32 %4 to i64
  %7 = getelementptr inbounds [8 x i8], ptr %3, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef 1.000000e-01) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %7, align 1, !tbaa !6
  %12 = add nuw nsw i32 %4, 1
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [8 x i8], ptr %3, i64 0, i64 %13
  %15 = load i8, ptr %14, align 1, !tbaa !6, !range !10, !noundef !11
  %16 = trunc nuw i8 %15 to i1
  %17 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %16, double noundef 2.000000e-01) #5
  %18 = zext i1 %17 to i8
  store i8 %18, ptr %14, align 1, !tbaa !6
  %19 = zext nneg i32 %5 to i64
  %20 = getelementptr inbounds [8 x i8], ptr %3, i64 0, i64 %19
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = trunc nuw i8 %21 to i1
  %23 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %22, double noundef 3.000000e-01) #5
  %24 = zext i1 %23 to i8
  store i8 %24, ptr %20, align 1, !tbaa !6
  %25 = add nuw nsw i32 %5, 1
  %26 = zext nneg i32 %25 to i64
  %27 = getelementptr inbounds [8 x i8], ptr %3, i64 0, i64 %26
  %28 = load i8, ptr %27, align 1, !tbaa !6, !range !10, !noundef !11
  %29 = trunc nuw i8 %28 to i1
  %30 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %29, double noundef 4.000000e-01) #5
  %31 = zext i1 %30 to i8
  store i8 %31, ptr %27, align 1, !tbaa !6
  %32 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %33 = trunc nuw i8 %32 to i1
  %34 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %33, double noundef 5.000000e-01) #5
  %35 = zext i1 %34 to i8
  store i8 %35, ptr %7, align 1, !tbaa !6
  br label %37

36:                                               ; preds = %37
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #4
  ret i32 %46

37:                                               ; preds = %2, %37
  %38 = phi i64 [ 0, %2 ], [ %47, %37 ]
  %39 = phi i32 [ 0, %2 ], [ %46, %37 ]
  %40 = shl nsw i32 %39, 1
  %41 = getelementptr inbounds [8 x i8], ptr %3, i64 0, i64 %38
  %42 = load i8, ptr %41, align 1, !tbaa !6, !range !10, !noundef !11
  %43 = trunc nuw i8 %42 to i1
  %44 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %43) #4
  %45 = zext i1 %44 to i32
  %46 = or disjoint i32 %40, %45
  %47 = add nuw nsw i64 %38, 1
  %48 = icmp eq i64 %47, 8
  br i1 %48, label %36, label %37, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %0, 2
  %4 = tail call i32 @f(i32 noundef %0, i32 noundef %3)
  ret i32 %4
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
