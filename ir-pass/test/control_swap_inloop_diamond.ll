; control_swap_inloop_diamond.ll — ACCEPT (bd test_C_libtooling-8h7d.5, Phase 7.3
; Increment 3; owner ruling 2026-08-29). A FLAT (depth-1) tainted-condition PHASE
; diamond that lives wholly inside a classically-bounded loop body, with a
; loop-CARRIED routed base — the merge feeds the backedge and the routed `%q` is a
; loop-header phi. Source shape:
;
;     for (...) { if (q > 5) { q = cq_phi(q, b); } }   // q loop-carried
;
; THIS FILE WAS `control_swap_reject_inloop_diamond.ll` UNTIL 2026-08-29, AND THE
; FLIP IS THE INCREMENT. The d8jl guard declined every flat region on a CFG cycle
; for a STRUCTURAL reason — `RegionFlatten` erases the merge, which inside a loop
; can be the LATCH, dangling the header phi. Two things changed:
;   * the erase has repaired that since bd dugh (2026-07-04, AFTER d8jl was
;     written): `flattenRegion` runs `Pred->replaceSuccessorsPhiUsesWith(Merge,
;     Pred)` before the erase, which repoints exactly the header-phi incoming the
;     broken-module report was about — `Pred` becomes the new latch;
;   * `ControlDetect::flatRegionRollableInLoop` now ADMITS only a region whose
;     blocks all sit at one depth of a REDUCIBLE `LoopInfo` loop with a single
;     latch and no second cycle through the entry. Everything else keeps the
;     decline, irreducible cycles first (see the sibling
;     control_swap_reject_inloop_diamond_irreducible.ll, still RED).
;
; WHAT THE ROLLED FORM IS. IR size is independent of the trip count (PRD 7.3
; §2.1): ONE copy of the stream, inside the intact loop, and only the runtime
; trace grows. The loop-carried header phi is collapsed to its root mint by the
; round-2 rail analysis (`collapseFlattenedLoopRails`), which runs AFTER the
; flatten because that is the first point at which the merge phi is gone and the
; rail peels. The register `%h` is one physical qubit for the whole loop; the only
; ancilla left (the flag) is minted, used, stripped and freed INSIDE the iteration,
; so nothing dirty crosses the back edge.
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` fires as ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route — work-rail
; alloc, both `cqrt_cswap`s, the rail free — is gone entirely. Everything else
; below (flag mint, strip, flag free, the rolled CFG, the exit measure) is
; byte-identical to the routed form.
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
;   * phi i32 [ %[[H]]
;
; NOTE — the header above still NAMES a retired symbol (`cqrt_rz_<W>`,
; `cqrt_cswap` or a `_controlled` twin).  That prose is kept DELIBERATELY:
; it is the fixture's PURPOSE and the record of what the pre-Inc-1 pass
; emitted here.  Read it as history; the stream this file now ASSERTS is
; the derived one below, and the two are meant to differ.
;
; 9 line(s) of prose that annotated the OLD CHECK block were removed with
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

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %q, %merge ]       ; loop-carried routed base
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]      ; classical induction
  %c1 = icmp sgt i32 %q, 5                             ; TAINTED (quantum) condition
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)  ; phase arm (Rz)
  br label %merge
merge:
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n                      ; classical loop bound
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
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
; CHECK: define i32 @example(i32 %u0, double %b, i32 %n) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: br label %loop
; CHECK: loop:                                             ; preds = %loop, %entry
; CHECK-NEXT: %[[I:[a-zA-Z0-9_.]+]] = phi i32 [ 0, %entry ], [ %inext, %loop ]
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double %b)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[INEXT:[a-zA-Z0-9_.]+]] = add i32 %[[I]], 1
; CHECK-NEXT: %[[DONE:[a-zA-Z0-9_.]+]] = icmp sgt i32 %[[INEXT]], %n
; CHECK-NEXT: br i1 %[[DONE]], label %exit, label %loop
; CHECK: exit:                                             ; preds = %loop
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M1]]
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
; NOROUTE-NOT: classical-condition phi
; NOROUTE-NOT: control flow inside a loop body
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
