; r19 — AREA 5 (the STOP RULE, round-2 edition): the rail's GRANDPARENT is
; round-2-tainted but the parent is an OUT-OF-PLACE template result, so the
; measured value is a DIFFERENT register. `railWireNamesBackward` must stop at
; the template and this must ACCEPT.
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
  %w = xor i32 %y, 9
  %x = trunc i32 %w to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %a = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %a)
  %t = add i32 %m, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }
