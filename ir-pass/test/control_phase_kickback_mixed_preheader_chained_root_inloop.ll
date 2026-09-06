; control_phase_kickback_mixed_preheader_chained_root_inloop.ll — ACCEPT. bd
; test_C_libtooling-3qlq Inc 1, the THIRD C-1 review round — **THE
; DISCRIMINATOR** for finding F-C1C-1's (1b) tripwire, and the F-C1-1 capability
; carried through a CHAINED root mint.
;
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       int q2=cq_theta(q,0.3);
;       int a = q2 + 7;
;       for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
;       return cq_measure(r)+cq_measure(a); }     /* NO read of the PRE-op name */
;
; This is `control_phase_kickback_reject_preloop_commit_stale.ll` MINUS ONE TOKEN
; (`cq_measure(q)+`), and the two dispositions are opposite. Here the whole theta
; chain's post-RAUW handle has no later reader other than the in-place gate
; itself, M-C's G6/G7 still hold at `lowerOps`, the re-verification passes, and
; the loop keeps the round-2 capability: the preheader `add` is `cqrt_addc_i32`
; ON THE ROOT MINT'S RAIL, so `invariantRegisterRoots` clause (ii)'s (I1) argument
; applies and the per-trip bit rail is discharged EVERY iteration.
;
; It exists because a tripwire that fires on every program is not a fence, it is a
; blanket decline. MEASURED: 38 trace lines, 3 mints / 3 `_unc`, BYTE-IDENTICAL on
; the round-2 binary and here.
;
; ⭐ It also pins the CLAUSE (ii) PEEL through a chained root: the body reads a
; register two `cq_theta` hops and one in-place `add` away from its mint, and all
; three RAUW to the ONE `cqrt_alloc` handle.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; ONE alloc for the whole `q`/`q2` chain, TWO `cqrt_ry` on it, then the in-place
; preheader gate on that same handle.
; CHECK: %[[Q:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[Q]], i32 7)

; The rolled body, in full — including the per-iteration DISCHARGE of the bit rail.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %[[Q]], i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ⭐ EXACTLY ONE discharge, in the rolled body.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ⭐ EXACTLY ONE in-place gate, and no out-of-place rail for it.
; PCNT-COUNT-1: call void @cqrt_addc_i32(
; PCNT-NOT: call void @cqrt_addc_i32(
; PCNT-NOT: call i32 @cq_template_add_i32_hl(

; Two frees, both in the body.
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; WHOLE-FILE PURE-NEGATIVE — including the (1b) diagnostic, which must NOT fire.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: no longer provable at lowering
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(

; ModuleID = 'p/y2_preadd_chained_nopreread.c'
source_filename = "p/y2_preadd_chained_nopreread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #2
  %5 = add nsw i32 %4, 7
  br label %10

6:                                                ; preds = %17
  %7 = tail call i32 @cq_measure_si32(i32 noundef %18) #2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5) #2
  %9 = add nsw i32 %8, %7
  ret i32 %9

10:                                               ; preds = %1, %17
  %11 = phi i32 [ 0, %1 ], [ %19, %17 ]
  %12 = phi i32 [ %3, %1 ], [ %18, %17 ]
  %13 = shl nuw nsw i32 1, %11
  %14 = and i32 %13, %5
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %17, label %16

16:                                               ; preds = %10
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %17

17:                                               ; preds = %16, %10
  %18 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 1.000000e-01) #2
  %19 = add nuw nsw i32 %11, 1
  %20 = icmp eq i32 %19, 3
  br i1 %20, label %6, label %10, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable

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
