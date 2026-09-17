; control_phase_kickback_reject_inloop_invariant_cond_hoisted.ll — **ACCEPT since bd
; `test_C_libtooling-drbq.12` (2026-09-17).** It shipped as a DECLINE from Rule-13
; round-1 finding F-L5-3 (bd test_C_libtooling-3qlq Inc 1 part A, lens L5): the
; OVER-DECLINE that the shipped P6 accept fixture hid. The original header is kept
; verbatim below because it is the accurate account of why the program was refused.
;
;     int q = cq_theta(0, 0.5);
;     for (int i = 0; i < 2; ++i) { if (q == 5) cq_phi(PI); }   // q untouched
;     return cq_measure(q);
;
; `clang -O1` output verbatim. With NO gate on `q` in the body the condition
; register is LOOP-INVARIANT, so LICM hoists `%2 = icmp eq i32 %1, 5` into the
; PREHEADER (block `%0` here, NOT the loop header where the shipped accept
; fixture hand-writes it). `condWireDisposition`'s P4 precondition
; `Cond->getParent() != R.Pred` — an unbounded gap across blocks — then returned
; `DeclineNow` before any rotation clause ran.
;
; THIS IS bd `drbq.12`'s OVER-DECLINE ARRIVING AT THE PHASE STEM, where it did
; not previously exist. Under the retired register surface a phase arm always
; gated `q` (`q = cq_phi(q, θ)`), so the register was loop-VARIANT and the
; compare stayed put; the pre-3qlq oracle ACCEPTS this program's register
; spelling. Under kickback a pure-phase body gates nothing, so `if (q == k)
; cq_phi(θ)` alone in a loop is ALWAYS hoisted and ALWAYS declined. The Ry stem's
; identical class has had a fixture since drbq Inc 3
; (`control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll`); the phase stem
; had none, so nothing said the suite does not cover this spelling.
;
; TWO ONE-TOKEN WORKAROUNDS, both MEASURED to accept BEFORE this bead: gate the
; register in the body (`q = cq_theta(q, -0.5);`, i.e. an actual Grover diffusion —
; see `control_phase_kickback_inloop_body_gate.ll`), or make the threshold opaque
; (`volatile int off;` … `q == 5 + off`), which defeats LICM. Neither is needed now.
;
; ⚠ IT SHIPPED AS A DECLINE AND IT IS NOW AN ACCEPT. The sentence that stood here
; said it was *"LOUD AND SAFE (Prime Directive), so it ships as a decline rather than
; as a widening — `condWireDisposition`'s P4 clause is a POSITIONAL fence in the
; Rule-13 core and moving it is its own increment with its own adversarial round."*
; bd `drbq.12` IS that increment. P4 now admits a cross-block COMPARE whose gap
; `crossBlockCompareMintable` has walked with the evidence narrowed to a
; RAIL-RELABELLING gate on the CONDITION's own rail (`railWireClosure`, BothWays).
;
; ⚠ AND THE dtzb IN-PLACE `add`/`sub`/`xor` IS **NOT** IN THAT VOCABULARY. An earlier
; draft of this header said it was; that fence was BUILT, MEASURED as a pure
; OVER-DECLINE (`trackD2/probes/dtzb_flat_red.ll`) and REMOVED —
; `railRelabellingGateOn`'s own header says so in capitals. The real ground is the
; G6/G7 ORDER INTERLOCK: control emission runs BEFORE `lowerOps`, so when M-C decides,
; the flag mint and `_unc` strip already read the condition's handle and already sit
; AFTER anything in the gap, and G6 refuses in-place for a parent with a use it cannot
; prove earlier.;
; ⚠ RETIREMENT TRIGGER FOR THAT INTERLOCK, and it is an ORDER property rather than a
; semantic one, so name what would break the ORDER: (a) the day control emission no
; longer precedes `lowerOps` in `CQLoweringPass::run`, or (b) the day a PRE-LOOP
; `taint.InPlaceRailOps` commitment (`commitOutOfLoopInPlaceOps`) reaches an op inside
; the gap — that op then carries an owner and G5's self-marking clause stops G6 from
; re-asking the position question about it. Either one, and the removed fence is the
; shape to re-derive, against G6's answer at that point and NOT against the
; both-roots reading that made it an over-decline. This trigger is JOINED to the
; existing G6 pin (`railCondWireDisposition` / `chainedThetaBetweenDefAndBranch`
; headers: *"if M-C's G6 ever admits an in-place op on a rail with a later read, this
; ground is gone"*) rather than starting a second one.
;
; Only this paragraph
; and the directive block below moved; the module is byte-identical to the decline
; version, so the flip is pinned against unchanged input.
;
; ⚠ The file name still says `reject_` on purpose — the bd `gahu` precedent: a
; renamed fixture can be RESURRECTED by a merge (L8), leaving one module under two
; names with contradictory verdicts. The rename is filed, not taken.
;
; THE STREAM IS THE SHIPPED KICKBACK, per trip and inside the ROLLED body: mint the
; eq-flag from `%h`, `cqrt_rz_i1` on the FLAG carrying `!cq.branchphase`, the `_unc`
; strip, one `cqrt_free`. NOTHING is emitted on `%h` at all (Rule 7) — it is read as
; arg-0 of the mint and of the strip and by its measure, never `cqrt_x`-bracketed,
; never freed. ⚠ Do NOT read the `cqrt_rz_i1` as a restoration of the retired
; register Rz: its arg-0 is the FLAG ancilla, never a user register.
;
; RETIREMENT TRIGGER (L8): if the cross-block prong is ever narrowed back, this file
; returns to its inverted form, expecting
; `cq controlled lowering: condition predates a non-diagonal gate under quantum control`.
; Flip it back; never delete it. (Written without the literal directive tokens — lit
; scrapes those out of prose too.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NEG --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTRZ %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTMINT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTSTRIP %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTFREE %s < %t.cqd0.ll
; ---- MUTATION-MATRIX HARDENING (bd `test_C_libtooling-drbq.12`, 2026-09-17) ----
; Rule 12(c): a fixture is validated by MUTATION, not by re-reading its prefixes.
; The first injection-matrix run over this batch reported 21 MISSED over 9 accept
; fixtures — a stray `cqrt_ry` before the `ret`, a duplicated mint, a duplicated
; free, and a `cqrt_x` injected onto the USER REGISTER all slipped through, because
; no whole-file prefix counted those symbols here. The block below is the closure:
; an EXACT count per symbol (a `COUNT-n` followed by its own `-NOT`, which is what
; turns "at least n" into "exactly n"), ONE PREFIX PER SYMBOL because consecutive
; `COUNT`s under a shared prefix scan FORWARD and fall through to the trailing
; `declare` lines, and a pure-negative prefix for the two gates that must never
; appear. Counts are MEASURED off this fixture's own lowered output, never guessed.
; RUN: %filecheck --check-prefix=MXALLOC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRY %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRZ %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMINT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXSTRIP %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXFREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMEAS %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXNONE --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" --implicit-check-not="call void @cqrt_cnot(" %s < %t.cqd0.ll

; MXALLOC-COUNT-1: = call i32 @cqrt_alloc_
; MXALLOC-NOT: = call i32 @cqrt_alloc_
; MXRY-COUNT-1: call void @cqrt_ry_i32(
; MXRY-NOT: call void @cqrt_ry_i32(
; MXRZ-COUNT-1: call void @cqrt_rz_i1(
; MXRZ-NOT: call void @cqrt_rz_i1(
; MXMINT-COUNT-1: = call i32 @cq_template_icmp_
; MXMINT-NOT: = call i32 @cq_template_icmp_
; MXSTRIP-COUNT-1: call void @cq_template_icmp_
; MXSTRIP-NOT: call void @cq_template_icmp_
; MXFREE-COUNT-1: call void @cqrt_free(
; MXFREE-NOT: call void @cqrt_free(
; MXMEAS-COUNT-1: = call i32 @cqrt_measure_
; MXMEAS-NOT: = call i32 @cqrt_measure_
; MXNONE-NOT: call{{.*}}@cq_theta_
; MXNONE-NOT: call{{.*}}@cq_measure_si32
; MXNONE-NOT: call{{.*}}@cq_phi


; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK: call void @cqrt_rz_i1(i32 %[[F]], double 0x400921FB54442D18), !cq.branchphase
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[F]])

; Negatives name the CALL, never the bare symbol: the lowered module keeps a
; `declare void @cqrt_x(i32)` whether or not anything calls it, so a bare negative is
; a red on a correct stream (measured on the sibling fixture; the bd `qta2` class).
; NEG-NOT: call void @cqrt_cnot
; NEG-NOT: call void @cqrt_toffoli
; NEG-NOT: call void @cqrt_ry_i32_controlled
; NEG-NOT: call{{.*}}@cq_phi
; NEG-NOT: call{{.*}}@cq_theta_

; Counts in their own whole-file prefixes (Rule 12(a)): exactly one of everything,
; because the loop is ROLLED — this is also the trip-count-independence witness.
; ⚠ ONE PREFIX PER SYMBOL. Consecutive `COUNT` directives under a SHARED prefix scan
; FORWARD from where the previous one stopped, so interleaved symbols cannot be
; counted in one prefix — the later ones then silently match the trailing `declare`
; lines instead. Every pattern names the CALL and is followed by its own `-NOT`,
; which is what turns "at least N" into "exactly N".
; CNTRZ-COUNT-1: call void @cqrt_rz_i1(
; CNTRZ-NOT: call void @cqrt_rz_i1(
; CNTMINT-COUNT-1: call i32 @cq_template_icmp_eq_i32_hl(
; CNTMINT-NOT: call i32 @cq_template_icmp_eq_i32_hl(
; CNTSTRIP-COUNT-1: call void @cq_template_icmp_eq_i32_hl_unc(
; CNTSTRIP-NOT: call void @cq_template_icmp_eq_i32_hl_unc(
; CNTFREE-COUNT-1: call void @cqrt_free(
; CNTFREE-NOT: call void @cqrt_free(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #1
  %2 = icmp eq i32 %1, 5
  br label %5

3:                                                ; preds = %8
  %4 = tail call i32 @cq_measure_si32(i32 noundef %1) #1
  ret i32 %4

5:                                                ; preds = %0, %8
  %6 = phi i32 [ 0, %0 ], [ %9, %8 ]
  br i1 %2, label %7, label %8

7:                                                ; preds = %5
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #1
  br label %8

8:                                                ; preds = %5, %7
  %9 = add nuw nsw i32 %6, 1
  %10 = icmp eq i32 %6, 0
  br i1 %10, label %5, label %3
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
