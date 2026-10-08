; control_classical_call_arm_twin_reject_decl_noundef_return.ll — DECLINE (bd dm7f.21).
; The bodyless neighbour of the flipped return-attribute rows
; (control_classical_call_arm_twin_accept_root_retattr_range.ll,
; ..._twin_accept_inner_retattr_range.ll, ..._twin_accept_inner_retattr_nofpclass.ll):
; the hoisted callee `@pb` is a `speculatable` DECLARATION whose `range(i32 0, 5)`
; return nothing can prove, called at a `noundef` call site. `pb(50)` may return
; poison, and a `noundef` result that is poison is immediate UB on basis states the
; guard `q > 3` excluded (all of them, Ry(0)). With a body, the speculation-safe twin
; freezes the `ret` and drops the `range`; a declaration has no body to twin, so
; `classicalCallHoistRoute` answers `Unsafe` and the hoist declines loudly.
; HONEST SCOPE: an interim decline (R1), not physics. Dropping the ROOT call site's
; `noundef` (a refinement: the result is then a poison value the controlled copy never
; merges on a shielded state) would lower it; filed as a dm7f.21 follow-up. IR-only:
; C cannot spell `speculatable` on a user declaration.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error: {{.*}}in function example i32 (i32, i32): cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

declare range(i32 0, 5) i32 @pb(i32 noundef) #0

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call noundef i32 @pb(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { speculatable nounwind willreturn memory(none) }
