; control_inplace_ry_reject_stateprep_intrinsic_bswap — DECLINE (F2-semantic: the pinned register is produced by a CURATED
; `llvm.*` INTEGER INTRINSIC, which `IntrinsicLowering.cpp` lowers to a real
; rail and the round-2 walk's `dyn_cast<BinaryOperator>` dropped).
;
; ⚠ ROUND-3 RULE-13 FINDING (lens R3, F-R3-3, CONFIRMED-MISCOMPILE, 4 plain-C
; programs). Source `$S/review3/R3/p/h04_bswap_eq5.c`: `unsigned t = __builtin_bswap32((unsigned)q); if (t == 5u) r = cq_theta(t, 0.9);` — `-O1` rewrites `icmp eq (bswap %1), 5` into `icmp eq i32 %1, 83886080` because `bswap` is invertible, leaving `%7 = call i32 @llvm.bswap.i32(i32 %1)` alive and measured.
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)
declare i32 @llvm.bswap.i32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp eq i32 %q, 83886081
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_ui32(i32 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 5, %entry ]
  %t = call i32 @llvm.bswap.i32(i32 %q)
  %mr = call i32 @cq_measure_ui32(i32 %rm)
  %mt = call i32 @cq_measure_ui32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}
