; control_phase_kickback_inloop_reject_hoisted_temp.ll — ACCEPT-WITH-A-LEAK, and
; THE DISCRIMINATING CONTROL for the F-L7-2 / F-L5-1 fix (bd
; test_C_libtooling-3qlq Inc 1 part A, Rule-13 round 1). This file is not here to
; show something working; it is here so the widening beside it stays narrow, and
; it is MUTATION-VALIDATED (see below) rather than merely asserted.
;
;     int q = cq_theta(u, 0.3);
;     int p = q * 3;                                  // HOISTED loop-invariant
;     for (int i = 0; i < 8; ++i)                     // TEMPLATE rail
;         if ((p >> i) & 1) cq_phi(0.3);              // p read by the condition;
;     return cq_measure(q);                           // NOTHING gated in the body
;
; `clang -O1` output verbatim, K=8 so the loop stays genuinely ROLLED. The body
; gates nothing, so this reaches `invariantRegisterRoots` — unlike a body that
; gates `q`, which `collapseRailPhisIn` claims one level up.
;
; WHAT IT PINS. `markIfRailLocal`'s own comment names one hazard for anyone
; widening its "accumulating loop-invariant tainted input" refusal: "a recovered
; gate in the PREHEADER (does not repeat) with `At` in a body marked here
; (repeats K times) would emit K adjoints against ONE forward gate. … Widening it
; — even 'just' to admit a hoisted loop-invariant temp — makes it reachable, and
; NO SHIPPED TEST WOULD GO RED."
;
; `%3 = mul nsw i32 %2, 3` IS that hoisted loop-invariant temp: a value that
; lowers to `cq_template_mul_i32_hl`, minting a FRESH handle in the preheader,
; read by the body. `invariantRegisterRoots` REFUSES it — it admits only a ROOT
; MINT (a classical-arg-0 `cq_theta`, which lowers to `cqrt_alloc_<W>` and is
; excluded from the M-B interior partition OUTRIGHT by
; `ChainWalk::isInteriorTerminalHandle`'s clause (I1), so no `At` can ever be
; placed for it). So this loop is NOT marked iteration-local and its `and` rails
; LEAK, one per activation.
;
; ⚠ THE LEAK IS A KNOWN, UNFIXED RESIDUAL, AND THE HONEST GROUND IS THE PRIME
; DIRECTIVE, NOT A PROOF. Under a deliberate MUTATION that admits ANY
; loop-invariant tainted value, this program's 8 `and` rails DO discharge and the
; preheader `mul` rail is NOT reversed K times — i.e. the specific multiplicity
; hazard the comment names did not materialise on this shape when I looked for
; it. What that measurement establishes is that I could not EXHIBIT the hazard
; here, not that it is absent; the comment says it is reachable and untested, and
; widening a Rule-13-core clause on "I could not break it in one afternoon" is
; exactly the reasoning this project's history says not to trust. So the narrow
; form ships, the leak stands, and it is an OWNER QUESTION in
; `docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC1_NOTES.md` §1
; (cost: `int p = q*3;` before a per-bit loop is rolled≠unrolled; hand-unrolling
; works, and so does using `q` itself).
;
; MUTATION-VALIDATED, BOTH DIRECTIONS: deleting the root-mint test in
; `invariantRegisterRoots` makes this file's two `..._unc` negatives FIRE (the
; discharges appear), and the sibling
; `control_phase_kickback_inloop_derived_cond.ll` stays green. Its own witness is
; the reverse: before the fix its `UCNT` count was ZERO and every other directive
; in it still passed. One change, two shapes, opposite dispositions.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=EXITD < %t.cqd0.ll

; The region lowers; the PER-TRIP condition chain's rails do NOT discharge (the
; HOISTED `mul` rail does, at the loop exit — see the EXITD prefix below).
; CHECK: %[[P:.*]] = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[P]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

; ── CONVERTED IN PLACE, 2026-09-18 (bd `test_C_libtooling-tu9q`, piece P2) ────
;
; ⚠⚠ **THIS BLOCK USED TO BE A WHOLE-FILE PURE NEGATIVE CLAIMING "no discharge of
; the derived chain anywhere", AND IT NAMED THE WRONG MECHANISM.** Verbatim, so
; the correction is legible: *"These are the lines that FIRE if
; `invariantRegisterRoots` is ever widened to admit a hoisted template rail —
; which is precisely the shipped comment's warning, now with a test behind it."*
; It listed `@cq_template_and_i32_hl_unc` and `@cq_template_mul_i32_hl_unc`
; together, as one property.
;
; THEY ARE TWO PROPERTIES AND ONLY ONE OF THEM MOVED. The `mul` rail is minted in
; the PREHEADER; the `and` rail is minted PER TRIP. bd `tu9q`'s P2 gives the first
; one a loop-EXIT anchor — with `invariantRegisterRoots` COMPLETELY UNCHANGED and
; the loop body UNMARKED, so the prediction above is falsified twice over: the
; root admission did not widen, and the flip is a placement. The `and` rail still
; leaks, because an in-body `At` needs the marking that P0/P3 supply.
;
; THE FLIP IS CORRECT, and the argument is on the operands rather than by analogy:
; `%h_op` (= `%h * 3`) is minted once, its only in-loop users READ it (the per-trip
; `and`), nothing writes `%h` between the mint and the loop exit, so
; `cq_template_mul_i32_hl_unc(%h_op, %h, 3)` at the exit returns `%h_op` to |0⟩ on
; every branch and its `cqrt_free` is a proven-|0⟩ one (Rule 6). The adjoint runs
; ONCE against ONE forward execution — `multiplicityAgrees` is asked and both
; endpoints key to `nullptr`, since neither the preheader nor the exit is marked.
;
; ⚠ L8 RETIREMENT TRIGGER, RE-AIMED: the `and` negative below is what fires when
; the P0/P3 half lands, and THEN the cause really will be the root admission
; (clause (ii-d)) plus the component partition. Re-derive against the
; hand-unrolled twin's MULTISET at that point (owner ruling S3: byte identity is
; the instrument, not the claim). The four structural negatives are UNMOVED and
; keep their original meaning.
;
; THE HOISTED RAIL NOW DISCHARGES AT THE LOOP EXIT — in its own prefix.
; EXITD: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; EXITD-NEXT: call void @cqrt_free(i32 %h_op)
; EXITD-NEXT: %m = call i32 @cqrt_measure_i32(i32 %h)
;
; WHOLE-FILE PURE-NEGATIVE, narrowed to the property that still holds: the
; PER-TRIP chain does not discharge, and no route/controlled/phase machinery
; appears anywhere.
; NOROUTE-NOT: @cq_template_and_i32_hl_unc
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(


; ── Rule-13 ROUND-2 finding F-R2-1, the assertion repair ────────────────────
; Round 1 repaired three assertion families (the 8-width Rz negative, the
; `cqrt_x` negative, the `cqrt_free` count) in the corpus IT could see, and the
; merge brought in a set that had never been asked the same question. Measured by
; injection at `c4bd888`: `cqrt_rz_f80`/`f16` NOT CAUGHT in 18 accepts, an
; UNPAIRED `cqrt_x` (a wrong-branch phase) NOT CAUGHT in 21, an EXTRA
; `cqrt_free` (a hidden measurement, Rule 6) NOT CAUGHT in 20. Every accept in
; the branch now carries all three, and each is validated by injecting the line
; into this fixture's OWN output.

; The `cqrt_x` census. An UNPAIRED bracket is a wrong-branch phase.
; XCNT-COUNT-2: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; The `cqrt_free` census. An EXTRA free is a hidden measurement (Rule 6).
; ⚠ **THE COUNT MOVED 1 → 2 ON 2026-09-18 (bd `tu9q` P2), AND THE SECOND FREE IS
; NOT IN THE BODY.** Free #1 is the per-trip condition FLAG (`%h_cmp`, minted and
; stripped inside the loop); free #2 is the HOISTED `mul` rail at the LOOP EXIT,
; which the `EXITD` prefix above pins positionally. The census stays a census — it
; is still the line that catches an injected free — but a reader must not read
; `COUNT-2` as "two frees per trip". Re-derive it, do not relax it, if P0/P3 adds
; the per-trip chain's own pair.
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(



; ONE kickback gate in the rolled body, and no other. Added by Rule-13 round 2:
; an extra `cqrt_rz_i1` injected AFTER the last `cqrt_free` was MISSED here,
; because this file's only positives are the ordered body chain and its whole
; point is a NEGATIVE (no discharge), so nothing bounded the gate count.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #1
  %3 = mul nsw i32 %2, 3
  br label %6

4:                                                ; preds = %12
  %5 = tail call i32 @cq_measure_si32(i32 noundef %2) #1
  ret i32 %5

6:                                                ; preds = %1, %12
  %7 = phi i32 [ 0, %1 ], [ %13, %12 ]
  %8 = shl nuw nsw i32 1, %7
  %9 = and i32 %8, %3
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %12, label %11

11:                                               ; preds = %6
  tail call void @cq_phi(double noundef 3.000000e-01) #1
  br label %12

12:                                               ; preds = %6, %11
  %13 = add nuw nsw i32 %7, 1
  %14 = icmp eq i32 %13, 8
  br i1 %14, label %4, label %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
