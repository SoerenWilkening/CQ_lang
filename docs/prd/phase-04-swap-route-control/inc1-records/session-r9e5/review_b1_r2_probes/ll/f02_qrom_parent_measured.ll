; f02 — the rail's parent is a const-global QROM read (a fresh rail); its name is
; measured before the select.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_theta_si64(i64, double)
declare i64 @cq_measure_si64(i64)
@tab = private unnamed_addr constant [4 x i8] c"\01\00\01\00", align 1
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.000000e-01)
  %i = and i32 %q, 3
  %p = getelementptr inbounds [4 x i8], ptr @tab, i32 0, i32 %i
  %v = load i8, ptr %p, align 1
  %t = trunc i8 %v to i1
  %b = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %t)
  %a = select i1 %b, i32 7, i32 9
  %zz = zext i1 %mm to i32
  %m = call i32 @cq_measure_si32(i32 %a)
  %r = add i32 %m, %zz
  ret i32 %r
}
