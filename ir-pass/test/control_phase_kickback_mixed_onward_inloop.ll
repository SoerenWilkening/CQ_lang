; control_phase_kickback_mixed_onward_inloop.ll — ACCEPT. bd
; test_C_libtooling-3qlq Inc 1, the SECOND C-1 review round, finding
; **F-C1-2(2a)** (CONFIRMED MISCOMPILE, twin witness). THE MIXED **ONWARD** LOOP:
; the kickback's condition register is a 6.5 classical-call-arm `%out` rail — a
; region no stage sees until ROUND 2 — and the SAME loop also CARRIES a second
; tainted register.
;
;     int ext_f(int a);                                  /* separate TU */
;     int slice(int u){ int q=u; cq_theta(&q,0.5); int r=u; cq_theta(&r,0.3);
;       int y=5; if (q>5) y=ext_f(7);                    /* 6.5 arm -> %out */
;       for(int i=0;i<3;i++){ if((y>>i)&1) cq_phi(0.25); cq_theta(&r,0.1); }
;       cq_theta(&y,0.9);                               /* the diffusion */
;       return cq_measure(r)+cq_measure(y); }
;
; `clang -O1` on that source, `llvm-link`ed with `int ext_f(int a){return a+100;}`,
; `@main` dropped. `!llvm.loop` kept VERBATIM — a genuine ROLLED loop.
;
; WHY `control_phase_kickback_onward_inloop.ll` (round 2's F-R1-1 fixture) DOES
; NOT COVER THIS, and why `n8` — the round-1 C-1 fix's own onward probe — escaped:
; both of those reach the round-2 collapse on the `Collapsed` branch, where the
; carried root is in the LOCAL `Roots` the caller just filled. Here the loop's
; in-body control is CLASSICAL at round 1 (`%out` does not exist yet), so ROUND-1
; `lowerLoops`/`tryCaseA` claims and collapses the carried rail ITSELF; by the
; round-2 pass there is no tainted header phi left, `collapseRailPhisIn` returns
; `NotClaimed`, and the local set is EMPTY. Clause (iii) then refused on the
; carried root's in-body `cq_theta(%r,.1)` and took the INVARIANT register's
; discharge down with it. `n8` escapes only because it ALSO carries a ROUND-1
; per-bit region on `q`, which is what puts it on the `Collapsed` path; delete
; that one line and the same program leaks.
;
; MEASURED on 542d588 AND on the round-1 C-1 fix (`opt` exit 0, verify-clean,
; STRICT stage 2b `0 violation(s)`): THREE `cq_template_and_i32_hl` mints and
; **ZERO** `_unc` discharges, against a hand-unrolled twin at 3/3 — the `diff` of
; the two traces is EXACTLY the three inserted `_unc` + `cqrt_free` pairs. The
; trace ended `cqrt_ry_i32(%out, 0.9)` with three live which-path records of
; `%out`'s bits: rolled and unrolled are DIFFERENT UNITARIES.
;
; THE FIX. "This candidate is a rail a Case-A collapse already proved" now comes
; from the TREE (`taint.ClaimedRailRoots`, written at BOTH collapse sites) rather
; than from the caller's local set, and clause (0) reads the UNION — and skips the
; candidate **INTO** `RootsOut`, because `markIfRailLocal`'s own "accumulating
; loop-invariant tainted input" clause needs the claimed rail in `Roots` to answer
; `onRail`. (Widening the skip and not the roots left the extension returning TRUE
; with nothing marked — the 8h7d.5 lesson inside this very edit.)
;
; WITNESS — the trace is now BYTE-IDENTICAL to the hand-unrolled twin's, pinned at
; the e2e layer by `e2e-phase-onward-perbit-loop-mixed-twin-identical`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The CONDITION-SOURCE register `q` and the CARRIED register `r`, in source
; order, then the 6.5 classical-call arm minting `%out` off `q`.
; CHECK: %[[Q:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(

; The post-loop diffusion on `%out` and both measures.
; CHECK: call void @cqrt_ry_i32(i32 %[[OUT]], double 9.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[OUT]])

; THE ROLLED BODY, in full and in order — LIFO per trip, and then the CARRIED
; register's own per-trip gate (the line whose presence made round 1 refuse).
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)

; ⭐ THE ASSERTION F-C1-2 IS ABOUT: exactly ONE `and` discharge in the rolled body.
; ZERO at 542d588 and at the round-1 fix.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ONE kickback gate in the body — the 6.5 arm emits none.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; THREE frees: the 6.5 arm's own flag, plus the body's bit rail and flag.
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; FOUR `cqrt_x`: the 6.5 arm's two-arm bracket, and the kickback's ¬flag bracket.
; XCNT-COUNT-4: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: fneg

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  %4 = icmp sgt i32 %2, 5
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %7

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ 5, %1 ]
  br label %14

9:                                                ; preds = %21
  %10 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 9.000000e-01) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %22) #3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %13 = add nsw i32 %12, %11
  ret i32 %13

14:                                               ; preds = %21, %7
  %15 = phi i32 [ 0, %7 ], [ %23, %21 ]
  %16 = phi i32 [ %3, %7 ], [ %22, %21 ]
  %17 = shl nuw nsw i32 1, %15
  %18 = and i32 %17, %8
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %21, label %20

20:                                               ; preds = %14
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  br label %21

21:                                               ; preds = %20, %14
  %22 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 1.000000e-01) #3
  %23 = add nuw nsw i32 %15, 1
  %24 = icmp eq i32 %23, 3
  br i1 %24, label %9, label %14, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1


; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
