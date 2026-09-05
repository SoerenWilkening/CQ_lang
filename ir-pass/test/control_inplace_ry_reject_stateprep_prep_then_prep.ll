; control_inplace_ry_reject_stateprep_prep_then_prep.ll — DECLINE (F1): two
; SEQUENTIAL state preps on the SAME register.
;
;     int r = 0;
;     if (q == 5) r = cq_theta(0, .9);      // region 1 — accepts
;     if (q == 6) r = cq_theta(0, .4);      // region 2 — DECLINES
;                                           // probe `p12c`, from C
;
; Region 2's merge φ has region 1's merge φ as its Pred incoming — a VALUE, not a
; `Constant` — so F1 refuses it as a data mux. That is the right answer and the
; reason is physical: region 2's arm would mint a SECOND rail at |0>, and on
; region 2's `f=0` component the source's `r` is region 1's rail, which may be
; `Ry(.9)|0>`. Two different physical wires, muxed.
;
; ⚠ CONTRAST, DELIBERATELY, WITH TWO FIXTURES THAT ACCEPT THE NEIGHBOURING
; SHAPES: `..._stateprep_two_regions.ll` (the same source with TWO variables —
; each region's Pred incoming is its own `Constant`) and
; `..._stateprep_seq_then_chained.ll` (prep then a CHAINED arm on the same `r` —
; region 2 rotates region 1's rail IN PLACE and mints nothing). Same CFG, three
; verdicts, and the discriminator is always the merge incoming.
; F1 — SEED IDENTITY (PRD §14.2a). On the `f=0` component the fresh rail holds
; |SEED>, so the merge is FAITHFUL only if the source's straight-through value IS
; the seed. Anything else is a DATA MUX between a prepared rail and an unrelated
; value, and a data mux has no rotation-arm lowering.
;
; F1 is an EXPLICIT clause with its own string, and that is the point of it.
; Before Inc 4 the shape was refused twice over BY POINTER IDENTITY ON UNIQUED
; CONSTANTS — R3's `RotBase != Routed` and the emitter's `T->getArgOperand(0) !=
; Base` — with no comment saying so and no fixture pinning it. Those two keep
; their own string for the shape they are about (a cross-handle mux); F1 runs
; FIRST so the message names the seed.
;
;
; ⚠ THE STRING MOVED 2026-09-05 (round-1 Rule-13 review, lens L5 finding
; F-L5-1): F1's second sub-clause now says `state prep merged with a quantum
; register` when the PRED INCOMING IS TAINTED, and keeps
; `state prep seed does not match the merge incoming` for every other mismatch
; (a constant that is not the seed, `undef`/`poison`, a `select`, a
; `ConstantExpr`, a runtime value). The split exists because the one string
; described the IR rather than the program: on the plain-C R4 shape
; `for (…) { if (a == 5) a = cq_theta(a, .9); }` — an in-place Ry on the
; CONDITION register, with no state prep and no seed anywhere in the source — it
; named a "seed" that only exists because `-O1` substituted `5` for `a` on the
; proving edge, and its implied fix ("make the straight-through value the seed")
; is not the fix. A TAINTED incoming is a NO-CLONING MUX (Rule 8), and that is
; what the new string names.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep merged with a quantum register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %m1
m1:
  %rm = phi i32 [ %rt, %arm1 ], [ 0, %entry ]
  %c2 = icmp eq i32 %q, 6
  br i1 %c2, label %arm2, label %m2
arm2:
  %st = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  br label %m2
m2:
  %sm = phi i32 [ %st, %arm2 ], [ %rm, %m1 ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %sm)
  %s = add i32 %mq, %mr
  ret i32 %s
}
