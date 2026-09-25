; taint_reject_scrubbed_handle_clone_arg_layout.ll — DECLINE (bd test_C_libtooling-9bhg;
; the fence is bd test_C_libtooling-l3oi Rule-13 round 7 F-R7-1's).
;
; The DECLINE twin of taint_reject_scrubbed_handle_clone_arg.ll, and the fixture
; that keeps bd l3oi's CLONE-READER clause (`taint.SpecHandleArgMask`) pinned now
; that the ordered scrub made that file an accept.
;
; HAND-EDITED from that file's llvm-linked two-TU module: `@main` is the same
; program — `q = cq_theta(m, .5); t = h(q, m); u = g(t); return cq_measure(u);` —
; with `u = g(t)` moved into a block LAID OUT BEFORE the block defining `t`
; (`entry → def → use`, layout `entry, use, def`). Legal IR; `clang -O1` does not
; emit this layout, which is why it is hand-written. `plan6.Pending` is in LAYOUT
; order, so the ordered scrub resolves `g(t)` FIRST, from its detection-time mask
; with `t` QUANTUM (`__cq_q_g_1`, returning a register), and only then proves `h`'s
; clone returns the classical `k + 1` and scrubs `t`. The clone call now reads the
; integer in its masked slot 0: `declineScrubbedHandleReads` refuses it.
;
; RETIREMENT TRIGGER: if `specialize()` ever orders `Pending` by dominance (RPO)
; instead of layout, this becomes the ACCEPT its twin is — re-derive it then and
; find another subject for the clone-reader clause (a loop-carried argument), do
; not delete the clause.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;   int g(int a) { return a * 3 + 1; }
;   int g2(int a, int b) { return a + b; }
;
; Regenerate: take taint_reject_scrubbed_handle_clone_arg.ll's module body and
; replace `@main` with the three-block function below.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main {{.*}}: cq taint escape: classical call result used as a quantum register

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
entry:
  %argv1 = getelementptr inbounds i8, ptr %1, i64 8
  %s = load ptr, ptr %argv1, align 8, !tbaa !6
  %m = tail call i32 @atoi(ptr nocapture noundef %s)
  %q = tail call i32 @cq_theta_si32(i32 noundef %m, double noundef 5.000000e-01) #4
  br label %def

use:                                              ; preds = %def
  %u = tail call i32 @g(i32 noundef %t) #4
  %r = tail call i32 @cq_measure_si32(i32 noundef %u) #4
  ret i32 %r

def:                                              ; preds = %entry
  %t = tail call i32 @h(i32 noundef %q, i32 noundef %m) #4
  br label %use
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
