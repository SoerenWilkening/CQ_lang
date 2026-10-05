; lowering_mc_reject_irreducible_site.ll — THE M-C IN-PLACE FENCE REFUSES A SITE
; INSIDE AN IRREDUCIBLE CYCLE (Increment 7 Rule-13 round, finding F1; bd
; test_C_libtooling-x67f). Rule 12's negative half for the G5 loop clause, at
; BOTH of the fence's entry points.
;
; THE DEFECT IT PINS — a WRONG VALUE, not a leak. G5 asked
; `LoopInfo::getLoopFor` alone. `LoopInfo` recognizes NATURAL loops only (one
; back edge to a header that dominates the body), so an IRREDUCIBLE cycle (two
; entries, no dominating header) returned null from it while executing its blocks
; K times. An in-place gate is a WRITE, and the fence is the only thing that
; makes it an at-most-once write, so the register was mutated ONCE PER TRIP:
;
;     source:   every trip recomputes  s = q - off  from the loop-invariant q,
;               and the measurement reads  q - off
;     emitted:  cqrt_addc_i32(h, -off)   <- trip 1
;               cqrt_addc_i32(h, -off)   <- trip 2, the SAME rail
;               cqrt_measure_i32(h)      ==  q - 2*off
;
; `opt` exited 0, the module was verify-clean, and `free_pairing_check.py` was
; clean too (the rail is measured, never freed, so no pairing rule fires) — the
; definition of a verify-clean silent miscompile. It was found by an adversarial
; probe (`a8e_irreducible_site_runnable.ll`, linked and RUN), never by a gate.
;
; THE FENCE IS NOW `LoopInfo` **OR** `blockCanRepeat` (FreePoint.h — the
; reachable-from-itself successor DFS, `LoopInfo` kept in front as the O(1) fast
; path). That is the SAME predicate bd test_C_libtooling-4p7j put behind the
; uncompute spine's three reversal backstops and `FreePoint`'s `kMsgLoopBackedge`
; loudness guard; the M-C in-place fence is its FIFTH consumer, and the lesson
; that memory records — when you fix a blind predicate, grep for EVERY consumer —
; is exactly the one this finding repeats. `blockCanRepeat` is a strict SUPERSET
; of "in a natural loop", so no acyclic CFG changes disposition.
;
; THE FALLBACK IS NOT A DIAGNOSTIC. Failing this fence means the op keeps the
; ORDINARY out-of-place lowering (a fresh rail per trip), which is the existing,
; correct disposition and byte-identically what the natural-loop spelling of the
; same program already got. There is no new message; there must not be one.
;
; REACHABLE FROM PLAIN clang -O1 C (corrected by the Inc-7 fix-round re-review,
; R1 -- the earlier 'hand-IR only' record was WRONG). The two goto-into-a-cycle
; spellings the Rule-13 round wrote (a8c, a8d) failed to reach the fence only
; because their second cycle-entry block was EMPTY, so SimplifyCFG folded the
; irreducible cycle into a self-loop; one volatile side effect in that block
; defeats the fold, and r1_irreducible_c.c then compiles at -O1 to a two-entry
; cycle (print<loops> reports NO loops) on which the PRE-FIX plugin, linked and
; run, measures q-6 where the source says q-3 -- opt rc=0, verify-clean,
; free_pairing_check clean. No shipped golden ever carried it (0 goldens moved).
; The paragraph below is the ORIGINAL bounded claim, kept as history: those two
; spellings decline FIRST at the two goto-into-a-cycle spellings the
; Rule-13 round wrote (`a8c`, `a8d`) both decline FIRST at
; `declineClassicalMuxes` — "cq taint escape: tainted value muxed by a
; classical-condition phi" — because in each of them the cycle's own result is
; live out of the cycle and `clang -O1` merges it with a phi. That is two
; measured spellings, NOT a proof that none exists, and the distinction is worth
; keeping: what makes the hole reachable HERE is that the mutated wire (`%q` /
; `%h`) is defined in `entry` and DOMINATES the cycle, so nothing upstream needs
; a phi for it at all. It is the same reachability story bd memory
; [uncompute-irreducible-gate-fence-2026-08-29] records for the WRITE side of the
; uncompute partitions, and the C surface widens toward it the moment
; `declineClassicalMuxes` or the 7.3 loop path widens.
;
; BOTH ENTRY POINTS, ONE FENCE (Rule 14). `inPlaceFenceHolds` is asked from
; `lowerOps` Phase 1 (a `BinaryOperator`, no plan) and from
; `lowerLateReassignments` (the already-lowered `cq_template_sub_i32_hl` call plus
; the M-B discharge plan). Both functions below convert on a plugin built before
; this fix — measured — so the file is a real red state for each:
;   @early_round_site — no region; the sub's only other user of the parent is the
;                       `cqrt_ry` in `entry`, which G6/G7 settle, so Phase 1
;                       converts it. (This half PRE-DATES Increment 7a: the base
;                       plugin `2afd9a7` emits the byte-identical mutating stream.
;                       Inc 7a did not introduce the hole, it added a second door
;                       into it.)
;   @late_round_site  — the derived-condition region's chain templates are
;                       undischarged `BinaryOperator`s when Phase 1 asks (arm (e)
;                       refuses), so only the LATE round, holding the plan that
;                       says the chain discharges before the site, could convert
;                       it — and pre-fix it did.
;
; `%off` is a volatile load (not a formal parameter, which G4 holds out
; independently) and the trip counter is volatile so nothing folds the cycle away.
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

; ── Phase-1 entry point ──────────────────────────────────────────────────────
; The cycle is {A, B}: `entry` branches to BOTH, so B has predecessors {entry, A}
; and A has predecessors {entry, B} — no header dominates the body, and
; `opt -passes='print<loops>'` reports NO loops for this function.
;
; the out-of-place fallback: a fresh rail, the parent register left intact
define i32 @early_round_site(i32 %u, ptr %p, i1 %c0, ptr %pc) {
entry:
  %off = load volatile i32, ptr %p, align 4
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br i1 %c0, label %A, label %B
A:
  br label %B
B:
  %s = sub nsw i32 %q, %off
  %n = load volatile i32, ptr %pc, align 4
  %n1 = add i32 %n, 1
  store volatile i32 %n1, ptr %pc, align 4
  %cb = icmp slt i32 %n1, 2
  br i1 %cb, label %A, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

; ── Late-round entry point ───────────────────────────────────────────────────
; The `lowering_mc_late_sub_after.ll` shape (a derived-condition phase region,
; whose chain the M-B interior partition discharges right after the flag strip)
; with the site moved INSIDE an irreducible cycle. The region lowers exactly as
; it does there — the plan is real and arm (d2) would settle the prior readers —
; and G5 is now the only thing between that plan and a per-trip mutation.
;
; the chain, the kickback and the full interior discharge — all of it BEFORE the
; cycle, which is precisely what makes arm (d2) willing and G5 load-bearing
; and the site still lowers OUT OF PLACE inside the cycle
define i32 @late_round_site(i32 noundef %0, ptr noundef %1, i1 %c0, ptr %pc) {
  %3 = load volatile i32, ptr %1, align 4
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = ashr i32 %4, 2
  %6 = add nsw i32 %5, %4
  %7 = icmp eq i32 %6, 5
  br i1 %7, label %8, label %10
8:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %10
10:
  br i1 %c0, label %A, label %B
A:
  br label %B
B:
  %12 = sub nsw i32 %4, %3
  %n = load volatile i32, ptr %pc, align 4
  %n1 = add i32 %n, 1
  store volatile i32 %n1, ptr %pc, align 4
  %cb = icmp slt i32 %n1, 2
  br i1 %cb, label %A, label %exit
exit:
  %14 = call i32 @cq_measure_si32(i32 noundef %12)
  ret i32 %14
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
; CHECK: define i32 @early_round_site(i32 %u, ptr %p, i1 %c0, ptr %pc) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[OFF:[a-zA-Z0-9_.]+]] = load volatile i32, ptr %p, align 4
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: br i1 %c0, label %A, label %B
; CHECK: A:                                                ; preds = %B, %entry
; CHECK-NEXT: br label %B
; CHECK: B:                                                ; preds = %A, %entry
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_hl(i32 %[[H]], i32 %[[OFF]])
; CHECK-NEXT: %[[N:[a-zA-Z0-9_.]+]] = load volatile i32, ptr %pc, align 4
; CHECK-NEXT: %[[N1:[a-zA-Z0-9_.]+]] = add i32 %[[N]], 1
; CHECK-NEXT: store volatile i32 %[[N1]], ptr %pc, align 4
; CHECK-NEXT: %[[CB:[a-zA-Z0-9_.]+]] = icmp slt i32 %[[N1]], 2
; CHECK-NEXT: br i1 %[[CB]], label %A, label %exit
; CHECK: exit:                                             ; preds = %B
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H_OP]])
; CHECK-NEXT: ret i32 %[[M1]]
; CHECK-NEXT: }
; CHECK: define i32 @late_round_site(i32 noundef %0, ptr noundef %1, i1 %c0, ptr %pc) {
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = load volatile i32, ptr %1, align 4
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ashr_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[H_OP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[H]], i32 %[[H_OP]])
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H_OP1]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP1]], i32 5)
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 %[[H_OP1]], i32 %[[H]], i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP1]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[H_OP]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: br i1 %c0, label %A, label %B
; CHECK: A:                                                ; preds = %B, %2
; CHECK-NEXT: br label %B
; CHECK: B:                                                ; preds = %A, %2
; CHECK-NEXT: %[[H_OP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_hl(i32 %[[H]], i32 %[[V3]])
; CHECK-NEXT: %[[N:[a-zA-Z0-9_.]+]] = load volatile i32, ptr %pc, align 4
; CHECK-NEXT: %[[N1:[a-zA-Z0-9_.]+]] = add i32 %[[N]], 1
; CHECK-NEXT: store volatile i32 %[[N1]], ptr %pc, align 4
; CHECK-NEXT: %[[CB:[a-zA-Z0-9_.]+]] = icmp slt i32 %[[N1]], 2
; CHECK-NEXT: br i1 %[[CB]], label %A, label %exit
; CHECK: exit:                                             ; preds = %B
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H_OP2]])
; CHECK-NEXT: ret i32 %[[M]]
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
; NOROUTE-NOT: cqrt_addc_
; NOROUTE-NOT: cqrt_xorc_
; NOROUTE-NOT: warning
; NOROUTE-NOT: error

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

; ---------------------------------------------------------------------------
; STDERR assertions, CARRIED ACROSS VERBATIM.  These pin a WARNING, not a
; gate, so nothing about the register-free surface touches them; they are
; reproduced unchanged rather than re-derived, and the RUN lines above keep
; their original spelling.
; SILENT-NOT: warning
; SILENT-NOT: error
