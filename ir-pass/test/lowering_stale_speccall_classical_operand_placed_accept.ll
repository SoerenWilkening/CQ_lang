; lowering_stale_speccall_classical_operand_placed_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.6, review round 1 F2; owner ruling bd 57ch (A)).
;
;   __attribute__((noinline)) int f(int x, int k) { return x * 3 + k; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int r = f(q, argc * 3);          // stale q + a CLASSICAL operand
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; -O1 schedules `%5 = mul nsw i32 %0, 3` AFTER both thetas, so the call's second
; operand does not dominate the placement slot. It is classical and does not depend
; on the gate, so the placement CARRIES it to the slot with the call
; (StaleReadPlacement.h clause (b)); the first snapshot refused it, with a comment
; that called it a post-gate value (it is not). Main lowered this at exit 0 with the
; clone call after `ry(h, .3)`: f ran on the rotated register.
; Decline twin (a carried load that would cross a conflicting store):
; lowering_stale_speccall_reject_classical_operand_load_conflict.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[K:.*]] = mul nsw i32 %0, 3
; CHECK-NEXT: %[[R:.*]] = tail call i32 @__cq_q_f_01(i32 noundef %[[H]], i32 noundef %[[K]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = mul nsw i32 %0, 3
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #2
  %5 = mul nsw i32 %0, 3
  %6 = tail call i32 @f(i32 noundef %3, i32 noundef %5)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  %8 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
