; control_angle_select_ry_tree_shared_node_data.ll — ACCEPT (bd
; test_C_libtooling-dm7f.54, item C; review F1, revC54b/p3 — was a VERIFIER CRASH
; from plain C):
;
;     _Bool c = a && b; _Bool d = c || e;
;     cq_theta(&t, d ? .7 : .3);  int s = k + c;
;
; `c` (`select i1 %a, i1 %b, i1 false`) is an INTERIOR node of the angle tree AND
; has a data use. The round-1 binary pre-claimed it, so nothing lowered it and
; `opt` aborted on `select i32 %h, i32 %h2, i1 false`. Now `ControlDetect`
; pre-claims only nodes whose every use is inside an angle tree (a FIXPOINT over
; the tree nodes), so `c` stays an ordinary 4.4 data select; `lowerControlRegions`
; schedules the angle region BEFORE it, the angle network is minted from the
; LEAVES (`g = a ∧ b`, `g1 = g ∨ e`), and the data select then lowers `c`'s own
; value into `%out` (two controlled copies on the CNOT copy of `a`), which the
; `k + c` add reads. ANALYTIC: t = Ry(.7)|0> iff (a ∧ b) ∨ e, else Ry(.3)|0>;
; every network ancilla is undone by its mirror and freed at |0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[E:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[OUT:out[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_copy_i1_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[B]], i32 %[[OUT]])
; CHECK:      %[[G:g[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: %[[G1:g[0-9]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[G]], i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[E]], i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[G]], i32 %[[E]], i32 %[[G1]])
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[G1]], i32 %[[T]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[G1]], i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[G]], i32 %[[E]], i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[E]], i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[G]], i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call i32 @cq_template_zext_i1_to_i32(i32 %[[OUT]])
; NEG-NOT: = select
; NEG-NOT: cq_theta_

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #2
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 8.000000e-01) #2
  %5 = select i1 %2, i1 %3, i1 false
  %6 = select i1 %5, i1 true, i1 %4
  %7 = select i1 %6, double 0x3FE6666666666666, double 3.000000e-01
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %7) #2
  %9 = zext i1 %5 to i32
  %10 = add nsw i32 %9, %0
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8) #3
  %12 = zext i1 %11 to i32
  %13 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
