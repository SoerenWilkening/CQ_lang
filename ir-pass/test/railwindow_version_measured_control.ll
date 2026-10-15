; railwindow_version_measured_control.ll — ACCEPT (bd `test_C_libtooling-01po.19` S7;
; ADVERSARIAL twin of railwindow_reject_alias_self_control.ll).
;
; `if (cq_measure(q[i])) cq_theta(&q[j], .5)` with runtime i, j: the condition
; is a MEASUREMENT result, classical (R3: `cq_measure` is the sole sink), so the
; aliased copy is "measure x, then rotate x if 1" — legal, not self-control.
; The control == target refusal must not fire (it walks only quantum values).
;
; ANALYTIC TRACE: h = the rail of q[i], Ry(.3).
;   distinct (i != j): m = measure(h); if m: Ry(.5) on cell j's rail.
;   aliased  (i == j): m = measure(h); if m: Ry(.5) on h.
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int f(int i, int j) {
;     bool q[4] = {0};
;     i &= 3; j &= 3;
;     cq_theta(&q[i], .3);
;     if (cq_measure(q[i])) cq_theta(&q[j], .5);
;     int r = 0;
;     for (int k = 0; k < 4; k++) r = 2 * r + cq_measure(q[k]);
;     return r;
;   }
;   int main(int argc, char **argv) { (void)argv; return f(argc, argc + 1); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --input-file=%t.ll --implicit-check-not='cqrt_ry_i1_controlled'
; CHECK-LABEL: define i32 @f(
; CHECK: [[H:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[H]], double 3.000000e-01)
; CHECK: br i1 %cq.win.ne, label %[[D:[^,]+]], label %[[AL:[^,]+]], !cq.railwindow.version
; CHECK: {{^}}[[D]]:
; CHECK: [[M:%[a-z0-9.]+]] = call i1 @cqrt_measure_i1(i32 [[H]])
; CHECK-NEXT: br i1 [[M]],
; CHECK: [[RJ:%[a-z0-9.]+]] = load i32, ptr
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[RJ]], double 5.000000e-01)
; CHECK: {{^}}[[AL]]:
; CHECK: [[M2:%[a-z0-9.]+]] = call i1 @cqrt_measure_i1(i32 [[H]])
; CHECK: br i1 [[M2]],
; CHECK: call void @cqrt_ry_i1(i32 [[H]], double 5.000000e-01)

source_filename = "measctl.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #4
  store i32 0, ptr %3, align 4
  %4 = and i32 %0, 3
  %5 = zext nneg i32 %4 to i64
  %6 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %5
  %7 = load i8, ptr %6, align 1, !tbaa !6, !range !10, !noundef !11
  %8 = trunc nuw i8 %7 to i1
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 3.000000e-01) #5
  %10 = zext i1 %9 to i8
  store i8 %10, ptr %6, align 1, !tbaa !6
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9) #4
  br i1 %11, label %13, label %12

12:                                               ; preds = %13, %2
  br label %22

13:                                               ; preds = %2
  %14 = and i32 %1, 3
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = trunc nuw i8 %17 to i1
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %18, double noundef 5.000000e-01) #5
  %20 = zext i1 %19 to i8
  store i8 %20, ptr %16, align 1, !tbaa !6
  br label %12

21:                                               ; preds = %22
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #4
  ret i32 %31

22:                                               ; preds = %12, %22
  %23 = phi i64 [ %32, %22 ], [ 0, %12 ]
  %24 = phi i32 [ %31, %22 ], [ 0, %12 ]
  %25 = shl nsw i32 %24, 1
  %26 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %23
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %28) #4
  %30 = zext i1 %29 to i32
  %31 = or disjoint i32 %25, %30
  %32 = add nuw nsw i64 %23, 1
  %33 = icmp eq i64 %32, 4
  br i1 %33, label %21, label %22, !llvm.loop !12
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
