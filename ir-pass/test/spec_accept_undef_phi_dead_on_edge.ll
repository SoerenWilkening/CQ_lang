; spec_accept_undef_phi_dead_on_edge.ll — ACCEPT (bd p3kd.8, the log1p shape).
;
; openlibm log1p/log1pf (src/s_log1p.c, src/s_log1pf.c) leave the correction term
; `c` uninitialized on the path where `k == 0`, and read it only where `k != 0`.
; clang -O1 keeps that as a merge phi with an `undef` incoming
; (`%12 = phi [ %10, %3 ], [ undef, %1 ]` below) beside a phi that is the constant
; 0 on the same edge. The bd 3p2a fence asked a SYNTACTIC question ("is an undef
; anywhere in the return cone?") and declined `callee return value denotes no value
; (undef/poison)`, so acosh/asinh/atanh/log1p (f32, f64) did not lift.
;
; The semantic question (UndefReach.h): on every execution through the undef's
; edge, does the RETURNED value depend on it? On the edge %1 -> %11 the sibling phi
; `%13` is 0, so `%14 = icmp eq i32 0, 0` is true and the return select takes
; `%15 = a + 1`, which never reads `%12`. The undef is unobservable, so the body
; computes a function of its argument and lifts; PredMux's `convertPhis` then
; freezes the incoming to zero (a legal refinement of `undef`, and a deterministic
; one, so the clone and any uncompute twin compute the same return). The return
; is NOT replaced by zero: on the k != 0 edge `%12` is the real `%10`.
;
; C source (clang -O1):
;   __attribute__((noinline)) int helper(int a) {
;     int c, k;
;     if (a > 5) { k = a - 5; c = ((a * 7 + 3) * a - 11) * a + 5; }
;     else       { k = 0; }
;     if (k == 0) return a + 1;
;     return k + c;
;   }
;   int example(int u0) { int q = u0; cq_theta(&q, 0.5); return cq_measure(helper(q)); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define range(i32 -2147483647, -2147483648) i32 @helper(i32 noundef %0) {
  %2 = icmp sgt i32 %0, 5
  br i1 %2, label %3, label %11

3:
  %4 = add nsw i32 %0, -5
  %5 = mul nuw nsw i32 %0, 7
  %6 = add nuw nsw i32 %5, 3
  %7 = mul nuw nsw i32 %6, %0
  %8 = add nsw i32 %7, -11
  %9 = mul nsw i32 %8, %0
  %10 = add nuw nsw i32 %9, 5
  br label %11

11:
  %12 = phi i32 [ %10, %3 ], [ undef, %1 ]
  %13 = phi i32 [ %4, %3 ], [ 0, %1 ]
  %14 = icmp eq i32 %13, 0
  %15 = add nsw i32 %0, 1
  %16 = add nsw i32 %13, %12
  %17 = select i1 %14, i32 %15, i32 %16
  ret i32 %17
}

define i32 @example(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = tail call i32 @helper(i32 noundef %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3)
  ret i32 %4
}

; CHECK-LABEL: define i32 @example(
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = {{(tail )?}}call i32 @__cq_q_helper_1(i32 {{(noundef )?}}%[[H]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; The clone is one straight-line block with no undef/poison literal left in it
; (PredMux froze the incoming to 0: a `cqrt_alloc_i32(i32 0)` copy source): the
; guarded product chain is speculated, the merge is a controlled-copy mux, and the
; result is copied out and the forward reversed. The CHECK-NOT pattern needs a
; leading space so the `noundef` parameter attribute does not match it.
; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32
; CHECK-NOT: {{ (undef|poison)[],) ]}}
; CHECK:     call void @cqrt_copy_i32(
; CHECK-NOT: {{ (undef|poison)[],) ]}}
; CHECK:     ret i32
