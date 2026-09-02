; lowering_uncompute_interior_region_addc_after_readers.ll — ACCEPT (M-B
; Increment 6, clause (d2); bd test_C_libtooling-160a Rule-13 round, finding
; F1e). Third of three: the write on the routed base is RIGHT of every reader of
; the chain, so the interval is genuinely clean and the chain discharges.
;
; This is the fixture that stops its two leak siblings from being vacuous. Same
; program, same recorded route group, ONE line moved: `cqrt_addc_i32(%h, 5)` now
; follows the last reader of `%h_op` (`%h_op & 7`, whose rail is measured). The
; clause-(d) RIGHT disjunct (`provablyBefore(At, M)`) then holds for the addc,
; the route group is exempted as a unit by (d2), and the component discharges
; LIFO — `and_unc`, free, `mul_unc`, free — all of it BEFORE the addc runs.
;
; READ THE ORDER, IT IS THE PROOF. `mul_i32_hl_unc(%h_op, %h, 37)` is emitted
; while `%h` still holds the label the forward `mul` read: the two cswaps between
; them restore it (clause (d2)), the arm `Rz` landed on the WORK rail and is
; diagonal anyway, and the only other write on `%h` in the function comes after.
; Move that addc one line earlier and this becomes
; lowering_uncompute_interior_leak_region_addc_inside.ll.
;
; RED-CHECKED against an `f27c7fd` (pre-Increment-6) plugin: the chain does not
; discharge there at all (the strip is not an interior consumer), so the two
; `_unc`/free pairs below are absent.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cqrt_addc_i32(i32, i32)

define i32 @addc_after_all_readers(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = mul nsw i32 %q, 37
  %k = and i32 %d, -8
  %c = icmp eq i32 %k, 40
  br i1 %c, label %arm, label %merge
arm:
  %g = call i32 @cq_phi_si32(i32 %q, double 0x400921FB54442D18)
  br label %merge
merge:
  %p = phi i32 [ %g, %arm ], [ %q, %entry ]
  %t = and i32 %d, 7
  %m2 = call i32 @cq_measure_si32(i32 %t)
  call void @cqrt_addc_i32(i32 %p, i32 5)
  %m1 = call i32 @cq_measure_si32(i32 %p)
  %s = add i32 %m1, %m2
  ret i32 %s
}

; CHECK-LABEL: define i32 @addc_after_all_readers(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 37)
; CHECK-NEXT: %[[K:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[D]], i32 -8)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 40)
; the region, CONTROL-IN-PLACE since drbq Inc 2a: one `cqrt_rz_<W>_controlled` on
; the user's own register in place of the route quintuple — no work rail, no
; CSWAP, nothing to free but the flag.
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[K]], i32 40)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[D]], i32 7)
; The discharge — LIFO, each free after its own adjoint, and BOTH strictly before
; the in-place write on the borrowed parent:
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[K]], i32 %[[D]], i32 -8)
; CHECK-NEXT: call void @cqrt_free(i32 %[[K]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 37)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[T]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 5)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
