; lowering_reject_taint_escape_inmodule_body.ll — DECLINE: tainted value passed
; to an IN-MODULE callee WITH A VISIBLE BODY (test_C_libtooling-bxv). Pins
; today's accept/decline boundary for non-intrinsic callees: visible-body and
; declared-only callees decline IDENTICALLY.
;
; Phase 6 (call-graph specialization, backend.md §7.2 clone-on-taint) is NOT
; implemented: there is no clone, no retarget, and `@helper`'s body is never
; taint-specialized — the call survives verbatim and, after rotation lowering's
; RAUW, `@helper(i32 %h)` computes `add` on the RUNTIME HANDLE TAG (confirmed at
; HEAD 6ac1ae3: exit 0, verify-clean). At -O1 the common case inlines small
; helpers away BEFORE the pass runs (docs/frontend.md §"hidden internal casts");
; a call that SURVIVES to the pass is exactly the case inlining did not fold,
; and today that is the same silent escape as an opaque extern. When Phase 6
; lands, the clone-on-taint accept must flip THIS fixture deliberately
; (regenerate-by-decision, Rule 12) — never by reflex.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
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
  %r = call i32 @helper(i32 %q)                   ; visible body, still unhandled
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
