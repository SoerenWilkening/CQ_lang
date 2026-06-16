; control_swap_switch_phase_passthrough.ll — ACCEPT spec, PHASE switch with an
; EMPTY passthrough case (case 2 routes q unchanged: an arm BLOCK with no gate,
; merge incoming = q). Confirms the emitter SKIPS a gate-free arm — no flag, no
; rail, no route for case 2 — while still flattening its (now-dead) block, and the
; round-3 driver passthrough-arm scan does NOT over-decline a legitimate empty
; passthrough. WI-1 fired the transitional "switch" decline; WI-2 graduates it to
; the lowered stream (exactly cases 0 and 1; case 2 contributes nothing).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=XCT
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1
                                i32 2, label %a2 ]
a0:
  %g0 = call i32 @cq_phi_si32(i32 0, double 1.000000e-01)
  br label %merge
a1:
  %g1 = call i32 @cq_phi_si32(i32 1, double 2.000000e-01)
  br label %merge
a2:
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %g0, %a0 ], [ %g1, %a1 ], [ %q, %a2 ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; case 0 (full stream)
; CHECK:     %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 0)
; CHECK:     %[[R0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F0]], i32 %[[Q]], i32 %[[R0]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R0]], double 1.000000e-01)
; CHECK:     call void @cqrt_cswap(i32 %[[F0]], i32 %[[Q]], i32 %[[R0]])
; CHECK:     call void @cqrt_free(i32 %[[R0]])
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[Q]], i32 0)
; CHECK:     call void @cqrt_free(i32 %[[F0]])
; case 1 (full stream)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 1)
; CHECK:     %[[R1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[Q]], i32 %[[R1]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R1]], double 2.000000e-01)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[Q]], i32 %[[R1]])
; CHECK:     call void @cqrt_free(i32 %[[R1]])
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[Q]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; case 2 is an EMPTY passthrough — NO stream — q is measured directly:
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])

; exactly 4 frees (2 rails + 2 flags) — the passthrough case 2 allocates/frees
; NOTHING; no fifth:
; CNT-COUNT-4: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; exactly TWO |0> rails — the passthrough case 2 is SKIPPED (no rail/route). The
; handle alloc `cqrt_alloc_i32(i32 %u0)` is a distinct literal, so this counts only
; the `(i32 0)` rails:
; XCT-COUNT-2: call i32 @cqrt_alloc_i32(i32 0)
; XCT-NOT:     call i32 @cqrt_alloc_i32(i32 0)

; whole-output absence scan: accepts; re-anchor held; no controlled gates; and in
; particular NO eq-flag for case literal 2 (the passthrough mints none):
; ACC-NOT: under quantum control
; ACC-NOT: cq_phi
; ACC-NOT: phi i32
; ACC-NOT: _controlled
; ACC-NOT: , i32 2)
