; spec_reject_qram_read_alloca.ll — bd 20xt.4 Inc 1 (over-accept probe): a
; tainted-index read off an ALLOCA (a Shadow-shaped local array) inside a spec-clone
; body is NOT a const-global QROM read. The Phase-6 spec-clone QROM path admits ONLY
; a GLOBAL origin (`qromReadShapeInScope` requires `Origin.Kind == Global`); a mutable
; local array is the Phase-7.5 Shadow-store ABI (`cqrt_qram_store`/`_load` with an
; alloca handle + a whole-DAG LIFO store reversal), which the Bennett-clone forward
; stream does NOT model — so `scanBody` keeps the loud non-reversibilizable decline
; rather than silently lowering an alloca read as if it were an immutable table.
; `opt` exits non-zero. (This fences the two QRAM ABIs apart in the spec-clone path.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define internal double @lookup(double %x) {
  %a = alloca [4 x double], align 16
  %i = fptosi double %x to i32
  %m = and i32 %i, 3
  %idx = zext i32 %m to i64
  %p = getelementptr inbounds [4 x double], ptr %a, i64 0, i64 %idx
  %v = load double, ptr %p, align 8
  %r = fadd double %v, %x
  ret double %r
}

define double @example(double %u) {
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @lookup(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction)
