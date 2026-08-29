; lowering_stale_record_loop_tracking_phi.ll — the ACCEPT BOUNDARY of the
; Increment-3 record-refresh cut (bd test_C_libtooling-8h7d.5), and the twin of
; lowering_reject_stale_record_loop_nontracking_phi.ll.
;
;     for (...) { d = q * 3; q = cq_theta(q, t2); }
;
; `%qh` is a loop-header phi whose latch incoming `%qn` IS the body's last wire
; write, so at every trip `%qh` denotes exactly what the rail holds
; (`phiTracksWire` proves it: nothing rotates the wire between `%qn` and the back
; edge, and nothing rotates it between `%q` and the loop entry). The body theta
; `%qn` therefore reaches the `mul` only by re-executing `%qh` — it is the NEXT
; iteration's producer, not this one's staler — and the stale-record guard must
; NOT fire.
;
; WHY THIS FIXTURE STILL USES `not`. The program is refused, but by a DIFFERENT
; owner and for a different reason: `%d = mul %qh, 3` mints a fresh out-of-place
; rail every trip, so the loop is not a pure Case-A rail, the header phi survives,
; and `declineClassicalMuxes` declines it. That is the pre-existing disposition
; for an unclaimed tainted header phi and it is not what this fixture is about —
; the load-bearing assertion is the CHECK-NOT: the stale-record message no longer
; owns this program. (The FULL accept, where the loop lowers end to end, is
; control_swap_inloop_post_region_theta.ll and the e2e Grover-loop slices; a `mul`
; is used here precisely because it is NOT an in-place rail op, which isolates the
; wire-walk question from the rail collapse.)
;
; Compare lowering_reject_stale_record_loop.ll (PRD 7.3 §2.9), which stays RED:
; there the read is of `%q` itself — minted OUTSIDE the loop, never re-bound — so
; no barrier lies on the back-edge path and the record genuinely goes stale.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: operand predates a non-diagonal gate
; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %qh = phi i32 [ %q, %entry ], [ %qn, %loop ]        ; TRACKS the wire
  %d = mul i32 %qh, 3                                  ; the READ
  %qn = call i32 @cq_theta_si32(i32 %qh, double %t2)   ; body Ry, carried
  %inext = add i32 %i, 1
  %done = icmp slt i32 %inext, %n
  br i1 %done, label %loop, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
