; spec_single_adjoint.ll — Phase 6.1 WI-1.8: the Bennett-wrap correctness
; invariants asserted on the post-`specialize` IR (DD-2 / DD-3):
;   (a) EXACTLY one adjoint per clone forward gate — a two-op body (`(a+1)*3`)
;       has TWO forward `cq_template_*` and EXACTLY TWO `_unc` adjoints (no
;       double-uncompute: the per-op Phase-5 `_unc` and the whole-body Bennett
;       reverse never both fire on the same gate);
;   (b) the clone's rails are ABSENT from the original module taint and are never
;       selected by the `:115` whole-DAG terminal walk — the caller-side
;       uncompute frees NO clone rail (every `cqrt_free` lives INSIDE the clone,
;       emitted by the Bennett wrap; the C-Taint disjoint-set boundary);
;   (c) the result rail is the LAST forward call, copied out BEFORE the reverse
;       (which zeroes it in place), and every scratch free FOLLOWS the complete
;       reverse chain (DD-3 ordering).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck --check-prefix=COUNT %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @affine(i32 %a) {
entry:
  %t = add i32 %a, 1
  %y = mul i32 %t, 3
  ret i32 %y
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @affine(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; (a)+(c) the exact clone shape: two forward gates, copy-out of the LAST one
;         BEFORE the reverse, the two adjoints in LIFO order, then the two frees
;         AFTER the complete reverse, then `ret` the basis copy.
; CHECK:       define internal i32 @__cq_q_affine_1(i32 %a)
; CHECK:       %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %a, i32 1)
; CHECK-NEXT:  %[[MUL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[ADD]], i32 3)
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[MUL]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cq_template_mul_i32_hl_unc(i32 %[[MUL]], i32 %[[ADD]], i32 3)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[ADD]], i32 %a, i32 1)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[ADD]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[MUL]])
; CHECK-NEXT:  ret i32 %[[OUT]]

; (a) EXACTLY two `_unc` CALL sites module-wide (the clone's two gate adjoints —
;     no double-uncompute), and (b) EXACTLY two `cqrt_free` CALL sites (the
;     clone's two scratch rails — the caller-side uncompute frees no clone rail).
;     Call-specific patterns so the `declare … _unc`/`declare … cqrt_free` lines
;     are not miscounted.
; COUNT-COUNT-2: call void @{{.*}}_unc(
; COUNT-NOT:     call void @{{.*}}_unc(
; COUNT-COUNT-2: call void @cqrt_free(
; COUNT-NOT:     call void @cqrt_free(
