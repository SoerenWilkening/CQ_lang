; control_phase_kickback_rail_inloop_iterlocal_invariant_seed.ll — ACCEPT (Track
; A.1, Rule-13 ROUND-2 finding F-A1R2-3; probe `review_a1_r2_probes/b3.c`, plain
; `clang -O1` C, single TU).
;
; WHAT IS DISTINCT ABOUT THIS MEMBER, and it is the only reason it is a file and
; not a duplicate of `control_phase_kickback_rail_inloop_iterlocal_measure_after.ll`:
; the origin theta's SEED is a LOOP-INVARIANT NON-CONSTANT value (`(_Bool)(u & 1)`,
; computed in the preheader), so the natural expectation is that `-O1` LICMs the
; whole `cq_theta` out of the body — in which case the register would be
; loop-CARRIED, the per-activation barrier would have no subject and the program
; would (correctly) decline. IT DOES NOT: `clang -O1` keeps the call in the body
; (a call is not speculatable), and the lowered `cqrt_alloc_i1(%3)` is INSIDE the
; loop block — MEASURED, and pinned by `CHECK-LABEL` below. The accept's ground is
; therefore "the origin re-executes on every path", NOT "the seed is a constant".
;
;     int slice(int u) { int acc = 0;
;       for (int i = 0; i < 3; ++i) {
;         _Bool b = cq_theta((_Bool)(u & 1), 0.5);
;         if (b) cq_phi(0.3);
;         acc += cq_measure(b) + ext(i);
;       }
;       return acc; }
;
; DECLINE -> ACCEPT against the ORACLE (`main` 0c7380c rc 1, `condition measured
; before the control route`); ACCEPT on b439944 and here. It is one of the (at
; least) five plain-C members of the rail-path accept class the round-1 record
; named as "exactly two, by name" — see `FIX_A1_R2.md` F-A1R2-3.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 1
  %3 = icmp ne i32 %2, 0
  br label %5

4:                                                ; preds = %10
  ret i32 %15

5:                                                ; preds = %1, %10
  %6 = phi i32 [ 0, %1 ], [ %15, %10 ]
  %7 = phi i32 [ 0, %1 ], [ %16, %10 ]
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 5.000000e-01) #2
  br i1 %8, label %9, label %10

9:                                                ; preds = %5
  tail call void @cq_phi(double noundef 3.000000e-01) #2
  br label %10

10:                                               ; preds = %9, %5
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8) #2
  %12 = zext i1 %11 to i32
  %13 = tail call i32 @ext(i32 noundef %7) #2
  %14 = add i32 %6, %12
  %15 = add i32 %14, %13
  %16 = add nuw nsw i32 %7, 1
  %17 = icmp eq i32 %16, 3
  br i1 %17, label %4, label %5, !llvm.loop !6
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare i32 @ext(i32 noundef) local_unnamed_addr #1


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

; THE MINT IS IN THE LOOP BODY — the ground of the accept, pinned positionally
; rather than asserted:
; CHECK-LABEL: 5:
; CHECK:      %h = call i32 @cqrt_alloc_i1(
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %h, double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: %m = call i1 @cqrt_measure_i1(i32 %h)

; ONE mint / rotation / kickback / measurement PER ACTIVATION — the loop is
; ROLLED, so these whole-file counts are one iteration's text:
; ACNT-COUNT-1:  call i32 @cqrt_alloc_i1(
; ACNT-NOT:      call i32 @cqrt_alloc
; MCNT-COUNT-1:  call i1 @cqrt_measure_i1(
; MCNT-NOT:      call i1 @cqrt_measure
; RYCNT-COUNT-1: call void @cqrt_ry_i1(
; RYCNT-NOT:     call void @cqrt_ry
; The rail IS the flag: nothing is minted for it and nothing is freed (a dead
; register left ALLOCATED is Rule 6's safe direction).
; FCNT-NOT:      call void @cqrt_free(
; NOROUTE-NOT:   @cqrt_cswap
; NOROUTE-NOT:   call void @cqrt_x(
; NOROUTE-NOT:   call i32 @cq_theta
; NOROUTE-NOT:   call void @cq_phi

; SILENT-NOT: cq controlled lowering
; SILENT-NOT: cq loop lowering
