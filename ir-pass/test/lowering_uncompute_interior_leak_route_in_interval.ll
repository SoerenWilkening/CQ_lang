; lowering_uncompute_interior_leak_route_in_interval.ll — LEAK PROBE (M-B
; Increment 5, bd test_C_libtooling-4p7j Rule-13 round, finding F4a). CLAUSE (d)'s
; OWN ROUTE CASE: a Phase-4 `cqrt_cswap` route on a BORROWED parent, strictly
; INSIDE the interval [first recovered gate reading it, `At`], satisfies neither
; disjunct and leaks the group.
;
; The clause-(d) scan has exactly two ways out for a mutation `M` of a borrowed
; parent `P`:
;   LEFT   `provablyBefore(M, First)` — M ran before the interval opened;
;   RIGHT  `provablyBefore(At, M)`    — M runs only after the discharge.
; The shipped fixtures pin LEFT (the source `Ry` that mints the wire —
; interior_straightline) and RIGHT (the chained `cq_theta` after the discharge —
; live_record_derived_cond_theta_discharged; and a region route after it —
; interior_region_chain, then named interior_region_partial). THE STRICTLY-INSIDE
; CASE HAD NO FIXTURE, which is
; the one where an `_unc` would read a RELABELLED register: `cqrt_cswap(flag, P,
; work)` exchanges P's amplitude with the work rail on the flag-set branch, so
; between the forward gate and the adjoint P no longer holds what the forward
; gate read, and the "adjoint" would neither zero the rail nor be the forward's
; inverse. Freeing it would then be a hidden measurement (Rules 6/8).
;
; THE SHAPE (the hand-IR spelling of `x = a*a; m0 = measure(x < 3); if (a > 2)
; { a = cq_phi(a, .25); } measure(x > 100)` — the C form is
; `scratchpad/review-inc5/a19_cswap_interval_c.c` and lowers identically).
; `%h_op = mul(%h, %h)` is read BEFORE the region and again AFTER it, so `At`
; lands after the region while `First` is before it, and the emitter's own route
; pair sits between them.
;
; ⚠ RE-DISPOSITIONED BY M-B INCREMENT 6 — SAME VERDICT, DIFFERENT REASON, AND
; THE HEADER ABOVE IS NOW HISTORY. Increment 6 added clause (d2): the phase-arm
; emitter RECORDS its route as a matched group, and a group every member of which
; lies inside the interval IS admitted (it is the identity on the base's basis
; label, and an `_unc` is a label-only reader). So the two `cqrt_cswap` calls in
; this file are no longer what refuses it.
;
; WHAT REFUSES IT NOW, measured: the region's FLAG STRIP,
; `cq_template_icmp_sgt_i32_hl_unc(%[[FLAG]], %[[H]], 2)`. This region's
; condition is DIRECT, so the strip reads the borrowed source wire itself.
; `preservesBorrowedParent` proves only two shapes read-only (a diagonal
; `cqrt_rz_<W>` on the parent, and a forward reassigning producer) and an adjoint
; twin is neither, so the strip must clear the positional scan — and it cannot:
; it is after the interval opens (not LEFT) and before the discharge would go
; (not RIGHT), and it is not a route, so clause (d2) never looks at it.
;
; THAT IS AN OVER-DECLINE AND IS RECORDED AS ONE. A recorded strip demonstrably
; does not WRITE the operands in its shifted handle slots — that is the whole
; basis on which `isInteriorConsumer` admits it as a consumer — so admitting it
; in `preservesBorrowedParent` too would be the same claim from the other side.
; Increment 6 deliberately did not make it (its customers do not need it and the
; leak direction is free), and the widening is filed rather than assumed. If this
; file ever ACCEPTS, check that it was that widening and not a lost fence.
;
; NOTE WHAT IS *NOT* THE ARGUMENT, and it is why the route half moved. The route
; pair is self-cancelling — the second `cqrt_cswap` restores the basis label,
; which is why the emitter's own flag strip may read `%h` between the halves and
; why a chain SUNK past a whole region still discharges (`a9b_after_region.c`,
; LEFT). Increment 5 refused it anyway, on the grounds that clause (d) is a
; POSITIONAL proof and a data-uncompute driver that does not own the route should
; not reason about it. Increment 6 resolved that by having the OWNER record the
; pair, rather than by having this scan infer it.
;
; ⚠ AND SINCE drbq Inc 2a THERE IS NO ROUTE HERE AT ALL — SAY IT PLAINLY, BECAUSE
; THE FILE'S NAME NO LONGER DESCRIBES WHAT IT MEASURES. The §6a peephole lowers
; this FLAT phase region control-in-place: the quintuple
; `alloc(0); cswap; rz(rail); cswap; free(rail)` is one
; `cqrt_rz_i32_controlled(%[[FLAG]], %[[H]], .25)`. So the "strictly-inside route"
; that names this file is not emitted any more, and the clause-(d2) group
; exemption is not consulted (`TaintSet::RestoringRoutes` has no writer at HEAD).
;
; WHAT THE FILE MEASURES NOW, and why it is still worth its name in git history:
; the SAME verdict, from the SAME refusing element, with one MORE thing proven not
; to be it. The controlled Rz sits strictly inside the interval on the borrowed
; parent `%[[H]]`, and it is ADMITTED — `preservesBorrowedParent` clause (1b), a
; diagonal gate on both branches moves no basis label. The flag strip is still
; what refuses the discharge, exactly as the Increment-6 paragraph above records:
; it is after `First`, before `At`, and is neither a diagonal rotation nor a
; forward reassigning producer. If this file ever ACCEPTS, check that it was the
; filed strip widening and not a lost fence — that instruction is unchanged.
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

; Original negatives PRESERVED (re-measured on the Inc-1 output):
; NOROUTE-NOT: @cq_template_mul_i32_unc(
; NOROUTE-NOT: @cq_template_mul_i32_hl_unc(
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)

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
