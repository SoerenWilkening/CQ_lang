; spec_accept_predicted_classical_state_prep_seed_bool.ll — ACCEPT (bd test_C_libtooling-cepm x bd z0re (round 3b)).
; THE READING CALLEE. `h` READS its quantum argument — through a call to `g`, whose own
; callee `f2` is an external in `g`'s TU, so `-O1` infers no `memory(none)`/`willreturn`
; for `g` and the pass's liveness (DeadValueLiveness.h) keeps the call as a ROOT, so bd
; vsfp's dead-argument drop does NOT fire — and returns the CLASSICAL `k + 1`.
; `predictReturnTainted(h, 01)` is FALSE (the masked parameter reaches neither the
; `ret` nor a conditional terminator), so since bd cepm propagation leaves the call's
; RESULT classical (`specCallResultPredictedClassical`, SpecializeClone.h): no stage
; before `specialize()` reads it as a register, and the clone `@__cq_q_h_01` (built
; unchanged) returns the classical value. Before bd cepm the result was tainted
; CONSERVATIVELY and scrubbed only after both control rounds.
; Here the classical-verdict result `t` is the SEED of a controlled state prep (`r = t; if (COND)
; { r = t; cq_theta(&r, θ); }`), or the base of an if/else angle select. THIS FILE PINS THE bd cepm x bd z0re
; COMPOSITION (Rule-13 r1B F-r1B-3 / r1A): with `t` classical it takes z0re's DIRECT path — a RUNTIME
; state-prep seed (`cqrt_alloc_<W>(t)` + `cqrt_ry_<W>_controlled` on the fresh rail) or an UNTAINTED
; angle-select base. On cepm ALONE it DECLINED (the direct path did not exist; the oracle 9a230646 had
; accepted it through the SIDE DOOR on the conservatively tainted `t`). On main (z0re, no cepm) it
; ACCEPTS with a BYTE-IDENTICAL lowered module, so it is not a corpus mover: it pins that the landing
; of cepm does not take this accept away.
;
; 5 TUs, each `clang -O1`, llvm-linked as tests/e2e/run_slice_multi.sh does.
; Caller TU (-include CQ.h):
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = m; cq_theta(&q, .5); int t = h(q, m); int r = t; _Bool b = (_Bool)0; cq_theta(&b, .3); if (b) { r = t; cq_theta(&r, .2); } return cq_measure(r) + cq_measure(b); }
; Library TU 1 (plain C):
;   /* h READS a (a call to g, an external here) and returns the CLASSICAL k + 1. */
;   void g(int a);
;   int h(int a, int k) { g(a); return k + 1; }
; Library TU 2 (plain C):
;   /* f2 is an external here: -O1 keeps the unused call and infers nothing. */
;   int f2(int a);
;   void g(int a) { f2(a); }
; Library TU 3 (plain C):
;   /* f3 is an external here: f2 gets no memory(none)/willreturn, so a call to f2
;      is a liveness ROOT of the pass. */
;   int f3(int a);
;   int f2(int a) { return f3(a) + 1; }
; Library TU 4 (plain C):
;   int f3(int a) { return a * 3; }
;
; Main ba4fdad4: ACCEPT, byte-identical lowered module. cepm alone (round 2, 89186a30): DECLINE
; `state prep seed does not match the merge incoming under quantum control`.
; Hand-inlined twin (zl17T.c: `g(q); int t = m + 1;`) is TRACE-IDENTICAL on the merged (cepm + rhk5 + z0re) binary under argv
; `5 7` and `2 9`, stage 2b STRICT clean on both (docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/twincmp.sh).
; tools/trace_twin_equiv.py: EQUIV.
; Regenerate: docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/mkprobes.py + gen.sh zl17C, then mkfix.py.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK:       %[[R:[A-Za-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[T]])
; CHECK-NEXT:  call void @cqrt_ry_i32_controlled(i32 %{{[A-Za-z0-9_.]+}}, i32 %[[R]], double 2.000000e-01)

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
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01) #4
  br i1 %8, label %9, label %11

9:                                                ; preds = %2
  %10 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 2.000000e-01) #4
  br label %11

11:                                               ; preds = %9, %2
  %12 = phi i32 [ %10, %9 ], [ %7, %2 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8) #4
  %15 = zext i1 %14 to i32
  %16 = add nsw i32 %13, %15
  ret i32 %16
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  tail call void @g(i32 noundef %0) #4
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define void @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f2(i32 noundef %0) #4
  ret void
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @f2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f3(i32 noundef %0) #4
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @f3(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0}
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
