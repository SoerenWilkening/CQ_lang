; control_classical_call_arm_twin_accept_divrem_switch.ll — ACCEPT (batch 053, bd
; dm7f.29 + dm7f.30). Hand IR: a helper that SWITCHES on a classical selector and
; divides by a classical divisor on two of its arms, as in
;   int dv(int a, int b, int s) { switch (s) { case 0: return (unsigned)a / (unsigned)b;
;                                              case 1: return a % b; default: return (unsigned)a % 7u; } }
; (written as a `switch` by hand to pin the three shapes in one body, whatever clang
; makes of that C). The strict walk refuses the `switch` and the register divisors, so the
; Direct route is closed. THE TWIN freezes the switch condition (a sink), guards
; `udiv` by `select(b == 0, 1, freeze b)` and `srem` by
; `select((b == 0) | (b == -1), 1, freeze b)` with the `b == -1` remainder rebuilt as
; 0, leaves the constant `urem ..., 7` alone (total as written), and freezes the
; `ret` (a guarded quotient of a frozen-away divisor is not the source's value off
; its domain, and `%a` may be poison).
; ANALYTIC (R2): on a basis state where the source runs `dv(a, b, s)` without UB, s
; is defined (a switch on poison is UB) and on the arm taken b is defined and non-zero
; (and `a % -1 == 0` for every a but INT_MIN, where the source is UB), so every guard
; selects b and every freeze but the `ret`'s is the identity: the twin returns
; `dv(a, b, s)`. Elsewhere it is total and its value is never merged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @example(
; CHECK:       %r = call i32 @__cq_specsafe_dv(i32 %a, i32 %b, i32 %s)
; CHECK-NOT:   call i32 @dv(
; CHECK:       define internal i32 @__cq_specsafe_dv(i32 noundef %a, i32 noundef %b, i32 noundef %s) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %s.fr = freeze i32 %s
; CHECK-NEXT:    switch i32 %s.fr, label %d [
; CHECK:       u:
; CHECK-NEXT:    %[[UF:cq.div.fr[0-9]*]] = freeze i32 %b
; CHECK-NEXT:    %[[UZ:cq.div.zero[0-9]*]] = icmp eq i32 %[[UF]], 0
; CHECK-NEXT:    %[[US:cq.div.safe[0-9]*]] = select i1 %[[UZ]], i32 1, i32 %[[UF]]
; CHECK-NEXT:    %q = udiv i32 %a, %[[US]]
; CHECK-NEXT:    br label %m
; CHECK:       r:
; CHECK-NEXT:    %[[RF:cq.div.fr[0-9]*]] = freeze i32 %b
; CHECK-NEXT:    %[[RZ:cq.div.zero[0-9]*]] = icmp eq i32 %[[RF]], 0
; CHECK-NEXT:    %[[RM:cq.div.m1[0-9]*]] = icmp eq i32 %[[RF]], -1
; CHECK-NEXT:    %[[RB:cq.div.bad[0-9]*]] = or i1 %[[RZ]], %[[RM]]
; CHECK-NEXT:    %[[RS:cq.div.safe[0-9]*]] = select i1 %[[RB]], i32 1, i32 %[[RF]]
; CHECK-NEXT:    %t = srem i32 %a, %[[RS]]
; CHECK-NEXT:    %[[RR:cq.div.res[0-9]*]] = select i1 %[[RM]], i32 0, i32 %t
; CHECK-NEXT:    br label %m
; CHECK:       d:
; CHECK-NEXT:    %w = urem i32 %a, 7
; CHECK-NEXT:    br label %m
; CHECK:       m:
; CHECK-NEXT:    %v = phi i32 [ %q, %u ], [ %[[RR]], %r ], [ %w, %d ]
; CHECK-NEXT:    %v.fr = freeze i32 %v
; CHECK-NEXT:    ret i32 %v.fr
; CHECK:       ![[TW]] = !{ptr @dv}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @dv(i32 noundef %a, i32 noundef %b, i32 noundef %s) #0 {
entry:
  switch i32 %s, label %d [
    i32 0, label %u
    i32 1, label %r
  ]
u:
  %q = udiv i32 %a, %b
  br label %m
r:
  %t = srem i32 %a, %b
  br label %m
d:
  %w = urem i32 %a, 7
  br label %m
m:
  %v = phi i32 [ %q, %u ], [ %t, %r ], [ %w, %d ]
  ret i32 %v
}

define i32 @example(i32 noundef %u0, i32 noundef %a, i32 noundef %b, i32 noundef %s) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @dv(i32 %a, i32 %b, i32 %s)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
