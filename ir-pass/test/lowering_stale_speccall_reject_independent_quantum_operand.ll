; lowering_stale_speccall_reject_independent_quantum_operand.ll — ACCEPT since bd test_C_libtooling-57ch.6 (batch 053;
; owner ruling bd 57ch (A)). ⚠ VERDICT INVERTED: this file declined before batch 053.
;
; The placement now CARRIES the independent register's mint with the call
; (StaleReadPlacement.h clause (b)): `p` is minted in the span and touched by no
; other gate, so its gate commutes with the staling gate. Two-gate spelling:
; lowering_stale_speccall_independent_gates_placed_accept.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: {{error|warning}}
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 0x3FE6666666666666)
; CHECK-NEXT: %[[R:[0-9]+]] = tail call i32 @__cq_q_f_11(i32 noundef %[[H]], i32 noundef %[[P]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])
;
; ── HISTORY: the pre-batch-053 header, kept verbatim (its verdict text is
; superseded by the block above) ──
; lowering_stale_speccall_reject_independent_quantum_operand.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 2 R2-4: recorded, not built).
;
;   __attribute__((noinline)) int f(int x, int k) { return x * 3 + k; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int p = 0; cq_theta(&p, .7);     // a FRESH register minted after the gate
;     int r = f(q, p);                 // stale q + the independent quantum p
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; `p` does not depend on the gate: its source theta is on a disjoint wire, so the
; program equals `int p = 0; cq_theta(&p, .7); int r = f(q, p); int q2 = q;
; cq_theta(&q2, .3);`. Placing the call would have to move `p`'s front-end gate above
; the staling gate, a commuting reorder of gates on disjoint wires; the placement
; never moves a front-end gate, so it refuses (StaleReadPlacement.h clause (b)) and
; the stale fence declines. This is NOT the 57ch (B) shape (no post-gate value of the
; read's own wire is needed). Main lowered it at exit 0 with f on the rotated
; register.
; RETIREMENT TRIGGER (L7): r2j3.6 follow-up F8 (carry an independent register's
; mint and gates along when they commute with the staling gate) flips this file.
;

define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = mul nsw i32 %0, 3
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #2
  %4 = tail call i32 @f(i32 noundef %1, i32 noundef %3)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %7 = add nsw i32 %6, %5
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
