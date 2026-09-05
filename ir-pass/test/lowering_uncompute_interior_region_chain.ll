; lowering_uncompute_interior_region_chain.ll — ACCEPT, and bd
; test_C_libtooling-6uqc's P0 CLOSED (M-B Increment 6, clause (d2); renamed from
; lowering_uncompute_interior_region_partial.ll, which pinned the seam).
;
;     a = cq_theta(a, 0.5);
;     if (sqrt(a + 3.0) <= 5.0) { a = cq_phi(a, 3.0); }
;     return cq_measure(a);
;
; THE DEFECT THIS FILE USED TO PIN. A region whose condition is DERIVED computes
; its compare operand through a chain of template rails — here
; `cq_template_sitofp_i32_to_f64`, `cq_template_fadd_f64_hl`,
; `cq_template_sqrt_f64`. `SwapRouteEmit` strips only the FLAG, so at HEAD
; (c36934a) all three stayed allocated and entangled with the wire forever;
; Increment 5 discharged the first two BEFORE the region and had to leave the
; third, because its second user is the flag strip — a `cq_template_*_unc`, which
; `isTemplateProducer` refuses. Refusing it was CORRECT: discharging at the
; anchor its forward consumers imply would free the rail before the strip
; recomputes the flag from it.
;
; CLAUSE (d2) — the emitter-recorded strip. `SwapRouteEmit`'s PHASE path records
; its strip in `TaintSet::DischargedFlagGates`, `isInteriorConsumer` admits a
; RECORDED strip as a READ of the rails in its shifted handle slots, and the
; interior partition's `dagInsertPoint` then lands right after that strip. The
; whole chain is uncomputed there, LIFO, and freed. THE ORDER BELOW IS THE PROOF:
; the strip runs FIRST (it still reads the live `sqrt` rail), then the three
; adjoints, then the flag free.
;
; WHY THE `sitofp` ADJOINT MAY READ THE WIRE ACROSS THE REGION — RESTATED FOR
; CONTROL-IN-PLACE (drbq Inc 2a; the paragraph this replaces argued the same
; verdict from the swap route, which this path no longer emits).
; `cq_template_sitofp_i32_to_f64_unc(%[[C]], %[[H]])` recomputes `sitofp` from
; %[[H]]'s COMPUTATIONAL-BASIS LABEL — an `_unc` is a label-only reader — and the
; region's ONLY gate on %[[H]] is now `cqrt_rz_i32_controlled(flag, %[[H]], 3.0)`,
; which is `diag(1, e^{i3})` on the flag-set branch and `I` on the other:
; DIAGONAL either way, so the label is not restored-after-being-moved, it is NEVER
; MOVED. `Uncomputation::preservesBorrowedParent` clause (1b) states exactly that,
; pointwise, for this one gate. It deliberately does NOT restore the wire's PHASE
; — that phase IS the answer the region computed — and by the label-only-reader
; argument that is exactly what makes this legal. (The pre-2a route needed the
; weaker GROUP argument of clause (d2): two `cqrt_cswap`s are the identity on the
; label only when BOTH run. There is no group here to prove.)
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
;   * call void @cqrt_x(   [superseded by the XCNT count]
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
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @llvm.sqrt.f64(double)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = sitofp i32 %q to double
  %a  = fadd double %c, 3.000000e+00
  %s  = call double @llvm.sqrt.f64(double %a)
  %gt = fcmp ugt double %s, 5.000000e+00
  br i1 %gt, label %merge, label %arm

arm:
  call void @cq_phi(double 3.000000e+00)
  br label %merge

merge:
  %m = call i32 @cq_measure_si32(i32 %q)
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
; CHECK: define i32 @slice(i32 %u0) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[H]])
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %[[H_CAST]], double 3.000000e+00)
; CHECK-NEXT: %[[H_INTR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sqrt_f64(i32 %[[H_OP]])
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %[[H_INTR]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %[[H_CMP]], i32 %[[H_INTR]], double 5.000000e+00)
; CHECK-NEXT: call void @cq_template_sqrt_f64_unc(i32 %[[H_INTR]], i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_INTR]])
; CHECK-NEXT: call void @cq_template_fadd_f64_hl_unc(i32 %[[H_OP]], i32 %[[H_CAST]], double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[H_CAST]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CAST]])
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
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 1 and 1 here.
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
