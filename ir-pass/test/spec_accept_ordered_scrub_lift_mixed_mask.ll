; spec_accept_ordered_scrub_lift_mixed_mask.ll — ACCEPT (bd test_C_libtooling-9bhg's
; ordered scrub composed with bd d88e's lift; Rule-13 r2B_9bhg F-9D-2's suggested pin
; `D2`, re-spelled for bd vsfp).
;
; `t = h(q, c)` is a Phase-6 site whose clone proves the classical `k + 1`.
; `u = g2(t, q)` is a MIXED site: detected with mask 11, it shrinks to 10 once the
; ordered scrub removes `t`'s taint. It is built as `__cq_q_g2_10`, with `t` a literal
; and `q` the handle; `g2 = a * b + 1` reads both, so its verdict is QUANTUM.
; `r = u; if (c > 3) r = cq_theta(u, .2)` is a one-register lift over `u` under a
; CLASSICAL condition. Its base is a GENUINE site result, so bd d88e's re-ask
; confirms it and the module accepts.
; Measured at the bd vsfp merge (2026-09-27):
; - `main` c1136be2 DECLINES it at the l3oi fence: it builds `__cq_q_g2_11` from the
;   detection-time mask, reading the scrubbed `t` as a handle.
; - Its trace equals the hand-inlined twin's (`t = c + 1`) for arguments 5 7, 2 9, 1 1
;   and 4 4.
; - Stage 2b STRICT reports 0 violations and 0 unproven on both (TRACK_9BHG §12).
; What it pins: the mask RECOMPUTATION of the ordered scrub, in composition with the lift.
; Mutant M8 (no recompute) turns it red.
;
; RE-SPELLED for bd vsfp: r2B's `h` ignored `a`, so the drop removed the argument and
; `t` was classical from the start, with no ordered-scrub event (measured:
; `CQ_DEADARG_DBG: drop arg 0 of @h in @main`). The BRANCH-ONLY read now in `@h` keeps
; the parameter live. The `env CQ_DEADARG_DBG=1` and
; `--implicit-check-not=CQ_DEADARG_DBG` pin that the drop does not fire. IR-ONLY from C
; at -O1. RETIREMENT TRIGGER: a liveness predicate with control dependence makes the
; read dead again; re-derive the subject then (L8).
;
; Library TU (plain C, no CQ.h) — review_r2B_9bhg/probes/src/lib.c, of which this uses:
;   int h(int a, int k) { return k + 1; }        // then hand-edited as above
;   int g2(int a, int b) { return a * b + 1; }
;
; Caller TU (clang -O1 -include CQ.h):
;   int h(int a, int k); int g2(int a, int b);
;   int main(int c, char **v) {
;     int q = cq_theta(c, .5);
;     int t = h(q, c);
;     int u = g2(t, q);
;     int r = u;
;     if (c > 3) r = cq_theta(u, .2);
;     return cq_measure(r) + cq_measure(q);
;   }
;
; Regenerate: clang -O1 -emit-llvm -S each TU as above, llvm-link -S caller.ll lib.ll,
; then add the branch-only read to `@h`.
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not=CQ_DEADARG_DBG --implicit-check-not=__cq_q_g2_11
; CHECK-NOT: error
; CHECK-LABEL: define i32 @main(
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %0)
; CHECK-NEXT: [[U:%[0-9]+]] = tail call i32 @__cq_q_g2_10(i32 noundef [[T]], i32 noundef %h)
; CHECK: call void @cqrt_ry_i32(i32 [[U]], double 2.000000e-01)
; CHECK: %m = call i32 @cqrt_measure_i32(i32 [[U]])
; CHECK-LABEL: define internal i32 @__cq_q_g2_10(
; CHECK-NEXT: %h_op = call i32 @cq_template_mul_i32_hl(i32 %1, i32 %0)

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #4
  %4 = tail call i32 @h(i32 noundef %3, i32 noundef %0) #4
  %5 = tail call i32 @g2(i32 noundef %4, i32 noundef %3) #4
  %6 = icmp sgt i32 %0, 3
  br i1 %6, label %7, label %9

7:                                                ; preds = %2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 2.000000e-01) #4
  br label %9

9:                                                ; preds = %7, %2
  %10 = phi i32 [ %8, %7 ], [ %5, %2 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  %12 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %13 = add nsw i32 %12, %11
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %vsfp.c = icmp eq i32 %0, 0   ; bd vsfp: a BRANCH-ONLY read keeps this parameter LIVE (header)
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @hq(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) local_unnamed_addr #2 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @g2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = mul nsw i32 %1, %0
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef double @hf(double noundef %0, double noundef %1) local_unnamed_addr #2 {
  %3 = fadd double %1, 1.000000e+00
  ret double %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef double @hfq(double noundef %0, double noundef %1) local_unnamed_addr #2 {
  %3 = tail call double @llvm.fmuladd.f64(double %0, double %1, double 5.000000e-01)
  ret double %3
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483646, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = mul nsw i32 %0, 7
  %3 = add nsw i32 %2, 2
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @ext_f2(i32 noundef %0) local_unnamed_addr #2 {
  %2 = mul nsw i32 %0, 5
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @ext_h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
