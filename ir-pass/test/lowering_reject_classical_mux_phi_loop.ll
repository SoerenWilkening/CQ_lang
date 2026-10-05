; lowering_reject_classical_mux_phi_loop.ll — DECLINE: one-base merge phi
; reachable around a CLASSICAL loop back edge (test_C_libtooling-5j5 decline
; complement; pins lift condition (7a), the iteration-2 staleness).
;
; The diamond body is exactly the headline lift shape — both incomings
; tainted, both resolve to the one base %q, the chain sits in its arm — but
; the merge feeds a classical back edge. On iteration 1 (i==0) the arm fires
; ry; on iteration 2 the straight edge claims the BASE record %q while the
; physical register already carries the iteration-1 ry: measuring the
; last-iteration %p as "the un-rotated q" is a stale record, verify-clean
; wrong. Condition (7a) — no chain gate may reach the OTHER edge's
; terminator — sees arm -> merge -> loop (the back edge) and refuses; the
; wi5 decline fires.
;
; (Pre-3qlq register form: the loop-carried source `for(..) if(c) q = cq_phi(q,θ);`
; also declined: its loop-header phi never resolves to one base — the resolver
; stops at phis, so header-incoming and back-edge-incoming bases differ.)
;
; Guard: TaintPropagation::declineClassicalMuxes. It OWNS the exact `Msg`
; string; this CHECK mirrors it character-for-character (Rule 12).
;
;
; 3qlq(prep_a2): HAND DECISION — the register `cq_phi` here was NEVER the subject.
; This fixture pins an uncompute / mux / measurement-ordering / specialization rule
; and used `%r = cq_phi_<sfx>(%x, θ)` only as "a gate on a handle".  D1 removes that
; spelling, so the gate is re-spelled `cq_theta_<sfx>` — the OTHER in-place rotation
; on the same rail, which is what the corpus uses everywhere else for the same job.
; MEASURED on the Inc-1 binary: the swap reproduces this fixture's ORIGINAL asserted
; diagnostic, so the CHECK lines are UNCHANGED and the property is pinned by exactly
; the text it was pinned by before.  (prep_a measured the same 16 files against the
; pre-3qlq ORACLE; this is the independent re-measurement on the SUBJECT.)
; ⚠ Note what the swap does NOT preserve: Rz is DIAGONAL and Ry is not, so a rule
; that turned on diagonality would move.  None of these 16 do — that is what the
; character-for-character reproduction of the diagnostic establishes.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]   ; classical induction
  %c = icmp eq i32 %i, 0
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)
  br label %merge
merge:
  %p = phi i32 [ %q2, %arm ], [ %q, %loop ]     ; iter-2 straight edge: stale base record
  %inext = add i32 %i, 1
  %d = icmp slt i32 %inext, %n
  br i1 %d, label %loop, label %exit            ; classical back edge
exit:
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi
