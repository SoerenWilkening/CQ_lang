; control_inplace_ry_stateprep_deep_chain.ll — ACCEPT, and it is the RED-GREEN
; for a BOUND that the round-3 fix DELETED.
;
; The round-2 forward walk was bounded at depth 8 / 64 values and DECLINED on
; exceeding either — conservative, and correct as far as it went, but the bound
; was reachable by ordinary arithmetic: round-3 lens R3 measured `bd_d09_mixed`
; and `bd_d11_mixed` (11-deep mixed chains off the condition register, seed
; 999999) and `b05_fanout70_seed999` (70 fan-out users) DECLINING on the bound
; alone, with NO member anywhere near the seed. Those were pure over-declines.
;
; The semantic form has no per-value depth bound at all: it is a FIXPOINT over
; the tainted user graph with one total step cap (`kF2MaxSteps`), so a long
; chain is EVALUATED rather than truncated. This file is the 11-deep chain,
; every member measured (so nothing can be DCE'd away), with a seed no member
; can reach — `h` is pinned to `{5}` on the arm edge, so the chain evaluates to
; 8, 40, 33, 97, 90, 270, 287, 298, 2086, 2119, 2132, and the seed is 999999.
;
; ⚠ WHAT IT DOES NOT SAY. A bound that never trips is not a bound that cannot
; trip: `kF2MaxSteps` still DECLINES on exceeding, for the same reason the old
; one did — a search that stopped looking is the "we stopped and accepted" shape
; the fence exists to stop. Nothing in the tree pins that path, because no
; measured program comes within two orders of magnitude of it; that is recorded
; in PRD §14.2b rather than pretended away.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %h = and i32 %q, 15
  %c = icmp eq i32 %h, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 999999, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 999999, %entry ]
  %a1 = add i32 %h, 3
  %a2 = mul i32 %a1, 5
  %a3 = xor i32 %a2, 9
  %a4 = or i32 %a3, 64
  %a5 = sub i32 %a4, 7
  %a6 = mul i32 %a5, 3
  %a7 = xor i32 %a6, 17
  %a8 = add i32 %a7, 11
  %a9 = mul i32 %a8, 7
  %a10 = xor i32 %a9, 33
  %a11 = add i32 %a10, 13
  %m1 = call i32 @cq_measure_si32(i32 %a1)
  %m2 = call i32 @cq_measure_si32(i32 %a2)
  %m3 = call i32 @cq_measure_si32(i32 %a3)
  %m4 = call i32 @cq_measure_si32(i32 %a4)
  %m5 = call i32 @cq_measure_si32(i32 %a5)
  %m6 = call i32 @cq_measure_si32(i32 %a6)
  %m7 = call i32 @cq_measure_si32(i32 %a7)
  %m8 = call i32 @cq_measure_si32(i32 %a8)
  %m9 = call i32 @cq_measure_si32(i32 %a9)
  %m10 = call i32 @cq_measure_si32(i32 %a10)
  %m11 = call i32 @cq_measure_si32(i32 %a11)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mr
}

; CHECK:      call i32 @cq_template_icmp_eq_i32_hl(
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 999999)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 {{.*}}, i32 %[[R]], double 9.000000e-01)

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
