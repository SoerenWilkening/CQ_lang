; lowering_reject_classical_mux_phi_spec_scrubbed_base_controlled_consumer.ll —
; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@h` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces
; an integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; never reaches the specializer: `t` is classical from the start and the
; classical-mux guard itself declines with this very string — the verdict AND the
; string survived while the SUBJECT (the d88e re-ask) vanished, which no stdout/stderr
; A/B can see (found by the `CQ_DEADARG_DBG` census: 33 lit modules touched).
; The added lines in `@h` (a branch-only read — see ROUND 2 below) keep the parameter live, so this file still reaches the fence it was written for. That
; residual population — a callee that READS the argument yet returns classical — is
; IR-ONLY from C at -O1 (the library TU deletes a dead read). The `env
; CQ_DEADARG_DBG=1` + `CHECK-NOT: CQ_DEADARG_DBG` pair pins that the drop does NOT
; fire here: a widening of the drop (e.g. to dataflow liveness) retires this subject
; and must re-derive it (CLAUDE.md L8).
; ⚠ ROUND 2 (bd vsfp, Rule-13 r1A/r1B): round 1's DEAD `mul` read no longer keeps the
; parameter used — the drop now asks LIVENESS (`DeadValueLiveness.h`), and a value that
; reaches no root is dead. The read is therefore a BRANCH-ONLY one now: `%vsfp.c` and an
; EMPTY diamond on it. A branch condition is a liveness ROOT (the predicate has no
; control dependence — see its LIMITS), so the parameter is LIVE in the original callee,
; the drop does not fire (the NODROP / CHECK-NOT pin below), and the clone is built as
; before; the clone's own flatten then removes the branch and the specializer records
; the slot dead. Where this module ACCEPTS, its operand is a `cq_theta` result (the
; phantom-read backstop's one exemption); where it DECLINES, the owner named here fires
; before the backstop is asked. A predicate WITH control dependence (ADCE) retires this
; subject — the pin below then turns red and the subject must be re-derived (L8).
;
; DECLINE (bd test_C_libtooling-d88e, Rule-13 round r1B F-DB-3): the lifted φ's
; consumer is a round-1-EMITTED quantum-controlled region, and the miscompile
; KEEPS every measurement.
;
; A TWO-TU module, built exactly as tests/e2e/run_slice_multi.sh builds one
; (r1B probe `zlC`). `t = h(q, m)` is a Phase-6 site whose clone returns the
; classical `k + 1`. The first `if` is a CLASSICAL one-register lift of
; `r = phi(t, cq_theta(t, .9))`; the second is a tainted-condition (`q2 > 3`)
; in-place controlled-Ry arm on `r`, which round-1 control emission already
; lowered — its hoisted `cq_theta(r, .2)` reads the lifted φ, i.e. the base `t`,
; as a register.
;
; On main `def1b088` (cq-opt `b1603d23`) this ACCEPTS at exit 0 with BOTH
; `cqrt_measure`s present — so a measure-count metric reads it as clean — and the
; circuit is wrong: after `specialize()` scrubs `t`, the user's Ry(.9) lands on a
; fresh rail `alloc(t) -> h2` that nothing ever reads, and the measured register is
; a SECOND fresh prep `alloc(t) -> h3` under `cqrt_ry_i32_controlled(flag, h3, .2)`
; that never saw the Ry(.9). bd `test_C_libtooling-l3oi`'s fence cannot see it
; either: when the emitter ran, the consumer was a still-unlowered `cq_theta`, not a
; `cqrt_*` call. The d88e re-ask (`declineFalsifiedMergePhiLifts`) declines it with
; the classical-mux guard's string, stderr byte-identical to the hand-inlined twin
; (`int t = m + 1;`, r1B `zlT`). No other fixture of this family has a lift whose φ
; feeds a quantum-controlled region.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int r=t; if (m>2) r=cq_theta(t,.9); int s=r; if (q2>3) s=cq_theta(r,.2); return cq_measure(s)+cq_measure(q2); }
;
; Regenerate: clang -O1 -emit-llvm -S the two TUs as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: in function main i32 (i32, ptr): cq taint escape: tainted value muxed by a classical-condition phi

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
  %12 = icmp sgt i32 %5, 2
  br i1 %12, label %13, label %15

13:                                               ; preds = %2
  %14 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #4
  br label %15

15:                                               ; preds = %13, %2
  %16 = phi i32 [ %14, %13 ], [ %10, %2 ]
  %17 = icmp sgt i32 %11, 3
  br i1 %17, label %18, label %20

18:                                               ; preds = %15
  %19 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 2.000000e-01) #4
  br label %20

20:                                               ; preds = %18, %15
  %21 = phi i32 [ %19, %18 ], [ %16, %15 ]
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #4
  %23 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  %24 = add nsw i32 %23, %22
  ret i32 %24
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %vsfp.c = icmp eq i32 %0, 0   ; bd vsfp r2: a BRANCH-ONLY read keeps this parameter LIVE
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
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
