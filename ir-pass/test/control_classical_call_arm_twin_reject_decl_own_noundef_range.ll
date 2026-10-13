; control_classical_call_arm_twin_reject_decl_own_noundef_range.ll — DECLINE (batch 053,
; bd dm7f.26 decline neighbour).
; control_classical_call_arm_twin_accept_decl_noundef_return.ll with the `noundef` on
; the DECLARATION's own return instead of the call site:
; `declare noundef range(i32 0, 5) i32 @pb(i32 noundef)`. A wrapper twin
; (`freeze(pb(freeze x))`) can strip a CALL SITE's return contract, but not the
; declaration's: if `pb` returned a value outside `[0, 5)` that value would be poison
; in a `noundef` return, i.e. UB inside the call itself, and nothing proves the range
; for a bodyless callee (`returnAttrsHold` refuses a declaration's `range`; no
; vacuous proof). `declarationWrapperExists` (TwinTotality.h) answers false, the
; route answers Unsafe, and the 6.5 arm declines loudly.
; HONEST SCOPE: an unproven contract of an opaque callee, the "no implementation to
; lift" side of NORTHSTAR goal 1, unless the owner rules that a `speculatable`
; declaration's own `noundef range` is trusted as its `speculatable` promise is.
; Retire this row on such a ruling. IR-only: C cannot spell `speculatable`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error: {{.*}}in function example i32 (i32, i32): cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

declare noundef range(i32 0, 5) i32 @pb(i32 noundef) #0

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pb(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { speculatable nounwind willreturn memory(none) }
