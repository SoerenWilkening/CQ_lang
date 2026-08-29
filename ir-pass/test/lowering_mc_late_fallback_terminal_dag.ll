; lowering_mc_late_fallback_terminal_dag.ll — FALLBACK (M-C Increment 7a, bd
; test_C_libtooling-x67f). The site stays OUT OF PLACE; that is the existing
; lowering, not a decline (see _fallback_reader_after.ll's header).
;
; WHAT IT PINS: THE DEAD-TERMINAL SUPERSET WITHHELD FROM THE PLAN. The M-B
; interior partition and the dead-terminal spine are two owners of one rail set,
; and at emit the terminal groups run FIRST and hand the interior partition the
; `ReversedGates`/`ReversedRails` they actually claimed (Rule 8, single
; ownership). `planInteriorDischarges` runs BEFORE any of that, so it cannot see
; those sets; instead it recovers the whole DAG of EVERY terminal candidate and
; withholds every gate in it from `GateAt`.
;
; WHY THAT ASYMMETRY IS THE POINT. A mis-prediction inside the interior
; partition is self-limiting: the in-place gate this round emits is a MUTATION
; of a borrowed parent, so if the plan moves, clause (d) of
; `planInteriorComponent` refuses the component and it LEAKS — a kept rail, no
; adjoint, no dirty free. The dead-terminal spine has no clause-(d) scan; it
; places its adjoints at a post-dominating FreePoint. So a gate that spine might
; claim is never trusted here, even though — see below — no reachable miscompile
; was found through it.
;
; HERE: `%5 = a * 3` and `%6 = %5 * 5` are interior rails (each has a forward
; template consumer), the component's anchor lands before the subtraction, and
; arm (d2) would otherwise admit both. `%7 = %6 * 7` is a DEAD terminal, so the
; terminal spine's backward walk from it reaches `%5`'s and `%6`'s producers,
; and both are withheld. The subtraction stays out of place and the whole chain
; is reversed by the dead-terminal spine at the end instead.
;
; NO REACHABLE MISCOMPILE WAS FOUND THROUGH THIS FENCE, and saying so is part of
; the fixture. `recoverDataDag` enqueues every tainted operand of a recovered
; gate, so if a terminal DAG contains a gate reading the parent it also VISITS
; the parent and collects the parent's in-place gates — including the `cqrt_addc`
; this round would emit — and `emitDagReversal` walks one DAG in reverse program
; order, which adjoints the later `addc` before the earlier producer. That is
; arm (a)'s pre-existing argument, reached from the other side. The fence is
; kept anyway: it is two lines, over-declining is the safe direction, and the
; alternative is to rest a Rule-6 property on a cross-partition ordering
; coincidence (Rule 13's whole subject).
;
; NO RED STATE EXISTS on any earlier plugin. MEASURED MUTATION instead (bd
; memory [rule12-pins-without-a-red-state-2026-08-29]): dropping the withholding
; in `Uncomputation::planInteriorDischarges` —
;     if (!TermGates.count(G)) Plan.GateAt[G] = P.At;
;   → Plan.GateAt[G] = P.At;
; converts the subtraction here, and the terminal group's insertion point then
; falls between two of its own recovered gates, so the module declines LOUDLY
; with "cq uncompute: dead chain spans divergent control-flow arms" (rc 1, so
; both RUN lines fail). MEASURED, not predicted. The two sibling fallbacks stay
; green under that same mutation.
;
; HAND-WRITTEN, not `clang -O1` output: the shape needs a dead terminal whose
; last use sits between the chain and the site, and every C spelling of that
; either gets DCE'd or introduces a measurement that changes which fence fires.
; The IR is nonetheless in the pre-lowering form the pass really sees.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCONV < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define void @late_terminal_dag(i32 noundef %0, ptr noundef %1) {
  %3 = load volatile i32, ptr %1, align 4
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = mul nsw i32 %4, 3
  %6 = mul nsw i32 %5, 5
  %7 = mul nsw i32 %6, 7
  %8 = call i32 @cq_phi_si32(i32 noundef %7, double noundef 2.000000e+00)
  %9 = sub nsw i32 %4, %3
  %10 = call i32 @cq_phi_si32(i32 noundef %9, double noundef 4.000000e+00)
  ret void
}

; CHECK-LABEL: define void @late_terminal_dag(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[X:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[Y:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[X]], i32 5)
; CHECK-NEXT: %[[Z:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[Y]], i32 7)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[Z]], double 2.000000e+00)
; THE SITE, out of place: `%[[X]]`'s producer reads `%[[H]]` and is withheld
; from the plan because the dead-terminal spine can reach it from `%[[Z]]`.
; CHECK-NEXT: %[[SUB:.*]] = call i32 @cq_template_sub_i32_hl(i32 %[[H]], i32 %3)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[SUB]], double 4.000000e+00)
; the dead-terminal spine then reverses the whole thing in LIFO order, the
; subtraction rail included — which is what it is for.
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[SUB]], double -4.000000e+00)
; CHECK-NEXT: call void @cq_template_sub_i32_hl_unc(i32 %[[SUB]], i32 %[[H]], i32 %3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[SUB]])
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[Z]], double -2.000000e+00)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[Z]], i32 %[[Y]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[Z]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[Y]], i32 %[[X]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[Y]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[X]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H]])

; NOCONV-NOT: cqrt_addc_i32
; NOCONV-NOT: cqrt_xorc_i32
