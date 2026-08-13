; spec_cache_two_masks.ll — Phase 6.2 WI-2.4: two call sites of the SAME callee
; with DIFFERENT taint signatures synthesize TWO DISTINCT clones. `f(tainted,
; classical)` → mask `0b01` → `@__cq_q_f_01`; `f(classical, tainted)` → mask
; `0b10` → `@__cq_q_f_10`. The cache key is `(callee, mask)`, NOT `callee` — the
; prototype's `Function*`-only key (C7) would collapse both onto one clone (the
; over-accept class). The two clones are not merely differently named: the body
; lowers DIFFERENTLY per mask — `_01` makes arg0 the handle (`add_hl(%x, %y)`),
; `_10` makes arg1 the handle (`add_hl(%y, %x)`), the classical side passing
; through each time — so the distinction is semantic, not cosmetic.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %x, i32 %y) {
entry:
  %s = add i32 %x, %y
  ret i32 %s
}

define void @example(i32 %u0, i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r1 = call i32 @f(i32 %q, i32 %c)
  %r2 = call i32 @f(i32 %c, i32 %q)
  %m1 = call i32 @cq_measure_si32(i32 %r1)
  %m2 = call i32 @cq_measure_si32(i32 %r2)
  ret void
}

; Two sites, two distinct masks → two distinct retargets (handle in arg0 vs arg1).
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[R1:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_f_01(i32 %[[H]], i32 %c)
; CHECK:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_f_10(i32 %c, i32 %[[H]])
;
; Mask-01 clone: arg0 is the handle, arg1 (%y) the classical pass-through.
; CHECK:     define internal i32 @__cq_q_f_01(i32 %x, i32 %y)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %x, i32 %y)
;
; Mask-10 clone: arg1 is the handle, arg0 (%x) the classical pass-through — the
; OPPOSITE operand orientation, proving the mask drives the lowering, not just
; the name (C7 — no coarse-key collapse).
; CHECK:     define internal i32 @__cq_q_f_10(i32 %x, i32 %y)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %y, i32 %x)
