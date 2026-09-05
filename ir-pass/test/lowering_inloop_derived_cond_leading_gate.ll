; lowering_inloop_derived_cond_leading_gate.ll — ACCEPT (bd test_C_libtooling-8h7d.5,
; Rule-13 ROUND 4, finding F-4). The rolled loop whose body puts a BASIS-RELABELLING
; GATE BEFORE the tainted region, and whose derived-condition ancilla chain therefore
; used to LEAK once per trip:
;
;     for (int i = 0; i < 2; ++i) {
;         q = cq_theta(q, 0.25);                   /* the LEADING Ry */
;         if ((q & 3) == 1) { q = cq_phi(q, PI); } /* a DERIVED condition */
;         q = cq_theta(q, -0.5);
;     }
;
; WHAT WAS WRONG. The M-B interior partition proves clause (d1) — "the borrowed
; parent holds, at every emitted `_unc`, the value it held when the forward gate
; ran" — over the window `(T_First, T_At)`, and the mutation it must place here is
; the NEXT iteration's leading `cqrt_ry`, which sits textually BEFORE `First` in the
; body. Rounds 1-3 spelt the "M is outside the window" legs with `First` in the
; barrier slot, so the forward walk from `First` reached that Ry around the back edge
; WITHOUT re-entering `First`, the leg failed, and the whole component was abandoned:
; `cq_template_and_i32_hl(%h, 3)` was minted, never `_unc`-reversed and never freed,
; and the trailing `cqrt_ry` then fired over a LIVE, ENTANGLED record of the wire
; (Rule 8 — a dirty entangled rail dephases under later interference).
;
; IT WAS INVISIBLE TO EVERY SHIPPED GATE. `opt` exited 0, `opt -verify` was clean,
; STRICT `free_pairing_check.py` reported 0 violations (it counts `cqrt_alloc` mints,
; and this rail is TEMPLATE-minted), and with no leading `cq_phi` to trip the M-A
; guard the run was SILENT. The only witness is the hand-unrolled twin, which
; discharges the chain — which is why the e2e pair
; slice_control_grover_loop_leading_gate{,_unrolled} ships with a byte-diff twin gate,
; and why tools/loop_twin_matrix.py now runs the whole prefix x region x suffix matrix.
;
; THE FIX is the window lemma at the borrowed-parent scan (Uncomputation.cpp). The
; certificate that places the leading Ry is (W2) — "every path `M` -> `At`
; re-executes `First`" — asked as the BARE barrier walk. Rounds 1-3 asked it through
; `provablyBeforePerActivation`, which bundles a `DT.dominates` conjunct that no step
; of the window proof uses; the leading Ry does not dominate the discharge point, so
; the leg failed on a premise it never needed. `M == At` is also REACHABLE here
; (`At` is `getNextNode()` of the last consumer of an owned rail, which is the
; TRAILING `cqrt_ry`), and (W2) places that one too.
;
; MUTATION (both directions verified): restore the `provablyBeforePerActivation`
; spelling of (W1)/(W2) and this fixture goes red on the missing
; `cq_template_and_i32_hl_unc` / `cqrt_free`.
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. Nothing else moves — the flag
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
; NOTE — the header above still NAMES a retired symbol (`cqrt_rz_<W>`,
; `cqrt_cswap` or a `_controlled` twin).  That prose is kept DELIBERATELY:
; it is the fixture's PURPOSE and the record of what the pre-Inc-1 pass
; emitted here.  Read it as history; the stream this file now ASSERTS is
; the derived one below, and the two are meant to differ.
;
; 15 line(s) of prose that annotated the OLD CHECK block were removed with
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

define i32 @slice() {
  %1 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %4

2:                                                ; preds = %12
  %3 = call i32 @cq_measure_si32(i32 %14)
  ret i32 %3

4:                                                ; preds = %0, %12
  %5 = phi i32 [ 0, %0 ], [ %15, %12 ]
  %6 = phi i32 [ %1, %0 ], [ %14, %12 ]
  %7 = call i32 @cq_theta_si32(i32 %6, double 2.500000e-01)
  %8 = and i32 %7, 3
  %9 = icmp eq i32 %8, 1
  br i1 %9, label %10, label %12

10:                                               ; preds = %4
  call void @cq_phi(double 0x400921FB54442D18)
  br label %12

12:                                               ; preds = %10, %4
  %14 = call i32 @cq_theta_si32(i32 %7, double -5.000000e-01)
  %15 = add nuw nsw i32 %5, 1
  %16 = icmp eq i32 %5, 0
  br i1 %16, label %4, label %2
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
; CHECK: define i32 @slice() {
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: br label %2
; CHECK: 1:                                                ; preds = %2
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
; CHECK: 2:                                                ; preds = %2, %0
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = phi i32 [ 0, %0 ], [ %4, %2 ]
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H_OP]], i32 1)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP]], i32 1)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[H_OP]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = add nuw nsw i32 %[[V3]], 1
; CHECK-NEXT: %[[V5:[a-zA-Z0-9_.]+]] = icmp eq i32 %[[V3]], 0
; CHECK-NEXT: br i1 %[[V5]], label %2, label %1
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
; NOROUTE-NOT: warning
; NOROUTE-NOT: error
; NOROUTE-NOT: call void @cqrt_cswap

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-2: call void @cqrt_free(
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
; SILENT-NOT: warning
; SILENT-NOT: error
