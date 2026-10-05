; lowering_reject_live_record_qram_fp64_load_index.ll — WARNING (was DECLINE): the LOAD-INDEX
; ancestors of a QRAM read are live basis records of the loaded rail (M-A
; Increment 3, bd test_C_libtooling-6uqc).
;
; ⚠ THIS FILE REVERSES A SHIPPED, RULE-13-CLEARED POSITIVE, BY OWNER RULING.
; The module below is byte-for-byte the program that shipped as
; lowering_qram_fp64_measure_no_dirty_free.ll (bd 38t2). That fixture's thesis was
; "the compiler emits EXACTLY the user's forward gate stream, with zero
; `cqrt_free`, zero `_unc` and no inserted measurement in the measured cone —
; emitted == written = correct-by-construction". THE EMISSION CLAIM IS STILL TRUE
; AND IS STILL PINNED (the rewritten
; lowering_qram_fp64_measure_no_dirty_free.ll keeps every CHECK-NOT); what the
; owner ruled (2026-08-27 / 2026-08-28, bd test_C_libtooling-6uqc) is that
; "emitted == written" is NOT a soundness argument when a live entangled record
; stands at a NON-DIAGONAL gate. That is the whole premise of this campaign.
;
; THE PHYSICS, in the stream's own terms. The emitted forward program is (the
; uncontrolled `cq_phi(0.3)` is a global phase and is deleted):
;     %arr1    = cqrt_qram_alloc_f64(8)
;     %h       = cqrt_alloc_f64(%u0) ; ry(0.5)                  the carrier
;     %h2      = cqrt_alloc_f64(0.0) ; ry(0.1)                  index register q
;     %h_cast  = cq_template_fptosi_f64_to_i32(%h2)             qi
;     cqrt_qram_store_f64(%arr1, %h_cast, %h)
;     %h3      = cqrt_alloc_f64(0.0) ; ry(0.2)                  index register p
;     %h_cast4 = cq_template_fptosi_f64_to_i32(%h3)             pi
;     %0       = cqrt_qram_load_f64(%arr1, %h_cast4)            <-- THE WIRE
;     cqrt_ry_f64(%0, 1.0)                                      <-- T
;     cqrt_measure_f64(%0)
; The loaded value is `[pi == qi] · carrier` — a function of `pi`. `%h_cast4`
; (the fptosi rail holding `pi`) and `%h3` (the alloc rail holding `p`) are
; therefore BASIS RECORDS of the wire's value. `%h_cast4` is discharged by the
; M-B interior partition right after the load (a load is an interior consumer of
; its index); `%h3`, an alloc rail carrying the Ry that minted `p`, can never be
; (it stays a borrowed parent), so it is dead, undischarged and entangled when the
; chained `cqrt_ry_f64(%0, 1.0)` fires. (Corrected 2026-10-01, bd r2j3.1: this
; paragraph said NEITHER rail is uncomputed, which the pinned stream below already
; contradicted for `%h_cast4`. Since r2j3.1 the STORE's index `%h_cast` is
; discharged after the store the same way; that changes the stream, not the
; warning.) The wire's reduced
; state is diagonal in `pi`, so the Ry — the very phase-to-amplitude conversion
; the original fixture existed to demonstrate — acts on a MIXTURE. That is bd
; test_C_libtooling-nepx's argument, at fp width, with the records on the
; ancestor side.
;
; WHICH RAILS THE WALK REACHES, AND WHICH IT DOES NOT — this is the ruled-deferral
; boundary and it is visible here. The backward walk enters the load's operands:
; `%arr1` is a `cqrt_qram_alloc_*` handle and the walk STOPS there (severance
; class 4, the QRAM ARRAY CELL class, owner-ruled deferred 2026-08-27 point 4 and
; pinned by lowering_qram_array_record_chained_theta_accept.ll), so `%h`, `%h2`
; and `%h_cast` — reachable only THROUGH the array — are never counted. The
; decline is carried entirely by the INDEX side: `%h_cast4` and `%h3`.
;
; MEASURED AT HEAD (pre-Inc-3): `opt` exit 0 — this exact module lowered.
;
; ⚠ NOW A WARNING, NOT A DECLINE — owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, shipped as M-A Increment 7b): "we can always apply any
; unitary operation we want … it is the user's fault to have produced a badly
; functioning code" (Rule 17). The dephasing-by-leftover-record class is the
; USER's circuit, so `opt` prints `warning: …`, exits ZERO, and hands back the
; lowered module. THE ANALYSIS AND THE MESSAGE STRING ARE UNCHANGED — only the
; severity moved, so everything this header says about WHY the record counts
; still holds verbatim. The record is LEFT ALLOCATED and never freed (Rule 6 is
; untouched: nothing frees a rail that is not provably |0>), which the
; `NOFREEREC` prefix below pins alongside the gate that IS now emitted. The file KEEPS its
; `reject_` name deliberately — see RotationLowering.h, which also states what
; the ruling does NOT cover (every wrong-value and dirty-free guard stays loud).
;
; 3qlq(prep_a2): the FileCheck assertions below were RE-DERIVED from this
; fixture's own output under the Inc-1 (register-free `void @cq_phi(double)`)
; binary.  The pre-Inc-1 pin — a `cqrt_rz_<W>` or `cqrt_rz_<W>_controlled` on
; the user's REGISTER — asserted the gate PRD §1 shows is the identity on the
; marked branch (`cqrt_rz_<W>` is TENSORED, so a routed W-bit Rz applies
; `(-1)^popcount(target)` and can never mark |0..0>).  This file pins NO
; kickback (corrected 2026-10-05, bd zbz3): its one `cq_phi` is uncontrolled,
; so it is deleted as a global phase and no flag, `cqrt_rz_i1` or compare
; `_unc` is emitted.  What it pins is the ordered stream below (the forward
; store and load, each index cast discharged and freed right after its QRAM
; access, the chained Ry on the loaded rail, the measure), two frees (FCNT)
; and the M-A warning on stderr (WARN).  The fixture's PURPOSE (its header
; above) is unchanged.
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
; 30 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WARN < %t.err

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
  %w  = call double @cq_theta_f64(double %v, double 1.000000e+00)  ; T — chained Ry over the index records
  %m  = call double @cq_measure_f64(double %w)
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
; bd r2j3.1: the STORE's computed index is an M-B interior rail too (the store is
; never reversed and reads it once), so it is discharged right after the store:
; CHECK-NEXT: call void @cq_template_fptosi_f64_to_i32_unc(i32 %[[H_CAST]], i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CAST]])
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H3]], double 2.000000e-01)
; CHECK-NEXT: %[[H_CAST4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %[[H3]])
; CHECK-NEXT: %[[V0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARR1]], i32 %[[H_CAST4]])
; CHECK-NEXT: call void @cq_template_fptosi_f64_to_i32_unc(i32 %[[H_CAST4]], i32 %[[H3]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CAST4]])
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[V0]], double 1.000000e+00)
; CHECK-NEXT: %[[M5:[a-zA-Z0-9_.]+]] = call double @cqrt_measure_f64(i32 %[[V0]])
; CHECK-NEXT: ret double %[[M5]]
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
; NOROUTE-NOT: warning
; NOROUTE-NOT: call void @cqrt_free(i32 %h3)

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(

; ---------------------------------------------------------------------------
; STDERR assertions, CARRIED ACROSS VERBATIM.  These pin a WARNING, not a
; gate, so nothing about the register-free surface touches them; they are
; reproduced unchanged rather than re-derived, and the RUN lines above keep
; their original spelling.
; WARN: warning{{.*}}in function shadow_fp_measure{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: warning
