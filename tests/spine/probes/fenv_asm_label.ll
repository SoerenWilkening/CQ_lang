; tests/spine probe (CR rule 23; cq-ten4): a Mach-O asm label "\01_fesetround" names C's fesetround for taint, the
; spine's classify and eff-fenv alike (taint/FenvName.h): the classical fesetround(0) after a quantum one drops the mode
; rail, which leaked (live at exit) when only taint stripped the prefix. Hand-written.
; USERCHECK q
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @"\01_fesetround"(i32)
declare i32 @fesetround(i32)
define double @q(double %x0, double %t, double %y) {
  %x = call double @cq_theta_f64(double %x0, double %t)
  %b = fcmp olt double %x, 1.0
  %m = select i1 %b, i32 2048, i32 1024
  %s = call i32 @fesetround(i32 %m)
  %s2 = call i32 @"\01_fesetround"(i32 0)
  %z = fadd double %y, 1.0e-20
  %w = fadd double %z, %x
  %r = call double @cq_measure_f64(double %w)
  ret double %r
}
