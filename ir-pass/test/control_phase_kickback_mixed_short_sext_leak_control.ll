; control_phase_kickback_mixed_short_sext_leak_control.ll — ACCEPT **AND LEAKS**,
; deliberately. bd test_C_libtooling-3qlq Inc 1, the SECOND C-1 review round,
; finding **F-C1-3**: the Q-R1-1 template-rail class reached by a TYPE the user
; wrote, not by a cast the user wrote.
;
;     int slice(short u){ short q=cq_theta(u,0.5); short r=cq_theta(u,0.3);
;       for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
;       q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
;
; That is `control_phase_kickback_mixed_invariant_carried_inloop.ll`'s source with
; `int` changed to `short` and nothing else. `clang -O1` HOISTS a
; `sext i16 %q to i32` into the loop's preheader (the shift is done at `int`), so
; the per-bit condition reads `cq_template_sext_i16_to_i32(%h)` — a loop-invariant
; TEMPLATE rail — and `invariantRegisterRoots` clause (ii) refuses it: a template
; rail is exactly what `ChainWalk::isInteriorTerminalHandle` clause (I1) ADMITS, so
; the multiplicity argument that licenses a root mint does not carry. The per-trip
; `and` rails are therefore NOT discharged.
;
; WHY IT IS COMMITTED. PRD §0 E2's disclosure of the Q-R1-1 residual reads as a
; list of things the SOURCE spells — "a cast, a Q+Q op, an onward `mul`" — and a
; reader will not expect `short` to be one of them. It is: no cast appears in the
; program at all. MEASURED IDENTICAL on 542d588, on the round-1 C-1 fix and on this
; HEAD — rolled `cq_template_and_i32_hl` 3 / `_unc` **0** against a hand-unrolled
; twin at 3/3, rolled trace BYTE-UNCHANGED across all three binaries — so this file
; also pins that NEITHER C-1 widening reached the class. The leak is the
; Prime-Directive disposition until Q-R1-1 is ruled (Rule 6: left allocated, never
; freed dirty).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The two `i16` root mints, then ⭐ the HOISTED `sext` TEMPLATE rail the body's
; condition reads. Nothing in the source asked for that cast.
; CHECK: %[[Q:.*]] = call i32 @cqrt_alloc_i16(
; CHECK-NEXT: call void @cqrt_ry_i16(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = call i32 @cqrt_alloc_i16(
; CHECK-NEXT: call void @cqrt_ry_i16(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[P:.*]] = call i32 @cq_template_sext_i16_to_i32(i32 %[[Q]])

; The rolled body: the bit rail is minted off the TEMPLATE rail, the flag is
; stripped and freed, and the `and` is NEVER discharged. That missing line is what
; this file pins.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[P]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i16(i32 %[[R]], double 1.000000e-01)

; ⭐ ZERO `and` discharges — the Q-R1-1 leak, unreached by either C-1 widening.
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ONE free in the body: the flag alone (the bit rail and the `sext` rail are the leak).
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; XCNT-COUNT-2: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: fneg

; ModuleID = 'p/r5_short_inv.c'
source_filename = "p/r5_short_inv.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 -65536, 65535) i32 @slice(i16 noundef signext %0) local_unnamed_addr #0 {
  %2 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef 5.000000e-01) #2
  %3 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef 3.000000e-01) #2
  %4 = sext i16 %2 to i32
  br label %12

5:                                                ; preds = %19
  %6 = tail call signext i16 @cq_theta_si16(i16 noundef signext %2, double noundef 9.000000e-01) #2
  %7 = tail call signext i16 @cq_measure_si16(i16 noundef signext %6) #2
  %8 = sext i16 %7 to i32
  %9 = tail call signext i16 @cq_measure_si16(i16 noundef signext %20) #2
  %10 = sext i16 %9 to i32
  %11 = add nsw i32 %10, %8
  ret i32 %11

12:                                               ; preds = %1, %19
  %13 = phi i32 [ 0, %1 ], [ %21, %19 ]
  %14 = phi i16 [ %3, %1 ], [ %20, %19 ]
  %15 = shl nuw nsw i32 1, %13
  %16 = and i32 %15, %4
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %19, label %18

18:                                               ; preds = %12
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %19

19:                                               ; preds = %18, %12
  %20 = tail call signext i16 @cq_theta_si16(i16 noundef signext %14, double noundef 1.000000e-01) #2
  %21 = add nuw nsw i32 %13, 1
  %22 = icmp eq i32 %21, 3
  br i1 %22, label %5, label %12, !llvm.loop !6
}

declare signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #1


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
