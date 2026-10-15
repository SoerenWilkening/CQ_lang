; railwindow_accept_cell_temp_eager.ll — ACCEPT (bd 01po.19 S4, owner ruling Q4
; (a)): a per-trip temporary read from two cells, then one of those cells
; rotated in place in the same trip.
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
; The temporary's interior records (zext q[i], zext q[i+1], their sum) must be
; reversed after their last reader (the `* 3`, whose result is measured) and
; BEFORE the in-place Ry on q[i] — eager placement. Pinned: in the loop body the
; `_unc` + `cqrt_free` of every record precede `cqrt_ry_i1(%L, .5)` on the cell
; read %L, and the cell rails themselves are never freed. Case B marks the body
; (a rail stored into a handle cell is a kept carrier, not tainted-index
; memory). Stage 2b (window-aware) verifies the 4 frees; the mutant that moves
; the Ry before the reversal is refused by it (T2-operand-mutated).
;
; SOURCE (clang -O1, verbatim below):
;   /* bd 01po.19 S4 / Q4: a temporary read from two cells, then one cell rotated in place in
;      the same trip. The temporary's interior records must be reversed before the
;      rotation (eager placement), never after it. */
;   int f(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .3 + .1 * i);
;     int r = 0;
;     for (int i = 0; i < 3; i++) {
;       int s = q[i] + q[i + 1];
;       r += cq_measure(s * 3);
;       cq_theta(&q[i], .5);
;     }
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   int main(void) { return f(); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not='error:'
; S4-LABEL: define {{.*}} @f(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %3)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double %9)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %h_cast = call i32 @cq_template_zext_i1_to_i8(i32 %.rail2)
; S4: %.rail4 = load i32, ptr %cq.rail.addr3, align 4
; S4: %h_cast7 = call i32 @cq_template_zext_i1_to_i8(i32 %.rail4)
; S4: %h_op = call i32 @cq_template_add_i8(i32 %h_cast, i32 %h_cast7)
; S4: %h_op8 = call i32 @cq_template_mul_i8_hl(i32 %h_op, i8 3)
; S4: %h_cast9 = call i32 @cq_template_zext_i8_to_i32(i32 %h_op8)
; S4: call void @cq_template_mul_i8_hl_unc(i32 %h_op8, i32 %h_op, i8 3)
; S4: call void @cqrt_free(i32 %h_op8)
; S4: call void @cq_template_add_i8_unc(i32 %h_op, i32 %h_cast, i32 %h_cast7)
; S4: call void @cqrt_free(i32 %h_op)
; S4: call void @cq_template_zext_i1_to_i8_unc(i32 %h_cast7, i32 %.rail4)
; S4: call void @cqrt_free(i32 %h_cast7)
; S4: call void @cq_template_zext_i1_to_i8_unc(i32 %h_cast, i32 %.rail2)
; S4: call void @cqrt_free(i32 %h_cast)
; S4: %m = call i32 @cqrt_measure_i32(i32 %h_cast9)
; S4: call void @cqrt_ry_i1(i32 %.rail2, double 5.000000e-01)
; S4: store i32 %.rail2, ptr %cq.rail.addr1, align 4
; S4: %.rail6 = load i32, ptr %cq.rail.addr5, align 4
; S4: %m10 = call i1 @cqrt_measure_i1(i32 %.rail6)
; S4-LABEL: define {{.*}} @main(

; ModuleID = 'temp.c'
source_filename = "temp.c"
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

14:                                               ; preds = %2, %14
  %15 = phi i64 [ %19, %14 ], [ 0, %2 ]
  %16 = phi i32 [ %26, %14 ], [ 0, %2 ]
  %17 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %15
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !10, !noundef !11
  %19 = add nuw nsw i64 %15, 1
  %20 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %19
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = add nuw nsw i8 %21, %18
  %23 = mul nuw nsw i8 %22, 3
  %24 = zext nneg i8 %23 to i32
  %25 = tail call i32 @cq_measure_si32(i32 noundef %24) #4
  %26 = add nsw i32 %25, %16
  %27 = trunc nuw i8 %18 to i1
  %28 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %27, double noundef 5.000000e-01) #5
  %29 = zext i1 %28 to i8
  store i8 %29, ptr %17, align 1, !tbaa !6
  %30 = icmp eq i64 %19, 3
  br i1 %30, label %32, label %14, !llvm.loop !15

31:                                               ; preds = %32
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #4
  ret i32 %41

32:                                               ; preds = %14, %32
  %33 = phi i64 [ %42, %32 ], [ 0, %14 ]
  %34 = phi i32 [ %41, %32 ], [ %26, %14 ]
  %35 = shl nsw i32 %34, 1
  %36 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %33
  %37 = load i8, ptr %36, align 1, !tbaa !6, !range !10, !noundef !11
  %38 = trunc nuw i8 %37 to i1
  %39 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %38) #4
  %40 = zext i1 %39 to i32
  %41 = or disjoint i32 %35, %40
  %42 = add nuw nsw i64 %33, 1
  %43 = icmp eq i64 %42, 4
  br i1 %43, label %31, label %32, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @f()
  ret i32 %1
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
!16 = distinct !{!16, !13, !14}
