; lowering_reject_stale_reader_sibling_theta.ll — DECLINE (bd
; test_C_libtooling-3d8q, P1). THE REPRODUCER, one line of plain C:
;
;   int q=0; cq_theta(&q,0.3); int b=q; cq_theta(&b,0.5); int c=q; cq_theta(&c,0.9);
;   return cq_measure(b)+cq_measure(c);
;
; `%b` and `%c` are two in-place Ry on ONE physical rail (`lowerRotations` RAUWs
; both to `%q`'s handle; `Chained = taint.Tainted.count(arg0)`), so the source
; names two DIFFERENT states of one register — a no-cloning request (Rule 8) and,
; under `docs/frontend.md` §3.2's linear rule, a read of a pre-gate value the
; compiler cannot prove executes before the gate.
;
; ⚠ WHY THIS IS THE PROJECT'S PUREST RULE-2 CASE, and why a green suite could
; never have caught it: on the pre-fix compiler it emitted
; `ry(.3); ry(.5); ry(.9); measure; measure` — BYTE-IDENTICAL to the stream of a
; DIFFERENT, well-formed program (`a=q; cq_theta(&a,.5); c=a; cq_theta(&c,.9);
; cq_measure(c)+cq_measure(c)`, the accept twin
; `lowering_stale_reader_chain_accept.ll`). `opt` exit 0, verify-clean, STRICT
; stage 2b `0 violation(s)`. The golden byte-diff proves every symbol resolves,
; never that the unitary is right.
;
; TWO readers here are stale and either alone is a decline — `%c` (a `cq_theta`
; reader whose sibling `%b` precedes it) and `cq_measure(%b)` (a `cq_measure`
; reader whose sibling `%c` precedes it). `%b` itself is NOT: it reads `%q`
; strictly before `%c` fires, which `gateIsHarmless` leg 1 proves (the accept
; boundary is `lowering_stale_record_add_before_theta.ll`'s, unchanged).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %b = call i32 @cq_theta_si32(i32 %q, double 5.000000e-01)
  %c = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %m1 = call i32 @cq_measure_si32(i32 %b)
  %m2 = call i32 @cq_measure_si32(i32 %c)
  %s = add i32 %m1, %m2
  ret i32 %s
}
