; control_inplace_ry_reject_stateprep_constexpr_seed.ll — DECLINE (F1): the seed
; is a `ConstantExpr` (`ptrtoint (ptr @G to i32)`), and so is the merge incoming,
; so it is POINTER-IDENTICAL and every identity test passes. Hand IR only.
;
; ⚠ POINTER IDENTITY IS NOT ENOUGH HERE, AND THAT IS THE WHOLE ROW. A
; `ConstantExpr` is a LINK-TIME constant whose value THIS COMPILER CANNOT READ,
; so `cqrt_alloc_i32(ptrtoint …)` would prepare a rail at a value the fence
; cannot name — "the rail starts at |SEED>" is unverifiable rather than false.
; That is the Inc-2b round-2 finding one family over (a `double` `ConstantExpr`
; arm fell into the branch labelled "runtime arm" and bypassed every value
; clause). This fixture also covers the GLOBAL-ADDRESS seed of PRD §14.3 row
; F1-7: at every integer width a global's address can only appear as a
; `ptrtoint` `ConstantExpr`, so the two rows are ONE fixture and committing a
; second would be a false coverage claim.
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

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
@G = external global i32

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 ptrtoint (ptr @G to i32), double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ ptrtoint (ptr @G to i32), %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
