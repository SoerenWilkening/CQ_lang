; spec_accept_predicted_classical_indirect_call_arg.ll — ACCEPT (bd test_C_libtooling-cepm (round 3; Rule-13 r2 F-r2-4)).
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
; Here the site's SECOND argument is `fp(n)`, an INDIRECT call through a function pointer chosen at
; run time (`fp = (m > 4) ? G : G2`, both classical). Round 1b's `LaterTaintOracle` counted ANY indirect
; call as a value a later round can taint, predicted the site quantum, tainted `t` at round 1 and bd
; l3oi's fence declined. Round 2 removed that seed with the callee seed (bd we38): an indirect call is
; never crossed by bd 3jru (the crossing requires the call to NAME the function). THIS FILE PINS the
; indirect half, which `spec_accept_predicted_classical_measured_callee.ll` (the callee-name half) does
; not (Rule-13 r2 F-r2-4). Sibling probe `fp1` (fp → a `cq_theta`-holding, measured-return callee)
; accepts twin-identically too.
;
; 6 TUs, each `clang -O1`, llvm-linked as tests/e2e/run_slice_multi.sh does.
; Caller TU (-include CQ.h):
;   int h(int a, int k);
;   int G(int n); int G2(int n);
;   int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int (*fp)(int) = (m > 4) ? G : G2; int q = cq_theta(m, .5); int y = fp(n); int t = h(q, y); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q); }
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
; Library TU 5 (plain C):
;   int G(int n) { return n * 5 + 1; }
;   int G2(int n) { return n - 3; }
;
; Oracle 9a230646: DECLINE `classical call result used as a quantum register`. Round 1b: same.
; Hand-inlined twin (fp3T.c: `g(q); int t = y + 1;`) is TRACE-IDENTICAL under argv
; `5 7` and `2 9`, stage 2b STRICT clean on both (docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/twincmp.sh).
; Regenerate: docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/mkprobes.py + gen.sh fp3C, then mkfix.py.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:       %[[Y:[0-9]+]] = tail call i32 %{{[0-9]+}}(
; CHECK-NEXT:  %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef %{{[A-Za-z0-9_.]+}}, i32 noundef %[[Y]])
; CHECK-NOT:   cq_template_icmp
; CHECK:       %[[C:[0-9]+]] = icmp sgt i32 %[[T]], 3
; CHECK-NEXT:  br i1 %[[C]],
; CHECK:       ret i32

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
  %9 = icmp sgt i32 %5, 4
  %10 = select i1 %9, ptr @G, ptr @G2
  %11 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %12 = tail call i32 %10(i32 noundef %8) #4, !callees !10
  %13 = tail call i32 @h(i32 noundef %11, i32 noundef %12) #4
  %14 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 4.000000e-01) #4
  %15 = icmp sgt i32 %13, 3
  br i1 %15, label %16, label %18

16:                                               ; preds = %2
  %17 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 2.000000e-01) #4
  br label %18

18:                                               ; preds = %16, %2
  %19 = phi i32 [ %17, %16 ], [ %14, %2 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
  %21 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  %22 = add nsw i32 %21, %20
  ret i32 %22
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @G(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 5
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483648, 2147483645) i32 @G2(i32 noundef %0) local_unnamed_addr #3 {
  %2 = add nsw i32 %0, -3
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0, !0}
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
!10 = !{ptr @G, ptr @G2}
