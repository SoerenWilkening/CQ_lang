; lowering_reject_tainted_arm_read_live_at_gate.ll — DECLINE (bd
; test_C_libtooling-01po.7, the LATE re-check of the stale-record fence's
; tainted-arm grant). `clang -O1` of a NON-main helper whose array is observed
; inside it, so the local array's store is REVERSED at the end:
;
;     static int g(int seed) {
;       int arr[8] = {0};
;       int q = seed; cq_theta(&q, .5);
;       int i = seed + 1; cq_theta(&i, .5);
;       if (q < 3) arr[i & 7] = 7;     // computed index under tainted control
;       cq_theta(&i, -.3);             // chained Ry on the index source
;       int v = arr[q & 7];
;       return cq_measure(v);
;     }
;
; The early fence grants the `and` (the Ry follows it on every trace) and records
; the grant. The store's reversal re-reads the index, so the hoisted `and` rail is
; NOT discharged until the end: it stands, computed on every branch, when `Ry(-.3)`
; fires on `i`, and on the `q >= 3` branch the source made no such copy. The late
; live-record pass finds the granted record live at that gate and declines.
;
; L5, disclosed: this instance is benign by LIFO, since the spine undoes `Ry(-.3)`
; before it uncomputes the `and` and nothing between reads `i`. The re-check cannot
; tell, so it fails loudly: an over-decline, never a wrong unitary.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: hoisted tainted-arm read is live at a non-diagonal gate

define i32 @main() {
  %1 = tail call fastcc i32 @g()
  ret i32 %1
}

define internal fastcc i32 @g() unnamed_addr {
  %1 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %1)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %1, i8 0, i64 32, i1 false)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01)
  %4 = icmp slt i32 %2, 3
  br i1 %4, label %5, label %9

5:                                                ; preds = %0
  %6 = and i32 %3, 7
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %7
  store i32 7, ptr %8, align 4
  br label %9

9:                                                ; preds = %5, %0
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -3.000000e-01)
  %11 = and i32 %2, 7
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %1)
  ret i32 %15
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
