; cq-ltoq: classical CR §2 rows in a lowered module (run.py totalize_module)
target triple = "x86_64-apple-macosx16.0.0"
define i32 @t_udiv(i32 %a, i32 %b) {
  %r = udiv i32 %a, %b
  ret i32 %r
}
define i32 @t_urem(i32 %a, i32 %b) {
  %r = urem i32 %a, %b
  ret i32 %r
}
define i32 @t_sdiv(i32 %a, i32 %b) {
  %r = sdiv exact i32 %a, %b
  ret i32 %r
}
define i32 @t_srem(i32 %a, i32 %b) {
  %r = srem i32 %a, %b
  ret i32 %r
}
define i32 @t_shl(i32 %a, i32 %b) {
  %r = shl nuw nsw i32 %a, %b
  ret i32 %r
}
define i64 @t_ashr(i64 %a, i64 %b) {
  %r = ashr exact i64 %a, %b
  ret i64 %r
}
define i32 @t_fptosi(double %x) {
  %r = fptosi double %x to i32
  ret i32 %r
}
define i64 @t_fptoui(double %x) {
  %r = fptoui double %x to i64
  ret i64 %r
}
define i32 @t_fptoui80(x86_fp80 %x) {
  %r = fptoui x86_fp80 %x to i32
  ret i32 %r
}
define i32 @t_cttz(i32 %a) {
  %r = call i32 @llvm.cttz.i32(i32 %a, i1 true)
  ret i32 %r
}
define double @t_maxnum(double %a, double %b) {
  %r = call double @llvm.maxnum.f64(double %a, double %b)
  ret double %r
}
declare i32 @llvm.cttz.i32(i32, i1)
declare double @llvm.maxnum.f64(double, double)
