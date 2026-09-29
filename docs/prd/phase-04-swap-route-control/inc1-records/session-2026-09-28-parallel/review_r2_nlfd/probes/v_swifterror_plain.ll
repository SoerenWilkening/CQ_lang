define swiftcc i32 @h2(ptr swifterror %e, i32 %x) noinline {
  ret i32 %x
}
define swiftcc i32 @h(ptr swifterror %e, i32 %a) noinline {
  %r = call swiftcc i32 @h2(ptr swifterror %e, i32 %a)
  %r2 = add i32 %r, 1
  ret i32 %r2
}
