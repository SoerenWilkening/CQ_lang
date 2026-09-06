; control_angle_select_phase_reject_sharecond.ll — DECLINE. Rule-13 round-1
; finding F-L4-3 (bd test_C_libtooling-3qlq Inc 1 part A, lens L4): the SHARED-
; CONDITION-FLAG angle select, and the ONE thing keeping F-L7-1 out of this path.
;
;     int f = (q > 5);
;     if (q > 5) cq_phi(0.9); else cq_phi(0.3);
;     return cq_measure(q + f);
;
; `clang -O1` folds the arms into ONE call on an angle select. The compare then
; has THREE users (the select, the branch's fold, and the `zext` data use), and
; `classifyAngleSelect`'s S2 `hasOneUse` refuses it before any of the by-difference
; machinery runs.
;
; WHY IT IS WORTH A FIXTURE RATHER THAN A NOTE. `AngleSelectEmit` mints its flag AT
; THE CONSUMER and, unlike `emitPhaseKickbackRegion`, has NO `ShareCondFlag` path
; at all — it strips and frees unconditionally. If the shared-flag shape ever
; reached it, the flag would be freed while a data lineage still read it, and the
; round-1 CONFIRMED miscompile F-L7-1 would have a second, differently-shaped
; door. Today that door is closed by `hasOneUse` and by nothing else, and nothing
; said so. (The Rz-gate half is now also covered by membership — every emitted
; gate here carries `!cq.branchphase` — but the FREE is not, which is why the
; structural fence is the one that matters here.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: rotation angle under quantum control
; CHECK-NOT: cqrt_rz

; ModuleID = 'p/m01_angsel_sharecond.c'
source_filename = "p/m01_angsel_sharecond.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = icmp eq i32 %2, 5
  %4 = zext i1 %3 to i32
  %5 = select i1 %3, double 9.000000e-01, double 3.000000e-01
  tail call void @cq_phi(double noundef %5) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %4) #2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2
  %2 = icmp eq i32 %1, 5
  %3 = zext i1 %2 to i32
  %4 = select i1 %2, double 9.000000e-01, double 3.000000e-01
  tail call void @cq_phi(double noundef %4) #2
  %5 = tail call i32 @cq_measure_si32(i32 noundef %3) #2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
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
