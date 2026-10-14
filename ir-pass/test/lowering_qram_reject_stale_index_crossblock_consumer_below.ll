; lowering_qram_reject_stale_index_crossblock_consumer_below.ll — DECLINE (bd
; test_C_libtooling-57ch.1 and -57ch.3; batch 053 composition fix-forward, HIGH).
; Renamed from lowering_qram_stale_index_crossblock_placed_accept.ll, which pinned
; the defect as an accept.
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
; The stale reader is the `and i64 %q, 7`; its consumer is the QROM load (through
; the index `gep`), which is not stale and so was NOT moved. Placing the `and` alone
; left its rail live across `cq_theta(&q2, .3)` with no valid position for its
; `_unc` (it re-reads `q`): dirty, entangled, a verify-clean dephasing the read-first
; twin (`and`, load and uncompute before the gate) does not have. Clause (b') of
; StaleReadPlacement.cpp refuses a placement that leaves a minted rail with a
; non-measurement user outside the moved set; the stale fence declines.
; RETIREMENT TRIGGER (L7): carrying the read's forward tainted cone (here the `gep`
; and the load, re-checked by (b)-(e)) flips this file to an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32, ptr): cq opcode lowering: operand predates a non-diagonal gate

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
