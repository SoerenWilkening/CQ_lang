; control_swap_reject_value_ifelse_qq_readcond.ll — no-hint Q+Q threading on an
; if/else first arm must not escalate a READ to the §3c string (4.2 WI-3
; hardening; the §8 review probe, 2026-06-10).
;
; `if (q > 5) { t = q + p; } else { t = p; }` — the then-arm only READS %q (a
; Q+Q link computing a fresh value; nothing is overwritten). On an if/else
; FIRST arm there is no routed hint, so the QQ walk threads operand 0 (= %q)
; and anchors it as the routed slot — heuristic, not proof. The provenance hit
; on that anchored base therefore declines GENERIC `control flow` (before the
; QQ defer is even consulted), never the PERMANENT `arm rewrites a condition
; operand` (the Defect-2 lesson inverted: never brand a deferrable/mux shape
; information-theoretically impossible on unproven evidence). Contrast:
; control_swap_value_reject_clobber_qq.ll — the DIAMOND `q=q+p`, where the
; straight-through PROVES the rewrite and §3c rightly fires.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: arm rewrites a condition operand
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  %t1 = add i32 %q, %p       ; Q+Q READ of the condition register
  br label %merge
else:
  br label %merge
merge:
  %tm = phi i32 [ %t1, %then ], [ %p, %else ]
  %m  = call i32 @cq_measure_si32(i32 %tm)
  ret i32 %m
}
