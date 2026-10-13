; control_classical_call_arm_twin_accept_decl_noundef_return.ll — ACCEPT (bd dm7f.26;
; was control_classical_call_arm_twin_reject_decl_noundef_return.ll, a DECLINE since
; bd dm7f.21).
; The bodyless neighbour of the return-attribute rows
; (control_classical_call_arm_twin_accept_root_retattr_range.ll,
; ..._twin_accept_inner_retattr_range.ll, ..._twin_accept_inner_retattr_nofpclass.ll):
; the hoisted callee `@pb` is a `speculatable` DECLARATION whose `range(i32 0, 5)`
; return nothing can prove, called at a `noundef` call site. `pb(k)` may return
; poison, and a `noundef` result that is poison is immediate UB on basis states the
; guard `q > 3` excluded (all of them, Ry(0)), so the Direct route is refused.
; THE TWIN of a bodyless callee is a WRAPPER (SpeculationTwin.cpp):
; `__cq_specsafe_pb(x) = freeze(pb(freeze x))`, its call site carrying no return
; attribute, the root site keeping its `noundef` (the wrapper's result is defined).
; ANALYTIC (R2): `@pb` is trusted on its `speculatable` promise exactly as the Direct
; route trusts it (control_classical_call_arm_accept_speculatable_decl.ll), so the
; call is UB-free for the frozen (defined) argument. On a basis state where the
; source runs `pb(k)` without UB, k is defined (a `noundef` parameter: the argument
; freeze is the identity) and the result is not poison (a `noundef` site), so the
; result freeze is the identity too and the wrapper returns `pb(k)`. Elsewhere it
; returns some defined value the controlled copy never merges. IR-only: C cannot
; spell `speculatable` on a user declaration.
; Decline neighbour (the declaration's OWN `noundef` return, which no wrapper edit
; sheds): control_classical_call_arm_twin_reject_decl_own_noundef_range.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @example(
; CHECK:       %r = call noundef i32 @__cq_specsafe_pb(i32 %k)
; CHECK-NOT:   call {{.*}}@pb(
; CHECK:       call i32 @cqrt_alloc_i32(i32 %r)
; CHECK:       define internal i32 @__cq_specsafe_pb(i32 noundef %0) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK-NEXT:    %.fr = freeze i32 %0
; CHECK-NEXT:    %2 = call i32 @pb(i32 %.fr)
; CHECK-NEXT:    %.fr1 = freeze i32 %2
; CHECK-NEXT:    ret i32 %.fr1
; CHECK:       ![[TW]] = !{ptr @pb}

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
