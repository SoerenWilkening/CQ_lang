; taint_accept_spec_classical_return_round2.ll — ACCEPT (bd test_C_libtooling-9bhg;
; Rule-13 r2B_9bhg F-9D-2's suggested pin `R6`, re-spelled for bd vsfp).
;
; A provisional return whose taint arises only in ROUND 2.
; - `y` is a 6.5 classical-call-arm `%out` (`if (q > 5) y = ext_f(7)`) and is tainted
;   only by the round-2 reseed.
; - So `t = h(y, m)` becomes a Phase-6 site only in round 2, and `f`'s return
;   (`t + cq_measure(y) + cq_measure(q)`) is PROVISIONAL only in the round-2 call of
;   `propagateWorklist`.
; - `h`'s clone returns the classical `k + 1`, so `f` returns a classical integer and
;   `main` branches on it classically.
; What it pins: that the round-2 crossing decision also DEFERS. Before this file, mutant
; M1 (the drain never defers) was killed only by round-1 shapes (r2B F-9D-2).
; Measured at the bd vsfp merge (2026-09-27):
; - `main` c1136be2 DECLINES this module with the 3jru string.
; - Its trace equals the hand-inlined twin's (`t = m + 1`) for arguments 5 7, 2 9, 1 1
;   and 4 4.
; - Stage 2b STRICT reports 0 violations and 0 unproven on both (TRACK_9BHG §12).
;
; RE-SPELLED for bd vsfp, as the other 9bhg fixtures are. r2B's `h` ignored `a`, so
; `dropDeadCallArguments` removed the argument before propagation and the program was
; the twin (measured: `CQ_DEADARG_DBG: drop arg 0 of @h in @f`). The BRANCH-ONLY read
; now in `@h` (`%vsfp.c` feeding an EMPTY diamond) keeps the parameter live. The
; `env CQ_DEADARG_DBG=1` and `--implicit-check-not=CQ_DEADARG_DBG` pin that the drop
; does not fire. From C at -O1 this spelling is IR-ONLY: the library TU deletes an empty
; branch. RETIREMENT TRIGGER: a liveness predicate with control dependence makes the
; read dead again; re-derive the subject then (L8).
;
; Library TU (plain C, no CQ.h) — review_r2B_9bhg/probes/src/lib.c, of which this uses:
;   int h(int a, int k) { return k + 1; }        // then hand-edited as above
;   int ext_f(int a) { return a * 7 + 2; }
;
; Caller TU (clang -O1 -include CQ.h):
;   int h(int a, int k); int ext_f(int a);
;   __attribute__((noinline)) int f(int m) {
;     int q = cq_theta(m, .5);
;     int y = 0;
;     if (q > 5) y = ext_f(7);
;     int t = h(y, m);
;     return t + cq_measure(y) + cq_measure(q);
;   }
;   int main(int c, char **v) { int r = f(c); if (r > 7) return 1; return r; }
;
; Regenerate: clang -O1 -emit-llvm -S each TU as above, llvm-link -S caller.ll lib.ll,
; then add the branch-only read to `@h`.
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not=CQ_DEADARG_DBG
; CHECK-NOT: error
; CHECK-LABEL: define i32 @f(
; CHECK: %out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %0)
; CHECK-NEXT: %m = call i32 @cqrt_measure_i32(i32 %out)
; CHECK-NEXT: [[A:%[0-9]+]] = add nsw i32 %m, [[T]]
; CHECK-NEXT: %m2 = call i32 @cqrt_measure_i32(i32 %h)
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: cq{{rt|_template}}_
; CHECK: [[R:%[0-9]+]] = tail call i32 @f(i32 noundef %0)
; CHECK-NEXT: icmp sgt i32 [[R]], 7
; CHECK-LABEL: define internal i32 @__cq_q_h_01(
; CHECK: add nsw i32 %1, 1

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #5
  %3 = icmp sgt i32 %2, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @ext_f(i32 noundef 7) #5
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ 0, %1 ]
  %8 = tail call i32 @h(i32 noundef %7, i32 noundef %0) #5
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %10 = add nsw i32 %9, %8
  %11 = tail call i32 @cq_measure_si32(i32 noundef %2) #5
  %12 = add nsw i32 %10, %11
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483648, 8) i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #2 {
  %3 = tail call i32 @f(i32 noundef %0)
  %4 = icmp sgt i32 %3, 7
  %5 = select i1 %4, i32 1, i32 %3
  ret i32 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %vsfp.c = icmp eq i32 %0, 0   ; bd vsfp: a BRANCH-ONLY read keeps this parameter LIVE (header)
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @hq(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @g2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = mul nsw i32 %1, %0
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef double @hf(double noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = fadd double %1, 1.000000e+00
  ret double %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef double @hfq(double noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = tail call double @llvm.fmuladd.f64(double %0, double %1, double 5.000000e-01)
  ret double %3
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #4

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483646, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 7
  %3 = add nsw i32 %2, 2
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @ext_f2(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 5
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @ext_h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
