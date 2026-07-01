; lowering_byref_remquo_hl_f64.ll — bd g387: cross_binary _hl shape.
; remquo(x, 3.0, *quo) with x tainted and the divisor a classical literal → the
; `_hl` shape of BOTH the same_binary primary (cq_template_remquo_f64_hl) and the
; NEW cross_binary secondary (cq_template_remquoquo_f64_to_i32_hl). The classical
; operand is the fp `from` width (double); the quotient result is i32.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cq_template_remquo_f64_hl(i32 %[[X:[a-zA-Z0-9_.]+]], double 3.000000e+00)
; CHECK:     call i32 @cq_template_remquoquo_f64_to_i32_hl(i32 %[[X]], double 3.000000e+00)
;
; CHECK-NOT: alloca
; CHECK-NOT: load
; CHECK-NOT: call {{.*}}@remquo(
; CHECK-NOT: @cq_byref_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @cq_measure_si32(i32)
declare double @remquo(double, double, ptr)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)

define void @ex() {
entry:
  %qp = alloca i32, align 4
  %x = call double @cq_theta_f64(double 0.000000e+00, double 5.000000e-01)
  call void @llvm.lifetime.start.p0(i64 4, ptr %qp)
  %r = call double @remquo(double %x, double 3.000000e+00, ptr %qp)
  %rr = call double @cq_measure_f64(double %r)
  %qv = load i32, ptr %qp, align 4
  %rq = call i32 @cq_measure_si32(i32 %qv)
  call void @llvm.lifetime.end.p0(i64 4, ptr %qp)
  ret void
}
