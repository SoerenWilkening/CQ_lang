; control_swap_switch_datamux_onward_ctl_phase.ll — ACCEPT (yn71, Phase 4×6, the
; CONTROL case): a 4.5 all-ConstantInt switch DATA-MUX whose UNTAINTED merge `%out`
; feeds a NEW TAINTED-condition diamond applying a phase — `switch(q){0:r=7; 5:r=9;
; 17:r=11;}; if (r > 8) r = cq_phi(r, .25); measure r`. The data-mux merge is
; all-ConstantInt (data-untainted), so `if (r > 8)` was classical at round-1; the
; second propagation (`repropagateControlMerges`) taints `%out` → `icmp sgt %out, 8`,
; a new quantum-controlled branch on the data-mux answer.
;
; yn71 RE-DETECTS the diamond (`detectAndLowerOnwardControl`) and `SwapRouteEmit` emits
; the routed phase arm ON `%out`: mint the flag from `icmp(%out, 8)`, route `%out` into
; a |0> rail via `cqrt_cswap`, VERBATIM uncontrolled `cqrt_rz` on the rail, route back,
; free the rail, `icmp_inv`-strip + free the flag; the measure reads `%out`. This is
; the CONTROL twin of control_swap_switch_datamux_onward_arith.ll (dugh onward DATA).
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
; 7 line(s) of prose that annotated the OLD CHECK block were removed with
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
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 5, label %a1
                                i32 17, label %a2 ]
a0:
  br label %merge
a1:
  br label %merge
a2:
  br label %merge
merge:
  %rm = phi i32 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ], [ 11, %a2 ]  ; all-const data-mux -> %out
  %c2 = icmp sgt i32 %rm, 8                                          ; tainted only AFTER re-seed
  br i1 %c2, label %ph, label %m2                                    ; NEW tainted control on %out
ph:
  call void @cq_phi(double 0.25)
  br label %m2
m2:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
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
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: %[[DELTA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 4)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[H_CMP]], i32 %[[DELTA]], i32 %[[OUT]])
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[DELTA2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 10)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[H_CMP1]], i32 %[[DELTA2]], i32 %[[OUT]])
; CHECK-NEXT: %[[H_CMP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 17)
; CHECK-NEXT: %[[DELTA4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 8)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[H_CMP3]], i32 %[[DELTA4]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP3]], i32 %[[H]], i32 17)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP3]])
; CHECK-NEXT: %[[H_CMP5:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[OUT]], i32 8)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP5]], double 2.500000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP5]], i32 %[[OUT]], i32 8)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP5]])
; CHECK-NEXT: %[[M6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: ret i32 %[[M6]]
; CHECK-NEXT: }

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE.  No positive directive may enter this prefix: a
; positive WINDOWS every negative after it, which is how an injected gate
; escaped 20 of 20 blocks in bd drbq Inc 3 (F-L6-1) and again in Inc 4.
; NOROUTE-NOT: cqrt_cswap
;   ^ the swap route is retired — no work rail, so no Fredkin
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
;   * cqrt_copy   (present in this fixture's own output)
;   * _controlled   (present in this fixture's own output)

; Original negatives PRESERVED (re-measured on the Inc-1 output):
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: under quantum control

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-4: call void @cqrt_free(
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
; ACC-NOT: under quantum control
