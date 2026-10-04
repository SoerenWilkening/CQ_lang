; control_inplace_ry_reject_share_cond_flag.ll — DECLINE: the condition is also
; read as DATA, so the region would take the ziov SHARED-FLAG path
; (control-in-place-PRD §4 R7; bd test_C_libtooling-drbq).
;
;     int q = 0; cq_theta(&q,.5); int f = (q > 5);
;     if (q > 5) cq_theta(&r, .9);
;     use(f);
;
; `clang -O1` CSEs the two `q > 5` into one `icmp` with a branch use and a data
; use. On the ziov path `emitRegion` mints ONE flag at the compare, feeds it to the
; data lineage, and SKIPS the eager strip+free — the data lineage owns the handle.
; That leaves the flag a LIVE record of the PRE-Ry condition past the region while
; this class relabels a register in place. Nothing proves the two compose, and Inc
; 1 was not cleared for it; the PRD defers it to Inc 2, where the Rz path already
; handles sharing. Over-declining is always safe.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation arm shares the condition flag under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  %f = zext i1 %c to i32
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  %mf = call i32 @cq_measure_si32(i32 %f)
  %s  = add i32 %m, %mf
  ret i32 %s
}
