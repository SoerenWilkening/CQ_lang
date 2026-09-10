; x02 — CONTROL for x01: the SIBLING deleted, nothing else changed. Must ACCEPT.
@tbl = internal unnamed_addr constant [8 x i1] [i1 true, i1 false, i1 true, i1 true, i1 false, i1 true, i1 false, i1 true]
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @qrom_rail(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [8 x i1], ptr @tbl, i64 0, i64 %i
  %x = load i1, ptr %g
  %b = call i1 @cq_theta_i1(i1 %x, double 2.500000e-01)
  %a = select i1 %b, i32 2, i32 5
  %m1 = call i32 @cq_measure_si32(i32 %a)
  %m2 = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m2 to i32
  %s = add i32 %m1, %z
  ret i32 %s
}
