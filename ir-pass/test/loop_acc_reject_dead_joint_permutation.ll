; loop_acc_reject_dead_joint_permutation.ll — DECLINE, an ADVERSARIAL WITNESS (bd 01po.19.18.6, R11 round 1
; rA1B-F5; ruling ruling-01po19-18-dead-accumulator-leak-warn-2026-10-16).
;
; SOURCE (clang -O1, verbatim below; the reviewer's pC.c):
;   #include <stdio.h>
;   int main(void) {
;       int a = 0;
;       cq_theta(&a, 1.0);
;       int c = 0;
;       for (int i = 0; i < 3; i++) {
;           if (c == 1) cq_phi(0.5);
;           c += a;
;       }
;       int r = 0;
;       cq_theta(&r, 0.3);
;       a += r;                      /* the recorded value moves into a+r (a permutation) */
;       cq_theta(&r, 0.7);           /* non-diagonal move of r: interferes branches of old a */
;       printf("%d %d\n", cq_measure(r), cq_measure(a));
;       return 0;
;   }
;
; THE HAZARD. `a += r` after the loop writes the recorded register `a` FROM the
; unrecorded `r`; the dead counter's record of the old `a` together with the new
; `a` now determines `r`, so the later `cq_theta(&r, .7)` dephases branches the
; source keeps coherent. The postcondition now grows the lineage through any
; runtime/template call that writes a lineage rail: its other operands join it.
; MASKED TODAY (measured): the straight-line in-place QQ round refuses `a += r`
; first. This file pins that the shape is loud.
; RETIREMENT TRIGGER: when the masking owner admits the shape, this file must
; then fail at the dead-accumulator postcondition (re-derive the CHECK there),
; and when bd 8h7d.20 reverses the counter after the loop it becomes an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq in-place lowering: quantum reassignment of a dead register is not provable in place

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00) #3
  br label %9

2:                                                ; preds = %14
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #3
  %4 = add nsw i32 %3, %1
  %5 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666) #3
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %6, i32 noundef %7)
  ret i32 0

9:                                                ; preds = %0, %14
  %10 = phi i32 [ 0, %0 ], [ %16, %14 ]
  %11 = phi i32 [ 0, %0 ], [ %15, %14 ]
  %12 = icmp eq i32 %11, 1
  br i1 %12, label %13, label %14

13:                                               ; preds = %9
  tail call void @cq_phi(double noundef 5.000000e-01) #4
  br label %14

14:                                               ; preds = %13, %9
  %15 = add nsw i32 %11, %1
  %16 = add nuw nsw i32 %10, 1
  %17 = icmp eq i32 %16, 3
  br i1 %17, label %2, label %9, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }


!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
