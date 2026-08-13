; spec_accept_transitive_retattr.ll — Phase 6.3 WI-3.6 regression pin (Rule-12).
; The transitive inner's return carries the `noundef range(...)` attributes that
; `clang -O1` emits for a non-full-range op (here `a & 255`). The uncompute twin
; @__cq_q_inner_1_unc RETYPES the return to void, on which NO return attribute is
; valid — a leaked `noundef`/`range` (copied verbatim by `CloneFunctionInto`) is a
; malformed module that aborts `opt -verify` (exit 134). `stripStaleClassicalAttrs`
; must clear the entire return-index attribute set for the void twin. This fixture
; CRASHED before that fix; the verify RUN below is the regression gate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define noundef range(i32 0, 256) i32 @inner(i32 noundef %a) {
entry:
  %y = and i32 %a, 255
  ret i32 %y
}

define i32 @outer(i32 %t) {
entry:
  %u = call i32 @inner(i32 %t)
  %r = add i32 %u, 1
  ret i32 %r
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @outer(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}

; Module order is outer clone, inner clone, then the twin. The outer reverse
; still calls the twin on the entangled inner rail before freeing it.
; CHECK:      define internal i32 @__cq_q_outer_1(i32 %t)
; CHECK:      %[[U:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_inner_1(i32 %t)
; CHECK:      call void @__cq_q_inner_1_unc(i32 %[[U]], i32 %t)
; CHECK-NEXT: call void @cqrt_free(i32 %[[U]])

; The void twin synthesizes with a CLEAN void return — no `noundef`/`range`
; between `internal` and `void` (else `define internal void` would not match).
; CHECK:      define internal void @__cq_q_inner_1_unc(i32 %out, i32 noundef %a)
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %a, i32 255)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[T]], i32 %out)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[T]], i32 %a, i32 255)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: ret void
