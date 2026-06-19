; spec_overaccept_probe_decl_only.ll — Phase 6.4 WI-4.3 over-accept probe
; (the DD-2 no-IR contract). `@liftable` has a perfectly specializable SIGNATURE
; but NO body in this module (declaration only — the cross-TU case before
; llvm-link, or a genuinely external symbol). There is no IR to clone, so it is
; never a candidate (the `!isDeclaration()` SHAPE filter) and STILL fires
; `kMsgUnknownCallee`. Guards against a weakening that would clone a body that
; isn't actually present.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @liftable(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @liftable(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: @__cq_q_liftable
