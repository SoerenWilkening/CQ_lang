; control_classical_call_arm_twin_reject_sdiv_callee.ll — DECLINE (bd dm7f.21).
; Immediate UB that is NOT poison, which no `freeze` can discharge. IR: clang 19 -O1
; of exactly
;   __attribute__((noinline)) int g(int v){ return v ^ 5; }
;   __attribute__((noinline)) int h(int x){ return g(100 / x); }
;   int ex(int k){ int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = h(k); return cq_measure(y); }
; target attributes trimmed (R8). `sdiv i32 100, %0` traps for k = 0 (and is UB for
; INT_MIN / -1 shapes): hoisting `@h` out of the zero-amplitude guard would execute
; it on every basis state (bd wve8's SIGFPE). The speculation-safe twin freezes only
; poison sinks; a frozen divisor may still be zero, so the existing totality proof
; (`isSpeculatableTotalCallee`: a divisor must be a non-zero constant) keeps
; refusing the body before the twin is asked. Physics does not forbid the program;
; a guarded-divisor lowering (`k == 0 ? 1 : k` on the speculated path) is the gap
; this row pins until it lands.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error: {{.*}}in function ex i32 (i32): cq controlled lowering: control flow under quantum control

define noundef i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, 5
  ret i32 %2
}

define noundef i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = sdiv i32 100, %0
  %3 = tail call i32 @g(i32 noundef %2)
  ret i32 %3
}

define i32 @ex(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #2
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @h(i32 noundef %0)
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
