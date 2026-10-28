; cq-6ady: plain fp operations of a lowered module that touches the fp environment run in the default one
target triple = "x86_64-apple-macosx16.0.0"
define double @d_up(double %a, double %b) {
  %m = call i32 @fesetround(i32 2048)
  %r = fadd double %a, %b
  ret double %r
}
define i32 @d_flags(double %a, double %b) {
  %c = call i32 @feclearexcept(i32 61)
  %r = fdiv double %a, %b
  %f = call i32 @fetestexcept(i32 61)
  ret i32 %f
}
define double @d_constrained(double %a, double %b) {
  %m = call i32 @fesetround(i32 2048)
  %r = call double @llvm.experimental.constrained.fadd.f64(double %a, double %b, metadata !"round.dynamic", metadata !"fpexcept.strict") #0
  ret double %r
}
declare i32 @fesetround(i32)
declare i32 @feclearexcept(i32)
declare i32 @fetestexcept(i32)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)
attributes #0 = { strictfp }
