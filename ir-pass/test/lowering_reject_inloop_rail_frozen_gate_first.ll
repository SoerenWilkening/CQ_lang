; lowering_reject_inloop_rail_frozen_gate_first.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 3). THE FIXTURE THAT PINS WHY THE RECORD
; SET AND THE SKIP SET ARE TWO DIFFERENT SETS.
;
;     %rec = phi i32 [ %q0, %entry ], [ %rec, %merge ]   ; a FROZEN identity carry
;     …
;     %z  = cq_theta(%rec, 0.25)                         ; a GATE on the frozen record
;     %mz = cq_measure(%z)
;
; This is round 2's F-2 shape (lowering_reject_inloop_rail_identity_carry.ll) with
; the frozen record's consumer changed from an out-of-place `mul` to an IN-PLACE
; `cq_theta`. It declines for the reason F-2's argument gives — a gate applied to a
; frozen record is ITSELF a non-member read of that record at a position where the
; sibling chain's gates have already moved the wire, so the fence names `%rec`'s
; read before anything downstream of `%z` matters. (That is also why frozen-ness is
; not propagated forward: it never needs to be.)
;
; THE MUTATION IT EXISTS TO CATCH. Round 3's F-3 fix widens the RECORD set from the
; chain to the rail's forward closure. The symmetric-looking edit — widening the
; SKIP set (`MemberSet`, the values whose own consumers are not reads) to that same
; closure — was measured and REGRESSES THIS FILE FROM A DECLINE TO AN ACCEPT: `%z`
; joins the rail by the extension's first edge kind, so a rail-wide skip set treats
; it as "the wire moving" and deletes exactly the read that proves `%rec` frozen.
; The two sets answer different questions and must stay apart:
;
;   SKIP set   = "whose own in-place execution IS the wire moving?"  → the CHAIN.
;   RECORD set = "which SSA names denote a state of this rail?"      → the RAIL.
;
; HAND IR, and reported as such (Rule 11), for the same reason its F-2 sibling is:
; `ir-pass/test/*.ll` is a shipped input surface, and the C spellings of a zero-hop
; identity carry are folded by InstCombine or LICM-hoisted out of the loop. The
; ACCEPT boundary on the other side is control_swap_inloop_gatefree_body.ll — an
; identity carry on a rail with no gate at all cannot stale anything and keeps
; lowering.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q   = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %rec = phi i32 [ %q0, %entry ], [ %rec, %merge ]   ; FROZEN identity carry
  %i   = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %z  = call i32 @cq_theta_si32(i32 %rec, double 2.500000e-01)  ; a GATE on the frozen record
  %mz = call i32 @cq_measure_si32(i32 %z)
  %qn = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %m1 = call i32 @cq_measure_si32(i32 %qn)
  %s = add i32 %m1, %mz
  ret i32 %s
}
