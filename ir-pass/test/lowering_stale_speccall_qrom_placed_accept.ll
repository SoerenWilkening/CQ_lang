; lowering_stale_speccall_qrom_placed_accept.ll — ACCEPT (bd test_C_libtooling-r2j3.6,
; population 2: a QROM read inside the lifted callee; owner ruling bd 57ch (A)).
;
;   static const int tbl[8] = {3,1,4,1,5,9,2,6};
;   __attribute__((noinline)) int g(int x) { return tbl[x & 7]; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int r = g(q);                    // reads the PRE-Ry record
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; Before r2j3.6 the clone's `cqrt_qram_load_i32` indexed the ROTATED register (exit 0).
; `g` reads only constant memory (`memory(none)` at -O1), so nothing between the gate
; and the call conflicts with it and the call is PLACED just before the gate: the
; clone call between the two Ry, its QROM load reading the pre-Ry index.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @main()
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = tail call i32 @__cq_q_g_1(i32 noundef %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-LABEL: define {{.*}}i32 @__cq_q_g_1(
; CHECK:      call i32 @cqrt_qram_load_i32(

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 7
  %3 = zext nneg i32 %2 to i64
  %4 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %3
  %5 = load i32, ptr %4, align 4
  ret i32 %5
}

define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %3 = tail call i32 @g(i32 noundef %1)
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
