; control_inplace_ry_reject_stateprep_range_knownbits.ll — DECLINE (F2, the
; RANGE clause, and specifically its KNOWN-BITS half).
;
; F2's edge range is `computeConstantRange(H) ∩ fromKnownBits(computeKnownBits(H))`
; — the two halves `computeConstantRangeIncludingKnownBits` combines, spelled
; out because that entry point wants a `SimplifyQuery`. THIS FIXTURE ISOLATES THE
; SECOND HALF: `%b` is a `zext`, i.e. a `CastInst`, and `computeConstantRange`
; returns the FULL range for one (its `setLimitsForBinOp` table covers
; `BinaryOperator`s only). `computeKnownBits` sees the `i1` source and gives
; `[0,2)`; the `ne 0` edge then intersects to the singleton `{1}`, which is the
; seed. Delete the `fromKnownBits(...)` intersection and this file goes GREEN as
; an ACCEPT — that is its red-green relation, and it is the only file in the
; family with it (round-1 Rule-13 review, mutation table row M9).
;
; The source shape is `int b = (q > 7); int r = 1; if (b) r = cq_theta(b, .9);`
; — the L2 `k04` class. ⚠ From plain C that spelling does NOT reach the pass in
; this form: instcombine rewrites `icmp ne (zext %c), 0` to `%c` and DELETES
; `%b`, which is the residual documented in the notes §10 and PRD §14.2b (F2 can
; only see registers that still exist). The module below keeps `%b` alive as a
; compare operand, which is the shape a caller-supplied `.ll` — or a future
; `-O1` that stops doing that rewrite — presents.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 7
  %b  = zext i1 %c0 to i32
  %c  = icmp eq i32 %b, 0
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 1, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 1, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
