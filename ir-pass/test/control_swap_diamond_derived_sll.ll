; control_swap_diamond_derived_sll.ll — ACCEPT: derived base at 64-bit width (sll).
;
; The derived-base diamond (test_C_libtooling-9hh) at the `sll` (i64) width.
; Pins the width-dispatch interaction: every fixture in the control_swap family
; is si32, which could hide an i32 width assumption in the emitter's
; suffix-derived rail/Rz/template minting. Width comes from the FIRST arm gate's
; cq_phi suffix (never from the derived Q's SSA type — §4 width-source): rails
; alloc as cqrt_alloc_i64, arm gates as cqrt_rz_i64, the flag pair as
; cq_template_icmp_sgt_i64_hl[/_inv] carrying the i64 LITERAL — while every
; HANDLE stays i32 (Rule 15: width-only ABI, handles are always i32).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_phi_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define i64 @example(i64 %u0, double %a) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %qd = call i64 @cq_phi_sll(i64 %q, double 9.000000e-01)
  %c = icmp sgt i64 %qd, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i64 @cq_phi_sll(i64 %qd, double %a)
  br label %merge
merge:
  %qm = phi i64 [ %q1, %arm ], [ %qd, %entry ]
  %m  = call i64 @cq_measure_sll(i64 %qm)
  ret i64 %m
}

; i32 HANDLES everywhere; i64 only in the alloc seed and the template literal
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %u0)
; CHECK:     call void @cqrt_ry_i64(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i64(i32 %[[Q]], double 9.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i64_hl(i32 %[[Q]], i64 5)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_rz_i64(i32 %[[T]], double %a)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_free(i32 %[[T]])
; CHECK:     call void @cq_template_icmp_sgt_i64_hl_unc(i32 %[[F]], i32 %[[Q]], i64 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i64 @cqrt_measure_i64(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i64

; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
