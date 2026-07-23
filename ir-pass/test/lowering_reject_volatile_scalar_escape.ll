; lowering_reject_volatile_scalar_escape.ll — DECLINE PIN (bd zco4): the volatile
; scalar-local SSA promotion must NOT fire when the alloca's ADDRESS escapes (here
; passed to an unknown external call) — an escaped address admits writers the user
; scan cannot see, so promotion could drop or reorder a store an external observer
; relies on (Gate 2: every user must be a direct load/store of the alloca or a
; lifetime/dbg marker — no call-arg / gep / ptrtoint / cast / phi / select on the
; address). Left untouched, the tainted store rides the existing loud decline. The
; escaping call sits before the tainted store so the store is the sole blocker: if
; promotion over-fired the module would compile and this test would fail.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare void @sink(ptr)

define double @probe(double %u0) {
entry:
  %z = alloca double, align 8
  call void @sink(ptr nonnull %z)              ; address escapes — no promotion
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  store volatile double %q, ptr %z, align 8
  %v = load volatile double, ptr %z, align 8
  %m = call double @cq_measure_f64(double %v)
  ret double %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
