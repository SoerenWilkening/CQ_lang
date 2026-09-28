; spec_reject_dropped_arg_statepred_runtime_seed.ll — ⚠ NOW AN ACCEPT (bd
; test_C_libtooling-z0re, OWNER RULING 2026-09-28, option (a)). The file keeps its
; `_reject_` name DELIBERATELY (the bd gahu precedent — a `git mv` can be resurrected
; by a merge, CLAUDE.md L8); read the verdict off the RUN lines. RETIREMENT
; TRIGGER (L8): rename to `spec_dropped_arg_statepred_runtime_seed.ll` in bd gahu's
; batch rename (the bead lists this file), then run the duplicate-body scan.
;
; The OWNER QUESTION bd z0re's member `l12C` (d88e probes). On `main` aee8f4f8 `t =
; h(q, m)` was a Phase-6 site: round 1 read the conservatively-tainted `t` as a
; register and classified `if (q2 > 3) r = cq_theta(t, .2)` as an IN-PLACE
; controlled-Ry arm; after `specialize()` scrubbed `t` it lowered as a controlled
; state prep seeded by a RUNTIME value, while the hand-inlined twin (`int t = m + 1;`)
; declined at F1 (literal-only seed). bd vsfp's dead-argument drop then turned the
; call into `h(0, m)`, so the module IS the twin and it declined with F1's string —
; this file pinned that, and its own header said "THIS IS NOT A RULING ON bd z0re".
;
; THE RULING: option (a) — admit the runtime seed on the DIRECT path, so twin and
; side door agree by ACCEPTING. The drop still fires (first CHECK, stderr); the
; module then lowers exactly as the twin `slice_z0re_runtime_seed_prep.c` does: the
; fresh rail is `cqrt_alloc_i32(%9)` with `%9` the classical `h(0, m)` result, rotated
; by `.2` under the flag from `q2 > 3`. The side door that still READS its argument
; is pinned separately (`spec_stateprep_runtime_seed_side_door{,_twin}.ll`). RED on
; the ORACLE (main 9a230646), which declined.
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int t = h(q, m); int q2 = cq_theta(n, .3); int r = t; if (q2 > 3) r = cq_theta(t, .2); return cq_measure(r) + cq_measure(q2); }
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;
; Regenerate (the tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19):
;   clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o caller.ll
;   clang -O1 -emit-llvm -S lib.c -o lib.ll      (plain C, no CQ.h)
;   llvm-link -S caller.ll lib.ll -o <this file's body>
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   -o %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=DBG < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; DBG: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
; DBG-NOT: error
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[T:[0-9]+]] = tail call i32 @h(i32 noundef 0, i32 noundef %5)
; CHECK-NEXT: %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %8)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q2]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q2]], i32 3)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[T]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q2]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q2]])

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %10 = tail call i32 @h(i32 noundef %9, i32 noundef %5) #4
  %11 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 3.000000e-01) #4
  %12 = icmp sgt i32 %11, 3
  br i1 %12, label %13, label %15

13:                                               ; preds = %2
  %14 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 2.000000e-01) #4
  br label %15

15:                                               ; preds = %13, %2
  %16 = phi i32 [ %14, %13 ], [ %10, %2 ]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #4
  %18 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  %19 = add nsw i32 %18, %17
  ret i32 %19
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

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
