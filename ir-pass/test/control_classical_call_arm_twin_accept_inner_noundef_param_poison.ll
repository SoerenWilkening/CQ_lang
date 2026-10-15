; control_classical_call_arm_twin_accept_inner_noundef_param_poison.ll — ACCEPT (bd dm7f.21).
; FLIPPED from control_classical_call_arm_reject_inner_noundef_param_poison.ll (bd
; bwfp, a DECLINE) by the owner ruling of 2026-10-08 (option a).
; The UB sink is one call deeper. `@pf` passes `x + 1` (`nsw`: poison on overflow) to
; `@g`'s `noundef` parameter, the C shape `int pf(int x) { return g(x + 1); }`. On a
; basis state the guard excluded, the hoisted `@pf(%k)` with `%k = INT_MAX` would pass
; poison to a `noundef` parameter: immediate UB. bwfp declined. Now the hoist calls
; `@pf`'s speculation-safe twin, whose `@g` argument is frozen.
; ANALYTIC (R2): for `%k != INT_MAX` the add does not overflow, `freeze` is the
; identity and the twin computes `pf(%k)`; for `%k = INT_MAX` under a true guard the
; source itself executes `g(poison)`, UB, with no behaviour to preserve; under a false
; guard the twin's value is never merged (the controlled copy is the identity where
; the flag is 0). `@g`'s result is defined for a defined argument (`mul` without
; flags), so the twin's `ret` needs no freeze. Neighbour: a `range` on the same
; parameter, which no freeze satisfies, is dropped by redirecting to `@g`'s twin
; since batch 053 (control_classical_call_arm_twin_accept_inner_param_range.ll). Contrast
; control_classical_call_arm_accept_inner_call_nsw.ll, which needs no twin at all.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_specsafe_pf(i32 %k)
; CHECK:       call void @cqrt_xorc_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[R]])
; CHECK:       define internal i32 @__cq_specsafe_pf(i32 noundef %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %a = add nsw i32 %x, 1
; CHECK-NEXT:    %a.fr = freeze i32 %a
; CHECK-NEXT:    %r = call i32 @g(i32 noundef %a.fr)
; CHECK-NEXT:    ret i32 %r

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @g(i32 noundef %y) #0 {
entry:
  %m = mul i32 %y, 3
  ret i32 %m
}

define internal i32 @pf(i32 noundef %x) #0 {
entry:
  %a = add nsw i32 %x, 1
  %r = call i32 @g(i32 noundef %a)
  ret i32 %r
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pf(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
