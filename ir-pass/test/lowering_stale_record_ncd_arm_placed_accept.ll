; lowering_stale_record_ncd_arm_placed_accept.ll — ACCEPT (bd
; test_C_libtooling-57ch.1 and -57ch.3, batch 053; owner ruling bd 57ch (A)): a
; stale PURE op after a merge, whose staling gate sits in a classical ARM, is placed
; at the end of the block that dominates both (before the branch).
;
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int r = q;                       // the pre-arm record
;     if (argc > 1) cq_theta(&q, .3);  // the staling gate, in a classical arm
;     int d = r + 1;                   // reads the pre-arm record after the merge
;     return (int)cq_measure(d) + (int)cq_measure(q);
;   }
;
; ⚠ THE READ-FIRST SPELLING HAS THE SAME -O1 MODULE. `int d = q + 1;` written
; BEFORE the `if` is sunk into the merge block by -O1 (byte-identical module,
; batch-053 L3 probe t02), so before batch 053 a program written in the fresh order
; declined too: `cq opcode lowering: operand predates a non-diagonal gate`.
;
; The slot is the terminator of the nearest common dominator of the read and the
; gate (StaleReadRegion.h): every path from it reaches the read exactly once, the
; span is the arm, and `add` touches no memory. The template is emitted before the
; branch, so it copies the pre-arm label on both paths; the arm's Ry then runs on
; `q` alone. The warning is the lyyf live-record class, and it is the program's:
; `d` is a basis copy of `q` that the source keeps (it is measured) across a
; non-diagonal gate on `q`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN %s < %t.err
; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: icmp sgt i32 %0, 1
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: br i1
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %4 = icmp sgt i32 %0, 1
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #2
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = add nsw i32 %3, 1
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
