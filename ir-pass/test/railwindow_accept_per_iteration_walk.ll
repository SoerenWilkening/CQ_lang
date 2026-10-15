; railwindow_accept_per_iteration_walk.ll — ACCEPT (bd 01po.19 S4 (d), design
; addendum "per-iteration objects"): a `_Bool q[4] = {0}` declared in a loop
; body and walked by an inner loop.
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
; Analytic reading: every outer trip re-materializes four |0> rails right after
; the scope's own initializer (the walk copies the memset), rotates cell i&3 by
; .1*(i+k), and measures all four. The previous trip's rails are LEFT
; ALLOCATED (never freed: not provably |0>). Traced for n=3: 12 allocs, three
; per-trip rotation sets, 12 measures.
;
; SOURCE (clang -O1, verbatim below):
;   /* bd 01po.19 S4 (d): an array declared inside a loop body: fresh rails per trip, the
;      previous trip's rails left allocated. */
;   int f(int n) {
;     int r = 0;
;     for (int k = 0; k < n; k++) {
;       bool q[4] = {0};
;       for (int i = 0; i < n; i++) cq_theta(&q[i & 3], .1 * (i + k));
;       for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     }
;     return r;
;   }
;   int main(void) { return f(3); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not='error:' --implicit-check-not=cqrt_free
; S4-LABEL: define {{.*}} @f(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %10)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double %18)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail2)
; S4-LABEL: define {{.*}} @main(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %6)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double %13)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail2)

; ModuleID = 'periter.c'
source_filename = "periter.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i8], align 4
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %6, label %4

4:                                                ; preds = %23, %1
  %5 = phi i32 [ 0, %1 ], [ %35, %23 ]
  ret i32 %5

6:                                                ; preds = %1, %23
  %7 = phi i32 [ %24, %23 ], [ 0, %1 ]
  %8 = phi i32 [ %35, %23 ], [ 0, %1 ]
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #3
  store i32 0, ptr %2, align 4
  br label %9

9:                                                ; preds = %6, %9
  %10 = phi i32 [ %21, %9 ], [ 0, %6 ]
  %11 = and i32 %10, 3
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = add nuw nsw i32 %10, %7
  %17 = uitofp nneg i32 %16 to double
  %18 = fmul double %17, 1.000000e-01
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef %18) #4
  %20 = zext i1 %19 to i8
  store i8 %20, ptr %13, align 1, !tbaa !6
  %21 = add nuw nsw i32 %10, 1
  %22 = icmp eq i32 %21, %0
  br i1 %22, label %26, label %9, !llvm.loop !12

23:                                               ; preds = %26
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #3
  %24 = add nuw nsw i32 %7, 1
  %25 = icmp eq i32 %24, %0
  br i1 %25, label %4, label %6, !llvm.loop !15

26:                                               ; preds = %9, %26
  %27 = phi i64 [ %36, %26 ], [ 0, %9 ]
  %28 = phi i32 [ %35, %26 ], [ %8, %9 ]
  %29 = shl nsw i32 %28, 1
  %30 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %27
  %31 = load i8, ptr %30, align 1, !tbaa !6, !range !10, !noundef !11
  %32 = trunc nuw i8 %31 to i1
  %33 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %32) #3
  %34 = zext i1 %33 to i32
  %35 = or disjoint i32 %29, %34
  %36 = add nuw nsw i64 %27, 1
  %37 = icmp eq i64 %36, 4
  br i1 %37, label %23, label %26, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  br label %2

2:                                                ; preds = %18, %0
  %3 = phi i64 [ %19, %18 ], [ 0, %0 ]
  %4 = phi i32 [ %30, %18 ], [ 0, %0 ]
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  br label %5

5:                                                ; preds = %5, %2
  %6 = phi i64 [ %16, %5 ], [ 0, %2 ]
  %7 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %6
  %8 = load i8, ptr %7, align 1, !tbaa !6, !range !10, !noundef !11
  %9 = trunc nuw i8 %8 to i1
  %10 = add nuw nsw i64 %6, %3
  %11 = trunc nuw nsw i64 %10 to i32
  %12 = uitofp nneg i32 %11 to double
  %13 = fmul double %12, 1.000000e-01
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %9, double noundef %13) #4
  %15 = zext i1 %14 to i8
  store i8 %15, ptr %7, align 1, !tbaa !6
  %16 = add nuw nsw i64 %6, 1
  %17 = icmp eq i64 %16, 3
  br i1 %17, label %21, label %5, !llvm.loop !12

18:                                               ; preds = %21
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  %19 = add nuw nsw i64 %3, 1
  %20 = icmp eq i64 %19, 3
  br i1 %20, label %33, label %2, !llvm.loop !15

21:                                               ; preds = %5, %21
  %22 = phi i64 [ %31, %21 ], [ 0, %5 ]
  %23 = phi i32 [ %30, %21 ], [ %4, %5 ]
  %24 = shl nsw i32 %23, 1
  %25 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %22
  %26 = load i8, ptr %25, align 1, !tbaa !6, !range !10, !noundef !11
  %27 = trunc nuw i8 %26 to i1
  %28 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %27) #3
  %29 = zext i1 %28 to i32
  %30 = or disjoint i32 %24, %29
  %31 = add nuw nsw i64 %22, 1
  %32 = icmp eq i64 %31, 4
  br i1 %32, label %18, label %21, !llvm.loop !16

33:                                               ; preds = %18
  ret i32 %30
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
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
