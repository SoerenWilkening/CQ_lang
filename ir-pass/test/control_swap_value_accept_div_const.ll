; control_swap_value_accept_div_const.ll — ACCEPT: the DISCRIMINATOR for the
; Inc-2 speculation-totality fence (bd test_C_libtooling-3qlq Inc 2).
;
; `if (q > 5) { p = p*5; p = p/3; }` — the same division opcode family that
; control_swap_value_reject_speculation.ll declines, but with a NON-ZERO CONSTANT
; divisor, which `isSafeToSpeculativelyExecute` admits. Without this file the
; fence would be indistinguishable from "decline every div/rem in a value arm",
; and the next reader would have no way to tell which of the two it is.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i32 %p, 5
  %v2 = udiv i32 %v1, 3             ; non-zero CONSTANT divisor — speculatable
  br label %merge
merge:
  %pm = phi i32 [ %v2, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; the hoisted chain, division included, then the controlled-copy merge
; CHECK:     %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK:     %[[V1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; CHECK:     %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_udiv_i32_hl(i32 %[[V1]], i32 3)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[V2]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: under quantum control
; NOROUTE-NOT: phi i32
