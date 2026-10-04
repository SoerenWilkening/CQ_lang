; control_phase_kickback_rail_inplace_xor_bridge.ll — ACCEPT (bd 3qlq.4, Rule-13
; round-2 finding F-1b2-4): the ONE aliasing a wire walk cannot see, on a RAIL
; condition, and why the rail path may drop the compare path's positional prong.
;
;     _Bool b = b0; cq_theta(&b, .5); _Bool x = b ^ 1; _Bool c = x; cq_theta(&c, .9);
;     if (b) cq_phi(.7); return cq_measure(c);
;
; The compare path keeps its positional scan for "a theta on ANOTHER wire the
; walk never sees" (P5 in `condWireDisposition`) — the residual target being a
; dtzb in-place `add`/`xor` that would make `x` ALIAS `b`'s rail, so that
; `c = x; cq_theta(&c, .9)` moves the register the branch then reads. The rail path
; has no such prong, and this file pins WHY that is sound rather than lucky: M-C's
; G6 ("no data use AFTER the site") refuses the in-place conversion on a rail the
; branch reads later, so the `xor` lowers OUT of place onto a FRESH rail
; (`cq_template_xor_i1_hl(h, true) -> h_op`), `c` rotates `h_op`, and the
; kickback rides `h` untouched. (The pass also prints the lyyf warn-and-lower
; `non-diagonal gate over a live derived record` on stderr for the derived
; record `x` — exit 0, the record left allocated, Rule 6 untouched.) The compare
; spelling of the same program is the OVER-DECLINE twin
; `control_phase_kickback_reject_cmp_inplace_xor_bridge.ll`.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %x = xor i1 %b, true
  %c = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %c)
  %z = zext i1 %m to i32
  ret i32 %z
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1_hl(i32 %[[H]], i1 true)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[X]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H]], double 0x3FE6666666666666), !cq.branchphase
; CHECK-NEXT: {{.*}} = call i1 @cqrt_measure_i1(i32 %[[X]])
; CHECK-NOT: cqrt_xorc
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: call i1 @cq_theta_i1(
; XCNT-NOT: call void @cqrt_x(
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
