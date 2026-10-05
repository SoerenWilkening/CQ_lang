; lowering_uncompute_interior_leak_route_in_interval.ll — ACCEPT since bd
; test_C_libtooling-7xsh (was a LEAK PROBE: M-B Increment 5, bd 4p7j Rule-13
; round, finding F4a). CLAUSE (d) with a user of the BORROWED parent strictly
; INSIDE the interval [first recovered gate reading it, `At`]. The name is kept so
; a merge cannot resurrect the old leak pin under it (CLAUDE.md L7).
;
; The clause-(d) scan has exactly two ways out for a mutation `M` of a borrowed
; parent `P`:
;   LEFT   `provablyBefore(M, First)` — M ran before the interval opened;
;   RIGHT  `provablyBefore(At, M)`    — M runs only after the discharge.
; Other fixtures pin LEFT (interior_straightline) and RIGHT
; (live_record_derived_cond_theta_discharged, interior_region_chain).
;
; THE SHAPE (hand IR): `%h_op = mul(%h, %h)` is minted BEFORE the region
; `if (a > 2) cq_phi(.25)` and read AFTER it (`mul %x, 3`, measured), so `At`
; lands after the region while `First` is before it.
;
; WHAT REFUSED IT UNTIL bd 7xsh. The region's condition is DIRECT, so its flag
; strip `cq_template_icmp_sgt_i32_hl_unc(%[[H_CMP]], %[[H]], 2)` reads the borrowed
; wire itself, inside the interval, and `preservesBorrowedParent` admitted no
; adjoint twin; the strip could not clear the positional scan either (after
; `First`, before `At`). The kickback's `cqrt_rz_i1` lands on the flag, not on
; `%[[H]]`. So `%h_op` was never uncomputed.
;
; THIS FILE NOW ACCEPTS, AND IT WAS THE WIDENING, NOT A LOST FENCE — checked as
; this header asked. The widening it recorded as owed is row (4) of
; `preservesBorrowedParent`: an emitter-RECORDED strip reading the parent outside
; its slot-0 flag (`isRecordedStripReaderOf`, the very predicate `isInteriorConsumer`
; clause (c) uses — "the same claim from the other side"). MEASURED: the old and
; new lowerings of this module differ by exactly the two lines
; `mul_i32_unc(%h_op, %h, %h)` + `cqrt_free(%h_op)`, after `%h_op`'s last reader.
; Hand trace, Ry(.5)|u0> = Σ_v a_v|v> on q:
;   mul(q, q)                 x = v*v                    (fresh rail)
;   icmp_sgt_hl(q, 2)         f = [v>2]; rz_i1(f, .25): branch phase on f
;   icmp_sgt_hl_unc(f, q, 2)  f = 0 — reads q, writes only f; free(f)
;   mul_hl(x, 3)              y = 3v^2                   (x's last reader)
;   mul_unc(x, q, q)          x = v^2 ⊕ v^2 = 0: q's label is v across the window
;                             (the strip is Σ_v |v><v|_q ⊗ X_f^{[v>2]})
;   cqrt_free(x)              |0> in a product state — nothing learned
;   measure(y), measure(q)    the program's joint distribution, phase kept
; The membership neighbour (an UNRECORDED `_unc` reading the parent stays
; refused) is lowering_uncompute_interior_leak_unrecorded_strip_reads_parent.ll.
;
; HISTORY, and why the name no longer describes the file. Increment 5 wrote it for
; a Phase-4 `cqrt_cswap` ROUTE pair on the parent inside the interval
; (`cqrt_cswap(flag, P, work)` relabels P between the forward gate and the
; adjoint). Increment 6's clause (d2) admitted a RECORDED route group lying wholly
; inside, and the strip became the refuser. drbq Inc 2a replaced the route with
; one `cqrt_rz_i32_controlled(flag, %h, .25)` (admitted by clause (1b)); bd 3qlq
; replaced that with the kickback. The verdict and the refusing strip are unchanged.
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

define i32 @interior_route_in_interval(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = mul i32 %q, %q
  %gt = icmp sgt i32 %q, 2
  br i1 %gt, label %arm, label %merge
arm:
  call void @cq_phi(double 2.500000e-01)
  br label %merge
merge:
  %y = mul i32 %x, 3
  %m = call i32 @cq_measure_si32(i32 %y)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m, %m2
  ret i32 %s
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
; CHECK: define i32 @interior_route_in_interval(i32 %u0) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[H]], i32 %[[H]])
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 2.500000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[H_OP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H_OP]], i32 3)
; CHECK-NEXT: call void @cq_template_mul_i32_unc(i32 %[[H_OP]], i32 %[[H]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: %[[M3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H_OP1]])
; CHECK-NEXT: %[[M4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = add i32 %[[M3]], %[[M4]]
; CHECK-NEXT: ret i32 %[[S]]
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

; Original negatives PRESERVED (re-measured on the Inc-1 output), minus
; `@cq_template_mul_i32_unc(` — the discharge bd 7xsh added (CHECK above):
; NOROUTE-NOT: @cq_template_mul_i32_hl_unc(
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)

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
