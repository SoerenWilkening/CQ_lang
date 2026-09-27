@g = global i32 0
@ga = global i32 0
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @vload(i32 %x) { %v = load volatile i32, ptr @g
  %r = add i32 %v, %x
  ret i32 %r }
define i32 @aload(i32 %x) { %v = load atomic i32, ptr @ga acquire, align 4
  %r = add i32 %v, %x
  ret i32 %r }
define i32 @mload(i32 %x) { %v = load atomic i32, ptr @ga monotonic, align 4
  %r = add i32 %v, %x
  ret i32 %r }
define i32 @uload(i32 %x) { %v = load atomic i32, ptr @ga unordered, align 4
  %r = add i32 %v, %x
  ret i32 %r }
define i32 @unr(i32 %x) { %c = icmp eq i32 %x, 0
  br i1 %c, label %a, label %b
a: unreachable
b: ret i32 %x }
define i32 @divz(i32 %x, i32 %y) { %r = sdiv i32 %x, %y
  ret i32 %r }
define i32 @nr(i32 %x) noreturn { ret i32 %x }
define i32 @plain(i32 %x) { %r = mul i32 %x, 3
  ret i32 %r }
define i32 @main(i32 %a) {
  %q = call i32 @cq_theta_si32(i32 0, double 0.5)
  %1 = call i32 @vload(i32 %a)
  %2 = call i32 @aload(i32 %a)
  %3 = call i32 @mload(i32 %a)
  %4 = call i32 @uload(i32 %a)
  %5 = call i32 @unr(i32 %a)
  %6 = call i32 @divz(i32 %a, i32 0)
  %7 = call i32 @plain(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
