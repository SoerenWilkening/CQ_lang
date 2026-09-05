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
; the classical merge phi `%p` is still live and IS the region's gated base
; — the controlled-Rz/icmp_inv calls are minted against `%p`. The lift then RAUWs `%p` to
; its wire base `%q` and erases the phi; rotation lowering finally RAUWs `%q` to
; the `i32` handle `%h`. A THREE-stage RAUW chain (phi → wire base → handle) the
; emitted region stream must survive intact — the precise hazard this fixture
; guards (Rule 9: never cache value identity across a mutation).
;
; Correctness (Rule-13 trace reasoning, no controlled gates):
;   * Region 1 is CLASSICAL — per shot exactly one path runs; the lift moves NO
;     gate, only the SSA renaming phi disappears, so `cqrt_rz(h,0.25)` fires iff
;     `classical_c` (it stays INSIDE arm1). [[phi-select-onereg-lift-asymmetry]]
;   * Region 2 is a PHASE arm: under the §6a control-in-place peephole each arm Rz
;     is emitted as one `cqrt_rz_i32_controlled(flag, q, ·)` on the register itself
;     — no |0> work rail, no CSWAP route — and the boolean is then stripped with the
;     UNCONTROLLED icmp_inv(q); q's basis value is unchanged by Rz (diagonal), so
;     the strip is exact. ZERO copies (method-B on a phase arm dephases — Rule 7).
;   * The two regions only SHARE the wire %h; region 1's conditional Rz(0.25) has
;     completed before region 2 reads %h, and the flag strip reads %h's (unchanged)
;     basis label — no cross-region interference.
;
; The lift erases region 1's merge phi AND RegionFlatten erases region 2's merge
; phi: NO `phi i32` survives, no `@cq_theta`/`@cq_phi` remains, the controlled arm
; gates (region 2) AND the lifted Rz (region 1) are BOTH present, and the module is
; verify-clean. The two are distinguishable by SYMBOL — the lifted region-1 gate is
; the UNCONTROLLED `cqrt_rz_i32` still inside `arm1`, the region-2 gates are
; `cqrt_rz_i32_controlled` in `merge1` — which is exactly the ordering/RAUW property
; the fixture exists to pin. Both mechanisms are covered standalone by the e2e goldens
; (classical-if-gate, control-phase-diamond) + lit twins
; (lowering_classical_mux_phi_onereg.ll, control_swap_diamond.ll); this is the
; composition guard. See [[lift-stale-reseep-must-be-full-not-scoped-2qyz]] for
; the post-lift stale re-sweep that this clean (no add/mul/cast) shape no-ops.
;
;
; 3qlq(prep_a2): the FileCheck assertions below were RE-DERIVED from this
; fixture's own output under the Inc-1 (register-free `void @cq_phi(double)`)
; binary.  The pre-Inc-1 pin — a `cqrt_rz_<W>` or `cqrt_rz_<W>_controlled` on
; the user's REGISTER — asserted the gate PRD §1 shows is the identity on the
; marked branch (`cqrt_rz_<W>` is TENSORED, so a routed W-bit Rz applies
; `(-1)^popcount(target)` and can never mark |0..0>).  The stream now pinned is
; the KICKBACK: the flag is minted into a |0> ancilla, the phase lands on the
; FLAG with an UNCONTROLLED `cqrt_rz_i1`, the ordinary compare `_unc` returns
; the flag to |0> on every branch, and the flag is freed.  The fixture's
; PURPOSE (its header above) is unchanged.
;
; ORIGINAL negatives REMOVED.  Each was MEASURED to fire on this fixture's
; own Inc-1 output, so keeping it would assert something false.  A `-NOT`
; that used to sit AFTER a positive of its prefix was WINDOWED to the text
; past that positive; re-measuring it whole-file is a strictly stronger
; question, and where the pattern is one of the counted ones the
; `-COUNT-n` + `-NOT` pair below pins `exactly n` — stronger than the
; window it replaces, not weaker.
;   * call void @cqrt_rz_i1(   [superseded by the ACNT count]
;   * call void @cqrt_free(   [superseded by the FCNT count]
;   * !cq.branchphase
;
; NOTE — the header above still NAMES a retired symbol (`cqrt_rz_<W>`,
; `cqrt_cswap` or a `_controlled` twin).  That prose is kept DELIBERATELY:
; it is the fixture's PURPOSE and the record of what the pre-Inc-1 pass
; emitted here.  Read it as history; the stream this file now ASSERTS is
; the derived one below, and the two are meant to differ.
;
; 30 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 7, double 5.000000e-01)
  br i1 %c, label %arm1, label %merge1           ; CLASSICAL condition (region 1)
arm1:
  br label %merge1
merge1:
  %p = phi i32 [ %q, %arm1 ], [ %q, %entry ]    ; one register, two SSA names
  %tc = icmp sgt i32 %p, 5                        ; TAINTED condition (region 2)
  br i1 %tc, label %arm2, label %merge2
arm2:
  call void @cq_phi(double %a)
  call void @cq_phi(double %b)
  br label %merge2
merge2:
  %m  = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; ===========================================================================
; THE EMITTED STREAM, IN ORDER — DERIVED from this fixture's own pass output
; (prep_a2, bd test_C_libtooling-3qlq Inc 1).  Every `%name` below is bound at
; its DEFINITION and referenced afterwards, so the chain asserts operand
; IDENTITY — the strip and the free name the SAME flag the mint produced
; (bd 8txa: the golden itself must witness the pairing).  Handle names are
; DERIVED, never typed (bd drbq Inc 4: 9 of 20 accepts named a %h1 the pass
; never emits).  Trailing `!cq.branchphase` metadata is stripped here because
; its NUMBER is LLVM's, not ours; its presence and count are MDCNT's job.
; CHECK: define i32 @main(i32 %u0, i1 %c, double %a, double %b) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: br i1 %c, label %arm1, label %merge1
; CHECK: arm1:                                             ; preds = %entry
; CHECK-NEXT: br label %merge1
; CHECK: merge1:                                           ; preds = %arm1, %entry
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double %a)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double %b)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M1]]
; CHECK-NEXT: }

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE.  No positive directive may enter this prefix: a
; positive WINDOWS every negative after it, which is how an injected gate
; escaped 20 of 20 blocks in bd drbq Inc 3 (F-L6-1) and again in Inc 4.
; NOROUTE-NOT: cqrt_cswap
;   ^ the swap route is retired — no work rail, so no Fredkin
; NOROUTE-NOT: cqrt_copy
;   ^ method-B copy on a phase arm dephases the answer (Rule 7)
; NOROUTE-NOT: _controlled
;   ^ the kickback gate is UNCONTROLLED, on the flag ancilla
; NOROUTE-NOT: call void @cqrt_rz_{{[a-z0-9]+}}_controlled(
;   ^ ⚠ NARROW TWIN of the blanket `_controlled` above, and it exists because the blanket one is DROPPED from any fixture that legitimately emits a controlled Ry or a controlled copy — and dropping it took the only catch for a controlled Rz with it. MEASURED: 4 of the 104 re-derived accepts were BLIND to an injected `cqrt_rz_i32_controlled` — the exact pre-Inc-1 TENSORED gate this increment removes — until this line was added. The width complement above cannot cover it either: it requires `(` immediately after the width, and `cqrt_rz_i32_controlled(` has `_controlled` in between.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
;   ^ the TENSORED per-register Rz is the defect this increment removes (PRD §1). ONE complement pattern, not an enumeration of six — the shipped ABI has NINE widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block (round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
; NOROUTE-NOT: call void @cq_phi(
;   ^ a surviving phase call is lowered or deleted, never left for the linker
; NOROUTE-NOT: cq_phi_
;   ^ the register form is a RESERVED NAME and declines (round-1 F-L6-1)

; Original negatives PRESERVED (re-measured on the Inc-1 output):
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: cq_theta_si32
; NOROUTE-NOT: cq_phi_si32
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 2 and 2 here.
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
