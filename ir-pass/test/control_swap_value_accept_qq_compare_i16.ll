; control_swap_value_accept_qq_compare_i16.ll — ACCEPT spec: a DOWNSTREAM Q+Q
; DATA COMPARE off a VALUE-arm merge at i16 (the sub-i32 rows of the same
; widening; the flagship i32 row is control_swap_value_accept_qq_compare_on_merge.ll).
;
; ⚠ ACCEPT-CLASS WIDENING, pinned deliberately (bd test_C_libtooling-3qlq Inc 2,
; Rule-13 round-1 review F-V1-1; owner disposition OQ-22 KEEP+PIN). MEASURED:
; ORACLE 52d7764 rc=1 `no template for opcode 'icmp i1' in tainted context`;
; SUBJECT rc=0, the stream below, `free_pairing_check.py` STRICT rc=0. The
; mechanism is `taint.HandleWidth[out]` (bd p119.6), inherited from
; `emitSelectRegion`. What this row adds over the i32 one is that the compare
; template is chosen at the RECORDED i16 width, not at the laundered i32 of the
; handle SSA type — a mismatch there would be the finding, not the pin.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
declare i16 @cq_theta_si16(i16, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i16 %v0, i16 %w0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i16 @cq_theta_si16(i16 %v0, double 2.500000e-01)
  %r = call i16 @cq_theta_si16(i16 %w0, double 1.250000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i16 %p, 5
  %v2 = add i16 %v1, 15
  br label %merge
merge:
  %pm = phi i16 [ %v2, %arm ], [ %p, %entry ]
  %e  = icmp sgt i16 %pm, %r
  %ez = zext i1 %e to i32
  %m  = call i32 @cq_measure_si32(i32 %ez)
  ret i32 %m
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i16(i16 %v0)
; CHECK-NEXT: call void @cqrt_ry_i16(i32 %[[P]], double 2.500000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i16(i16 %w0)
; CHECK-NEXT: call void @cqrt_ry_i16(i32 %[[R]], double 1.250000e-01)
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i16_hl(i32 %[[P]], i16 5)
; CHECK-NEXT: call void @cqrt_addc_i16(i32 %[[V]], i16 15)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i16(i16 0)
; CHECK-NEXT: call void @cqrt_copy_i16_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i16_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; THE WIDENING — the Q+Q compare at the RECORDED i16 width, not the handle's i32.
; CHECK-NEXT: %[[E:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i16(i32 %[[OUT]], i32 %[[R]])
; CHECK-NEXT: %[[EZ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[E]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i16_unc(i32 %[[E]], i32 %[[OUT]], i32 %[[R]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[E]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[EZ]])

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy_i16(
; NOROUTE-NOT: phi i16
; NOROUTE-NOT: call i16 @cq_theta
; NOROUTE-NOT: call i32 @cq_theta
; the compare must be the i16 QQ template — never an i32 one over the laundered
; handle, and never a one-handle HL/LH form
; NOROUTE-NOT: cq_template_icmp_sgt_i32(
; NOROUTE-NOT: cq_template_icmp_sgt_i16_hl
; NOROUTE-NOT: cq_template_icmp_sgt_i16_lh
; NOROUTE-NOT: cqrt_copy_i32_controlled

; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CCNT-COUNT-2: call void @cqrt_copy_i16_controlled(
; CCNT-NOT:     call void @cqrt_copy_i16_controlled(
