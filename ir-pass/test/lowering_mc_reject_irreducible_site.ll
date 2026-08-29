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
; HAND-IR, AND THE REACHABILITY CLAIM IS MEASURED AND BOUNDED. No C spelling
; that has been TRIED reaches this fence: the two goto-into-a-cycle spellings the
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
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOINPLACE < %t.cqd0.ll
;
; THE SINGLE STRONGEST ASSERTION IN THE FILE, and the one that goes red if G5 is
; ever narrowed back to `LoopInfo`: not one in-place gate anywhere in the module.
; It is its own prefix precisely so it is scoped to the WHOLE module rather than
; to the region before the first CHECK-LABEL.
; NOINPLACE-NOT: cqrt_addc_
; NOINPLACE-NOT: cqrt_xorc_

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; ── Phase-1 entry point ──────────────────────────────────────────────────────
; The cycle is {A, B}: `entry` branches to BOTH, so B has predecessors {entry, A}
; and A has predecessors {entry, B} — no header dominates the body, and
; `opt -passes='print<loops>'` reports NO loops for this function.
;
; CHECK-LABEL: define i32 @early_round_site(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; the out-of-place fallback: a fresh rail, the parent register left intact
; CHECK:      %[[OP:.*]] = call i32 @cq_template_sub_i32_hl(i32 %[[H]], i32 %off)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[OP]], double 2.000000e+00)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[OP]])
define i32 @early_round_site(i32 %u, ptr %p, i1 %c0, ptr %pc) {
entry:
  %off = load volatile i32, ptr %p, align 4
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br i1 %c0, label %A, label %B
A:
  br label %B
B:
  %s = sub nsw i32 %q, %off
  %r = call i32 @cq_phi_si32(i32 %s, double 2.000000e+00)
  %n = load volatile i32, ptr %pc, align 4
  %n1 = add i32 %n, 1
  store volatile i32 %n1, ptr %pc, align 4
  %cb = icmp slt i32 %n1, 2
  br i1 %cb, label %A, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; ── Late-round entry point ───────────────────────────────────────────────────
; The `lowering_mc_late_sub_after.ll` shape (a derived-condition phase region,
; whose chain the M-B interior partition discharges right after the flag strip)
; with the site moved INSIDE an irreducible cycle. The region lowers exactly as
; it does there — the plan is real and arm (d2) would settle the prior readers —
; and G5 is now the only thing between that plan and a per-trip mutation.
;
; CHECK-LABEL: define i32 @late_round_site(
; CHECK:      %[[H2:.*]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; the chain, the route and the full interior discharge — all of it BEFORE the
; cycle, which is precisely what makes arm (d2) willing and G5 load-bearing
; CHECK:      call void @cq_template_ashr_i32_hl_unc(i32 %{{.*}}, i32 %[[H2]], i32 2)
; CHECK:      call void @cqrt_free(i32 %[[CMP:.*]])
; and the site still lowers OUT OF PLACE inside the cycle
; CHECK:      %[[OP2:.*]] = call i32 @cq_template_sub_i32_hl(i32 %[[H2]], i32 %3)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[OP2]], double 2.000000e+00)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[OP2]])
define i32 @late_round_site(i32 noundef %0, ptr noundef %1, i1 %c0, ptr %pc) {
  %3 = load volatile i32, ptr %1, align 4
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = ashr i32 %4, 2
  %6 = add nsw i32 %5, %4
  %7 = icmp eq i32 %6, 5
  br i1 %7, label %8, label %10
8:
  %9 = call i32 @cq_phi_si32(i32 noundef %4, double noundef 0x400921FB54442D18)
  br label %10
10:
  %11 = phi i32 [ %9, %8 ], [ %4, %2 ]
  br i1 %c0, label %A, label %B
A:
  br label %B
B:
  %12 = sub nsw i32 %11, %3
  %13 = call i32 @cq_phi_si32(i32 noundef %12, double noundef 2.000000e+00)
  %n = load volatile i32, ptr %pc, align 4
  %n1 = add i32 %n, 1
  store volatile i32 %n1, ptr %pc, align 4
  %cb = icmp slt i32 %n1, 2
  br i1 %cb, label %A, label %exit
exit:
  %14 = call i32 @cq_measure_si32(i32 noundef %13)
  ret i32 %14
}
