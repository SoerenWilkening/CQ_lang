; spec_accept_undef_outside_return_cone.ll — ACCEPT (bd 3p2a).
; ARM: the SCOPE of `returnDerivesFromUndef` — the RETURN CONE, never the body.
;
; *** THIS FILE PINS THE SCOPE, AND THE SCOPE IS THE ONE THING ABOUT bd 3p2a THAT
; A FIRST DRAFT GOT WRONG. *** That draft claimed the return-cone scope leaves
; `Specialization::ensureTwin`'s `findUndefOperandInBody` fence (bd xy9n) untouched.
; It does not: all three of that fence's rows carry their `undef` into the RETURNED
; value, so bd 3p2a declines them earlier. What the scope actually buys is narrower
; and worth pinning on its own — the fence does NOT reach DEAD and SCRATCH body
; positions, whose divergence between a clone and its twin is measurably
; self-cancelling (see spec_reject_twin_undef_dup_scratch.ll for that measurement).
; Widening this check to "any body instruction has an undef/poison operand" would
; therefore add only over-declines on top of a real fix, and would leave the twin
; fence with no reaching fixture at all (Rule 12). This file is the accept-side pin
; on that boundary.
;
; The division of labour after bd 3p2a, with every cell owned:
;   * a literal in an emitted GATE SLOT      -> declineUnpairedUndefLiterals
;                                               (bd xy9n guard 1, threshold 2)
;   * a literal reaching the RETURNED VALUE  -> returnDerivesFromUndef (bd 3p2a) —
;                                               the twin's un-copy channel, and the
;                                               only cell where a divergence leaves
;                                               a dirty rail
;   * a literal in a DEAD or SCRATCH body
;     position, duplicated into the twin     -> findUndefOperandInBody (bd xy9n),
;                                               retained as defence in depth
;
; The `%dead` xor below is in NONE of those cells: it feeds no gate (it is not
; param-derived, so it never enters the clone taint and `lowerOps` leaves it as a
; stock classical `xor`), it is not in the return cone, and in THIS module it is
; not duplicated — the clone is top-level and the wrap reverses it in place. It is
; dead classical UB the source is entitled to write, and it survives verbatim into
; the clone.
;
; *** DO NOT UPGRADE THAT LAST CLAUSE INTO A SAFETY PROPERTY. An earlier draft
; licensed this accept with "this clone is TOP-LEVEL, so no twin is synthesized",
; and the Rule-13 round showed nothing in the pass enforces it. *** `ensureTwin`
; — and hence every literal-integrity fence inside it — is reached from exactly
; ONE site, inside `buildClone`'s inner-call drain, while `EmitInverse` mints an
; `@__cq_q_<f>_<mask>_unc` CALL for ANY `__cq_q_`-prefixed forward. Change ONE
; token in the module below — replace the `cq_measure` with a dead source-derived
; `add`, so the whole-DAG spine reverses the clone call — and `opt` still exits 0
; while emitting a call to an UNDEFINED `@__cq_q_leaf_1_unc` with the
; poison-bearing body right there and no fence run at all (stage 2b passes it too;
; only the stage-3 LINK catches it). That gap is IR-only in reach and is filed as
; its own ticket. What licenses THIS row is the narrow, checked fact above — the
; `%dead` xor is outside the return cone — not a claim about twins.
;
; GREEN ON BOTH PLUGINS. Like every control, it is absent from the BASE-vs-SHIP
; differential; its power is arm-kill — replace the return-cone walk with a
; body-wide scan and THIS file goes red while every `spec_reject_ret_*` row stays
; green.
;

; NOTE ON THE NEGATIVES BELOW. A `CHECK-NOT` for a cq DIAGNOSTIC would be VACUOUS
; here and is deliberately absent: this RUN line pipes only the OUTPUT FILE into
; FileCheck, and every `DiagnosticInfoUnsupported` goes to STDERR, so such a
; pattern could never match and would pin nothing. (Measured; and it is a tree-wide
; pattern — 51 of the 73 fixtures carrying such a line do not pipe stderr.) The
; accept assertion is carried by cq-opt's EXIT CODE, which an un-inverted run line
; already requires, plus the positive CHECKs. (Do not spell either directive token
; in this prose: lit and FileCheck parse them out of comments — that is what turned
; this block into a shell syntax error the first time it was written.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 %a) {
entry:
  %dead = xor i32 poison, 7     ; UB, dead, and outside the return cone
  %y = mul i32 %a, 3
  ret i32 %y
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @leaf(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}

; The clone is minted and Bennett-wrapped; the dead undef-bearing xor rides along
; as ordinary classical UB; nothing declines:
; CHECK:     define internal i32 @__cq_q_leaf_1
; CHECK:       %[[Y:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK:       call void @cq_template_mul_i32_hl_unc(i32 %[[Y]], i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
