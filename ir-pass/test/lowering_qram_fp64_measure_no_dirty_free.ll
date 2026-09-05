; lowering_qram_fp64_measure_no_dirty_free.ll — ACCEPT (bd 38t2): the SHARP
; DISCRIMINATOR at fp width. A coherent fp carrier (`%cp = Rz(Ry)`) is stored at a
; tainted index, LOADED BACK at a DIFFERENT tainted index, given an in-place user
; `cq_phi_f64`, then MEASURED. This is the shape a naive "storing a carrier
; dephases → miscompile" analysis flags — but it is SOUND: the compiler emits
; EXACTLY the user's forward gate stream (alloc/ry/rz/ry/store/ry/load/rz/measure)
; with ZERO cqrt_free and ZERO `_unc` in the measured cone (the measured terminal
; takes the whole-DAG `InsertTerms`-empty bail). Emitted == written = correct-by-
; construction; the never-freed carrier/cell/index entanglement is unobservable at
; a computational-basis measure (measurement immunity, memory
; 7-5-qram-coherent-return-nocloning). NO compiler-inserted measurement/dirty-free
; can diverge from the faithful reversible-QRAM semantics (bd
; [38t2-fp-cell-commits-to-basis-sound]). Distinct tainted indices q != p defeat
; store->load forwarding and keep the array live.
;
; ⚠ THE FINAL GATE WAS A CHAINED `cq_theta_f64` UNTIL M-A INCREMENT 3, AND THAT
; VARIANT NOW DECLINES. Read this before assuming the change was cosmetic. With an
; in-place Ry there, `%h_cast4` (the fptosi rail holding the load index `pi`) and
; `%h3` (its `cqrt_alloc_f64` parent) are dead, undischarged, entangled ANCESTORS
; of the loaded rail at a NON-DIAGONAL gate — the loaded value is `[pi==qi]·carrier`,
; a function of `pi`, so the wire's reduced state is diagonal and the Ry acts on a
; mixture. Owner ruling (2026-08-27 / 2026-08-28, bd test_C_libtooling-6uqc):
; "emitted == written" is not a soundness argument at a non-diagonal gate over a
; live record, and that variant is now the negative fixture
; lowering_reject_live_record_qram_fp64_load_index.ll — same module, verbatim.
;
; WHY `cq_phi_f64` IS THE RIGHT REPLACEMENT and not a retreat: an Rz is DIAGONAL,
; so it COMMUTES with every basis record standing beside it and the dephasing
; argument does not reach it. Every property bd 38t2 pinned survives unchanged —
; no `_unc`, no `cqrt_free`, no `cqrt_copy`, no compiler-inserted measurement in
; the measured coherent-fp cone — and the CHECK-NOT block below is the same block
; it always was. What is NOT pinned here any more is the phase→amplitude
; interference observation; that is the reject twin's job now.
; (Measured, and it is why the obvious edit was not taken: simply deleting the
; final gate and measuring `%v` directly does NOT preserve this fixture — the
; whole-DAG spine then emits `cqrt_copy_f64` + `cqrt_qram_load_f64_unc` +
; `cqrt_free` + a full reversal, i.e. every CHECK-NOT below fires.)
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
; 27 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @shadow_fp_measure(double %u0) {
entry:
  %arr = alloca [8 x double], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 64, i1 false)
  %c  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  call void @cq_phi(double 3.000000e-01)
  %q  = call double @cq_theta_f64(double 0.0, double 1.000000e-01)
  %qi = fptosi double %q to i32
  %iq = sext i32 %qi to i64
  %gq = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %iq
  store double %c, ptr %gq, align 8
  %p  = call double @cq_theta_f64(double 0.0, double 2.000000e-01)
  %pi = fptosi double %p to i32
  %ip = sext i32 %pi to i64
  %gp = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %ip
  %v  = load double, ptr %gp, align 8                              ; load-back at a DIFFERENT index
  call void @cq_phi(double 1.000000e+00)  ; in-place user Rz — DIAGONAL
  %m  = call double @cq_measure_f64(double %v)
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
; CHECK: define double @shadow_fp_measure(double %u0) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[ARR1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 8)
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H2]], double 1.000000e-01)
; CHECK-NEXT: %[[H_CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_qram_store_f64(i32 %[[ARR1]], i32 %[[H_CAST]], i32 %[[H]])
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H3]], double 2.000000e-01)
; CHECK-NEXT: %[[H_CAST4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %[[H3]])
; CHECK-NEXT: %[[V0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARR1]], i32 %[[H_CAST4]])
; CHECK-NEXT: %[[QRET:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64(i32 %[[V0]], i32 %[[QRET]])
; CHECK-NEXT: call void @cqrt_qram_load_f64_unc(i32 %[[V0]], i32 %[[ARR1]], i32 %[[H_CAST4]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V0]])
; CHECK-NEXT: call void @cq_template_fptosi_f64_to_i32_unc(i32 %[[H_CAST4]], i32 %[[H3]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CAST4]])
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H3]], double -2.000000e-01)
; CHECK-NEXT: call void @cqrt_qram_store_f64_unc(i32 %[[ARR1]], i32 %[[H_CAST]], i32 %[[H]])
; CHECK-NEXT: call void @cq_template_fptosi_f64_to_i32_unc(i32 %[[H_CAST]], i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CAST]])
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H2]], double -1.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: %[[M5:[a-zA-Z0-9_.]+]] = call double @cqrt_measure_f64(i32 %[[QRET]])
; CHECK-NEXT: ret double %[[M5]]
; CHECK-NEXT: }

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE.  No positive directive may enter this prefix: a
; positive WINDOWS every negative after it, which is how an injected gate
; escaped 20 of 20 blocks in bd drbq Inc 3 (F-L6-1) and again in Inc 4.
; NOROUTE-NOT: cqrt_cswap
;   ^ the swap route is retired — no work rail, so no Fredkin
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
;
; MEASURED NOT APPLICABLE to this fixture (the candidate FIRES on the clean
; output, so asserting it would be false).  Recorded rather than dropped in
; silence — an absent assertion nobody explained is how a fence rots:
;   * cqrt_copy   (present in this fixture's own output)

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
