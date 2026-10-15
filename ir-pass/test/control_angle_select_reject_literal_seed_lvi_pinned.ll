; control_angle_select_reject_literal_seed_lvi_pinned.ll — DECLINE (bd
; test_C_libtooling-dm7f.54, item A1): the DIRECT pin of S3's literal half,
; `angleSelectLiteralSeedPinned`. A TAINTED value (`%z = and %t, 0`, a template
; rail) is PROVEN EQUAL to the consumer's literal seed 0 at the consumer
; (`LazyValueInfo::getConstantRange(%z, T)` is the singleton {0}), so the literal
; may be the image of a value substitution of a live register, and the region is
; refused with F2's string. Hand IR (`-O1` folds `and %t, 0`): the C-reachable
; members of this class (review p7, the `sdiv` variant) are masked today by the
; enclosing diamond's `control flow` (`..._literal_seed_pinned_p7.ll`), and this
; file is what keeps the fence itself red-green and mutation-killable.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)
define i32 @example(i32 %k) {
entry:
  %t = call i32 @cq_theta_si32(i32 %k, double 5.000000e-01) #0
  %c = call i1 @cq_theta_i1(i1 false, double 6.000000e-01) #0
  %z = and i32 %t, 0
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %r = call i32 @cq_theta_si32(i32 0, double %ang) #0
  %mr = call i32 @cq_measure_si32(i32 %r)
  %mz = call i32 @cq_measure_si32(i32 %z)
  %s = add i32 %mr, %mz
  ret i32 %s
}
attributes #0 = { nomerge nounwind }
