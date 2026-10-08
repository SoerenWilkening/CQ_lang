; control_classical_call_arm_accept_inner_call_nsw.ll — ACCEPT (bd test_C_libtooling-bwfp, review round 2).
; Plain C at -O1 (FunctionAttrs inferred `noundef` on g's return and `range` on f's):
;   __attribute__((noinline)) int g(int a) { return a ^ 5; }
;   __attribute__((noinline)) int f(int a) { return g(a) * 3 + 1; }
;   int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = f(argc); return cq_measure(y);
; Hoisting `f(argc)` out of the guard is sound: g's `noundef` parameter receives f's
; DEFINED parameter, and the only poison (`mul nsw`) reaches f's result, which is never
; merged on a shielded state. The first bwfp rule ("any `noundef` in the call tree needs
; the strict totality proof") declined this ordinary C; the poison-flow analysis
; (SpeculationSafety.cpp `poisonFlow`) accepts it, as e0af16ed did.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @main(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @f(i32 noundef %0)
; CHECK:       %[[RH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[RH]],

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define noundef i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, 5
  ret i32 %2
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @g(i32 noundef %0)
  %3 = mul nsw i32 %2, 3
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #3
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call i32 @f(i32 noundef %0)
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  ret i32 %9
}



attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable }
attributes #1 = { nounwind ssp uwtable }
attributes #2 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }


