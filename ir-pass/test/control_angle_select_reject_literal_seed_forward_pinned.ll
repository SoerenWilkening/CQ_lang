; control_angle_select_reject_literal_seed_forward_pinned.ll — DECLINE (bd
; test_C_libtooling-dm7f.54, item A1): S3's literal half through F2's FORWARD
; model. `%q20 = or (and %q, 3), 20` lies in [20, 24) and `%t = sdiv %q20, 4` is
; therefore exactly 5 = the consumer's literal seed; LVI alone does not
; re-evaluate a value defined above a pinning edge (measured, the `sdiv q, 4`
; drbq.13 shape), so the check seeds `f2Note` with LVI's ranges at the consumer
; and runs `f2Model` forward, F2's own machinery. Its R10 twin with seed 6
; (nothing is pinned to 6) ACCEPTS: `control_angle_select_ry_literal_seed_unpinned.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %k, double 5.000000e-01) #0
  %c = call i1 @cq_theta_i1(i1 false, double 6.000000e-01) #0
  %lo = and i32 %q, 3
  %q20 = or i32 %lo, 20
  %t = sdiv i32 %q20, 4
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %r = call i32 @cq_theta_si32(i32 5, double %ang) #0
  %mr = call i32 @cq_measure_si32(i32 %r)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mr, %mt
  ret i32 %s
}
attributes #0 = { nomerge nounwind }
