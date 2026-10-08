; control_classical_call_arm_twin_accept_root_retattr_range.ll — ACCEPT (bd dm7f.21).
; FLIPPED from control_classical_call_arm_reject_root_retattr_range.ll (bd bwfp R11
; round 3 F1(b), a DECLINE) by the owner ruling of 2026-10-08 (option a).
; The HOISTED call site is `noundef` and its callee `@pb` carries `range(i32 0, 5)` on
; its return without `noundef`. `pb(50)` yields poison, and a `noundef` call result
; that is poison is immediate UB on basis states the guard `q > 3` excluded. The hoist
; now calls `@pb`'s speculation-safe twin: its `ret` is frozen and its unprovable
; `range` dropped, so the result is defined and the call site's `noundef` holds.
; ANALYTIC (R2): for `%k` in [0, 5) the range held, the `freeze` is the identity and
; the twin returns `pb(%k)` = `%k`; otherwise, under a true guard the source's own
; call is UB, and under a false guard the twin's value is never merged. Decline
; neighbours, still refused: control_classical_call_arm_reject_root_param_range.ll (a
; value constraint on the PARAMETER, which a defined argument violates) and
; control_classical_call_arm_twin_reject_decl_noundef_return.ll (no body to twin).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call noundef i32 @__cq_specsafe_pb(i32 %k)
; CHECK:       call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       define internal i32 @__cq_specsafe_pb(i32 noundef %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %x.fr = freeze i32 %x
; CHECK-NEXT:    ret i32 %x.fr

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal range(i32 0, 5) i32 @pb(i32 noundef %x) #0 {
entry:
  ret i32 %x
}

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

attributes #0 = { nounwind willreturn memory(none) }
