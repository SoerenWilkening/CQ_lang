; control_swap_switch_datamux_angle_runtime.ll — ACCEPT.
;
; ⚠ THIS FIXTURE PINNED A DECLINE AND NOW PINS AN ACCEPT.  It was flip #11 of the
; twelve DECLINE->ACCEPT flips the register-free `cq_phi` migration produced, and
; it is rewritten here on the verdict of the Rule-13 flips lens
; ($SP/progress/review_flips.md), which graded all twelve and found ZERO
; over-accepts.  It was called `control_swap_reject_switch_datamux_angle_runtime.ll`.
;
; OLD ASSERTION (measured on the pre-3qlq ORACLE, which still renders it on this
; file's PRE-migration form): `rotation angle under quantum control`.
;
; WHAT THE OLD DECLINE PROTECTED: bd drbq Inc 2b's CLEARANCE NARROWING TO CONSTANT
; ARMS (blocker F-11), asked here on the `yn71` onward-control fixpoint (`plan2`)
; path — a run-time arm made the compiler synthesize an `fsub` whose error is
; unbounded in absolute radians and can be `inf`/`NaN` from two FINITE arms.
;
; WHY THE PROPERTY NO LONGER EXISTS: under kickback there is NO `fsub` — asserted
; below by the whole-file negative on `fsub double` (spelled in the NOROUTE
; block, not quoted here — FileCheck reads a directive token ANYWHERE on a
; line, so quoting one in prose mints a bogus directive), and MEASURED — and each
; run-time arm reaches its own `cqrt_rz_i1` verbatim.  Same ground on which
; `control_angle_select_reject_runtime_arms_rz.ll` became an accept.
;
; ⚠⚠ CONTINGENT ON PRD §12 Q3.  This increment proceeds on Q3's ASSUMED answer
; (run-time angle arms ARE admitted for the phase stem).  **IF THE OWNER ANSWERS
; Q3 "NO", THIS FILE AND `control_angle_select_reject_runtime_arms_rz.ll` BOTH
; REVERT TO DECLINES** — they are the two cells that ride on it, and they are the
; only two.  A reader finding this file green after a "no" ruling has found a
; missed revert, not a capability.
;
; ⚠ WHAT THIS CELL ADDS OVER `..._runtime_arms_rz.ll`: the angle select here is
; reached through the 4.5 SWITCH DATA MUX and the `plan2` onward-control fixpoint,
; not from a plain diamond.  The data mux itself is UNCHANGED — an `alloc(3)`
; preload plus two `cqrt_copy_i32_controlled` XOR-deltas — and `%out` is unchanged
; between the angle-select flag's mint and its strip (only the DIAGONAL `rz_i1`
; and the `cqrt_x` pair on the flag intervene), so the strip zeroes the flag and
; the free is clean.  `%out` and the two delta rails are left ALLOCATED, which is
; Rule-6-legal and pre-existing 4.5 behaviour, not something this flip introduced.
; ⚠ Note the two `cqrt_copy_i32_controlled` below are why the BLANKET
; `_controlled` negative is absent from this file's NOROUTE block: the generator
; MEASURED it as inapplicable and dropped it, which is exactly why the NARROW
; `cqrt_rz_{{[a-z0-9]+}}_controlled(` twin exists and is present.
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
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %u1, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %rm = phi i32 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ]
  %c = icmp ne i32 %rm, 0
  %ang = select i1 %c, double %a, double %b
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %qx)
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
; CHECK: define i32 @example(i32 %u0, i32 %u1, double %a, double %b) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H4]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: %[[DELTA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 4)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[H_CMP]], i32 %[[DELTA]], i32 %[[OUT]])
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[DELTA2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 10)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[H_CMP1]], i32 %[[DELTA2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: %[[H_CMP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[OUT]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP3]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP3]], double %b)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP3]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP3]], double %a)
; CHECK-NEXT: call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[H_CMP3]], i32 %[[OUT]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP3]])
; CHECK-NEXT: %[[M5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H4]])
; CHECK-NEXT: ret i32 %[[M5]]
; CHECK-NEXT: }

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE.  No positive directive may enter this prefix: a
; positive WINDOWS every negative after it, which is how an injected gate
; escaped 20 of 20 blocks in bd drbq Inc 3 (F-L6-1) and again in Inc 4.
; NOROUTE-NOT: cqrt_cswap
;   ^ the swap route is retired — no work rail, so no Fredkin
; NOROUTE-NOT: call void @cqrt_rz_{{[a-z0-9]+}}_controlled(
;   ^ ⚠ NARROW TWIN of the blanket `_controlled` above, and it exists because the blanket one is DROPPED from any fixture that legitimately emits a controlled Ry or a controlled copy — and dropping it took the only catch for a controlled Rz with it. MEASURED: 4 of the 104 re-derived accepts were BLIND to an injected `cqrt_rz_i32_controlled` — the exact pre-Inc-1 TENSORED gate this increment removes — until this line was added. The width complement above cannot cover it either: it requires `(` immediately after the width, and `cqrt_rz_i32_controlled(` has `_controlled` in between.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
;   ^ the TENSORED per-register Rz is the defect this increment removes (PRD §1). ONE complement pattern, not an enumeration of six — the shipped ABI has NINE widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block (round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
; NOROUTE-NOT: call void @cq_phi(
;   ^ a surviving phase call is lowered or deleted, never left for the linker
; NOROUTE-NOT: cq_phi_
;   ^ the register form is a RESERVED NAME and declines (round-1 F-L6-1)
; NOROUTE-NOT: fsub double
;   ^ the 2b BY-DIFFERENCE arithmetic. A kickback passes each arm's angle to its OWN gate VERBATIM, so no `fl(A-B)` is ever computed and the whole 2b residual (unbounded absolute-radian error, inf/NaN from two finite arms, the 2^-40 kAngleSelectMaxRoundingRad fence) has no object. This is the instruction a reviewer re-enabling the by-difference path would reintroduce.
; NOROUTE-NOT: fadd double
;   ^ the other half of the by-difference arithmetic (the unconditional twin's angle recombination).
;
; MEASURED NOT APPLICABLE to this fixture (the candidate FIRES on the clean
; output, so asserting it would be false).  Recorded rather than dropped in
; silence — an absent assertion nobody explained is how a fence rots:
;   * cqrt_copy   (present in this fixture's own output)
;   * _controlled   (present in this fixture's own output)

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 2 and 2 here.
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
