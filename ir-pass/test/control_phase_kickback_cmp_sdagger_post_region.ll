; control_phase_kickback_cmp_sdagger_post_region.ll — ACCEPT, and THE FIXTURE
; THAT KEEPS THE F-A1-1 FIX A DISCRIMINATOR RATHER THAN A BLANKET REFUSAL
; (Track A.1, Rule-13 round-1 finding F-A1-1).
;
; `control_phase_kickback_reject_cmp_round2_sibling_theta_sdagger.ll` MINUS the
; round-2 sibling `int b3 = y; cq_theta(&b3, 0.9);` — so the ONLY non-diagonal gate on
; the condition wire is the POST-REGION S-DAGGER `int b2 = b; cq_theta(&b2, -0.25);`,
; which `condWireDisposition`'s DT prong proves is after every execution of the
; branch and therefore ACCEPTS. That is the shipped S-dagger shape the owner's
; Grover cascade writes, and it must keep lowering. Two TUs through the shipped
; 6.5 recipe, from `session-9pum/probes/k10_caller.c` + `review_a1_r1_probes/lib3.c`:
;
;     int q = 3; cq_theta(&q, 0.5);
;     int y = 5; if (q > 5) y = ext_f(7);      /* 6.5 classical-call arm -> %out */
;     int z = 0; if (opaque()) z = ext(1);
;     int b  = y; cq_theta(&b, 0.25);
;     if (b > 1) cq_phi(0.3);
;     int b2 = b; cq_theta(&b2, -0.25);        /* the S-DAGGER, post-region      */
;     return cq_measure(b2) + z;
;
; MEASURED ACCEPT on `main` 0c7380c, on the pre-fix Track-A.1 build, and here —
; byte-identical stream in all three. It pins that the S-dagger capability
; SURVIVES the F-A1-1 change: this is the shape the fix could most easily have
; broken, since the whole fix is about not exempting a gate the classifier ruled
; on. ⚠ Do NOT read it as "the alternative spelling would decline this": with the
; suppression simply DELETED, `%18` would reach the POSITION-AWARE prong and, in
; an acyclic function, be proven harmless there, so this program would still
; accept. What "re-ask about every gate" costs is the twelve shipped IN-LOOP
; accepts, where the round-2 rail collapse has erased the loop-header phi that
; `gateIsHarmless`' barrier needs (IMPL_A1.md §5). This file's own counterfactual
; is a spelling that declines at the POSITION-FREE stage, or an exempt set that
; grows back into a per-entry suppression.
;
; The flag is minted from `Ry(.25)|y>`, which is exactly what `if (b > 1)` names:
; the S-dagger runs after the free of the flag rail.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=RYCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=RZCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=FCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=XCNT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NOROUTE %s < %t.cqd0.ll

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %2 = icmp sgt i32 %1, 5
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %5

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 5, %0 ]
  %7 = tail call i32 @opaque() #3
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %11, label %9

9:                                                ; preds = %5
  %10 = tail call i32 @ext(i32 noundef 1) #3
  br label %11

11:                                               ; preds = %9, %5
  %12 = phi i32 [ %10, %9 ], [ 0, %5 ]
  %13 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01) #3
  %14 = icmp sgt i32 %13, 1
  br i1 %14, label %15, label %16

15:                                               ; preds = %11
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  br label %16

16:                                               ; preds = %15, %11
  %17 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef -2.500000e-01) #3
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  %19 = add nsw i32 %18, %12
  ret i32 %19
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice()
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef i32 @opaque() local_unnamed_addr #2 {
  ret i32 1
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @ext(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 1
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

; THE ORDER IS THE ASSERTION: the condition register is rotated by 0.25, the flag
; is minted from THAT register, the kickback fires on the flag, the flag is
; stripped and freed, and only THEN does the S-dagger run.
; CHECK:      call void @cqrt_ry_i32(i32 %out, double 2.500000e-01)
; CHECK-NEXT: %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %out, i32 1)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %h_cmp2, double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp2, i32 %out, i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp2)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %out, double -2.500000e-01)
; CHECK-NEXT: %m = call i32 @cqrt_measure_i32(i32 %out)

; Whole-file exact counts, so an INJECTED gate anywhere in the module reddens a
; prefix (the injection-matrix discipline: a trailing CHECK-NOT is windowed by
; the positives above it and catches nothing).
; RYCNT-COUNT-3: call void @cqrt_ry_i32(
; RYCNT-NOT:     call void @cqrt_ry_i32(
; RZCNT-COUNT-1: call void @cqrt_rz_i1(
; RZCNT-NOT:     call void @cqrt_rz_i1(
; MCNT-COUNT-1:  call i32 @cqrt_measure_i32(
; MCNT-NOT:      call i32 @cqrt_measure_i32(
; FCNT-COUNT-2:  call void @cqrt_free(
; FCNT-NOT:      call void @cqrt_free(
; The only X-brackets belong to the 6.5 classical-call arm's copy merge; the
; kickback region emits NONE (its flag is minted by a compare, not by a bracket).
; XCNT-COUNT-2:  call void @cqrt_x(
; XCNT-NOT:      call void @cqrt_x(

; No route, and no `@cq_theta`/`@cq_phi` left standing.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: call void @cq_phi
