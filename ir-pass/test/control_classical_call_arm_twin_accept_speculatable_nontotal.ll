; control_classical_call_arm_twin_accept_speculatable_nontotal.ll — ACCEPT (batch 053,
; bd dm7f.30; was control_classical_call_arm_twin_reject_speculatable_nontotal.ll, a
; DECLINE since bd dm7f.21 R11 round 1 residual H2).
; A user function carrying a FALSE `speculatable` passes the Direct route's
; totality disjunct; `@F` passes `x + 1` (`nsw`) to `@K`'s `noundef` parameter, so it
; needs a twin. The H2 hole: a twin of `@F` that freezes that argument and still
; calls the ORIGINAL `@K` hands it `freeze(poison)`, which may be 0, and `@K`
; divides by it: a trap the `speculatable` promise never covered (round 1 hoisted
; exactly that, snapshot 7ba76a01). Round 1's fix required the strict walk for
; every twinned body, so this declined.
; Batch 053 restores the invariant instead: a twin never calls an original whose
; body is not total by itself. The totality walk (TwinTotality.h) ignores
; `speculatable` on a body and finds `@K`'s possibly-zero divisor, so `@F`'s twin
; REDIRECTS the call to `@K`'s twin, which guards the divisor.
; ANALYTIC (R2): on a basis state where the source runs `F(k)` without UB, `k + 1`
; is defined and non-zero, so the freezes are the identity and the guard selects it;
; `@K`'s twin returns `100 / (k + 1)` (for `k + 1 == -1`, `0 - 100`, the same value)
; and `@F`'s twin returns `F(k)`. Elsewhere both are total and the value is never
; merged. Hand IR: clang never emits `speculatable` on a user function.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @example(
; CHECK:       %r = call i32 @__cq_specsafe_F(i32 %k)
; CHECK-NOT:   call i32 @F(
; CHECK:       define internal i32 @__cq_specsafe_K(i32 noundef %y) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TK:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %cq.div.fr = freeze i32 %y
; CHECK-NEXT:    %cq.div.zero = icmp eq i32 %cq.div.fr, 0
; CHECK-NEXT:    %cq.div.m1 = icmp eq i32 %cq.div.fr, -1
; CHECK-NEXT:    %cq.div.bad = or i1 %cq.div.zero, %cq.div.m1
; CHECK-NEXT:    %cq.div.safe = select i1 %cq.div.bad, i32 1, i32 %cq.div.fr
; CHECK-NEXT:    %d = sdiv i32 100, %cq.div.safe
; CHECK-NEXT:    %cq.div.res = select i1 %cq.div.m1, i32 -100, i32 %d
; CHECK-NEXT:    %cq.div.res.fr = freeze i32 %cq.div.res
; CHECK-NEXT:    ret i32 %cq.div.res.fr
; CHECK:       define internal i32 @__cq_specsafe_F(i32 noundef %x) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TF:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %a = add nsw i32 %x, 1
; CHECK-NEXT:    %a.fr = freeze i32 %a
; CHECK-NEXT:    %r = call i32 @__cq_specsafe_K(i32 noundef %a.fr)
; CHECK-NEXT:    %r.fr = freeze i32 %r
; CHECK-NEXT:    ret i32 %r.fr
; CHECK-DAG:   ![[TK]] = !{ptr @K}
; CHECK-DAG:   ![[TF]] = !{ptr @F}

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
