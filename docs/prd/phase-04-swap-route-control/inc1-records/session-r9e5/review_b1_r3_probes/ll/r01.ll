; r01 — AREA 1: the round-2 window with the rail as BOTH condition and TRUE ARM
; (the g08 shape). `materializeCopySource`'s read of the register as DATA is not
; one of the four recorded sites; the CopyRailRoot cnot is, so this asks whether
; the fix's one recorded read covers the whole region.
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @f(i32 %a) #0 { %s = add i32 %a, 100  ret i32 %s }
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 3
  br i1 %c0, label %arm, label %merge
arm:
  %r = call i32 @f(i32 4)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = call i32 @cq_measure_si32(i32 %y)
  br label %second
second:
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %c2 = call i1 @cq_theta_i1(i1 true, double 7.000000e-01)
  %a = select i1 %b, i1 %b, i1 %c2
  %za = zext i1 %a to i32
  %m = call i32 @cq_measure_si32(i32 %za)
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %t = add i32 %m, %zz
  %u = add i32 %t, %keep
  ret i32 %u
}
attributes #0 = { nounwind willreturn memory(none) }
