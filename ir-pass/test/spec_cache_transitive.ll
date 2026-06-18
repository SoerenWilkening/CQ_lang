; spec_cache_transitive.ll — Phase 6.3 WI-3.4: convergence on the (callee,mask)
; key space across the transitive worklist. TWO distinct outer clones (outerA,
; outerB) each call the SAME inner `inner` with the SAME taint signature (mask 1).
; The shared (callee,mask) cache synthesizes @__cq_q_inner_1 (and its twin) EXACTLY
; ONCE; the second outer reuses it (no re-clone) — the depth-first drain finalizes
; the inner's record before outerB's cache hit reads it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck --check-prefix=COUNT %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck --check-prefix=CALLS %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @inner(i32 %a) {
entry:
  %y = mul i32 %a, 7
  ret i32 %y
}

define i32 @outerA(i32 %t) {
entry:
  %u = call i32 @inner(i32 %t)
  %r = add i32 %u, 1
  ret i32 %r
}

define i32 @outerB(i32 %t) {
entry:
  %u = call i32 @inner(i32 %t)
  %r = add i32 %u, 2
  ret i32 %r
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = call i32 @outerA(i32 %q)
  %b = call i32 @outerB(i32 %q)
  %m1 = call i32 @cq_measure_si32(i32 %a)
  %m2 = call i32 @cq_measure_si32(i32 %b)
  ret void
}

; Both outer clones synthesize and BOTH call the one shared inner clone + twin.
; CHECK-DAG: define internal i32 @__cq_q_outerA_1(i32 %t)
; CHECK-DAG: define internal i32 @__cq_q_outerB_1(i32 %t)
; CHECK-DAG: define internal i32 @__cq_q_inner_1(i32 %a)
; CHECK-DAG: define internal void @__cq_q_inner_1_unc(i32 %out, i32 %a)

; The inner clone + twin are synthesized EXACTLY ONCE (shared, not per-outer).
; Each prefix scans from the top, independent of the CHECK-DAG cursor and of each
; other (the def lines and the call sites straddle one another in module order).
; COUNT-COUNT-1: define internal i32 @__cq_q_inner_1(
; COUNT-NOT:     define internal i32 @__cq_q_inner_1(
; COUNT-COUNT-1: define internal void @__cq_q_inner_1_unc(
; COUNT-NOT:     define internal void @__cq_q_inner_1_unc(

; Both outers route through the SAME inner clone (two forward call sites, one def).
; CALLS-COUNT-2: call i32 @__cq_q_inner_1(
; CALLS-NOT:     call i32 @__cq_q_inner_1(
