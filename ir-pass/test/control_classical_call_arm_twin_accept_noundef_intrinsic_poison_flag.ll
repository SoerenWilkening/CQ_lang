; control_classical_call_arm_twin_accept_noundef_intrinsic_poison_flag.ll — ACCEPT (bd dm7f.21).
; FLIPPED from control_classical_call_arm_reject_noundef_intrinsic_poison_flag.ll (bd
; bwfp R11 round 5 F1, a DECLINE) by the owner ruling of 2026-10-08 (option a).
; `ctlz(%k, is_zero_poison=true)` is poison for `%k == 0`, and the call site is
; `noundef`, so `f(0)` is immediate UB AT the intrinsic call. LLVM 19's
; `canCreateUndefOrPoison` answers "no poison" for a `noundef` ctlz/cttz/abs whatever
; its flag; `createsPoison` (FlagProof.cpp) asks `curatedIntrinsicCanBePoison` and
; finds no operand fact proving `%k != 0`. The UB is the call site's own `noundef`, so
; no `freeze` of an operand reaches it: the speculation-safe twin of `@f` DROPS that
; call site's `noundef` and its value-constraining `range` (dropping a promise only
; removes UB), tracks the result as possibly poison, and freezes `@f`'s `ret`.
; ANALYTIC (R2): for `%k != 0` the ctlz is defined, the dropped attributes held, the
; `freeze` is the identity and the twin computes `f(%k)`; for `%k = 0` under a true
; guard the source's own call is UB; under a false guard the twin's arbitrary defined
; value is never merged. Decline neighbour, still refused: a CYCLIC body whose loop
; has no trip bound to carry, control_classical_call_arm_twin_reject_unbounded_loop.ll
; (a bounded one twins since batch 053: ..._twin_accept_cyclic_speculatable.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_specsafe_f(i32 noundef %k)
; CHECK:       call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       define internal i32 @__cq_specsafe_f(i32 noundef %k)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %a = call i32 @llvm.ctlz.i32(i32 %k, i1 true)
; CHECK-NEXT:    %r = xor i32 %a, 3
; CHECK-NEXT:    %r.fr = freeze i32 %r
; CHECK-NEXT:    ret i32 %r.fr

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.abs.i32(i32, i1 immarg)
declare i32 @llvm.ctlz.i32(i32, i1 immarg)
declare i8 @llvm.ctlz.i8(i8, i1 immarg)
define internal i32 @g(i32 noundef %v) #0 {
entry:
  %r = xor i32 %v, 5
  ret i32 %r
}
define internal i32 @f(i32 noundef %k) #0 {
entry:
  %a = call noundef range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %k, i1 true)
  %r = xor i32 %a, 3
  ret i32 %r
}
define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 noundef %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
