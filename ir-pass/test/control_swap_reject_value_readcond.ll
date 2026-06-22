; control_swap_reject_value_readcond.ll — fresh-value mux READING the condition
; register declines as a `non-routable value multiplexer`, NEVER the §3c string
; (4.2 WI-3; PRD Part II §8.3: "p=q+1 must NEVER get the §3c string" — the bd
; memory swap-route-detect-known-limits warning, honored structurally). The
; dedicated mux string is Phase 7.2 Inc 1 / 65wb.1 (was generic `control flow`).
;
; `if (q > 5) { p = q + 1; }` — the arm READS the condition register %q and
; writes a fresh value muxed against the unrelated straight-through %p. Reading
; q does not clobber it (q stays live, the flag is strippable), so §3c does not
; bind; but the chain bottoms at %q, not at the routed slot %p
; (`ChainBase != Routed`), so the region is not routable either — it is a data
; mux of the 4.4 select family. The §3c framing is structurally unreachable
; here: the base-identity test fires first. This pin is the regression guard
; against re-introducing a readsProvenance-style §3c test (which would wrongly
; permanent-reject this legitimate read).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}non-routable value multiplexer under quantum control
; CHECK-NOT: arm rewrites a condition operand
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %p1 = add i32 %q, 1        ; reads the CONDITION register; bottoms at %q != %p
  br label %merge
merge:
  %pm = phi i32 [ %p1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
