; control_inplace_ry_reject_stateprep_range_forward_or.ll — DECLINE (F2, the
; RANGE clause reaching FORWARD: the pinned register is a USER of the compare's
; operand, not the operand itself).
;
; ⚠ A ROUND-2 RULE-13 FINDING, NOT A DESIGN ROW — one of the SIX plain-C
; spellings that ACCEPTED after the round-1 fix (round-2 review, lens R1 finding
; F-R1-1, CONFIRMED-MISCOMPILE, probe `p/y05_and_or.c`):
;
;     int q = cq_theta(3,0.3); int t = (q&1)|8; int r = 9;
;     if (t != 8) r = cq_theta(t, 0.9);
;     return (int) cq_measure(r) + (int) cq_measure(t);
;
; `ipsccp` proves the pin about the DERIVED register and substitutes it into the
; arm's `cq_theta`; a later `instcombine` rewrites the COMPARE down onto an
; ANCESTOR of that register, so the operand CQ is handed is not the register the
; theorem is about — which is a FORWARD USER of it, and which is ALIVE in the
; emitted circuit and MEASURED by the source while receiving no rotation at all.
; The round-1 fix widened F2's PREDICATE and kept F2's SET; this is the bd
; `8h7d.5` F-1/F-3 lesson a third time. The full mechanism, with the isolated
; `opt` pipelines that measured it and the unconditional control that fixes
; CQ's own reading of `cq_theta(t,θ)`, is written once in
; `..._range_forward_add.ll` and in the walk's header in `ArmClassify.cpp`.
;
; THIS FILE'S ALGEBRA: the `ne 0` edge pins `%t` to `{1}`, and `{1} | 8 = {9}` = the seed.
;
;
; ---- STILL A DECLINE AFTER THE 2026-09-11 NARROWING (bd `drbq.14`) ----
;
; F2 was narrowed on 2026-09-11 (owner ruling): a pinned value that lies on the
; CONDITION'S OWN BACKWARD WIRE — `CondWire` =
; `{Region.Condition} ∪ ⋃ railWireClosure(condProvenance(Region.Condition))` — is
; no longer a collider, and NINETEEN fixtures of this family flipped to ACCEPT
; (they are now `control_inplace_ry_stateprep_*`). **THIS ONE DID NOT, and the
; reason is not an accident:**
;
; the pinned value is a FORWARD USER of a cone member (``or %t, 8``), minted on a
; FRESH rail — there is no in-place ABI for that opcode — and `CondWire`
; is built `WireDir::BackwardOnly`, so a forward user is not in it. This is
; the F-R1-1 class: six CONFIRMED plain-C silent miscompiles, whose defect
; was precisely that `-O1` rewrote the compare DOWNWARD onto an ANCESTOR of
; the rotated register, so the backward walk from the compare can never
; reach it. Widening `CondWire` to `BothWays` would swallow all six.
;
; So the narrowing is the WIRE and nothing wider, and this file is one of the 21
; that prove it. Measured 2026-09-11 on the narrowed binary: rc=1, same string,
; same anchor.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %t = and i32 %q, 1
  %c = icmp eq i32 %t, 0
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 8, double 9.000000e-01)
  br label %merge
merge:
  %rm  = phi i32 [ %rt, %arm ], [ 8, %entry ]
  %fwd = or disjoint i32 %t, 8
  %mr  = call i32 @cq_measure_si32(i32 %rm)
  %mf  = call i32 @cq_measure_si32(i32 %fwd)
  %s   = add i32 %mr, %mf
  ret i32 %s
}
