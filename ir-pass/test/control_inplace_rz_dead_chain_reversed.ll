; control_inplace_rz_dead_chain_reversed.ll — a phase region's TRANSPARENCY
; witness (bd test_C_libtooling-drbq Inc 2a, control-in-place-PRD §12.1).
;
; WHAT IT PINS: what happens to a register's OWN dead data chain across a
; tainted-condition phase region — the part the golden multiset audit needs to
; come out empty.
;
; THE SHAPE. `r` carries a two-link dead chain (`y = r*7`, `z = y*2`) computed
; BEFORE the region `if (q == 5) cq_phi(.9);`; `t = z*3` is measured after. So the
; interval [first gate reading r, the discharge point] STRADDLES the region, and
; the whole-DAG spine must reverse `z` then `y` and free both after the region.
;
; WHY IT IS LEGAL. `Uncomputation::preservesBorrowedParent` clause (d) needs
; every register the forward chain read to still hold its forward value when the
; adjoint fires. The kickback region's only gate is `cqrt_rz_i1` on its own flag,
; so `r`'s basis label is NEVER MOVED. The four lines the CHECK chain ends with
; (`mul_unc`, free, `mul_unc`, free) are that claim.
;
; (History: pre-3qlq the region was `r2 = cq_phi(r, .9)` on `r` itself. Under
; the swap route the licence was a GROUP property — both cswaps restore r's
; label, clause (d2), `TaintSet::RestoringRoutes`; Inc 2a moved it to the gate,
; an in-place `cqrt_rz_i32_controlled(f, r, θ)`, diagonal either way, which
; forced the Ry/Rz stem split in `ChainWalk::isInPlaceGateOn`. MEASURED then
; against the pre-2a binary: the routed stream had the identical four-line tail.)
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
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @dead_chain_across_region() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %y = mul nsw i32 %r, 7
  %z = mul nsw i32 %y, 2
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %t  = mul nsw i32 %z, 3
  %m1 = call i32 @cq_measure_si32(i32 %t)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %m3 = call i32 @cq_measure_si32(i32 %r)
  %s1 = add nsw i32 %m1, %m2
  %s2 = add nsw i32 %s1, %m3
  ret i32 %s2
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
; CHECK: define i32 @dead_chain_across_region() {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H1]], double 3.000000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H1]], i32 7)
; CHECK-NEXT: %[[H_OP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H_OP]], i32 2)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[H_OP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H_OP2]], i32 3)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[H_OP2]], i32 %[[H_OP]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP2]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[H_OP]], i32 %[[H1]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H_OP3]])
; CHECK-NEXT: %[[M4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H1]])
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M]], %[[M4]]
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S1]], %[[M5]]
; CHECK-NEXT: ret i32 %[[S2]]
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
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: phi i32

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 1 and 1 here.
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
