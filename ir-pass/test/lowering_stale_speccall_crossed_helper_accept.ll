; lowering_stale_speccall_crossed_helper_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.6, review round 4 R4-1: an over-decline of snapshot
; 1796963b, placed correctly by ed6d4c2e).
;
;   int calls;
;   __attribute__((noinline)) void tick(void) { calls++; }
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     tick();                          // a visible helper, ordinary memory only
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + calls;
;   }
;
; `tick` touches memory, but its visible body holds no volatile access, no atomic
; access, no fence and no opaque call, so the moved gates may cross it (owner ruling
; 2026-10-08 covers only those events; StaleReadPlacement.cpp `callCrossable` asks
; the body). `f` is `memory(none)`, so clause (e) finds no conflict either. Decline
; twin, one body instruction away: lowering_stale_speccall_reject_crossed_atomic_helper.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @main()
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = tail call i32 @__cq_q_f_1(i32 noundef %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: tail call void @tick()
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

@calls = global i32 0, align 4

define void @tick() local_unnamed_addr #0 {
  %1 = load i32, ptr @calls, align 4
  %2 = add nsw i32 %1, 1
  store i32 %2, ptr @calls, align 4
  ret void
}

define i32 @f(i32 noundef %0) local_unnamed_addr #1 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main() local_unnamed_addr #2 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #3
  tail call void @tick()
  %3 = tail call i32 @f(i32 noundef %1)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %5 = tail call i32 @cq_measure_si32(i32 noundef %2) #4
  %6 = add nsw i32 %5, %4
  %7 = load i32, ptr @calls, align 4
  %8 = add nsw i32 %6, %7
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
