; control_inplace_ry_reject_rail_sibling_theta.ll — DECLINE at RUNG (iii): a
; SIBLING `cq_theta` on the condition register's OWN PHYSICAL RAIL, before the
; branch (probe `p1`, `clang -O1` stage-1 module committed verbatim). This is the
; F-1b-1 class — the CONFIRMED silent miscompile the Inc-1b Rule-13 round-1
; review found — arriving at a new consumer:
;
;     int q = q0; cq_theta(&q, .2);  _Bool t = (_Bool)(q & 1);
;     _Bool b = t; cq_theta(&b, 0.5);
;     _Bool c = t; cq_theta(&c, 0.9);  /* SAME RAIL as b after lowerRotations */
;     if (b) cq_theta(&r, 0.9);
;
; `lowerRotations` lowers a `cq_theta` IN PLACE whenever its arg-0 is TAINTED and
; RAUWs the whole chain onto ONE handle, so `b` and `c` denote one register and
; the branch's name `b` is STALE by the time the arm's gate fires. The fence is
; `findNonDiagonalWireGate`, whose backward ancestry crosses a chained theta's
; arg-0 edge on `lowerRotations`' own `Chained` relation (the F-1b-1 fix) — which
; is why the TEMPLATE parent `%t` here does not hide the sibling.
;
; ⚠ THE SEED MUST BE TAINTED FOR THIS SHAPE TO EXIST AT ALL, and that is a
; measured fact worth keeping: with a CONSTANT seed (`_Bool t = 0;`) `-O1`
; const-folds both thetas' arg-0 to `i1 false`, so they become two SOURCE thetas
; on two SEPARATE rails and the program is correct and ACCEPTS. Probe `t10` is
; that program; it is not a sibling shape at `-O1` and no fixture claims it is.;
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

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4/probes/p1_sibling_theta_real.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4/probes/p1_sibling_theta_real.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.000000e-01) #2
  %3 = and i32 %2, 1
  %4 = icmp ne i32 %3, 0
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %4, double noundef 5.000000e-01) #2
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %4, double noundef 9.000000e-01) #2
  %7 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br i1 %5, label %8, label %10

8:                                                ; preds = %1
  %9 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 9.000000e-01) #2
  br label %10

10:                                               ; preds = %8, %1
  %11 = phi i32 [ %9, %8 ], [ %7, %1 ]
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2
  %13 = zext i1 %12 to i32
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2
  %15 = zext i1 %14 to i32
  %16 = add nuw nsw i32 %15, %13
  %17 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %18 = add nsw i32 %16, %17
  ret i32 %18
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice(i32 noundef 3)
  ret i32 0
}

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
