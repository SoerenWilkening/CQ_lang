; control_swap_reject_select_rail_round2_window.ll — DECLINE (bd
; test_C_libtooling-3d8q, OWNER RULING 2026-09-14). The RAIL-LEAF twin of
; `control_swap_select_cmp_round2_window_accept.ll`, which Track D inverted in
; the same landing; this file exists because that twin's e2e sibling was pinned
; ONLY at the e2e layer and the rail-leaf one was pinned NOWHERE ELSE AT ALL.
;
; PROVENANCE — this is not a hand-written module. It is the VERBATIM linked
; stage-1 IR of `tests/e2e/slice_control_select_bool_round2_window.c` +
; `..._lib.c` through the shipped 6.5 two-TU recipe (per-TU `clang -O1` ->
; `llvm-link` -> ONE `cq-lowering`), captured at the merge gate of 2026-09-14.
; That e2e slice ACCEPTED on the frozen session ORACLE `f7b65d8c` and is now
; UNREGISTERED (its golden deleted, the `.c` kept with the record in its header),
; exactly as `slice_control_switch_phase.c` was on 2026-09-05. The CMakeLists
; prose has said twice, in this very slice's own registration block, why the
; decline half cannot live at the e2e layer: "`run_slice*.sh` runs under
; `set -euo pipefail` and byte-diffs a golden, so a program whose `opt` exits
; non-zero cannot be a passing slice at all (there is no WILL_FAIL and no decline
; runner in this file)". So the decline comes HERE, as its linked stage-1 module.
;
; THE PROGRAM, AND WHY THE OLD VERDICT WAS WRONG:
;
;     bool x  = (y != 0);          /* the %out-derived seed, round-2 tainted */
;     bool b  = cq_theta(x, 0.25); /* consumes the name `x`                  */
;     int  a  = b ? 2 : 5;         /* the 4.4 copy merge on that rail        */
;     bool b3 = cq_theta(x, 0.9);  /* the SIBLING — reads `x` a SECOND time  */
;
; `b3` names `Ry(0.9)|x>`; the register holds `Ry(0.9)Ry(0.25)|x>`. That is
; `docs/frontend.md` §3.2's linear rule — a rotation CONSUMES the old name — and
; it is the project's P1 stale-reader class: two siblings emitting on ONE
; physical register. The original header (kept verbatim below) argued ORDER, and
; its argument is TRUE OF EXACTLY ONE OF THE TWO READS: "the register the copies
; read really is Ry(0.25)|x>, the label `b` names" is about the MERGE's read of
; `b` and says nothing about `b3`'s own read. `b3` is where the defect is. The
; same sentence, about the same defect, is in the cmp twin's converted header.
;
; ⚠ WHAT IS **NOT** LOST, checked before this file was written, so nobody
; re-derives it:
;   * "the round-2 window is OPEN and the program still lowers" stays pinned by
;     `control_phase_kickback_rail_round2_window_accept.ll` and
;     `control_phase_nest_rail_round2_window_accept.ll` — both unchanged, both
;     green on this binary;
;   * the rail ladder's round-2 re-verification (`reverifyRailCondReads`) stays
;     pinned by `control_swap_select_rail_round2_opaque_seed_accept.ll`;
;   * the DECLINE side by `control_swap_reject_select_rail_round2_plainc_twotu.ll`,
;     `..._sibling_theta.ll` and `..._measured_parent.ll`.
;   WHAT IS LOST is the one cell the cmp twin's header already names: the window
;   with a sibling PRESENT and the DT prong ACCEPTING. The shape "two sibling
;   rotations on one rail, both read" IS the defect, so that cell may be empty by
;   construction — which is the honest statement, not a proof.
;
; RETIREMENT TRIGGER (L8): this file and the cmp twin stand or fall TOGETHER.
; If the open question recorded in `control_swap_select_cmp_round2_window_accept.ll`
; — whether the CHAINED rewrite (`cq_theta(%b, 0.9)` instead of a sibling on
; `%x`) is a separate over-decline — resolves as an over-decline and the chained
; spelling is made to lower, then BOTH files become ACCEPTs again with that one
; operand changed and their headers intact, and the two e2e slices can be
; RE-REGISTERED with freshly derived goldens. Re-derive them then; do not delete
; either file, and do not re-register a slice without re-deriving its golden.
;
; ─────────────────────────────────────────────────────────────────────────────
; THE ORIGINAL e2e HEADER, KEPT VERBATIM WITH EVERY DIRECTIVE NEUTERED. It is the
; record of what this program was FOR, and — as above — its correctness claim is
; true of the merge's read and false of `b3`'s. The trace it predicts is the one
; the ORACLE emitted; it is NOT what this binary emits, because this binary
; declines.
;
; (was) slice_control_select_bool_round2_window.c — bd test_C_libtooling-r9e5
; (was) (Inc 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1): THE ROUND-2 TAINT WINDOW,
; (was) ACCEPTED, and it is the discriminator that the fix is a RE-VERIFICATION
; (was) and not a refusal of the window.
; (was)
; (was) Two TUs through the shipped 6.5 recipe (per-TU `-O1` IR -> `llvm-link` ->
; (was) ONE `cq-lowering`), because the window needs a callee `clang` cannot
; (was) inline:
; (was)
; (was)     int ext_f(int a);                 // _lib.c: { return a + 100; }
; (was)     int q = 3; q = cq_theta(q, 0.5);
; (was)     int y = 5;
; (was)     if (q > 5) y = ext_f(7);          // the 6.5 classical-call arm -> %out
; (was)     int keep = cq_measure(y);         // keeps %out live as an i32 phi
; (was)     bool x = (y != 0);                // CLASSICAL at round 1, TAINTED at round 2
; (was)     bool b  = cq_theta(x, 0.25);      // the rail the select reads
; (was)     int a = b ? 2 : 5;                // the 4.4 copy merge on that rail
; (was)     bool b3 = cq_theta(x, 0.9);       // the SIBLING — after the select
; (was)
; (was) `%x` is the `%out`-derived seed the §14.3 rail ladder saw as CLASSICAL
; (was) (round-1 taint) and `lowerRotations` sees as TAINTED (final taint), so `b`
; (was) and `b3` are ONE physical rail — the exact window in which the SAME
; (was) program with the sibling BEFORE the select is a wrong unitary
; (was) (`control_swap_reject_select_rail_round2_plainc_twotu.ll`, the committed
; (was) stage-1 module of that program, and `..._round2_sibling_theta.ll`).
; (was)
; (was) HERE IT IS CORRECT AND IT STILL LOWERS. The sibling runs after the merge,
; (was) so the register the copies read really is `Ry(0.25)|x>` — the label `b`
; (was) names — and the trace is the source order, gate for gate:
; (was)
; (was)     cq_template_icmp_ne_i32_hl(h2, 0) -> h5     <- %x's rail
; (was)     cqrt_ry_i1(h5, 0x1p-2)                      <- b
; (was)     cqrt_alloc_i1(0) -> h6; cqrt_cnot(h5, h6)   <- the copy flag
; (was)     ... the §5a merge on h6 ... cqrt_free(h6)
; (was)     cqrt_ry_i1(h5, 0x1.ccccccccccccdp-1)        <- b3, AFTER the merge
; (was)
; (was) `reverifyRailCondReads` re-asks rung (iii) at the recorded read point (the
; (was) first `cqrt_cnot`) with FINAL taint: the position-free walk DOES now find
; (was) the sibling — the F-1b-1 tainted-parent ancestry reaches it — and the DT
; (was) prong then proves it runs after every execution of that read, which is
; (was) `ProvenPostRegion`. Option 3 of the review (treat any non-`Constant`
; (was) arg-0 as chained) would have refused this program; option 1 keeps it.
; (was)
; (was) ORDER IS THE ASSERTION. No `cqrt_x` on either user register (h0, h5), one
; (was) `cqrt_free` per minted flag and none of a user register, STRICT stage 2b.
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
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 2.500000e-01) #3
  %10 = select i1 %9, i32 2, i32 5
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 9.000000e-01) #3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11) #3
  %14 = zext i1 %13 to i32
  %15 = add i32 %12, %7
  %16 = add i32 %15, %14
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
