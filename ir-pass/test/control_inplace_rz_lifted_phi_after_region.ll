; control_inplace_rz_lifted_phi_after_region.ll — ACCEPT. The STEM-DIFFERENTIAL
; CONTROL for `control_inplace_ry_lifted_phi_after_region.ll`: the same program
; with a PHASE arm in the first region instead of the in-place Ry arm, then the
; same 5j5 classical join φ over `r`. `clang -O1` output (attribute groups and
; metadata trimmed, like the Ry twin's) for
;
;   volatile int OPQ = 1;
;   int slice(void) { int q=3, r=7;
;                     cq_theta(&q,0.5); cq_theta(&r,0.25);
;                     if (q == 5)  { cq_phi(0.9); }        /* phase arm, kickback */
;                     if (OPQ)     { cq_theta(&r, 0.5); }  /* 5j5 lift            */
;                     return cq_measure(q) + cq_measure(r); }
;
; bd test_C_libtooling-drbq Increment 3, round-1 Rule-13 review finding F-L5-1.
; The pair is a STANDING witness that a change to `resolveWireBase`'s
; `ControlledRotations` stop cannot move one stem without the other going red.
; In the Ry twin the join φ's wire runs through the region's HOISTED controlled
; gate (M-β, a `ControlledRotations` STOP); here the phase arm touches no data
; register, so the join φ `%11 = phi [%9, %8], [%2, %5]` resolves through its
; arm's in-place Ry `%9` straight to the alloc `%2`, the plain 5j5 lift. Same
; program, one differing stem, one differing wire base.
;
; WHAT IT PINS: the phase region is the four-line kickback on a flag minted off
; `q` (mint, `cqrt_rz_i1`, strip, free) and touches no data register; the OPQ arm
; keeps its uncontrolled Ry on `r`'s handle in its own block; the join φ
; dissolves and both registers are measured on their own handles.
;
; History: pre-3qlq the first arm was the Inc-2a in-place Rz `r = cq_phi(r, 0.9)`
; (M-α, merge φ RAUW'd to the BASE) and the OPQ arm `r = cq_phi(r, 0.5)`. 3qlq
; made the first arm register-free and deleted the OPQ arm's phase; bd jttf
; (2026-10-05) re-spelled the OPQ arm as the in-place Ry above, in BOTH twins.
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

@OPQ = global i32 1, align 4

define i32 @slice() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01)
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %5

4:                                                ; preds = %0
  tail call void @cq_phi(double noundef 9.000000e-01)
  br label %5

5:                                                ; preds = %4, %0
  %6 = load volatile i32, ptr @OPQ, align 4
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %10, label %8

8:                                                ; preds = %5
  %9 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01)
  br label %10

10:                                               ; preds = %8, %5
  %11 = phi i32 [ %9, %8 ], [ %2, %5 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

declare void @cq_phi(double noundef) local_unnamed_addr
declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; ===========================================================================
; THE EMITTED STREAM, IN ORDER — DERIVED from this fixture's own pass output
; (prep_a2, bd test_C_libtooling-3qlq Inc 1).  Every `%name` below is bound at
; its DEFINITION and referenced afterwards, so the chain asserts operand
; IDENTITY — the strip and the free name the SAME flag the mint produced
; (bd 8txa: the golden itself must witness the pairing).  Handle names are
; DERIVED, never typed (bd drbq Inc 4: 9 of 20 accepts named a %h1 the pass
; never emits).  Trailing `!cq.branchphase` metadata is stripped here because
; its NUMBER is LLVM's, not ours; its presence and count are MDCNT's job.
; CHECK: define i32 @slice() local_unnamed_addr {
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[V1:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @OPQ, align 4
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = icmp eq i32 %[[V1]], 0
; CHECK-NEXT: br i1 %[[V2]], label %4, label %3
; CHECK: 3:                                                ; preds = %0
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: br label %4
; CHECK: 4:                                                ; preds = %3, %0
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H1]])
; CHECK-NEXT: %[[V5:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M2]], %[[M]]
; CHECK-NEXT: ret i32 %[[V5]]
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
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi_si
; NOROUTE-NOT: cq_measure_si

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
