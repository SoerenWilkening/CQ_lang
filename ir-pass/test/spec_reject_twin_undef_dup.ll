; spec_reject_twin_undef_dup.ll — DECLINE (bd xy9n).
; ARM: `findUndefOperandInBody` at `Specialization::synthUncomputeTwin`, the
; DUPLICATION fence — the second half of the bd xy9n fix, and the one the
; module-wide guard cannot do.
;
; *** THIS IS THE HOLE THE RULE-13 ROUND FOUND INSIDE THE FIX UNDER REVIEW. ***
; `declineUnpairedUndefLiterals` counts literal undef/poison SLOTS on emitted
; calls, so it is blind to an `undef` sitting ONE classical instruction ABOVE the
; slot. Here `%c = xor i32 undef, 7` is an Instruction, not a Constant, so the
; emitted `cq_template_mul_i32_hl(i32 %a, i32 %c)` carries no literal at all and
; the module-wide count is ZERO.
;
; That would be harmless — one register, read twice, same value — EXCEPT that
; `synthUncomputeTwin` builds the uncompute twin with
; `CloneFunctionInto(Twin, &Clone, …)`, which copies the body VERBATIM. So the
; computation is DUPLICATED and each copy reads `undef` independently. Measured on
; the pre-change plugin (`opt` exit 0, verify clean), the two bodies are:
;
;   define internal i32 @__cq_q_inner_1(i32 %a) {
;     %c = xor i32 undef, 7
;     %h_op = call i32 @cq_template_mul_i32_hl(i32 %a, i32 %c)
;     ...  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %a, i32 %c)
;   define internal void @__cq_q_inner_1_unc(i32 %out, i32 %a) {
;     %c = xor i32 undef, 7                      ; <-- an INDEPENDENT read
;     %h_op = call i32 @cq_template_mul_i32_hl(i32 %a, i32 %c)
;
; and the linked -O0 trace, identical across runs, reads
;
;   cq_template_mul_i32_hl(h0, 73903) -> h1      ; forward clone: undef=73896, ^7
;   ...
;   cq_template_mul_i32_hl(h0, 7)                ; TWIN: undef=0, ^7  *** DIFFERENT ***
;
; so the twin's `_unc` inverts a different multiplier than the clone's forward
; computed: the rail is left dirty AND entangled and the `cqrt_free` that follows
; is a hidden measurement. Rules 6 and 8.
;
; WHY THE FENCE IS HERE AND NOT IN THE COUNTING GUARD. `synthUncomputeTwin` is the
; ONLY place in the pass that re-materialises a whole gate-feeding COMPUTATION that
; a forward gate already read — everywhere else an adjoint copies the forward's
; OPERANDS, so both reads hit the same register. Widening the counting guard to
; "the argument is defined by an instruction with an undef operand" would instead
; over-decline every `clang -O1` dead-edge phi/select, taking
; `lowering_accept_undef_literal_single_slot.ll` and the whole
; `slice_libm_real_nexttoward` family with it, for no pairing gain. Guarding at the
; DUPLICATION is the exact parallel of bd 7udx's fence living at the ERASE.
;
; DERIVATION: this is `ir-pass/test/spec_accept_transitive.ll`'s body with EXACTLY
; ONE token changed — `%y = mul i32 %a, 7` becomes `%c = xor i32 undef, 7` /
; `%y = mul i32 %a, %c`. That fixture stays green and is this one's reach control.
;
; RED-GREEN: the pre-change plugin ACCEPTS this module (`opt` exit 0) and emits both
; duplicated bodies, so the decline below is genuinely new.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: undef/poison operand duplicated into the uncompute twin

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @inner(i32 %a) {
entry:
  %c = xor i32 undef, 7        ; undef-DERIVED, and an Instruction — not a literal
  %y = mul i32 %a, %c
  ret i32 %y
}

define i32 @outer(i32 %t) {
entry:
  %u = call i32 @inner(i32 %t)
  %r = add i32 %u, 1
  ret i32 %r
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @outer(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}
