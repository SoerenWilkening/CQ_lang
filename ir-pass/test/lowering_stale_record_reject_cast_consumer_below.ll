; lowering_stale_record_reject_cast_consumer_below.ll — DECLINE (bd
; test_C_libtooling-57ch.3; batch 053 composition fix-forward, HIGH; the
; composition probe's P2).
;
;   __attribute__((noinline)) int f(double v) { return (int)(v * 2.0) + 1; }
;   int probe(int x) {
;     int q = x; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int r = f((double)q) & 1;        // stale cast; its lifted consumer is not stale
;     return cq_measure(r) + cq_measure(q2);
;   }
;
; The stale reader is `sitofp %q`; its consumer, the lifted call `f`, reads the
; cast's fresh rail and is not stale, so it was not moved. The merged batch-053
; placement moved the cast alone: `(double)q_pre` stayed dirty and entangled across
; `cq_theta(&q2, .3)` (its `_unc` re-reads `q`, so it had no valid position and was
; never emitted) — verify-clean, stage 2b clean, a dephasing the read-first twin
; (cast, call, `_unc`, free, all before the Ry) does not have. Clause (b') of
; StaleReadPlacement.cpp refuses a placement that leaves a minted rail with a
; non-measurement user outside the moved set; the stale fence declines. The
; `cqc`-lifted twin (`lround((double)q)`, P1) declines the same way.
; RETIREMENT TRIGGER (L7): carrying the read's forward tainted cone (the call with
; it, re-checked by (b)-(e)) flips this file to an accept with the twin's stream.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function probe i32 (i32): cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 -2147483647, -2147483648) i32 @f(double noundef %0) local_unnamed_addr #0 {
  %2 = fmul double %0, 2.000000e+00
  %3 = fptosi double %2 to i32
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

define i32 @probe(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #3
  %4 = sitofp i32 %2 to double
  %5 = tail call i32 @f(double noundef %4)
  %6 = and i32 %5, 1
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %8 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
