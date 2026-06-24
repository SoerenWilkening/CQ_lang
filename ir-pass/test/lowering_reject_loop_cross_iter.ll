; lowering_reject_loop_cross_iter.ll — DECLINE (Phase 7.3 Inc 1, 799w.1; PRD §2.7,
; X1): a tainted value carried across iterations on a DIRTY (non-in-place) rail
;     double q = cq_theta(seed, 0.5);
;     double acc = 0.0;
;     for (int i = 0; i < n; i++) acc = acc + q;   // fresh value-op rail each iter
;     return cq_measure(acc);
; is NOT sound-rolled: each iteration threads a FRESH `fadd` rail through the
; header phi; the prior iteration's rail is dead but loop-carried, recoverable
; only by post-loop reversal of a K-deep chain. The physically-correct lowering is
; the static-K unroll fallback (unroll K bodies, recover each iteration's rail),
; DEFERRED to a filed follow-on (owner demoted unrolling to optional; the SE/
; UnrollLoop dlopen smoke test is its first gate). Until then: LOUD decline.
;
; Verified against real `clang -O1` output (Rule 11): the loop-carried header phi
; `%acch = phi double [0.0, entry], [%accn, loop]` has a latch incoming `%accn =
; fadd double %q0, %acch` that does NOT peel (through in-place gates) back to the
; header phi — it bottoms at a tainted `fadd` value-op rail. `tryCaseA`'s
; self-cycle peel sees the dirty latch and declines (Risk 2 — never a silent
; collapse of a loop-variant handle). LoopLowering OWNS the `Msg`; this CHECK
; mirrors it CHARACTER-FOR-CHARACTER (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried tainted value crosses iterations

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @crossiter(double %seed, i32 %n) {
entry:
  %q0 = call double @cq_theta_f64(double %seed, double 5.000000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

exit:                                             ; preds = %entry, %loop
  %accx = phi double [ 0.000000e+00, %entry ], [ %accn, %loop ]
  %m = call double @cq_measure_f64(double %accx)
  ret double %m

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %acch = phi double [ 0.000000e+00, %entry ], [ %accn, %loop ] ; cross-iter dirty rail
  %accn = fadd double %q0, %acch                  ; fresh value-op rail (NOT in-place)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop
}
