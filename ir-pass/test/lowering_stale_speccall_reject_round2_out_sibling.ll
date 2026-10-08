; lowering_stale_speccall_reject_round2_out_sibling.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 2 R2-2 / R2-3: the 6.5 `%out` route). Hand
; IR (the review's probe p1_round2_sibling).
;
; `%c2` reads `%out1`, the merge of a 6.5 classical call under quantum control
; (`if (q > 5) r1 = f(aa)`): classical at the early sweep and at round 1, tainted at
; round 2 once the classical-call-arm emitter's `%out` rail re-seeds propagation.
; Arm %a holds the lifted read `g(%p)`, arm %b an in-place Ry on `%p`. As in
; lowering_stale_speccall_reject_round2_breakescape_sibling.ll, the reader-policy
; grant of the early sweep is re-asked under round-2 taint before round-2 detection
; (`declineTaintedArmLiftedReads`) and declines with the stale-record string.
; ⚠ SAME STRING, DIFFERENT OWNER than on the round-1 snapshot 8c517ac4: there the
; early sweep's over-approximating "under tainted control" (`instUnderTaintedControl`:
; the arms are dominated by the TAINTED `%c1` branch and do not post-dominate it)
; already chose the pure-op policy. Exact control dependence (R2-3) says the arms
; depend only on `%c2`, so the early sweep grants and the round-2 re-ask declines.
; Measured control: with `%c1` classical (no `%out`, no round 2) the early sweep grants
; and the module dies later at the classical-mux guard, never at this string.
; RETIREMENT TRIGGER (L7): as for the break-escape twin.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32, i32): cq opcode lowering: operand predates a non-diagonal gate

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @g(i32 noundef %x) #0 {
  %m = mul nsw i32 %x, 3
  %r = add nsw i32 %m, 1
  ret i32 %r
}

define i32 @main(i32 %u0, i32 %aa) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01) #2
  %p = call i32 @cq_theta_si32(i32 0, double 5.000000e-01) #2
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %merge1
arm1:
  %r1 = call i32 @f(i32 %aa)
  br label %merge1
merge1:
  %out1 = phi i32 [ %r1, %arm1 ], [ 5, %entry ]
  %c2 = icmp sgt i32 %out1, 50
  br i1 %c2, label %a, label %b
a:
  %d = call i32 @g(i32 noundef %p)
  br label %merge2
b:
  %p2 = call i32 @cq_theta_si32(i32 %p, double 3.000000e-01) #2
  br label %merge2
merge2:
  %r = phi i32 [ %d, %a ], [ %p2, %b ]
  %m = call i32 @cq_measure_si32(i32 %r) #3
  %mq = call i32 @cq_measure_si32(i32 %q) #3
  %s = add i32 %m, %mq
  ret i32 %s
}
attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
