; the SAME module with the measure operand written as the theta's result — the
; program the source actually names once `u` is initialised.
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define i32 @main() {
  %1 = call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %2 = call i32 @cq_measure_si32(i32 noundef %1)
  ret i32 %2
}
