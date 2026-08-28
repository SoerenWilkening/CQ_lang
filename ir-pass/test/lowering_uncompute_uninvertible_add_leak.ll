; lowering_uncompute_uninvertible_add_leak.ll — ACCEPT-with-LEAK pin (bd
; test_C_libtooling-6uqc Inc 2a Rule-13 round, SHOULD-FIX 4). This is the
; ORIGINAL `add`-spelled body of lowering_uncompute_uninvertible.ll, which
; DECLINED at pre-M-C HEAD (`dead chain contains an un-invertible primitive`)
; and now lowers: M-C converts the dead terminal `add` to an in-place
; `cqrt_addc_i32` on the un-invertible parent's rail, so the chain loses its
; only template PRODUCER — no terminal, never recovered, and the loud decline
; becomes the Rule-6 sanctioned SAFE LEAK (nothing `_unc`'d, nothing freed).
; That flip is a documented Inc-2a scope effect (the G8 rejection note in
; ArithLowering.h), and this fixture is its record: leak-direction only, never
; a wrong free or wrong `_unc`. The re-vehicled `mul` fixture keeps the
; un-invertible DECLINE pinned; this one pins the `add` spelling's disposition.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_cnot(i32)

define void @slice(i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %bad = call i32 @cqrt_cnot(i32 %q)             ; un-invertible primitive (no _unc form)
  %t   = add i32 %bad, 7                          ; converts in place -> orphaned chain
  ret void
}

; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      %[[BAD:.*]] = call i32 @cqrt_cnot(i32 %[[H]])
; CHECK:      call void @cqrt_addc_i32(i32 %[[BAD]], i32 7)
; CHECK-NOT:  _unc
; CHECK-NOT:  call void @cqrt_free
