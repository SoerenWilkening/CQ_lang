; control_swap_reject_value_ifelse_readcond.ll — if/else fresh-value READ mux
; over the condition register declines GENERIC, never §3c (4.2 WI-3 hardening,
; §8 review 2026-06-10; the if/else analog of
; control_swap_reject_value_readcond.ll).
;
; `if (q > 5) { t = q + 1; } else { t = q + 2; }` — both arms READ the live
; condition register %q and compute fresh values; nothing is overwritten (%q
; stays live, the flag stays strippable). The if/else routed slot is anchored
; HEURISTICALLY from arm 1's chain base (there is no straight-through to prove
; identity against), so a provenance hit on the anchored base is mux-or-clobber
; evidence, not proof of a rewrite: the PERMANENT §3c string is reserved for
; the proven diamond identity, and this shape keeps the generic revisitable
; decline (the bd swap-route-detect-known-limits rule — a read must NEVER get
; the §3c string — applied structurally to the anchored-base path the retired
; readsProvenance fallback used to over-reject).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: arm rewrites a condition operand
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  %t1 = add i32 %q, 1        ; fresh value FROM the condition register
  br label %merge
else:
  %t2 = add i32 %q, 2        ; fresh value FROM the condition register
  br label %merge
merge:
  %tm = phi i32 [ %t1, %then ], [ %t2, %else ]
  %m  = call i32 @cq_measure_si32(i32 %tm)
  ret i32 %m
}
