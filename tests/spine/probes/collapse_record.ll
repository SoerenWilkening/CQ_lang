; Rule 2 classical collapse of a template rail with no original instruction (cq-e373): a vector lane's
; template is minted by aggr with no single original instruction, so once its source is measured the
; spine recomputes it from its record (fromRecord) with CR §2's totalization made explicit.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; and_i32_hl on lane 0, read after x is measured: recomputed as a classical and of the outcome.
define i32 @lane_and(i32 %x0, double %t, i32 %k) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %v0 = insertelement <2 x i32> poison, i32 %x, i64 0
  %v = insertelement <2 x i32> %v0, i32 %k, i64 1
  %a = and <2 x i32> %v, <i32 3, i32 5>
  %m = call i32 @cq_measure_si32(i32 %x)
  %e = extractelement <2 x i32> %a, i64 0
  %r = add i32 %e, %m
  ret i32 %r
}
; CHECK lane_and: call i32 @cq_template_and_i32_hl(
; CHECK lane_and: call void @cq_template_and_i32_hl_unc(
; CHECK lane_and: %{{c}} = and i32 %{{m}}, 3
; CHECK-COUNT lane_and: cqrt_measure_i32 1

; udiv_i32_lh with the measured lane as divisor: §2's udiv(a, 0) = 2^W - 1 is explicit.
define i32 @lane_udiv(i32 %x0, double %t) {
entry:
  %x = call i32 @cq_theta_si32(i32 %x0, double %t)
  %v0 = insertelement <2 x i32> poison, i32 %x, i64 0
  %v = insertelement <2 x i32> %v0, i32 7, i64 1
  %d = udiv <2 x i32> <i32 100, i32 100>, %v
  %m = call i32 @cq_measure_si32(i32 %x)
  %e = extractelement <2 x i32> %d, i64 0
  %r = add i32 %e, %m
  ret i32 %r
}
; CHECK lane_udiv: call i32 @cq_template_udiv_i32_lh(
; CHECK lane_udiv: %{{z}} = icmp eq i32 %{{m}}, 0
; CHECK lane_udiv: %{{q}} = udiv i32 100, %{{s}}
; CHECK lane_udiv: %{{c}} = select i1 %{{z}}, i32 -1, i32 %{{q}}
; CHECK-COUNT lane_udiv: cqrt_measure_i32 1
