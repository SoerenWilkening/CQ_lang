; lowering_live_record_sibling_region_then_measured_accept.ll — ACCEPT: the
; ONE-INSTRUCTION DISCRIMINATION CONTROL for
; lowering_reject_live_record_sibling_region_after_theta.ll (M-A, bd
; test_C_libtooling-6uqc; the F1 ruling, 2026-08-28).
;
; SOURCE — the reject twin plus a single measurement:
;     cq_theta(&a, 0.5);
;     int w = a * 2;                     // THE WIRE
;     int c = a * 3;                     // the SIBLING
;     cq_theta(&w, 0.5);              // T — chained, in-place Ry on the wire
;     if (c == 5) cq_phi(3.0);
;     int mp = cq_measure(c);            // <-- THE WHOLE DIFFERENCE
;     return cq_measure(w) + cq_measure(a) + mp;
;
; WHY IT LOWERS. `%h_op1` (`c`) is still a rail entangled with the wire and still
; undischarged when the gate fires — the physics AT THE GATE is identical to the
; reject twin's. What changed is that its lineage now reaches an OBSERVING SINK:
; `cq_measure(c)` is a `cqrt_measure_i32` directly on `%h_op1`. Under the ruled
; clause 3 that makes it the program's own live data, and a live record's
; dephasing of the rotation is
; SOURCE SEMANTICS, not a compiler defect (owner ruling 2026-08-27 (1)) — exactly
; the principle that keeps lowering_stale_record_add_before_theta.ll green.
;
; THE OTHER TWO RAILS, so the accept is not read as "regions are fine now":
;   * `%h` — measured after the gate, so clause 3 exempts it the same way.
;   * `%h_cmp` — the region's eq flag, minted AFTER the gate. It is skipped by the
;     F2 existence test (`provablyBefore(T, R)`): a rail that is not allocated when
;     the `Ry` fires cannot dephase it. Note it would NOT be exempt on clause 3 —
;     its only users are the kickback `cqrt_rz_i1`, the `_unc` strip and
;     `cqrt_free`, none of which observe anything. That is the division of labour
;     between the two fixes, visible in one module.
;
; SINCE bd 3qlq Inc 1 the phase arm lowers by KICKBACK: ONE uncontrolled
; `cqrt_rz_i1` on the flag (drbq Inc 2a's `cqrt_rz_i32_controlled(flag, register,
; theta)` and the earlier `cqrt_cswap` swap route are both retired). The flag
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

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w  = mul i32 %q, 2                                          ; THE WIRE
  %c  = mul i32 %q, 3                                          ; the SIBLING — now observed
  %q2 = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T
  %cc = icmp eq i32 %c, 5
  br i1 %cc, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e+00)
  br label %merge
merge:
  %mp = call i32 @cq_measure_si32(i32 %c)                      ; the OBSERVING SINK
  %m  = call i32 @cq_measure_si32(i32 %q2)
  %m0 = call i32 @cq_measure_si32(i32 %q)
  %a  = add nsw i32 %m, %m0
  %r  = add nsw i32 %a, %mp
  ret i32 %r
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
; CHECK: define i32 @slice(i32 %u0) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[H_OP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H_OP]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H_OP1]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 3.000000e+00)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP1]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H_OP1]])
; CHECK-NEXT: %[[M3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H_OP]])
; CHECK-NEXT: %[[M4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[A:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M3]], %[[M4]]
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = add nsw i32 %[[A]], %[[M2]]
; CHECK-NEXT: ret i32 %[[R]]
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
; NOROUTE-NOT: cq rotation lowering
; NOROUTE-NOT: non-diagonal gate over a live derived record
; NOROUTE-NOT: call void @cqrt_cswap

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

; ---------------------------------------------------------------------------
; STDERR assertions, CARRIED ACROSS VERBATIM.  These pin a WARNING, not a
; gate, so nothing about the register-free surface touches them; they are
; reproduced unchanged rather than re-derived, and the RUN lines above keep
; their original spelling.
; SILENT-NOT: non-diagonal gate over a live derived record
