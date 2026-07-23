; lowering_reject_volatile_scalar_undef_load.ll — DECLINE PIN (bd zco4): the
; volatile scalar-local SSA promotion must NOT fire when a load can execute before
; ANY store on some path from entry (Gate 5: every load must be store-defined, so
; PromoteMemToReg never materializes an `undef` reaching definition). Here `%pre`
; loads the alloca before it is ever stored — reading uninitialized memory (UB in
; C, and never a real accumulator). Promoting it would invent an `undef` quantum
; angle; the Prime-Directive decline leaves the alloca in memory and the tainted
; store rides the existing loud decline. This gate is LOAD-BEARING: with the
; alloca otherwise a clean promotable scalar, ONLY the undef-safety check keeps it
; in memory — verified, if promotion fired the module would compile.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %z = alloca double, align 8
  %pre = load volatile double, ptr %z, align 8   ; load precedes any store — undef
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  store volatile double %q, ptr %z, align 8
  %v = load volatile double, ptr %z, align 8
  %s = fadd double %v, %pre
  %m = call double @cq_measure_f64(double %s)
  ret double %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
