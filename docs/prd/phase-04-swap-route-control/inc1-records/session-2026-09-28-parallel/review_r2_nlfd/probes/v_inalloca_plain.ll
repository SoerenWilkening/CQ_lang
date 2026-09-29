define i32 @h2(ptr inalloca(i32) %s) noinline {
  %x = load i32, ptr %s
  ret i32 %x
}
define i32 @h(ptr inalloca(i32) %s) noinline {
  %r = call i32 @h2(ptr inalloca(i32) %s)
  %r2 = add i32 %r, 1
  ret i32 %r2
}
