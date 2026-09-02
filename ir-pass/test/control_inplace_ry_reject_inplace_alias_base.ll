; control_inplace_ry_reject_inplace_alias_base.ll — DECLINE, and R4's ONLY
; TRUE-POSITIVE fixture: the rotated base and the condition genuinely share ONE
; physical rail (round-1 Rule-13 review, lens L1 §1).
;
;     int q = cq_theta(u, .5);
;     (void)(q > 5);                 /* the compare, FIRST                    */
;     int b = q ^ 2;                 /* M-C lowers this IN PLACE on q's rail  */
;     if (q > 5) b = cq_theta(b, .9);
;
; WHY THIS FIXTURE EXISTS. Until the round-1 review, the ONLY committed R4
; fixture was `control_inplace_ry_reject_derived_base.ll`, and its own header
; says it is DELIBERATELY AN OVER-DECLINE ("M-C would in fact refuse this
; particular `add` — `%q` is read later — so the two rails really are disjoint
; here"). So the tree asserted that R4 declines a shape whose rails are
; DISJOINT, and asserted nothing about the shape R4 exists for.
;
; That gap is not hypothetical maintenance tidiness. `railWireClosure`'s
; `add`/`sub`/`xor` hop admits BOTH roots precisely because in-place-ness is
; decided by the M-C fence in `lowerOps`, long after detection (notes finding H,
; J′.3). A future narrowing of that hop to "only what M-C proves in place" —
; which J′.3 explicitly contemplates for Inc 2/3 — would keep the existing `add`
; fixture GREEN, since it is an over-decline whose whole point is that M-C
; refuses it, while silently admitting THIS module. That is the shape of every
; finding in this epic's history.
;
; THE PREMISE IS MEASURED, NOT ASSUMED. `control_inplace_ry_inplace_alias_witness.ll`
; is the control: the same `xor` with no region emits `cqrt_xorc_i32(%h, 2)` — IN
; PLACE — so `%b` really is `%q`'s rail. The compare is placed BEFORE the `xor`
; so M-C's "no data use of the parent after the reassignment" precondition holds.
;
; WITHOUT R4 the emitted stream would be
;     icmp_sgt_hl(h,5)->f; xorc(h,2); ry_i32_controlled(f,h,.9);
;     icmp_sgt_hl_unc(f,h,5); free(f)
; — the strip recomputes the predicate on a register the controlled Ry has just
; RELABELLED, so `f` does not return to |0> and `cqrt_free(f)` is a hidden
; measurement of an ancilla entangled with `q` (Rules 6/8, PRD §3).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error{{.*}}rotation arm on a condition wire under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %b = xor i32 %q, 2
  br i1 %c, label %arm, label %merge
arm:
  %bt = call i32 @cq_theta_si32(i32 %b, double 9.000000e-01)
  br label %merge
merge:
  %bm = phi i32 [ %bt, %arm ], [ %b, %entry ]
  %m = call i32 @cq_measure_si32(i32 %bm)
  ret i32 %m
}
