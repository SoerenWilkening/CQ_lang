; lowering_mc_late_grover2_offset.ll — ACCEPT (M-C Increment 7a, bd
; test_C_libtooling-x67f). WAS lowering_reject_live_record_mc_grover2_offset.ll,
; a LOUD DECLINE at the M-A live-record guard; renamed and re-dispositioned
; because the increment fixed the PROGRAM, not because the guard moved.
;
; THIS IS THE CAMPAIGN SHAPE, and it is the reason the two smaller siblings
; exist at all: TWO Grover iterations, each S — derived oracle — S† — R0, with
; the `+= off` / `-= off` offset trick carried across both. bd memory
; [mc-cannot-see-mb-discharge-2026-08-29] told slice authors to keep the offset
; trick OUT of a derived-oracle Grover, and named the reason precisely — "it is
; not a compiler bug to chase in M-B; it is a pipeline-ORDER fact about M-C".
; Increment 7a changes the pipeline order, so the advice is retired and this
; file is its receipt. The e2e twin is
; tests/e2e/slice_control_grover_derived_oracle_offset.c, which additionally
; LINKS and byte-diffs a trace.
;
; THE PHYSICS CLAIM, and it is the only one worth checking on a Grover slice:
; at EVERY `cqrt_ry_i32` — the five S/S† rotations across two iterations — the
; ONLY allocated rail is `%h`. Each iteration's oracle chain (`ashr` rail, QQ
; `add` rail), its flag, and its work rail are all freed on the lines above,
; and neither offset step mints a rail at all. A record standing at any one of
; those rotations would dephase the interference the algorithm depends on; that
; is what the M-A guard used to say, loudly and about the wrong cause.
;
; CHECKING IT IS DELIBERATELY SPLIT ACROSS TWO PREFIXES rather than written as a
; 60-line CHECK-NEXT transcript. The default prefix walks the stream in order and
; pins the FOUR offset steps and the two oracle discharges; the NOMINT prefix
; re-reads the SAME file (one `%cq-opt` spawn — the lit cost note) with nothing
; but CHECK-NOTs, which is the only way to say "no data-template rail for an
; offset step ANYWHERE in the function", including before the first CHECK. A full
; adjacency chain would additionally pin the two regions' interleaving — churn
; with no physics in it; that pinning lives in the two smaller siblings, whose
; streams are the same shape.
;
; RED STATE: RED on every plugin built before Increment 7a (non-zero exit at the
; M-A guard, so the RUN line fails before any CHECK is read).
;
; `%off` is a volatile load so nothing folds it away. The oracle predicate is
; `((a*5)>>2) == 5`, i.e. `a == 4` — SATISFIABLE, per bd 160a's Rule-13 finding
; F2 (the earlier `((a*37)>>3) == 5` had no integer solution without `nsw`
; overflow, so a demo that sold itself as marking a computed predicate marked
; nothing a C program may legally reach).
;
; SHAPE (`clang -O1` output of two iterations of):
;     a += off;
;     if (((a * 5) >> 2) == 5) a = cq_phi(a, PI);
;     a -= off;
;     cq_theta(&a, -0.5);
;     if (a == 0) cq_phi(0, PI);
;     cq_theta(&a, 0.5);
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

define i32 @mc_grover2_offset(ptr noundef %0) {
  %2 = load volatile i32, ptr %0, align 4
  %3 = call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %4 = add nsw i32 %3, %2
  %5 = ashr i32 %4, 2
  %6 = add nsw i32 %5, %4
  %7 = icmp eq i32 %6, 5
  br i1 %7, label %8, label %10
8:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %10
10:
  %12 = sub nsw i32 %4, %2
  %13 = call i32 @cq_theta_si32(i32 noundef %12, double noundef -5.000000e-01)
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %17
15:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %17
17:
  %19 = call i32 @cq_theta_si32(i32 noundef %13, double noundef 5.000000e-01)
  %20 = add nsw i32 %19, %2
  %21 = ashr i32 %20, 2
  %22 = add nsw i32 %21, %20
  %23 = icmp eq i32 %22, 5
  br i1 %23, label %24, label %26
24:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %26
26:
  %28 = sub nsw i32 %20, %2
  %29 = call i32 @cq_theta_si32(i32 noundef %28, double noundef -5.000000e-01)
  %30 = icmp eq i32 %29, 0
  br i1 %30, label %31, label %33
31:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %33
33:
  %35 = call i32 @cq_theta_si32(i32 noundef %29, double noundef 5.000000e-01)
  %36 = call i32 @cq_measure_si32(i32 noundef %35)
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
; CHECK: define i32 @mc_grover2_offset(ptr noundef %0) {
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = load volatile i32, ptr %0, align 4
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[V2]])
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ashr_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[H_OP4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[H]], i32 %[[H_OP]])
; CHECK-NEXT: %[[H_CMP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H_OP4]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP3]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP3]], i32 %[[H_OP4]], i32 5)
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 %[[H_OP4]], i32 %[[H]], i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP4]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[H_OP]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP3]])
; CHECK-NEXT: %[[CQ_NEGIMM:[a-zA-Z0-9_.]+]] = sub i32 0, %[[V2]]
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[CQ_NEGIMM]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: %[[H_CMP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP2]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP2]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[V2]])
; CHECK-NEXT: %[[H_OP6:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ashr_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[H_OP7:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[H]], i32 %[[H_OP6]])
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H_OP7]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP1]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H_OP7]], i32 5)
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 %[[H_OP7]], i32 %[[H]], i32 %[[H_OP6]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP7]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[H_OP6]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP6]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: %[[CQ_NEGIMM9:[a-zA-Z0-9_.]+]] = sub i32 0, %[[V2]]
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[CQ_NEGIMM9]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
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
; NOROUTE-NOT: call void @cqrt_rz_{{[a-z0-9]+}}_controlled(
;   ^ ⚠ NARROW TWIN of the blanket `_controlled` above, and it exists because the blanket one is DROPPED from any fixture that legitimately emits a controlled Ry or a controlled copy — and dropping it took the only catch for a controlled Rz with it. MEASURED: 4 of the 104 re-derived accepts were BLIND to an injected `cqrt_rz_i32_controlled` — the exact pre-Inc-1 TENSORED gate this increment removes — until this line was added. The width complement above cannot cover it either: it requires `(` immediately after the width, and `cqrt_rz_i32_controlled(` has `_controlled` in between.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
;   ^ the TENSORED per-register Rz is the defect this increment removes (PRD §1). ONE complement pattern, not an enumeration of six — the shipped ABI has NINE widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block (round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
; NOROUTE-NOT: call void @cq_phi(
;   ^ a surviving phase call is lowered or deleted, never left for the linker
; NOROUTE-NOT: cq_phi_
;   ^ the register form is a RESERVED NAME and declines (round-1 F-L6-1)

; Original negatives PRESERVED (re-measured on the Inc-1 output):
; NOROUTE-NOT: cq_template_sub_i32_hl
; NOROUTE-NOT: cq_template_add_i32_hl
; NOROUTE-NOT: non-diagonal gate over a live derived record

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-4: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-8: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 4 and 4 here.
; MDCNT-COUNT-4: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase

; ---------------------------------------------------------------------------
; STDERR assertions, CARRIED ACROSS VERBATIM.  These pin a WARNING, not a
; gate, so nothing about the register-free surface touches them; they are
; reproduced unchanged rather than re-derived, and the RUN lines above keep
; their original spelling.
; SILENT-NOT: non-diagonal gate over a live derived record
