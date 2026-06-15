; control_swap_reject_select_vector.ll — DECLINE: a VECTOR-result select (4.4
; WI-1 gate 4 width gate, the null-callee trap). A `<2 x i32>` result is not
; routable scalar-integer data: the WI-3 emitter could mint no alloc/copy symbol
; for it (`abiWidthFromType` returns "" → a null `FunctionCallee` AFTER the merge
; bracket would already be emitted — a crash-on-valid-input, violating
; detect-before-mutate). Gate 4's `!isIntegerTy()` arm (a vector is not a scalar
; integer) declines it `control flow`, AFTER the FP-use fence.
;
; The `<2 x i32>` arrives via the escape-whitelisted `bitcast` of a tainted i64
; (the same path ArmClassify's criterion-3 width check guards for a br merge).
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
  %v   = bitcast i64 %q to <2 x i32>                       ; tainted vector (whitelisted)
  %sel = select i1 %c, <2 x i32> %v, <2 x i32> zeroinitializer  ; vector-result mux
  %sb  = bitcast <2 x i32> %sel to i64                     ; back to a measurable handle
  %m   = call i64 @cq_measure_sll(i64 %sb)
  ret i64 %m
}
