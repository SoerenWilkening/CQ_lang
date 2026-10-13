; lowering_stale_record_sin_placed_accept.ll — ACCEPT (bd test_C_libtooling-57ch.3,
; batch 053; owner ruling bd 57ch (A)): a stale DIRECT `sin` (the bd 3c6m.71 route,
; one backend call) is placed before its staling gate like any pure op.
;
;   #include <math.h>
;   int main(void) {
;     double x = 0.25; cq_theta(&x, .5);
;     double y = x; cq_theta(&y, .3);
;     double s = sin(x);               // reads the PRE-Ry record
;     return (int)cq_measure(s) + (int)cq_measure(y);
;   }
;
; `llvm.sin.f64` is a curated pure producer (`inLowerOpsScope`), so it is asked the
; pure-op stale question and, since 57ch.3, placed when legal: `memory(none)` and
; `willreturn`, nothing crossed but the gate. Before batch 053 it declined loudly.
; The CHECK-NEXT chain is the load-bearing order: the template between the two Ry.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_f64(double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[S:.*]] = call i32 @cq_template_sin_f64(i32 %[[H]])
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 3.000000e-01)
; CHECK:      call double @cqrt_measure_f64(i32 %[[S]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main() local_unnamed_addr #0 {
  %1 = tail call double @cq_theta_f64(double noundef 2.500000e-01, double noundef 5.000000e-01) #3
  %2 = tail call double @cq_theta_f64(double noundef %1, double noundef 3.000000e-01) #3
  %3 = tail call double @llvm.sin.f64(double %1)
  %4 = tail call double @cq_measure_f64(double noundef %3) #4
  %5 = fptosi double %4 to i32
  %6 = tail call double @cq_measure_f64(double noundef %2) #4
  %7 = fptosi double %6 to i32
  %8 = add nsw i32 %7, %5
  ret i32 %8
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr

declare double @llvm.sin.f64(double) #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr

attributes #0 = { nounwind }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
