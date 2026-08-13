; lowering_reject_taint_escape_inmodule_body.ll — Phase 6 WI-1.10: the
; deliberate decline→ACCEPT flip (regenerate-by-decision, Rule 12; C22). This
; fixture USED to pin the taint-escape decline for a tainted value passed to an
; IN-MODULE callee with a visible body (`error: cq taint escape: … unknown
; callee`). Phase 6.1 call-graph specialization (clone-on-taint) now LIFTS that
; callee: the carve-out (`detectSpecializations` pre-pass → `shouldSpecialize`
; membership at the `:419` taint-escape seam) suppresses the decline, the driver
; clones `@helper` → `@__cq_q_helper_1`, lowers its `add` under a disjoint
; `cloneTaint`, and Bennett-wraps it (compute → copy-out → uncompute → free).
;
; The declaration-only sibling fixtures (`_opaque_call` / `_deep_arg` /
; `_indirect_call`) STAY DECLINES — a no-IR / indirect callee is never a
; candidate (DD-2), so the carve-out still fires `kMsgUnknownCallee` for them.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x) {
entry:
  %y = add i32 %x, 1
  ret i32 %y
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)                   ; visible body → specialized
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; The call retargets to the mangled clone (param 0 tainted → mask "1").
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_1(i32 %[[H]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; The clone: forward `add` template → alloc out → copy-out → void `_unc` adjoint
; → free scratch → return the basis-valued copy (Bennett compute-copy-uncompute).
; CHECK:     define internal i32 @__cq_q_helper_1(i32 %x)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP]], i32 %[[OUT]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %x, i32 1)
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; CHECK:     ret i32 %[[OUT]]
;
; The decline is GONE (the carve-out suppressed it); the original intrinsic is
; lowered and the copy is the basis-valued `_hl` template, never an `_inv` twin.
; CHECK-NOT: cq taint escape
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: cq_template_add_i32_hl_inv
