; lowering_qram_stale_index_crossblock_placed_accept.ll — ACCEPT (bd
; test_C_libtooling-57ch.1 and -57ch.3, batch 053; owner ruling bd 57ch (A)): the
; index computation of `tbl[q & 7]`, scheduled after the gate and a classical
; diamond, is placed before the gate; the QROM read then reads a fresh rail.
;
;   static const int tbl[8] = {3,1,4,1,5,9,2,6};
;   int g;
;   int main(int argc, char **argv) {
;     long q = 0L; cq_theta(&q, .5);
;     long q2 = q; cq_theta(&q2, .3);
;     if (argc > 1) g = argc;
;     int v = tbl[q & 7];              // stale index, after a classical diamond
;     return (int)cq_measure(v) + (int)cq_measure(q2) + g;
;   }
;
; The stale reader is the `and i64 %q, 7` in the merge block: a pure op reading the
; pre-Ry record. It post-dominates the gate across an acyclic span holding only a
; store to `g`, so it is placed before `cq_theta(&q2, .3)` (its template copies the
; pre-Ry label). The QROM load then indexes the `and`'s fresh rail, on which no gate
; acts: it is not stale and stays where it was. Before batch 053 the `and` declined.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK-NEXT: call void @cqrt_ry_i64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[A:.*]] = call i32 @cq_template_and_i64_hl(i32 %[[H]], i64 7)
; CHECK-NEXT: call void @cqrt_ry_i64(i32 %[[H]], double 3.000000e-01)
; CHECK:      store i32 %0, ptr @g
; CHECK:      %[[X:.*]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[A]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %{{[a-z0-9]+}}, i32 %[[X]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4
@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call i64 @cq_theta_sl(i64 noundef 0, double noundef 5.000000e-01) #2
  %4 = tail call i64 @cq_theta_sl(i64 noundef %3, double noundef 3.000000e-01) #2
  %5 = icmp sgt i32 %0, 1
  br i1 %5, label %6, label %7

6:                                                ; preds = %2
  store i32 %0, ptr @g, align 4
  br label %7

7:                                                ; preds = %6, %2
  %8 = and i64 %3, 7
  %9 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %8
  %10 = load i32, ptr %9, align 4
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %12 = tail call i64 @cq_measure_sl(i64 noundef %4) #3
  %13 = trunc i64 %12 to i32
  %14 = add nsw i32 %11, %13
  %15 = load i32, ptr @g, align 4
  %16 = add nsw i32 %14, %15
  ret i32 %16
}

declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr

attributes #0 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
