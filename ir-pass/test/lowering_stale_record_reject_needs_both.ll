; lowering_stale_record_reject_needs_both.ll — DECLINE (bd test_C_libtooling-57ch.3,
; batch 053; owner ruling bd 57ch (B), not built): a pure op that reads the PRE-gate
; record AND the post-gate value of the same register cannot be placed.
;
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int d = q * q2;                  // the PRE-Ry record AND the post-Ry value at once
;     return (int)cq_measure(d);
;   }
;
; Since 57ch.3 a stale pure op is placed before its staling gate (the accept twin
; is lowering_reject_stale_record_add.ll, whose verdict that change inverted). Here
; the `mul`'s other operand IS the gate's result, which exists only after the gate,
; so no slot exists (StaleReadPlacement.h clause (b): a value that depends on a
; staler refuses). The only lowering is 57ch (B): a kept pre-gate snapshot plus a
; warning. Loud with the one stale-record string until then.
; RETIREMENT TRIGGER (L7): 57ch (B) flips this file to an accept with a warning.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %3 = mul nsw i32 %2, %1
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  ret i32 %4
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
