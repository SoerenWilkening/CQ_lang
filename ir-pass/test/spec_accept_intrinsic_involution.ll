; spec_accept_intrinsic_involution.ll — Phase 7.1-E follow-up
; (test_C_libtooling-mvjc): the Class-1 sibling of spec_accept_intrinsic_body.ll.
; A `@llvm.bswap.i32` (a byte-swap INVOLUTION) inside a specialized clone lowers
; correctly. bswap is Class-1 — it HAS a frozen `_inv` twin (a fresh-minting
; adjoint) as well as an `_unc` — so this fixture pins the load-bearing
; discrimination: the whole-clone Bennett reverse uses the keep-live `_unc`
; (`cq_template_bswap_i32_unc`, which zeroes the rail in place by recomputing from
; the live source), NEVER the dirty-freeing `_inv` (Rule 6/8 — an `_inv` frees an
; entangled rail = a hidden measurement). One forward producer, copy out the i32
; result, one `_unc`, one free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.bswap.i32(i32)

define i32 @bswap_helper(i32 %a) {
entry:
  %b = call i32 @llvm.bswap.i32(i32 %a)
  ret i32 %b
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r = call i32 @bswap_helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_bswap_helper_1(
; CHECK:     define internal i32 @__cq_q_bswap_helper_1(i32 %a)
; CHECK:     %[[INTR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_bswap_i32(i32 %a)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[INTR]], i32 %[[OUT]])
; CHECK:     call void @cq_template_bswap_i32_unc(i32 %[[INTR]], i32 %a)
; CHECK:     call void @cqrt_free(i32 %[[INTR]])
; CHECK:     ret i32 %[[OUT]]
;
; The keep-live `_unc` is used, never bswap's dirty-freeing `_inv` twin.
; CHECK-NOT: cq_template_bswap_i32_inv
; CHECK-NOT: call i32 @llvm.bswap.i32
