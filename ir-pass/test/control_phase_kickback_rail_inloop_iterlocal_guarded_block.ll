; control_phase_kickback_rail_inloop_iterlocal_guarded_block.ll — ACCEPT (Track
; A.1, Rule-13 ROUND-2 finding F-A1R2-3; probe `review_a1_r2_probes/b4.c`, plain
; `clang -O1` C, single TU).
;
; WHAT IS DISTINCT: the origin, the branch and the measurement all sit inside a
; GUARDED SUB-BLOCK of the loop body (`if (opaque()) { ... }`), not in the body's
; straight line. The per-activation barrier's question is "does every path from
; the measurement back to the read point re-execute the origin?", and here the
; answer is yes for a CONTROL-FLOW reason rather than a textual one: the only path
; from the measure back to the read leaves the guarded block, crosses the latch and
; re-enters it through the guard, which re-executes `cqrt_alloc_i1`. This is the
; `o7c` argument, and no other pinned member exercises it.
;
;     int slice(int u) { int acc = 0;
;       for (int i = 0; i < 3; ++i) {
;         if (opaque()) { _Bool b = (_Bool)0; cq_theta(&b, 0.5);
;                         if (b) cq_phi(0.3);
;                         acc += cq_measure(b); }
;         acc += ext(i);
;       }
;       return acc; }
;
; DECLINE -> ACCEPT against the ORACLE (rc 1, `condition measured before the
; control route`); ACCEPT on b439944 and here.

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
  br label %3

2:                                                ; preds = %15
  ret i32 %18

3:                                                ; preds = %1, %15
  %4 = phi i32 [ 0, %1 ], [ %18, %15 ]
  %5 = phi i32 [ 0, %1 ], [ %19, %15 ]
  %6 = tail call i32 @opaque() #2
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %15, label %8

8:                                                ; preds = %3
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br i1 %9, label %10, label %11

10:                                               ; preds = %8
  tail call void @cq_phi(double noundef 3.000000e-01) #2
  br label %11

11:                                               ; preds = %10, %8
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9) #2
  %13 = zext i1 %12 to i32
  %14 = add nsw i32 %4, %13
  br label %15

15:                                               ; preds = %11, %3
  %16 = phi i32 [ %14, %11 ], [ %4, %3 ]
  %17 = tail call i32 @ext(i32 noundef %5) #2
  %18 = add nsw i32 %17, %16
  %19 = add nuw nsw i32 %5, 1
  %20 = icmp eq i32 %19, 3
  br i1 %20, label %2, label %3, !llvm.loop !6
}

declare i32 @opaque() local_unnamed_addr #1

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
; CHECK-LABEL: 8:
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
