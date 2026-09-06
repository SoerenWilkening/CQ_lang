; control_swap_reject_value_stalebase_inarm.ll — DECLINE: the layout that pins
; classifyArms' POSITION-FREE routed-base wire-staleness guard itself
; (test_C_libtooling-6j1 companion to
; control_swap_reject_value_stalebase_{diamond,ifelse}.ll).
;
; Since test_C_libtooling-6j1 the straight-line guard
; (OpcodeLowering::declineStaleRecordOps) shares the diagonal-alias seed
; closure and fires FIRST on the original stalebase twins (opt exits at the
; first DS_Error), so this companion uses the one layout that guard ACCEPTS
; while the routed wire is still stale:
;   * the condition is CROSS-QUBIT (`icmp` on `%p`) — its provenance never
;     touches `%q`'s wire, keeping every condition-side guard clean;
;   * the chained `cq_theta(%q, ·)` sits IN-ARM, AFTER the chain op — it is
;     provably post-emission of `add %qd, 3` (dominated, no reach-back), so
;     the position-aware straight-line guard accepts the add.
; The region-level guard must still decline: it is POSITION-FREE, because the
; route-in/route-back `cqrt_cswap` pair and the method-B reverse-play read the
; routed WIRE at the region boundary, not at the arm op's schedule — ANY
; non-diagonal gate on the routed base's closed wire (`{%qd, %q}`, backward
; `cq_phi` arg-0 hops) makes the routed record stale there. Accepting would
; replay the chain against the post-Ry rail (stale-record family,
; lowering_reject_stale_record_add.ll physics) — a verify-clean wrong unitary.
; (Defense-in-depth, not a sole barrier: the later valueArmIsPureChain check
; would also decline this layout — the in-arm theta is a stray op beside the
; chain — so what this fixture pins is the routed-base guard's OWNERSHIP of
; the decline and its message, not the only thing standing before emission.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %p  = call i32 @cq_theta_si32(i32 %v0, double 7.500000e-01) ; condition qubit — separate wire
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = icmp sgt i32 %p, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = add i32 %q, 3
  %q2 = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)  ; in-arm chained Ry, AFTER the op
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: error{{.*}}routed base predates a non-diagonal gate under quantum control
; the straight-line guard must NOT own this shape, and nothing may emit
; CHECK-NOT: cq opcode lowering: operand predates a non-diagonal gate
; CHECK-NOT: condition predates a non-diagonal gate
; CHECK-NOT: cqrt_copy
