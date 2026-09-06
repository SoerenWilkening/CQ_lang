; control_swap_value_accept_i64_merge_cast.ll — ACCEPT spec: a DOWNSTREAM CAST
; off a VALUE-arm merge, at a SUPER-i32 width (the `trunc` direction; the
; sub-i32 `sext` direction is control_swap_value_accept_i8_merge_cast.ll).
;
; ⚠ ACCEPT-CLASS WIDENING, pinned deliberately (bd test_C_libtooling-3qlq Inc 2,
; Rule-13 round-1 review F-V1-1; owner disposition OQ-22 KEEP+PIN). MEASURED on
; this module: ORACLE 52d7764 rc=1
; `no template for opcode 'trunc i32' in tainted context`; SUBJECT rc=0, the
; stream below, `free_pairing_check.py` STRICT rc=0. The mechanism is
; `taint.HandleWidth[out]` (bd p119.6), inherited from `emitSelectRegion`; the
; retired route recorded no width, so the laundered i32 handle had none to
; recover. See the i8 sibling's header for the full argument.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
declare i64 @cq_theta_sll(i64, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i64 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i64 @cq_theta_sll(i64 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i64 %p, 5
  %v2 = add i64 %v1, 15
  br label %merge
merge:
  %pm = phi i64 [ %v2, %arm ], [ %p, %entry ]
  %w  = trunc i64 %pm to i32
  %m  = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %v0)
; CHECK-NEXT: call void @cqrt_ry_i64(i32 %[[P]], double 2.500000e-01)
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i64_hl(i32 %[[P]], i64 5)
; CHECK-NEXT: call void @cqrt_addc_i64(i32 %[[V]], i64 15)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK-NEXT: call void @cqrt_copy_i64_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i64_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; THE WIDENING — the cast resolves at the RECORDED i64 width. Oracle declined here.
; CHECK-NEXT: %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[OUT]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[W]])

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy_i64(
; NOROUTE-NOT: phi i64
; NOROUTE-NOT: call i64 @cq_theta
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: trunc i64
; NOROUTE-NOT: cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: cqrt_copy_i32_controlled

; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CCNT-COUNT-2: call void @cqrt_copy_i64_controlled(
; CCNT-NOT:     call void @cqrt_copy_i64_controlled(
