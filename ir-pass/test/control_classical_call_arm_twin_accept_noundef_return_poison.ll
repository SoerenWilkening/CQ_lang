; control_classical_call_arm_twin_accept_noundef_return_poison.ll — ACCEPT (bd dm7f.21).
; FLIPPED from control_classical_call_arm_reject_noundef_return_poison.ll (bd bwfp, a
; DECLINE) by the owner ruling of 2026-10-08 (option a).
; control_classical_call_arm_accept_poisonselect_callee.ll plus ONE attribute: `@pf`'s
; RETURN is `noundef`. For `%k >= 32` the body computes `ret noundef poison`:
; immediate UB, which hoisting `@pf` itself (e0af16ed did, opt rc=0) would execute on
; basis states the guard `q > 3` excluded. The hoist now calls `@pf`'s
; speculation-safe twin, whose `ret` operand is frozen.
; ANALYTIC (R2): for `%k < 32` the `shl` is defined, so `%v` is and the `freeze` is
; the identity: the twin computes `pf(%k)`; for `%k >= 32` under a true guard the
; source executes `ret noundef poison`, UB; under a false guard the twin's value is
; never merged. Decline neighbour, still refused: the branch-on-poison body
; control_classical_call_arm_reject_poisonbr_callee.ll (the strict walk refuses a
; conditional branch before the twin is asked).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_specsafe_pf(i32 %k)
; CHECK:       call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       define internal noundef i32 @__cq_specsafe_pf(i32 noundef %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %s = shl i32 1, %x
; CHECK-NEXT:    %c = icmp eq i32 %s, 7
; CHECK-NEXT:    %v = select i1 %c, i32 1, i32 2
; CHECK-NEXT:    %v.fr = freeze i32 %v
; CHECK-NEXT:    ret i32 %v.fr

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal noundef i32 @pf(i32 noundef %x) #0 {
entry:
  %s = shl i32 1, %x
  %c = icmp eq i32 %s, 7
  %v = select i1 %c, i32 1, i32 2
  ret i32 %v
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
