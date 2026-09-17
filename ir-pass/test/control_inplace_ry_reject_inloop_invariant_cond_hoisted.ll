; control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll — **ACCEPT since bd
; `test_C_libtooling-drbq.12` (2026-09-17).** PRD §13.2 row W: the customer's
; SIMPLEST C spelling of the in-loop Ry arm, which used to be refused for a reason
; that was neither R7 nor P1.
;
;     for (i = 0; i < 2; ++i) { if (q == 5) r = cq_theta(r, 0.9); }
;
; With NO gate on `q` in the body, `q` is loop-INVARIANT, so `clang -O1` LICM-hoists
; the compare `%3 = icmp eq i32 %1, 5` into the ENTRY block while the region's
; `Pred` is the loop header. `condWireDisposition`'s P4 precondition
; (`Cond->getParent() != R.Pred` — "unbounded gap across blocks") USED TO return
; `DeclineNow` here, before the compare-to-branch window scan and before any
; rotation clause ran. **The arm's own Ry played no part in that decline at all.**
;
; ⚠ THE FILE NAME STILL SAYS `reject_` AND THAT IS DELIBERATE, NOT AN OVERSIGHT.
; It follows the bd `gahu` precedent: a `git mv` can be RESURRECTED by a merge (L8),
; leaving one module under two names with contradictory verdicts and no review able
; to see it. The rename is filed, not taken.
;
; THE BODY BELOW IS VERBATIM `clang -O1` OUTPUT, not a hand transcription, because
; the whole row is about what the optimizer does to the source. It is UNCHANGED from
; the decline version of this file — only the RUN/CHECK block and this header moved,
; so the flip is pinned against a byte-identical module.
;
; WHY IT IS SOUND, in the terms the old header already stated: the only thing
; between the hoisted compare and the branch is the arm's own `cq_theta` on `r`,
; and R4 has proved that rail disjoint from every condition rail — so the flag the
; mint reads IS the flag the source describes and the `_unc` strip returns it to
; |0>. What was missing was a clause that could SAY so, and that clause is
; `crossBlockCompareMintable` (`ArmClassify.cpp`): the SAME CFG-bounded gap walk
; Track P′ built for a claimed prep merge φ, run with the evidence narrowed to a
; RAIL-RELABELLING gate on the CONDITION's own rail (`railWireClosure`, BothWays)
; and its vocabulary WIDENED to the dtzb in-place `add`/`sub`/`xor`.
;
; THE STREAM IS THE ALREADY-CLEARED ONE. The `if (a == off)` twin with a
; `volatile int off` (which defeats both LICM and CSE) has lowered since drbq Inc 3
; and is `ACCEPT-IDENTICAL` in `tools/loop_twin_matrix.expected.txt`; the trace
; below is that twin's with the literal `5` where it has the opaque load. The loop
; stays ROLLED — ONE mint / controlled-Ry / strip / free inside the body — so the
; lowered IR is independent of the trip count.
;
; ⚠ WHAT MUST NOT MOVE: `%h` (the CONDITION register) is read only as arg-0 of the
; forward mint, of the `_unc` strip, as the CONTROL of `cqrt_ry_i32_controlled` and
; by its measure. It is never `cqrt_x`-bracketed and never freed. The ONE free is
; the flag `%h_cmp`, whose forward mint and `_unc` strip bracket it back to |0>.
;
; RETIREMENT TRIGGER (L8): if `condWireDisposition`'s cross-block prong is ever
; narrowed back, this file returns to a `not %cq-opt … | %filecheck` inversion whose
; expected string is
; `cq controlled lowering: condition predates a non-diagonal gate under quantum control`
; plus a negative on `cqrt_ry_i32_controlled`. Do not delete it; flip it back.
; (Spelled without the literal directive tokens, because lit scrapes them out of
; prose too — this exact sentence cost one syntax-error red.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NEG --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTMINT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTSTRIP %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTFREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTCRY %s < %t.cqd0.ll
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
; RUN: %filecheck --check-prefix=MXRYC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMINT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXSTRIP %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXFREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMEAS %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXNONE --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" --implicit-check-not="call void @cqrt_cnot(" %s < %t.cqd0.ll

; MXALLOC-COUNT-2: = call i32 @cqrt_alloc_
; MXALLOC-NOT: = call i32 @cqrt_alloc_
; MXRY-COUNT-2: call void @cqrt_ry_i32(
; MXRY-NOT: call void @cqrt_ry_i32(
; MXRYC-COUNT-1: call void @cqrt_ry_i32_controlled(
; MXRYC-NOT: call void @cqrt_ry_i32_controlled(
; MXMINT-COUNT-1: = call i32 @cq_template_icmp_
; MXMINT-NOT: = call i32 @cq_template_icmp_
; MXSTRIP-COUNT-1: call void @cq_template_icmp_
; MXSTRIP-NOT: call void @cq_template_icmp_
; MXFREE-COUNT-1: call void @cqrt_free(
; MXFREE-NOT: call void @cqrt_free(
; MXMEAS-COUNT-2: = call i32 @cqrt_measure_
; MXMEAS-NOT: = call i32 @cqrt_measure_
; MXNONE-NOT: call{{.*}}@cq_theta_
; MXNONE-NOT: call{{.*}}@cq_measure_si32
; MXNONE-NOT: call{{.*}}@cq_phi


; The whole emitted stream, in order. The mint, the controlled Ry, the strip and
; the free all sit INSIDE the rolled loop body, which is what makes the lowering
; trip-count independent.
; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[F]])

; Nothing non-diagonal ever touches a user register under control, and the retired
; route/Rz mechanisms are not resurrected. Pure negatives, no counts (Rule 12(a)).
; ⚠ Every negative names the CALL, never the bare symbol: `cq-lowering` leaves a
; `declare void @cqrt_x(i32)` in the module whether or not it is ever called, so a
; bare `cqrt_x` negative matches the DECLARATION and is a red on a correct stream
; (measured here; the same class as bd `qta2`).
; NEG-NOT: call void @cqrt_rz
; NEG-NOT: call void @cqrt_cnot
; NEG-NOT: call void @cqrt_toffoli
; NEG-NOT: call{{.*}}@cq_theta_
; NEG-NOT: call{{.*}}@cq_measure_

; Counts live in their own whole-file prefixes so they cannot window a negative
; (Rule 12(a)). ⚠ ONE PREFIX PER SYMBOL, and that is not cosmetic: consecutive
; `COUNT` directives under a SHARED prefix scan FORWARD from where the previous one
; stopped, so four interleaved symbols cannot be counted in one prefix — the later
; ones then silently match the trailing `declare` lines instead. That exact defect
; was caught here while writing this file, which is why every pattern below also
; names the CALL and is followed by its own `-NOT`, the idiom that turns "at least
; N" into "exactly N".
; ONE flag mint, ONE strip, ONE free, ONE controlled rotation — the loop is ROLLED,
; so these counts ARE the trip-count-independence witness.
; CNTMINT-COUNT-1: call i32 @cq_template_icmp_eq_i32_hl(
; CNTMINT-NOT: call i32 @cq_template_icmp_eq_i32_hl(
; CNTSTRIP-COUNT-1: call void @cq_template_icmp_eq_i32_hl_unc(
; CNTSTRIP-NOT: call void @cq_template_icmp_eq_i32_hl_unc(
; CNTFREE-COUNT-1: call void @cqrt_free(
; CNTFREE-NOT: call void @cqrt_free(
; CNTCRY-COUNT-1: call void @cqrt_ry_i32_controlled(
; CNTCRY-NOT: call void @cqrt_ry_i32_controlled(
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %3 = icmp eq i32 %1, 5
  br label %8

4:                                                ; preds = %13
  %5 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %14) #2
  %7 = add nsw i32 %6, %5
  ret i32 %7

8:                                                ; preds = %0, %13
  %9 = phi i32 [ 0, %0 ], [ %15, %13 ]
  %10 = phi i32 [ %2, %0 ], [ %14, %13 ]
  br i1 %3, label %11, label %13

11:                                               ; preds = %8
  %12 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #2
  br label %13

13:                                               ; preds = %8, %11
  %14 = phi i32 [ %12, %11 ], [ %10, %8 ]
  %15 = add nuw nsw i32 %9, 1
  %16 = icmp eq i32 %9, 0
  br i1 %16, label %8, label %4, !llvm.loop !6
}

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
