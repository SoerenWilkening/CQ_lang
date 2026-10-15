; railwindow_version_promotion_points.ll — ACCEPT + ADVERSARIAL (bd `test_C_libtooling-01po.19` S7,
; R11 round 1 A-F1, reviewer probe review_s7A/p4.c).
;
; Every access of q[j] sits under the user's own `if (i != j)`, so the source
; accesses alone prove the pair. But S3 promotes q[j] (two loads, two stores)
; with its SEED at the region entry and its WRITE-BACK at the latch — on the
; i == j path too, where the stale seed would clobber `q[i] = 0`. Before the
; fix this was loud only through the post-promotion S7 re-check ("needs S7").
; INVARIANT: the alias proof is asked at the promotion's own touches (seed and
; write-backs, `railWindowPlanPoints`), in the versioner and in the promoter;
; unproven there, the window is versioned. Exactly one versioning.
;
; ANALYTIC TRACE per trip i (h_i, h_j = the cells' rails):
;   distinct (i != j): Ry(.7) h_i; Ry(.3), Ry(.5) on h_j; q[i] := alloc(0);
;     the user's i == j arm is dead there (both edges dominate: "distinct").
;   aliased  (i == j): Ry(.7) h_i; q[i] := alloc(0) — the user's `i != j`
;     arms are folded away in the aliased copy (A-F2), no gate on q[j].
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int f(long j) {
;     bool q[4] = {0};
;     j &= 3;
;     for (long i = 0; i < 4; i++) {
;       cq_theta(&q[i], .7);
;       if (i != j) cq_theta(&q[j], .3);
;       q[i] = 0;
;       if (i != j) cq_theta(&q[j], .5);
;     }
;     int r = 0;
;     for (int k = 0; k < 4; k++) r = 2 * r + cq_measure(q[k]);
;     return r;
;   }
;   int main(int argc, char **argv) { (void)argv; return f(argc); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --input-file=%t.ll
; RUN: env CQ_RAILWINDOW_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=WIN
; WIN: CQ_RAILWINDOW_DBG: @f claims
; WIN: CQ_RAILWINDOW_DBG: version region
; WIN-NOT: CQ_RAILWINDOW_DBG: version region
; WIN-NOT: alias unproven: {{.*}} vs
;
; CHECK-LABEL: define i32 @f(
; CHECK: br i1 %cq.win.ne, label %[[D:[^,]+]], label %[[AL:[^,]+]], !cq.railwindow.version
; CHECK: {{^}}[[D]]:
; CHECK: call void @cqrt_ry_i1(i32 {{%[a-z0-9.]+}}, double 0x3FE6666666666666)
; CHECK: call void @cqrt_ry_i1(i32 [[HJ:%[a-z0-9.]+]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[HJ]], double 5.000000e-01)
; CHECK: {{^}}[[AL]]:
; CHECK-NEXT: [[HI:%[a-z0-9.]+]] = load i32, ptr
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[HI]], double 0x3FE6666666666666)
; CHECK-NOT: cqrt_ry_i1
; CHECK: call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NOT: cqrt_ry_i1
; CHECK: {{^}}}

source_filename = "rA_p4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i64 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #4
  store i32 0, ptr %2, align 4
  %3 = and i64 %0, 3
  %4 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %3
  br label %5

5:                                                ; preds = %1, %23
  %6 = phi i64 [ 0, %1 ], [ %24, %23 ]
  %7 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef 0x3FE6666666666666) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %7, align 1, !tbaa !6
  %12 = icmp eq i64 %6, %3
  br i1 %12, label %22, label %13

13:                                               ; preds = %5
  %14 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef 3.000000e-01) #5
  %17 = zext i1 %16 to i8
  store i8 %17, ptr %4, align 1, !tbaa !6
  store i8 0, ptr %7, align 1, !tbaa !6
  %18 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = trunc nuw i8 %18 to i1
  %20 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %19, double noundef 5.000000e-01) #5
  %21 = zext i1 %20 to i8
  store i8 %21, ptr %4, align 1, !tbaa !6
  br label %23

22:                                               ; preds = %5
  store i8 0, ptr %7, align 1, !tbaa !6
  br label %23

23:                                               ; preds = %22, %13
  %24 = add nuw nsw i64 %6, 1
  %25 = icmp eq i64 %24, 4
  br i1 %25, label %27, label %5, !llvm.loop !12

26:                                               ; preds = %27
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #4
  ret i32 %36

27:                                               ; preds = %23, %27
  %28 = phi i64 [ %37, %27 ], [ 0, %23 ]
  %29 = phi i32 [ %36, %27 ], [ 0, %23 ]
  %30 = shl nsw i32 %29, 1
  %31 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %28
  %32 = load i8, ptr %31, align 1, !tbaa !6, !range !10, !noundef !11
  %33 = trunc nuw i8 %32 to i1
  %34 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %33) #4
  %35 = zext i1 %34 to i32
  %36 = or disjoint i32 %30, %35
  %37 = add nuw nsw i64 %28, 1
  %38 = icmp eq i64 %37, 4
  br i1 %38, label %26, label %27, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = sext i32 %0 to i64
  %4 = tail call i32 @f(i64 noundef %3)
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
!15 = distinct !{!15, !13, !14}
