; lowering_stale_speccall_libm_placed_accept.ll — ACCEPT (bd test_C_libtooling-r2j3.6,
; population 4: a math.h call `tools/cqc` lifts; owner ruling bd 57ch (A)).
;
;   #include <math.h>
;   int main(void) {
;     double q = 0; cq_theta(&q, .5);
;     double q2 = q; cq_theta(&q2, .3);
;     double r = cbrt(q);              // reads the PRE-Ry record
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; The module is what `cqc` hands the pass for this program, reduced to `main` and the
; injected body it binds (`llvm-link` with build/libm/cq_libm.bc, then
; `llvm-extract --func=main --func=__cq_libm_cbrt --recursive`, `opt -strip-debug`).
; `bindLibmCalls` binds the quantum `cbrt` call to `__cq_libm_cbrt` and the call is
; lifted. Since bd 3c6m.72 this lowered at exit 0 with `__cq_q___cq_libm_cbrt_1(h)`
; AFTER `ry(h, .3)` (bd r2j3.6 note, 2026-10-06): cbrt of the rotated register. The
; bound call is `memory(none)` and `willreturn`, so it is PLACED just before the gate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @main()
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = call i32 @__cq_q___cq_libm_cbrt_1(i32 %[[H]])
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: call double @cqrt_measure_f64(i32 %[[R]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call double @cq_theta_f64(double noundef 0.000000e+00, double noundef 5.000000e-01) #5
  %2 = tail call double @cq_theta_f64(double noundef %1, double noundef 3.000000e-01) #5
  %3 = tail call double @cbrt(double noundef %1) #6
  %4 = tail call double @cq_measure_f64(double noundef %3) #7
  %5 = fptosi double %4 to i32
  %6 = tail call double @cq_measure_f64(double noundef %2) #7
  %7 = fptosi double %6 to i32
  %8 = add nsw i32 %7, %5
  ret i32 %8
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare double @cbrt(double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define double @__cq_libm_cbrt(double noundef %0) #4 {
  %2 = bitcast double %0 to i64
  %3 = lshr i64 %2, 32
  %4 = trunc nuw i64 %3 to i32
  %5 = trunc i64 %2 to i32
  %6 = and i32 %4, -2147483648
  %7 = and i32 %4, 2147483647
  %8 = icmp ugt i32 %7, 2146435071
  br i1 %8, label %9, label %11

9:                                                ; preds = %1
  %10 = fadd double %0, %0
  br label %52

11:                                               ; preds = %1
  %12 = icmp ult i32 %7, 1048576
  br i1 %12, label %13, label %22

13:                                               ; preds = %11
  %14 = or i32 %7, %5
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %52, label %16

16:                                               ; preds = %13
  %17 = fmul double %0, 0x4350000000000000
  %18 = bitcast double %17 to i64
  %19 = lshr i64 %18, 32
  %20 = trunc nuw i64 %19 to i32
  %21 = and i32 %20, 2147483647
  br label %22

22:                                               ; preds = %16, %11
  %23 = phi i32 [ %21, %16 ], [ %7, %11 ]
  %24 = phi i32 [ 696219795, %16 ], [ 715094163, %11 ]
  %25 = udiv i32 %23, 3
  %26 = add nuw nsw i32 %25, %24
  %27 = or disjoint i32 %26, %6
  %28 = zext i32 %27 to i64
  %29 = shl nuw i64 %28, 32
  %30 = bitcast i64 %29 to double
  %31 = fmul double %30, %30
  %32 = fdiv double %30, %0
  %33 = fmul double %31, %32
  %34 = tail call double @llvm.fmuladd.f64(double %33, double 0x3FF9F1604A49D6C2, double 0xBFFE28E092F02420)
  %35 = tail call double @llvm.fmuladd.f64(double %33, double %34, double 0x3FFE03E60F61E692)
  %36 = fmul double %33, %33
  %37 = fmul double %33, %36
  %38 = tail call double @llvm.fmuladd.f64(double %33, double 0x3FC2B000D4E4EDD7, double 0xBFE844CBBEE751D9)
  %39 = tail call double @llvm.fmuladd.f64(double %37, double %38, double %35)
  %40 = fmul double %39, %30
  %41 = bitcast double %40 to i64
  %42 = and i64 %41, -1073741824
  %43 = add i64 %42, 2147483648
  %44 = bitcast i64 %43 to double
  %45 = fmul double %44, %44
  %46 = fdiv double %0, %45
  %47 = fadd double %44, %44
  %48 = fsub double %46, %44
  %49 = fadd double %47, %46
  %50 = fdiv double %48, %49
  %51 = tail call double @llvm.fmuladd.f64(double %44, double %50, double %44)
  br label %52

52:                                               ; preds = %22, %13, %9
  %53 = phi double [ %10, %9 ], [ %51, %22 ], [ %0, %13 ]
  ret double %53
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind willreturn memory(none) }
attributes #7 = { nounwind }


