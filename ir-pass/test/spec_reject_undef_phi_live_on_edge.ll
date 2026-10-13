; spec_reject_undef_phi_live_on_edge.ll — DECLINE (bd p3kd.8, the decline cell of
; the phi-edge refinement).
;
; The same uninitialized-`c` program as spec_accept_undef_phi_dead_on_edge.ll, but
; `k` is 1 (not 0) on the path that leaves `c` uninitialized, so that path RETURNS
; `k + c`: the result denotes no value there. clang -O1 exploits it and folds the
; whole tail to `phi [ %8, %3 ], [ undef, %1 ]; ret`. The phi-edge evaluation
; (UndefReach.h) finds the undef reaching the `ret` on the edge %1 -> %9 and the
; bd 3p2a decline stands: never replace a reachable undef return with zero (bd
; p3kd.8 notes, the Bennett.jl yd4f GATE 2 distinction).
;
; C source (clang -O1):
;   __attribute__((noinline)) int live(int a) {
;     int c, k;
;     if (a > 5) { k = a - 5; c = ((a * 7 + 3) * a - 11) * a + 5; }
;     else       { k = 1; }
;     if (k == 0) return a + 1;
;     return k + c;
;   }
;   int ex_live(int u0) { int q = u0; cq_theta(&q, 0.5); return cq_measure(live(q)); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee return value denotes no value (undef/poison)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define range(i32 -2147483647, -2147483648) i32 @live(i32 noundef %0) {
  %2 = icmp sgt i32 %0, 5
  br i1 %2, label %3, label %9

3:
  %4 = mul nuw nsw i32 %0, 7
  %5 = add nuw nsw i32 %4, 3
  %6 = mul nuw nsw i32 %5, %0
  %7 = add nsw i32 %6, -10
  %8 = mul i32 %7, %0
  br label %9

9:
  %10 = phi i32 [ %8, %3 ], [ undef, %1 ]
  ret i32 %10
}

define i32 @ex_live(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = tail call i32 @live(i32 noundef %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3)
  ret i32 %4
}
