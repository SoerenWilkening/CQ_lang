; control_inplace_ry_reject_inloop_iterlocal_outside_mint.ll — DECLINE (bd
; `test_C_libtooling-wx8g`, R7-loop CLAUSE (c2)): the rotated register's rail does
; NOT cross the back edge, so clause (b) finds no header phi — but its ROOT MINT
; sits OUTSIDE the loop, so the rail is NOT re-minted per activation either.
;
;     int r0 = cq_theta(u1, .25);              // minted ONCE, before the loop
;     for (...) { int r = r0; if (q == 5) r = cq_theta(r0, .9); m += cq_measure(r); }
;
; This is the shape that shows (c2) is a POSITIVE proof and not the negation of
; (b). Every trip reads the SAME physical rail `r0` as its `f=0` component while
; the `f=1` component rotates it, so `r0` has K in-place mutators reading one
; value — Rule 8 fan-out, the `rz(h,1); rz(h,2) = Rz(3)` hazard, and the rolled
; form would serialise K rotations onto one register while the source means K
; independent conditional rotations of the SAME starting state.
;
; `railChainRootMint` (the shared body `railPhiRootMint` calls) returns the mint
; `%r0` for the base, and `L->contains(%r0->getParent())` is FALSE, so clause (c)
; refuses. Clause (b') is the mirror: it would accept a mint that dominates the
; header — but only for a rail that CROSSES the back edge, which this one does
; not. Neither half claims it, which is the correct answer.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r0, %loop ]
  %mm = call i32 @cq_measure_si32(i32 %rm)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 1
  br i1 %done, label %exit, label %loop
exit:
  ret i32 0
}
