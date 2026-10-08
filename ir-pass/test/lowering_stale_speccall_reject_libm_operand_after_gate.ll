; lowering_stale_speccall_reject_libm_operand_after_gate.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, population 4: a math.h call `tools/cqc` lifts).
;
;   #include <math.h>
;   int main(void) {
;     double q = 0; cq_theta(&q, .5);
;     double q2 = q; cq_theta(&q2, .3);
;     double k = cq_measure(q2);       // a POST-gate value ...
;     double r = fdim(q, k);           // ... read beside the PRE-gate record
;     return (int)cq_measure(r) + (int)k;
;   }
;
; The module is what `cqc` hands the pass, reduced to `main` and the injected bodies it
; binds (`llvm-link` with build/libm/cq_libm.bc, then `llvm-extract --func=main
; --func=__cq_libm_fdim --recursive`, `opt -strip-debug`). Before r2j3.6: exit 0 with
; `__cq_q___cq_libm_fdim_01(h, m)` after `ry(h, .3)` — fdim of the rotated register.
; The bound call needs the pre-Ry label of `q` and a value that exists only after the
; gate, so it cannot be placed (57ch (B) is not built): loud, with the one
; stale-record string.
; RETIREMENT TRIGGER (L7): when 57ch (B) lands this shape lowers with a snapshot and a
; warning; flip this file to an accept in that change.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call double @cq_theta_f64(double noundef 0.000000e+00, double noundef 5.000000e-01) #5
  %2 = tail call double @cq_theta_f64(double noundef %1, double noundef 3.000000e-01) #5
  %3 = tail call double @cq_measure_f64(double noundef %2) #6
  %4 = tail call double @fdim(double noundef %1, double noundef %3) #7
  %5 = tail call double @cq_measure_f64(double noundef %4) #6
  %6 = fptosi double %5 to i32
  %7 = fptosi double %3 to i32
  %8 = add nsw i32 %6, %7
  ret i32 %8
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare double @fdim(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define noundef double @__cq_libm_fdim(double noundef %0, double noundef %1) #3 {
  %3 = tail call i32 @__cq_libm_isnan(double noundef %0) #8
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %12

5:                                                ; preds = %2
  %6 = tail call i32 @__cq_libm_isnan(double noundef %1) #8
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %8, label %12

8:                                                ; preds = %5
  %9 = fcmp ogt double %0, %1
  %10 = fsub double %0, %1
  %11 = select i1 %9, double %10, double 0.000000e+00
  br label %12

12:                                               ; preds = %8, %5, %2
  %13 = phi double [ %11, %8 ], [ %0, %2 ], [ %1, %5 ]
  ret double %13
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define hidden range(i32 0, 2) i32 @__cq_libm_isnan(double noundef %0) local_unnamed_addr #4 {
  %2 = bitcast double %0 to i64
  %3 = and i64 %2, 9218868437227405312
  %4 = icmp eq i64 %3, 9218868437227405312
  %5 = and i64 %2, 4503599627370495
  %6 = icmp ne i64 %5, 0
  %7 = and i1 %4, %6
  %8 = zext i1 %7 to i32
  ret i32 %8
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }
attributes #7 = { nounwind willreturn memory(none) }
attributes #8 = { nobuiltin nounwind "no-builtins" }


