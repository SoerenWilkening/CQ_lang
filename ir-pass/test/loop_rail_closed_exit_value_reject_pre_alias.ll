; loop_rail_closed_exit_value_reject_pre_alias.ll — DECLINE (bd
; test_C_libtooling-8h7d.14's unsafe neighbour). `clang -O1` output
; (attributes and metadata dropped) of
;
;     int a7(int u, int n) {
;       int q = u; cq_theta(&q, .5);
;       int z = q;                                   // PRE-loop record of q
;       for (int i = 0; i < n; i++) { int d = q * q; if (d > 5) cq_phi(.25); q += 1; }
;       return cq_measure(z + 7) + cq_measure(q);
;     }
;
; WHAT IT PINS. The exit block holds TWO reads of the root record `%3`: the
; closed exit value `%6 = add %3, %1` (q0 + n, the loop's own exit value) and
; `%9 = add %3, 7` (z + 7, a computation on the PRE-loop record). bd 8h7d.14
; re-opens `%6` into the LCSSA φ because SCEV(`%6`) == SCEV-at-exit of the latch
; value. `%9` is NOT that value (`(7 + %3)` against `(%1 + %3)`), so it stays a
; read of `%3` past the body's in-place `addc`s and the record-liveness fence
; declines it: after the collapse it would compute `(q0 + n) + 7` where the
; source says `q0 + 7`. On main the module declined `loop-carried rail has
; multiple in-place consumers` (the two adds on `%3` counted as two in-place
; mutators); the re-open removes `%6`, and the stale read is what remains.
; Accept twin: `loop_rail_closed_exit_value.ll` `@plus_one` (`q + 1` after the
; loop, on the exit value).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @a7(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %13, label %7

5:
  %6 = add i32 %3, %1
  br label %7

7:
  %8 = phi i32 [ %3, %2 ], [ %6, %5 ]
  %9 = add nsw i32 %3, 7
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %12 = add nsw i32 %11, %10
  ret i32 %12

13:
  %14 = phi i32 [ %20, %19 ], [ %3, %2 ]
  %15 = phi i32 [ %21, %19 ], [ 0, %2 ]
  %16 = mul nsw i32 %14, %14
  %17 = icmp ugt i32 %16, 5
  br i1 %17, label %18, label %19

18:
  tail call void @cq_phi(double noundef 2.500000e-01)
  br label %19

19:
  %20 = add nsw i32 %14, 1
  %21 = add nuw nsw i32 %15, 1
  %22 = icmp eq i32 %21, %1
  br i1 %22, label %5, label %13
}
