; lowering_stale_speccall_independent_gates_placed_accept.ll — ACCEPT (bd
; test_C_libtooling-57ch.6, batch 053; owner ruling bd 57ch (A)): the placement
; carries an INDEPENDENT register's mint AND a later gate on it above the staling gate.
;
;   __attribute__((noinline)) int f(int x, int k) { return x * 3 + k; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int p = 0; cq_theta(&p, .7);     // a FRESH register minted after the gate
;     cq_theta(&p, .2);                // and a second gate on it
;     int r = f(q, p);
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; `p`'s register is minted in the span between the gate and the read and is touched
; only by gates the read depends on, so the mint and the chained gate move with the
; call (StaleReadPlacement.h clause (b)): gates on disjoint wires commute with the
; staling gate. The single-gate spelling is
; lowering_stale_speccall_reject_independent_quantum_operand.ll (verdict inverted by
; this change). The CHECK-NEXT chain is the load-bearing order: `p`'s mint, both its
; Ry, then the clone call, all before `ry(q, .3)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[P:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 2.000000e-01)
; CHECK-NEXT: %[[R:.*]] = tail call i32 @__cq_q_f_11(i32 noundef %[[H]], i32 noundef %[[P]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])

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
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #3
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.000000e-01) #3
  %5 = tail call i32 @f(i32 noundef %1, i32 noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  %7 = tail call i32 @cq_measure_si32(i32 noundef %2) #4
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
