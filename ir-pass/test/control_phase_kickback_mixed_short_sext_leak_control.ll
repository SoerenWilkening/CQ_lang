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

; control_phase_kickback_mixed_short_sext_leak_control.ll — ACCEPT **AND LEAKS**,
; deliberately. bd test_C_libtooling-3qlq Inc 1, the SECOND C-1 review round,
; finding **F-C1-3**: the Q-R1-1 template-rail class reached by a TYPE the user
; wrote, not by a cast the user wrote.
;
;     int slice(short u){ short q=cq_theta(u,0.5); short r=cq_theta(u,0.3);
;       for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
;       q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
;
; That is `control_phase_kickback_mixed_invariant_carried_inloop.ll`'s source with
; `int` changed to `short` and nothing else. `clang -O1` HOISTS a
; `sext i16 %q to i32` into the loop's preheader (the shift is done at `int`), so
; the per-bit condition reads `cq_template_sext_i16_to_i32(%h)` — a loop-invariant
; TEMPLATE rail — and `invariantRegisterRoots` clause (ii) refuses it: a template
; rail is exactly what `ChainWalk::isInteriorTerminalHandle` clause (I1) ADMITS, so
; the multiplicity argument that licenses a root mint does not carry. The per-trip
; `and` rails are therefore NOT discharged.
;
; WHY IT IS COMMITTED. PRD §0 E2's disclosure of the Q-R1-1 residual reads as a
; list of things the SOURCE spells — "a cast, a Q+Q op, an onward `mul`" — and a
; reader will not expect `short` to be one of them. It is: no cast appears in the
; program at all. MEASURED IDENTICAL on 542d588, on the round-1 C-1 fix and on this
; HEAD — rolled `cq_template_and_i32_hl` 3 / `_unc` **0** against a hand-unrolled
; twin at 3/3, rolled trace BYTE-UNCHANGED across all three binaries — so this file
; also pins that NEITHER C-1 widening reached the class. The leak is the
; Prime-Directive disposition until Q-R1-1 is ruled (Rule 6: left allocated, never
; freed dirty).
;

; The two `i16` root mints, then ⭐ the HOISTED `sext` TEMPLATE rail the body's
; condition reads. Nothing in the source asked for that cast.

; The rolled body: the bit rail is minted off the TEMPLATE rail, the flag is
; stripped and freed, and the `and` is NEVER discharged. That missing line is what
; this file pins.

; ⭐ ZERO `and` discharges — the Q-R1-1 leak, unreached by either C-1 widening.

; ONE free in the body: the flag alone (the bit rail and the `sext` rail are the leak).



; ModuleID = 'p/r5_short_inv.c'
;
;
; (a `DS_Error` decline writes 0 BYTES to stdout, so the property is pinned by the
;  `not` inversion on the RUN line plus this one message match — Rule 12
;  fixture-hygiene defect (b). Mirrored character-for-character with
;  `kMsgLoopLeakDephases` in `LoopLowering.cpp`.)


source_filename = "p/r5_short_inv.c"
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
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %h_cast, i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %h_cast, i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
;
; THE HOISTED RAIL, DISCHARGED AT THE LOOP EXIT **BEFORE** THE INTERFERENCE.  This
; ordering IS the Rule-8 claim and nothing else in the file states it:
; EXITD: call void @cq_template_sext_i16_to_i32_unc(i32 %h_cast, i32 %h)
; EXITD-NEXT: call void @cqrt_free(i32 %h_cast)
; EXITD-NEXT: call void @cqrt_ry_i16(i32 %h, double 9.000000e-01)
;
; THE ADJOINT CENSUS — exactly one per forward, whole-file, its own prefix so no
; positive above it windows the negative (Rule 12 fixture-hygiene (a)).  A SECOND
; `and` adjoint would be the over-reversed rail `railLocalQualifies`' multiplicity
; trigger names; a ZERO would be the leak this file used to pin.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 -65536, 65535) i32 @slice(i16 noundef signext %0) local_unnamed_addr #0 {
  %2 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef 5.000000e-01) #2
  %3 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef 3.000000e-01) #2
  %4 = sext i16 %2 to i32
  br label %12

5:                                                ; preds = %19
  %6 = tail call signext i16 @cq_theta_si16(i16 noundef signext %2, double noundef 9.000000e-01) #2
  %7 = tail call signext i16 @cq_measure_si16(i16 noundef signext %6) #2
  %8 = sext i16 %7 to i32
  %9 = tail call signext i16 @cq_measure_si16(i16 noundef signext %20) #2
  %10 = sext i16 %9 to i32
  %11 = add nsw i32 %10, %8
  ret i32 %11

12:                                               ; preds = %1, %19
  %13 = phi i32 [ 0, %1 ], [ %21, %19 ]
  %14 = phi i16 [ %3, %1 ], [ %20, %19 ]
  %15 = shl nuw nsw i32 1, %13
  %16 = and i32 %15, %4
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %19, label %18

18:                                               ; preds = %12
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %19

19:                                               ; preds = %18, %12
  %20 = tail call signext i16 @cq_theta_si16(i16 noundef signext %14, double noundef 1.000000e-01) #2
  %21 = add nuw nsw i32 %13, 1
  %22 = icmp eq i32 %21, 3
  br i1 %22, label %5, label %12, !llvm.loop !6
}

declare signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #1


attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
