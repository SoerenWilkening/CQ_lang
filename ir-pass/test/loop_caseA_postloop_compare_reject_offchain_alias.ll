; loop_caseA_postloop_compare_reject_offchain_alias.ll — DECLINE (bd
; test_C_libtooling-r2j3.13 reached through bd 8h7d.16; review round 1 probe p4).
; `clang -O1` output (attributes and metadata dropped) of
;
;     int p4(int u, int n) {
;       int q = u; cq_theta(&q, .5);
;       int z = q;                                   // PRE-loop alias of q
;       for (int i = 0; i < n; i++) q ^= 3;
;       int c = (q == 7);                            // post-loop compare
;       z += 5;
;       return cq_measure(z) + cq_measure(c);
;     }
;
; WHAT IT PINS (L9). Main declines this (`tainted value muxed by a
; classical-condition phi`): CLOSURE refused the post-loop compare `%7`. bd
; 8h7d.16 admits that compare, so the loop is claimed, and the fixpoint absorbs
; `%9 = add %3, 5` (an alias read of the ROOT placed after the loop) as an
; in-place member. Before r2j3.13 the record fence skipped it and the branch
; emitted `xorc(h,3) x n; …; addc(h,5); measure(h)`: z measured as
; (q0 ^ 3) + 5 for odd n where the source says q0 + 5. With round 1's skip set
; narrowed to the peeled chains, `%9` is asked as a read of `%3` past the
; body's `xorc` and the loop declines. Main-only twin (no compare):
; `lowering_reject_loop_rail_offchain_alias_add.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @p4(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %13, label %5

5:
  %6 = phi i32 [ %3, %2 ], [ %16, %13 ]
  %7 = icmp eq i32 %6, 7
  %8 = zext i1 %7 to i32
  %9 = add nsw i32 %3, 5
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %12 = add nsw i32 %11, %10
  ret i32 %12

13:
  %14 = phi i32 [ %16, %13 ], [ %3, %2 ]
  %15 = phi i32 [ %17, %13 ], [ 0, %2 ]
  %16 = xor i32 %14, 3
  %17 = add nuw nsw i32 %15, 1
  %18 = icmp eq i32 %17, %1
  br i1 %18, label %5, label %13
}
