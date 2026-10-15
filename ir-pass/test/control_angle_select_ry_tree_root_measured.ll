; control_angle_select_ry_tree_root_measured.ll — ACCEPT (bd test_C_libtooling-dm7f.54,
; item D; review F3, revC54b/p2 — declined with the misleading `rotation angle`):
;
;     _Bool c = a && b; cq_theta(&t, c ? .7 : .3); ... cq_measure(c)
;
; The tree ROOT has a second (measured) use. The network is minted from the
; LEAVES (`g = a ∧ b`), so the root is not consumed: it is not pre-claimed, lowers
; as its own 4.4 data select (`%out`, emitted after the angle region by the
; precedence edge), and the measurement reads `%out`. ANALYTIC: t = Ry(.7)|0> iff
; a ∧ b; `%out` holds a ∧ b by two controlled copies; both reads agree on every
; basis branch (a and b are read in control slots only).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[OUT:out[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[G:g[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[G]], i32 %[[T]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[G]], i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK:      call i1 @cqrt_measure_i1(i32 %[[T]])
; CHECK:      call i1 @cqrt_measure_i1(i32 %[[OUT]])

define range(i32 0, 3) i32 @f() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #2
  %3 = select i1 %1, i1 %2, i1 false
  %4 = select i1 %3, double 0x3FE6666666666666, double 3.000000e-01
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %4) #2
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #3
  %7 = zext i1 %6 to i32
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #3
  %9 = zext i1 %8 to i32
  %10 = add nuw nsw i32 %9, %7
  ret i32 %10
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
