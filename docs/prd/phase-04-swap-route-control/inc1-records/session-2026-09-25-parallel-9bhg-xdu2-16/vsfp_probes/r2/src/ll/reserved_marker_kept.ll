declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

; A module that DEFINES a reserved-namespace symbol with a pure (empty) body. Its call
; has no result, touches no memory and terminates, so by ATTRIBUTES and by BODY it is
; side-effect-free; the call is nevertheless the user's (or the front end's) and must
; not be deleted.
define void @__cq_marker() {
  ret void
}

define i32 @main(i32 %m) {
  %lo = trunc i32 %m to i1
  %b = call i1 @cq_theta_i1(i1 %lo, double 5.000000e-01)
  call void @__cq_marker()
  %p = select i1 %b, i32 9, i32 4
  %b2 = call i1 @cq_theta_i1(i1 %b, double 7.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b2)
  %mz = zext i1 %mm to i32
  ret i32 %mz
}
