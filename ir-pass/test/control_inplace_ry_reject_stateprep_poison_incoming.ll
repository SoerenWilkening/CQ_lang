; control_inplace_ry_reject_stateprep_poison_incoming.ll — DECLINE (F1): a
; `poison` Pred-edge incoming — the sibling of `..._undef_incoming.ll`.
;
; ⚠ HEADER CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L1 finding
; F-L1-2). This file used to say: *"a future widener who reaches for
; `isa<Constant>` (which both DO satisfy) reddens exactly these two."* **IT DOES
; NOT.** The SEED here is `i32 0` — a perfectly good `ConstantInt` — and only the
; MERGE INCOMING is `poison`, so F1's clause **1** (which is applied to the SEED)
; PASSES and the decline comes from clause **2**. Relax clause 1 to
; `isa<Constant>` and this file and its `undef` sibling stay GREEN. **The files
; that go red under that mutation are
; `control_inplace_ry_reject_stateprep_{undef,poison}_seed.ll`**, which carry
; `undef`/`poison` in BOTH slots; measured with the mutation, `undef_seed` becomes
; a real ACCEPT emitting `cqrt_alloc_i32(i32 undef)`.
;
; WHAT THIS FILE PINS is clause 2 on a `poison` incoming, and it is kept as its
; own fixture beside the `undef` one because `UndefValue` and `PoisonValue` are
; distinct LLVM classes reaching the same test.
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
  %rm = phi i32 [ %rt, %arm ], [ poison, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
