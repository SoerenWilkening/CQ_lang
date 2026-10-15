; spec_accept_gate_sub_export_return.ll — ACCEPT (bd test_C_libtooling-p3kd.21,
; bd jx32; owner ruling owner-ruling-p3kd21-gate-subroutines-2026-10-14).
;
;   __attribute__((noinline)) bool ry_b(bool t, double th) { cq_theta(&t, th); return t; }
;   long ry_l(long t, double th) { cq_theta(&t, th); return t; }
;   int main(void) { ... cq_theta(&q0, 1.0); q1 = ry_b(q1, 0.4); if (q0) q1 = ry_b(q1, 0.2); ... }
;
; `main`'s two calls of the noinline `ry_b` are compiled at their sites
; (SpecializeGateInline.h), the second under `q0`'s control (a controlled Ry on
; `q0`'s rail, never an uncontrolled `0.2`), and `ry_b` is then ERASED: the module
; defines `main`, so nothing outside it can call the external `ry_b` (R11 r1 item
; 5). `ry_l` is an export with no in-module use returning a `long`: its tainted
; `ret` returns the register's i32 handle ZERO-EXTENDED to i64, the C signature
; unchanged (`widenQuantumExportReturns`). The escaping handle is never freed.
; Narrower and floating-point exports keep the decline:
; spec_reject_gate_sub_export_{bool,double}.ll. `clang -O1 -include CQ.h` output
; verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i64 @ry_l(i64 noundef %0, double noundef %1)
; CHECK-NEXT: [[L:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i64(i64 %0)
; CHECK-NEXT: call void @cqrt_ry_i64(i32 [[L]], double %1)
; CHECK-NEXT: [[W:%[0-9a-z.]+]] = zext i32 [[L]] to i64
; CHECK-NEXT: ret i64 [[W]]
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK: [[Q0:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[Q0]], double 1.000000e+00)
; CHECK-NEXT: [[Q1:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[Q1]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 [[Q0]], i32 [[Q1]], double 2.000000e-01)
; CHECK-NOT: cqrt_free
; CHECK: ret i32 0
; CHECK-NOT: @ry_b

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
