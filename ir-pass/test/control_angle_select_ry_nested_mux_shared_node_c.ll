; control_angle_select_ry_nested_mux_shared_node_c.ll — ACCEPT under the debug
; allocator (bd test_C_libtooling-dm7f.54 round-2 review F1, the PLAIN-C
; spelling, -O1 keeps it):
;
;     _Bool n = (a > 3) && (b == 2); _Bool z = d < 7;
;     cq_theta(&t, (n ^ z) ? 0.11 : (n ? 0.22 : 0.33));
;
; `n` is a node of the outer member's tree (`n ^ z`) AND the inner member's
; condition. ANALYTIC: n⊕z -> Ry(.11); ¬(n⊕z) ∧ n -> Ry(.22); ¬(n⊕z) ∧ ¬n ->
; Ry(.33). The outer network (flags for a>3, b==2, d<7; g = AND; g3 = XOR) stays
; minted while the inner one (its own a>3, b==2 flags and AND) runs and strips;
; then the outer strips LIFO. Every free is proven-|0>.
;
; RUN: %debugalloc-cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; CHECK:      %[[G3:g[0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_ry_i1_controlled(i32 %[[G3]], i32 %[[T:[a-zA-Z0-9_.]+]], double 1.100000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G3]])
; CHECK:      %[[P:p[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[G3]], i32 %[[G6:g[0-9]+]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[P]], i32 %[[T]], double 2.200000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[G3]], i32 %[[G6]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G6]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[G3]], i32 %[[G6]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[P]], i32 %[[T]], double 3.300000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[G3]], i32 %[[G6]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G6]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[P]])
; CHECK:      call void @cqrt_x(i32 %[[G3]])
; CHECK:      call void @cqrt_free(i32 %[[G3]])
; CHECK:      call i1 @cqrt_measure_i1(i32 %[[T]])
; NEG-NOT: = select
; NEG-NOT: = icmp
; NEG-NOT: = xor

define range(i32 0, 2) i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %4 = icmp sgt i32 %1, 3
  %5 = icmp eq i32 %2, 2
  %6 = select i1 %4, i1 %5, i1 false
  %7 = icmp slt i32 %3, 7
  %8 = xor i1 %6, %7
  %9 = select i1 %6, double 2.200000e-01, double 3.300000e-01
  %10 = select i1 %8, double 1.100000e-01, double %9
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %10) #2
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11) #3
  %13 = zext i1 %12 to i32
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

define range(i32 0, 2) i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %4 = icmp sgt i32 %1, 3
  %5 = icmp eq i32 %2, 2
  %6 = select i1 %4, i1 %5, i1 false
  %7 = icmp slt i32 %3, 7
  %8 = xor i1 %6, %7
  %9 = select i1 %6, double 2.200000e-01, double 3.300000e-01
  %10 = select i1 %8, double 1.100000e-01, double %9
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %10) #2
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11) #3
  %13 = zext i1 %12 to i32
  ret i32 %13
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
