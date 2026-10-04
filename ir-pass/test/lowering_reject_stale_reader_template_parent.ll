; lowering_reject_stale_reader_template_parent.ll — DECLINE (bd
; test_C_libtooling-3d8q, P1). THE SIBLING PAIR ON A **TEMPLATE** PARENT, i.e.
; the shape whose ancestry edge only exists because of bd 3qlq.4 finding F-1b-1:
;
;   int q=0; cq_theta(&q,0.3); int t=q&1;
;   int b=t; cq_theta(&b,0.5); int c=t; cq_theta(&c,0.9); return cq_measure(b)+cq_measure(c);
;
; `%t` is a `cq_template_and_i32_hl` rail, and `%b`/`%c` are two in-place Ry on
; IT. The backward closure reaches a template parent only when `WireWalk` is given
; `Taint` (it crosses a chained theta's arg-0 edge on the relation
; `lowerRotations` actually builds the rail from), which is exactly the F-1b-1
; widening — so this file also pins that the 3d8q reader policy passes `&taint`.
; Drop that argument and this module accepts again, silently.
;
; ⚠ NOT the same as `lowering_reject_stale_record_chained_theta_sibling.ll`: there
; the stale reader is a PURE op and the owner is `declineStaleRecordOps`. Here
; there is no pure op at all — every reader is a rotation or a measurement.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %t = and i32 %q, 1
  %b = call i32 @cq_theta_si32(i32 %t, double 5.000000e-01)
  %c = call i32 @cq_theta_si32(i32 %t, double 9.000000e-01)
  %m1 = call i32 @cq_measure_si32(i32 %b)
  %m2 = call i32 @cq_measure_si32(i32 %c)
  %s = add i32 %m1, %m2
  ret i32 %s
}
