; control_swap_switch_value_accept_div_const.ll — ACCEPT: the SWITCH-half
; DISCRIMINATOR for the Inc-2 speculation-totality fence (bd
; test_C_libtooling-3qlq Inc 2, Rule-13 round-1 review finding F-V2-6).
;
; `switch(q){ case 0: p = p/3; case 1: p = p+2; }` — the same division opcode
; family that control_swap_switch_value_reject_speculation.ll declines, but with
; a NON-ZERO CONSTANT divisor, which `isSafeToSpeculativelyExecute` admits.
;
; WHY IT EXISTS. The switch half of the fence shipped with a DECLINE fixture and
; no accept twin, so on that side the fence was indistinguishable from "decline
; every div/rem in a switch value case" — a reader could not tell which of the
; two `emitSwitchValueRegion` implements, and a regression that widened the
; decline to every division would have gone unnoticed. The diamond half has had
; its discriminator since the increment (control_swap_value_accept_div_const.ll);
; this is its twin. Same predicate, same call site, opposite disposition.
;
; MEASURED: rc=0 on this binary AND rc=0 on the pre-3qlq oracle 52d7764 — the
; fence narrows only the possibly-zero-divisor shape, and this module is on the
; SAME side of it on both binaries (unlike the decline twin, which the oracle
; accepts).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %p0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %p0, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v0 = udiv i32 %p, 3              ; non-zero CONSTANT divisor — speculatable
  br label %merge
a1:
  %v1 = add i32 %p, 2
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v0, %a0 ], [ %v1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; THE WHOLE REGION STREAM, CONTIGUOUS — preload, then one (chain, delta, flag,
; controlled copy) group per content case, then the strips and flag frees.
; `CHECK-NEXT` adjacency is the contract (round-1 review F-V2-5).
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %p0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 0x3FE6666666666666)
; --- PRELOAD ---
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[P]], i32 %[[OUT]])
; --- case 0: THE DIVISION, hoisted onto the original %p and run
;     unconditionally, which is exactly why the divisor has to be provably
;     non-zero; then the XOR delta, the eq-flag and one controlled copy ---
; CHECK-NEXT: %[[T0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_udiv_i32_hl(i32 %[[P]], i32 3)
; CHECK-NEXT: %[[D0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32(i32 %[[P]], i32 %[[T0]])
; CHECK-NEXT: call void @cq_template_udiv_i32_hl_unc(i32 %[[T0]], i32 %[[P]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T0]])
; CHECK-NEXT: %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F0]], i32 %[[D0]], i32 %[[OUT]])
; --- case 1 ---
; CHECK-NEXT: %[[T1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[P]], i32 2)
; CHECK-NEXT: %[[D1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32(i32 %[[P]], i32 %[[T1]])
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[T1]], i32 %[[P]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T1]])
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[D1]], i32 %[[OUT]])
; --- each strip adjacent to the free it licenses (a free without its strip is
;     a dirty free = a hidden measurement, Rule 6) ---
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F0]], i32 %[[Q]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F0]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])

; Whole-file PURE-NEGATIVE scan. No route, no `cqrt_x` (the eq-flags are
; mutually exclusive), no residual switch, and — the point of this file — no
; decline diagnostic.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: under quantum control
; NOROUTE-NOT: switch i32

; EXACTLY FOUR frees: the two chain intermediates + the two flags. %p, %out and
; the two deltas are left allocated.
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; EXACTLY N=2 controlled copies — one per content case.
; CCNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CCNT-NOT:     call void @cqrt_copy_i32_controlled(
; EXACTLY ONE uncontrolled basis copy — the preload.
; PCNT-COUNT-1: call void @cqrt_copy_i32(
; PCNT-NOT:     call void @cqrt_copy_i32(
