; control_swap_inloop_derived_cond.ll — ACCEPT (bd test_C_libtooling-8h7d.5, Phase
; 7.3 Increment 3). THE CUSTOMER SHAPE, reduced: a DERIVED-condition phase oracle
; and the S-dagger rotation, inside a classically-bounded loop.
;
;     int a = cq_theta(u0, 0.5);
;     for (int i = 0; i < 3; ++i) {
;         if (sqrt(a + 3.) <= 3.5) a = cq_phi(a, b);
;         a = cq_theta(a, -0.5);
;     }
;     return cq_measure(a);
;
; VERBATIM `clang -O1` OUTPUT (Rule 9 — note the polarity: `<= 3.5` is emitted as
; `fcmp ugt` with the gate arm as the FALSE successor, so the emitter brackets the
; arm's gate run with `cqrt_x`).
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)`, and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. On this NEGATED arm that also
; halves the `cqrt_x` count — the route bracketed EACH of its two cswaps (four
; `cqrt_x`), control-in-place brackets the arm's gate run ONCE (two).
;
; THIS FIXTURE IS ABOUT THE DISCHARGE, not the arm gate. The condition builds a
; three-rail chain (`sitofp` → `fadd` → `sqrt`) that is ENTANGLED with the
; register; if it is still allocated when the S-dagger `cqrt_ry` fires, the
; rotation is dephased. The hand-unrolled twin reverses and frees all three
; between the flag strip and the flag free — the M-B interior partition (bd 160a).
; Getting the ROLLED loop to emit the same thing needed four `canRepeat` fences
; and three `provablyBefore` readings to be re-asked PER ACTIVATION, each gated on
; the affirmative `IterationLocalBlocks` mark that `markIfRailLocal` grants:
;   * the chain is minted, consumed, reversed and freed inside ONE iteration, so
;     the adjoint count matches the forward count trip for trip;
;   * the register is the loop's PERSISTENT rail — read from anywhere, never a
;     recovered terminal, and left to the user's `cq_measure`;
;   * clause (d)'s interval is [this trip's `sitofp`, this trip's discharge], and
;     the body's `cqrt_ry` sits strictly BETWEEN two intervals, never inside one.
;
; The end-to-end witness is `tests/e2e/slice_control_grover_loop_derived.c`, whose
; golden is BYTE-IDENTICAL to its hand-unrolled twin's.
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
;   * phi
;
; NOTE — the header above still NAMES a retired symbol (`cqrt_rz_<W>`,
; `cqrt_cswap` or a `_controlled` twin).  That prose is kept DELIBERATELY:
; it is the fixture's PURPOSE and the record of what the pre-Inc-1 pass
; emitted here.  Read it as history; the stream this file now ASSERTS is
; the derived one below, and the two are meant to differ.
;
; 15 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare double @llvm.sqrt.f64(double)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice(i32 noundef %0, double noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  br label %6
4:                                                ; preds = %15
  %5 = tail call i32 @cq_measure_si32(i32 noundef %17)
  ret i32 %5
6:                                                ; preds = %2, %15
  %7 = phi i32 [ 0, %2 ], [ %18, %15 ]
  %8 = phi i32 [ %3, %2 ], [ %17, %15 ]
  %9 = sitofp i32 %8 to double
  %10 = fadd double %9, 3.000000e+00
  %11 = tail call double @llvm.sqrt.f64(double %10)
  %12 = fcmp ugt double %11, 3.500000e+00
  br i1 %12, label %15, label %13
13:                                               ; preds = %6
  call void @cq_phi(double %1)
  br label %15
15:                                               ; preds = %13, %6
  %17 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef -5.000000e-01)
  %18 = add nuw nsw i32 %7, 1
  %19 = icmp eq i32 %18, 3
  br i1 %19, label %4, label %6
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
; CHECK: define i32 @slice(i32 noundef %0, double noundef %1) {
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: br label %4
; CHECK: 3:                                                ; preds = %4
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
; CHECK: 4:                                                ; preds = %4, %2
; CHECK-NEXT: %[[V5:[a-zA-Z0-9_.]+]] = phi i32 [ 0, %2 ], [ %6, %4 ]
; CHECK-NEXT: %[[H_CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[H]])
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %[[H_CAST]], double 3.000000e+00)
; CHECK-NEXT: %[[H_INTR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sqrt_f64(i32 %[[H_OP]])
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %[[H_INTR]], double 3.500000e+00)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double %1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %[[H_CMP]], i32 %[[H_INTR]], double 3.500000e+00)
; CHECK-NEXT: call void @cq_template_sqrt_f64_unc(i32 %[[H_INTR]], i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_INTR]])
; CHECK-NEXT: call void @cq_template_fadd_f64_hl_unc(i32 %[[H_OP]], i32 %[[H_CAST]], double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[H_CAST]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CAST]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: %[[V6:[a-zA-Z0-9_.]+]] = add nuw nsw i32 %[[V5]], 1
; CHECK-NEXT: %[[V7:[a-zA-Z0-9_.]+]] = icmp eq i32 %[[V6]], 3
; CHECK-NEXT: br i1 %[[V7]], label %3, label %4
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
; NOROUTE-NOT: control flow inside a loop body
; NOROUTE-NOT: non-diagonal gate over a live derived record
; NOROUTE-NOT: call void @cqrt_cswap

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
