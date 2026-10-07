declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i32 @cq_theta_i32(i32, double)
declare i32 @cq_measure_i32(i32)

define i32 @f80_int(x86_fp80 noundef nofpclass(nan inf) %x, i32 noundef %i, x86_fp80 noundef nofpclass(nan inf) %c) {
entry:
  %bits = bitcast x86_fp80 %x to i80
  %small = trunc i80 %bits to i32
  %v = add i32 %i, 7
  %sum = add i32 %small, %v
  %cmp = fcmp olt x86_fp80 %x, %c
  %r = select i1 %cmp, i32 %sum, i32 %v
  ret i32 %r
}

define i32 @main(x86_fp80 noundef %x, i32 noundef %i, x86_fp80 noundef %c) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %x, double 0.25)
  %p = call i32 @cq_theta_i32(i32 %i, double 0.5)
  %r = call i32 @f80_int(x86_fp80 %q, i32 %p, x86_fp80 %c)
  %m = call i32 @cq_measure_i32(i32 %r)
  ret i32 0
}
