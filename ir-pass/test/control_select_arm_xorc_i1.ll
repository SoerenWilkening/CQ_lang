; control_select_arm_xorc_i1.ll — ACCEPT (bd test_C_libtooling-dm7f.81, R11 round 1
; C-F2): the i1 width of the controlled xor-immediate. `select i1 %c, i1 true,
; i1 %b` (a constant-true arm and a runtime classical bool) writes
; `cqrt_xorc_i1_controlled(f, out, true)` on f and, X-bracketed, the classical %b
; on ¬f. The i1 immediate is a `bool` in the C prototype, so its declaration
; carries `zeroext` (bd etj3 / r2j3.20).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

; SILENT-NOT: {{.}}

; CHECK-LABEL: define i1 @example(
; CHECK:      %[[F:[0-9a-zA-Z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK-NEXT: %[[O:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_xorc_i1_controlled(i32 %[[F]], i32 %[[O]], i1 true)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_xorc_i1_controlled(i32 %[[F]], i32 %[[O]], i1 %b)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK:      declare void @cqrt_xorc_i1_controlled(i32, i32, i1 zeroext)

; Neither arm is a rail, and no controlled copy (or its declaration) is minted.
; NEG-NOT: @cqrt_alloc_i1(i1 true)
; NEG-NOT: @cqrt_alloc_i1(i1 %b)
; NEG-NOT: cqrt_copy_i1_controlled

declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)

define i1 @example(i32 %u0, i1 %b) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %s = select i1 %c, i1 true, i1 %b
  %m = call zeroext i1 @cq_measure_i1(i1 zeroext %s)
  ret i1 %m
}
