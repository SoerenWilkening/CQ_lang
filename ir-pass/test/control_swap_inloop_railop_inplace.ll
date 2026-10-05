; control_swap_inloop_railop_inplace.ll — ACCEPT, and the RED-GREEN FIXTURE FOR A
; SILENT MISCOMPILE THE FIRST DRAFT OF bd test_C_libtooling-8h7d.5 SHIPPED.
;
;     cq_theta(&q, .5); q += off;                 // the PRE-HEADER chain
;     for (...) { if (q == 5) cq_phi(PI);
;                 cq_theta(&q, -.5); q += off; cq_theta(&q, .5); }
;
; VERBATIM `clang -O1` output (`off` is `volatile`, so the offsets survive
; canonicalization and the immediate is a RUNTIME value — Rule 9).
;
; THE DEFECT. `collapseFlattenedLoopRails` RAUWs the loop-carried header phi to
; its ROOT MINT. The root is reached by PEELING through in-place gates, and a
; value self-update (`q += off`, issue dtzb) is one of them — so the peel walks
; STRAIGHT PAST `%3 = add %2, %1` and the collapse RAUWs every in-loop use to the
; PRE-OFFSET handle. Round 1 (`tryCaseA`) compensates by marking each such op into
; `taint.InPlaceRailOps`, which is what makes `lowerOps` emit the IN-PLACE
; `cqrt_addc_i32(h, imm)` rather than the out-of-place `cq_template_add_i32_hl`
; that mints a fresh rail. The first draft of round 2 collapsed WITHOUT marking:
; the add lowered out of place into a rail nothing read, and the whole loop
; computed on `q` where the source says `q + off`.
;
; IT WAS INVISIBLE TO EVERY OTHER GATE. `opt` exit 0, `opt -verify` clean, strict
; stage-2b free-pairing clean (the orphan rail is simply never freed, which Rule 6
; permits), and the golden byte-diff would have been "correct" against a golden
; regenerated from the broken build. The only outward sign was ONE M-A warning
; about a live derived record — i.e. the dead pre-offset handle. This fixture and
; tests/e2e/slice_control_grover_loop_offset.c are what make it loud.
;
; So the two CHECKs below are not decoration: `cqrt_addc_i32` present and
; `cq_template_add_i32_hl` ABSENT is the whole assertion. Delete the
; `InPlaceRailOps` marking from `collapseRailPhisIn` and this goes red.
;
; The phase arm lowers by kickback: flag minted from the icmp, one uncontrolled
; `cqrt_rz_i1(flag, PI)`, icmp `_unc` strip, one `cqrt_free` (the flag). No work
; rail, no `cqrt_cswap`.
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
; 30 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

@cq_off = global i32 3, align 4

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = load volatile i32, ptr @cq_off, align 4
  %3 = add nsw i32 %2, %1
  br label %6
4:                                                ; preds = %12
  %5 = tail call i32 @cq_measure_si32(i32 noundef %17)
  ret i32 %5
6:                                                ; preds = %0, %12
  %7 = phi i32 [ 0, %0 ], [ %18, %12 ]
  %8 = phi i32 [ %3, %0 ], [ %17, %12 ]
  %9 = icmp eq i32 %8, 5
  br i1 %9, label %10, label %12
10:                                               ; preds = %6
  call void @cq_phi(double 0x400921FB54442D18)
  br label %12
12:                                               ; preds = %10, %6
  %14 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef -5.000000e-01)
  %15 = load volatile i32, ptr @cq_off, align 4
  %16 = add nsw i32 %15, %14
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 5.000000e-01)
  %18 = add nuw nsw i32 %7, 1
  %19 = icmp eq i32 %7, 0
  br i1 %19, label %6, label %4
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
; CHECK: define i32 @slice() {
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[V1:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @cq_off, align 4
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[V1]])
; CHECK-NEXT: br label %3
; CHECK: 2:                                                ; preds = %3
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
; CHECK: 3:                                                ; preds = %3, %0
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = phi i32 [ 0, %0 ], [ %6, %3 ]
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: %[[V5:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @cq_off, align 4
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[V5]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[V6:[a-zA-Z0-9_.]+]] = add nuw nsw i32 %[[V4]], 1
; CHECK-NEXT: %[[V7:[a-zA-Z0-9_.]+]] = icmp eq i32 %[[V4]], 0
; CHECK-NEXT: br i1 %[[V7]], label %3, label %2
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
; NOROUTE-NOT: cq_template_add_i32_hl
; NOROUTE-NOT: call void @cqrt_cswap

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 1 and 1 here.
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
