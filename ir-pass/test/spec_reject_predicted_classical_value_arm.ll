; spec_reject_predicted_classical_value_arm.ll — DECLINE (bd test_C_libtooling-cepm (the L3 conjunct)).
; The call sits in the ARM of a QUANTUM condition (`if (q > 5) y = h(q, m);`). Its result is
; predicted classical, so it is no longer tainted — and `classifyClassicalCallArm` (6.5) used the
; RESULT's taint as its proof that every INPUT is classical ("propagate taints EVERY user of a
; tainted value", false since bd cepm). It now asks the inputs directly (`readsTaintedValue`),
; so the call is NOT a 6.5 classical-call arm and the region declines at `classifyArms` exactly
; as on the oracle. THE STRING IS THE PIN: without the `readsTaintedValue` conjunct the 6.5
; classifier claims the shape and declines `control flow under quantum control` (measured on
; this module), and a callee whose argument survives the drop with a `memory(none)` body (an
; IR-level shape) would be claimed and hoisted by it — see the ATTACK list in TRACK_CEPM_3ZR4.md.
;
; 5 TUs, each `clang -O1`, llvm-linked as tests/e2e/run_slice_multi.sh does.
; Caller TU (-include CQ.h):
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int y = 0; if (q > 5) y = h(q, m); return cq_measure(y) + cq_measure(q); }
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
; Oracle 9a230646: the same DECLINE (byte-identical first error line).
; Hand-inlined twin (vaT.c) declines with the SAME string.
; Regenerate: docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/mkprobes.py + gen.sh vaC, then mkfix.py.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: value-arm swap-route under quantum control

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
  %7 = icmp sgt i32 %6, 5
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  %9 = tail call i32 @h(i32 noundef %6, i32 noundef %5) #4
  br label %10

10:                                               ; preds = %8, %2
  %11 = phi i32 [ %9, %8 ], [ 0, %2 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  %13 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %14 = add nsw i32 %13, %12
  ret i32 %14
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
