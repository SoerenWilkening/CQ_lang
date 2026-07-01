declare { double, i32 } @llvm.frexp.f64.i32(double)
define {double,i32} @t(double %x){ %r = call {double,i32} @llvm.frexp.f64.i32(double %x)
 ret {double,i32} %r }
