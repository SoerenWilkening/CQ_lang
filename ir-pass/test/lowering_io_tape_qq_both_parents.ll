; lowering_io_tape_qq_both_parents.ll — ACCEPT (Phase 7.6). The MULTI-PARENT
; backward-closure fixture for bd 261j(a): `printf("%d", x + y)` with TWO thetas.
;
; The recorded rail is a QQ node with TWO tainted parents — so the correlation
; closure must reach BOTH. (Since bd r2j3.33 the node is the IN-PLACE
; `cqrt_add_i32(%B, %A)` on %A's rail, whose borrowed source %B is a DAG parent by
; the same ancestor-edge loop; before it, the template `cq_template_add_i32(%A,
; %B)`.) It does: %A and
; %B each carry a `cqrt_ry` (empty condition set, Rule 3), so both freeze and
; neither is freed, while the recorded QQ node itself reverses soundly: its adjoint
; (`cqrt_sub_i32(%B, %A)`; the template's `_unc` + free before r2j3.33) reads a
; source that reverse program order keeps at its producer-time value.
;
; WHY THIS FIXTURE EXISTS. The Rule-13 round proposed, as a mutant that would
; survive the whole family, "truncate the backward closure to the FIRST tainted
; operand of a multi-parent gate" — every other fixture has single-parent gates
; only, so all of them would still pass while `printf("%d", x+y)` silently regained
; a hidden-measurement free on %B. This is the fixture that kills it. The closure is
; built from `DagTraversal`'s ancestor edges, which are pushed for EVERY tainted
; operand (the same loop that already enqueues both parents of a QQ node); dropping
; any one of them is an UNDER-freeze, and under-freeze is the over-accept class.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEA < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEB < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0, i32 %u1) {
entry:
  %a = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %s = add i32 %a, %b
  %z = call i32 (ptr, ...) @printf(ptr @.str, i32 %s)
  ret void
}

; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[A]], double 5.000000e-01)
; CHECK:     %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:     call void @cqrt_ry_i32(i32 %[[B]], double 2.500000e-01)
; bd r2j3.33 (dm7f.51 step 1): %a's old value is dead and the sum survives (it is
; taped), so the QQ add lowers IN PLACE on %a's rail with %b the BORROWED source:
; CHECK:     call void @cqrt_add_i32(i32 %[[B]], i32 %[[A]]), !cq.inplace.qq
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[A]])
; The in-place gate reverses against its still-forward source (`cqrt_sub_i32`, the
; adjoint `EmitInverse` derives), returning %a's rail to %a — the same final
; state the out-of-place `_unc` + free of the old QQ rail produced:
; CHECK:     call void @cqrt_sub_i32(i32 %[[B]], i32 %[[A]]), !cq.inplace.qq
; Both parents reverse:
; CHECK:     call void @cqrt_ry_i32(i32 %[[B]], double -2.500000e-01)
; CHECK:     call void @cqrt_ry_i32(i32 %[[A]], double -5.000000e-01)
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; NEITHER parent is freed — the closure reached the second operand, not just the
; first. ONE PREFIX PER PARENT: a CHECK-NOT is bounded by the next positive
; directive of its own prefix, so the two guards cannot share one prefix or the
; FIRST one goes dead (see lowering_io_tape_partial_freeze_order.ll's header).
; Guarding %A is the whole point of this fixture — %A is the operand a
; first-operand-only closure would still freeze, so a dead %A window would leave
; the mirror mutant (LAST-operand-only closure) completely unguarded.
; NOFREEA:     %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREEA-NOT: call void @cqrt_free(i32 %[[A2]])
; NOFREEB:     %[[B2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; NOFREEB-NOT: call void @cqrt_free(i32 %[[B2]])
