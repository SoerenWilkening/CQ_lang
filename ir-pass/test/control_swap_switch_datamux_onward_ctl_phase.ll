; control_swap_switch_datamux_onward_ctl_phase.ll — ACCEPT (yn71, Phase 4×6, the
; CONTROL case): a 4.5 all-ConstantInt switch DATA-MUX whose UNTAINTED merge `%out`
; feeds a NEW TAINTED-condition diamond applying a phase — `switch(q){0:r=7; 5:r=9;
; 17:r=11;}; if (r > 8) r = cq_phi(r, .25); measure r`. The data-mux merge is
; all-ConstantInt (data-untainted), so `if (r > 8)` was classical at round-1; the
; second propagation (`repropagateControlMerges`) taints `%out` → `icmp sgt %out, 8`,
; a new quantum-controlled branch on the data-mux answer.
;
; yn71 RE-DETECTS the diamond (`detectAndLowerOnwardControl`) and `SwapRouteEmit` emits
; the routed phase arm ON `%out`: mint the flag from `icmp(%out, 8)`, route `%out` into
; a |0> rail via `cqrt_cswap`, VERBATIM uncontrolled `cqrt_rz` on the rail, route back,
; free the rail, `icmp_inv`-strip + free the flag; the measure reads `%out`. This is
; the CONTROL twin of control_swap_switch_datamux_onward_arith.ll (dugh onward DATA).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 5, label %a1
                                i32 17, label %a2 ]
a0:
  br label %merge
a1:
  br label %merge
a2:
  br label %merge
merge:
  %rm = phi i32 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ], [ 11, %a2 ]  ; all-const data-mux -> %out
  %c2 = icmp sgt i32 %rm, 8                                          ; tainted only AFTER re-seed
  br i1 %c2, label %ph, label %m2                                    ; NEW tainted control on %out
ph:
  %p = call i32 @cq_phi_si32(i32 %rm, double 0.25)
  br label %m2
m2:
  %pp = phi i32 [ %p, %ph ], [ %rm, %merge ]
  %m = call i32 @cq_measure_si32(i32 %pp)
  ret i32 %m
}

; The data-mux builds %out (preload + XOR-delta copies + N eq-flag strips), then the
; onward controlled phase arm routes %out under a flag minted from icmp(%out, 8):
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[OUT:[a-zA-Z0-9_.]+]], i32 8)
; CHECK:     %[[RAIL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[OUT]], i32 %[[RAIL]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[RAIL]], double 2.500000e-01)
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[OUT]], i32 %[[RAIL]])
; CHECK:     call void @cqrt_free(i32 %[[RAIL]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[OUT]], i32 8)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; No surviving merge phi / tainted branch, the onward Rz is UNCONTROLLED (routed), and
; the region ACCEPTS:
; CHECK-NOT: phi i32
; CHECK-NOT: cqrt_rz{{.*}}_controlled
; ACC-NOT: under quantum control
