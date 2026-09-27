define i32 @pure(i32 %x) {
  %y = mul i32 %x, 3
  ret i32 %y
}
define i32 @main(i32 %a) {
  %u = call i32 @pure(i32 %a)
  %c = icmp sgt i32 %a, 3
  br i1 %c, label %t, label %m
t:
  %v = call i32 @pure(i32 7)
  br label %m
m:
  ret i32 0
}
