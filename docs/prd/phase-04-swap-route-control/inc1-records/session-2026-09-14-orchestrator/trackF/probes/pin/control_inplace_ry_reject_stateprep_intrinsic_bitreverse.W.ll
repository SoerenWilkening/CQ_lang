; control_inplace_ry_reject_stateprep_intrinsic_bitreverse — DECLINE (F2-semantic: the pinned register is produced by a CURATED
; `llvm.*` INTEGER INTRINSIC, which `IntrinsicLowering.cpp` lowers to a real
; rail and the round-2 walk's `dyn_cast<BinaryOperator>` dropped).
;
; ⚠ ROUND-3 RULE-13 FINDING (lens R3, F-R3-3, CONFIRMED-MISCOMPILE, 4 plain-C
; programs). Source `$S/review3/R3/p/k01_bitrev.c` (`__builtin_bitreverse32`); `-O1` rewrites the compare to `icmp eq i32 %1, -1610612736`.
;
; The rotated register is a USER of the compare's operand — the exact direction
; round 2 fixed — but it is a `CallInst`, so the `BinaryOperator`-only SET never
; saw it. `intrinsicStem` (`IntrinsicLowering.cpp:33-58`) curates SIXTEEN
; integer intrinsics and the walk asked about none of them; the four INVERTIBLE
; members are the ones InstCombine relocates the compare across, which is why
; only they were reachable — an accident of InstCombine, not a fence.
;
; THE FENCE NEEDS NO OPCODE TABLE. Once every operand is pinned, F2 asks LLVM's
; own `ConstantFoldCall` — so every intrinsic `canConstantFoldCallTo` accepts is
; evaluated EXACTLY, and one it cannot fold is not a candidate at all (`clang`'s
; lattice is overdefined there too, so no fold could have produced the seed).
; Control, byte-identical on BOTH binaries (`p/u04_uncond_bswap.c` for the
; `bswap` member): the guard removed rotates the intrinsic's own rail in place.
;
;
; ---- STILL A DECLINE AFTER THE 2026-09-11 NARROWING (bd `drbq.14`) ----
;
; F2 was narrowed on 2026-09-11 (owner ruling): a pinned value that lies on the
; CONDITION'S OWN BACKWARD WIRE — `CondWire` =
; `{Region.Condition} ∪ ⋃ railWireClosure(condProvenance(Region.Condition))` — is
; no longer a collider, and NINETEEN fixtures of this family flipped to ACCEPT
; (they are now `control_inplace_ry_stateprep_*`). **THIS ONE DID NOT, and the
; reason is not an accident:**
;
; the pinned value is the result of a CURATED `llvm.*` intrinsic that CQ
; LOWERS TO A RAIL — a forward user on a fresh wire, out of `CondWire` for
; the same reason the `range_forward_*` family is. F-R3-1 found four of
; these as plain-C accepts when F2's closure enumerated `BinaryOperator`
; users only.
;
; So the narrowing is the WIRE and nothing wider, and this file is one of the 21
; that prove it. Measured 2026-09-11 on the narrowed binary: rc=1, same string,
; same anchor.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)
declare i32 @llvm.bitreverse.i32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp eq i32 %q, -1610612735
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_ui32(i32 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 5, %entry ]
  %t = call i32 @llvm.bitreverse.i32(i32 %q)
  %mr = call i32 @cq_measure_ui32(i32 %rm)
  %mt = call i32 @cq_measure_ui32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}
