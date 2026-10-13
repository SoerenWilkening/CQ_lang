; control_classical_call_arm_twin_accept_root_param_range.ll — ACCEPT (batch 053, bd
; dm7f.25; was control_classical_call_arm_reject_root_param_range.ll, a DECLINE since
; bd bwfp review round 2 F2).
; The hoisted call's own parameter is `noundef range(i32 1, 10)`. The argument `%k`
; is DEFINED, so no freeze applies, but on a basis state the guard excluded `%k` may
; be 50: a defined value outside the range is poison, and poison in a `noundef`
; parameter is immediate UB the source never executed. So the Direct route (which
; calls `@pr` itself) stays refused, and that refusal is still correct. dm7f.25: the
; Twin route calls `@pr`'s twin, whose parameter DROPS the `range` (as does the root
; call site): a defined 50 is then just 50.
; ANALYTIC (R2): on a basis state where the source runs `pr(k)` without UB, k lies in
; `[1, 10)` (a violation is UB in the source), so the dropped `range` held and the
; twin returns `k + 1`; elsewhere it returns some defined value the controlled copy
; never merges. The `ret` is frozen because the twin plans with every parameter
; possibly poison.
; Still refused (the claim's argument clause, outside this change): the same
; parameter fed a POISON-CAPABLE argument, whose freeze `freezeDischargesHoistedArg`
; does not license past a `range` (control_classical_call_arm_reject_frozen_arg_range.ll,
; ..._reject_frozen_arg_callee_range.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @ex_range(
; CHECK:       %r = call i32 @__cq_specsafe_pr(i32 %k)
; CHECK-NOT:   call i32 @pr(
; CHECK:       define internal i32 @__cq_specsafe_pr(i32 noundef %x) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %v = add i32 %x, 1
; CHECK-NEXT:    %v.fr = freeze i32 %v
; CHECK-NEXT:    ret i32 %v.fr
; CHECK:       ![[TW]] = !{ptr @pr}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @pr(i32 noundef range(i32 1, 10) %x) #0 {
entry:
  %v = add i32 %x, 1
  ret i32 %v
}
define i32 @ex_range(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pr(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
