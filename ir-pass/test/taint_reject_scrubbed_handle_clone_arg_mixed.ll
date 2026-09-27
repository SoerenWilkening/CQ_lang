; taint_reject_scrubbed_handle_clone_arg_mixed.ll — ACCEPT since bd test_C_libtooling-9bhg
; ⚠ bd test_C_libtooling-vsfp (merged into bd 9bhg 2026-09-27) — RE-SPELLED, and why.
; `@h` IGNORED its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now
; replaces an argument whose callee parameter is DEAD under liveness
; (`DeadValueLiveness.h`) by a constant before any stage reads it — what `clang -O1` does
; to the hand-inlined twin — so that spelling never reaches the specializer: no
; specialization site, no provisional return, and this file's subject is GONE. Measured on
; the merged tree before this re-spell: `CQ_DEADARG_DBG: drop arg 0 of @h`, and 4 of
; the 11 affected bd 9bhg fixtures still PASSED — for the hand-inlined twin's reason, not
; theirs (CLAUDE.md Rule 12(c)).
; The BRANCH-ONLY read now in `@h` (`%vsfp.c` feeding an EMPTY diamond — bd vsfp's
; own round-2 spelling) keeps the parameter LIVE: a branch condition is a liveness root.
; So the drop does not fire (pinned: `env CQ_DEADARG_DBG=1` on the RUN line and
; `--implicit-check-not=CQ_DEADARG_DBG`), the specialization site exists at propagation as
; before, and the clone is built as before. The clone's own flatten then removes the
; branch, the specializer records slot 0 dead, and `resolvePhantomCloneArgReads` (last in
; the post-`specialize()` chain) neutralises that slot where the module gets that far.
; From C at -O1 this spelling is IR-ONLY: the library TU deletes an empty branch. The
; `Library TU` source below is the ORIGINAL; the module is hand-edited from it.
; RETIREMENT TRIGGER: a liveness predicate WITH control dependence (ADCE) makes this read
; dead too. The pin then turns red and the subject must be re-derived (L8).
; (was a DECLINE for bd test_C_libtooling-l3oi, xdu2.13 Rule-13 round 7 F-R7-1).
;
; ⚠ THE NAME SAYS `reject` AND THE FILE IS AN ACCEPT. Deliberately not renamed: a
; `git mv` can be resurrected by a merge (CLAUDE.md L8; bd gahu's precedent). The
; property this file pins is now the ORDERED SCRUB's MASK RECOMPUTATION.
;
; A TWO-TU module (caller TU with `-include CQ.h`, llvm-linked with a plain-C
; library TU, as tests/e2e/run_slice_multi.sh builds one). `t = h(q, m)` is
; tainted at detection, so `u = g2(t, q)` entered `plan6.Pending` with mask 0b11.
; Before bd 9bhg the clone `__cq_q_g2_11` was built from that mask and took the
; scrubbed `t` in its quantum slot 0 beside the genuine register `q` — the trace
; read `add_i32(h0, h5)` (exit 0 on aad63450; declined by bd l3oi's clone-reader
; fence on 983f9361).
;
; bd 9bhg scrubs `h`'s site as soon as its clone proves the classical `k + 1`, then
; RECOMPUTES `g2(t, q)`'s mask from the current taint: 0b10. The clone is
; `__cq_q_g2_10` — `t` a classical operand, `q` the register — and its body is the
; mixed `a + b` over one handle, `cq_template_add_i32_hl(q, t)`, never a Q+Q add
; over an integer id.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;   int g(int a) { return a * 3 + 1; }
;   int g2(int a, int b) { return a + b; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k); int g2(int a, int b);
;   int main(int argc, char **argv) { int m = atoi(argv[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = g2(t, q); return cq_measure(u); }
;
; Regenerate: clang -O1 -emit-llvm -S each TU as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not=CQ_DEADARG_DBG --implicit-check-not=__cq_q_g2_11
; CHECK-NOT: error
; CHECK-LABEL: define i32 @main(
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; bd vsfp (merged 2026-09-27): h's slot 0 NEUTRALISED (`0`); `q` is still read by g2.
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %5)
; CHECK-NEXT: [[U:%[0-9]+]] = tail call i32 @__cq_q_g2_10(i32 noundef [[T]], i32 noundef %h)
; CHECK-NEXT: %m = call i32 @cqrt_measure_i32(i32 [[U]])
; CHECK-NEXT: ret i32 %m
; The clone: `b` (slot 1, the register) is the HANDLE and `a` (slot 0, `t`) the
; LITERAL of the one mixed add; then the ordinary Bennett copy-out and reverse.
; CHECK-LABEL: define internal i32 @__cq_q_g2_10(
; CHECK-NEXT: %h_op = call i32 @cq_template_add_i32_hl(i32 %1, i32 %0)
; CHECK-NEXT: %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %1, i32 %0)
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
; CHECK-NEXT: ret i32 %cqq.out

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
  %8 = tail call i32 @g2(i32 noundef %7, i32 noundef %6) #4
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  ret i32 %9
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %vsfp.c = icmp eq i32 %0, 0   ; bd vsfp: a BRANCH-ONLY read keeps this parameter LIVE (header)
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
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
