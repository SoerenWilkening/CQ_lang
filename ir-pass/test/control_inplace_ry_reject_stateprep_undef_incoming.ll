; control_inplace_ry_reject_stateprep_undef_incoming.ll — DECLINE (F1): an
; `undef` Pred-edge incoming.
;
; This is the `-O1` shape of `int r; if (…) r = cq_theta(0, θ);` — an
; UNINITIALIZED `r` — so it is not a hand-IR curiosity (probe `p11` reaches it by
; a different route, `llvm.assume`).
;
; ⚠ HEADER CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L1 finding
; F-L1-2). This file used to offer bd `xy9n`'s literal-integrity defect as "a
; SECOND, INDEPENDENT REASON" it is refused. **THAT DEFECT DOES NOT APPLY TO THIS
; MODULE.** The `undef` here is the merge's INCOMING; the alloc's argument is
; `Theta->getArgOperand(0)`, which is the `i32 0` SEED, so `undef` never reaches
; an emitted gate slot at all. The `xy9n` hazard belongs to an `undef` **SEED**,
; and it is pinned where it lives:
; `control_inplace_ry_reject_stateprep_undef_seed.ll` (measured: with F1's clause
; 1 disabled that module ACCEPTS and emits `cqrt_alloc_i32(i32 undef)`).
;
; THIS FILE PINS F1's clause **2** — the Pred incoming must be pointer-identical
; to the seed — and nothing else. Relaxing clause 1 to `isa<Constant>` leaves it
; green.
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed does not match the merge incoming under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ undef, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
