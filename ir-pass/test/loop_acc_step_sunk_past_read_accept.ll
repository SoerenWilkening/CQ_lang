; loop_acc_step_sunk_past_read_accept.ll — ACCEPT (bd 01po.19.18.8, R11 round 1
; rA1A-F2; an over-decline removed).
;
; SOURCE (clang -O1, verbatim below):
;   #include <stdio.h>
;   int main(void) {
;       int a = 0;
;       cq_theta(&a, 1.0);
;       int c = 0;
;       for (int i = 0; i < 3; i++) {
;           int old = c;
;           c += a;
;           if (old == 1) cq_phi(0.3);
;       }
;       printf("%d %d\n", cq_measure(a), cq_measure(c));
;       return 0;
;   }
;
; `-O1` places the step `%10 = add %9, %1` BEFORE the compare `icmp eq %9, 1` that
; reads the trip's OLD counter `%9` (the header phi, `old`). In place, the step
; moves the register, so a flag minted after it would read the NEW value: the
; record fence refused ("rail record read past an in-place gate on the same
; rail"). The step's only user is the header phi, so the commit SINKS it to the
; end of the latch, after every read of the trip's old value: an SSA-pure move of
; a pure op that changes no value any instruction sees. The flag is then minted
; from the register before the in-place add, as the source orders the reads.
; ANALYTIC: on each branch of `a` (every qubit rotated, backend.md §11.3) the
; register reads 0, a, 2a at the three compares — the source's `old` — and ends
; 3a; the phase fires where old == 1. Measured `c` is `-O1`'s closed form 3a.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; CHECK: %cq.acc = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.acc, i32 1)
; CHECK: call void @cqrt_free(i32 %h_cmp)
; CHECK: call void @cqrt_add_i32(i32 %h, i32 %cq.acc), !cq.inplace.qq

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00) #3
  br label %7

2:                                                ; preds = %13
  %3 = mul i32 %1, 3
  %4 = tail call i32 @cq_measure_si32(i32 noundef %1) #4
  %5 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %6 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %4, i32 noundef %5)
  ret i32 0

7:                                                ; preds = %0, %13
  %8 = phi i32 [ 0, %0 ], [ %14, %13 ]
  %9 = phi i32 [ 0, %0 ], [ %10, %13 ]
  %10 = add nsw i32 %9, %1
  %11 = icmp eq i32 %9, 1
  br i1 %11, label %12, label %13

12:                                               ; preds = %7
  tail call void @cq_phi(double noundef 3.000000e-01) #4
  br label %13

13:                                               ; preds = %12, %7
  %14 = add nuw nsw i32 %8, 1
  %15 = icmp eq i32 %14, 3
  br i1 %15, label %2, label %7, !llvm.loop !6
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
