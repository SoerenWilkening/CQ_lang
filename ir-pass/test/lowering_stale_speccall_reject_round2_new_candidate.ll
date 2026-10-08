; lowering_stale_speccall_reject_round2_new_candidate.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 3 R3-2). Hand IR (the review's probe
; q5_round2_newcand_derived).
;
; `%c2` reads `%out1`, the merge of a 6.5 classical call under quantum control, so it
; is classical at round 1 and tainted at round 2. Arm %a holds `g(%w)` with `%w =
; %out1 + 1`, and arm %b an in-place Ry on `%w`. `g(%w)` reads only round-2 taint,
; so it is a bd 9paa ROUND-2-NEW candidate: `adjudicateTaintDelta` adds it to `plan6`
; only AFTER the round-2 detection fixpoint. The re-ask before that detection
; (`declineTaintedArmLiftedReads`) therefore also counts a call detection WOULD admit
; on current taint (`isProvenSpecSite`: detection's own shape filter and
; `classifyCandidate`), asks it the pure-op question, and declines with the
; stale-record string. Before R3-2 this module died at round-2 detection with
; ArmClassify's `value-arm swap-route under quantum control` (main and ed6d4c2e
; alike), loud with the stale question never asked; this CHECK tells them apart.
; RETIREMENT TRIGGER (L7): with lowering_stale_speccall_reject_tainted_sibling_arms.ll.
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
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %merge1
arm1:
  %r1 = call i32 @f(i32 %aa)
  br label %merge1
merge1:
  %out1 = phi i32 [ %r1, %arm1 ], [ 5, %entry ]
  %w = add i32 %out1, 1
  %c2 = icmp sgt i32 %out1, 50
  br i1 %c2, label %a, label %b
a:
  %d = call i32 @g(i32 noundef %w)
  br label %merge2
b:
  %p2 = call i32 @cq_theta_si32(i32 %w, double 3.000000e-01) #2
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
