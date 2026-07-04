; control_classical_call_arm_reject_onward_spec_qqcmp.ll — DECLINE (bd 0vvq Increment 2,
; the re-plan's Q+Q-COMPARE boundary; surfaced by the Rule-13 adversarial review). A 6.5
; classical-call arm's `%out` feeds a Phase-6 candidate `@cmpf` whose body compares its
; TWO parameters (`icmp slt %a, %b`). At round 1 the merge is untainted, so `%out` is a
; classical arg (mask `0b01`) and the compare lowers `_hl` (width recovered from the
; classical operand). The round-2 re-plan grows the mask to `0b11`, so BOTH compare
; operands become tainted handles — a Q+Q compare, whose logical width is UNRECOVERABLE
; from two i32-laundered handles (CompareLowering.cpp:101-112, the pre-existing
; `lowering_icmp_qq_no_width_reject` limitation — the result is an i1, unlike a binary op
; whose result type carries the width). So the specialization DRIVER's `lowerOps` over the
; clone body loud-declines it (`no template for opcode 'icmp i1' in tainted context`).
;
; This is SAFE (Prime Directive): opt exits non-zero, the module is discarded, NO wrong
; unitary. The decline is BYTE-IDENTICAL to a ROUND-1 mask-`0b11` compare candidate
; (`@cmpf(q1, q2)` with two theta handles) — the re-plan reaches the SAME pre-existing
; boundary, not a new one; it just surfaces late (naming the clone `@__cq_q_cmpf_11`).
; Moving this decline earlier (a mask-AWARE source-located pre-check shared with detection)
; is tracked follow-on bd test_C_libtooling-6o60 (0vvq §9.2). scanBody accepts the compare mask-INDEPENDENTLY
; (compareInScope only), which is why the wider mask reaches here rather than declining at
; re-plan classification.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}no template for opcode 'icmp i1' in tainted context
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0

; a visible pure body that COMPARES its two parameters — Q+Q icmp when both are tainted.
define i32 @cmpf(i32 %a, i32 %b) {
entry:
  %c = icmp slt i32 %a, %b
  %z = zext i1 %c to i32
  %r = add i32 %z, %a
  ret i32 %r
}

define void @example(i32 %u0, i32 %aa) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %cc = icmp sgt i32 %q, 3
  br i1 %cc, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %aa)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %z = call i32 @cmpf(i32 %q, i32 %y)    ; re-plan 0b01 -> 0b11 -> Q+Q icmp in the clone
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }
