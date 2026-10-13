; control_angle_select_ry_verbatim_pi_1e16.ll — ACCEPT: `A = pi`, `B = 1e16`,
; every gate angle VERBATIM (bd test_C_libtooling-dm7f.6, owner ruling
; 2026-10-03 item (1): each gate gets exactly the double the C program computes).
;
;     cq_theta(&r, (q == 5) ? M_PI : 1e16);
;
; The measured counter-example of the retired by-difference stream: it realized
; `B + fl(A - B) = 4.0` on the true edge where the source wrote `pi` (0.858 rad
; wrong), and the 2^-40 residual bound declined it. The X-bracket route (owner
; ruling 2026-10-13) computes no difference: `pi` lands in the f = 1 gate and
; `1e16` in the bracketed f = 0 gate, bit for bit the source's doubles, so the
; flag-1 branch is Ry(pi) and the flag-0 branch Ry(1e16).
;
; THIS FILE WAS `control_angle_select_reject_rounding_pi_1e16.ll` (drbq Inc-2b
; round-1 finding L7-F1). Its three siblings that pinned the retired bound itself
; (`accept_rounding_at_bound`, `reject_rounding_above_bound`,
; `accept_rounding_flagship_bound`) and the exact-difference cell
; (`accept_exact_difference_large`) were deleted with the bound: no difference is
; computed, so they had no subject left.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOSUB < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  ; 0x400921FB54442D18 = pi ; 0x4341C37937E08000 = 1e16
  %ang = select i1 %c, double 0x400921FB54442D18, double 0x4341C37937E08000
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 1.000000e+16)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; NOSUB-NOT: fsub
; NOSUB-NOT: 0xC341C37937E07FFE
