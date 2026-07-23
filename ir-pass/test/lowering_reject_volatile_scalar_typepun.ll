; lowering_reject_volatile_scalar_typepun.ll — DECLINE PIN (bd zco4): the volatile
; scalar-local SSA promotion must NOT fire when an access TYPE-PUNS the slot (here
; a `load volatile i64` of a `double` alloca) — a bit-reinterpreting view is the
; promoteFp80Union / union-bit-pattern domain, not the exact-type scalar
; accumulator's (Gate 4: every load result / store value type must equal the
; allocated type). Left untouched, the tainted `double` store rides the existing
; loud decline. If promotion over-fired, PromoteMemToReg would have no defined
; reaching value for the i64 view and the module would either miscompile or the
; store would vanish and compile — this test pins the safe decline instead.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %z = alloca double, align 8
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  store volatile double %q, ptr %z, align 8
  %bits = load volatile i64, ptr %z, align 8    ; mixed-width view — no promotion
  %v = load volatile double, ptr %z, align 8
  %m = call double @cq_measure_f64(double %v)
  ret double %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
