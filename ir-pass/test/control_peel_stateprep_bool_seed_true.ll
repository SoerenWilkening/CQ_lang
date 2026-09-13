; control_peel_stateprep_bool_seed_true.ll — ACCEPT. THE OTHER EDGE of the bd
; `rb9x` collision (`trackR/probes/b_P2t_seed_true_peeled.c`).
;
;     int  b0 = 0;
;     bool b1 = 1;                 ; <- the ONLY difference from
;     int  a  = 5;                 ;    control_peel_stateprep_bool_seed_int_cond.ll
;     b0 = cq_theta(b0, 0.5);
;     if (b0 == 1) { b1 = cq_theta(b1, 0.5); a = 2; }
;     return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
;
; ⚠ WHY BOTH SEEDS NEEDED A FIXTURE, AND WHY ONE WOULD HAVE BEEN A HALF-TEST.
; The peel's clone is the SAME compare as the region's condition, so LVI pins it
; to `{true}` on one edge of the branch and to `{false}` on the other — and F2
; asks BOTH edges (`for (unsigned E = 0; E < BI->getNumSuccessors(); ++E)`).
; So an `i1` seed collides whichever constant it is: `false` matches the false
; edge's fold, `true` matches the true edge's. MEASURED on the ORACLE
; `fbbe0820ef4b176a`: `b_P2` and `b_P2t` BOTH decline, and they decline through
; DIFFERENT edges of the same loop. A fixture for only one seed would leave the
; other edge unpinned, and a future narrowing that got the polarity backwards
; would go green on it.
;
; The admissibility argument, the record spelling and the retirement triggers are
; in `control_peel_stateprep_bool_seed_int_cond.ll`'s header and in
; `TaintSet::PeelClones`; this file adds only the second edge. The emitted stream
; is byte-identical to that fixture's except for the prepared rail's seed
; (`cqrt_alloc_i1(i1 true)`), which is the whole point: the SEED changes, the
; CIRCUIT SHAPE does not.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT  < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 5.000000e-01) #2
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ true, %0 ]
  %7 = phi i32 [ 2, %3 ], [ 5, %0 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2
  %10 = zext i1 %9 to i32
  %11 = add nsw i32 %8, %10
  %12 = tail call i32 @cq_measure_si32(i32 noundef %7) #2
  %13 = add nsw i32 %11, %12
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}

; THE WHOLE STREAM, IN ORDER. Region 1 (the state prep) fires on the TRUE
; successor, so there is NO `cqrt_x` bracket on its flag; the peeled `a` mux is
; the ordinary 4.4 controlled-copy merge and brings its own X-bracketed pair.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 true)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F1]], i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[S1]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[S2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: %[[M0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

; ------------------------------------------------------------------
; NEGATIVES — WHOLE-FILE AND PURE (no positive directive inside a negative
; prefix: a positive `-COUNT-n` WINDOWS every negative after it, the drbq Inc-4
; round-1 lesson).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = select
; NOROUTE-NOT: cq.peel
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi
; NOROUTE-NOT: = icmp
; THE FREEZE (Rule 6): no `cqrt_free` may ever name the PREPPED `i1` rail — a
; controlled `Ry(0.5)|0> != |0>`, so it is LEFT ALLOCATED and measured.
; NOROUTE-NOT: call void @cqrt_free(i32 %h3)
; …and the arm gate must not become UNCONDITIONAL (that would fire the prep on
; both branches — the verify-clean wrong unitary this whole family guards).
; NOROUTE-NOT: call void @cqrt_ry_i1(i32 %h3, double 5.000000e-01)
; …nor may the merge out-rail be freed dirty.
; NOROUTE-NOT: call void @cqrt_free(i32 %out)

; ACNT-COUNT-5: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_i1_controlled(
; CCNT-NOT:     call void @cqrt_ry_i1_controlled(
; CPCNT-COUNT-2: call void @cqrt_copy_
; CPCNT-NOT:     call void @cqrt_copy_
; UCNT-COUNT-2: call void @cq_template_icmp_eq_i32_hl_unc(
; UCNT-NOT:     call void @cq_template_icmp_eq_i32_hl_unc(
