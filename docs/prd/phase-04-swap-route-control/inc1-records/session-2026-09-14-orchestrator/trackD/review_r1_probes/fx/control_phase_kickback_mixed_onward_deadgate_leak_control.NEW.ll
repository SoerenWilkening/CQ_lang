; control_phase_kickback_mixed_onward_deadgate_leak_control.ll — ACCEPT **AND
; LEAKS**, deliberately. bd test_C_libtooling-3qlq Inc 1, the SECOND C-1 review
; round: finding F-C1-2(2a)'s DISCRIMINATING CONTROL, and the reason
; `taint.ClaimedRailRoots` is an explicit RECORD rather than an inference.
;
;     int ext_f(int a);                                  /* separate TU */
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       int y=5; if (q>5) y=ext_f(7);                    /* 6.5 arm -> %out */
;       int t=r; for(int i=0;i<3;i++){ if((y>>i)&1) cq_phi(0.25);
;                                      t=cq_theta(r,0.1); }   /* result UNCARRIED */
;       return cq_measure(t)+cq_measure(y); }
;
; ⚠ `cq_measure(t)`, NOT `cq_measure(r)` — bd test_C_libtooling-3d8q. The body's
; `cq_theta(r,·)` CONSUMES the name `r` (`docs/frontend.md` §3.2's linear rule),
; so the original `cq_measure(r)` named the PRE-LOOP record of a rail the loop had
; already rotated three times — CLAUDE.md's own 8h7d.5 F-3 shape, out of loop, and
; a member of the P1 stale-reader class. It declines since
; `recordStaleQuantumReaders` landed. ⚠ WHAT THIS FILE PINS IS UNTOUCHED, which
; is why the edit is one operand and not a conversion: `%20` is the LAST TRIP's
; own result, the gate's arg-0 is STILL the loop-invariant `%3` so there is still
; NO loop-carried header φ for `r`, the rail is still unclaimed, and the emitted
; stream is BYTE-IDENTICAL — all five prefixes below are the lines they always
; were, counts included. ⚠ It is NOT the sibling: `..._inloop.ll` CARRIES the
; result (`r = cq_theta(r,0.1)`, a header φ) and discharges. Uncarried-but-read is
; a third point, and it lowers exactly like the dead one.
;
; WHAT THIS PINS. The body gates `r` in place K times, and because the result is
; DEAD there is NO loop-carried header phi for it — so no collapse ever claimed
; that rail and nothing proved its self-cycle, its fan-out or its record
; liveness. The tempting shortcut for F-C1-2(2a) is "the header carries no
; tainted phi, therefore the collapse must already own this candidate"; that
; inference is FALSE here, and taking it would grant `markIfRailLocal` a
; permission on an unproven rail whose gate multiplicity nothing has checked.
; `taint.ClaimedRailRoots` is written ONLY where a Case-A collapse really claimed
; a rail, so `%r`'s root is absent, clause (iii) refuses on the in-body
; `cq_theta(%r,.1)`, and the extension declines — the per-trip bit rails keep
; leaking. That leak is the Prime-Directive disposition (Rule 6: left allocated,
; never freed dirty), and this file's job is to prove the F-C1-2 widening did not
; reach it.
;
; MEASURED IDENTICAL on 542d588, on the round-1 C-1 fix and on this HEAD: rolled
; `cq_template_and_i32_hl` 3 / `_unc` **0**, `opt` exit 0, STRICT stage 2b clean,
; and the rolled trace BYTE-UNCHANGED across all three binaries. Its sibling
; `control_phase_kickback_mixed_onward_inloop.ll` is the SAME program with the
; result LIVE (`r = cq_theta(r,0.1)`), and it discharges — one token apart,
; opposite dispositions.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The two root mints and the 6.5 arm's `%out`.
; CHECK: %[[Q:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)

; The rolled body: the bit rail is minted and the flag stripped and freed, but
; the `and` is NEVER discharged — the leak this file pins. The in-place gate on
; the unclaimed rail `%[[R]]` still runs once per trip.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)

; ⭐ ZERO `and` discharges — the unclaimed-rail refusal, unchanged by F-C1-2.
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; TWO frees: the 6.5 arm's own flag, and the body's kickback flag. NOT the bit
; rail (that is the leak).
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; FOUR `cqrt_x`: the 6.5 arm's two-arm bracket and the kickback's ¬flag bracket.
; (Added by the injection matrix: without this prefix the `extra_x` mutation was
; caught by NO block.)
; XCNT-COUNT-4: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

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
  br label %13

9:                                                ; preds = %19
  %10 = tail call i32 @cq_measure_si32(i32 noundef %20) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %12 = add nsw i32 %11, %10
  ret i32 %12

13:                                               ; preds = %19, %7
  %14 = phi i32 [ 0, %7 ], [ %21, %19 ]
  %15 = shl nuw nsw i32 1, %14
  %16 = and i32 %15, %8
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %19, label %18

18:                                               ; preds = %13
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  br label %19

19:                                               ; preds = %18, %13
  %20 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.000000e-01) #3
  %21 = add nuw nsw i32 %14, 1
  %22 = icmp eq i32 %21, 3
  br i1 %22, label %9, label %13, !llvm.loop !6
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
