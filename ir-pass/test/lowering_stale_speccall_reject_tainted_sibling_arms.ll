; lowering_stale_speccall_reject_tainted_sibling_arms.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 1 F1): the tainted-branch twin of
; lowering_stale_speccall_classical_sibling_arm_accept.ll, and the lifted-call twin of
; lowering_reject_stale_record_tainted_sibling_arms.ll (same module, `call @f` for
; the `add`). Hand IR.
;
; Under QUANTUM control both arms run, and the control emitters linearize them in an
; order the CFG does not fix (a value arm's chain is hoisted into the pred, an
; in-place Ry arm becomes a controlled Ry), so CFG exclusivity is not execution
; exclusivity. A lifted call under tainted control therefore keeps the PURE-OP stale
; policy (`gateFollowsRead`: the gate must post-dominate the read, which a sibling arm
; never does), and the early stale sweep declines with the pure-op string. Pinned so
; the reader policy the classical twin uses never reaches a tainted arm silently.
; "Under tainted control" is EXACT control dependence (`controlDependsOnTaintedBranch`,
; review round 2 R2-3), and a branch tainted only at round 2 (a 6.5 `%out`, a 7.4
; break-escape register) is covered by the re-ask before every detection
; (`declineTaintedArmLiftedReads`, R2-2), which since review round 3 R3-2 also counts
; a bd 9paa round-2-NEW candidate (`isProvenSpecSite`): round-2 twins
; lowering_stale_speccall_reject_round2_breakescape_sibling.ll,
; lowering_stale_speccall_reject_round2_out_sibling.ll and
; lowering_stale_speccall_reject_round2_new_candidate.ll.
; RETIREMENT TRIGGER (L7): the day a control emitter claims a value arm holding a
; lifted call (today ArmClassify refuses it at detection: `value-arm swap-route under
; quantum control`), re-derive this file AND both round-2 twins against that
; emitter's order; do not just flip them. Likewise if a stage between the early sweep
; and detection starts tainting a branch condition without an `adjudicateTaintDelta`
; and is not followed by a `declineTaintedArmLiftedReads` before the next detection.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

define i32 @f(i32 noundef %x) local_unnamed_addr #0 {
  %m = mul nsw i32 %x, 3
  %r = add nsw i32 %m, 1
  ret i32 %r
}

define i32 @main() local_unnamed_addr #1 {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01) #2
  %c = call i32 @cq_theta_si32(i32 0, double 7.000000e-01) #2
  %cc = icmp sgt i32 %c, 3                        ; TAINTED condition
  br i1 %cc, label %a, label %b

a:
  %d = call i32 @f(i32 noundef %q)                ; lifted read of %q in one arm
  br label %merge

b:
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01) #2   ; Ry in the sibling
  br label %merge

merge:
  %r = phi i32 [ %d, %a ], [ %q2, %b ]
  %m = call i32 @cq_measure_si32(i32 %r) #3
  %mc = call i32 @cq_measure_si32(i32 %c) #3
  %s = add i32 %m, %mc
  ret i32 %s
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
