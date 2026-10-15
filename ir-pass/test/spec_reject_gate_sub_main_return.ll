; spec_reject_gate_sub_main_return.ll — DECLINE (bd test_C_libtooling-p3kd.21 R11 r2
; F1, bd r2j3.35; reviewer probe revS4/p4.c). `main` returns a register:
;
;   int main(int argc, char **argv) { int q = argc; cq_theta(&q, 0.5); return q; }
;
; `main`'s return is the process exit status, classical by definition, so the
; register reaches classical code without `cq_measure`: physics-forbidden under
; NORTHSTAR goal 1 (coordinator ruling from NORTHSTAR, 2026-10-15). Before, it
; lowered to `ret i32 %h`, the rail's index as the exit status. The check is
; `declineTaintEscapes`' (the one owner); `main` is never an export
; (`isQuantumReturnExport`). Positive twin, same body measuring:
; spec_accept_gate_sub_main_return_measured.ll. Mirrors the diagnostic
; character-for-character. `clang -O1 -include CQ.h` output verbatim.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function main i32 (i32, ptr): cq taint escape: quantum value returned from main without cq_measure

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  ret i32 %3
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
