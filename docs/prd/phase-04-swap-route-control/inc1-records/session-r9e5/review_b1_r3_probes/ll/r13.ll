; r13 — CONTROL for r12: the SIBLING deleted.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @main() {
entry:
  %arr = alloca [8 x i1], align 1
  call void @llvm.memset.p0.i64(ptr %arr, i8 0, i64 8, i1 false)
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %v = call i1 @cq_theta_i1(i1 true, double 3.000000e-01)
  %iw = sext i32 %q to i64
  %gs = getelementptr inbounds [8 x i1], ptr %arr, i64 0, i64 %iw
  store i1 %v, ptr %gs
  %gl = getelementptr inbounds [8 x i1], ptr %arr, i64 0, i64 2
  %x = load i1, ptr %gl
  %b = call i1 @cq_theta_i1(i1 %x, double 2.500000e-01)
  %a = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %a)
  %mm = call i1 @cq_measure_i1(i1 %b)
  %zz = zext i1 %mm to i32
  %t = add i32 %m, %zz
  ret i32 %t
}
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
