; control_inplace_ry_reject_stateprep_runtime_seed.ll — DECLINE (F1): a RUNTIME
; seed. The merge's Pred incoming and the theta's arg-0 are THE SAME SSA VALUE
; (a classical function argument), so the merge is faithful by construction.
;
;     int slice(int seed){ int r = seed; if (q == 5) r = cq_theta(seed, .9); }
;     // probe `p16`, from C
;
; ⚠ THIS IS A DELIBERATE OVER-DECLINE OF A SHAPE THAT WOULD COST NOTHING TO
; ACCEPT, AND IT IS ON THE OWNER'S DESK (PRD §14.11 Q2). `cqrt_alloc_<W>` takes a
; runtime value, and F1 spelled *"the Pred incoming is the SAME VALUE as `T`'s
; arg-0, and that value is untainted"* would pick it up with no new machinery and
; no new frozen symbol. It ships declined because the owner's scope says
; `Constant`.
;
; Note the `Constant` spelling is NOT redundant even if Q2 is granted: it is what
; makes `-0.0` vs `0.0` a decline, because value identity on a UNIQUED constant
; already IS bit identity, while SSA identity on a runtime value proves nothing
; about `-0.0` (there `-0.0` is not a compile-time fact either).
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

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %u1, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %u1, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
