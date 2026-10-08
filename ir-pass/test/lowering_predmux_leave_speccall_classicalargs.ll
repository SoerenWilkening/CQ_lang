; lowering_predmux_leave_speccall_classicalargs.ll — ACCEPT (dm7f.16.1).
; The shared owner retains total purefn(u)=3*u+7 (wrapping i32).
; Output is purefn(u) for q>10, q for 5<q<=10, and zero otherwise.
; Classical calls inside nested quantum value arms use the common edge mux.
; Historical filename retained.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @purefn(i32 %a) {
  %t = mul i32 %a, 3
  %r = add i32 %t, 7
  ret i32 %r
}
define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @purefn(i32 %u)          ; classical arg — NOT pending-spec
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}

; CHECK-LABEL: define i32 @example(
; CHECK: %[[U:[a-zA-Z0-9_.]+]] = freeze i32 %u
; CHECK: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[U]])
; CHECK: %[[V:[a-zA-Z0-9_.]+]] = call i32 @purefn(i32 %[[U]])
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 10)
; CHECK: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[V]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G:[a-zA-Z0-9_.]+]], i32 %[[S]], i32 %[[INNER:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[Q]], i32 %[[INNER]])
; CHECK: call void @cqrt_copy_i32_controlled(i32 %[[OUTG:[a-zA-Z0-9_.]+]], i32 %[[INNER]], i32 %[[OUT:[a-zA-Z0-9_.]+]])
; CHECK: %[[ZERO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[OUTG]], i32 %[[ZERO]], i32 %[[OUT]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[OUT]])
