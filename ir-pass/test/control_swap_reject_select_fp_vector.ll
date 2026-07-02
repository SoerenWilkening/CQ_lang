; control_swap_reject_select_fp_vector.ll — DECLINE (fp-data-select-PRD §5
; matrix 5): an fp VECTOR select (`<2 x double>`). The gate-4 fp-data accept is
; SCALAR-only (`isFloatingPointTy`, deliberately NOT `isFPOrFPVectorTy` on the
; accept side): there is no vector copy primitive, and a vector select is not
; routable scalar data. Hand-written .ll shape (-O1 C rarely produces it): the
; vector arrives via escape-whitelisted casts of a tainted i64.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define i64 @example(i64 %u0) {
entry:
  %q   = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %c   = icmp sgt i64 %q, 5
  %qe  = zext i64 %q to i128                       ; tainted i128 (whitelisted cast)
  %v   = bitcast i128 %qe to <2 x double>          ; tainted fp VECTOR
  %sel = select i1 %c, <2 x double> %v, <2 x double> zeroinitializer
  %sb  = bitcast <2 x double> %sel to i128
  %st  = trunc i128 %sb to i64                     ; back to a measurable handle
  %m   = call i64 @cq_measure_sll(i64 %st)
  ret i64 %m
}
