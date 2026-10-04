; lowering_mc_late_fallback_measured_chain.ll — FALLBACK (M-C Increment 7a, bd
; test_C_libtooling-x67f). The site stays OUT OF PLACE; that is the existing
; lowering, not a decline (see the sibling _fallback_reader_after.ll's header).
;
; WHAT IT PINS: NO PLAN ENTRY MEANS NO CONVERSION. The late round trusts a prior
; producer only when the M-B interior partition has PLANNED that producer's rail
; for discharge. Here the derived condition's chain rail is MEASURED after the
; region, so `ChainWalk::isInteriorTerminalHandle` refuses it on (I3) — a
; measure user disqualifies a rail, and rightly: `FreePoint` classifies a
; measured terminal as `Measured` and the spine emits neither an adjoint nor a
; free for it, so the rail stands entangled with the register for the rest of
; the program. Converting the subtraction would then relabel a register that a
; live record still describes.
;
; NOTE WHICH HALF OF THE CHAIN STILL DISCHARGES, because the file would be
; misread otherwise: the `ashr` rail IS interior (its only consumer is the QQ
; `add`), so M-B uncomputes and frees it before the region — visible in the
; CHECK chain below. It is the QQ `add` rail, the one the user measures, that
; has no owner. A partial plan is normal; what the fence asks is whether the
; SPECIFIC prior reader of the site's parent is in it, and the `add` reads the
; parent.
;
; NO RED STATE EXISTS on any earlier plugin (before Increment 7a nothing
; converted late at all). MEASURED MUTATION instead (bd memory
; [rule12-pins-without-a-red-state-2026-08-29]): replacing arm (d2)'s plan
; lookup in `ArithLowering::priorUseIsSettled` with a blanket
;     return true;
; (i.e. "any prior rail-minting producer is settled") converts the sub here and
; reddens ELEVEN fixtures — this file, _fallback_reader_after.ll and
; _fallback_terminal_dag.ll (which cover the three independent steps of that
; arm), PLUS the eight ordinary Q+C arithmetic fixtures whose parent then has a
; "settled" prior template reader and converts at the late round:
; lowering_add_qc_{i1,i8,i16,i32,i64}.ll, lowering_xor_qc_i32.ll,
; lowering_sub_negative.ll and lowering_intrinsic_smin_fanout_skip.ll. Dropping
; only the POSITION test leaves this file green (it reddens
; _fallback_reader_after.ll ALONE), which is what shows this one pins membership
; rather than placement.
;
; THE COUNT WAS WRONG HERE UNTIL THE INCREMENT-7 RULE-13 ROUND (finding F2, and
; the same class as Increment 6's F-A): this header said "this + the other two",
; and the reviewer measured eleven — re-measured independently in the fix round
; (`lit ir-pass/test` under M2: 1245 pass / 1 XFAIL / 11 fail, the list above).
; The direction is harmless — the family discriminates from eight MORE sides
; than claimed — but an off-by-eight measured claim is exactly the kind of
; statement this project's defence rests on being literal (Rule 19).
;
; `%off` is a volatile load so nothing folds it away.
;
; SHAPE (`clang -O1` output of):
;     int a = u; cq_theta(&a, 0.5);
;     int t = (a >> 2) + a;
;     if (t == 5) a = cq_phi(a, PI);
;     int mt = cq_measure(t);
;     a -= off;
;     return cq_measure(a) + mt;
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
; 35 line(s) of prose that annotated the OLD CHECK block were removed with
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

define i32 @late_measured_chain(i32 noundef %0, ptr noundef %1) {
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
  %12 = call i32 @cq_measure_si32(i32 noundef %6)
  %13 = sub nsw i32 %4, %3
  %14 = call i32 @cq_measure_si32(i32 noundef %13)
  %15 = add nsw i32 %14, %12
  ret i32 %15
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
; CHECK: define i32 @late_measured_chain(i32 noundef %0, ptr noundef %1) {
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = load volatile i32, ptr %1, align 4
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ashr_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[H_OP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[H]], i32 %[[H_OP]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[H_OP]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H_OP1]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP1]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H_OP1]])
; CHECK-NEXT: %[[H_OP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_hl(i32 %[[H]], i32 %[[V3]])
; CHECK-NEXT: %[[M3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H_OP2]])
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M3]], %[[M]]
; CHECK-NEXT: ret i32 %[[V4]]
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
; NOROUTE-NOT: cq_template_add_i32_unc
; NOROUTE-NOT: cqrt_addc_i32
; NOROUTE-NOT: cqrt_xorc_i32
; NOROUTE-NOT: warning
; NOROUTE-NOT: error

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 1 and 1 here.
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase

; ---------------------------------------------------------------------------
; STDERR assertions, CARRIED ACROSS VERBATIM.  These pin a WARNING, not a
; gate, so nothing about the register-free surface touches them; they are
; reproduced unchanged rather than re-derived, and the RUN lines above keep
; their original spelling.
; SILENT-NOT: warning
; SILENT-NOT: error
