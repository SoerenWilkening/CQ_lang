; lowering_mc_late_fallback_reader_after.ll — FALLBACK (M-C Increment 7a, bd
; test_C_libtooling-x67f). The site stays OUT OF PLACE, which is not a decline:
; `cq_template_sub_i32_hl` is a lowering this compiler emits correctly, and the
; whole M-C fence is written so that failing it costs a kept ancestor rail and
; nothing else (Rule 17 — the decline belongs to inputs outside the target
; shape, not to a shape we lower).
;
; WHAT IT PINS: THE POSITION HALF OF ARM (d2). The late round admits a prior
; producer whose rail the M-B interior partition has PLANNED to discharge — but
; only when that discharge is `provablyBefore` the site. Here the derived
; condition's chain rail is read by TWO recorded flag strips, and the SECOND
; region sits AFTER the subtraction. The interior anchor is the nearest common
; post-dominator of the point right after every consumer, so it lands after the
; second strip, i.e. after the site. The chain's `_unc`s therefore run with the
; register ALREADY relabelled if the sub had been converted, and the adjoint of
; `add(q, q>>2)` would recompute from the wrong basis — a dirty rail and a
; `cqrt_free` that is a hidden measurement (Rules 6/8), verify-clean and
; invisible to the golden byte-diff. The plan HAS an entry for these gates; it
; is the placement that refuses.
;
; CONTRAST WITH ITS SIBLINGS, because the three refuse at three different steps:
;   * this file — the gate IS planned, the `At` is not before the site;
;   * _fallback_measured_chain.ll — no plan entry at all (the rail is measured,
;     so the interior partition never owns it);
;   * _fallback_terminal_dag.ll — planned, well placed, and WITHHELD because the
;     dead-terminal spine could reach the gate.
;
; NO RED STATE EXISTS on any earlier plugin: before Increment 7a nothing
; converted late at all, so this file is green on every one of them for a
; different reason. MEASURED MUTATION instead (bd memory
; [rule12-pins-without-a-red-state-2026-08-29]): dropping the position test in
; `ArithLowering::priorUseIsSettled` arm (d2) —
;     if (It != Plan->GateAt.end() && provablyBefore(It->second, bo, DT))
;   → if (It != Plan->GateAt.end())
; converts the sub here and reddens this file, while
; _fallback_measured_chain.ll and _fallback_terminal_dag.ll stay green (they
; refuse at the other two steps).
;
; `%off` is a volatile load so nothing folds it away. Both regions are ordinary
; flat diamonds; the sequential pair lowers since bd hcrg.
;
; SHAPE (`clang -O1` output of, with `z = t * 3; if (z == 9)` const-folded by
; clang into the `t == 3` spelling below):
;     int a = cq_theta(u, 0.5);
;     int t = (a >> 2) + a;
;     if (t == 5) a = cq_phi(a, PI);
;     a -= off;
;     if (t == 3) a = cq_phi(a, 1.5);
;     return cq_measure(a);
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. Nothing else moves — the flag
; mint, the strip, the flag free and every downstream gate are unchanged.
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
; NOTE — the header above still NAMES a retired symbol (`cqrt_rz_<W>`,
; `cqrt_cswap` or a `_controlled` twin).  That prose is kept DELIBERATELY:
; it is the fixture's PURPOSE and the record of what the pre-Inc-1 pass
; emitted here.  Read it as history; the stream this file now ASSERTS is
; the derived one below, and the two are meant to differ.
;
; 16 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @late_reader_after(i32 noundef %0, ptr noundef %1) {
  %3 = load volatile i32, ptr %1, align 4
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = ashr i32 %4, 2
  %6 = add nsw i32 %5, %4
  %7 = icmp eq i32 %6, 5
  br i1 %7, label %8, label %10
8:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %10
10:
  %12 = sub nsw i32 %4, %3
  %13 = icmp eq i32 %6, 3
  br i1 %13, label %14, label %16
14:
  call void @cq_phi(double 1.500000e+00)
  br label %16
16:
  %18 = call i32 @cq_measure_si32(i32 noundef %12)
  ret i32 %18
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
; CHECK: define i32 @late_reader_after(i32 noundef %0, ptr noundef %1) {
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = load volatile i32, ptr %1, align 4
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ashr_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[H_OP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[H]], i32 %[[H_OP]])
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H_OP2]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP1]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H_OP2]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: %[[H_OP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_hl(i32 %[[H]], i32 %[[V3]])
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H_OP2]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 1.500000e+00)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP2]], i32 3)
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 %[[H_OP2]], i32 %[[H]], i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP2]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[H_OP]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H_OP3]])
; CHECK-NEXT: ret i32 %[[M]]
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
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
;   ^ the TENSORED per-register Rz is the defect this increment removes (PRD §1). ONE complement pattern, not an enumeration of six — the shipped ABI has NINE widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block (round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
; NOROUTE-NOT: call void @cq_phi(
;   ^ a surviving phase call is lowered or deleted, never left for the linker
; NOROUTE-NOT: cq_phi_
;   ^ the register form is a RESERVED NAME and declines (round-1 F-L6-1)

; Original negatives PRESERVED (re-measured on the Inc-1 output):
; NOROUTE-NOT: cqrt_addc_i32
; NOROUTE-NOT: cqrt_xorc_i32
; NOROUTE-NOT: warning
; NOROUTE-NOT: error
; NOROUTE-NOT: call void @cqrt_cswap

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 2 and 2 here.
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase

; ---------------------------------------------------------------------------
; STDERR assertions, CARRIED ACROSS VERBATIM.  These pin a WARNING, not a
; gate, so nothing about the register-free surface touches them; they are
; reproduced unchanged rather than re-derived, and the RUN lines above keep
; their original spelling.
; SILENT-NOT: warning
; SILENT-NOT: error
