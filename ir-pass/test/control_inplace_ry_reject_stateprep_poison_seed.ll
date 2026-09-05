; control_inplace_ry_reject_stateprep_poison_seed.ll — DECLINE (F1, the FIRST
; sub-clause: the SEED must be a `ConstantInt` or `ConstantFP`). The POISON sibling of
; `control_inplace_ry_reject_stateprep_undef_seed.ll`.
;
; ⚠ ADDED 2026-09-05 (round-1 Rule-13 review, lens L1 finding F-L1-2, probe
; `p/d01_poison_seed.ll`) BECAUSE THE TWO SHIPPED `undef`/`poison` FIXTURES DO NOT
; PIN THIS CLAUSE. In `..._reject_stateprep_undef_incoming.ll` and
; `..._poison_incoming.ll` the SEED is `i32 0` and only the MERGE INCOMING is
; `undef`/`poison`, so clause 1 (which is applied to the seed) PASSES and the
; decline comes from clause 2. Relax clause 1 to `isa<Constant>` — the exact
; mutation those files' headers name — and both stay GREEN. This file and its
; `undef` sibling are the ones that go red, because `UndefValue` and
; `PoisonValue` ARE `Constant`s.
;
; The bd `xy9n` literal-integrity argument belongs HERE and not there: with
; clause 1 relaxed this module emits `cqrt_alloc_i32(i32 poison)`, i.e. a literal
; `undef` in an emitted gate slot, which the `-O0` stage 3 may read as a
; different value at each site. In the `_incoming` files `undef` never reaches a
; gate slot at all — the alloc argument is `Theta->getArgOperand(0)`, which is
; the `i32 0` seed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed does not match the merge incoming under quantum control
; CHECK-NOT: cqrt_alloc_i32(i32 poison)
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 poison, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ poison, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mq
}
