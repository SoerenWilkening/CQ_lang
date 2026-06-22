; control_swap_abort_park.ll — Phase 7.2 Increment 3 ACCEPT: the abort/exit park
; cascade (PRD-7.2 §2.8 / §2.11-B, IMPLEMENTATION-PLAN-7.2 §5).
;
; Captured from real `clang -O1` (§2-D) on `if (q > 5) abort(); return
; cq_measure(q);` — the verified -O1 shape: a tainted-condition `br` whose TRUE
; arm is `{tail call void @abort(); unreachable}` (NO value, NO merge φ), the
; FALSE sibling the ordinary uncontrolled remainder. `recoverRegion` would label
; the `unreachable`-terminated arm `OffPattern` and decline generically, so
; `classifyAbortPark` recognizes it FIRST.
;
; The park cascade: mint the abort flag from q0 -> alloc the |0> graveyard rail ->
; `cqrt_cswap(flag, q, grave)` the would-abort component aside (self-bracketed; A
; TRUE-successor sink is un-negated, so NO `cqrt_x` bracket) -> record the flag on
; the tape (`cqrt_tape_write_i1`, the truncate-at-inspection marker) -> redirect
; the branch to the sibling so the downstream runs UNCONTROLLED. The abort call +
; `unreachable` are erased; the graveyard + flag are KEPT, NEVER `cqrt_free`'d (a
; parked entangled rail freed dirty is a hidden measurement, Rule 6).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=NOFREE
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

; The ORDERED park stream (order IS the contract — a reordered cswap/record is
; trace-plausible yet wrong; mint-before-park is load-bearing so the flag reads q0).
; CHECK: %[[TAPE:.+]] = call i32 @cqrt_tape_alloc()
; CHECK: %[[Q:.+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK: call void @cqrt_ry_i32(i32 %[[Q]], double {{.+}})
; CHECK: %[[FLAG:.+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK: %[[GRAVE:.+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_cswap(i32 %[[FLAG]], i32 %[[Q]], i32 %[[GRAVE]])
; CHECK: call i32 @cqrt_tape_write_i1(i32 %[[TAPE]], i32 %[[FLAG]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[Q]])

; EXACTLY ONE graveyard cswap (one live register parked).
; CNT-COUNT-1: call void @cqrt_cswap(
; CNT-NOT:     call void @cqrt_cswap(

; The graveyard is NEVER freed; the abort arm is fully erased (whole-file scan).
; NOFREE-NOT: call void @cqrt_free(
; NOFREE-NOT: call void @abort()
; NOFREE-NOT: unreachable

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort()

define i32 @slice() {
  %q = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %abort, label %cont
abort:
  call void @abort()
  unreachable
cont:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
