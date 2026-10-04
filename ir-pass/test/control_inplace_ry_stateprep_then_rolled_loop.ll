; control_inplace_ry_stateprep_then_rolled_loop.ll — ACCEPT: a FLAT state prep
; followed by a classically-bounded loop that ROTATES THE PREPPED REGISTER, and
; the loop ROLLS.
;
; ⚠ A NEW ACCEPT CLASS WITH NO FIXTURE, NO SLICE, NO GOLDEN AND NO MATRIX CELL
; AT HAND-BACK, and the record predicted it could not happen (round-1 Rule-13
; review, lens L6 finding F-3, probe `L2`). PRD §14.6 and notes §3 both said a
; hoisted state-prep `T` is a mint "which set WOULD CLAIM it if R7 were lifted",
; and §14.5 gave the reason: "the obstruction is positional — the hoisted `T`
; sits INSIDE the loop body, so `DT.dominates(Mint, L->getHeader())` fails".
; THAT IS TRUE ONLY WHEN THE REGION IS IN THE LOOP. For a FLAT prep followed by a
; loop, `T` DOMINATES the header and `LoopLowering::railPhiRootMint` succeeds
; with a `Mint` that is a CONTROLLED rotation — a shape that did not exist before
; Inc 4. `collapseFlattenedLoopRails` then claims the rail φ, and the body rolls.
;
; The C original (measured HEAD rc=0, pre-Inc-4 oracle rc=1):
;
;     int q = u0; cq_theta(&q, .5);  int r = 0;
;     if (q == 7) { r = 0; cq_theta(&r, .9); }                /* flat prep */
;     for (int i=0;i<3;i++){ if (q>5) q=cq_phi(q,.2); cq_theta(&r,.1); }
;
; NO DEFECT ON THIS WITNESS: the hand-unrolled K=3 twin links and runs to a
; BYTE-IDENTICAL trace (24 lines each), strict stage 2b 0 violations / 0
; unproven.
;
; ⚠ IT IS CONTEXT-DEPENDENT, AND THAT IS A PRE-EXISTING `LoopLowering` FACT, NOT
; AN Inc-4 ONE: `collapseFlattenedLoopRails` only runs when
; `taint.InLoopFlattenedPreds` is non-empty, so REMOVING the unrelated in-loop
; `if (q > 5)` region makes the identical prepped-rail loop DECLINE
; (`cq taint escape: tainted value muxed by a classical-condition phi`, on BOTH
; binaries). The disposition of the state-prep rail's loop therefore depends on
; whether some OTHER register has a region inside that loop. Recorded here so the
; next reader does not conclude from this file that "a prepped rail always rolls".
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
; 33 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ 0, %entry ], [ %rt, %arm ]
  br label %header
header:
  %i  = phi i32 [ 0, %merge ], [ %inext, %latch ]
  %rp = phi i32 [ %rm, %merge ], [ %rn, %latch ]
  %qp = phi i32 [ %q, %merge ], [ %qp, %latch ]
  %bc = icmp sgt i32 %qp, 5
  br i1 %bc, label %barm, label %latch
barm:
  call void @cq_phi(double 2.000000e-01)
  br label %latch
latch:
  %rn = call i32 @cq_theta_si32(i32 %rp, double 1.000000e-01)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %header
exit:
  %mq = call i32 @cq_measure_si32(i32 %qp)
  %mr = call i32 @cq_measure_si32(i32 %rn)
  %s  = add i32 %mq, %mr
  ret i32 %s
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
; CHECK: define i32 @example(i32 %u0) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 7)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[H_CMP]], i32 %[[H2]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: br label %header
; CHECK: header:                                           ; preds = %header, %entry
; CHECK-NEXT: %[[I:[a-zA-Z0-9_.]+]] = phi i32 [ 0, %entry ], [ %inext, %header ]
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP1]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 1.000000e-01)
; CHECK-NEXT: %[[INEXT:[a-zA-Z0-9_.]+]] = add nuw nsw i32 %[[I]], 1
; CHECK-NEXT: %[[DONE:[a-zA-Z0-9_.]+]] = icmp eq i32 %[[INEXT]], 3
; CHECK-NEXT: br i1 %[[DONE]], label %exit, label %header
; CHECK: exit:                                             ; preds = %header
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H2]])
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = add i32 %[[M]], %[[M3]]
; CHECK-NEXT: ret i32 %[[S]]
; CHECK-NEXT: }

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE.  No positive directive may enter this prefix: a
; positive WINDOWS every negative after it, which is how an injected gate
; escaped 20 of 20 blocks in bd drbq Inc 3 (F-L6-1) and again in Inc 4.
; NOROUTE-NOT: cqrt_cswap
;   ^ the swap route is retired — no work rail, so no Fredkin
; NOROUTE-NOT: cqrt_copy
;   ^ method-B copy on a phase arm dephases the answer (Rule 7)
; NOROUTE-NOT: call void @cqrt_rz_{{[a-z0-9]+}}_controlled(
;   ^ ⚠ NARROW TWIN of the blanket `_controlled` above, and it exists because the blanket one is DROPPED from any fixture that legitimately emits a controlled Ry or a controlled copy — and dropping it took the only catch for a controlled Rz with it. MEASURED: 4 of the 104 re-derived accepts were BLIND to an injected `cqrt_rz_i32_controlled` — the exact pre-Inc-1 TENSORED gate this increment removes — until this line was added. The width complement above cannot cover it either: it requires `(` immediately after the width, and `cqrt_rz_i32_controlled(` has `_controlled` in between.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
;   ^ the TENSORED per-register Rz is the defect this increment removes (PRD §1). ONE complement pattern, not an enumeration of six — the shipped ABI has NINE widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block (round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
; NOROUTE-NOT: call void @cq_phi(
;   ^ a surviving phase call is lowered or deleted, never left for the linker
; NOROUTE-NOT: cq_phi_
;   ^ the register form is a RESERVED NAME and declines (round-1 F-L6-1)
;
; MEASURED NOT APPLICABLE to this fixture (the candidate FIRES on the clean
; output, so asserting it would be false).  Recorded rather than dropped in
; silence — an absent assertion nobody explained is how a fence rots:
;   * _controlled   (present in this fixture's own output)

; Original negatives PRESERVED (re-measured on the Inc-1 output):
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: call void @cqrt_free(i32 %h2)
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h2, double 9.000000e-01)

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
