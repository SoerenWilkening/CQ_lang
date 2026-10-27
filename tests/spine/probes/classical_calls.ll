; calls::classify: calls with no quantum involvement stay ordinary calls in a tainted function (an
; external declaration, a known library function, a classical intrinsic); a quantum intrinsic is a
; template; a cq_phi under no quantum predicate is deleted (rule 12; the pred double deletes it).
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare void @cq_phi(double)
declare i32 @ext(i32)
declare i32 @puts(ptr)
declare double @llvm.fabs.f64(double)
@s = private constant [3 x i8] c"hi\00"

define double @classical_calls(double %x0, double %t, i32 %c, double %d) {
  %e = call i32 @ext(i32 %c)
  %p = call i32 @puts(ptr @s)
  %a = call double @llvm.fabs.f64(double %d)
  %x = call double @cq_theta_f64(double %x0, double %a)
  call void @cq_phi(double %t)
  %q = call double @llvm.fabs.f64(double %x)
  %r = call double @cq_measure_f64(double %q)
  ret double %r
}
; CHECK classical_calls: call i32 @ext(i32 %{{c}})
; CHECK classical_calls: call i32 @puts(ptr @s)
; CHECK classical_calls: call double @llvm.fabs.f64(double %{{d}})
; CHECK classical_calls: @cq_template_fabs_f64(i32
; CHECK-COUNT classical_calls: cq_phi 0
; CHECK-COUNT classical_calls: rz_i1 0
