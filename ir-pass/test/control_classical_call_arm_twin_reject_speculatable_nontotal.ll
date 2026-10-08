; control_classical_call_arm_twin_reject_speculatable_nontotal.ll — DECLINE (bd dm7f.21, R11 round 1 residual H2).
; A user function carrying a FALSE `speculatable` skips the strict body walk (the
; 6.5 purity gate trusts `isSafeToSpeculativelyExecute`). `@F` passes `x + 1`
; (`nsw`) to `@K`'s `noundef` parameter, so it needs a twin; but a twin freezes that
; argument, and `freeze(poison)` may be 0, which `@K` divides by: a trap the
; `speculatable` promise never covered (it says nothing about values a freeze
; invents). Round 1 hoisted `@__cq_specsafe_F` here (snapshot 7ba76a01). The twin
; route now requires the strict walk (`isSpeculatableTotalCallee`), which refuses
; `@K`'s non-constant divisor, so the hoist declines loudly. Hand IR: clang never
; emits `speculatable` on a user function.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error: {{.*}}in function example i32 (i32, i32): cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @K(i32 noundef %y) #0 {
entry:
  %d = sdiv i32 100, %y
  ret i32 %d
}

define internal i32 @F(i32 noundef %x) #1 {
entry:
  %a = add nsw i32 %x, 1
  %r = call i32 @K(i32 noundef %a)
  ret i32 %r
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @F(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) speculatable }
