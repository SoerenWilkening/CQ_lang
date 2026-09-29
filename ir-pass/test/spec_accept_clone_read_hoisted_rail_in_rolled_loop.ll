; spec_accept_clone_read_hoisted_rail_in_rolled_loop.ll — ACCEPT, the hoisted rail
; DISCHARGED AT THE LOOP EXIT (bd rhk5; Rule-13 round-2 r2A F-r2A-2, probe `l2i`,
; stage-1 IR below copied VERBATIM from
; review_r2A_rhk5/probes/src/l2i.s1.ll — the 2-TU C program llvm-linked). The C:
;
;     q = cq_theta(m, .5); r = cq_theta(m, .3); p = q * 3;
;     for (i = 0; i < 3; i++) {
;       if ((p >> i) & 1) cq_phi(.2);
;       r = cq_theta(r, .1);
;       t += cq_measure(h(m + i, p));   // h(a, k) = k + 1, another TU → a Phase-6 clone
;     }
;     q = cq_theta(q, .9);
;
; `p` is a LICM-hoisted template rail read by the rolled body's condition — the bd
; tu9q (ii-d) grant, whose licence is verified EX POST by the postcondition
; `declineUndischargedExitObligations`. The body ALSO passes `p` to a clone call.
;
; ORACLE (main 9a230646): DECLINES `cq loop lowering: hoisted invariant rail admitted
; for in-loop discharge was not discharged` — the clone consumer kept `p` out of the
; interior partition, so the exit discharge (ii-d) was granted for never happened and
; the postcondition caught it.
; bd rhk5 (round 1 and round 2): ACCEPTS — clause (b′) admits the read-only clone call
; as an interior consumer, and `p` is `_unc`'d and freed ONCE at the loop exit, BEFORE
; the trailing `cqrt_ry_i32(q, .9)`. The postcondition is SATISFIED, not bypassed
; (r2A checked it). Measured by r2A: the rolled program is `trace_twin_equiv` EQUIV to
; its hand-unrolled twin that keeps the clone (`l2iV.c`), warn 0, 2b STRICT 0 dirty.
;
; ⚠ WHAT THIS FILE RECORDS: bd rhk5 moves a tu9q POSTCONDITION decline to an accept.
; No module in the round-2 corpus A/B was of this class — the "0 D→A" there covered
; the SWEPT corpus only; this D→A mover was found outside it, by r2A.
;
; RED on the oracle (a decline: exit 1, empty stdout), GREEN on rhk5 rounds 1 and 2.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=EXIT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=BODY < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ONCE < %t.cqd0.ll

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #5
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #5
  %4 = mul nsw i32 %2, 3
  br label %11

5:                                                ; preds = %19
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %20) #5
  %9 = add i32 %7, %24
  %10 = add i32 %9, %8
  ret i32 %10

11:                                               ; preds = %19, %1
  %12 = phi i32 [ 0, %1 ], [ %25, %19 ]
  %13 = phi i32 [ 0, %1 ], [ %24, %19 ]
  %14 = phi i32 [ %3, %1 ], [ %20, %19 ]
  %15 = shl nuw nsw i32 1, %12
  %16 = and i32 %15, %4
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %19, label %18

18:                                               ; preds = %11
  tail call void @cq_phi(double noundef 2.000000e-01) #5
  br label %19

19:                                               ; preds = %18, %11
  %20 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 1.000000e-01) #5
  %21 = add nsw i32 %12, %0
  %22 = tail call i32 @h(i32 noundef %21, i32 noundef %4) #5
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #5
  %24 = add nsw i32 %23, %13
  %25 = add nuw nsw i32 %12, 1
  %26 = icmp eq i32 %25, 3
  br i1 %26, label %5, label %11, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !9
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @slice(i32 noundef %5)
  %7 = and i32 %6, 1
  ret i32 %7
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = !{!10, !10, i64 0}
!10 = !{!"any pointer", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}

; SILENT-NOT: warning
; SILENT-NOT: error
;
; The EXIT block: `p`'s discharge, then the trailing Ry on `q`.
; EXIT-LABEL: define i32 @slice(
; EXIT: %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
; EXIT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; EXIT-NEXT: call void @cqrt_free(i32 %h_op)
; EXIT-NEXT: call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)
;
; The rolled BODY reads `p` (the per-bit rail and the clone call) and never discharges
; it: no `mul_unc` between the clone call and the back edge.
; BODY-LABEL: define i32 @slice(
; BODY: call i32 @cq_template_and_i32_hl(i32 %h_op,
; BODY: call void @cq_template_and_i32_hl_unc(i32 %h_op2, i32 %h_op,
; BODY: call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op)
; BODY-NOT: call void @cq_template_mul_i32_hl_unc(
; BODY: br i1 %{{[0-9]+}}, label %{{[0-9]+}}, label %{{[0-9]+}}, !llvm.loop
;
; Exactly ONE discharge of `p` in the whole module (a whole-file count, its own prefix).
; ONCE-COUNT-1: call void @cq_template_mul_i32_hl_unc(
; ONCE-NOT: call void @cq_template_mul_i32_hl_unc(
