; spec_accept_clone_switch.ll — ACCEPT (bd p3kd.7.1; was spec_reject_clone_switch.ll,
; the 5po2 I2 over-accept probe): a tainted-scrutinee SWITCH in a lifted callee.
; `scanBody`'s terminator whitelist admitted only `ret`/`br`, so the switch declined
; `InBodyControl` at detection. The clone path already lowers it:
; `normalizeReturnMerge` folds the three `ret`s into one merge φ, and the clone's
; `claimAll` PredMux fixpoint flattens the tainted switch region (the same switch
; edge predicates the top-level PredMux uses: one `icmp eq` flag per case, the
; default arm the base of the chain) into two selects that main's SelectMergeEmit
; (since bd p3kd.7.8; formerly `lowerCloneSelect`) lowers to the controlled-copy
; data-mux. The case constants 10 and 20 are
; materialized rails (left allocated); the default arm `b + 3` is a captured data
; template, reversed and freed.
;
; Trace check, |b> basis state:
;   sel  = [b==1]·20 ⊕ [b!=1]·(b+3)
;   sel2 = [b==0]·10 ⊕ [b!=0]·sel
; b=0 → 10, b=1 → 20, otherwise b+3, which is the switch. The reverse replays the
; copies in reverse order, then both compare `_unc`s and the add `_unc`, and frees
; every forward rail; the materialized |10>/|20> rails are never freed.
;
; bd p3kd.7.8: `lowerCloneSelect` is gone; main's stage list lowers the clone and
; both selects go through main's SelectMergeEmit. Each merge's trailing `cqrt_x`
; strip is elided by the Bennett wrap, so a flag stays at its negation until the
; mirror's own `cqrt_x` restores it before that flag's compare `_unc`. Hand trace:
; sel = f1 ? 20 : b+3, sel2 = f0 ? 10 : sel; the mirror replays sel2's two copies
; (sel2 back to 0, f0 restored), icmp_eq 0 `_unc`, then sel's two copies (sel back
; to 0, f1 restored), icmp_eq 1 `_unc`, add `_unc`, so all five freed rails are |0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  switch i32 %b, label %def [ i32 0, label %z
                              i32 1, label %o ]
z:
  ret i32 10
o:
  ret i32 20
def:
  %d = add i32 %b, 3
  ret i32 %d
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK-LABEL: define i32 @example(
; CHECK:       %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_1(i32 %[[H]])
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[R]])
;
; The clone is ONE straight-line block: no switch, br or phi survives in it.
; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %b)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 3)
; CHECK-NEXT:  %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %b, i32 1)
; CHECK-NEXT:  %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  %[[K20:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 20)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[K20]], i32 %[[S1]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[D]], i32 %[[S1]])
; CHECK-NEXT:  %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %b, i32 0)
; CHECK-NEXT:  %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  %[[K10:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 10)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[K10]], i32 %[[S2]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F0]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[S1]], i32 %[[S2]])
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[S2]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[S1]], i32 %[[S2]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F0]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[K10]], i32 %[[S2]])
; CHECK-NEXT:  call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F0]], i32 %b, i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[D]], i32 %[[S1]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[K20]], i32 %[[S1]])
; CHECK-NEXT:  call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %b, i32 1)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %b, i32 3)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[S1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F0]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[S2]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
