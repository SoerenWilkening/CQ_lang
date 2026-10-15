; railwindow_accept_uninit_seed_zero.ll — ACCEPT (bd 01po.19 S4 review B-1,
; ruling Q1): an array with NO pre-Q classical writer (an uninitialized `int
; q[n]` VLA) seeds every cell |0> through the walk's zero path, the
; undef-seed-is-zero rule of bd z9t1 (one rule with
; `normalizeUndefRotationSeed`). Before the fix the walk read the
; indeterminate original object and the trace printed garbage seeds
; (`cqrt_alloc_i32(1439144840)`). Pinned: the seed is the constant 0 and the
; original object is never read (no `cq.rail.init` load). Traced (n=3):
; alloc(0) x3, Ry(.3) x3, Ry(.2) x3, three measures.
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; ruling
; `ruling-01po19-s4-r1-qs-2026-10-15`).
;
; SOURCE (clang -O1, verbatim below):
;   /* bd 01po.19 S4 review B-1: an array no classical code ever writes before
;      the first quantum write: every cell is seeded |0>. */
;   int f(int n) {
;     int q[n];
;     for (int i = 0; i < n; i++) cq_theta(&q[i], .3);
;     for (int i = 0; i < n; i++) cq_theta(&q[i], .2);
;     int r = 0;
;     for (int i = 0; i < n; i++) r += cq_measure(q[i]);
;     return r;
;   }
;   int main(void) { return f(3); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not='error:' --implicit-check-not=cqrt_free --implicit-check-not=cq.rail.init
; S4-LABEL: define {{.*}} @f(
; S4: %.rails = alloca i32, i64 %2, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i32(i32 0)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i32(i32 %.rail, double 3.000000e-01)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: call void @cqrt_ry_i32(i32 %.rail2, double 2.000000e-01)
; S4: store i32 %.rail2, ptr %cq.rail.addr1, align 4
; S4: %.rail4 = load i32, ptr %cq.rail.addr3, align 4
; S4: %m = call i32 @cqrt_measure_i32(i32 %.rail4)
; S4-LABEL: define {{.*}} @main(
; S4: %.rails = alloca i32, i64 3, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i32(i32 0)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i32(i32 %.rail, double 3.000000e-01)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: call void @cqrt_ry_i32(i32 %.rail2, double 2.000000e-01)
; S4: store i32 %.rail2, ptr %cq.rail.addr1, align 4
; S4: %.rail4 = load i32, ptr %cq.rail.addr3, align 4
; S4: %m = call i32 @cqrt_measure_i32(i32 %.rail4)

; ModuleID = 'uninit.c'
source_filename = "uninit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = zext i32 %0 to i64
  %3 = alloca i32, i64 %2, align 16
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = zext nneg i32 %0 to i64
  br label %11

7:                                                ; preds = %11, %1
  %8 = icmp sgt i32 %0, 0
  br i1 %8, label %9, label %18

9:                                                ; preds = %7
  %10 = zext nneg i32 %0 to i64
  br label %22

11:                                               ; preds = %5, %11
  %12 = phi i64 [ 0, %5 ], [ %16, %11 ]
  %13 = getelementptr inbounds i32, ptr %3, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !6
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 3.000000e-01) #3
  store i32 %15, ptr %13, align 4, !tbaa !6
  %16 = add nuw nsw i64 %12, 1
  %17 = icmp eq i64 %16, %6
  br i1 %17, label %7, label %11, !llvm.loop !10

18:                                               ; preds = %22, %7
  %19 = icmp sgt i32 %0, 0
  br i1 %19, label %20, label %29

20:                                               ; preds = %18
  %21 = zext nneg i32 %0 to i64
  br label %31

22:                                               ; preds = %9, %22
  %23 = phi i64 [ 0, %9 ], [ %27, %22 ]
  %24 = getelementptr inbounds i32, ptr %3, i64 %23
  %25 = load i32, ptr %24, align 4, !tbaa !6
  %26 = tail call i32 @cq_theta_si32(i32 noundef %25, double noundef 2.000000e-01) #3
  store i32 %26, ptr %24, align 4, !tbaa !6
  %27 = add nuw nsw i64 %23, 1
  %28 = icmp eq i64 %27, %10
  br i1 %28, label %18, label %22, !llvm.loop !13

29:                                               ; preds = %31, %18
  %30 = phi i32 [ 0, %18 ], [ %37, %31 ]
  ret i32 %30

31:                                               ; preds = %20, %31
  %32 = phi i64 [ 0, %20 ], [ %38, %31 ]
  %33 = phi i32 [ 0, %20 ], [ %37, %31 ]
  %34 = getelementptr inbounds i32, ptr %3, i64 %32
  %35 = load i32, ptr %34, align 4, !tbaa !6
  %36 = tail call i32 @cq_measure_si32(i32 noundef %35) #4
  %37 = add nsw i32 %36, %33
  %38 = add nuw nsw i64 %32, 1
  %39 = icmp eq i64 %38, %21
  br i1 %39, label %29, label %31, !llvm.loop !14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %1)
  br label %2

2:                                                ; preds = %2, %0
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = getelementptr inbounds i32, ptr %1, i64 %3
  %5 = load i32, ptr %4, align 4, !tbaa !6
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 3.000000e-01) #3
  store i32 %6, ptr %4, align 4, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 3
  br i1 %8, label %9, label %2, !llvm.loop !10

9:                                                ; preds = %2, %9
  %10 = phi i64 [ %14, %9 ], [ 0, %2 ]
  %11 = getelementptr inbounds i32, ptr %1, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 2.000000e-01) #3
  store i32 %13, ptr %11, align 4, !tbaa !6
  %14 = add nuw nsw i64 %10, 1
  %15 = icmp eq i64 %14, 3
  br i1 %15, label %16, label %9, !llvm.loop !13

16:                                               ; preds = %9, %16
  %17 = phi i64 [ %23, %16 ], [ 0, %9 ]
  %18 = phi i32 [ %22, %16 ], [ 0, %9 ]
  %19 = getelementptr inbounds i32, ptr %1, i64 %17
  %20 = load i32, ptr %19, align 4, !tbaa !6
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #4
  %22 = add nsw i32 %21, %18
  %23 = add nuw nsw i64 %17, 1
  %24 = icmp eq i64 %23, 3
  br i1 %24, label %25, label %16, !llvm.loop !14

25:                                               ; preds = %16
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %1)
  ret i32 %22
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nomerge nounwind }
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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = distinct !{!14, !11, !12}
