; lowering_stale_speccall_fresh_record_accept.ll — ACCEPT, the non-stale lifted call
; (bd test_C_libtooling-r2j3.6).
;
; The lifted call reads `q2`, the POST-Ry record, which is exactly what the register
; holds where the call runs: no staling gate, nothing to place, and the call stays
; AFTER the gate. Pins that the lifted-call stale question does not move or refuse a
; fresh read (the fence's don't-over-decline boundary for the new reader family).
;
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int r = f(q2);
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @main()
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: %[[R:.*]] = tail call i32 @__cq_q_f_1(i32 noundef %[[H]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %3 = tail call i32 @f(i32 noundef %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %6 = add nsw i32 %5, %4
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
