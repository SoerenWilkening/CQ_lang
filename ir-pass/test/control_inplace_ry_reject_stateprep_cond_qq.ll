; control_inplace_ry_stateprep_cond_qq.ll — DECLINE, and PRD §14.3's accept row
; A-12 IS CORRECTED BY THIS FIXTURE (measured 2026-09-04, bd
; test_C_libtooling-drbq Inc 4).
;
;     int q = …; cq_theta(&q, …); int p = …; cq_theta(&p, …); int r = 0;
;     if (q == p) { r = 0; cq_theta(&r, .9); }  // a Q+Q condition
;
; §14 listed this as an ACCEPT on the ground that "F2 needs a `ConstantInt`
; operand and a Q+Q compare has none" — which is TRUE, and is not the operative
; clause. The region is refused LATER and for a reason that has nothing to do
; with state prep: the in-place rotation emitter mints its flag with
; `lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, …)`, i.e. with NO Q+Q
; width, so a two-handle compare has no flag template and the tainted `icmp`
; falls through to `lowerOps`, which declines LOUDLY with the generic
; no-template string.
;
; ⚠ IT IS PRE-EXISTING AND ARM-CLASS-INDEPENDENT, WHICH IS WHY IT IS RECORDED
; RATHER THAN FIXED HERE. The CHAINED twin — the same region with
; `cq_theta(&r, .9)` on a live third register, i.e. the Inc-1 shape that has
; shipped since 2026-09-02 — declines with the IDENTICAL string on the PRE-INC-4
; ORACLE and on this binary (measured, `$S/impl/probe/qq_chained.ll`). So Inc 4
; neither introduced nor widened it, and "state prep under a Q+Q condition"
; is not a capability this increment withheld. Tracked as an Inc-4 finding for
; the owner (notes §8); the fix belongs to the emitter's flag mint, not to F1/F2.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}no template for opcode 'icmp i1' in tainted context
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, %p
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
