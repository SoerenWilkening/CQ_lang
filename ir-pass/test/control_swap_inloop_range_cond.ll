; control_swap_inloop_range_cond.ll — ACCEPT (bd test_C_libtooling-8h7d.5, Rule-13
; ROUND 4, finding OD-A). A TWO-SIDED RANGE oracle — the canonical Grover marking
; predicate — inside a classically-bounded loop:
;
;     for (int i = 0; i < 2; ++i) {
;         if (q > 5 && q < 20) { q = cq_phi(q, PI); }
;         cq_theta(&q, -0.5);
;     }
;
; WHAT WAS WRONG. `clang -O1` canonicalizes the range test to
; `%t = add %q, -6; icmp ult %t, 14`, and `%t` therefore wears the dtzb IN-PLACE
; SHAPE (`inPlaceValueRailOperand` — `V OP c` with add/xor and a classical
; immediate). Round 2's Rule-8 fan-out guard counted it beside the arm's real
; `cq_phi` and declined `cq loop lowering: loop-carried rail has multiple in-place
; consumers` — on a program whose hand-unrolled twin compiles. `%t` is a
; DERIVED-CONDITION temp inside a loop body: M-C's G5 (`inPlaceFenceHolds`,
; ArithLowering.cpp) refuses OUTRIGHT any site inside a natural loop or a
; `blockCanRepeat` block, and it is neither a chain member nor in
; `taint.InPlaceRailOps`, so `lowerOps` mints it a FRESH rail. It never mutates the
; loop-carried register and was never a second in-place consumer at all.
;
; THE FIX is `railValueConsumerDisposition` (LoopLowering.cpp) — ONE spelling of
; "will this `BinaryOperator` be lowered in place", shared by both rounds' fan-out
; guards, by `collectRailGates`' forward extension and by `markIfRailLocal`'s
; `onRail` (Rule 14). Only the PROVEN-`OutOfPlace` cell is dropped; the `Unproven`
; straight-line cell still counts and still declines (see
; lowering_reject_inloop_control_rail_fanout.ll).
;
; THE SECOND HEAD OF THE SAME FINDING is `markIfRailLocal`, and it is why this
; fixture checks the DISCHARGE and not just the accept. Its `onRail` also peeled
; `%t` by SHAPE, so `%t` counted as "the register", `AnyLocal` stayed false, the
; body was never certified ITERATION-LOCAL, and the uncompute spine's §2.9 acyclic
; backstop leaked the whole condition chain once per trip — the rolled trace then
; differs from its hand-unrolled twin's, with two M-A warnings and nothing else.
; `peelInPlaceStep`'s `AsLowered` parameter is that fix.
;
; WHAT THIS FILE DOES *NOT* PIN, stated because the mutation was run and the
; comfortable claim was false: it is NOT a witness for the round-4 window-lemma
; change in `Uncomputation.cpp`. Restoring the dominance-bundled
; `provablyBeforePerActivation` spelling of (W1)/(W2) leaves this fixture GREEN —
; this body has no LEADING basis-relabelling gate, so every mutation of the
; borrowed parent is placed by the old legs too. The window lemma's own pins are
; lowering_inloop_derived_cond_leading_gate.ll (the rolled leading gate) and
; lowering_live_record_dead_compare_flag_discharged.ll (the `M == At` adjacency).
;
; MUTATION (both directions verified): make the fan-out guard count `OutOfPlace`
; again and this fixture goes red on the accept; make `onRail` peel by shape again
; and it goes red on the missing `cq_template_add_i32_hl_unc` / `cqrt_free`.
;
; e2e twin: slice_control_grover_loop_range_oracle{,_unrolled} (byte-diff gate).
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

define i32 @slice() {
  %1 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %4

2:                                                ; preds = %11
  %3 = call i32 @cq_measure_si32(i32 %13)
  ret i32 %3

4:                                                ; preds = %0, %11
  %5 = phi i32 [ 0, %0 ], [ %14, %11 ]
  %6 = phi i32 [ %1, %0 ], [ %13, %11 ]
  %7 = add i32 %6, -6
  %8 = icmp ult i32 %7, 14
  br i1 %8, label %9, label %11

9:                                                ; preds = %4
  call void @cq_phi(double 0x400921FB54442D18)
  br label %11

11:                                               ; preds = %9, %4
  %13 = call i32 @cq_theta_si32(i32 %6, double -5.000000e-01)
  %14 = add nuw nsw i32 %5, 1
  %15 = icmp eq i32 %5, 0
  br i1 %15, label %4, label %2
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
; CHECK-NEXT: br label %2
; CHECK: 1:                                                ; preds = %2
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
; CHECK: 2:                                                ; preds = %2, %0
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = phi i32 [ 0, %0 ], [ %4, %2 ]
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 -6)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i32_hl(i32 %[[H_OP]], i32 14)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_ult_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP]], i32 14)
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[H_OP]], i32 %[[H]], i32 -6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = add nuw nsw i32 %[[V3]], 1
; CHECK-NEXT: %[[V5:[a-zA-Z0-9_.]+]] = icmp eq i32 %[[V3]], 0
; CHECK-NEXT: br i1 %[[V5]], label %2, label %1
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
; NOROUTE-NOT: cqrt_addc_
; NOROUTE-NOT: warning
; NOROUTE-NOT: error
; NOROUTE-NOT: call void @cqrt_cswap

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
