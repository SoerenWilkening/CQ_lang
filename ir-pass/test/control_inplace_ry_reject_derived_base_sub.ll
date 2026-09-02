; control_inplace_ry_reject_derived_base_sub.ll — DECLINE. The `sub` spelling of
; R4's condition-wire fence (round-1 Rule-13 review, lens L1 §1).
;
;     int q = cq_theta(u, .5);
;     int b = q - 1;                 /* derived FROM the condition register */
;     if (q > 5) b = cq_theta(b, .9);
;
; WHY `sub` GETS ITS OWN FIXTURE ALONGSIDE `add` AND `xor`: R4 is the SOLE fence
; for this whole family, and the two shared wire walkers are ASYMMETRIC across
; the three opcodes. `WireWalk::collectWireValues` crosses `Add` and `Xor`
; forward but NOT `Sub`, and `findNonDiagonalWireGate` deliberately crosses none
; of them ("AN IN-PLACE VALUE SELF-UPDATE IS NOT CROSSED HERE, and that is a
; MEASURED decision"). So for a base derived by any of the three the wire walk
; returns nothing, `condWireDisposition` defers nothing, and what prints is R4's
; OWN string — measured for `add`, `sub` and a two-hop `add;xor` chain alike.
; Pinning only `add` would let a change to the `Sub` asymmetry pass unnoticed.
;
; The `sub` hop is admitted by `railWireClosure` for the same reason `add`/`xor`
; are: `ArithLowering`'s `inPlaceReassignRailOperand` lowers a handle-LHS `sub`
; in place on the parent's rail when the M-C fence admits it, and that fence runs
; in `lowerOps`, long after detection. Both roots are therefore admitted and the
; region declines (notes finding H).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error{{.*}}rotation arm on a condition wire under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %b = sub i32 %q, 1
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %bt = call i32 @cq_theta_si32(i32 %b, double 9.000000e-01)
  br label %merge
merge:
  %bm = phi i32 [ %bt, %arm ], [ %b, %entry ]
  %m = call i32 @cq_measure_si32(i32 %bm)
  ret i32 %m
}
