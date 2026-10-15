; railwindow_version_aliased_user_test.ll — ACCEPT (bd `test_C_libtooling-01po.19` S7,
; R11 round 1 A-F2; the reviewer's review_s7A/p3.c with an unguarded q[j]
; access first, so the window IS versioned).
;
; In the aliased copy (i == j) the user's own `if (i != j)` is a known-false
; classical compare. Left in place, its dead arm gates the cell rail AFTER
; `cq_measure(q[i])` measured it ("gate applied to handle after measurement",
; a false physics refusal). The aliased copy now folds every compare that tests
; exactly "the two cells are one" (`railWindowCompareIsCellEquality` against
; the dominating guard's aliased edge), folds the branch and drops the dead
; arm before any later stage runs.
;
; ANALYTIC TRACE (h = q[j]'s rail, Ry(.1)):
;   distinct (i != j): Ry(.7) q[i]; measure q[i]; Ry(.3), Ry(.5) on h;
;     q[i] := alloc(0).
;   aliased  (i == j): Ry(.7) h; measure h; q[i] := alloc(0); no gate after
;     the measurement.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --input-file=%t.ll
; CHECK-LABEL: define i32 @f(
; CHECK: [[H:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[H]], double 1.000000e-01)
; CHECK: br i1 %cq.win.ne, label %[[D:[^,]+]], label %[[AL:[^,]+]], !cq.railwindow.version
; CHECK: {{^}}[[D]]:
; CHECK: call void @cqrt_ry_i1(i32 [[H]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[H]], double 5.000000e-01)
; CHECK: {{^}}[[AL]]:
; CHECK: call void @cqrt_ry_i1(i32 [[H]], double 0x3FE6666666666666)
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 [[H]])
; CHECK-NOT: cqrt_ry_i1
; CHECK: call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NOT: cqrt_ry_i1
; CHECK: {{^}}}
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int f(int i, int j) {
;     bool q[4] = {0};
;     i &= 3; j &= 3;
;     cq_theta(&q[j], .1);
;     cq_theta(&q[i], .7);
;     int r = cq_measure(q[i]);
;     if (i != j) cq_theta(&q[j], .3);
;     q[i] = 0;
;     if (i != j) cq_theta(&q[j], .5);
;     for (int k = 0; k < 4; k++) r = 2 * r + cq_measure(q[k]);
;     return r;
;   }
;   int main(int argc, char **argv) { (void)argv; return f(argc, argc - 1); }

source_filename = "p3b.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #4
  store i32 0, ptr %3, align 4
  %4 = and i32 %0, 3
  %5 = and i32 %1, 3
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef 1.000000e-01) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %7, align 1, !tbaa !6
  %12 = zext nneg i32 %4 to i64
  %13 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef 0x3FE6666666666666) #5
  %17 = zext i1 %16 to i8
  store i8 %17, ptr %13, align 1, !tbaa !6
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %16) #4
  %19 = zext i1 %18 to i32
  %20 = icmp eq i32 %4, %5
  br i1 %20, label %31, label %21

21:                                               ; preds = %2
  %22 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %23 = trunc nuw i8 %22 to i1
  %24 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %23, double noundef 3.000000e-01) #5
  %25 = zext i1 %24 to i8
  store i8 %25, ptr %7, align 1, !tbaa !6
  store i8 0, ptr %13, align 1, !tbaa !6
  %26 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %27 = trunc nuw i8 %26 to i1
  %28 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %27, double noundef 5.000000e-01) #5
  %29 = zext i1 %28 to i8
  store i8 %29, ptr %7, align 1, !tbaa !6
  br label %30

30:                                               ; preds = %31, %21
  br label %33

31:                                               ; preds = %2
  store i8 0, ptr %13, align 1, !tbaa !6
  br label %30

32:                                               ; preds = %33
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #4
  ret i32 %42

33:                                               ; preds = %30, %33
  %34 = phi i64 [ %43, %33 ], [ 0, %30 ]
  %35 = phi i32 [ %42, %33 ], [ %19, %30 ]
  %36 = shl nsw i32 %35, 1
  %37 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %34
  %38 = load i8, ptr %37, align 1, !tbaa !6, !range !10, !noundef !11
  %39 = trunc nuw i8 %38 to i1
  %40 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %39) #4
  %41 = zext i1 %40 to i32
  %42 = or disjoint i32 %36, %41
  %43 = add nuw nsw i64 %34, 1
  %44 = icmp eq i64 %43, 4
  br i1 %44, label %32, label %33, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %0, -1
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
