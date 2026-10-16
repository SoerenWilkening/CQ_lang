; lowering_uncompute_orphan_dead_op.ll — ACCEPT (bd test_C_libtooling-r2j3.7, the
; original shape measured 2026-10-01 on 52e669c4).
;
; `%a = add i32 %q, 1` has NO USER. It lowers to a forward template
; `cq_template_add_i32_hl(h, 1) -> h_op`, a live CNOT-style copy of the user's
; register `h`. Before the fix nothing reversed it: the dead-terminal group that owns
; it recovers `h`'s whole DAG, `h` also feeds the compare a control emitter owns, the
; DAG is `NotClosed`, and the group leaks; the M-B interior partition skipped it
; because it is a terminal (`isInteriorTerminalHandle` (I2)) and has no forward
; consumer (I4). `opt` rc 0, no `_unc`, no free.
;
; THE FIX: an ORPHAN rail (a terminal with no user at all) that no terminal group
; reversed is an M-B candidate (ChainWalk `isInteriorTerminalHandle` (I2)/(I4)),
; anchored on its own definition (`planInteriorComponent`): it is discharged right
; after it is minted, while its parent `h` is provably unmoved (clause (d)), BEFORE
; any later gate on `h`. Single ownership is the caller's `ReversedGates`/
; `ReversedRails` exclusion. The same body in `main` lowers identically (bd r2j3.7:
; `main` runs the helper's dead-record discipline, owner ruling
; owner-ruling-r2j3-7-main-dead-record-2026-10-16).
;
; Analytic: h_op = h + 1 is a basis permutation of h; `_unc` XORs h + 1 back while
; h holds the value the forward gate read, so h_op is |0> at the free (stage 2b).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @f(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[OP]])
; CHECK-NEXT: call i32 @cq_template_icmp_ult_i32_hl(i32 %[[H]], i32 4)
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[M]], double 5.000000e-01)
; CHECK-NEXT: %[[MOP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[M]], i32 1)
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[MOP]], i32 %[[M]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[MOP]])
; CHECK-NEXT: call i32 @cq_template_icmp_ult_i32_hl(i32 %[[M]], i32 4)

define i32 @f(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = add i32 %q, 1
  %c = icmp ult i32 %q, 4
  %s = select i1 %c, i32 4, i32 99
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

define i32 @main() {
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %a = add i32 %q, 1
  %c = icmp ult i32 %q, 4
  %s = select i1 %c, i32 4, i32 99
  %m = call i32 @cq_measure_si32(i32 %s)
  %r = call i32 @f(i32 %m)
  ret i32 %r
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
