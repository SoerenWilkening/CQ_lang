; control_phase_kickback_mixed_preheader_volatile_imm_leak_control.ll —
; ACCEPT-AND-LEAKS. bd test_C_libtooling-3qlq Inc 1, the THIRD C-1 review round —
; **THE MEASURED COST OF F-C1B-1's FIX (1a), pinned rather than left to prose.**
;
;     static volatile int off = 7;
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       q = q + off;                                   /* a VOLATILE-LOAD immediate */
;       for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
;       q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
;
; The (1a) fence is `isa<Constant>(Imm)` at the commit, whose whole argument is
; that a `Constant` can NEVER become tainted between `lowerLoops` and `lowerOps`.
; A volatile load is not a `Constant`, so this program — a NEW accept that the
; SECOND C-1 round introduced (3 `cq_template_and_i32_hl` mints / 3 `_unc`) —
; returns to the pre-round-2 leak (3 mints / **0** `_unc`, 32 trace lines,
; BYTE-IDENTICAL to 542d588 AND to the round-1 fix, MEASURED).
;
; ⚠ M-C ITSELF STILL LOWERS THE OP IN PLACE at `lowerOps` (`cqrt_addc_i32(%h,
; %off)` below): the immediate is stage-2b-provable (census 0.5 cleared a volatile
; load explicitly, and `slice_control_seq_grover`'s own `off` is this shape). What
; the fence refuses is the PREDICTION of that answer from a program point before
; the round-2 taint fixpoint — not the answer. So the register the body reads IS
; the root mint's rail and the discharge would be SOUND; it is simply no longer
; PROVEN at the point the proof is needed, and Rule 6's direction is to leak.
;
; This is the Prime-Directive direction and it is recorded in PRD §0 E2 and notes
; §3.11 as a cost, not a defect. Buying it back means the commit asking a question
; about the immediate that survives a taint change — an owner question, not a
; review round's call (notes §3.11, OQ-C1-8).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll

; The root mint, the volatile load, and M-C's OWN in-place gate on it.
; CHECK: %[[Q:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK: %[[OFF:.*]] = load volatile i32, ptr @{{.*}}
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[Q]], i32 %[[OFF]])

; The rolled body: the bit rail is minted, the flag minted / bracketed / kicked /
; stripped / freed — and the BIT RAIL IS NOT DISCHARGED. That is the leak.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ⭐ THE ASSERTION: ZERO `and` discharges. It was ONE on the round-2 binary.
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ⭐ AND EXACTLY ONE free in the body — the flag's. The bit rail is left allocated
; (Rule 6's safe direction), never freed dirty.
; PCNT-COUNT-1: call void @cqrt_free(
; PCNT-NOT: call void @cqrt_free(

; Exactly ONE kickback gate in the module (the rolled body's).
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; `#cqrt_rz_i1 == #!cq.branchphase` — an unmarked kickback gate is one the
; uncompute spine would adjoint, cancelling the user's phase exactly (F-L7-1).
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; The `cqrt_x` census: the kickback's polarity bracket(s) and the arm brackets.
; An UNPAIRED one is a wrong-branch phase.
; XCNT-COUNT-2: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; bd 3qlq, the FOURTH C-1 round, lens finding F-C1D-4: the Ry budget.
; NOTHING may add an uncontrolled `cqrt_ry` on a register under quantum
; control — a non-diagonal gate there is a different unitary, and before this
; prefix an injected one was caught by 0 of this file's prefixes.
; RYCNT-COUNT-4: call void @cqrt_ry_
; RYCNT-NOT: call void @cqrt_ry_

; WHOLE-FILE PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(

; ModuleID = 'p/z21_preadd_volatile_imm.c'
source_filename = "p/z21_preadd_volatile_imm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@off = global i32 7, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  %4 = load volatile i32, ptr @off, align 4, !tbaa !6
  %5 = add nsw i32 %4, %2
  br label %11

6:                                                ; preds = %18
  %7 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 9.000000e-01) #2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2
  %9 = tail call i32 @cq_measure_si32(i32 noundef %19) #2
  %10 = add nsw i32 %9, %8
  ret i32 %10

11:                                               ; preds = %1, %18
  %12 = phi i32 [ 0, %1 ], [ %20, %18 ]
  %13 = phi i32 [ %3, %1 ], [ %19, %18 ]
  %14 = shl nuw nsw i32 1, %12
  %15 = and i32 %14, %5
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %18, label %17

17:                                               ; preds = %11
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %18

18:                                               ; preds = %17, %11
  %19 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 1.000000e-01) #2
  %20 = add nuw nsw i32 %12, 1
  %21 = icmp eq i32 %20, 3
  br i1 %21, label %6, label %11, !llvm.loop !10
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
