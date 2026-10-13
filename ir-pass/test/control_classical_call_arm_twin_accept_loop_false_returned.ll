; control_classical_call_arm_twin_accept_loop_false_returned.ll — ACCEPT (batch 053, R11
; round-1 finding A-F2, bd dm7f.27 x dm7f.25). Hand IR: `@g` claims `returned` on %x
; but returns %x + 4, and `@f` loops until `i == g(k & 3)`:
;   int g(int x) /* returned x, falsely */ { return x + 4; }
;   int f(int k) { int n = g(k & 3), s = 0; for (int i = 0; i != n; ++i) s += i; return s; }
; ScalarEvolution reads a call as its `returned` argument (`getReturnedArgOperand`),
; so with the attribute in place it bounds the loop by `k & 3` (max backedge-taken
; count 3) while the real trip count is 4..7. A false `returned` is NOT UB, so that
; bound need not hold on a UB-free execution: `@f`'s twin (which calls `@g`'s twin,
; `returned` dropped, dm7f.25) would leave through `cq.trip.exit` after 4 header
; visits and return 0 where the source returns the sum. Fixed: `loopBounds` strips
; every `returned` (call site and callee) for its analysis and restores it after;
; `n` is then an unknown call result and the bound is the full i32 range.
; ANALYTIC (R2): on a basis state where the source runs `f(k)` without UB, n = (k&3)+4
; and the loop runs n times, below the bound 4294967295, so the counter never fires
; and the twin returns `f(k)`; elsewhere it is total and never merged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; The original keeps its attribute: the analysis strip is restored.
; CHECK-LABEL: define internal i32 @g(i32 returned %x)
; CHECK-LABEL: define i32 @example(
; CHECK:       %r = call i32 @__cq_specsafe_f(i32 %k)
; CHECK:       define internal i32 @__cq_specsafe_g(i32 %x) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin !{{[0-9]+}} {
; CHECK:       define internal i32 @__cq_specsafe_f(i32 noundef %k) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin !{{[0-9]+}} {
; CHECK:         %n = call i32 @__cq_specsafe_g(i32 %a)
; CHECK:         %cq.trip.over = icmp ugt i64 %cq.trip, 4294967295
; CHECK:       cq.trip.exit:
; CHECK-NEXT:    ret i32 0

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @g(i32 returned %x) #0 {
entry:
  %y = add i32 %x, 4
  ret i32 %y
}

define internal i32 @f(i32 noundef %k) #1 {
entry:
  %a = and i32 %k, 3
  %n = call i32 @g(i32 %a)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %body ]
  %s = phi i32 [ 0, %entry ], [ %s.next, %body ]
  %done = icmp eq i32 %i, %n
  br i1 %done, label %exit, label %body
body:
  %s.next = add i32 %s, %i
  %i.next = add i32 %i, 1
  br label %loop
exit:
  ret i32 %s
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
attributes #1 = { nounwind memory(none) }
