; lowering_byref_remquo_f64.ll — bd g387: by-ref math out-param, remquo (binary).
; remquo(x,y,*quo): remainder returned, quotient bits written through an `int*`
; cell. The quotient is a function of BOTH operands → the NEW `cross_binary`
; ((fp,fp)->int) shape. QQ here (both x,y tainted): the primary lowers to
; `cq_template_remquo_f64` (same_binary) and the secondary to
; `cq_template_remquoquo_f64_to_i32` (cross_binary, bare-QQ base symbol).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cq_template_remquo_f64(i32 %[[X:[a-zA-Z0-9_.]+]], i32 %[[Y:[a-zA-Z0-9_.]+]])
; CHECK:     call i32 @cq_template_remquoquo_f64_to_i32(i32 %[[X]], i32 %[[Y]])
;
; CHECK-NOT: alloca
; CHECK-NOT: load
; CHECK-NOT: call {{.*}}@remquo(
; CHECK-NOT: @cq_byref_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)
declare double @remquo(double, double, ptr)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)

define i32 @ex() {
entry:
  %qptr = alloca i32, align 4
  %x = call double @cq_theta_f64(double 0.000000e+00, double 5.000000e-01)
  %y = call double @cq_theta_f64(double 0.000000e+00, double 3.000000e-01)
  call void @llvm.lifetime.start.p0(i64 4, ptr %qptr)
  %r = call double @remquo(double %x, double %y, ptr %qptr)
  %ri = fptosi double %r to i32
  %r1 = call i32 @cq_measure_si32(i32 %ri)
  %qv = load i32, ptr %qptr, align 4
  %r2 = call i32 @cq_measure_si32(i32 %qv)
  %sum = add i32 %r1, %r2
  call void @llvm.lifetime.end.p0(i64 4, ptr %qptr)
  ret i32 %sum
}
