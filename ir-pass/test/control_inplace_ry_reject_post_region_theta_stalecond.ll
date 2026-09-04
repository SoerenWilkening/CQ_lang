; control_inplace_ry_reject_post_region_theta_stalecond.ll — DECLINE (FLAT): the
; RED half of the §13.4b pair. The condition wire gains a non-diagonal gate that is
; NOT provably after the region, so `condWireDisposition` returns `DeclineNow` and
; the P1 widening is never reached.
;
;     qs = cq_theta(q, .2);            <-- a SIBLING Ry on the condition's wire,
;     if (q == 5) r = cq_theta(r, .9);     emitted BEFORE the branch
;
; THE TWO HALVES MUST NOT DRIFT. Its green twin
; (control_inplace_ry_post_region_theta_cond.ll) is the identical arm class with the
; wire gate on the OTHER side of the region, and Increment 3 widens P1 to admit
; exactly that one. `DeclineNow` is decided by `condWireDisposition`'s P4/P5
; preconditions and by `wireGainsNonDiagonalGate(Prov, BI, DT)` — all BEFORE the
; `SawRotationArm` disjunct exists — so this fixture is what says the widening did
; not reach past the disposition it was given.
;
; The physics: the flag is minted AT THE BRANCH from the condition's CURRENT basis
; and stripped by recomputing the predicate on the same registers. `%qs` is an Ry
; on `%q`'s OWN physical rail (rotation lowering RAUWs the sibling onto the one
; handle) that runs BEFORE the branch, so the mint reads a basis the source compare
; never described and the `_unc` strip cannot return the flag to |0>.
;
; ⚠ THE FIRST DRAFT OF THIS FIXTURE DID NOT DECLINE, and the reason is worth
; carrying: it wrote the gate as `%q1 = cq_theta(%q, .1)` and then compared `%q1`,
; which puts the gate ON THE COMPARE'S OWN ANCESTRY — and `findNonDiagonalWireGate`
; EXEMPTS on-ancestry gates by design (they PRODUCE the record; they cannot stale
; it). That shape accepts, correctly, and accepted before Increment 3 too. A gate
; is stale evidence only when it is OFF the seed's own arg-0 chain, which is what
; the sibling below is.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %qs = call i32 @cq_theta_si32(i32 %q, double 2.000000e-01)
  %c  = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r0, %entry ]
  %ma = call i32 @cq_measure_si32(i32 %qs)
  %mb = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %ma, %mb
  ret i32 %s
}
