; spec_accept_odr_callee_dead_arg_kept.ll — ACCEPT, and the dead-argument DROP
; must NOT fire (bd test_C_libtooling-p3kd.2). `@h` ignores its tainted `%a` in
; THIS module's body. For an exact `@h` the drop rewrites the call to
; `@h(0, %k)` and leaves it calling `@h` (measured on main 7b4e6359 with the
; linkage removed: `CQ_DEADARG_DBG: drop arg 0 of @h`). That is LLVM's
; `DeadArgumentEliminationPass::removeDeadArgumentsFromCallers` across the TU
; boundary, and LLVM refuses it unless `hasExactDefinition()`: the call still
; runs the LINKED body, and a differently optimized `linkonce_odr` variant may
; still read the slot (LLVM's example is a dead `load` kept in the linker-chosen
; copy; here it could be a kept `sdiv 10, %a` the visible copy deleted, which the
; constant 0 turns into a trap). So `dropEligibleCallee` asks
; `calleeBodyTrusted(F, AssumeOfLinkedCall)` and the ODR site is not dropped. It
; is lifted instead: the call is retargeted to the internal clone, so the body
; whose `%a` is dead is the body that runs.
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define linkonce_odr i32 @h(i32 noundef %a, i32 noundef %k) {
entry:
  %y = add i32 %k, 1
  ret i32 %y
}

define i32 @example(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r = call i32 @h(i32 noundef %q, i32 noundef %k)
  %m = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m, %r
  ret i32 %s
}

; ERR-NOT: CQ_DEADARG_DBG
; ERR-NOT: error
;
; CHECK-LABEL: define i32 @example(
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
;
; The site calls the INTERNAL clone (its recorded-dead slot nulled there, which
; is sound because the clone is exact); the original `@h` is no longer called.
; CHECK:     call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %k)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT: call i32 @h(
; CHECK-LABEL: define internal i32 @__cq_q_h_01(i32 noundef %a, i32 noundef %k)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %y = add i32 %k, 1
; CHECK-NEXT:   ret i32 %y
