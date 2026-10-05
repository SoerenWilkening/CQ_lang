; control_inplace_ry_reject_flat_rotated_dead.ll — DECLINE (FLAT), and the
; decline is `clang -O1`'s doing rather than a fence's. The other half of the
; pair begun in `control_inplace_ry_inloop_rotated_dead.ll` (bd
; test_C_libtooling-rhwb; drbq Inc 3 round-1 lens L3 Q5).
;
;     if (q == 5) cq_theta(&r, 0.9);
;     if (q == 5) cq_theta(&r, 0.9);
;     return cq_measure(q);          <-- `r` is DEAD
;
; This is the HAND-UNROLLED TWIN of the accept, i.e. the increment's own stated
; oracle for it — and it does not exist as one. With `r` dead, `clang -O1` drops
; the SECOND diamond's merge φ entirely (block `%12` below has no `r` phi;
; `%11`'s only consumer was that φ). `recoverRegion` needs a 2-incoming merge φ
; to name a region at all, so the shape is OFF-PATTERN and declines generically.
;
; ⚠ READ THE DIRECTION. This is NOT the flat path refusing something the rolled
; path mis-lowers. It is the flat path having NOTHING TO LOWER, because the two
; spellings stopped being the same program shape under `-O1` — the same class of
; artifact `tools/loop_twin_matrix.py`'s docstring warns about for constant
; folding, met from a different side. Measured IDENTICALLY on the pre-Inc-3
; ORACLE binary, so nothing here moved in this increment.
;
; CONSEQUENCE, recorded because it is the reason the pair is committed: for the
; dead-rotated-register shape the twin-identity witness is STRUCTURALLY
; UNAVAILABLE. The rolled accept is argued from Rule 6 and from its emitted
; stream, not from a twin. Anyone who later reads the rolled file as
; "matrix-covered" is wrong, and this file is where they find that out.
;
; THE BODY IS VERBATIM `clang -O1` OUTPUT (`review3/L3/p/q5a_rdead_unrolled.c`),
; renamed, minus the two uncontrolled `q = cq_phi(q, 0.1)` 3qlq deleted — a hand
; transcription would have re-created the φ the optimizer deleted.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @example() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %9 = icmp eq i32 %1, 5
  br i1 %9, label %10, label %12

10:                                               ; preds = %6
  %11 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 9.000000e-01) #2
  br label %12

12:                                               ; preds = %10, %6
  %14 = tail call i32 @cq_measure_si32(i32 noundef %1) #2
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1


declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @example()
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
