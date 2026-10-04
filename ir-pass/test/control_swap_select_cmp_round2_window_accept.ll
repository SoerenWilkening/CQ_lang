; control_swap_select_cmp_round2_window_accept.ll — ACCEPT (Track A.1, bd
; test_C_libtooling-9pum): THE ROUND-2 TAINT WINDOW, ACCEPTED — the discriminator
; that the fix is a RE-VERIFICATION and not a refusal of the window. The compare
; twin of `control_swap_select_rail_round2_window_accept.ll`.
;
; Same two-TU recipe, same `%out`-derived seed, same two sibling thetas on ONE
; rail at final taint — with the sibling written AFTER the select:
;
;     int keep = cq_measure(y);
;     int x = (y != 0);                 // CLASSICAL at round 1, TAINTED at round 2
;     int b = x; cq_theta(&b, 0.25);
;     int a = (b == 1) ? 2 : 5;         // the 4.4 merge on that rail
;     int b3 = x; cq_theta(&b3, 0.9);   // the SIBLING — after the merge
;
; HERE THE STREAM IS CORRECT AND IT STILL LOWERS: the copies really do read
; `Ry(0.25)|x>`, the label `b` names. `reverifyCmpCondReads` re-asks rung (iii)
; at the recorded read point (the `cq_template_icmp_eq_i32_hl` mint) with FINAL
; taint: the position-free walk DOES now find the sibling (the F-1b-1 ancestry
; reaches it) and is CLEAN taint-blind, so the window is open — and the DT prong
; then proves the sibling runs after every execution of that read. A fence that
; refused the window outright would refuse this program.
;
; ORDER IS THE ASSERTION: `ry(h_cast,.25)`, then the whole merge, then
; `ry(h_cast,.9)`. BYTE-UNCHANGED from `main` 0c7380c.

; ─────────────────────────────────────────────────────────────────────────────
; ⚠ VERDICT INVERTED — ACCEPT → DECLINE (bd test_C_libtooling-3d8q, P1). THE
; HEADER ABOVE IS KEPT VERBATIM because it is the record of what this file was
; for, and because its correctness claim is TRUE OF EXACTLY ONE OF THE TWO READS
; IN THE PROGRAM. "the copies really do read `Ry(0.25)|x>`, the label `b` names"
; is about the MERGE's read of `b`; it says nothing about `b3`'s own read, and
; `b3` is where the defect is:
;
;     b  = x; cq_theta(&b, 0.25);  /* consumes the name `x` */
;     …the merge on b…
;     b3 = x; cq_theta(&b3, 0.9);  /* names Ry(0.9)|x>  — the register holds
;                                  Ry(0.9)Ry(0.25)|x> */
;
; That is `f1_two_siblings_nocontrol.c` with a round-2 rail under it — the
; project's P1 stale-reader class (`docs/frontend.md` §3.2's linear rule:
; "a rotation consumes the old name"), and this module ACCEPTED on the frozen
; session ORACLE. It surfaces only through the reader fence's DELTA-SCOPED
; round-2 re-ask, because `%9` is CLASSICAL at round 1.
;
; ⚠ WHAT IS LOST, AND WHAT STILL PINS TRACK A.1 — check this before assuming the
; conversion cost the increment's subject:
;   * "the round-2 window is OPEN and the program still lowers" is pinned by
;     `control_phase_kickback_rail_round2_window_accept.ll` and
;     `control_phase_nest_rail_round2_window_accept.ll` (both unchanged, both
;     green);
;   * the decline side of `reverifyCmpCondReads` is pinned by
;     `control_swap_reject_select_cmp_round2_sibling_theta.ll` and its five
;     `*_round2_sibling_theta` relatives (all unchanged, all green);
;   * WHAT IS LOST is one cell: the COMPARE path with a sibling PRESENT and the
;     DT prong ACCEPTING. No well-formed program is currently known to occupy it,
;     which is the honest statement — the shape "two sibling rotations on one
;     rail, both read" IS the defect, so the cell may be empty by construction.
;
; MEASURED, so the next agent does not have to re-derive it: the obvious
; well-formed rewrite — `%13 = cq_theta(i32 %10, double 9.000000e-01)`, i.e. a
; CHAINED gate on `b` instead of a sibling on `x`, ONE OPERAND, byte-identical
; emitted stream — does NOT restore the cell. It declines with
; `cq controlled lowering: condition predates a non-diagonal gate under quantum
; control`. Whether that is a true property of the chained shape or a separate
; over-decline is an OPEN QUESTION, filed, not answered here.
;
; RETIREMENT TRIGGER: if that question resolves as an over-decline and the
; chained spelling is made to lower, THIS FILE becomes an ACCEPT again with that
; one operand changed and the header above intact. Re-derive it then; do not
; delete it.
; ─────────────────────────────────────────────────────────────────────────────

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 5, %0 ]
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  %8 = icmp ne i32 %6, 0
  %9 = zext i1 %8 to i32
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 2.500000e-01) #3
  %11 = icmp eq i32 %10, 1
  %12 = select i1 %11, i32 2, i32 5
  %13 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 9.000000e-01) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %12) #3
  %15 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  %16 = add i32 %14, %7
  %17 = add i32 %16, %15
  ret i32 %17
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice()
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}

; THE SIBLING IS AFTER THE MERGE. One rail (%[[HC]]) carries both rotations, and
; the second one follows the flag's free — which is exactly why it is harmless.
; ⚠ THE OLD ACCEPT'S DIRECTIVE BLOCKS ARE PRESERVED BELOW, NEUTERED TO PROSE, and
; that is deliberate (L8): they are the exact stream this program used to emit
; — `ry(h_cast,.25)`, the whole 4.4 copy merge, the strip, the free, then
; `ry(h_cast,.9)`, with 3 ry / 3 free / 3 measure / 4 x — and they are what a
; future agent must re-derive if the RETIREMENT TRIGGER above ever fires. They
; are NOT live directives: a `DS_Error` writes 0 bytes to stdout, so leaving
; them as live positive directives would make this fixture fail for a reason
; that has nothing to do with its subject. (Writing the directive token in this
; very sentence is how the first attempt failed — FileCheck reads comments.)
;
; (was) [check] %[[HC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(
; (was) [check] call void @cqrt_ry_i32(i32 %[[HC]], double 2.500000e-01)
; (was) [check-next] %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HC]], i32 1)
; (was) [check] call void @cqrt_free(i32 %[[F]])
; (was) [check-next] call void @cqrt_ry_i32(i32 %[[HC]], double 9.000000e-01)

; (was) [ord] call void @cqrt_ry_i32({{.*}}, double 2.500000e-01)
; (was) [ord] call i32 @cq_template_icmp_eq_i32_hl(
; (was) [ord] call void @cqrt_copy_i32_controlled(
; (was) [ord] call void @cqrt_copy_i32_controlled(
; (was) [ord] call void @cq_template_icmp_eq_i32_hl_unc(
; (was) [ord] call void @cqrt_free(
; (was) [ord] call void @cqrt_ry_i32({{.*}}, double 9.000000e-01)

; (was) [noroute-not] cqrt_cswap
; (was) [noroute-not] cqrt_rz
; (was) [noroute-not] call i32 @cq_theta_
; (was) [rycnt-count-3] call void @cqrt_ry_
; (was) [rycnt-not] call void @cqrt_ry_
; (was) [fcnt-count-3] call void @cqrt_free(
; (was) [fcnt-not] call void @cqrt_free(
; (was) [mcnt-count-3] call i32 @cqrt_measure_
; (was) [mcnt-not] call i32 @cqrt_measure_
; (was) [xcnt-count-4] call void @cqrt_x(
; (was) [xcnt-not] call void @cqrt_x(
