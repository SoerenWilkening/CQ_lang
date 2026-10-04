; control_inplace_ry_reject_rail_round2_sibling_theta.ll — DECLINE from
; `reverifyRailCondReads`, i.e. from the bd `r9e5` ROUND-2 TRIPWIRE, at a NEW
; consumer. Hazard H-2, and it is the single most likely way l4x4.b could have
; shipped a silent miscompile.
;
; THE WINDOW. The §13.3 rail ladder's rungs (ii) and (iii) are asked inside
; `detectControlRegions` with ROUND-1 taint, while `lowerRotations` decides
; chained-vs-source with FINAL taint (`Chained = taint.Tainted.count(arg0)`), and
; `repropagateControlMerges` re-seeds taint from the 6.5/4.5 `%out` rails in
; between. A `cq_theta_i1` whose arg-0 is DERIVED from `%out` is a SOURCE theta to
; both of the ladder's closures and a CHAINED one to the lowering — so its sibling
; rides the SAME physical rail, invisibly to a fence that already ran.
;
; THE PROGRAM. Two TUs through the shipped 6.5 recipe (per-TU `clang -O1` ->
; `llvm-link` -> ONE `cq-lowering`), committed as the LINKED STAGE-1 MODULE it
; really is:
;
;   int ext_f(int a);  void ext_sink(int a);       /* lib: { return a + 100; } */
;   int slice(int g) {
;       int q = 3; cq_theta(&q, 0.5);
;       int y = 5;
;       if (q > 5) y = ext_f(7);        /* 6.5 classical-call arm -> %out      */
;       int keep = cq_measure(y);
;       if (g) ext_sink(keep);          /* an opaque CLASSICAL diamond — see ⚠ */
;       bool x  = (y != 0);             /* CLASSICAL at round 1                */
;       bool b  = x; cq_theta(&b, 0.25);
;       bool b3 = x; cq_theta(&b3, 0.9);  /* SIBLING on the same wire            */
;       int r = 7; cq_theta(&r, 0.25);
;       if (b) cq_theta(&r, 0.9);    /* the in-place Ry arm reads `b`       */
;       return cq_measure(r) + cq_measure(b3) + keep;
;   }
;
; MEASURED WITH THE RECORD DISABLED (the mutation that proves it is load-bearing,
; not decoration): `markRailCondRead` commented out at both emitter sites, `opt`
; EXIT 0, verify-clean, and the emitted stream is
;
;     cq_template_icmp_ne_i32_hl(%out, 0) -> h      <- x's rail
;     cqrt_ry_i1(h, 0.25)                           <- b  = θ(x, .25)
;     cqrt_ry_i1(h, 0.9)                            <- b3 = θ(x, .9)  ** SAME RAIL **
;     cqrt_ry_i32_controlled(h, h2, 0.9)            <- controlled on Ry(.9)Ry(.25)|x>
;
; i.e. the arm fires controlled on a register the source's condition does not
; name. With the record in place the pass declines here.
;
; ⚠ THE `if (g) ext_sink(keep);` LINE IS LOAD-BEARING AND IS NOT PADDING. Without
; it the rail region's `Pred` IS the 6.5 arm's merge block, and
; `lowerControlRegions`' hcrg precedence graph refuses that alias outright
; (`sequentialChainAlias` admits only `BranchRegion`/`PhaseKickback` kinds) with
; a generic `control flow` — PRE-EXISTING and arm-class-independent, MEASURED on
; `main` with the COMPARE twin of this very program, which declines identically.
; The opaque classical diamond simply moves the rail region out of that block so
; the round-2 window is reachable at all.
;
; ⚠ THERE IS NO e2e DECLINE MODE, which is why the linked module lives here and
; not in `tests/e2e`: `run_slice_multi.sh` runs under `set -euo pipefail` and
; byte-diffs a golden, so a program whose `opt` exits non-zero cannot be
; registered as a passing slice at all.;
; RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4: both decline
; `bare i1 register condition` at `classifyArms`' first gate, so neither binary
; can witness this fence at all. The string below is reachable only because
; l4x4.b widened that gate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout, so every IR-TEXT negative a
; decline fixture could carry is VACUOUS — `2>&1 | FileCheck` sees the diagnostic
; and nothing else. What pins "no silent lowering" is the `not` INVERSION on the
; RUN line above (the pass must exit non-zero) plus the string below, mirrored
; character-for-character against `ir-pass/src`.
; CHECK: error: {{.*}}cq {{[a-z ]*}}lowering: condition predates a non-diagonal gate under quantum control

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %3 = icmp sgt i32 %2, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ 5, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  %9 = icmp eq i32 %0, 0
  br i1 %9, label %11, label %10

10:                                               ; preds = %6
  tail call void @ext_sink(i32 noundef %8) #3
  br label %11

11:                                               ; preds = %10, %6
  %12 = icmp ne i32 %7, 0
  %13 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %12, double noundef 2.500000e-01) #3
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %12, double noundef 9.000000e-01) #3
  %15 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #3
  br i1 %13, label %16, label %18

16:                                               ; preds = %11
  %17 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 9.000000e-01) #3
  br label %18

18:                                               ; preds = %16, %11
  %19 = phi i32 [ %17, %16 ], [ %15, %11 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  %21 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %14) #3
  %22 = zext i1 %21 to i32
  %23 = add i32 %20, %8
  %24 = add i32 %23, %22
  ret i32 %24
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice(i32 noundef 1)
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

; bd vsfp round 2: `ext_sink` is now an EXTERNAL declaration (a body in a TU this
; module does not contain). Its linked body was empty and side-effect-free, so the
; dead-argument drop's liveness predicate saw `ext_sink(keep)` as a DEAD call and
; deleted it — with it the opaque diamond this file's header calls load-bearing, and
; the module fell back to the hcrg `control flow` decline (measured). The twin with
; the empty body visible would lose the diamond the same way; an opaque sink is what
; the header means by "opaque", so it is spelled that way now.
declare void @ext_sink(i32 noundef) local_unnamed_addr

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
