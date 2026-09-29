define i32 @h2(ptr preallocated(i32) %s, i32 %x) noinline {
  ret i32 %x
}
define i32 @h(ptr preallocated(i32) %s, i32 %a) noinline {
  %r = call i32 @h2(ptr preallocated(i32) %s, i32 %a)
  %r2 = add i32 %r, 1
  ret i32 %r2
}
