; lowering_reject_loop_rail_offchain_alias_add.ll — DECLINE (bd
; test_C_libtooling-r2j3.13, P1: a silent miscompile on main 7b4e6359).
; `clang -O1` output (attributes and metadata dropped) of
;
;     int p3(int u, int n) {
;       int q = u; cq_theta(&q, .5);
;       int z = q;                                   // PRE-loop alias of q
;       int s = 0;
;       for (int i = 0; i < n; i++) { q += 1; s += cq_measure(q); }
;       z += 5;
;       return s + cq_measure(z);
;     }
;
; THE HOLE. `tryCaseA`'s fixpoint (a) absorbs `%7 = add %3, 5` (the dtzb in-place
; SHAPE on the root `%3`) as a rail MEMBER and the accept MARKS it in place, so
; main emitted `ry(h,.5); {addc(h,1); measure(h)} x n; addc(h,5); measure(h)`,
; exit 0, no warning: the source measures q0 + 5, the stream q0 + n + 5. The
; record fence never asked `%7`: round 1 handed its WHOLE `railRoot` to
; `staleReadOfValue` as the skip set, which skips a member reading a refreshing
; record, and the root mint always refreshes. No other fence saw it: the loop
; carries no Ry, so the stale-record pre-pass found nothing on the wire, and the
; fan-out guard counts per value (the loop's mutator hangs off the header φ).
;
; THE FIX (bd r2j3.13). Round 1's SKIP set is the peeled header chains only
; (root → pre-header chain → header φ → latch chain), as round 2's already is;
; the GATE set is still every rail value. An off-chain absorbed op is then a
; read like any other: `%3` → `addc` in the body → `%7` is a stale path, and
; the module declines.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @p3(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %10, label %5

5:
  %6 = phi i32 [ 0, %2 ], [ %16, %10 ]
  %7 = add nsw i32 %3, 5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %9 = add nsw i32 %8, %6
  ret i32 %9

10:
  %11 = phi i32 [ %17, %10 ], [ 0, %2 ]
  %12 = phi i32 [ %16, %10 ], [ 0, %2 ]
  %13 = phi i32 [ %14, %10 ], [ %3, %2 ]
  %14 = add nsw i32 %13, 1
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14)
  %16 = add nsw i32 %15, %12
  %17 = add nuw nsw i32 %11, 1
  %18 = icmp eq i32 %17, %1
  br i1 %18, label %5, label %10
}
