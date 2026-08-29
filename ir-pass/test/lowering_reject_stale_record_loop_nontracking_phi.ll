; lowering_reject_stale_record_loop_nontracking_phi.ll — DECLINE, and this is THE
; over-accept probe for `WireWalk::phiTracksWire` (bd test_C_libtooling-8h7d.5).
;
; Increment 3 lets a wire gate be exempted when every path from the gate back to
; the read RE-EXECUTES the record's own definition — which, for a loop-header
; phi, is the claim "the phi re-reads the wire every trip". THAT CLAIM IS FALSE IN
; GENERAL, and this fixture is the shape it is false for.
;
;     for (...) { d = q * 3; q = cq_theta(q, t2); cq_theta(q, t3); }
;                                                 ^^^^^^^^^^^^^^^ result DISCARDED
;
; `%qh` is the loop-carried register phi and it looks exactly like the customer's
; — 2 incomings, latch value `%qn` a chained theta that peels back to the phi. But
; `%junk` fires on the SAME physical wire AFTER `%qn`, so on iteration 2 `%qh`
; denotes the PRE-`%junk` record while the rail holds the POST-`%junk` state. The
; emitted `cq_template_mul_i32_hl` then reads a basis the SSA operand does not
; name: the verify-clean stale-record miscompile, hidden behind the back edge.
;
; `phiTracksWire` catches it by walking each incoming to its edge and refusing the
; barrier if a `cq_theta` runs in between — here `%junk`, between `%qn` and the
; latch terminator. Without that check the barrier walk would cut the path at
; `%qh` and ACCEPT. Flip `phiTracksWire` to `return true` and this fixture goes
; green while the miscompile ships; that is exactly what it is here to prevent.
;
; The ACCEPT twin is lowering_stale_record_loop_tracking_phi.ll — the same
; program without the discarded rotation.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
; CHECK-NOT: cq_template_mul_i32_hl
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2, double %t3, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %qh = phi i32 [ %q, %entry ], [ %qn, %loop ]        ; carried register phi
  %d = mul i32 %qh, 3                                  ; the READ (not an in-place op)
  %qn = call i32 @cq_theta_si32(i32 %qh, double %t2)   ; carried
  %junk = call i32 @cq_theta_si32(i32 %qn, double %t3) ; DISCARDED — the phi stops tracking
  %inext = add i32 %i, 1
  %done = icmp slt i32 %inext, %n
  br i1 %done, label %loop, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
