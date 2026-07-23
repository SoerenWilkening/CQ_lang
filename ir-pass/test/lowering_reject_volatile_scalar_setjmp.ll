; lowering_reject_volatile_scalar_setjmp.ll — DECLINE PIN (bd zco4): the volatile
; scalar-local SSA promotion must NOT fire in a function that calls a
; `returns_twice` routine (setjmp). `volatile` on a stack local in a setjmp
; function is the C-standard mechanism that keeps the value in MEMORY across a
; longjmp (a non-volatile local is indeterminate after longjmp — that is WHY the
; idiom needs volatile); promoting it to a register would drop the value longjmp
; must restore. This gate is LOAD-BEARING: with the alloca's users otherwise a
; clean promotable scalar, ONLY the returns_twice check keeps it in memory — and
; verified, if promotion fired here the module would compile (a silent soundness
; violation). A pure libm body never calls setjmp, so over-declining costs nothing.
; Left untouched, the tainted store rides the existing loud decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @setjmp(ptr) returns_twice

define double @probe(double %u0, ptr %jb) {
entry:
  %z = alloca double, align 8
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %sj = call i32 @setjmp(ptr %jb)               ; returns_twice — no promotion
  store volatile double %q, ptr %z, align 8
  %v = load volatile double, ptr %z, align 8
  %m = call double @cq_measure_f64(double %v)
  ret double %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
