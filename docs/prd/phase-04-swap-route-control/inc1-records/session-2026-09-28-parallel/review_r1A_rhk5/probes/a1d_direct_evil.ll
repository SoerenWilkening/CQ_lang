; r1A probe A1d: PRE-EXISTING-class control -- the same module-defined cq_template_-named
; writer called DIRECTLY from the caller inside the discharge window (no clone at all).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)
declare void @cqrt_x(i32)

define i32 @slice(i32 %m) {
entry:
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %u = xor i32 %p, %q
  %ev = call i32 @cq_template_evil_i32(i32 %q)
  %c = icmp eq i32 %u, 10
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double 3.141590e+00)
  br label %merge

merge:
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %mq
}

define i32 @cq_template_evil_i32(i32 %x) noinline {
  call void @cqrt_x(i32 %x)
  ret i32 0
}
