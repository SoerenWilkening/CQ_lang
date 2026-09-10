; control_swap_select_rail_inplace_xor_bridge.ll — ACCEPT (bd
; test_C_libtooling-r9e5, Rule-13 round-1 item F-B1R1-3): the select-side pin of
; the F-1b2-4 structural ground that `railCondWireDisposition`'s header states
; for the kickback and the 4.4 select INHERITS. The compare path's positional
; prong exists for a theta on ANOTHER wire that would ALIAS the condition's rail
; through a dtzb in-place `xor` (`x = b ^ 1; c = cq_theta(x, θ)`); the rail path
; drops that prong because a condition rail is always read LATER by its own
; consumer — the branch for the kickback, the two mid-block `cqrt_cnot` reads of
; the copy flag here — so M-C's G6 refuses the in-place conversion and the `xor`
; lowers OUT of place onto a fresh rail: `cq_template_xor_i1_hl(%h, true)` mints
; `%h_op`, the second `cqrt_ry_i1` moves `%h_op`, and `%h` — the register the
; merge controls on — is never relabelled. If M-C's G6 ever admits an in-place op
; on a rail with a later read, this file goes RED alongside
; `control_phase_kickback_rail_inplace_xor_bridge.ll`, and the prong must return
; at BOTH consumers. The compare spelling is the documented over-decline
; `control_phase_kickback_reject_cmp_inplace_xor_bridge.ll`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %x = xor i1 %b, true
  %c = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %s = select i1 %b, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %s)
  %n = call i1 @cq_measure_i1(i1 %c)
  %z = zext i1 %n to i32
  %r = add i32 %m, %z
  ret i32 %r
}

; ORD: %h = call i32 @cqrt_alloc_i1(i1 false)
; ORD-NEXT: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; ORD-NEXT: %h_op = call i32 @cq_template_xor_i1_hl(i32 %h, i1 true)
; ORD-NEXT: call void @cqrt_ry_i1(i32 %h_op, double 9.000000e-01)
; ORD-NEXT: %bf = call i32 @cqrt_alloc_i1(i1 false)
; ORD-NEXT: call void @cqrt_cnot(i32 %h, i32 %bf)
; ORD-NEXT: %out = call i32 @cqrt_alloc_i32(i32 0)
; ORD-NEXT: %selop = call i32 @cqrt_alloc_i32(i32 2)
; ORD-NEXT: call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out)
; ORD-NEXT: call void @cqrt_x(i32 %bf)
; ORD-NEXT: %selop1 = call i32 @cqrt_alloc_i32(i32 5)
; ORD-NEXT: call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out)
; ORD-NEXT: call void @cqrt_x(i32 %bf)
; ORD-NEXT: call void @cqrt_cnot(i32 %h, i32 %bf)
; ORD-NEXT: call void @cqrt_free(i32 %bf)
; ORD-NEXT: %m2 = call i32 @cqrt_measure_i32(i32 %out)
; ORD-NEXT: %m3 = call i1 @cqrt_measure_i1(i32 %h_op)

; The xor is OUT of place (a `cq_template_xor_i1_hl` producer, never a
; `cqrt_xorc_i1` on %h), no cqrt_x on either user rail, one free, and exactly
; one Ry on the condition register %h.
; NOX-NOT: @cqrt_xorc_i1(i32 %h
; NOX-NOT: call void @cqrt_x(i32 %h)
; NOX-NOT: call void @cqrt_x(i32 %h_op)
; NOX-NOT: @cqrt_cswap
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; RYCNT-COUNT-1: call void @cqrt_ry_i1(i32 %h,
; RYCNT-NOT: call void @cqrt_ry_i1(i32 %h,
