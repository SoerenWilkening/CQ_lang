; lowering_stale_speccall_crossed_lifetime_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.6, review round 4 R4-1: an over-decline of snapshot
; 1796963b, placed correctly by ed6d4c2e).
;
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int buf[4];
;     buf[0] = argc; buf[1] = argc + 1; buf[2] = argc + 2; buf[3] = argc + 3;
;     int k = buf[(argc >> 2) & 3];
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + k;
;   }
;
; Between the gate and the stale lifted call sit a stack array's
; `llvm.lifetime.start` and plain non-volatile stores and a load: no volatile access,
; no atomic, no fence (owner ruling 2026-10-08), and nothing `f` (`memory(none)`)
; conflicts with. The intrinsic is `nosync`, so it is crossable
; (StaleReadPlacement.cpp `callCrossable`); 1796963b refused every crossed call that
; touches memory. The call is placed between the two Ry.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = tail call i32 @__cq_q_f_1(i32 noundef %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = alloca [4 x i32], align 16
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 3.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #4
  store i32 %0, ptr %3, align 16
  %6 = add nsw i32 %0, 1
  %7 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 %6, ptr %7, align 4
  %8 = add nsw i32 %0, 2
  %9 = getelementptr inbounds i8, ptr %3, i64 8
  store i32 %8, ptr %9, align 8
  %10 = add nsw i32 %0, 3
  %11 = getelementptr inbounds i8, ptr %3, i64 12
  store i32 %10, ptr %11, align 4
  %12 = lshr i32 %0, 2
  %13 = and i32 %12, 3
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %14
  %16 = load i32, ptr %15, align 4
  %17 = tail call i32 @f(i32 noundef %4)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #4
  %19 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  %20 = add i32 %18, %16
  %21 = add i32 %20, %19
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #4
  ret i32 %21
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
