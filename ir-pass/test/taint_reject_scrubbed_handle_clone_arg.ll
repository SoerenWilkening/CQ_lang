; taint_reject_scrubbed_handle_clone_arg.ll — ACCEPT since bd test_C_libtooling-9bhg
; (was a DECLINE for bd test_C_libtooling-l3oi, xdu2.13 Rule-13 round 7 F-R7-1).
;
; ⚠ THE NAME SAYS `reject` AND THE FILE IS AN ACCEPT. Deliberately not renamed: a
; `git mv` can be resurrected by a merge (CLAUDE.md L8; bd gahu's precedent). The
; property this file pins is now the ORDERED SCRUB, and its decline twin is
; taint_reject_scrubbed_handle_clone_arg_layout.ll.
;
; A TWO-TU module (caller TU with `-include CQ.h`, llvm-linked with a plain-C
; library TU, as tests/e2e/run_slice_multi.sh builds one). `t = h(q, m)` is
; tainted at detection, and `u = g(t)` was entered in `plan6.Pending` with `t`'s
; slot QUANTUM. Before bd 9bhg, `specialize()` built EVERY top-level clone from
; those detection-time masks and scrubbed only afterwards, so `__cq_q_g_1` read the
; integer `k + 1` as a register handle — the trace read
; `cq_template_mul_i32_hl(h5, 3)`, an unallocated id (exit 0 on aad63450; declined
; by bd l3oi's clone-reader fence on 983f9361).
;
; bd 9bhg ORDERS the scrub the way `buildClone` already orders its inner calls:
; each top-level site's scrub runs as soon as it resolves, and a later site's mask
; is RECOMPUTED from the current taint before it is built. `h`'s clone proves the
; classical `k + 1`, the scrub untaints `t` and `g(t)`, `g(t)`'s mask is then 0, and
; it is an ordinary classical call: no clone of `g`, no gate reading `t`, and the
; user's `cq_measure(u)` of a classical value lowers to the value (bd 21mg).
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;   int g(int a) { return a * 3 + 1; }
;   int g2(int a, int b) { return a + b; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k); int g(int a);
;   int main(int argc, char **argv) { int m = atoi(argv[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = g(t); return cq_measure(u); }
;
; Regenerate: clang -O1 -emit-llvm -S each TU as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not=__cq_q_g_
; CHECK-NOT: error
; CHECK-LABEL: define i32 @main(
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef %h, i32 noundef %5)
; CHECK-NEXT: [[U:%[0-9]+]] = tail call i32 @g(i32 noundef [[T]])
; CHECK-NEXT: ret i32 [[U]]

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call i32 @h(i32 noundef %6, i32 noundef %5) #4
  %8 = tail call i32 @g(i32 noundef %7) #4
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  ret i32 %9
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

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @g2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %1, %0
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
