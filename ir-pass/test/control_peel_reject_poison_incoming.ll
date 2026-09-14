; control_peel_reject_poison_incoming.ll — DECLINE `control flow` (bd
; test_C_libtooling-b6ap, P3b / SCOPE H-9): the data mux's pred incoming is a
; LITERAL `poison`. NOT PEELED.
;
; The explicit `poison` half of P3b's one `isa<UndefValue>` test (`PoisonValue`
; derives from `UndefValue`; `control_peel_reject_undef_incoming.ll` is the `undef`
; half). A peel would put the literal into a `select` arm and thence into TWO
; emitted gate slots — the controlled copy and its `_unc` — which is exactly the
; population `LiteralIntegrity`'s guard 1 counts: at the `-O0` stage-3 link the two
; slots may read as two DIFFERENT values, so the adjoint stops inverting its forward
; (Rules 6, 8). Refusing is the decline-keeping option.
;
; ⚠ IT IS ONE TOKEN FROM AN ACCEPT. `control_peel_freeze_incoming.ll` is this exact
; module with a `%frz = freeze i32 poison` named in the phi instead — and it PEELS,
; soundly, because a `freeze` is SINGLE-VALUED BY DEFINITION, which is the very
; property guard 1 counts. The pair is the measurement behind the P3b comment
; (Rule-13 round-1 review, DOC item); probes `x02_poison_incoming.s1.ll` /
; `x03_freeze_incoming.s1.ll`.

; ⚠ RETIREMENT TRIGGER (bd `z9t1`, review round 2 F-U2-2 / round 3 F-U3-2 — DO
; NOT DELETE THIS FIXTURE, RE-DERIVE IT). `normalizeUndefRotationSeed`
; (`RotationLowering.cpp`) rewrites every `UndefValue` incoming of every phi that
; carries a normalized `@cq_theta_*` result to the type's zero, BEFORE
; `MergePhiPeel` runs. *** THE ONLY REASON THIS FIXTURE IS UNTOUCHED IS THAT ITS
; POISON-BEARING PHI `%6` DOES NOT CARRY A THETA *** — the theta-carrying phi in
; this module is `%7`, and it has no poison incoming. It is NOT a scope narrowing
; in z9t1; the two shapes simply miss each other.
;
; MAKE `%6` CARRY THE THETA AND P3b STOPS FIRING: the incoming is a concrete
; `i32 0` by the time the peel looks, the peel proceeds, and the module reaches
; F2 instead (measured on both binaries; the zero twin is identical — probes
; `$SES/trackU/review_r3_probes/pC_p3b_carrier*` and
; `$SES/trackU/review_r2_probes/pC_peel_p3b_carrier.ll`). That disarm is SOUND on
; P3b's OWN ground, and it is the SAME ground this header already gives for the
; `freeze` twin above: the hazard is a literal read as two DIFFERENT values at the
; `-O0` stage-3 link, and a uniqued `i32 0` is single-valued exactly as a `freeze`
; is. So the disarm and the removal of the hazard are the same event.
;
; If this fixture ever goes RED, do not "fix" it by narrowing z9t1: check first
; whether the module's poison phi has acquired a theta incoming, in which case the
; verdict legitimately moved and this file must be re-derived onto a phi that
; still carries no theta.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout — the `not` inversion on the RUN
; line plus the mirrored string is what pins it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

define i32 @example()  {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %5, label %3

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ 5, %3 ], [ poison, %0 ]
  %7 = phi i32 [ %4, %3 ], [ 0, %0 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %10 = add nsw i32 %9, %8
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %12 = add nsw i32 %10, %11
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: control flow under quantum control
