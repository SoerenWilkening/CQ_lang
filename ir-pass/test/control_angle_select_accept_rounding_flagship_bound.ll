; control_angle_select_accept_rounding_flagship_bound.ll — ACCEPT, and it is the
; fixture that pins the ROUNDING fence's ACCEPT side (bd drbq Inc 2b round-1
; Rule-13 review, lens L7-F1).
;
; The flagship pair `A = 0.9, B = 0.3` is the shape this increment exists for, and
; it is NOT exact in binary64. Measured (`review2b/L7/fp.out`, and reproduced by
; `tools/`-free arithmetic in the fix agent's `delta.c`):
;
;     A        = 0x3FECCCCCCCCCCCCD
;     B        = 0x3FD3333333333333
;     fl(A-B)  = 0x3FE3333333333334        <- the constant this fixture pins
;     delta    = A - (B + fl(A-B)) = -0x1p-54 = -5.551115e-17 rad
;
; `|delta| = 2^-54` is 2^14 times SMALLER than the placeholder threshold
; `kAngleSelectMaxRoundingRad = 2^-40`, so the fence does not move this shape —
; which is the Rule-17 obligation: a fence added for the macroscopic cases
; (pi/1e16 at 0.858 rad, 1.0/1e300 at 1.0 rad) must not decline the ordinary-angle
; C `if/else` we set out to build.
;
; THIS IS ALSO THE DOCUMENTED FIRST INSTANCE OF THE ERROR. The flagship e2e golden
; `slice_control_angle_select_ry.expected.log` emits exactly this constant, so
; every claim of "exact" in this tree now reads "exact in real arithmetic (angle
; additivity on one axis); in IEEE double the emitted true-arm angle is
; `B + fl(A-B)`, `|delta| <= 1/2 ulp(A-B)`". The threshold itself is a PLACEHOLDER
; pending the owner ruling recorded in CONTROL_IN_PLACE_INC2B_NOTES.md §9.
;
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`), as for every 2b accept.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
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
; the UNCONDITIONAL twin at B = 0.3
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; THE ROUNDED DIFFERENCE, pinned as BITS: fl(0.9 - 0.3), delta = -2^-54
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; A STRAY ROTATION AFTER THE EMITTED STREAM was invisible to every one of the 17
; accept fixtures (round-1 Rule-13 review, L6-N11): an adjacency chain stops at
; its last `CHECK-NEXT`, and a `NOROUTE`-style whole-body negative cannot be used
; on a rotation symbol because the legitimate twin and gate are rotations. A
; TRAILING `CHECK-NOT` runs from the last match to EOF, which is exactly the
; uncovered region — and it is where a leaked rotation on a FROZEN rail would sit.
; CHECK-NOT: call void @cqrt_ry_
; CHECK-NOT: call void @cqrt_rz_

; NOROUTE:     define{{.*}}@example
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: select
; the exact-arithmetic answer 0.6 is NOT what is emitted, and pinning its absence
; is the whole content of the rounding finding
; NOROUTE-NOT: double 6.000000e-01

; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
