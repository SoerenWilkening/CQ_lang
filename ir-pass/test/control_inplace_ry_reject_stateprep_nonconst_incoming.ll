; control_inplace_ry_reject_stateprep_nonconst_incoming.ll — DECLINE (F1): the
; Pred incoming is the QUANTUM REGISTER itself.
;
;     int r = q;  if (q > 5) { r = 0; cq_theta(&r, .9); }  // probe `q17`, from C
;
; ⚠ THIS IS A NO-CLONING VIOLATION (Rule 8), NOT A TIDINESS COMPLAINT. On the
; straight-through edge `r` IS `q` — an ALIAS of a superposed register — and the
; region asks for a mux between that alias and a freshly prepared rail. Copy +
; uncompute cannot disentangle a superposition, and there is no rail whose two
; components are "q" and "Ry(θ)|0>".
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
; `for (…) { if (a == 5) cq_theta(&a, .9); }` — an in-place Ry on the
; CONDITION register, with no state prep and no seed anywhere in the source — it
; named a "seed" that only exists because `-O1` substituted `5` for `a` on the
; proving edge, and its implied fix ("make the straight-through value the seed")
; is not the fix. A TAINTED incoming is a NO-CLONING MUX (Rule 8), and that is
; what the new string names.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep merged with a quantum register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %q, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
