; control_inplace_ry_stateprep_ifelse_condwire_pin_p6.ll — ACCEPT (bd
; test_C_libtooling-dm7f.54 round-2 review F2; revC54r2/p6.c, plain C at -O1, the
; exact program for the drbq.13 disclosure):
;
;     int t = 0; cq_theta(&t, 1.0);
;     if (t == 5) { cq_theta(&t, 0.1); } else { t = 5; cq_theta(&t, 0.2); }
;     return cq_measure(t);
;
; GVN puts the literal 5 into the then-arm, so both arms prepare the SAME literal
; (item B's twin-literal prep, one rail). F2 on the TRUE arm edge pins `t` to 5
; = the seed, but `t` is the CONDITION'S OWN register (`CondWire`), the
; owner-ruled α trade, so it is excluded and the region lowers: the source's
; in-place Ry of `t` on the t == 5 branch becomes a Ry of a fresh |5>, while the
; measured result is the merged `t` either way. Its TERNARY twin
; `control_angle_select_ry_literal_seed_condwire_p6t.ll` asks the same F2
; exclusions (`f2ExcludedAtTest`, one spelling) and emits this stream byte for
; byte.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 1.000000e+00)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 1.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

define i32 @f6() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00) #3
  %2 = icmp eq i32 %1, 5
  br i1 %2, label %3, label %5

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 1.000000e-01) #3
  br label %7

5:                                                ; preds = %0
  %6 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 2.000000e-01) #3
  br label %7

7:                                                ; preds = %5, %3
  %8 = phi i32 [ %4, %3 ], [ %6, %5 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

define i32 @main() local_unnamed_addr #2 {
  %1 = tail call i32 @f6()
  ret i32 %1
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
