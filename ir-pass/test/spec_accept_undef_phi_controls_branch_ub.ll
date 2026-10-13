; spec_accept_undef_phi_controls_branch_ub.ll — ACCEPT, unchanged by bd p3kd.8 (a
; regression pin: the phi-edge refinement must not TIGHTEN the bd 3p2a fence).
;
; The undef incoming never reaches the returned value as DATA: both arms compute
; from `a` alone. On the edge %entry -> %join it only decides WHICH arm runs
; (`br i1 %t`, `%t = icmp sgt i32 %c, 3`). LangRef: a `br`/`switch` on an undef or
; poison condition is immediate undefined behaviour, so no defined execution
; branches on it, and the returned value never denotes undef on a defined
; execution. The bd 3p2a cone walk never followed a branch condition, so `main`
; fc6ee653 already lifts this (PredMux freezes the incoming to zero and the `lo`
; arm runs on a <= 5); the phi-edge evaluation (UndefReach.h) explores BOTH
; successors of such a branch and keeps that verdict. Measured on fc6ee653 before
; the change: `opt` exit 0, `@__cq_q_branchy_1` built.
;
; Hand-written IR: clang -O1 resolves this UB itself (it folds the branch on the
; uninitialized `c` and keeps one arm), so the C source below never reaches the
; pass in this shape.
;   __attribute__((noinline)) int branchy(int a) {
;     int c, r;
;     if (a > 5) c = a * 7;
;     if (c > 3) r = a * 9; else r = a * 3;
;     return r;
;   }
;   int example(int u0) { int q = u0; cq_theta(&q, 0.5); return cq_measure(branchy(q)); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @branchy(i32 noundef %a) {
entry:
  %c0 = icmp sgt i32 %a, 5
  br i1 %c0, label %init, label %join

init:
  %m = mul nsw i32 %a, 7
  br label %join

join:
  %c = phi i32 [ %m, %init ], [ undef, %entry ]
  %t = icmp sgt i32 %c, 3
  br i1 %t, label %hi, label %lo

hi:
  %h1 = mul nsw i32 %a, 9
  br label %out

lo:
  %l1 = mul nsw i32 %a, 3
  br label %out

out:
  %r = phi i32 [ %h1, %hi ], [ %l1, %lo ]
  ret i32 %r
}

define i32 @example(i32 noundef %u0) {
  %q = tail call i32 @cq_theta_si32(i32 noundef %u0, double noundef 5.000000e-01)
  %r = tail call i32 @branchy(i32 noundef %q)
  %m = tail call i32 @cq_measure_si32(i32 noundef %r)
  ret i32 %m
}

; CHECK-LABEL: define i32 @example(
; CHECK:     call i32 @__cq_q_branchy_1(
; CHECK-LABEL: define internal i32 @__cq_q_branchy_1(
; CHECK-NOT: {{ (undef|poison)[],) ]}}
; CHECK:     ret i32
