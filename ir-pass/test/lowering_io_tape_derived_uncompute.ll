; lowering_io_tape_derived_uncompute.ll — ACCEPT (Phase 7.6): `putchar(x + 1)` on a
; tainted x, then dead. The DERIVED value `x+1` (a `cq_template_add` producer) is
; taped, then the WHOLE source DAG uncomputes through the Phase-5 spine: the add is
; reversed (`_unc`) and `x+1` freed, then x's own ry is reversed and x freed — all
; AFTER the tape write captured the value (Bennett copy-out). The kept output rail
; is never reversed/freed. Confirms a tape write recognized as a sink lets a derived
; source lineage uncompute normally (PRD-7.6 §2.4).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @putchar(i32)

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = add i32 %q, 1
  %r = call i32 @putchar(i32 %s)
  ret void
}

; The derived add is taped, then the whole DAG is reversed (add `_unc` + free of the
; derived rail, then x's ry adjoint + free of x) AFTER the tape write:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[OP]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
; CHECK-NOT: call{{.*}}@putchar
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape
