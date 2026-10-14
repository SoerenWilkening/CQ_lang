; taint_reject_quantum_return_9bhg_quantum_twin.ll — DECLINE (bd test_C_libtooling-3jru; companion of
; spec_accept_dropped_arg_9bhg_original.ll).
;
; Same program as bd 9bhg's original, but the callee READS its quantum argument
; (`h(a, k) = a + k`), so `t` is a genuinely quantum register returned across a
; function boundary: bd 3jru's loud refusal must still speak (bd 9bhg closed, not landed).
;
; Two TUs, clang -O1 -include CQ.h each, then llvm-link:
;   lib.c:  int h(int a, int k) { return a + k; }
;   main.c: (as in spec_accept_dropped_arg_9bhg_original.ll)
;
; bd p3kd.21 R11 r1 fix (2026-10-15) — NOW AN ACCEPT; the file name and the
; DECLINE text above are history. `f` holds `cq_theta` and returns `h(q, m) + cq_measure(q)`, a register it
; rotates returned through the lifted `h`, so after the dead-argument drop's slot
; B trigger (c) compiles its call at the site (R11 r1 item 7); `main` then
; returns that register, the existing Escaped contract of an entry point. The register is the caller's own, and
; the module compiles exactly as its hand-inlined twin does on the pre-change
; binary (`f`'s body written into `main`: identical, call for call). The 3jru refusal itself is unchanged and still pinned by
; taint_reject_quantum_return_fnptr.ll and
; spec_reject_predicted_classical_round2_return_crossing.ll.
;
; bd p3kd.21 R11 r2 F1 (bd r2j3.35, 2026-10-15) — A DECLINE AGAIN, on its true
; ground. The callee is still compiled at its site, so the 3jru crossing is gone,
; but `main` then returns the register as the process exit status, which NORTHSTAR
; goal 1 forbids: the subject of this fixture IS that return, so it is re-expected
; as the main-return decline (11adde57..020fc11e had accepted it).
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function main i32 (i32, ptr): cq taint escape: quantum value returned from main without cq_measure

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #5
  %3 = tail call i32 @h(i32 noundef %2, i32 noundef %0) #5
  %4 = tail call i32 @cq_measure_si32(i32 noundef %2) #5
  %5 = add nsw i32 %4, %3
  ret i32 %5
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @f(i32 noundef %5)
  ret i32 %6
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
