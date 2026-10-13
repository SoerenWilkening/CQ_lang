; lowering_stale_speccall_reject_dependent_quantum_operand.ll — DECLINE (bd
; test_C_libtooling-57ch.6, batch 053; 57ch (B), not built): the lifted call's
; second quantum operand is derived from the POST-gate value, so it cannot move.
;
;   __attribute__((noinline)) int f(int x, int k) { return x * 3 + k; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int p = q2; cq_theta(&p, .7);    // p is derived from the POST-gate value
;     int r = f(q, p);
;     return (int)cq_measure(r) + (int)cq_measure(p);
;   }
;
; 57ch.6 carries an independent register's gates above the staling gate, but here
; `cq_theta(&p, .7)` is a gate on `q`'s own register whose input is the staling
; gate's result: the read needs the pre-gate label of `q` AND a post-gate state at
; once (StaleReadPlacement.h clause (b): a staler is never carried, and a gate on a
; register that predates the slot is never carried). Loud until 57ch (B).
; Contrast lowering_stale_speccall_independent_gates_placed_accept.ll.
; RETIREMENT TRIGGER (L7): 57ch (B) flips this file to an accept with a warning.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = mul nsw i32 %0, 3
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666) #3
  %4 = tail call i32 @f(i32 noundef %1, i32 noundef %3)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %7 = add nsw i32 %6, %5
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
