; lowering_freeze_passthrough_i32.ll — ACCEPT: a tainted INTEGER `freeze` is a
; basis-level identity (Phase-7.1 Increment B). `cq_theta` -> tainted i32 `add`
; template -> `freeze i32` -> `cq_measure`, no FP / select / rotation in the
; lineage. The freeze of an already-defined runtime i32 handle is the handle, so
; `declineTaintEscapes` FOLDS it away (RAUW to the operand + erase): no standing
; freeze remains, the measure reads the handle directly, and the whole-DAG
; uncompute sees the true lineage (a standing freeze would otherwise trip
; FreePoint's `unrecognized-user` reject — that is exactly why the fold, not a
; bare skip, is the accept).
;
; FOLD chosen (pinned): `CHECK-NOT: freeze`. The accept is NARROW — the negative
; siblings `lowering_reject_freeze_escaped_return.ll` /
; `lowering_reject_freeze_measured_fanout.ll` pin the R-B laundering declines.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = add i32 %q, 7                              ; tainted i32 op (HL template)
  %f = freeze i32 %s                              ; basis-level identity -> folded
  %m = call i32 @cq_measure_si32(i32 %f)
  ret i32 %m
}

; The add lowers to a template handle, the freeze is folded away, and the measure
; reads the folded handle directly:
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OP]])
; CHECK-NOT: freeze
; CHECK-NOT: cq taint escape
