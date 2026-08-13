; lowering_io_tape_qq_both_parents.ll — ACCEPT (Phase 7.6). The MULTI-PARENT
; backward-closure fixture for bd 261j(a): `printf("%d", x + y)` with TWO thetas.
;
; The recorded rail is a QQ node — `cq_template_add_i32(%A, %B)`, a producer with
; TWO tainted parents — so the correlation closure must reach BOTH. It does: %A and
; %B each carry a `cqrt_ry` (empty condition set, Rule 3), so both freeze and
; neither is freed, while the recorded QQ rail itself is a plain producer and
; therefore reverses AND frees soundly (its `_unc` recomputes %A+%B from two parents
; that reverse program order keeps at their producer-time values).
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
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[A]], i32 %[[B]])
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[OP]])
; The QQ rail reverses against BOTH still-forward parents, and frees:
; CHECK:     call void @cq_template_add_i32_unc(i32 %[[OP]], i32 %[[A]], i32 %[[B]])
; CHECK:     call void @cqrt_free(i32 %[[OP]])
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
