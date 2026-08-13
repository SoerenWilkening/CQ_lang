; control_swap_diamond_after_classical_lift.ll — ACCEPT: the lift/region
; COMPOSITION (test_C_libtooling-1k0q). A classical-condition ONE-REGISTER lift
; and a separate tainted-condition PHASE-arm diamond, sequenced in ONE function:
;
;     q = cq_theta(...);                         // base wire
;     if (classical_c) q = cq_phi(q, 0.25);      // classical lift  (region 1)
;     if (q > 5)       { rz(q,a); rz(q,b); }     // tainted phase   (region 2)
;     measure(q);
;
; This pins the lift/region ORDERING interaction that was previously cleared only
; analytically + by an ad-hoc adversarial probe (Rule-13 re-clearance LENS C,
; 2026-06-11): in the pass, `lowerControlRegions` (SwapRouteEmit) runs BEFORE the
; `declineClassicalMuxes` one-register lift. So region 2 is emitted FIRST while
; the classical merge phi `%p` is still live and IS the swap-route's routed base
; — the cswap/icmp_inv calls are minted against `%p`. The lift then RAUWs `%p` to
; its wire base `%q` and erases the phi; rotation lowering finally RAUWs `%q` to
; the `i32` handle `%h`. A THREE-stage RAUW chain (phi → wire base → handle) the
; emitted region stream must survive intact — the precise hazard this fixture
; guards (Rule 9: never cache value identity across a mutation).
;
; Correctness (Rule-13 trace reasoning, no controlled gates):
;   * Region 1 is CLASSICAL — per shot exactly one path runs; the lift moves NO
;     gate, only the SSA renaming phi disappears, so `cqrt_rz(h,0.25)` fires iff
;     `classical_c` (it stays INSIDE arm1). [[phi-select-onereg-lift-asymmetry]]
;   * Region 2 is a PHASE arm: route q into a |0> rail, run the Rz gates VERBATIM/
;     UNCONTROLLED, route back (phi = adjoint of the split, same %flag), free the
;     |0> rail, then strip the boolean with the UNCONTROLLED icmp_inv(q) — q's
;     basis value is unchanged by Rz (diagonal), so the strip is exact. ZERO
;     controlled gates, ZERO copies (method-B on a phase arm dephases — Rule 7).
;   * The two regions only SHARE the wire %h; region 1's conditional Rz(0.25) has
;     completed before region 2 reads %h, and the flag strip reads %h's (unchanged)
;     basis label — no cross-region interference.
;
; The lift erases region 1's merge phi AND RegionFlatten erases region 2's merge
; phi: NO `phi i32` survives, no `@cq_theta`/`@cq_phi` remains, the cswap route
; (region 2) AND the lifted Rz (region 1) are BOTH present, and the module is
; verify-clean. Both mechanisms are covered standalone by the e2e goldens
; (classical-if-gate, control-phase-diamond) + lit twins
; (lowering_classical_mux_phi_onereg.ll, control_swap_diamond.ll); this is the
; composition guard. See [[lift-stale-reseep-must-be-full-not-scoped-2qyz]] for
; the post-lift stale re-sweep that this clean (no add/mul/cast) shape no-ops.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; Independent EXACT free-count scan (§8.2): two cqrt_free (rail + flag), no third.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 7, double 5.000000e-01)
  br i1 %c, label %arm1, label %merge1           ; CLASSICAL condition (region 1)
arm1:
  %q2 = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)
  br label %merge1
merge1:
  %p = phi i32 [ %q2, %arm1 ], [ %q, %entry ]    ; one register, two SSA names
  %tc = icmp sgt i32 %p, 5                        ; TAINTED condition (region 2)
  br i1 %tc, label %arm2, label %merge2
arm2:
  %q3 = call i32 @cq_phi_si32(i32 %p,  double %a)
  %q4 = call i32 @cq_phi_si32(i32 %q3, double %b)
  br label %merge2
merge2:
  %qm = phi i32 [ %q4, %arm2 ], [ %p, %merge1 ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; Base wire: alloc + Ry in entry.
; CHECK:      call i32 @cqrt_alloc_i32(i32 7)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H:[a-zA-Z0-9_.]+]], double 5.000000e-01)
; Region 1 (classical lift): the gate stays INSIDE arm1 on the base handle — it
; fires iff the classical branch is taken; the renaming phi is GONE.
; CHECK:      arm1:
; CHECK-NEXT:   call void @cqrt_rz_i32(i32 %[[H]], double 2.500000e-01)
; Region 2 (tainted phase diamond, flattened into merge1): mint the flag from the
; tainted icmp, then route q into a |0> work rail.
; CHECK:      merge1:
; CHECK-NEXT:   %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK:        %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:        call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[T]])
; arm body: VERBATIM, UNCONTROLLED Rz gates on the routed rail.
; CHECK:        call void @cqrt_rz_i32(i32 %[[T]], double %a)
; CHECK:        call void @cqrt_rz_i32(i32 %[[T]], double %b)
; route the active result back (adjoint of the split, same %flag), free |0> rail.
; CHECK:        call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[T]])
; CHECK:        call void @cqrt_free(i32 %[[T]])
; strip the boolean: q==q0, so icmp_inv(q) returns the flag to |0>; reclaim it.
; CHECK:        call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:        call void @cqrt_free(i32 %[[F]])
; q (not a phi) is measured — both merge phis RAUW'd away.
; CHECK:        call i32 @cqrt_measure_i32(i32 %[[H]])
; Both merge phis erased (lift + RegionFlatten); all intrinsics gone.
; CHECK-NOT:  phi i32
; CHECK-NOT:  cq_theta_si32
; CHECK-NOT:  cq_phi_si32
; Dephasing guard: a phase arm uses ZERO controlled gates / copies.
; CHECK-NOT:  _controlled
; CHECK-NOT:  cqrt_copy

; Exact free count — two (work rail + flag), no third anywhere (no spurious free
; from the uncompute pass, which would be a hidden measurement collapsing q).
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
