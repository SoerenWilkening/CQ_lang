; control_swap_select_polarity.ll — ACCEPT: polarity-canonicalized condition (the
; §6.7 probe). `clang -O1` canonicalizes `if (q != 5)` to `icmp eq` and may swap
; the select's true/false operands. The emitter maps the TRUE operand (operand 1)
; to f=1 and the FALSE operand (operand 2) to ¬f, and mints the flag from the
; ACTUAL emitted predicate (`lowerCompareToFlag`), so an `eq`-canonicalized select
; lowers to the correctly-mapped stream — `cq_template_icmp_eq_i32_hl`, the TRUE
; operand (here the classical %x) copied on the flag, the FALSE operand (q) on
; ¬flag. No polarity-specific code path; the mapping just tracks the predicate.
;
; `(q==5) ? x : q` — true=x (classical, materialized first), false=q (handle).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = icmp eq i32 %q, 5
  %sel = select i1 %c, i32 %x, i32 %q       ; true=x, false=q (operands swapped)
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; the flag tracks the eq predicate; true operand (x) copied on the flag, false
; operand (q) on ¬flag — the materialize for the classical true operand allocs first:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[XH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: phi i32

; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
; ORD: call void @cqrt_copy_i32_controlled(
; ORD: call void @cqrt_x(
