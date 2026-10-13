; control_classical_call_arm_twin_accept_false_returned.ll — ACCEPT (batch 053, bd
; dm7f.25; was control_classical_call_arm_reject_false_returned.ll, a DECLINE since bd
; test_C_libtooling-bwfp R11 round 4 F1).
; `@g` claims `returned` on %x but returns %x + 4. LLVM's known bits trust `returned`
; (`CallBase::getReturnedArgOperand`), so `@f`'s `noundef range(i32 0, 4)` was
; "proven" from `and %k, 3` forwarded through `@g`. Real: f(k) = (k & 3) + 4, out of
; range, so `ret noundef poison`: immediate UB on basis states the guard `q > 3`
; excluded (all of them, Ry(0)). Measured on the round-4 snapshot (sha 86f1d42c):
; `call i32 @f(i32 %k)` hoisted into `entry`, opt rc=0. The Direct route still
; refuses it: `returned` is admitted only when every `ret` returns that parameter.
; What changed (batch 053, dm7f.25): `returned` is one of the parameter attributes a
; twin DROPS (with `range`, `nofpclass`), so `@f`'s twin redirects the call to `@g`'s
; twin, which no longer claims it, and treats its result as possibly poison; `@f`'s
; twin drops its own `range` and freezes its `ret`. The original `@f` (whose `ret
; noundef poison` was the miscompile) is never called.
; ANALYTIC (R2): the source's `f(k)` is UB on EVERY state it runs (its `noundef`
; return is always out of range), so there is no UB-free state to be exact on; the
; twins are total (no division, no loop, `ret` frozen) and return `(k & 3) + 4`,
; never merged here (the guard has zero amplitude) and a refinement of UB otherwise.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @example(
; CHECK:       %r = call i32 @__cq_specsafe_f(i32 %k)
; CHECK-NOT:   call i32 @f(
; CHECK:       define internal i32 @__cq_specsafe_g(i32 %x) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TG:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %y = add i32 %x, 4
; CHECK-NEXT:    %y.fr = freeze i32 %y
; CHECK-NEXT:    ret i32 %y.fr
; CHECK:       define internal noundef i32 @__cq_specsafe_f(i32 noundef %k) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TF:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %a = and i32 %k, 3
; CHECK-NEXT:    %r = call i32 @__cq_specsafe_g(i32 %a)
; CHECK-NEXT:    %r.fr = freeze i32 %r
; CHECK-NEXT:    ret i32 %r.fr
; CHECK-DAG:   ![[TG]] = !{ptr @g}
; CHECK-DAG:   ![[TF]] = !{ptr @f}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal i32 @g(i32 returned %x) #0 {
entry:
  %y = add i32 %x, 4
  ret i32 %y
}
define internal noundef range(i32 0, 4) i32 @f(i32 noundef %k) #0 {
entry:
  %a = and i32 %k, 3
  %r = call i32 @g(i32 %a)
  ret i32 %r
}
define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
