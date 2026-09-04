; control_inplace_ry_reject_inloop_premark.ll — DECLINE (PRD §13.2 row R6-1): a
; PRE-Ry record of the rotated register, minted before the loop and read AFTER it.
;
;     int mark = r; for (...) { if (q > 5) r = cq_theta(r, .9); } measure(mark);
;
; R6 PER ACTIVATION REFUSES IT, and the reason is the certificate's own shape: the
; record's definition `D` is the mint, which sits in the entry block and is NEVER
; re-executed, so the path `BI -> merge -> exit -> measure` carries no barrier and
; the read is a genuine stale record. `mark` names the register BEFORE K controlled
; rotations and is measured after all of them.
;
; THIS IS THE ROW THAT PROVES THE PER-ACTIVATION CLAUSE IS NOT A BLANKET ACCEPT.
; Its FLAT twin declines for the same reason on `provablyBefore`; the two spellings
; agree here and disagree only where the back edge is the whole difference (the
; header phi and the merge phi of the ACCEPT shapes). 8 cells of
; `tools/loop_twin_matrix.py` are this family, and Increment 3 deliberately moves
; them from `DECLINE-BOTH-DIFFERENT` to `DECLINE-BOTH` with the identical string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %mk = call i32 @cq_measure_si32(i32 %r0)
  %m  = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mk, %m
  ret i32 %s
}
