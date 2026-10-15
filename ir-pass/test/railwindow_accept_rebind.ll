; railwindow_accept_rebind.ll — ACCEPT (bd 01po.19 S4, owner ruling Q3 (a)): a
; classical store over a live, rotated cell REBINDS it.
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
; Analytic reading: h0..h3 rotated; `q[i] = 1` for i<2 becomes
; `cqrt_alloc_i1(true)` stored into the handle cell (the retype's rebind mint),
; so cells 0,1 measure fresh |1> rails and cells 2,3 their rotated rails. The
; old rails h0,h1 are ABANDONED: left allocated, never freed (a rotated rail is
; not provably |0>, R5) and never reverse-played. Pinned: no `cqrt_free`.
;
; SOURCE (clang -O1, verbatim below):
;   /* bd 01po.19 S4 / Q3: a classical store over a live rotated cell rebinds it to a fresh
;      basis rail; the old rail is abandoned (left allocated, never freed). */
;   int f(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .3 + .1 * i);
;     for (int i = 0; i < 2; i++) q[i] = 1;
;     int r = 0;
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   int main(void) { return f(); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not='error:' --implicit-check-not=cqrt_free
; S4-LABEL: define {{.*}} @f(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %3)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double %9)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %h4 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %h3 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail2)
; S4-LABEL: define {{.*}} @main(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %3)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double %9)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %h4 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %h3 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail2)

; ModuleID = 'rebind.c'
source_filename = "rebind.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #4
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %12, %2 ]
  %4 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = trunc nuw nsw i64 %3 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 1.000000e-01, double 3.000000e-01)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef %9) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %4, align 1, !tbaa !6
  %12 = add nuw nsw i64 %3, 1
  %13 = icmp eq i64 %12, 4
  br i1 %13, label %14, label %2, !llvm.loop !12

14:                                               ; preds = %2
  store i16 257, ptr %1, align 4
  br label %16

15:                                               ; preds = %16
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #4
  ret i32 %25

16:                                               ; preds = %14, %16
  %17 = phi i64 [ 0, %14 ], [ %26, %16 ]
  %18 = phi i32 [ 0, %14 ], [ %25, %16 ]
  %19 = shl nsw i32 %18, 1
  %20 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %17
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = trunc nuw i8 %21 to i1
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %22) #4
  %24 = zext i1 %23 to i32
  %25 = or disjoint i32 %19, %24
  %26 = add nuw nsw i64 %17, 1
  %27 = icmp eq i64 %26, 4
  br i1 %27, label %15, label %16, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #4
  store i32 0, ptr %1, align 4
  br label %2

2:                                                ; preds = %2, %0
  %3 = phi i64 [ 0, %0 ], [ %12, %2 ]
  %4 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = trunc nuw nsw i64 %3 to i32
  %8 = uitofp nneg i32 %7 to double
  %9 = tail call double @llvm.fmuladd.f64(double %8, double 1.000000e-01, double 3.000000e-01)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef %9) #5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %4, align 1, !tbaa !6
  %12 = add nuw nsw i64 %3, 1
  %13 = icmp eq i64 %12, 4
  br i1 %13, label %14, label %2, !llvm.loop !12

14:                                               ; preds = %2
  store i16 257, ptr %1, align 4
  br label %15

15:                                               ; preds = %15, %14
  %16 = phi i64 [ 0, %14 ], [ %25, %15 ]
  %17 = phi i32 [ 0, %14 ], [ %24, %15 ]
  %18 = shl nsw i32 %17, 1
  %19 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %16
  %20 = load i8, ptr %19, align 1, !tbaa !6, !range !10, !noundef !11
  %21 = trunc nuw i8 %20 to i1
  %22 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %21) #4
  %23 = zext i1 %22 to i32
  %24 = or disjoint i32 %18, %23
  %25 = add nuw nsw i64 %16, 1
  %26 = icmp eq i64 %25, 4
  br i1 %26, label %27, label %15, !llvm.loop !15

27:                                               ; preds = %15
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #4
  ret i32 %24
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
