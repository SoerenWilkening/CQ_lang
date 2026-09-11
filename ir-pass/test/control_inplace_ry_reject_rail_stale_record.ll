; control_inplace_ry_reject_rail_stale_record.ll — DECLINE at R6: a PRE-REGION
; RECORD of the rotated register is read AFTER the region (`int mark = r;` …
; `cq_measure(mark)`, probe `t24`).
;
; After the region the register carries `Ry(θ)` on the `b = 1` branch, so every
; consumer must read the POST-region name (the merge φ, which M-β RAUWs to the
; last hoisted gate). An SSA name for the PRE-Ry value read afterwards is a stale
; record: the emitted gate would name the relabelled rail while the source means
; the value before it. R6 is unchanged by this increment — it is a question about
; the ROTATED REGISTER and never mentions the condition — and the COMPARE twin
; (probe `t24c`) declines with the identical string on `main`.;
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
; CHECK: error: {{.*}}cq {{[a-z ]*}}lowering: stale rail record read past a controlled Ry under quantum control

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4/probes/t24_stale_record.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4/probes/t24_stale_record.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br i1 %1, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ %2, %0 ]
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %8 = zext i1 %7 to i32
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %10 = add nsw i32 %9, %8
  %11 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
  %12 = add nsw i32 %10, %11
  ret i32 %12
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br i1 %1, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  br label %5

5:                                                ; preds = %0, %3
  %6 = phi i32 [ %4, %3 ], [ %2, %0 ]
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %9 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
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
