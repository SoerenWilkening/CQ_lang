; spec_reject_twin_undef_dup_scratch.ll — DECLINE (bd xy9n, kept alive by bd 3p2a).
; ARM: `findUndefOperandInBody` at `Specialization::ensureTwin` — THE ONLY ROW
; THAT STILL REACHES IT after the bd 3p2a return-cone fence landed in front of it,
; and the row that pins its PLACEMENT (this module pre-supplies the twin, so a
; fence inside `synthUncomputeTwin` would be short-circuited past).
;
; *** THIS FILE PINS AN OVER-DECLINE, AND SAYS SO UP FRONT. *** Its three sibling
; rows (spec_reject_twin_undef_dup{,_pretwin,_transitive}.ll) all carry the undef
; into the RETURNED value, which bd 3p2a now refuses at the specialization accept
; predicate — earlier, and before any clone is minted. Here the undef feeds only a
; SCRATCH gate and the return cone (`%r = add i32 %a, 1`) is clean, so the 3p2a
; fence passes and `ensureTwin` is genuinely reached.
;
; THE MEASUREMENT, taken with the twin fence armed OFF, because a fixture that
; claims a harm it cannot show is worse than no fixture. Linked at the shipped -O0
; stage 3 and run twice (byte-identical output, so not an ASLR artefact), the two
; bodies DO read two different materialisations of the same `undef`:
;
;   cq_template_mul_i32_hl(h0, 73903) -> h1     ; forward clone
;   cq_template_mul_i32_hl_unc(h1, h0, 73903)   ; ... and its own adjoint
;   cq_template_mul_i32_hl(h0, 7)     -> h6     ; TWIN  *** DIFFERENT ***
;   cq_template_mul_i32_hl_unc(h6, h0, 7)       ; ... and its own adjoint
;
; and the out rail IS NEVERTHELESS CORRECTLY ZEROED: the twin un-copies via the
; recomputed RETURN value (`add(h0,1)`), which does not touch `%c`, so
; `cqrt_copy_i32(h7, h3)` cancels `cqrt_copy_i32(h2, h3)` exactly. Each `mul` pair
; is self-inverse WITHIN its own body. No dirty rail, no hidden measurement — the
; divergence here is harmless.
;
; SO WHY DECLINE IT. Because `undef` gives NO guarantee that two dynamic reads
; agree, the harmlessness above is a property of THIS body shape rather than of the
; construct, and this project has already retracted one "they agreed in the probe
; I ran" argument (the falsified "one slot is one materialisation", measurably
; wrong inside a rolled loop — one static slot, six reads, two values). Over-
; declining is the safe direction; the zero measured population is the one carried
; over from spec_reject_twin_undef_dup_transitive.ll's own header (966 fixtures +
; 257 e2e stage-1 modules + 251 openlibm modules), not a fresh measurement of this
; shape.
;
; WHY THE FENCE IS NOT DELETED NOW THAT bd 3p2a COVERS THE HARMFUL CELL. Removing
; a fence because a different one happens to cover its measured population is an
; accept WIDENING, and shipping one inside a tightening commit is precisely what
; bd ajw7 exists to remember. This row is what keeps it from being dead code with
; no reaching fixture (Rule 12) while that decision waits for its own review.
;
; DERIVATION: spec_reject_twin_undef_dup.ll's body with ONE line added —
; `%r = add i32 %a, 1` — and the `ret` retargeted to it, so the undef-fed `mul`
; becomes scratch. The pre-supplied `@__cq_q_inner_1_unc` is carried over from
; ..._pretwin.ll unchanged in role: it short-circuits `ensureTwin`, so this row
; fails if the fence is moved back inside `synthUncomputeTwin`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: undef/poison operand duplicated into the uncompute twin

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)

define i32 @inner(i32 %a) {
entry:
  %c = xor i32 undef, 7        ; undef-DERIVED, and an Instruction — not a literal
  %y = mul i32 %a, %c          ; SCRATCH: never returned, never copied out
  %r = add i32 %a, 1           ; the returned value — a CLEAN cone
  ret i32 %r
}

define i32 @outer(i32 %t) {
entry:
  %u = call i32 @inner(i32 %t)
  %r = add i32 %u, 1
  ret i32 %r
}

; Pre-supplied twin — the `ensureTwin` short-circuit this row pins the placement
; against. Its body is irrelevant to the short-circuit (only "a definition of that
; name exists" matters); it mirrors the real one for readability.
define internal void @__cq_q_inner_1_unc(i32 %out, i32 %a) {
entry:
  %c = xor i32 undef, 7
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %a, i32 %c)
  %h_op1 = call i32 @cq_template_add_i32_hl(i32 %a, i32 1)
  call void @cqrt_copy_i32(i32 %h_op1, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op1, i32 %a, i32 1)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %a, i32 %c)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  ret void
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @outer(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}
