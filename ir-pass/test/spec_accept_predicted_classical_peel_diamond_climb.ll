; spec_accept_predicted_classical_peel_diamond_climb.ll — ACCEPT (bd test_C_libtooling-cepm (round 3; Rule-13 r2 F-r2-1)).
; HAND IR (Rule-13 r2 review probe `review_r2_cepm/probes/ir/pkdC.s1.ll`, copied verbatim to
; `cepm_probes/ir/`): an if/else diamond on the tainted `q > 5` with two NON-EMPTY phase arms
; (`cq_phi(.2)` | `cq_phi(.3); cq_phi(.1)`) and two pred-available merge φs `y=[m|n]`, `z=[n|m]`, feeding
; `t = h(q, z); if (t > 3) cq_theta(&q2, .2)` with the READING callee (`h(a,k){ g(a); return k+1; }`).
;
; THIS FILE PINS `LaterTaintOracle::walk`'s CLIMB past the φ block's direct predecessors. The merge-φ
; peel (`MergePhiPeel`) replaces `z` by a tainted `select` in a GROWTH drain, so `h(q, z)`'s mask grows
; `01` → `11` and its clone returns a register. The tainted `br` is the ENTRY block's; both of the
; merge's direct predecessors are ARM blocks with unconditional terminators. The round-1 settle step
; therefore taints the site at round 1 only because the climb reaches that `br`. Remove the climb and
; the site stays STICKY, the peel's growth replans its mask to `11`, and `specialize()` declines
; `lifted callee returns a quantum register where propagation predicted a classical result` — a LOUD
; over-decline, never an accept (Rule-13 r2 mutant C1; re-measured in round 3, TRACK §15).
; Round 2's comment at the climb called it "UNPINNED AND, TODAY, UNREACHABLE" (F-r2-1; L7). No C
; spelling is known: `-O1` sinks the arms' common trailing `cq_phi` into the merge (probes `pk1`/`pk2`).
;
; Oracle 9a230646: the same ACCEPT with a BYTE-IDENTICAL stream (so this file is green on the oracle; its
; red is the climb-less mutant, not the oracle).
; Hand-inlined twin (pkdT.s1.ll) ACCEPTS with a different stream: the quantum-returning clone keeps its
; copy-out rail (the compiler-kept copy-out class, bd ffir, owner question), identical on the oracle.
; Regenerate: copy docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/ir/pkdC.s1.ll to the probe dir (r3gen.sh), then mkfix.py.
;
; bd p3kd.21 R11 r2 F1 (bd r2j3.35, 2026-10-15): `main` now MEASURES the value it
; returns. A register returned from `main` reaches the process exit status without
; `cq_measure`, which NORTHSTAR goal 1 forbids and the pass now refuses
; (spec_reject_gate_sub_main_return.ll); the measurement is outside this fixture's
; subject, which is unchanged.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_11(i32 noundef %[[H:[A-Za-z0-9_.]+]], i32 noundef %{{[A-Za-z0-9_.]+}})
; CHECK:       %[[F:[A-Za-z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[T]], i32 3)
; CHECK-NEXT:  call void @cqrt_ry_i32_controlled(i32 %[[F]],
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
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %10 = icmp sgt i32 %9, 5
  br i1 %10, label %armA, label %11

armA:                                             ; preds = %2
  tail call void @cq_phi(double noundef 2.000000e-01) #4
  br label %12

11:                                               ; preds = %2
  tail call void @cq_phi(double noundef 3.000000e-01) #4
  tail call void @cq_phi(double noundef 1.000000e-01) #4
  br label %12

12:                                               ; preds = %11, %armA
  %14 = phi i32 [ %8, %11 ], [ %5, %armA ]
  %15 = phi i32 [ %5, %11 ], [ %8, %armA ]
  %16 = tail call i32 @h(i32 noundef %9, i32 noundef %15) #4
  %17 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 4.000000e-01) #4
  %18 = icmp sgt i32 %16, 3
  br i1 %18, label %19, label %21

19:                                               ; preds = %12
  %20 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 2.000000e-01) #4
  br label %21

21:                                               ; preds = %19, %12
  %22 = phi i32 [ %20, %19 ], [ %17, %12 ]
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #4
  %24 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %25 = add i32 %23, %14
  %26 = add i32 %25, %24
  %cq.main.m = call i32 @cq_measure_si32(i32 %26)
  ret i32 %cq.main.m
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #2

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
