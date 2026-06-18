; spec_cache_hit.ll — Phase 6.2 WI-2.5: two call sites with the SAME `(callee,
; mask)` share ONE clone (cache hit). Both sites call `f` with the same tainted
; arg0 → mask `0b01`... → identical key `(f, 1)`. The first site MISSES (clone +
; lower + Bennett wrap), records the clone in the `(callee, mask)` cache; the
; second site HITS and reuses the existing clone via `setCalledFunction` — NO
; re-clone. Exactly one `define internal @__cq_q_f_1` is synthesized and BOTH
; sites retarget to it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %x) {
entry:
  %s = mul i32 %x, 3
  ret i32 %s
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r1 = call i32 @f(i32 %q)
  %r2 = call i32 @f(i32 %q)
  %m1 = call i32 @cq_measure_si32(i32 %r1)
  %m2 = call i32 @cq_measure_si32(i32 %r2)
  ret void
}

; BOTH sites retarget to the SAME clone — a broken (callee-only or re-clone) cache
; would point the second site at a distinct `@__cq_q_f_1.1`, failing this count.
; CHECK:         %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-COUNT-2: call i32 @__cq_q_f_1(i32 %[[H]])
;
; Exactly one clone definition, Bennett-wrapped once.
; CHECK:     define internal i32 @__cq_q_f_1(i32 %x)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %x, i32 3)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP]],
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[OP]], i32 %x, i32 3)
; CHECK:     ret i32
;
; No duplicate clone (the cache prevented a second `cloneFor`).
; CHECK-NOT: define internal i32 @__cq_q_f_1.
