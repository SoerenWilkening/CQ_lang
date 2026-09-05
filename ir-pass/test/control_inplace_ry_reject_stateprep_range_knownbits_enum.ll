; control_inplace_ry_reject_stateprep_range_knownbits_enum.ll — DECLINE, and it
; RETIRES A RECORDED OVER-ACCEPT (round-2 Rule-13 review, lens R1 finding
; F-R1-3), closed by the round-3 fix along the way.
;
; `%t = and %q, 4` has the exact value set `{0,4}`, which `ConstantRange` CANNOT
; represent: `fromKnownBits` answers the HULL `[0,5)`, so the `ne 0` edge gave
; `[1,5)` and never the true singleton `{4}`. The shipped fence therefore missed
; a genuine A3 pin one bit up from `..._range_mask1.ll`'s, and F-R1-3 recorded
; both the miss and its fix: "when `Known` leaves ≤ 8 bits unknown, ENUMERATE
; the ≤ 256 `Known`-consistent values and intersect with `Edge`". `f2Refine`
; does exactly that, on EVERY value the walk learns about, and the pin is found.
;
; ⚠ IT WAS NOT REACHABLE FROM PLAIN C AT THIS CLANG AND STILL IS NOT. IPSCCP's
; lattice is a `ConstantRange` too, so it fails to pin `and q,4` and performs NO
; fold — the two analyses failed TOGETHER, which is why F-R1-3 cost nothing
; while F-R1-1's class (where the fold SUCCEEDED and the question was asked of
; the wrong value) was a miscompile. The fence is now STRONGER than the folder
; that creates the ambiguity, which is the safe direction and removes the
; retirement trigger F-R1-3 left behind.
;
; BOUNDARY, both directions and both measured: `hb03` (`and q,5`, `ugt 4`,
; seed 5) and `hb04` (mask 1) DECLINED BEFORE this change and still do — the
; hull happened to be tight there, so the enumeration adds nothing;
; `control_inplace_ry_stateprep_cond_derived.ll` (`and q,6`, `eq 2`, seed 0)
; still ACCEPTS, because 5 unknown bits enumerate to a set that does not contain
; the seed. The enumeration only ever NARROWS, so it can only ever add declines.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = and i32 %q, 4
  %c = icmp eq i32 %t, 0
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 4, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 4, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}
