; control_inplace_ry_reject_inloop_sharecond.ll — DECLINE (PRD §13.2 row R7'): an
; in-loop Ry arm whose condition compare is ALSO read as data (the ziov
; `ShareCondFlag` path).
;
; On that path `emitRegion` SKIPS the flag strip and free, because a downstream
; data lineage owns the flag. The flag is then a LIVE record of the PRE-Ry
; condition past the region, while this class relabels a register in place — and
; inside a loop it would be a live record per activation with nothing proving the
; per-trip composition. Nothing was cleared for it flat, let alone rolled.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation arm shares the condition flag under quantum control
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
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %fz    = zext i1 %c to i32
  %fm    = call i32 @cq_measure_si32(i32 %fz)
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  %s = add i32 %m, %fm
  ret i32 %s
}
