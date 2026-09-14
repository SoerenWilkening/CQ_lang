; control_inplace_ry_reject_inloop_iterlocal_derived_mint.ll — DECLINE (bd
; `test_C_libtooling-wx8g`, R7-loop CLAUSE (c2)): the ITERATION-LOCAL rotated base
; is a DERIVED OUT-OF-PLACE value, not a clean rail mint.
;
;     for (...) { int p = cq_theta(u1, .25); int r = p * 5;
;                 if (q == 5) r = cq_theta(r, .9); m = cq_measure(r); }
;
; `peelInPlaceBase` stops at the `mul` (no in-place ABI — a `mul` MINTS a fresh
; rail through `cq_template_mul_*`), so `railChainRootMint` returns null and (c2)
; refuses. It is the ITERATION-LOCAL twin of PRD §13.2 row DB, which clause (b')
; refuses for the loop-CARRIED spelling
; (`control_inplace_ry_reject_inloop_derived_base.ll`) — one predicate, two
; positions, the same answer for the same reason (Rule 14).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %p = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %d = mul nsw i32 %p, 5
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %d, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %d, %loop ]
  %mm = call i32 @cq_measure_si32(i32 %rm)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 1
  br i1 %done, label %exit, label %loop
exit:
  ret i32 0
}
