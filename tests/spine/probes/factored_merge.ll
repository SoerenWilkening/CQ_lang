; cq-174f: a quantum phi whose join is reached by several output edges (a classical guard's skip edge
; and a loop unit's exit) is factored by the classical facts of those edges first. g6 (review cq-hqk5,
; wt/rev/small-n1/g6.c): a rule-14 case-1 loop in the arm `x == k && n > 0`; the guard n > 0 skips to
; the join, where the phi takes the skip path's seed 0, and on the unit's exit edge the select over
; the quantum rest (x == k ? loop value : 0). Before the fix the select sat in the join and read the
; loop's copy-out on the skip path (LLVM verifier: does not dominate).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @g6(i32 %x0, double %th, i32 %n, i32 %k, i32 %c) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %th)
  %q = icmp eq i32 %x, %k
  %g = icmp sgt i32 %n, 0
  %qg = and i1 %q, %g
  br i1 %qg, label %loop, label %exit
loop:
  %i = phi i32 [ %i1, %loop ], [ 0, %entry ]
  %acc = phi i32 [ %acc1, %loop ], [ 0, %entry ]
  %m = mul nsw i32 %acc, %c
  %acc1 = add nsw i32 %m, %x
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, %n
  br i1 %done, label %exit, label %loop
exit:
  %r = phi i32 [ 0, %entry ], [ %acc1, %loop ]
  %o = call i32 @cq_measure_si32(i32 %r)
  ret i32 %o
}
; CHECK g6: br i1 %{{g}}, label %{{a}}, label %{{b}}
; CHECK g6: phi i32 [ %{{s}}, %{{s0}} ], [ %{{t}}, %{{t0}} ]
; CHECK-COUNT g6: @cq_template_select_i32_hl( 1
; CHECK-COUNT g6: @cqrt_measure_i32( 1
