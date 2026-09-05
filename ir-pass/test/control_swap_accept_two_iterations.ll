; control_swap_accept_two_iterations.ll — ACCEPT (bd test_C_libtooling-lom0
; Increment 4): TWO COMPLETE GROVER ITERATIONS, four chained `cq_theta`s, four
; sequential tainted-condition phase regions, one physical register.
;
; This is the fixture the increment exists for. `clang -O1` of:
;     volatile int off = 3;
;     int q = 0;
;     q = cq_theta(q, 0.5);  q += off;                 /* S      */
;     if (q == 5) q = cq_phi(q, PI);                   /* O      */
;     q -= off;  q = cq_theta(q, -0.5);                /* S†     */
;     if (q == 0) q = cq_phi(q, PI);                   /* R0     */
;     q = cq_theta(q, 0.5);  q += off;                 /* S      */
;     if (q == 5) q = cq_phi(q, PI);                   /* O      */
;     q -= off;  q = cq_theta(q, -0.5);                /* S†     */
;     if (q == 0) q = cq_phi(q, PI);                   /* R0     */
;     q = cq_theta(q, 0.5);  q += off;                 /* re-prep */
;     return cq_measure(q);
;
; MEASURED at HEAD (b4e329b): declines,
;     cq controlled lowering: condition predates a non-diagonal gate
; and nothing else — bd lom0's own comment records that a 2-iteration Grover
; hits this one diagnostic and no other. It is the single wall.
;
; FOUR CHAINED THETAS, TWO OF WHICH DRIVE THE ACCEPT. The two `S†` thetas and
; the two `S` re-preps are all chained (arg-0 is a live quantum wire). The
; ORACLE regions never needed the widening: their conditions read an `add`
; result, the walk crosses the merge phi but not the following `sub`, so the
; S-dagger theta behind it is never reached and no gate is found on their wire
; at all (measured on the one-iteration twin: swapping an oracle arm for a value
; op yields the value-arm string, not the deferred wire-gate one). The two REFLECTION regions are
; the ones that declined: each reads a chained theta directly, and each one's
; forward wire runs through its merge phi into the NEXT `cq_theta`. Both of
; those are dominated by their region's branch and cannot reach back to it, so
; `provablyBefore(BI, T)` holds twice and both regions accept as PHASE arms.
;
; WHAT THE STREAM BELOW WITNESSES, in order, and it is the whole correctness
; claim of the increment: for EVERY region the flag is minted, the arm gate fires
; CONTROLLED AND IN PLACE on the register, and the flag is `_unc`-STRIPPED and
; FREED — and only THEN does the next `cqrt_ry_i32` fire. Four strips, four flag
; frees, and no `cqrt_ry_i32` between a mint and its strip. A regression that let
; a re-prep Ry slide before a strip would still verify clean and still pair every
; free; only this ordering catches it.
;
; ⚠ THERE ARE **ZERO** RAIL FREES, and this paragraph used to claim four. Since bd
; drbq Inc 2a (2026-09-02) the FLAT phase path emits no work rail at all — the CNT
; block below asserts exactly that (one cqrt_alloc_i32 on the CNT prefix, four
; cqrt_free on CNT3 = the four FLAG frees), and line ~181 of this same file already said
; "No swap route survives on any of the four regions". Corrected in the Inc-2a
; round-1 review (L3 F3); the file used to contradict itself.
;
; ONE REGISTER (M-C, bd 6uqc Inc 2): every `+= off` / `-= off` is an in-place
; `cqrt_addc_i32`, so exactly FIVE `cqrt_alloc_i32` appear — the wire plus one
; work rail per region — and nothing else is entangled with the wire when any of
; the four non-diagonal gates fires. That is the property the e2e customer
; `slice_control_grover_2iter` re-checks at the trace level with strict
; free-pairing (`5 rail mint(s) of which 1 left allocated`, the measured register).
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
;   * call i32 @cqrt_alloc_i32(
;   * call void @cq_template_icmp_eq_i32_hl_unc(
;   * call void @cqrt_free(   [superseded by the FCNT count]
;
; 17 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

@off = global i32 3, align 4

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
  %1 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %2 = load volatile i32, ptr @off, align 4
  %3 = add nsw i32 %2, %1
  %4 = icmp eq i32 %3, 5
  br i1 %4, label %5, label %7

5:                                                ; preds = %0
  call void @cq_phi(double 0x400921FB54442D18)
  br label %7

7:                                                ; preds = %5, %0
  %9 = load volatile i32, ptr @off, align 4
  %10 = sub nsw i32 %3, %9
  %11 = call i32 @cq_theta_si32(i32 %10, double -5.000000e-01)
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %15

13:                                               ; preds = %7
  call void @cq_phi(double 0x400921FB54442D18)
  br label %15

15:                                               ; preds = %13, %7
  %17 = call i32 @cq_theta_si32(i32 %11, double 5.000000e-01)
  %18 = load volatile i32, ptr @off, align 4
  %19 = add nsw i32 %18, %17
  %20 = icmp eq i32 %19, 5
  br i1 %20, label %21, label %23

21:                                               ; preds = %15
  call void @cq_phi(double 0x400921FB54442D18)
  br label %23

23:                                               ; preds = %21, %15
  %25 = load volatile i32, ptr @off, align 4
  %26 = sub nsw i32 %19, %25
  %27 = call i32 @cq_theta_si32(i32 %26, double -5.000000e-01)
  %28 = icmp eq i32 %27, 0
  br i1 %28, label %29, label %31

29:                                               ; preds = %23
  call void @cq_phi(double 0x400921FB54442D18)
  br label %31

31:                                               ; preds = %29, %23
  %33 = call i32 @cq_theta_si32(i32 %27, double 5.000000e-01)
  %34 = load volatile i32, ptr @off, align 4
  %35 = add nsw i32 %34, %33
  %36 = call i32 @cq_measure_si32(i32 %35)
  ret i32 %36
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
; CHECK-NEXT: %[[V1:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @off, align 4
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[V1]])
; CHECK-NEXT: %[[H_CMP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP3]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP3]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP3]])
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @off, align 4
; CHECK-NEXT: %[[CQ_NEGIMM:[a-zA-Z0-9_.]+]] = sub i32 0, %[[V2]]
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[CQ_NEGIMM]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: %[[H_CMP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP2]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP2]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @off, align 4
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[V3]])
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP1]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @off, align 4
; CHECK-NEXT: %[[CQ_NEGIMM4:[a-zA-Z0-9_.]+]] = sub i32 0, %[[V4]]
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[CQ_NEGIMM4]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[V5:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @off, align 4
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[V5]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
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
; NOROUTE-NOT: phi
; NOROUTE-NOT: br i1

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-4: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 4 and 4 here.
; MDCNT-COUNT-4: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
