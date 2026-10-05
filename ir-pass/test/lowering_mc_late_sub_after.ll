; lowering_mc_late_sub_after.ll — ACCEPT (M-C Increment 7a, bd
; test_C_libtooling-x67f). WAS lowering_reject_live_record_mc_sub_after.ll, a
; LOUD DECLINE at the M-A live-record guard; it is renamed and re-dispositioned
; here because the increment FIXED the program, not because the guard moved.
;
; WHAT IT USED TO PIN (bd memory [mc-cannot-see-mb-discharge-2026-08-29], and
; bd 160a's Rule-13 finding F1f, which turned that memory into these three
; fixtures). `lowerOps` runs BEFORE `uncompute`, so the M-C prior-use fence
; (`ArithLowering::priorUseIsSettled`) could only see a discharge that some
; EARLIER emitter had already inlined. Here the prior readers of the register
; are the DERIVED oracle's own chain templates, whose `_unc` + `cqrt_free` the
; M-B interior partition emits LATER — and, at the moment `lowerOps` Phase 1
; asks, are not even `CallInst`s yet (they are still plain `ashr`/`add`
; opcodes, which arm (e) refuses on sight). So `a -= off` stayed OUT of place,
; minted a fresh rail, and the ORIGINAL register stood as a dead ancestor
; record at the S† `cq_theta`, where the M-A guard declined the whole program
; with a message naming the wrong cause.
;
; WHAT IT PINS NOW. The LATE round (`lowerLateReassignments`, the last stage
; before `uncompute`) re-asks the SAME fence on the fully-lowered module with
; the M-B discharge PLAN in hand. The chain rails are planned for discharge
; right after the region's flag strip — provably before the sub — so arm (d2)
; settles them and the sub converts to the in-place `cqrt_addc_i32(%h, -off)`.
;
; THERE IS NO `cqrt_subc_`, AND THERE MUST NOT BE. `x - c` and `x + (-c)` are
; the same permutation under the runtime's `h := (h + imm) mod 2^W` contract, so
; `sub` emits `cqrt_addc_<W>` with the immediate negated by ordinary CLASSICAL
; IR (`sub i32 0, %off` here, since `off` is an SSA value). The Phase-11 freeze
; surface is untouched (Rule 15).
;
; THE RESULT IS A ONE-RAIL PROGRAM, which is the physics claim: at the ONLY
; `cqrt_ry_i32` after the region, the sole allocated rail is `%h` — the flag and
; both chain rails have been freed on the lines above, and the kickback mints no
; other rail. That is what the CHECK-NEXT chain below pins, and it is why the M-A
; guard now has nothing to name.
;
; RED STATE: this file is RED on every plugin built before Increment 7a — there
; it exits non-zero at the guard, so both the `%cq-opt` RUN line and every CHECK
; fail. The siblings are lowering_mc_late_add_sub_around.ll (the `+= off` /
; `-= off` pair around the region) and lowering_mc_late_grover2_offset.ll (two
; full Grover iterations carrying the offset trick). One function per file:
; before the flip the pass stopped at the first loud diagnostic, and keeping the
; split means each shape still fails on its own.
;
; `%off` is a volatile load so nothing folds it away.
;
; SHAPE (`clang -O1` output of):
;     int a = u; cq_theta(&a, 0.5);
;     if (((a * 5) >> 2) == 5) cq_phi(PI);
;     a -= off;
;     cq_theta(&a, -0.5);  return cq_measure(a);
;
; The flat phase arm lowers by KICKBACK: ONE uncontrolled `cqrt_rz_i1(flag,
; theta)` on the flag ancilla, between the flag mint and its strip. (drbq Inc 2a's
; `cqrt_rz_i32_controlled(flag, register, theta)` and the earlier swap route —
; work-rail alloc, both `cqrt_cswap`s, the rail free — are retired.) The flag mint,
; the strip and the flag free are where they were.
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

define i32 @mc_sub_after(i32 noundef %0, ptr noundef %1) {
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
  %13 = call i32 @cq_theta_si32(i32 noundef %12, double noundef -5.000000e-01)
  %14 = call i32 @cq_measure_si32(i32 noundef %13)
  ret i32 %14
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
; CHECK: define i32 @mc_sub_after(i32 noundef %0, ptr noundef %1) {
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = load volatile i32, ptr %1, align 4
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ashr_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[H_OP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[H]], i32 %[[H_OP]])
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H_OP1]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP1]], i32 5)
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 %[[H_OP1]], i32 %[[H]], i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP1]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[H_OP]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[CQ_NEGIMM:[a-zA-Z0-9_.]+]] = sub i32 0, %[[V3]]
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[CQ_NEGIMM]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
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
; NOROUTE-NOT: non-diagonal gate over a live derived record
; NOROUTE-NOT: call void @cqrt_cswap

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-3: call void @cqrt_free(
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
; SILENT-NOT: non-diagonal gate over a live derived record
