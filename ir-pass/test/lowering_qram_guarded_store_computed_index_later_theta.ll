; lowering_qram_guarded_store_computed_index_later_theta.ll — ACCEPT (bd
; test_C_libtooling-01po.7; a DECLINE->ACCEPT flip, main 7b4e6359 declined it with
; `cq opcode lowering: operand predates a non-diagonal gate`). `clang -O1` of
;
;     int arr[8] = {0};
;     int q = argc; cq_theta(&q, .5);
;     int c = argc + 1; cq_theta(&c, .5);
;     if (c < 3)
;       arr[q & 7] = 5;               // computed index, guarded store
;     int p = argc + 2; cq_theta(&p, .5);
;     int v = arr[p & 7];
;     cq_theta(&q, -.5);              // later chained Ry on the index source
;     return cq_measure(q) + cq_measure(v) + cq_measure(c);
;
; The `and` sits under tainted control and the Ry on `q` after the merge, so the
; stale-record fence's dominance precondition refused it. Every trace runs the `and`
; before the Ry (the Ry post-dominates it and cannot reach it), so the VALUE was
; never in doubt; the hazard was the hoisted RAIL. Since bd 01po.7 the fence grants
; it and records the grant, and the late live-record pass declines loudly if that
; rail is still standing at the Ry (lowering_reject_tainted_arm_read_live_at_gate.ll).
;
; SEMANTIC EVIDENCE (hand trace of the stream below; nothing in `main` is
; reversed). f = (c < 3) on its own rail; i = q & 7 is computed on EVERY branch
; (hoisted); `qram_store_controlled(f, arr, i, 5)` writes 5 into cell i only when
; f = 1, the source's guarded write (a faithful CNOT write, bd 38t2). Then the flag
; is stripped and freed against the unmoved c, and i is stripped (`and_unc(i, q, 7)`)
; and freed against the UNMOVED q: compute-then-uncompute of i is the identity on
; q, so on the f = 0 branch no copy of q exists when `Ry(-0.5)` fires, exactly as
; in the source. On f = 1 the cell holds the write the source made. The later
; `Ry(-0.5)` on q therefore acts on the same joint state as the source's.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; DIAG-NOT: error
; DIAG-NOT: live derived record
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK:      %[[I:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 7)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[I]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cq_template_and_i32_hl_unc(i32 %[[I]], i32 %[[Q]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[I]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[Q]], double -5.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[Q]])

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = add nsw i32 %0, 1
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01)
  %7 = icmp slt i32 %6, 3
  br i1 %7, label %8, label %12

8:                                                ; preds = %2
  %9 = and i32 %4, 7
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %10
  store i32 5, ptr %11, align 4
  br label %12

12:                                               ; preds = %8, %2
  %13 = add nsw i32 %0, 2
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 5.000000e-01)
  %15 = and i32 %14, 7
  %16 = zext nneg i32 %15 to i64
  %17 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %16
  %18 = load i32, ptr %17, align 4
  %19 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01)
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19)
  %21 = tail call i32 @cq_measure_si32(i32 noundef %18)
  %22 = add nsw i32 %21, %20
  %23 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %24 = add nsw i32 %22, %23
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %24
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
