; control_angle_select_ry_literal_seed_condwire_exempt.ll — ACCEPT (bd
; test_C_libtooling-dm7f.54 round-2 review F2): the direct pin of the CondWire
; exclusion in the literal-seed check. `%z = and %t, 0` is PROVEN EQUAL to the
; seed 0 at the consumer (the LVI singleton that makes
; `..._reject_literal_seed_lvi_pinned.ll` decline), but here `%z` is on the angle
; select's OWN condition wire (`%c = icmp eq %z, 0`), so F2's exclusion
; (`f2ExcludedAtTest`) applies and the literal is admitted, as F2 admits the
; same pin at an if/else. Hand IR (`-O1` folds `and %t, 0`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK: call void @cqrt_ry_i32_controlled(
; CHECK: call void @cqrt_ry_i32_controlled(

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %k) {
entry:
  %t = call i32 @cq_theta_si32(i32 %k, double 5.000000e-01) #0
  %z = and i32 %t, 0
  %c = icmp eq i32 %z, 0
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %r = call i32 @cq_theta_si32(i32 0, double %ang) #0
  %mr = call i32 @cq_measure_si32(i32 %r)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mr, %mt
  ret i32 %s
}

attributes #0 = { nomerge nounwind }
