; j01 — THE LEG-2 BARRIER CASE WITH A FORWARD-NAME MEASURE: a loop-carried rail
; whose seed theta re-executes each trip (the barrier), with a forward theta and
; its measurement AFTER the select in the body. The fix deliberately does not
; collect forward names — measure whether that is sound here.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  br label %hdr
hdr:
  %i = phi i32 [ 0, %entry ], [ %in, %hdr ]
  %ph = phi i1 [ false, %entry ], [ %c, %hdr ]
  %acc = phi i32 [ 0, %entry ], [ %na, %hdr ]
  %b = call i1 @cq_theta_i1(i1 %ph, double 5.000000e-01)
  %a = select i1 %b, i32 2, i32 5
  %c = call i1 @cq_theta_i1(i1 %b, double 3.000000e-01)
  %mc = call i1 @cq_measure_i1(i1 %c)
  %zc = zext i1 %mc to i32
  %ma = call i32 @cq_measure_si32(i32 %a)
  %t1 = add i32 %acc, %zc
  %na = add i32 %t1, %ma
  %in = add i32 %i, 1
  %e = icmp eq i32 %in, 3
  br i1 %e, label %out, label %hdr
out:
  ret i32 %na
}
