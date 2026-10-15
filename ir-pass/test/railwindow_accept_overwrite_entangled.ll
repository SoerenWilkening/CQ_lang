; railwindow_accept_overwrite_entangled.ll — ACCEPT + ADVERSARIAL (bd 01po.19
; S4; salvaged from the unmerged unroll branch's
; `railbank_unroll_accept_overwrite_entangled.ll`, retargeted: its `^=` needs
; S5, so the entanglement here is a temporary instead).
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
; A temporary `s = q[0] + q[1]` records two rotated cells (zext/add template
; rails), the cells are then OVERWRITTEN by a walk, and only then is `s`
; consumed. Analytic reading of the pinned stream: the overwrite is a rebind
; (fresh |0> rails h6,h7 parked in cells 0,1; the old rails h0,h1 abandoned,
; never freed); `s`'s records are reversed against h0,h1 — which no gate moved
; (a store is not a gate), so every `_unc` reads the label its forward read —
; and freed; `s*3` is measured; the cells then measure h6, h7, h2, h3. Stage 2b
; (window-aware) verifies all 8 frees. The hazard this pins: a free of a cell
; rail, or a reversal reading the REBOUND rail instead of the old one.
;
; SOURCE (clang -O1, verbatim below):
;   /* adversarial (salvaged overwrite-entangled, retargeted to S4): a temporary
;      records two rotated cells, then the cells are overwritten with a classical 0
;      inside a walk, and only then is the temporary consumed. The overwrite is a
;      REBIND: the old rails are abandoned (left allocated, never freed dirty), the
;      temporary's records are reversed against those old rails (unmoved: a store
;      is not a gate), and the cells measure their fresh |0> rails. */
;   int f(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .7 + .1 * i);
;     int s = q[0] + q[1];
;     for (int i = 0; i < 2; i++) q[i] = 0;
;     int r = cq_measure(s * 3);
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
; S4: %.rail = load i32, ptr %.rails, align 4
; S4: %h_cast = call i32 @cq_template_zext_i1_to_i8(i32 %.rail)
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %h_cast8 = call i32 @cq_template_zext_i1_to_i8(i32 %.rail2)
; S4: %h7 = call i32 @cqrt_alloc_i1(i1 false)
; S4: %h6 = call i32 @cqrt_alloc_i1(i1 false)
; S4: %h_op = call i32 @cq_template_add_i8(i32 %h_cast, i32 %h_cast8)
; S4: %h_op9 = call i32 @cq_template_mul_i8_hl(i32 %h_op, i8 3)
; S4: %h_cast10 = call i32 @cq_template_zext_i8_to_i32(i32 %h_op9)
; S4: call void @cq_template_mul_i8_hl_unc(i32 %h_op9, i32 %h_op, i8 3)
; S4: call void @cqrt_free(i32 %h_op9)
; S4: call void @cq_template_add_i8_unc(i32 %h_op, i32 %h_cast, i32 %h_cast8)
; S4: call void @cqrt_free(i32 %h_op)
; S4: call void @cq_template_zext_i1_to_i8_unc(i32 %h_cast8, i32 %.rail2)
; S4: call void @cqrt_free(i32 %h_cast8)
; S4: call void @cq_template_zext_i1_to_i8_unc(i32 %h_cast, i32 %.rail)
; S4: call void @cqrt_free(i32 %h_cast)
; S4: %m = call i32 @cqrt_measure_i32(i32 %h_cast10)
; S4: %.rail3 = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail3, double %12)
; S4: store i32 %.rail3, ptr %cq.rail.addr, align 4
; S4: %.rail5 = load i32, ptr %cq.rail.addr4, align 4
; S4: %m11 = call i1 @cqrt_measure_i1(i32 %.rail5)
; S4-LABEL: define {{.*}} @main(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %3)
; S4: %.rail = load i32, ptr %.rails, align 4
; S4: %h_cast = call i32 @cq_template_zext_i1_to_i8(i32 %.rail)
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %h_cast8 = call i32 @cq_template_zext_i1_to_i8(i32 %.rail2)
; S4: %h7 = call i32 @cqrt_alloc_i1(i1 false)
; S4: %h6 = call i32 @cqrt_alloc_i1(i1 false)
; S4: %h_op = call i32 @cq_template_add_i8(i32 %h_cast, i32 %h_cast8)
; S4: %h_op9 = call i32 @cq_template_mul_i8_hl(i32 %h_op, i8 3)
; S4: %h_cast10 = call i32 @cq_template_zext_i8_to_i32(i32 %h_op9)
; S4: call void @cq_template_mul_i8_hl_unc(i32 %h_op9, i32 %h_op, i8 3)
; S4: call void @cqrt_free(i32 %h_op9)
; S4: call void @cq_template_add_i8_unc(i32 %h_op, i32 %h_cast, i32 %h_cast8)
; S4: call void @cqrt_free(i32 %h_op)
; S4: call void @cq_template_zext_i1_to_i8_unc(i32 %h_cast8, i32 %.rail2)
; S4: call void @cqrt_free(i32 %h_cast8)
; S4: call void @cq_template_zext_i1_to_i8_unc(i32 %h_cast, i32 %.rail)
; S4: call void @cqrt_free(i32 %h_cast)
; S4: %m = call i32 @cqrt_measure_i32(i32 %h_cast10)
; S4: %.rail3 = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail3, double %12)
; S4: store i32 %.rail3, ptr %cq.rail.addr, align 4
; S4: %.rail5 = load i32, ptr %cq.rail.addr4, align 4
; S4: %m11 = call i1 @cqrt_measure_i1(i32 %.rail5)

; ModuleID = 'overwrite_ent.c'
source_filename = "overwrite_ent.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #4
  store i32 0, ptr %1, align 4
  br label %10

2:                                                ; preds = %10
  %3 = load i8, ptr %1, align 4, !tbaa !6, !range !10, !noundef !11
  %4 = getelementptr inbounds i8, ptr %1, i64 1
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  store i16 0, ptr %1, align 4
  %6 = add nuw nsw i8 %5, %3
  %7 = mul nuw nsw i8 %6, 3
  %8 = zext nneg i8 %7 to i32
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  br label %23

10:                                               ; preds = %0, %10
  %11 = phi i64 [ 0, %0 ], [ %20, %10 ]
  %12 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %11
  %13 = load i8, ptr %12, align 1, !tbaa !6, !range !10, !noundef !11
  %14 = trunc nuw i8 %13 to i1
  %15 = trunc nuw nsw i64 %11 to i32
  %16 = uitofp nneg i32 %15 to double
  %17 = tail call double @llvm.fmuladd.f64(double %16, double 1.000000e-01, double 0x3FE6666666666666)
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %14, double noundef %17) #5
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %12, align 1, !tbaa !6
  %20 = add nuw nsw i64 %11, 1
  %21 = icmp eq i64 %20, 4
  br i1 %21, label %2, label %10, !llvm.loop !12

22:                                               ; preds = %23
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #4
  ret i32 %32

23:                                               ; preds = %2, %23
  %24 = phi i64 [ 0, %2 ], [ %33, %23 ]
  %25 = phi i32 [ %9, %2 ], [ %32, %23 ]
  %26 = shl nsw i32 %25, 1
  %27 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %24
  %28 = load i8, ptr %27, align 1, !tbaa !6, !range !10, !noundef !11
  %29 = trunc nuw i8 %28 to i1
  %30 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %29) #4
  %31 = zext i1 %30 to i32
  %32 = or disjoint i32 %26, %31
  %33 = add nuw nsw i64 %24, 1
  %34 = icmp eq i64 %33, 4
  br i1 %34, label %22, label %23, !llvm.loop !15
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
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #4
  store i32 0, ptr %1, align 4
  br label %10

2:                                                ; preds = %10
  %3 = load i8, ptr %1, align 4, !tbaa !6, !range !10, !noundef !11
  %4 = getelementptr inbounds i8, ptr %1, i64 1
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  store i16 0, ptr %1, align 4
  %6 = add nuw nsw i8 %5, %3
  %7 = mul nuw nsw i8 %6, 3
  %8 = zext nneg i8 %7 to i32
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  br label %22

10:                                               ; preds = %10, %0
  %11 = phi i64 [ 0, %0 ], [ %20, %10 ]
  %12 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %11
  %13 = load i8, ptr %12, align 1, !tbaa !6, !range !10, !noundef !11
  %14 = trunc nuw i8 %13 to i1
  %15 = trunc nuw nsw i64 %11 to i32
  %16 = uitofp nneg i32 %15 to double
  %17 = tail call double @llvm.fmuladd.f64(double %16, double 1.000000e-01, double 0x3FE6666666666666)
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %14, double noundef %17) #5
  %19 = zext i1 %18 to i8
  store i8 %19, ptr %12, align 1, !tbaa !6
  %20 = add nuw nsw i64 %11, 1
  %21 = icmp eq i64 %20, 4
  br i1 %21, label %2, label %10, !llvm.loop !12

22:                                               ; preds = %22, %2
  %23 = phi i64 [ 0, %2 ], [ %32, %22 ]
  %24 = phi i32 [ %9, %2 ], [ %31, %22 ]
  %25 = shl nsw i32 %24, 1
  %26 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %23
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %28) #4
  %30 = zext i1 %29 to i32
  %31 = or disjoint i32 %25, %30
  %32 = add nuw nsw i64 %23, 1
  %33 = icmp eq i64 %32, 4
  br i1 %33, label %34, label %22, !llvm.loop !15

34:                                               ; preds = %22
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #4
  ret i32 %31
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
