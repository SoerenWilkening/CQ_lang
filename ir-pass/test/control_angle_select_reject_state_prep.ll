; control_angle_select_reject_state_prep.ll — DECLINE (S3): the consumer's arg-0
; is CLASSICAL — controlled STATE PREP (bd drbq Inc 2b; PRD S5 / Increment 4).
;
;     int r = 0; cq_theta(&r, q == 5 ? .9 : .3);
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
; source shape seen through different `-O1` outcomes: `if (c) { r = 0; cq_theta(&r,A); }
; else { r = 0; cq_theta(&r,B); }` is merged by SimplifyCFG into the ONE theta with an
; angle `select` that this fixture pins, while the owner's ruling on the
; hand-IR if/else form is a separate explicit decline
; (`control_inplace_ry_reject_stateprep_ifelse_two_preps.ll`,
; `if/else state prep allocates two rails`).
; ⚠ bd test_C_libtooling-fmt3 (2026-09-28): the if/else half of the sentence above is
; no longer true. With `nomerge` on every `cq_theta_*` (CQ.h) the if/else is NOT merged;
; it reaches `classifyArms` and declines `if/else state prep allocates two rails`
; (drbq.13's own counter-example `a1.c` measured, `fmt3_probes/src/d13a1.c`). This
; fixture's select shape comes from C only as `r = SEED; cq_theta(&r, c ? A : B)`.
;
; What S3 would need is the angle-select lowering on a fresh rail —
; `alloc(SEED); cqrt_ry_<W>(h, B); cqrt_ry_<W>_controlled(f, h, -B);
; cqrt_ry_<W>_controlled(f, h, A)` since bd dm7f.6 (the by-difference form it
; replaced carried the §12.3 rounding concerns, now retired) — and it inherits
; S1-S10 wholesale.
;
; ⚠ bd test_C_libtooling-z0re (OWNER RULING 2026-09-28, option (a)) ADMITTED THE
; SAME SHAPE WITH A **RUNTIME** BASE — `control_angle_select_ry_runtime_base.ll`
; lowers exactly that stream. THIS FILE STAYS A DECLINE, because its base is a
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
