; control_swap_select_ret.ll — ACCEPT: the emitter adds NO measurement (Rule 5).
; The coherent-first invariant: the compiler never emits a measurement the user
; did not write. Here the select result escapes via `ret` (no user `cq_measure`),
; so the lowered stream must contain ZERO measure calls — `%sel` is RAUW'd to the
; |0> result rail `%out` and returned directly. Proves the controlled-XOR copy
; merge is a pure unitary insertion, never a measure-and-branch.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = icmp sgt i32 %q, 5
  %sel = select i1 %c, i32 %q, i32 %x
  ret i32 %sel
}

; the merge stream lands and %sel is RAUW'd to %out, returned directly:
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     ret i32 %[[OUT]]
; NO measurement is added by the emitter (Rule 5):
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq_measure
