declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
  %1 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %2 = select i1 %1, i32 2, i32 5
  %3 = call i1 @cq_measure_i1(i1 %1)
  %4 = zext i1 %3 to i32
  %5 = call i1 @cq_measure_i1(i1 false)
  %6 = zext i1 %5 to i32
  %7 = add nuw nsw i32 %6, %4
  %8 = call i32 @cq_measure_si32(i32 %2)
  %9 = add nsw i32 %7, %8
  ret i32 %9
}
