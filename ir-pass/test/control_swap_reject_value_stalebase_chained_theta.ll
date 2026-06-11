; control_swap_reject_value_stalebase_chained_theta.ll — DECLINE: a value
; diamond whose routed base is itself a CHAINED theta, re-rotated by a SIBLING
; theta on the same wire (test_C_libtooling-6vk, surface S3 — the routed-base
; twin of the straight-line chained-theta over-accept).
;
; The routed base `%qb = cq_theta(%q, 1.0)` is a chained, in-place Ry record on
; `%q`'s wire; `%qs = cq_theta(%q, 0.25)` is a SIBLING chained Ry on the SAME
; wire through the parent name `%q`. Post-RAUW `%q`/`%qb`/`%qs` are ONE i32
; handle, so the arm op (and any route-in) reads the post-`%qs` wire while the
; chain's SSA base `%qb` names the pre-`%qs` RECORD — the stale-record family,
; replayed onto the rail as a verify-clean wrong unitary.
;
; This was the WI-5 routed-base guard's blind spot one theta hop up:
; condProvenance stops AT a theta source (never entering its tainted arg-0),
; and before test_C_libtooling-6vk the WireWalk closure stopped at the chained
; theta `%qb`, so the sibling `%qs` (a user of `%q`, not `%qb`) was unreachable
; — exit 0, the full method-B routed stream emitted. The fix crosses the
; chained-theta arg-0 hop to the wire origin `%q`; the EARLIER straight-line
; guard (OpcodeLowering::declineStaleRecordOps) then catches the arm's
; `add %qb, 3` first — the pre-branch Ry can never be provably post-emission of
; an arm op — and opt exits at the FIRST DS_Error, so that is the observed
; message (same physics, earlier owner; mirrors
; control_swap_reject_value_stalebase_diamond.ll). No `cqrt_cswap`/`cqrt_copy`
; route is emitted.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qb = call i32 @cq_theta_si32(i32 %q, double 1.000000e+00)   ; routed base — chained theta
  %qs = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)   ; SIBLING chained Ry on %q's wire
  %c  = icmp sgt i32 %qs, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = add i32 %qb, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %qb, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
; never silently routed
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_copy
