; r1A probe A1e: PRE-EXISTING reserved-namespace control -- the module DEFINES an
; ABI adjoint symbol the pass itself emits (a no-op body). No clone involved.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @slice(i32 %m) {
entry:
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %c = icmp eq i32 %p, 6
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 3.141590e+00)
  br label %merge
merge:
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %mq
}

define void @cq_template_mul_i32_hl_unc(i32 %o, i32 %x, i32 %l) noinline {
  ret void
}
