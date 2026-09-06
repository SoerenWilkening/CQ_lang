; control_angle_select_phase_reject_qq_cond.ll — DECLINE. Rule-13 round-1 finding
; F-L4-3 (bd test_C_libtooling-3qlq Inc 1 part A, lens L4): a Q+Q compare under an
; angle select.
;
; The flag mint passes no Q+Q width (PRD 6.3 / 9, pre-existing and unchanged by
; this increment), so `compareFlagMintable`'s dry run refuses and the region
; declines before any emission. The accept class for the phase stem is
; single-tainted-operand compares only; this file is what says the suite knows
; that, rather than leaving the Q+Q half to an unpinned code path.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: rotation angle under quantum control
; CHECK-NOT: cqrt_rz

; ModuleID = 'p/q01_qq_sel.c'
source_filename = "p/q01_qq_sel.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01) #2
  %5 = icmp eq i32 %3, %4
  %6 = select i1 %5, double 9.000000e-01, double 3.000000e-01
  tail call void @cq_phi(double noundef %6) #2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3) #2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %4) #2
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 2.500000e-01) #2
  %3 = icmp eq i32 %1, %2
  %4 = select i1 %3, double 9.000000e-01, double 3.000000e-01
  tail call void @cq_phi(double noundef %4) #2
  %5 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
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
