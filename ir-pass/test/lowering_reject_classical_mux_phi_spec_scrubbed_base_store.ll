; lowering_reject_classical_mux_phi_spec_scrubbed_base_store.ll — DECLINE (bd test_C_libtooling-d88e, P1 silent miscompile, found by
; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@h` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces
; an integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; never reaches the specializer: `t` is classical from the start and the
; classical-mux guard itself declines with this very string — the verdict AND the
; string survived while the SUBJECT (the d88e re-ask) vanished, which no stdout/stderr
; A/B can see (found by the `CQ_DEADARG_DBG` census: 33 lit modules touched).
; The ONE added line in `@h`, `%vsfp.read`, is a DEAD READ that keeps the
; parameter used, so this file still reaches the fence it was written for. That
; residual population — a callee that READS the argument yet returns classical — is
; IR-ONLY from C at -O1 (the library TU deletes a dead read). The `env
; CQ_DEADARG_DBG=1` + `CHECK-NOT: CQ_DEADARG_DBG` pair pins that the drop does NOT
; fire here: a widening of the drop (e.g. to dataflow liveness) retires this subject
; and must re-derive it (CLAUDE.md L8).
;
; bd 9bhg's Rule-13 round r1A, F-9A-1): the measurement stored through a pointer from a non-`main` function.
;
; A TWO-TU module: the caller TU (`-include CQ.h`) llvm-linked with a plain-C
; library TU, exactly as tests/e2e/run_slice_multi.sh builds one. `t = h(q, m)`
; reads the tainted `q`, so `propagate` taints `t` CONSERVATIVELY and every stage
; before `specialize()` sees it as a quantum REGISTER. `declineClassicalMuxes`'
; one-register lift (`liftOneRegisterMergePhi`) therefore proved the
; classical-condition merge phi `phi(t, cq_theta(t, .2))` a pure renaming of ONE
; register, RAUW'd it to its wire base `t` and erased it. `specialize()` then
; clones `h`, proves the clone returns the CLASSICAL `k + 1`, and
; `scrubForwardCone` untaints `t`: the lift's premise is false after the fact.
; Before this fence the rotation lowered as a SOURCE on a fresh rail that nothing
; reads and the user's `cq_measure` read the classical `t` down the bd 21mg
; classical-measure path — NO measurement, `opt` exit 0, stage-2b STRICT clean
; (measured on main `def1b088`, cq-opt `b1603d23`: 0 `cqrt_measure` in the lowered
; module, 1 in the source). bd `test_C_libtooling-l3oi`'s fence could not see it:
; no EMITTED gate reads `t` — the consumers were reached through a RAUW.
;
; THE CORRECT DISPOSITION IS THE HAND-INLINED TWIN'S (`int t = m + 1;`, the same
; caller with `h`'s classical return written directly), and the twin DECLINES at
; `declineClassicalMuxes` with exactly the string below (measured on the same
; oracle): the phi muxes the classical `t` and a quantum register under a
; classical condition, a real data mux and not a renaming. The lift now RECORDS
; its taint-dependent premise (`taint.LiftedMergePhis`) and
; `declineFalsifiedMergePhiLifts` RE-ASKS it at FINAL taint right after
; `specialize()` in both entry points (CLAUDE.md L1: record, then re-ask).
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   __attribute__((noinline)) int f(int m, int *out) { int q = cq_theta(m, .5); int t = h(q, m); int r = t; if (m > 3) r = cq_theta(t, .2); *out = cq_measure(r); return 0; }
;   int main(int c, char **v) { int m = atoi(v[1]); int o; f(m, &o); return o; }
;
; Regenerate: clang -O1 -emit-llvm -S the two TUs as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: in function f i32 (i32, ptr): cq taint escape: tainted value muxed by a classical-condition phi

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define noundef i32 @f(i32 noundef %0, ptr nocapture noundef writeonly %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #6
  %4 = tail call i32 @h(i32 noundef %3, i32 noundef %0) #6
  %5 = icmp sgt i32 %0, 3
  br i1 %5, label %6, label %8

6:                                                ; preds = %2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 2.000000e-01) #6
  br label %8

8:                                                ; preds = %6, %2
  %9 = phi i32 [ %7, %6 ], [ %4, %2 ]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #6
  store i32 %10, ptr %1, align 4, !tbaa !6
  ret i32 0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = alloca i32, align 4
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  %5 = load ptr, ptr %4, align 8, !tbaa !10
  %6 = tail call i32 @atoi(ptr nocapture noundef %5)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #6
  %7 = call i32 @f(i32 noundef %6, ptr noundef nonnull %3)
  %8 = load i32, ptr %3, align 4, !tbaa !6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #6
  ret i32 %8
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #5 {
  %vsfp.read = mul i32 %0, 3   ; bd vsfp: a DEAD READ keeps this parameter used
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"any pointer", !8, i64 0}
