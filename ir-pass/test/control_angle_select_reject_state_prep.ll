; control_angle_select_reject_state_prep.ll — DECLINE (S3): the consumer's arg-0
; is CLASSICAL — controlled STATE PREP (bd drbq Inc 2b; PRD S5 / Increment 4).
;
;     int r = cq_theta(0, q == 5 ? .9 : .3);
;
; There is no live register to rotate in place: the gate would have to MINT one
; (`cqrt_alloc_i32(0)`) and then apply a controlled Ry to the fresh rail, whose
; "prepped vs |0>" disposition on the inactive branch nothing here proves. That
; is Increment 4's shape, with its own fence (the merge/seed identity), and it
; declines until then.
;
; Note the direction: this is a decline of a shape the epic INTENDS to support
; later, not of one it refuses on principle (Rule 17 — the target shape of THIS
; increment is the chained rotation, and that one lowers).
;
; ⚠ STILL DECLINED AFTER bd test_C_libtooling-drbq INC 4, DELIBERATELY, AND THIS
; IS INC 4's SECOND CUSTOMER SITE (PRD §14.2e / §14.11 Q5, follow-on `drbq.13`).
; Inc 4 shipped controlled state prep at ONE site — `inPlaceRotationArmTheta`'s
; classical-seed path, a flat DIAMOND — and left S3 refused. The two are the same
; source shape seen through different `-O1` outcomes: `if (c) r = cq_theta(0,A);
; else r = cq_theta(0,B);` is merged by SimplifyCFG into the ONE theta with an
; angle `select` that this fixture pins, while the owner's ruling on the
; hand-IR if/else form is a separate explicit decline
; (`control_inplace_ry_reject_stateprep_ifelse_two_preps.ll`,
; `if/else state prep allocates two rails`).
;
; What S3 would need is an Inc-2b-shaped BY-DIFFERENCE lowering on a fresh rail —
; `alloc(SEED); cqrt_ry_<W>(h, B); cqrt_ry_<W>_controlled(f, h, A-B)` — and it
; inherits EVERY §12.3 arithmetic concern: exact only in real arithmetic,
; |δ| <= ½ ulp(A-B) unbounded in ABSOLUTE radians, `fl(A-B)` non-finite from two
; FINITE arms, and the constant-arms-only narrowing (clearance finding F-11)
; verbatim. It also inherits S1-S10 wholesale, which is a second increment's
; worth of surface. Not folded in.
;
; ⚠ bd test_C_libtooling-z0re (OWNER RULING 2026-09-28, option (a)) ADMITTED THE
; SAME SHAPE WITH A **RUNTIME** BASE — `control_angle_select_ry_runtime_base.ll`
; lowers `alloc(t); ry(h, B); ry_controlled(f, h, A−B)`, which is exactly the
; lowering sketched above. THIS FILE STAYS A DECLINE, because its base is a
; LITERAL, and the literal is refused for a measured reason rather than for scope:
; `-O1`'s IPSCCP can fold a live register the condition tests INTO the literal on
; one edge before SimplifyCFG sinks the two thetas, leaving that register live
; and unrotated (`control_angle_select_reject_literal_base_offwire_fold.ll`, probe
; a1) — the hazard F2 guards at the FLAT diamond prep (and misses at a NESTED one:
; bd `fmt3`, a PRE-EXISTING P1 on its own track), and F2 is an edge analysis a
; select does not have. The "prepped vs |0>" worry in the first paragraph is NOT
; the reason (the theta runs on both components, so there is no inactive one); it
; is kept as history. OWNER RULING 2026-09-28 on bd drbq.13: the literal base
; STAYS DECLINED.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 0, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mt
  ret i32 %s
}
