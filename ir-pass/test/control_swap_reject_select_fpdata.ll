; control_swap_reject_select_fpdata.ll — DECLINE: an fp-DATA select (4.4 WI-1
; gate 4 FP-use fence; staged out, §16.4). An f64 result used as DATA (not an
; angle) is — in principle — a mux, but shipping the f64 copy ABI reverses the
; binding `cq_runtime.h` no-FP-twins invariant ("the 5 INTEGER widths only — an
; FP merge phi under tainted control is categorically an angle, never data, the
; f64 miscompile family") and is safe only once the §3.2 angle gate is
; independently cleared. So it declines `control flow` until the fp-data accept
; path lands.
;
; `%sel` is a tainted-condition f64 select; both operands are tainted f64
; handles, and the result is MEASURED (a data sink, NOT a rotation arg-1), so
; gate 3 passes — the decline is the gate-4 `isFPOrFPVectorTy` fence, which fires
; BEFORE the width check (the f64 trap: f64 has a valid ABI width yet is treated
; as an angle).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qb  = fadd double %q, 1.000000e+00              ; a distinct tainted f64 data value
  %c   = fcmp ogt double %q, 5.000000e+00          ; tainted condition (ogt in scope)
  %sel = select i1 %c, double %q, double %qb       ; f64 DATA mux
  %m   = call double @cq_measure_f64(double %sel)  ; data sink (NOT an angle)
  ret double %m
}
