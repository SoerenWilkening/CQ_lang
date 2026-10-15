; condtree_classical_leaf_reject_callee_quantum_return_nested.ll — DECLINE (bd
; test_C_libtooling-xdu2.13 / bd test_C_libtooling-3jru).
;
; The same refusal through TWO calls: `g` returns `h(k) + 1`, and `h` returns a
; `cq_theta` register. bd 3jru's `propagate` fixpoint taints `h`'s call inside
; `g`, so `g`'s `ret` is tainted and so is `g`'s call site (chains and recursion
; iterate to a fixpoint). Red on bc42274e.
;
; bd p3kd.21 (2026-10-14) — NOW AN ACCEPT; the file name and the DECLINE text
; above are history. The returning callee is a GATE SUBROUTINE (it holds
; `cq_theta`), so its call is compiled at the call site (SpecializeGateInline.h,
; trigger (c): a used register return) and the 3jru crossing no longer exists: the
; register is the caller's own. Measured: the lowered body is identical, call for
; call, to `clang -O1` of the same source with the helper force-inlined, on the
; pre-change binary (taint_reject_quantum_return_helper_arg.ll's twin). The CHECKs
; capture every rail and pin each operand, each `_unc` right before its
; `cqrt_free`, and the user's measurements (R11 r1 item 8: reviewer mutants M1-M3
; reading the handle id classically, deleting a `cq_measure`, or dropping an
; `_unc`, are killed). The 3jru refusal itself is unchanged and still pinned by
; taint_reject_quantum_return_fnptr.ll and
; spec_reject_predicted_classical_round2_return_crossing.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define internal i32 @slice(
; CHECK-NEXT: [[Q:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[R:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 %m)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[R]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 [[R]], i32 1)
; CHECK-NEXT: [[C1:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 [[Q]], i32 1)
; CHECK-NEXT: [[C2:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 [[R]], i32 %n)
; CHECK-NEXT: [[G:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 [[C1]], i32 [[C2]], i32 [[G]])
; CHECK-NEXT: [[OUT:%[0-9a-z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 [[G]], i32 [[OUT]], i32 10)
; CHECK-NEXT: call void @cqrt_x(i32 [[G]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 [[G]], i32 [[OUT]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 [[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 [[C1]], i32 [[C2]], i32 [[G]])
; CHECK-NEXT: call void @cqrt_free(i32 [[G]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[C2]], i32 [[R]], i32 %n)
; CHECK-NEXT: call void @cqrt_free(i32 [[C2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 [[C1]], i32 [[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 [[C1]])
; CHECK-NEXT: [[MA:%[0-9a-z_.]+]] = call i32 @cqrt_measure_i32(i32 [[OUT]])
; CHECK-NEXT: ret i32 [[MA]]
; CHECK-NOT: call {{.*}}@g(

define i32 @h(i32 %k) noinline {
  %t = call i32 @cq_theta_si32(i32 %k, double 7.000000e-01)
  ret i32 %t
}
define i32 @g(i32 %k) noinline {
  %v = call i32 @h(i32 %k)
  %w = add i32 %v, 1
  ret i32 %w
}
define internal i32 @slice(i32 %m, i32 %n) {
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %r = call i32 @g(i32 %m)
  %t = icmp sgt i32 %q, 1
  %c = icmp eq i32 %r, %n
  %a = and i1 %t, %c
  %s = select i1 %a, i32 10, i32 7
  %m1 = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m1
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
