; lowering_predmux_leave_speccall_weak.ll — DECLINE probe: a weak callee reached
; under NESTED tainted control declines loudly and is never cloned. Originally
; (bd adia Rule-13 board, the CONFIRMED fence gap) this pinned the E4 pending-spec
; pure-callee proof `hasExactDefinition()` — an INTERPOSABLE definition
; (weak_any/linkonce_any/common/extern_weak) may be replaced by the linker at
; stage 3, so a purity/termination proof read off the module-local body must never
; be baked into the speculated hoist and the Bennett clone (verify-clean).
;
; UPDATE (bd gxhi): the SAME interposability hazard is now caught EARLIER, at
; `detectSpecializations` — `scanBody` requires `hasExactDefinition()`, and the
; spec-scan pre-pass runs BEFORE `lowerControlRegions`, so it MASKS the control
; envelope (the coshl-family ordering) and the loud spec-interposable decline
; fires first, char-for-char below. The E4 `isSpeculatablePureCalleeBodyImpl`
; fence remains as defense-in-depth (it would fire were the spec-scan ever
; bypassed). NOTE: `hasExactDefinition()` ALSO declines weak_odr/linkonce_odr/
; available_externally (they `mayBeDerefined`), not only this arbitrary-replacement
; `weak_any` case — a safe over-decline. The direct-call analogue with no control
; region is pinned by spec_reject_weak_callee.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee has a non-link-exact definition (interposable/derefinable linkage); the linker may bind a different body
; CHECK-NOT: @__cq_q_purefn
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define weak i32 @purefn(i32 %a) {
  %t = mul i32 %a, 3
  %r = add i32 %t, 7
  ret i32 %r
}
define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @purefn(i32 %q)
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
