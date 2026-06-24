; spec_reject_fcmp_pred.ll — Phase 6.4 (WI-1.13 over-accept hardening, completed):
; a tainted body containing an OUT-OF-SCOPE fcmp predicate (`false` — the
; degenerate always-0, outside the lowerable fcmp set) has no reversible template.
; (After 8rvn / Phase 7.1 iw81.4 §4.4 broadened the fcmp set to the full ordered/
; unordered comparison family, `true`/`false` are the only out-of-set fcmp
; predicates left, so `false` is the standing residual probe here.) Before this
; the body whitelist accepted any `CmpInst` of valid width, so the clone
; `__cq_q_helper_01` was created and the predicate only backstopped LATE at
; lowerOps' `diagnoseNoTemplate` (naming the CLONE: "no template for opcode
; 'fcmp i1' in tainted context"). The classifier now mirrors `compareInScope` at
; DETECTION, declining at the offending compare's `!dbg` with the precise
; "unsupported compare predicate" kind. Recorded in `plan6.Diagnosed`, so the
; carve-out does NOT also emit `kMsgUnknownCallee`; CHECK-NOT confirms no clone.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x, float %c) {
entry:
  %f = sitofp i32 %x to float
  %p = fcmp false float %f, %c
  %z = zext i1 %p to i32
  ret i32 %z
}

define i32 @example(i32 %u0, float %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, float %c)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported compare predicate)
; CHECK-NOT: cq taint escape
; CHECK-NOT: @__cq_q_helper
