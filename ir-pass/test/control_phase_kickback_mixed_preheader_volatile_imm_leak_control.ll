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
;     cq_theta(&q, 0.9); return cq_measure(q) + cq_measure(r);
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

; control_phase_kickback_mixed_preheader_volatile_imm_leak_control.ll —
; ACCEPT-AND-LEAKS. bd test_C_libtooling-3qlq Inc 1, the THIRD C-1 review round —
; **THE MEASURED COST OF F-C1B-1's FIX (1a), pinned rather than left to prose.**
;
;     static volatile int off = 7;
;     int slice(int u){ int q=u; cq_theta(&q,0.5); int r=u; cq_theta(&r,0.3);
;       q = q + off;                                   /* a VOLATILE-LOAD immediate */
;       for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); cq_theta(&r,0.1); }
;       cq_theta(&q,0.9); return cq_measure(q)+cq_measure(r); }
;
; The (1a) fence is `isa<Constant>(Imm)` at the commit, whose whole argument is
; that a `Constant` can NEVER become tainted between `lowerLoops` and `lowerOps`.
; A volatile load is not a `Constant`, so this program — a NEW accept that the
; SECOND C-1 round introduced (3 `cq_template_and_i32_hl` mints / 3 `_unc`) —
; returns to the pre-round-2 leak (3 mints / **0** `_unc`, 32 trace lines,
; BYTE-IDENTICAL to 542d588 AND to the round-1 fix, MEASURED).
;
; ⚠ M-C ITSELF STILL LOWERS THE OP IN PLACE at `lowerOps` (`cqrt_addc_i32(%h,
; %off)` below): the immediate is stage-2b-provable (census 0.5 cleared a volatile
; load explicitly, and `slice_control_seq_grover`'s own `off` is this shape). What
; the fence refuses is the PREDICTION of that answer from a program point before
; the round-2 taint fixpoint — not the answer. So the register the body reads IS
; the root mint's rail and the discharge would be SOUND; it is simply no longer
; PROVEN at the point the proof is needed, and Rule 6's direction is to leak.
;
; This is the Prime-Directive direction and it is recorded in PRD §0 E2 and notes
; §3.11 as a cost, not a defect. Buying it back means the commit asking a question
; about the immediate that survives a taint change — an owner question, not a
; review round's call (notes §3.11, OQ-C1-8).
;

; The root mint, the volatile load, and M-C's OWN in-place gate on it.

; The rolled body: the bit rail is minted, the flag minted / bracketed / kicked /
; stripped / freed — and the BIT RAIL IS NOT DISCHARGED. That is the leak.

; ⭐ THE ASSERTION: ZERO `and` discharges. It was ONE on the round-2 binary.

; ⭐ AND EXACTLY ONE free in the body — the flag's. The bit rail is left allocated
; (Rule 6's safe direction), never freed dirty.

; Exactly ONE kickback gate in the module (the rolled body's).

; `#cqrt_rz_i1 == #!cq.branchphase` — an unmarked kickback gate is one the
; uncompute spine would adjoint, cancelling the user's phase exactly (F-L7-1).

; The `cqrt_x` census: the kickback's polarity bracket(s) and the arm brackets.
; An UNPAIRED one is a wrong-branch phase.

; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.

; WHOLE-FILE PURE-NEGATIVE.

; ModuleID = 'p/z21_preadd_volatile_imm.c'
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; (a `DS_Error` decline writes 0 BYTES to stdout, so the property is pinned by the
;  `not` inversion on the RUN line plus this one message match — Rule 12
;  fixture-hygiene defect (b). Mirrored character-for-character with
;  `kMsgLoopLeakDephases` in `LoopLowering.cpp`.)
; CHECK: cq loop lowering: rolled body leaks a rail entangled with a rotated register
;
; ⚠⚠ THE bd `bbu0` DEFER INSTRUMENT MOVED HERE ON 2026-09-21 (bd
; `test_C_libtooling-4jok`), AND IT MOVED BECAUSE ITS PREVIOUS HOST STOPPED BEING
; ONE.  It lived in `loop_leak_dephase_reject_region_derivedbase_live.ll`, which
; bd `tu9q` P0+P3 converts to an ACCEPT — under the env gate that module now
; exits 0, so the three-line ordering below had nowhere to be observed.  That
; file's own header left the instruction and it is being followed verbatim:
; *"`RUN`/`DEFER` block again then, to whichever module still declines at
; `declineDephasingUnmarkedLoopRails`; do not silently drop it."*
;
; ⚠ WHY THIS FILE IS THE HOST.  It is the THIRD member of the `CLAUDE.md` §5 trio
; and the only one bd `tu9q` does NOT move: its preheader rail is a `volatile`
; immediate, so `mintsOutOfPlaceTemplateRail`'s forecast is followed by an M-C
; IN-PLACE lowering and clause (ii-d) has no rail to place.  It therefore still
; reaches `declineDephasingUnmarkedLoopRails`, which is the whole requirement.
; MEASURED on `cq-opt` 3368af12…: exit 1, all three lines, in this order.
;
; WHAT THE INSTRUMENT PINS: with the env gate set, bd `bbu0`'s deferred verdict
; speaks AFTER the `lyyf` warning and BEFORE the dephasing decline — one module,
; one owner per diagnostic, in a fixed order.  Five other fixtures still decline
; at that fence today (`loop_leak_dephase_reject_nested_{depth3_middle_rail,
; iterlocal_inner,iic_inner,marked_inner}.ll`, `…_arm_minted_unmarked_control.ll`),
; so if THIS file ever moves, re-home the block again rather than dropping it.
;
; RUN: env CQ_BBU0_DEFER_DEPHASE_FENCE=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:     -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=DEFER
;
; DEFER: cq rotation lowering: non-diagonal gate over a live derived record
; DEFER: cq bbu0 instrument: dephasing decline DEFERRED past the warn stage
; DEFER: cq loop lowering: rolled body leaks a rail entangled with a rotated register


source_filename = "p/z21_preadd_volatile_imm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@off = global i32 7, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  %4 = load volatile i32, ptr @off, align 4, !tbaa !6
  %5 = add nsw i32 %4, %2
  br label %11

6:                                                ; preds = %18
  %7 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 9.000000e-01) #2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2
  %9 = tail call i32 @cq_measure_si32(i32 noundef %19) #2
  %10 = add nsw i32 %9, %8
  ret i32 %10

11:                                               ; preds = %1, %18
  %12 = phi i32 [ 0, %1 ], [ %20, %18 ]
  %13 = phi i32 [ %3, %1 ], [ %19, %18 ]
  %14 = shl nuw nsw i32 1, %12
  %15 = and i32 %14, %5
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %18, label %17

17:                                               ; preds = %11
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %18

18:                                               ; preds = %17, %11
  %19 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 1.000000e-01) #2
  %20 = add nuw nsw i32 %12, 1
  %21 = icmp eq i32 %20, 3
  br i1 %21, label %6, label %11, !llvm.loop !10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable

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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
