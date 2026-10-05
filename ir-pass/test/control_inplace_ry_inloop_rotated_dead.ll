; control_inplace_ry_inloop_rotated_dead.ll — ACCEPT (ROLLED, in-loop): the
; rotated register is NEVER MEASURED. Half of a paired witness with
; `control_inplace_ry_reject_flat_rotated_dead.ll`, and the pair exists to record
; a gap rather than a capability (bd test_C_libtooling-rhwb; drbq Inc 3 round-1
; lens L3 Q5).
;
;     for (i = 0; i < 2; ++i) { if (q == 5) cq_theta(&r, 0.9); }
;     return cq_measure(q);          <-- `r` is DEAD after the loop
;
; ROLLED IS CORRECT AND IT IS THE FREEZE'S OWN FLAGSHIP CONSEQUENCE. The
; controlled Ry fires once per trip on `%h1`, which is then LEFT ALLOCATED —
; never `_unc`'d, never freed. That is the right answer under Rule 6, not an
; omission: a dead register carrying superposition ENTANGLED with the condition
; register must not be freed, because `cqrt_free` is a hardware reset, i.e. a
; hidden measurement that would collapse `q`. Measured (L3, pre-3qlq): 15 trace
; lines, strict stage 2b `4 rail mints of which 4 left allocated, 2 cqrt_free sites: 2
; verified, 0 violations`.
;
; ⚠ WHAT THE PAIR RECORDS: FOR THIS SHAPE THE INCREMENT'S STATED ORACLE DOES NOT
; EXIST. Every slice and fixture in this family is argued against the Increment-1
; FLAT lowering — "the rolled loop emits the same gate stream its hand-unrolled
; twin does". Hand-unroll THIS program and `clang -O1`, seeing `r` dead, emits NO
; MERGE φ for the second diamond, so `ControlDetect` declines it: the twin is not
; a different stream, it is not a stream at all. `tools/loop_twin_matrix.py` has a
; `ROLLED-ONLY` disposition and cells that use it, but none of them is a
; dead-rotated-register cell, so the class was recorded nowhere. It is now
; recorded here, in a pair, deliberately — a rolled accept whose flat twin
; declines is exactly the shape whose witness cannot be twin-identity, and a
; reader must know that before treating this file as covered by the matrix.
;
; THE BODY IS VERBATIM `clang -O1` OUTPUT (`review3/L3/p/q5a_rdead.c`), renamed,
; less the loop's `q = cq_phi(q, 0.1)` 3qlq deleted, because the whole point of
; the pair is what the optimizer does to the two spellings.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; one rolled copy of the per-activation stream:
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.0
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; only the CONDITION register is measured; `r` is dead:
; CHECK: call i32 @cqrt_measure_i32(i32 %[[Q]])
;
; THE FREEZE, asserted whole-file: the dead rotated register is never uncomputed
; and never freed. The `cqrt_free` above names the FLAG, and per function it is
; the only one (the module carries `@example` and the `main` `-O1` inlined the
; body into, so the whole-module count is 2 — one flag free each).
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: @cq_theta_
; NOROUTE-NOT: cqrt_ry_i32_controlled_inv
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @example() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br label %5

3:                                                ; preds = %12
  %4 = tail call i32 @cq_measure_si32(i32 noundef %8) #2
  ret i32 %4

5:                                                ; preds = %0, %12
  %6 = phi i32 [ 0, %0 ], [ %15, %12 ]
  %7 = phi i32 [ %2, %0 ], [ %13, %12 ]
  %8 = phi i32 [ %1, %0 ], [ %8, %12 ]
  %9 = icmp eq i32 %8, 5
  br i1 %9, label %10, label %12

10:                                               ; preds = %5
  %11 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 9.000000e-01) #2
  br label %12

12:                                               ; preds = %10, %5
  %13 = phi i32 [ %11, %10 ], [ %7, %5 ]
  %15 = add nuw nsw i32 %6, 1
  %16 = icmp eq i32 %6, 0
  br i1 %16, label %5, label %3, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1


declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br label %3

3:                                                ; preds = %10, %0
  %4 = phi i32 [ 0, %0 ], [ %13, %10 ]
  %5 = phi i32 [ %2, %0 ], [ %11, %10 ]
  %6 = phi i32 [ %1, %0 ], [ %6, %10 ]
  %7 = icmp eq i32 %6, 5
  br i1 %7, label %8, label %10

8:                                                ; preds = %3
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 9.000000e-01) #2
  br label %10

10:                                               ; preds = %8, %3
  %11 = phi i32 [ %9, %8 ], [ %5, %3 ]
  %13 = add nuw nsw i32 %4, 1
  %14 = icmp eq i32 %4, 0
  br i1 %14, label %3, label %15, !llvm.loop !6

15:                                               ; preds = %10
  %16 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  ret i32 0
}

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
