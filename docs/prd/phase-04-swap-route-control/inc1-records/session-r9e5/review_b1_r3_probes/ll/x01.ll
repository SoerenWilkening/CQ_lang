; x01 — AREA 3: a taint-growth event AFTER `reverifyRailCondReads`.
; The rail's arg-0 is a const-global QROM read (`load i1`), which is CLASSICAL at
; round 1, at the round-2 fixpoint AND at the re-verification stage, and becomes
; TAINTED at `lowerQramReads` (pipeline slot 510 > the stage's 431) because that
; stage RAUWs the load onto the tainted `cqrt_qram_load_i1` result. Two thetas
; share that arg-0, so at `lowerRotations` BOTH are `Chained` onto ONE rail and
; the select's control read fires after the SIBLING's Ry. F-B1R2-1 verbatim, one
; growth event over.
@tbl = internal unnamed_addr constant [8 x i1] [i1 true, i1 false, i1 true, i1 true, i1 false, i1 true, i1 false, i1 true]
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @qrom_rail(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [8 x i1], ptr @tbl, i64 0, i64 %i
  %x = load i1, ptr %g
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %b = call i1 @cq_theta_i1(i1 %x, double 2.500000e-01)
  %a = select i1 %b, i32 2, i32 5
  %m1 = call i32 @cq_measure_si32(i32 %a)
  %m2 = call i1 @cq_measure_i1(i1 %b3)
  %z = zext i1 %m2 to i32
  %s = add i32 %m1, %z
  ret i32 %s
}
