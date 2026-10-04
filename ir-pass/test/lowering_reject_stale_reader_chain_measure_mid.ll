; lowering_reject_stale_reader_chain_measure_mid.ll — DECLINE (bd
; test_C_libtooling-3d8q, P1). A WELL-FORMED CHAIN whose MIDDLE name is measured:
;
;   int q=0; cq_theta(&q,0.3); int a=q; cq_theta(&a,0.125); int b=a; cq_theta(&b,0.25);
;   return cq_measure(a)+cq_measure(b);
;
; ⚠ THIS IS CLAUDE.md's OWN 8h7d.5 FINDING F-3 SHAPE ("`a` naming the pre-`b`
; register"), OUT OF LOOP — the in-loop spelling has declined since the Phase-7.3
; rail work at `LoopLowering::staleRailRecordRead`, which reasons over a
; LOOP-COLLAPSED rail chain only, so the loop-free spelling accepted on every
; shipped binary until bd 3d8q.
;
; The chain itself is fine and `cq_measure(%b)` (the TIP) is fine: `%q` and `%a`
; are on `%b`'s own backward ancestry and the walker exempts producers of the
; record. It is `cq_measure(%a)` that is stale — `%b` is a DESCENDANT, not an
; ancestor, and it fires before the measurement. Accept twin:
; `lowering_stale_reader_chain_accept.ll`, the same chain with only the tip read.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %a = call i32 @cq_theta_si32(i32 %q, double 1.250000e-01)
  %b = call i32 @cq_theta_si32(i32 %a, double 2.500000e-01)
  %m1 = call i32 @cq_measure_si32(i32 %a)
  %m2 = call i32 @cq_measure_si32(i32 %b)
  %s = add i32 %m1, %m2
  ret i32 %s
}
