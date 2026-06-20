; control_swap_reject_select_f16.ll — Phase 7.1 Increment D: the f16 analog of
; the f64 angle trap (control_swap_reject_select_fpdata.ll). A tainted-condition
; `select` whose data operands are `half` and whose result is MEASURED (a data
; sink, not a rotation arg-1) is — shape-for-shape — exactly what
; control_swap_select_i8.ll ACCEPTS as the 4.4 controlled-XOR copy merge. It must
; nonetheless DECLINE for f16: an FP merge under tainted control is categorically
; an angle, never data (the f64 miscompile family), so the gate-4
; `isFPOrFPVectorTy` fence fires and `copyFn("f16")` is null (no `cqrt_copy_f16`
; — WidthDispatch's isIntegerTy guard). Adding f16 as a recognized width must NOT
; open this door: f16 now has a valid ABI width yet stays an angle, the precise
; f16 restatement of the "non-empty width ≠ data" trap.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy

declare half @cq_theta_f16(half, double)
declare half @cq_measure_f16(half)

define half @example(half %u0) {
entry:
  %q   = call half @cq_theta_f16(half %u0, double 5.000000e-01)
  %qb  = fadd half %q, 0xH3C00                  ; a distinct tainted f16 data value
  %c   = fcmp ogt half %q, 0xH4500             ; tainted condition (ogt in scope)
  %sel = select i1 %c, half %q, half %qb       ; f16 DATA mux
  %m   = call half @cq_measure_f16(half %sel)  ; data sink (NOT an angle)
  ret half %m
}
