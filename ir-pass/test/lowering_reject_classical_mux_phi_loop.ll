; lowering_reject_classical_mux_phi_loop.ll — DECLINE: one-base merge phi
; reachable around a CLASSICAL loop back edge (test_C_libtooling-5j5 decline
; complement; pins lift condition (7a), the iteration-2 staleness).
;
; The diamond body is exactly the headline lift shape — both incomings
; tainted, both resolve to the one base %q, the chain sits in its arm — but
; the merge feeds a classical back edge. On iteration 1 (i==0) the arm fires
; rz; on iteration 2 the straight edge claims the BASE record %q while the
; physical register already carries the iteration-1 rz: measuring the
; last-iteration %p as "the un-rotated q" is a stale record, verify-clean
; wrong. Condition (7a) — no chain gate may reach the OTHER edge's
; terminator — sees arm -> merge -> loop (the back edge) and refuses; the
; wi5 decline fires.
;
; (The genuinely loop-carried source `for(..) if(c) q = cq_phi(q,θ);` also
; declines: its loop-header phi never resolves to one base — the resolver
; stops at phis, so header-incoming and back-edge-incoming bases differ.)
;
; Guard: TaintPropagation::declineClassicalMuxes. It OWNS the exact `Msg`
; string; this CHECK mirrors it character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
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
  %q2 = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)
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
