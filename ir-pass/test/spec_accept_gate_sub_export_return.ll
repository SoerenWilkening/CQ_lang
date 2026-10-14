; spec_accept_gate_sub_export_return.ll — ACCEPT (bd test_C_libtooling-p3kd.21,
; bd jx32). EXTERNAL-LINKAGE gate subroutines with non-i32 quantum returns:
;
;   __attribute__((noinline)) bool ry_b(bool t, double th) { cq_theta(&t, th); return t; }
;   long   ry_l(long t, double th)   { cq_theta(&t, th); return t; }
;   double ry_d(double t, double th) { cq_theta(&t, th); return t; }
;   int main(void) { ... cq_theta(&q0, 1.0); q1 = ry_b(q1, 0.4); if (q0) q1 = ry_b(q1, 0.2); ... }
;
; Before: `cq taint escape: tainted value returned at non-i32 width` on each
; standalone body. `main`'s two calls of the noinline `ry_b` are compiled at their
; sites (SpecializeGateInline.h), the second under `q0`'s control (a controlled
; Ry on `q0`'s rail, never an uncontrolled `0.2`). The three definitions are then
; exports with no in-module use: an export's tainted `ret` carries the register's
; runtime handle, which is always `i32` (Rule 13), so its return is re-declared
; `i32` after lowering (`retypeQuantumExportReturns`); name, linkage and
; parameters are kept, the `zeroext` return attribute (it described the `_Bool`)
; is dropped, and the escaping handle is never freed.
; `clang -O1 -include CQ.h` output verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK: [[Q0:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK: [[Q1:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(
; CHECK: call void @cqrt_ry_i1(i32 [[Q1]], double 4.000000e-01)
; CHECK-NOT: call void @cqrt_ry_i1(i32 {{.*}}, double 2.000000e-01)
; CHECK: call void @cqrt_ry_i1_controlled(i32 [[Q0]], i32 [[Q1]], double 2.000000e-01)
; CHECK-NOT: @ry_b(
; CHECK: ret i32 0
; CHECK-LABEL: define i32 @ry_b(i1 noundef zeroext %0, double noundef %1)
; CHECK: [[H:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(i1 %0)
; CHECK-NOT: cqrt_free
; CHECK: ret i32 [[H]]
; CHECK-LABEL: define i32 @ry_l(i64 noundef %0, double noundef %1)
; CHECK: [[L:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i64(i64 %0)
; CHECK-NOT: cqrt_free
; CHECK: ret i32 [[L]]
; CHECK-LABEL: define i32 @ry_d(double noundef %0, double noundef %1)
; CHECK: [[D:%[0-9a-z.]+]] = call i32 @cqrt_alloc_f64(double %0)
; CHECK-NOT: cqrt_free
; CHECK: ret i32 [[D]]

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1

; Function Attrs: noinline nounwind ssp uwtable
define zeroext i1 @ry_b(i1 noundef zeroext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %0, double noundef %1) #4
  ret i1 %3
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @ry_l(i64 noundef %0, double noundef %1) local_unnamed_addr #2 {
  %3 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef %1) #4
  ret i64 %3
}

declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define double @ry_d(double noundef %0, double noundef %1) local_unnamed_addr #2 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  ret double %3
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #2 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e+00) #4
  %2 = tail call zeroext i1 @ry_b(i1 noundef zeroext false, double noundef 4.000000e-01)
  br i1 %1, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @ry_b(i1 noundef zeroext %2, double noundef 2.000000e-01)
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ %2, %0 ]
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #5
  %8 = zext i1 %7 to i32
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #5
  %10 = zext i1 %9 to i32
  %11 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %8, i32 noundef %10)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
