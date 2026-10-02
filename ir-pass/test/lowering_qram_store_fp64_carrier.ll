; lowering_qram_store_fp64_carrier.ll — ACCEPT (bd 38t2): a DEAD-scratch fp cell
; store of a COHERENT CARRIER. `%cp = Rz(Ry(theta))` is a superposition-with-relative-
; phase fp carrier; `arr[q] = %cp` stores it into a `[8 x double]` cell at a tainted
; index. This is FAITHFUL reversible QRAM: the store CNOT-copies the fp BIT PATTERN
; into the |0> cell, and the whole-DAG LIFO uncompute fires `cqrt_qram_store_f64_unc`
; FIRST — disentangling the carrier from the cell — and only THEN reverse-plays the
; carrier's own `cqrt_rz_f64`/`cqrt_ry_f64` adjoints and frees it clean (the Bennett
; order, NOT method-B: a CNOT-copy of a carrier into |0> preserves the phase in the
; JOINT amplitude, so the reversal is a clean identity — bd
; [38t2-fp-cell-commits-to-basis-sound]). PARITY with the shipped integer
; lowering_qram_store_dead_lifo.ll (the fp store is the identical W-bit CNOT-write;
; handles are always i32, only the symbol name changes). The array handle is a
; classical resource token, NEVER freed (§2.9). NO measurement (Rule 5).
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
;   * call void @cqrt_free(   [superseded by the FCNT count]
;
; NOTE — the header above still NAMES a retired symbol (`cqrt_rz_<W>`,
; `cqrt_cswap` or a `_controlled` twin).  That prose is kept DELIBERATELY:
; it is the fixture's PURPOSE and the record of what the pre-Inc-1 pass
; emitted here.  Read it as history; the stream this file now ASSERTS is
; the derived one below, and the two are meant to differ.
;
; 25 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare double @cq_theta_f64(double, double)

define void @shadow_fp_carrier(double %u0) {
entry:
  %arr = alloca [8 x double], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 64, i1 false)
  %c  = call double @cq_theta_f64(double %u0, double 5.000000e-01)   ; Ry superposition carrier
  call void @cq_phi(double 3.000000e-01)  ; Rz relative phase — the "answer"
  %q  = call double @cq_theta_f64(double 0.0, double 1.000000e-01)   ; tainted fp index
  %qi = fptosi double %q to i32
  %iq = sext i32 %qi to i64
  %gq = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %iq
  store double %c, ptr %gq, align 8                                 ; arr[q] = carrier (tainted fp value)
  ret void
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
; CHECK: define void @shadow_fp_carrier(double %u0) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[ARR1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 8)
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H2]], double 1.000000e-01)
; CHECK-NEXT: %[[H_CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_qram_store_f64(i32 %[[ARR1]], i32 %[[H_CAST]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_qram_store_f64_unc(i32 %[[ARR1]], i32 %[[H_CAST]], i32 %[[H]])
; CHECK-NEXT: call void @cq_template_fptosi_f64_to_i32_unc(i32 %[[H_CAST]], i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CAST]])
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H2]], double -1.000000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double -5.000000e-01)
; bd 5c5b (libcqops vmz9): %[[H2]] (seed +0.0) is born |0> and freed above; %[[H]]
; (runtime seed %u0) returns to |u0>, not |0>, so it is kept.
; CHECK-NEXT: ret void
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
; NOROUTE-NOT: cqrt_measure
; NOROUTE-NOT: cq taint escape

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
