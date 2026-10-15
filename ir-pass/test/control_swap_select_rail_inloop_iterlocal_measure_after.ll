; control_swap_select_rail_inloop_iterlocal_measure_after.ll — ACCEPT, and a
; DECLINE → ACCEPT MOVER ON `main` 0c7380c (Track A.1, Rule-13 round-1 finding
; F-A1-2). The 4.4 DATA SELECT twin of
; `control_phase_kickback_rail_inloop_iterlocal_measure_after.ll`; verbatim
; `clang -O1` from `review_a1_r1_probes/b2.c`:
;
;     for (int i = 0; i < 3; ++i) {
;         _Bool b = (_Bool)0; cq_theta(&b, 0.5);
;         int a = b ? i : 5;                  /* the 1b-B.1 rail-root select */
;         acc += cq_measure(a) + cq_measure(b);
;     }
;
; MEASURED: `main` 0c7380c DECLINES it `condition measured before the control
; route`; this branch ACCEPTS. Read the two files together — one consumer per
; ladder rung, same barrier, same ground.

; ⚠ WHY THE ACCEPT IS RIGHT, CHECKED PHYSICALLY AND NOT ASSUMED. The register is
; ITERATION-LOCAL: `cqrt_alloc_i1` is emitted INSIDE the loop body (asserted
; below), so every trip mints a FRESH physical register, and the body's
; `cq_measure` collapses the register THIS trip minted — never the one the NEXT
; trip's control read names. `isPotentiallyReachable(M, ReadPoint)` alone answers
; "can the read follow the measure?" with TRUE around any back edge, which is the
; WRONG question inside a loop; the right one is "can it follow it ON THE SAME
; REGISTER?", and the barrier is what asks it. Without the barrier five shipped
; accepts move (`control_swap_inloop_diamond_iterlocal.ll`, `…_seq`, and the
; three `…_reject_inloop_{irreducible,multilatch,second_cycle}` declines, which
; would keep declining on the WRONG rung — a DIAGDIFF).
;
; THE BARRIER IS THE WIRE ORIGIN AND ONLY WHEN IT IS A SOURCE THETA
; (`railMeasuredBeforeReadPoint`, ArmClassify.cpp): a source theta lowers to a
; fresh `cqrt_alloc_<W>` + `cqrt_ry_<W>` on EVERY execution, so a measurement
; followed by a re-execution of the origin on EVERY path back to the read point
; collapsed a register this read can no longer name. A CHAINED theta refreshes
; nothing (an in-place Ry) and a non-theta origin is refused too; a MISSING
; barrier DECLINES. Its round-2 blind spot — a `cq_theta` that is a SOURCE at
; round-1 taint and CHAINED at final taint — is closed by the UNGATED rung (ii)
; in `reverifyCmpCondReads` (reviewer probe `o7a`, ACCEPT on `main` and DECLINE
; here).

; The arm is loop-VARIANT (`i`), which is what keeps the select INSIDE the body;
; the constant-arm spelling is LICM-hoisted and is a different program (the
; compare pair `control_swap_reject_select_cmp_inloop_measure_after{,_constarm}.ll`
; records that distinction).

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=ACNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=FCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=XCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NOROUTE %s < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  br label %2

1:                                                ; preds = %2
  ret i32 %11

2:                                                ; preds = %0, %2
  %3 = phi i32 [ 0, %0 ], [ %11, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %12, %2 ]
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %6 = select i1 %5, i32 %4, i32 5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2
  %9 = zext i1 %8 to i32
  %10 = add i32 %7, %3
  %11 = add i32 %10, %9
  %12 = add nuw nsw i32 %4, 1
  %13 = icmp eq i32 %12, 3
  br i1 %13, label %1, label %2, !llvm.loop !6
}

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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}

; THE MINT IS IN THE BODY, and the flag is the 1b-B.1 CNOT COPY of the rail onto
; a fresh ancilla — never a `cqrt_x` on the user register.
; CHECK-LABEL: 2:
; CHECK:      %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK-NEXT: %bf = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %h, i32 %bf)
; CHECK:      call void @cqrt_xorc_i32_controlled(i32 %bf, i32 %out, i32 %{{[0-9]+}})
; CHECK:      call void @cqrt_cnot(i32 %h, i32 %bf)
; CHECK-NEXT: call void @cqrt_free(i32 %bf)
; CHECK-NEXT: %m = call i32 @cqrt_measure_i32(i32 %out)
; CHECK-NEXT: %{{m[0-9]*}} = call i1 @cqrt_measure_i1(i32 %h)

; Per-activation counts (the loop is ROLLED): two i1 mints (the rail and the
; flag ancilla), one i32 mint (the out rail; bd dm7f.81: the arms are literals), two
; measurements, ONE free — the ancilla's, proven |0> by the second CNOT.
; ACNT-COUNT-2: call i32 @cqrt_alloc_i1(
; ACNT-NOT:     call i32 @cqrt_alloc_i1(
; MCNT-COUNT-1: call i32 @cqrt_measure_i32(
; MCNT-COUNT-1: call i1 @cqrt_measure_i1(
; MCNT-NOT:     call {{i1|i32}} @cqrt_measure
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; The two X-brackets are on the ANCILLA `%bf`, never on `%h`.
; XCNT-COUNT-2: call void @cqrt_x(i32 %bf)
; XCNT-NOT:     call void @cqrt_x(
; NOROUTE-NOT:  @cqrt_cswap
; NOROUTE-NOT:  call i32 @cq_theta
; NOROUTE-NOT:  call void @cq_phi
