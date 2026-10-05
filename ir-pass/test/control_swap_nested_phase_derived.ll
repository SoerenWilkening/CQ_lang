; control_swap_nested_phase_derived.ll — ACCEPT spec (§8 derived-base probe):
; depth-2 phase nest whose OUTER condition is a DERIVED compare that provably
; survives clang -O1 — an FP carrier `q + 1.0 > 5.0` (an integer `q+1>5` folds to
; `icmp sgt q,4` and exercises nothing; document, don't fight, the canonicalizer).
;
; The outer flag is minted from `fcmp ogt` on the `fadd` result
; (`cq_template_fadd_f64_hl`), the inner flag from `fcmp olt` on q itself. The
; QUANTUM HANDLE is f64 (NOT an angle; the same class as
; control_swap_diamond_derived_f64.ll). Both levels lower by kickback: the outer
; phase on f1, the inner on a fresh |0> AND node `g = f1 ∧ f2` (`cqrt_toffoli`),
; uncomputed and freed before the two flag strips.
;
; THE OUTER CHAIN IS DISCHARGED (bd 7xsh, 2026-10-05; FCNT 3 -> 4, DELIBERATE).
; Measured first on cq-opt sha256 50a6f549 (bd zbz3 item 11): the stream never
; uncomputed the outer chain's `cq_template_fadd_f64_hl` rail (H_OP) — FCNT pinned
; three frees (g and the two flags) and stage 2b reported "3 template rail mint(s)
; of which 1 left dirty": `q + 1.0` stood allocated, entangled with q. Cause,
; INSTRUMENTED (not inferred): H_OP is an M-B interior rail discharged after the
; outer strip with q BORROWED, and clause (d) (`borrowedParentsUnmoved`) refused
; exactly one user of q in that window — the INNER strip
; `cq_template_fcmp_olt_f64_hl_unc(H_CMP1, q, 9.0)` — because
; `preservesBorrowedParent` admitted no `_unc`.
;
; THE SEMANTIC EVIDENCE for the new stream. The inner strip XORs [q<9.0] onto its
; slot-0 flag and only READS q (slot 1; slot 2 is a literal): Σ_v |v><v|_q ⊗
; X^{[v<9]}, block-diagonal in q's basis, so q's LABEL over the window is the label
; the forward fadd read. Row (4) of `preservesBorrowedParent` now admits an
; emitter-RECORDED strip (`DischargedFlagGates`) reading the parent outside slot 0
; (`isRecordedStripReaderOf`, shared with `isInteriorConsumer` clause (c)). The
; discharge `fadd_f64_hl_unc(H_OP, q, 1.0)` is out-of-place XOR-compute, so it is
; EXACT for f64 whatever the rounding: H_OP holds fl(v+1.0) and the `_unc` XORs
; fl(v+1.0) recomputed from the same label, leaving |0> in a product state, and
; `cqrt_free(H_OP)` learns nothing. It lands after the outer strip (H_OP's last
; reader) and before the outer flag's free. f64 here is DATA (a `cq_theta_f64`
; register, not an angle — R3). The i32 twin is
; control_nested_phase_inner_reads_chain_source.ll; the leak neighbour (an
; UNRECORDED `_unc` reading the parent stays refused) is
; lowering_uncompute_interior_leak_unrecorded_strip_reads_parent.ll. A
; `cq_theta` on q after the nest still declines (`condition predates a
; non-diagonal gate`), unchanged.
;
; WI-1 lands DETECTION only — recognized as the accept shape, declined
; transitionally `nested control flow`, so this XFAILs. WI-3 lands the emitter and
; this XPASSes — delete the XFAIL then.
;
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

declare void @cq_phi(double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %a, double %b) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %d  = fadd double %q, 1.000000e+00
  %c1 = fcmp ogt double %d, 5.000000e+00
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = fcmp olt double %q, 9.000000e+00
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call double @cq_measure_f64(double %q)
  ret double %m
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
; CHECK: define double @example(double %u0, double %a, double %b) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %[[H]], double 1.000000e+00)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[H_OP]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double %b)
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f64_hl(i32 %[[H]], double 9.000000e+00)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H_CMP]], i32 %[[H_CMP1]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[G]], double %a)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H_CMP]], i32 %[[H_CMP1]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_fcmp_olt_f64_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], double 9.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP]], double 5.000000e+00)
; CHECK-NEXT: call void @cq_template_fadd_f64_hl_unc(i32 %[[H_OP]], i32 %[[H]], double 1.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call double @cqrt_measure_f64(i32 %[[H]])
; CHECK-NEXT: ret double %[[M2]]
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
; NOROUTE-NOT: phi double

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 2 and 2 here.
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
