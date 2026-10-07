@table = private constant [4 x double] [double 1.0, double 2.0, double 3.0, double 4.0]
declare double @cq_theta_f64(double, double)
declare i32 @cq_theta_i32(i32, double)
declare double @cq_measure_f64(double)

define double @lookup(double noundef %x, i32 noundef %idx) {
entry:
  %bits = bitcast double %x to i64
  %low = trunc i64 %bits to i32
  %mix = xor i32 %low, %idx
  %small = and i32 %mix, 3
  %wide = zext i32 %small to i64
  %p = getelementptr inbounds [4 x double], ptr @table, i64 0, i64 %wide
  %r = load double, ptr %p, align 8
  ret double %r
}

define double @outer_lookup(double noundef %x, i32 noundef %idx) {
entry:
  %r = call double @lookup(double %x, i32 %idx)
  %v = fmul double %r, 2.0
  ret double %v
}

define i32 @main(double noundef %x, i32 noundef %idx) {
entry:
  %q = call double @cq_theta_f64(double %x, double 0.25)
  %i = call i32 @cq_theta_i32(i32 %idx, double 0.5)
  %r = call double @outer_lookup(double %q, i32 %i)
  %m = call double @cq_measure_f64(double %r)
  ret i32 0
}
