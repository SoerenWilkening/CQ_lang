; control_classical_call_arm_twin_accept_redirect_facts.ll — ACCEPT (bd dm7f.21).
; A twin must not keep facts its own redirect falsified. `@G` claims
; `noundef range(i32 0, 10)` but returns its argument, so `G(50)` is immediate UB and
; `@F`'s twin calls `@G`'s twin, which freezes the `ret` and DROPS the range. In `@F`,
; `add nuw i32 %r, 5` cannot wrap if `%r` lies in [0, 10), and `computeKnownBits`
; reads exactly that range through the call to `@G`. In the twin that call returns
; `freeze(x)`, any value, so the `nuw` can fail there and the poison would reach
; `@h`'s `noundef` parameter. The plan therefore keeps a redirected (or stripped)
; call's result POSSIBLY POISON downstream, and `%y` is frozen before `@h`.
; (Hand-written IR: the shape needs a false `range`, which clang does not emit.)
; ANALYTIC (R2): on a UB-free execution of the source's `F(%k)`, `%k` is in [0, 10),
; every freeze is the identity and the twin returns `F(%k)`; otherwise the source's
; own call is UB under a true guard and the value is never merged under a false one.
; Mutant this kills: `Pois = false` for a redirected call (PoisonFlow.cpp).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(
; CHECK:       call i32 @__cq_specsafe_F(i32 %k)
; CHECK:       define internal noundef i32 @__cq_specsafe_G(i32 %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %x.fr = freeze i32 %x
; CHECK-NEXT:    ret i32 %x.fr
; CHECK:       define internal i32 @__cq_specsafe_F(i32 noundef %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %r = call i32 @__cq_specsafe_G(i32 %x)
; CHECK-NEXT:    %y = add nuw i32 %r, 5
; CHECK-NEXT:    %y.fr = freeze i32 %y
; CHECK-NEXT:    %z = call i32 @h(i32 noundef %y.fr)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal noundef range(i32 0, 10) i32 @G(i32 %x) #0 {
entry:
  ret i32 %x
}

define internal i32 @h(i32 noundef %v) #0 {
entry:
  %w = xor i32 %v, 3
  ret i32 %w
}

define internal i32 @F(i32 noundef %x) #0 {
entry:
  %r = call i32 @G(i32 %x)
  %y = add nuw i32 %r, 5
  %z = call i32 @h(i32 noundef %y)
  ret i32 %z
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
