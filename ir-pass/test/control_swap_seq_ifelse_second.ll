; control_swap_seq_ifelse_second.ll — ACCEPT.
;
; ⚠ THIS FIXTURE PINNED A DECLINE AND NOW PINS AN ACCEPT.  It was flip #10 of the
; twelve DECLINE->ACCEPT flips the register-free `cq_phi` migration produced, and
; it is rewritten here on the verdict of the Rule-13 flips lens
; ($SP/progress/review_flips.md), which graded all twelve and found ZERO
; over-accepts.  It was called `control_swap_reject_seq_ifelse_second.ll`.
;
; OLD ASSERTION (measured on the pre-3qlq ORACLE, which still renders it on this
; file's PRE-migration form): `value-arm swap-route under quantum control`.
;
; WHAT THE OLD DECLINE PROTECTED: **NOTHING.**  This is the one flip whose old
; header said so itself — "this is an over-DECLINE, and deliberately left
; standing".  bd `hcrg` fixed the sequential-region ORDER bug but left this cell
; declining because `isValueChangingOp` read the PREVIOUS region's merge PHI as a
; new basis value, so the follower's routed base looked like a fresh register.
;
; WHY THE PROPERTY NO LONGER EXISTS: the cause WAS that merge phi.  A
; register-free region has none, and the follower's compare reads `%q` directly.
; A documented over-decline now lowers — a genuine CAPABILITY GAIN, and this is
; the only `hcrg` sequential-chain cell whose FOLLOWER is an `if/else`.
;
; ⚠ THE SEQUENTIAL PATH HAS NOT LOST ITS STALENESS FENCE, measured: a NON-DIAGONAL
; gate placed between the two regions renders
; `condition predates a non-diagonal gate`.  What was lifted is the structural
; over-decline, not a correctness guard.
;
; ⚠ EMISSION ORDER vs SOURCE ORDER, and the stream below is the witness: `hcrg`
; Kahn-sorts the regions and may emit the FOLLOWER first, but each emitter inserts
; POSITIONALLY into its own pred block, so region 1's whole quadruple appears
; strictly BEFORE region 2's first mint.  Unitary:
; `e^{i(a·[q>5])} · e^{i(c·[q>3] + d·[q<=3])}`.  STRICT stage 2b: 2 frees, 2 verified.
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

define i32 @example(i32 %u0, double %a, double %c, double %d) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  call void @cq_phi(double %a)
  br label %m1
m1:
  %c2 = icmp sgt i32 %q, 3
  br i1 %c2, label %t2, label %f2      ; an IF/ELSE follower — no Pred edge
t2:
  call void @cq_phi(double %c)
  br label %m2
f2:
  call void @cq_phi(double %d)
  br label %m2
m2:
  %m = call i32 @cq_measure_si32(i32 %q)
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
; CHECK: define i32 @example(i32 %u0, double %a, double %c, double %d) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP1]], double %a)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double %c)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double %d)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M2]]
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
; NOROUTE-NOT: fsub double
;   ^ the 2b BY-DIFFERENCE arithmetic. A kickback passes each arm's angle to its OWN gate VERBATIM, so no `fl(A-B)` is ever computed and the whole 2b residual (unbounded absolute-radian error, inf/NaN from two finite arms, the 2^-40 kAngleSelectMaxRoundingRad fence) has no object. This is the instruction a reviewer re-enabling the by-difference path would reintroduce.
; NOROUTE-NOT: fadd double
;   ^ the other half of the by-difference arithmetic (the unconditional twin's angle recombination).

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-3: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 3 and 3 here.
; MDCNT-COUNT-3: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
