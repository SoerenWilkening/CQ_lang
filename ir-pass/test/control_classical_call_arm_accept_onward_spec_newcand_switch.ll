; control_classical_call_arm_accept_onward_spec_newcand_switch.ll — ACCEPT (bd p3kd.7.1;
; the program control_classical_call_arm_reject_onward_spec_newcand_inbody.ll declined until
; then). A 6.5 classical-call arm's `%out` (y = q>3 ? f(a) : 5, a controlled-copy merge
; into a fresh rail) is the sole argument of a round-2 NEW candidate `@g(i32)` whose body is
; a tainted-scrutinee SWITCH. `scanBody` used to refuse the `switch` terminator; it now
; admits it, round-2 detection (bd 9paa) puts `g(%out)` in the plan, and the clone flattens
; the switch (PredMux claimAll, one `icmp eq` flag per case) and lowers the two resulting
; selects as the controlled-copy data-mux. The caller is the existing round-2 path,
; unchanged: the merge rail `%out` is passed BORROWED to the clone and the clone's result is
; measured.
;
; Trace check, |v> = |out>: sel = [v==1]·20 ⊕ [v!=1]·(v+3); sel2 = [v==0]·10 ⊕ [v!=0]·sel,
; which is g. The Bennett reverse returns every clone scratch rail to |0> before its free.
;
; bd p3kd.7.8: the clone is now lowered by MAIN's stage list; each flattened select
; goes through main's 4.4 path (CondTreeEmit `icmp eq` flag + SelectMergeEmit
; controlled-copy merge, constants materialized) instead of the removed clone-only
; select lowering. The forward is the same except that each merge's flag strip
; (trailing `cqrt_x`, compare `_unc`, free) is elided inside a clone: both brackets
; stay OPEN (F1 = [v!=1], F0 = [v!=0]) and the exact mirror closes them. Hand trace
; of the mirror: S2 ^= [v!=0]·S1, F0→[v==0], S2 ^= [v==0]·10 (S2 = 0), F0 `_unc`;
; S1 ^= [v!=1]·D, F1→[v==1], S1 ^= [v==1]·20 (S1 = 0), F1 `_unc`; D `_unc`. The
; five freed rails are |0>; the |20> and |10> rails stay allocated, which the
; full-body CHECK-NEXT pin through `}` enforces. The caller side is unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatableTotalCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_twin_accept_partial_callee.ll (a VISIBLE partial body,
; hoisted since batch 053 only as its divisor-guarded twin). Nothing else in this fixture changes; the body is inert.
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}
; a visible body with a tainted-scrutinee SWITCH — lifted since bd p3kd.7.1.
define i32 @g(i32 %v) {
entry:
  switch i32 %v, label %def [ i32 0, label %z
                              i32 1, label %o ]
z:
  ret i32 10
o:
  ret i32 20
def:
  %d = add i32 %v, 3
  ret i32 %d
}

define void @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %z = call i32 @g(i32 %y)      ; round-2 NEW candidate g(%out) -> lifted
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }

; CHECK-LABEL: define void @example(
; CHECK:       %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:       %[[Z:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_g_1(i32 %[[OUT]])
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 %[[Z]])
;
; CHECK-LABEL: define internal i32 @__cq_q_g_1(i32 %v)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %v, i32 3)
; CHECK-NEXT:  %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %v, i32 1)
; CHECK-NEXT:  %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  %[[K20:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 20)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[K20]], i32 %[[S1]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[D]], i32 %[[S1]])
; CHECK-NEXT:  %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %v, i32 0)
; CHECK-NEXT:  %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  %[[K10:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 10)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[K10]], i32 %[[S2]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F0]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[S1]], i32 %[[S2]])
; CHECK-NEXT:  %[[CO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[S2]], i32 %[[CO]])
; The exact mirror, outer select first, each compare `_unc` after its copies.
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[S1]], i32 %[[S2]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F0]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[K10]], i32 %[[S2]])
; CHECK-NEXT:  call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F0]], i32 %v, i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[D]], i32 %[[S1]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[K20]], i32 %[[S1]])
; CHECK-NEXT:  call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %v, i32 1)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %v, i32 3)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[S1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F0]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[S2]])
; CHECK-NEXT:  ret i32 %[[CO]]
; CHECK-NEXT:  }
