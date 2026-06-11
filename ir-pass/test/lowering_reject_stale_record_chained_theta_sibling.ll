; lowering_reject_stale_record_chained_theta_sibling.ll — DECLINE: the
; sibling-Ry-behind-a-CHAINED-theta over-accept that test_C_libtooling-6j1
; left open and test_C_libtooling-6vk closes (surface S1, straight-line, NO
; control flow).
;
; `%d = add i32 %q2, 3` reads the CHAINED theta `%q2 = cq_theta(%q, %t2)` — a
; mid-wire record on `%q`'s physical wire — while a SIBLING chained theta
; `%q3 = cq_theta(%q, %t3)` re-rotates that SAME wire through the parent name
; `%q`. Rotation lowering RAUWs `%q`/`%q2`/`%q3` to ONE i32 handle, so the
; template emitted at the add's scheduled position (AFTER `cqrt_ry(%h, %t3)`)
; reads the post-`%t3` basis while `%q2` denotes the pre-`%t3` record: the same
; stale-record physics as lowering_reject_stale_record_add.ll, one THETA hop
; removed instead of one cq_phi hop.
;
; The 6j1 seed closure stopped at the chained theta `%q2` (its record
; boundary), and `%q3` is a user of the SIBLING name `%q`, never of `%q2`, so a
; forward-only walk from `%q2` could not reach it — exit 0, verify-clean
; over-accept. The fix crosses the chained-theta arg-0 hop to the wire origin
; `%q` while EXEMPTING the on-ancestry producing thetas (`%q2`, `%q`), so only
; the OFF-ancestry sibling `%q3` is flagged. The on-ancestry accept boundary is
; pinned by lowering_stale_record_chained_theta_onancestry.ll. Guard:
; WireWalk::findNonDiagonalWireGate via OpcodeLowering::declineStaleRecordOps.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2, double %t3) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double %g)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained, in-place Ry (read by the add)
  %q3 = call i32 @cq_theta_si32(i32 %q, double %t3)   ; SIBLING chained Ry on %q's wire
  %d  = add i32 %q2, 3                                ; SSA denotes the pre-%t3 record
  %m  = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
