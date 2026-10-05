; lowering_reject_break_phase_inloop_comparand.ll — DECLINE (bd
; test_C_libtooling-3by9). The genuinely unsafe NEIGHBOUR of
; lowering_loop_break_qq_phase.ll: the SAME kickback on the comparand `p`, moved
; from before the loop INTO the loop body. `clang -O1` output, unedited apart from
; the ModuleID / source_filename lines:
;
;     int break_phase_inloop(int x, int pseed, int n) {
;         int p = pseed; cq_theta(&p, 0.5);
;         int q = x; cq_theta(&q, 0.25);
;         for (int i = 0; i < n; i++) {
;             q = q ^ 9;
;             if (p == 3) cq_phi(0.3);    // INSIDE the break loop
;             if (q == p) break;
;         }
;         return cq_measure(q);
;     }
;
; WHY IT IS UNSAFE. The source fires the phase once per iteration UP TO the break,
; so the |p=3> branch picks up e^{i 0.3 k(q0,p)}, k the break iteration: a phase
; that depends on q's lineage through the loop's own control, not a diagonal on p
; alone. The 7.4 lowering runs the body for the FULL classical trip (the break is
; virtual) and its reverse-play replays only the rail gates and the break-cond
; chain, so any phase gate inside the construct would fire n times on every
; branch: the wrong unitary.
;
; WHY IT REACHES THE B3 FENCE, AND WHAT IT DISCRIMINATES. The phase block's
; DIRECT controller is `p == 3` (LICM-hoisted to the preheader), whose lineage is
; {p}, disjoint from the answer's lineage {q0, rail phi, q ^ 9}: a predicate that
; read only the direct controller would accept here exactly as it accepts the
; before-the-loop sibling. `lineageCarriesBranchPhase` walks the controllers
; TRANSITIVELY: the block holding the `p == 3` branch is itself control-dependent
; on the loop's fused exit `select(q^9 == p, true, i+1 == n)`, whose lineage
; contains the rail. So B3 declines with its own message.
;
; NOT THE ONLY WALL. With B3 disabled the loop is still refused, by tryBreak's
; B4 body clause (a side-effecting call in the body: the `cq_phi`), which rides
; L1 to `cq controlled lowering: loop under quantum control`. This fixture pins
; the B3 classification and its message, not the absence of any other fence.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break preserves a phase answer

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @break_phase_inloop(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %19

7:                                                ; preds = %3
  %8 = icmp eq i32 %4, 3
  br label %9

9:                                                ; preds = %14, %7
  %10 = phi i32 [ 0, %7 ], [ %16, %14 ]
  %11 = phi i32 [ %5, %7 ], [ %12, %14 ]
  %12 = xor i32 %11, 9
  br i1 %8, label %13, label %14

13:                                               ; preds = %9
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  br label %14

14:                                               ; preds = %13, %9
  %15 = icmp eq i32 %12, %4
  %16 = add nuw nsw i32 %10, 1
  %17 = icmp eq i32 %16, %2
  %18 = select i1 %15, i1 true, i1 %17
  br i1 %18, label %19, label %9, !llvm.loop !6

19:                                               ; preds = %14, %3
  %20 = phi i32 [ %5, %3 ], [ %12, %14 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  ret i32 %21
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
