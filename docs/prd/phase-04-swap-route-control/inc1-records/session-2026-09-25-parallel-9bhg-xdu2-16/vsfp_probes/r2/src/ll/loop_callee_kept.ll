declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

; No `mustprogress`: this loop may legitimately never terminate (x = x*3+1 mod 2^32
; need not reach 7), so a call to @spin is NOT removable even though its body writes
; no memory and its result is unused.
define i32 @spin(i32 %a, i32 %k) {
entry:
  br label %loop
loop:
  %x = phi i32 [ %k, %entry ], [ %x2, %loop ]
  %x2 = mul i32 %x, 3
  %x3 = add i32 %x2, 1
  %done = icmp eq i32 %x3, 7
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %x3
}

define i32 @main(i32 %m) {
  %lo = trunc i32 %m to i1
  %b = call i1 @cq_theta_i1(i1 %lo, double 5.000000e-01)
  %p = select i1 %b, i32 9, i32 4
  %t = call i32 @spin(i32 %p, i32 %m)
  %b2 = call i1 @cq_theta_i1(i1 %b, double 7.000000e-01)
  %mm = call i1 @cq_measure_i1(i1 %b2)
  %mz = zext i1 %mm to i32
  ret i32 %mz
}
