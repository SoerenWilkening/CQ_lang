; control_inplace_ry_reject_inloop_alias.ll — DECLINE (PRD §13.2 row R6-3), the
; ALIAS shape, and the RE-HOMED decline sibling of
; control_inplace_ry_inloop_diamond.ll (which flipped to ACCEPT in Increment 3).
;
; The same CFG as that accept, with ONE edit: the loop's carry is made an IDENTITY
; (`%p = phi [ %r0, entry ], [ %p, merge ]`) while the region's merge `%rm`
; escapes to a `cq_measure` after the loop. `%p` is then TWO copies of one wire —
; an alias, never a copy (Rule 8) — and it is FROZEN: it re-executes every
; iteration and yields the same value while the register moves under it.
;
; TWO INDEPENDENT REASONS REFUSE IT, and having both is the point (bd
; [[identity-carry-phi-does-not-refresh]] is a CONFIRMED silent miscompile that
; reached exactly this shape through a missing cut):
;   * the REFRESH FENCE — `WireWalk::phiTracksWire(%p)` is false, because a
;     `cq_theta` runs between the latch incoming and the edge, so the certificate's
;     premise ("re-executing `D` re-establishes the record") is refused before the
;     barrier walk is even run;
;   * the PHI-EDGE READ POSITION — `%p`'s own read position on the LATCH edge is
;     the latch terminator, and `BI -> arm -> merge -> latch` never re-enters the
;     header, so `D = %p` is not re-executed on that path.
;
; hand IR: `clang -O1` folds a zero-hop identity carry away, so this shape is not
; reachable from C — which is why the fixture is written directly.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %p = phi i32 [ %r0, %entry ], [ %p, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %p, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %p, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
