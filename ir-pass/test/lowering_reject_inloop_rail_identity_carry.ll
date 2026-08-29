; lowering_reject_inloop_rail_identity_carry.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 2, finding F-2 — THE CUT'S PREMISE).
;
; `railGateBetween` suppresses ("cuts") every path that RE-EXECUTES the record's
; definition, on the premise that re-executing the def refreshes the record. That
; premise is true of every in-place gate and of an ordinary rail phi. It is FALSE
; for a ZERO-HOP IDENTITY-CARRY phi:
;
;     %rec = phi i32 [ %q0, %entry ], [ %rec, %merge ]
;
; which step (1) accepts as a rail because `peelInPlaceBase(LatV) == &P` holds
; TRIVIALLY. It re-executes every iteration and yields the SAME value every time —
; a FROZEN alias of the mint — while the sibling chain on the SAME root mint moves
; the wire underneath it. The cut then suppressed exactly the path carrying the
; staleness, and the module lowered to
;
;     loop: … cq_template_mul_i32_hl(%h, 7); measure(…); cqrt_ry_i32(%h, -0.5) …
;
; so iteration 2's `mul` reads `%h` AFTER iteration 1's Ry while `%rec` names
; `%q0`'s state every iteration. Same class as
; lowering_reject_inloop_rail_alias_shared_mint.ll (two chains, one mint, one
; physical register), reached through the cut instead of through the grouping.
;
; THE FIX IS STATED GENERALLY, not as `In == P`: a carry refreshes only if it
; crosses a rail GATE. An incoming that peels back to the phi through diagonal /
; renaming steps alone is the same frozen record wearing extra phases; a
; basis-relabelling `cq_theta` or in-place `add`/`xor` on the carry is what makes a
; phi a genuine rotating rail — which is why the CUSTOMER's own header phi (`%q`
; here) still refreshes and still lowers.
;
; HAND IR, and reported as such (Rule 11): `ir-pass/test/*.ll` is a shipped input
; surface, and the C spellings of this shape are folded by InstCombine or
; LICM-hoisted out of the loop (where they are sound — the hoisted read runs once,
; before any gate, and the M-A guard warns). The previous round's "unreachable"
; hole turned out to be `clang -O1` reachable, so this one is fenced on the IR it
; is written on. The gate-free sibling control_swap_inloop_gatefree_body.ll is the
; ACCEPT boundary: an identity carry whose rail has NO gate at all cannot stale
; anything, and it must keep lowering. So is the OLDER
; lowering_unroll_leave_identity_carry.ll (3c6m.55 Lever B, the round-1 `tryCaseA`
; path), whose whole point is that the zero-hop peel IS a Case-A claim seed — F-2
; narrows what such a phi may be trusted to REFRESH, and changes nothing about what
; it may be CLAIMED as.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cq_template_mul_i32_hl
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q   = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %rec = phi i32 [ %q0, %entry ], [ %rec, %merge ]   ; IDENTITY carry: always %q0
  %i   = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %g = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %g, %mid ], [ %q, %loop ]
  %acc = mul i32 %rec, 7                             ; reads the FROZEN record
  %mm = call i32 @cq_measure_si32(i32 %acc)
  %qn = call i32 @cq_theta_si32(i32 %qm, double -5.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %m1 = call i32 @cq_measure_si32(i32 %qn)
  ret i32 %m1
}
