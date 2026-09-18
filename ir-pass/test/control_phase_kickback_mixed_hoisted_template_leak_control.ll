; ⚠⚠ CONVERTED ACCEPT -> DECLINE, 2026-09-14c, bd `test_C_libtooling-s82e` under
; OWNER RULING **D4**. READ THIS BLOCK BEFORE THE ORIGINAL HEADER BELOW, WHICH IS
; KEPT VERBATIM AND IS NOW PARTLY WRONG.
;
; This fixture shipped as ACCEPT-AND-LEAKS, and its own header calls that leak
; "the PRIME-DIRECTIVE disposition, not an oversight" / "the safe direction
; (Rule 6)". **THAT CLAIM IS MEASURABLY FALSE FOR THIS PROGRAM**, and the
; measurement that falsifies it is THE ONE THE ORIGINAL HEADER ALREADY RECORDS:
; the per-bit `and` rails are `3/0 rolled` against `3/3 hand-unrolled`, and the
; source ends
;
;     q = cq_theta(q, 0.9); return cq_measure(q) + cq_measure(r);
;
; — a NON-DIAGONAL, TENSORED `cqrt_ry` on `q`, followed by a measurement of `q`.
; The three leaked rails are which-path copies of `q`'s bits. Leaving them
; allocated leaves each of `q`'s qubits maximally entangled with an ancilla
; nobody touches again, so the `Ry(0.9)` acts on a DECOHERED mixture where the
; hand-unrolled twin acts on the pure state: per qubit the `alpha*beta*sin(0.9)`
; interference term is present in one circuit and absent in the other, and
; `cq_measure(q)` is an observable of the program. Rolled and unrolled are
; DIFFERENT UNITARIES here — `CLAUDE.md` Rule 8, "a permutation that leaves a rail
; dirty AND entangled still dephases under later interference". It is NOT the
; accepted Rule-6 qubit leak; that disposition is correct only when the leaked
; rail's partner is itself garbage, which is what
; `loop_leak_dephase_accept_pertrip_dead.ll` pins.
;
; ⚠ THE DISCRIMINATION IS EXACT AND THE TREE ALREADY CONTAINED THE CONTROL:
; `control_phase_kickback_mixed_invariant_carried_inloop.ll` is this same source
; with the invariant base a ROOT MINT instead of a template rail. There
; `invariantRegisterRoots` admits it, `markIfRailLocal` marks the body, the spine
; discharges IN-BODY once per trip — and it is UNMOVED by this increment
; (`A:32d17cb8675d` on both binaries, measured in the same corpus sweep). The
; difference is conjunct (1) of `declineDephasingUnmarkedLoopRails`: a MARKED body
; discharges, an UNMARKED one leaks.
;
; ⚠ RULE 17: this is NOT a punt. The program receives an INVALID circuit today,
; so refusing it is the Prime Directive, and the owner's 2026-09-11 "do not
; decline code that leads to a valid quantum circuit" ruling does not reach it.
; THE DECLINE IS THE INTERIM; **bd `tu9q`** (P1) is the END STATE and builds the
; discharge pairing so this program COMPILES.
;
; RETIREMENT TRIGGER (L8): when `tu9q` lands this becomes an ACCEPT again, and the
; stream to re-derive is the HAND-UNROLLED twin's — `3/3`, not the `3/0` this file
; used to pin. The pre-conversion RUN lines and CHECK prefixes are in git history
; at this commit's parent; do NOT restore them verbatim, because they pinned the
; LEAKING stream and that is the thing `tu9q` removes.
;
; ⚠ Q-R1-1 IS AFFECTED AND MUST BE RE-READ. `CLAUDE.md` §5 files "an in-loop
; hoisted loop-invariant TEMPLATE rail read by the body's condition (Q-R1-1)" as
; an OVER-DECLINE candidate — "a Prime-Directive decline, not a proof". For the
; sub-case with a post-loop rotation the opposite is now measured: the ACCEPT was
; the defect. Q-R1-1's remaining population is the sub-case with NO later
; interference, which still accepts and still leaks.
;
; ── the original header follows, verbatim and superseded in the part named above ──

; control_phase_kickback_mixed_hoisted_template_leak_control.ll — ACCEPT, AND IT
; LEAKS. bd test_C_libtooling-3qlq Inc 1, the Rule-13 CLEARANCE finding C-1. This
; is the DISCRIMINATING CONTROL for that fix: the shape one operator away from the
; one C-1 repaired, whose disposition the fix must NOT change.
;
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3); int p=q*3;
;       for(int i=0;i<3;i++){ if((p>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
;       q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
;
; `clang -O1` on that source with `@main` dropped; `!llvm.loop` verbatim.
;
; WHAT IT PINS. The kickback's condition register is `p = q * 3` — a HOISTED
; LOOP-INVARIANT **TEMPLATE** rail (`cq_template_mul_i32_hl`), not a root mint. The
; loop is otherwise the C-1 shape exactly: `r` is loop-CARRIED, so
; `collapseRailPhisIn` returns `Collapsed`, and the `Collapsed` branch now also
; asks `invariantRegisterRoots`. Clause (ii) REFUSES `p` — a `cq_template_*` call
; is precisely what `ChainWalk::isInteriorTerminalHandle` clause (I1) ADMITS to the
; M-B interior partition, so it is precisely what may NOT be handed to
; `markIfRailLocal` as a Root: a recovered forward gate in the PREHEADER paired
; with an adjoint `At` in the K-times body is the multiplicity hazard that
; function's own comment names, and only the (I1) exclusion rules it out.
;
; SO THE BODY'S PER-BIT `and` RAILS ARE STILL NOT DISCHARGED, and that is the
; PRIME-DIRECTIVE disposition, not an oversight: the leak is the safe direction
; (Rule 6 — a rail not provably |0> is left allocated, never freed dirty), and
; widening clause (ii) to admit a template rail is **owner question Q-R1-1**, not
; this fix's to decide. MEASURED, rolled/unrolled `and_i32_hl` vs `_unc`:
; **3/0 rolled and 3/3 unrolled on BOTH 542d588 (the pre-fix subject) and on the
; C-1 fix** — byte-identical rolled traces, `diff` empty. That equality IS the
; assertion: it says the widening did not reach here.
;
; Two sibling spellings measure the same wall and are recorded in
; `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3: a `sext` rail (`long long p = q;`) and a
; Q+Q rail (`p = q + r`). Q-R1-1's disclosure therefore covers ANY loop-invariant
; TEMPLATE rail — a cast, a Q+Q op, an onward `mul` — not only `q*3`.
;

; The hoisted template rail is minted ONCE, in the preheader.

; The rolled body: the bit rail is minted off `%[[P]]`, the flag is minted,
; bracketed, kicked, stripped and freed — and then NOTHING. No `and` discharge,
; no free of the bit rail.

; ⭐ THE CONTROL'S OWN ASSERTION. **ZERO** `and` discharges — the leak, pinned.
; If a future widening of clause (ii) reaches the hoisted template rail this goes
; RED, which is the point: Q-R1-1 must be RULED, not drifted into.

; ONE kickback gate, and it is the only Rz.

; EXACTLY ONE free in the whole module — the flag's. The bit rail and the `mul`
; rail are LEFT ALLOCATED, never freed dirty (Rule 6, the safe direction).

; The `cqrt_x` census: exactly the kickback's negated-polarity bracket
; (`clang -O1` canonicalizes `(p>>i)&1` to `icmp eq ..., 0`, so the arm is the
; FALSE successor -- Rule 9). An UNPAIRED one is a wrong-branch phase, and an
; injected extra one was caught by NOTHING before this prefix existed (this
; round's injection matrix: `extra_x` MISSED).

; WHOLE-FILE PURE-NEGATIVE.
;
;
; (a `DS_Error` decline writes 0 BYTES to stdout, so the property is pinned by the
;  `not` inversion on the RUN line plus this one message match — Rule 12
;  fixture-hygiene defect (b). Mirrored character-for-character with
;  `kMsgLoopLeakDephases` in `LoopLowering.cpp`.)


; ⚠⚠ CONVERTED DECLINE -> ACCEPT, 2026-09-21, bd `test_C_libtooling-4jok`, WHEN
; bd `tu9q` P0+P3 LANDED.  READ THIS BLOCK BEFORE EVERYTHING BELOW IT, WHICH IS
; KEPT VERBATIM AND IS NOW PARTLY HISTORY.
;
; ⚠ THIS FILE'S OWN L8 TRIGGER PREDICTED THIS EXACTLY, AND IT WAS RIGHT ABOUT THE
; VERDICT AND ABOUT THE STREAM: *"when `tu9q` lands this becomes an ACCEPT again,
; and the stream to re-derive is the HAND-UNROLLED twin's — `3/3`, not the `3/0`
; this file used to pin.  … do NOT restore them verbatim, because they pinned the
; LEAKING stream and that is the thing `tu9q` removes."*  Measured on `cq-opt`
; 3368af12…: **3 forwards / 3 adjoints ROLLED**, matching the twin.  The old
; prefixes are NOT restored.
;
; ⚠ AND THE DISTINCTION `CLAUDE.md` §5 DRAWS MUST NOT BE READ AS A BAN ON AN
; ACCEPT PREFIX.  §5 says of this family *"the ACCEPT was the defect"* and *"do
; not restore their old `CHECK` prefixes, which pinned the leaking stream."*  That
; forbids the OLD prefixes, whose property was *the per-trip chain does not
; discharge*.  The prefixes below pin the OPPOSITE property — that it DOES — over
; a stream where every per-trip rail is `_unc`'d and freed in the body and the
; hoisted rail is discharged at the loop EXIT **before** the trailing
; `cqrt_ry`.  Rule-13 round 5 (F-5) flags getting this backwards as the single
; easiest mistake at this landing.
;
; WHY THE ACCEPT IS SOUND, and it is a PLACEMENT argument, not a leak argument.
; The old decline was correct for a tree without bd `tu9q`'s P1/P2: the per-bit
; rails were which-path copies of the rotated register, left standing across the
; trailing non-diagonal gate — Rule 8, a wrong unitary.  P1 (`multiplicityAgrees`)
; and P2 (`anchorForConsumer`'s loop-exit placement) make the body markable, the
; spine then places an in-body `At` per trip, and nothing entangled with the
; register survives to the interference.
;
; ⚠ WHAT IS *NOT* CLAIMED HERE.  This is `opt` exit code, stage-2b rail identities
; and an emitted trace — there is no simulator (Rule 2), and this project's own
; history records every shipped Grover golden passing exactly this bar while being
; the identity.  The independent clearance is Rule-13 round 5
; (`session-2026-09-21-orchestrator/round5/REVIEW.md`, `CLEAR-WITH-ITEMS`, 0 P1),
; which re-ran this family under an edge-complete entanglement checker after
; finding the orchestrator's own instrument blind to permutation-gate edges.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.a0.ll
; RUN: %filecheck %s < %t.a0.ll
; RUN: %filecheck %s --check-prefix=EXITD < %t.a0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.a0.ll
;
; THE PER-TRIP CHAIN, DISCHARGED IN THE BODY.  Positional, because the property is
; an ORDER: the `_unc` must sit between the rail's last reader and the next trip.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %h_op, i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
;
; THE HOISTED RAIL, DISCHARGED AT THE LOOP EXIT **BEFORE** THE INTERFERENCE.  This
; ordering IS the Rule-8 claim and nothing else in the file states it:
; EXITD: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; EXITD-NEXT: call void @cqrt_free(i32 %h_op)
; EXITD-NEXT: call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)
;
; THE ADJOINT CENSUS — exactly one per forward, whole-file, its own prefix so no
; positive above it windows the negative (Rule 12 fixture-hygiene (a)).  A SECOND
; `and` adjoint would be the over-reversed rail `railLocalQualifies`' multiplicity
; trigger names; a ZERO would be the leak this file used to pin.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  %4 = mul nsw i32 %2, 3
  br label %10

5:                                                ; preds = %17
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %18) #2
  %9 = add nsw i32 %8, %7
  ret i32 %9

10:                                               ; preds = %1, %17
  %11 = phi i32 [ 0, %1 ], [ %19, %17 ]
  %12 = phi i32 [ %3, %1 ], [ %18, %17 ]
  %13 = shl nuw nsw i32 1, %11
  %14 = and i32 %13, %4
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %17, label %16

16:                                               ; preds = %10
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %17

17:                                               ; preds = %16, %10
  %18 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 1.000000e-01) #2
  %19 = add nuw nsw i32 %11, 1
  %20 = icmp eq i32 %19, 3
  br i1 %20, label %5, label %10, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
