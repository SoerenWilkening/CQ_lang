; control_classical_call_arm_accept_two_sequential.ll — bd test_C_libtooling-dm7f.22
; (batch 053, lane L5): TWO SEQUENTIAL 6.5 classical-call arms on one quantum
; condition register now lower. Before, the alias pre-flight in
; `SwapRouteEmit::lowerControlRegions` declined `control flow under quantum control`
; at the SECOND region's compare, because its `Pred` is the first region's
; `MergeBB` and only `BranchRegion`/`PhaseKickback` were `reorderable`. A
; `ClassicalCallArm` ends in the same `flattenRegion` (doomed set {Arm, MergeBB},
; `Pred` survives) and emits positionally before `Pred`'s `br`, so the bd hcrg
; sequential-chain argument transfers verbatim: the LATER region is emitted
; first, and its stream rides the earlier region's merge splice, landing AFTER
; the earlier region's stream in program order (the CHECK order below).
;
; C source (clang -O1, plain C + CQ.h; F and F2 noinline classical helpers):
;   __attribute__((noinline)) int F(unsigned x, unsigned p) { return (int)((x ^ p) & 255u); }
;   __attribute__((noinline)) int F2(unsigned x, unsigned p) { return (int)((x + p) & 255u); }
;   int ex(unsigned x, unsigned p) { int q = 0; cq_theta(&q, .5); int y = q, z = q;
;     if (q > 3) y = F2(x, p);
;     if (q > 5) z = F(x, p);
;     return cq_measure(y) + cq_measure(z); }
;
; Analytic trace: y = (q>3) ? F2(x,p) : q lands in %out2 (flag minted from q > 3,
; F2's result materialized and copied on f, q copied on ¬f inside the cqrt_x
; bracket, flag stripped against the untouched q and freed); z = (q>5) ? F(x,p) : q
; likewise in %out. Neither region writes q (copies write fresh rails), so the
; second mint and both strips read the same basis q. Both flags are proven |0> at
; their single free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --input-file=%t.ll %s

; CHECK-LABEL: define i32 @ex(
; CHECK:       %h = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       [[A:%[0-9]+]] = tail call i32 @F2(
; CHECK-NEXT:  [[F1:%h_cmp[0-9]*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 3)
; CHECK-NEXT:  [[O1:%out[0-9]*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_xorc_i32_controlled(i32 [[F1]], i32 [[O1]], i32 [[A]])
; CHECK-NEXT:  call void @cqrt_x(i32 [[F1]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 [[F1]], i32 %h, i32 [[O1]])
; CHECK-NEXT:  call void @cqrt_x(i32 [[F1]])
; CHECK-NEXT:  call void @cq_template_icmp_sgt_i32_hl_unc(i32 [[F1]], i32 %h, i32 3)
; CHECK-NEXT:  call void @cqrt_free(i32 [[F1]])
; CHECK-NEXT:  [[B:%[0-9]+]] = tail call i32 @F(
; CHECK-NEXT:  [[F2:%h_cmp[0-9]*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
; CHECK-NEXT:  [[O2:%out[0-9]*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_xorc_i32_controlled(i32 [[F2]], i32 [[O2]], i32 [[B]])
; CHECK-NEXT:  call void @cqrt_x(i32 [[F2]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 [[F2]], i32 %h, i32 [[O2]])
; CHECK-NEXT:  call void @cqrt_x(i32 [[F2]])
; CHECK-NEXT:  call void @cq_template_icmp_sgt_i32_hl_unc(i32 [[F2]], i32 %h, i32 5)
; CHECK-NEXT:  call void @cqrt_free(i32 [[F2]])
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 [[O1]])
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 [[O2]])
; CHECK-NOT:   @cq_theta
; CHECK-NOT:   @cq_measure_si32

define noundef range(i32 0, 256) i32 @F(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = xor i32 %1, %0
  %4 = and i32 %3, 255
  ret i32 %4
}

define noundef range(i32 0, 256) i32 @F2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = add i32 %1, %0
  %4 = and i32 %3, 255
  ret i32 %4
}

define i32 @ex(i32 noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %7

5:
  %6 = tail call i32 @F2(i32 noundef %0, i32 noundef %1)
  br label %7

7:
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = icmp sgt i32 %3, 5
  br i1 %9, label %10, label %12

10:
  %11 = tail call i32 @F(i32 noundef %0, i32 noundef %1)
  br label %12

12:
  %13 = phi i32 [ %11, %10 ], [ %3, %7 ]
  %14 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %15 = tail call i32 @cq_measure_si32(i32 noundef %13) #3
  %16 = add nsw i32 %15, %14
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
