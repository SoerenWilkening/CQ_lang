; control_angle_select_ry_tree_cmp_fresh.ll — ACCEPT (bd test_C_libtooling-dm7f.54):
; a Ry ANGLE SELECT on a FRESH target under a conjunction of two compares.
;
;     int x = 0, y = 0; bool t = 0;
;     cq_theta(&x, 1.0); cq_theta(&y, 0.5);
;     cq_theta(&t, (x == 1 && y == 2) ? 0.7 : 0.3);
;
; The network mints one flag per compare leaf, ANDs them onto `g`, and strips
; in exact LIFO order (node, then leaves in reverse mint order), all after the
; closing `x(g)`. The target is the fresh rail of the literal seed (`nomerge`).
; ANALYTIC: g = (x==1) ∧ (y==2); g = 1 -> t = Ry(.7)|0>, else Ry(.3)|0>; x and
; y are never relabelled, so each `_unc` returns its flag to |0> exactly.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %x = call i32 @cq_theta_si32(i32 0, double 1.000000e+00) #0
  %y = call i32 @cq_theta_si32(i32 0, double 5.000000e-01) #0
  %cx = icmp eq i32 %x, 1
  %cy = icmp eq i32 %y, 2
  %c = select i1 %cx, i1 %cy, i1 false
  %ang = select i1 %c, double 0x3FE6666666666666, double 3.000000e-01
  %t = call i1 @cq_theta_i1(i1 false, double %ang) #0
  %mx = call i32 @cq_measure_si32(i32 %x)
  %my = call i32 @cq_measure_si32(i32 %y)
  %mt = call i1 @cq_measure_i1(i1 %t)
  %zt = zext i1 %mt to i32
  %s1 = add i32 %mx, %my
  %s = add i32 %s1, %zt
  ret i32 %s
}

attributes #0 = { nomerge nounwind }

; CHECK:      %[[X:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[X]], double 1.000000e+00)
; CHECK-NEXT: %[[Y:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Y]], double 5.000000e-01)
; CHECK-NEXT: %[[FX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[X]], i32 1)
; CHECK-NEXT: %[[FY:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Y]], i32 2)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FX]], i32 %[[FY]], i32 %[[G]])
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[G]], i32 %[[T]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[G]], i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FX]], i32 %[[FY]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FY]], i32 %[[Y]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[FY]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FX]], i32 %[[X]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[FX]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[X]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Y]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[T]])

; NEG-NOT: = select
; NEG-NOT: = icmp
; NEG-NOT: cq_theta_
