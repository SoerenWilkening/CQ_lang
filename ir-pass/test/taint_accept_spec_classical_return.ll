; taint_accept_spec_classical_return.ll — ACCEPT (bd test_C_libtooling-9bhg).
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
;
; A TWO-TU module: the caller TU (`-include CQ.h`) llvm-linked with a plain-C
; library TU, as tests/e2e/run_slice_multi.sh builds one (single-TU -O1 deletes
; the dead argument, so the shape needs the second TU).
;
; `f` returns `t = h(q, m)`. `h(q, m)` reads the register `q`, so at DETECTION it
; is a Phase-6 specialization site and its result is tainted CONSERVATIVELY; the
; clone `__cq_q_h_01` later proves it returns the CLASSICAL `k + 1`. `f` therefore
; returns a classical integer and `main` reads it classically — which is what the
; pre-3jru compiler (aad63450) emitted, byte for byte.
;
; bd 3jru made taint cross call returns, and its refusal `quantum value returned
; across a function boundary` ran on that PRE-specialize conservative taint, so
; this module declined on 983f9361 (an over-decline, owner ruling 2026-09-11).
; The fix: `propagateWorklist` no longer crosses a return whose taint is
; SPECIALIZATION-PROVISIONAL (`returnTaintIsSpecProvisional` — every tainted return
; value lies in the counterfactual scrub cone of the function's own specialization
; sites), so `main` never sees provisional taint; the early refusal skips such a
; function and `declineQuantumReturnCalls` is RE-ASKED after `specialize()`'s scrub,
; where the verdict is final.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   __attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
;   int main(int argc, char **argv) { int m = atoi(argv[1]); return f(m); }
;
; Regenerate: clang -O1 -emit-llvm -S each TU as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not=CQ_DEADARG_DBG
; CHECK-NOT: error
; CHECK-LABEL: define i32 @f(
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; bd vsfp (merged 2026-09-27): the clone reads no slot 0, so `resolvePhantomCloneArgReads`
; NEUTRALISES it (`0`), `q` has no reader left, and the spine discharges it exactly as the
; hand-inlined twin (`t = m + 1`) does: Ry(-0.5), then a proven-|0> free.
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %h)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %0)
; CHECK-NEXT: ret i32 [[T]]
; CHECK-LABEL: define i32 @main(
; CHECK-NOT: cq{{rt|_template}}_
; CHECK: [[R:%[0-9]+]] = tail call i32 @f(i32 noundef %5)
; CHECK-NEXT: ret i32 [[R]]
; CHECK-LABEL: define internal i32 @__cq_q_h_01(
; CHECK-NEXT: vsfp.join:
; CHECK-NEXT: add nsw i32 %1, 1
; CHECK-NEXT: ret i32

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #5
  %3 = tail call i32 @h(i32 noundef %2, i32 noundef %0) #5
  ret i32 %3
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

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
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %vsfp.c = icmp eq i32 %0, 0   ; bd vsfp: a BRANCH-ONLY read keeps this parameter LIVE (header)
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
  %3 = add nsw i32 %1, 1
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
