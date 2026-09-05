; lowering_mc_seq_region_customer.ll — THE CAMPAIGN'S CUSTOMER SHAPE, at lit
; level (bd test_C_libtooling-6uqc M-C Increments 2a+2b; bd
; test_C_libtooling-nepx, which this file's 2b state CLOSES).
;
; This is `tests/e2e/slice_control_seq_grover.c` as the pass receives it: a theta,
; a `q += off`, a tainted-condition phase region, the `q -= off`, a chained S†
; theta, a second region, and a final `q += off`. `off` is a volatile load in the
; slice precisely so `clang -O1` cannot cancel the pair; here the two loads are
; spelled directly.
;
; WHAT IT PINS, AND IT IS THE WHOLE REASON THE FENCE IS POSITION-AWARE. Site 3
; (`%18 = add i32 %17, %16`) has a parent whose user list is NOT empty: the
; region-2 compare read it, the arm's controlled `Rz` read it (two `cqrt_cswap`s
; routed it before the §6a control-in-place peephole), and its `_unc` strip read
; it again. Under the WITHDRAWN "single-consumer-ever" reading every one of those
; disqualified the site, and the customer stayed dephased (SPIKE §9.8). Under the
; RULED position-aware, spine-discharge-aware fence they do not, because every one
; of them is a PRIOR, COMPLETED reader: they all precede the add, and the compare's
; flag was `_unc`-stripped AND `cqrt_free`d before it. So both `add` sites convert
; and the two ancestor rails they used to mint are never allocated.
;
; WHAT BATCH 2b ADDED, AND IT IS THE WHOLE OF bd nepx. The middle site is the
; `sub`, and 2a did not admit it: it still minted a fresh rail off the (collapsed)
; `%h`, and that rail was live and entangled when the S† `cqrt_ry_i32(…, -0.5)`
; fired — one ancestor instead of three, but a dephased reflection either way.
; With `sub` admitted (`q - c` → `cqrt_addc_i32(q, -c)`, the immediate negated in
; CLASSICAL IR) this function is a ONE-RAIL program end to end: exactly one data
; register is ever allocated, and every gate after the state prep acts on it in
; place. The `cq_template_sub_i32_hl` CHECK this file used to carry as its batch
; boundary is REPLACED below by the negation + in-place gate it became — replaced
; and not deleted, exactly as the 2a text asked.
;
; The negation `%cq_negimm = sub i32 0, %2` is CLASSICAL: it is created in Phase 2
; of `lowerOps` (after the taint set is frozen), never joins `taint.Tainted`,
; never becomes a gate, and emits NO trace line — the e2e golden sees only the
; negated runtime value `-3` in the `addc` immediate slot.
;
; THE OTHER THING IT PINS is that `detectControlRegions` + `SwapRouteEmit` +
; `RegionFlatten` all run BEFORE `lowerOps`, which is why the fence can see this
; at all. Pre-flatten, the parent of sites 2 and 3 is a MERGE PHI whose later-use
; set is not readable off the CFG; post-flatten it is a plain SSA value with a
; positioned, fully torn-down user list.
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

@off = global i32 3

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
  %1  = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)      ; S
  %2  = load volatile i32, ptr @off, align 4
  %3  = add nsw i32 %2, %1                                       ; site 1: q += off
  %4  = icmp eq i32 %3, 5
  br i1 %4, label %5, label %7

5:                                                ; the oracle arm
  call void @cq_phi(double 0x400921FB54442D18)
  br label %7

7:
  %9  = load volatile i32, ptr @off, align 4
  %10 = sub nsw i32 %3, %9                                       ; site 2: q -= off
  %11 = call i32 @cq_theta_si32(i32 %10, double -5.000000e-01)   ; S-dagger
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %15

13:                                               ; the reflection arm
  call void @cq_phi(double 0x400921FB54442D18)
  br label %15

15:
  %17 = load volatile i32, ptr @off, align 4
  %18 = add nsw i32 %17, %11                                     ; site 3: q += off
  %19 = call i32 @cq_measure_si32(i32 %18)
  ret i32 %19
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
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP1]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @off, align 4
; CHECK-NEXT: %[[CQ_NEGIMM:[a-zA-Z0-9_.]+]] = sub i32 0, %[[V2]]
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[CQ_NEGIMM]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @off, align 4
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[V3]])
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
; NOROUTE-NOT: cq_template_sub_
; NOROUTE-NOT: cq_template_add_
; NOROUTE-NOT: call void @cqrt_cswap

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 2 and 2 here.
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
