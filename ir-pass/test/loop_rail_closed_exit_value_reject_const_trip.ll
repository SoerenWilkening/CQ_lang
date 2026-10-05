; loop_rail_closed_exit_value_reject_const_trip.ll — DECLINE (bd
; test_C_libtooling-8h7d.14's unsafe neighbour, the SCEV-equality conjunct).
; `clang -O1` output (attributes and metadata dropped) of
;
;     int a8(int u) {
;       int q = u; cq_theta(&q, .5);
;       int z = q;                                   // PRE-loop record of q
;       for (int i = 0; i < 3; i++) { int d = q * q; if (d > 5) cq_phi(.25); q += 1; }
;       return cq_measure(z + 7) + cq_measure(q);
;     }
;
; WHAT IT PINS. A constant trip count leaves no zero-trip guard, so the exit
; block `%3` (only predecessor: the latch) holds BOTH reads of the root record
; `%2`: the closed exit value `%4 = add %2, 3` and the pre-loop alias read
; `%5 = add %2, 7`. Both pass every POSITIONAL conjunct of
; `reopenClosedRailExits` (dominated by the exit block, same loop depth, direct
; users of the root, same type); only ScalarEvolution separates them:
; SCEV(`%4`) = `(3 + %2)` is the latch value's exit SCEV, SCEV(`%5`) =
; `(7 + %2)` is not. `%4` is re-opened into the LCSSA φ; `%5` stays a read of
; `%2` past the body's in-place `addc`s and the record-liveness fence declines
; it — after the collapse it would compute `(q0 + 3) + 7` where the source says
; `q0 + 7`. Re-opening `%5` too (the SCEV test dropped) would alias `z + 7` to the
; register: a silent wrong value. On main the module declined `loop-carried rail
; has multiple in-place consumers` (the two adds on `%2`). Its zero-trip-guarded
; sibling, where the alias read sits outside the exit block:
; `loop_rail_closed_exit_value_reject_pre_alias.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @a8(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  br label %9

3:
  %4 = add i32 %2, 3
  %5 = add nsw i32 %2, 7
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %8 = add nsw i32 %7, %6
  ret i32 %8

9:
  %10 = phi i32 [ %2, %1 ], [ %16, %15 ]
  %11 = phi i32 [ 0, %1 ], [ %17, %15 ]
  %12 = mul nsw i32 %10, %10
  %13 = icmp ugt i32 %12, 5
  br i1 %13, label %14, label %15

14:
  tail call void @cq_phi(double noundef 2.500000e-01)
  br label %15

15:
  %16 = add nsw i32 %10, 1
  %17 = add nuw nsw i32 %11, 1
  %18 = icmp eq i32 %17, 3
  br i1 %18, label %3, label %9
}
