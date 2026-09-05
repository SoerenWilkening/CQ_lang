; control_inplace_ry_reject_stateprep_i1_arm_flag.ll — DECLINE, and this is the
; PLAIN-C-REACHABLE half of the `i1` story (round-3 Rule-13 fix).
;
; This module is the `-O1` image of, verbatim (`$S/fix3/q/z02_i1_flag_arm.c`):
;
;     int slice(void){ int q = cq_theta(3, 0.3);
;                      _Bool c = (q == 5);
;                      _Bool r = 1;
;                      if (c) r = cq_theta(c, 0.9);   /* IN-PLACE Ry on the FLAG */
;                      return (int) cq_measure(r) + (int) cq_measure(q); }
;
; `clang -O1` substitutes `true` for `c` inside the arm (the arm edge proves it),
; so what reaches the pass is `call i1 @cq_theta_i1(i1 true, …)` — a STATE PREP
; whose seed is the fold of the condition register. The `i1` seed and the `i32`
; compare literal have different types, so the shipped `K->getType() ==
; SeedI->getType()` gate skipped every clause of F2 and this ACCEPTED, minting a
; fresh `cqrt_alloc_i1(1)` where the source rotates the flag's own rail.
;
; The un-folded spelling of the same program declines LOUDLY AND DIFFERENTLY —
; `rotation arm shares the condition flag` (`q/z04_i1_arm_flag.c`, which keeps
; the flag live so the fold cannot happen) — which is the Inc-2b F-11 structure
; exactly: the class was reachable ONLY through the fold.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 true, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ true, %entry ]
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %mq = call i32 @cq_measure_si32(i32 %q)
  ret i32 %mq
}
