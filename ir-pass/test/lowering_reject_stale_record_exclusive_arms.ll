; lowering_reject_stale_record_exclusive_arms.ll — DECLINE (known
; OVER-decline, pinned so the boundary cannot drift silently): the op and the
; sibling chained Ry sit on MUTUALLY EXCLUSIVE classical branches
; (test_C_libtooling-6j1 §8 review note).
;
; Physically every single trace here is fine — the CLASSICAL `%cc` picks
; exactly one of {template, Ry} per execution, so the template (path a) always
; reads the pre-Ry wire it denotes and the Ry (path b) never co-executes with
; it. But the position-aware accept proof is DOMINANCE-based
; (`DT->dominates(EmitPoint, theta)` — the add in arm `a` does not dominate
; the theta in arm `b`), and dominance cannot see path exclusivity, so the
; guard conservatively declines (Prime Directive: over-decline is safe; the
; seed closure reaches the theta through `{%qd → %q}` exactly as in
; lowering_reject_stale_record_alias_sibling.ll). A future refinement MAY
; accept this shape with a path-exclusivity argument — until one is designed
; and adversarially cleared, this fixture pins the decline in BOTH directions:
; it keeps the shape from silently lowering AND records that today's decline
; is deliberate, not an accident of the walk.
;
; ⚠ THAT FUTURE REFINEMENT NOW EXISTS — FOR THE OTHER POLICY ONLY (bd
; test_C_libtooling-3d8q). `WireWalk`'s `RequireEmitDominance=false` asks legs 1
; and 2 with no dominance PRECONDITION, and leg 1
; (`!isPotentiallyReachable(T, EmitPoint)`) is exactly the path-exclusivity
; argument this header asked for. It is passed ONLY by
; `recordStaleQuantumReaders` (the `@cq_theta_*` / `@cq_measure_*` reader
; family), where the shape is not exotic but STRUCTURAL — a rotation reader
; routinely IS a branch arm, and 14 shipped fixtures flip without it. Accept
; twin, one reader class away: `lowering_stale_reader_exclusive_arms_accept.ll`.
;
; THIS FILE'S DECLINE IS DELIBERATELY LEFT STANDING. Flipping the PURE-op policy
; is an ACCEPT-direction widening of a fence that has shipped and been
; Rule-13-cleared since Phase 5, and it belongs to its own increment with its own
; adversarial round — not to a change whose whole warrant is widening a decline.
; RETIREMENT TRIGGER: when that increment lands, this file becomes an ACCEPT and
; its stream is the twin's; re-derive it then, do not delete it.
;
; bd r2j3.2 (review round 1, F1) widened the pure-op policy by ONE case, not this
; one: a gate that fails dominance is granted when it POST-dominates the read and
; cannot reach it (`gateFollowsRead`, OpcodeLowering.cpp — a read in a classical arm,
; or a QRAM access in a tainted one, with the gate after the merge). A sibling arm
; never post-dominates, so this decline stands; its tainted-branch twin is
; lowering_reject_stale_record_tainted_sibling_arms.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %c0, double %g, double %t2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %cc = icmp sgt i32 %c0, 0                                ; CLASSICAL condition
  br i1 %cc, label %a, label %b
a:
  %d = add i32 %q, 3                                      ; op on one path
  %m1 = call i32 @cq_measure_si32(i32 %d)
  br label %merge
b:
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)        ; sibling Ry on the other
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  br label %merge
merge:
  %r = phi i32 [ %m1, %a ], [ %m2, %b ]                    ; classical merge (measure results)
  ret i32 %r
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
