; control_inplace_ry_reject_stateprep_cast_zext_live.ll — DECLINE. The `zext`
; sibling of `..._cast_sext_live.ll` (round-3 lens R3, F-R3-2; source
; `$S/review3/R3/p/g04_ull_eq5.c`, `unsigned long long t = (unsigned)q;`).
;
; Both spellings are in the family because `ConstantRange::castOp` reads them
; differently and only one of them is numerically the identity — the fence must
; not accidentally rest on `sext` being value-preserving.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_theta_ull(i64, double)
declare i64 @cq_measure_ull(i64)

define i64 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i64 @cq_theta_ull(i64 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i64 [ %rt, %arm ], [ 5, %entry ]
  %t  = zext i32 %q to i64
  %mr = call i64 @cq_measure_ull(i64 %rm)
  %mt = call i64 @cq_measure_ull(i64 %t)
  %s  = add i64 %mr, %mt
  ret i64 %s
}
