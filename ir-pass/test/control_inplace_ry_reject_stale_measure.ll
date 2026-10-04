; control_inplace_ry_reject_stale_measure.ll — DECLINE: a PRE-REGION SSA record of
; the rotated register is MEASURED after the region (control-in-place-PRD §4 R6;
; bd test_C_libtooling-drbq).
;
;     int r = 0; cq_theta(&r,.3); int mark = r;
;     if (q > 5) cq_theta(&r, .9);
;     use(cq_measure(mark));
;
; `mark` and `r` are ONE SSA value and ONE physical rail. After the region that
; rail carries `Ry(θ)` on the flag=1 branch, so `cq_measure(mark)` lowers to a
; measurement of the POST-Ry register while the source means the value before it:
; a verify-clean WRONG VALUE, the class of bd `0njv` (open, owner ruling pending).
;
; R6 is deliberately STRICTER than the pass-wide `declineStaleRecordOps` — that
; guard covers PURE producers only, and a measure is not one — so the `0njv` hole
; is not reachable through this accept. Every user of the base that is not this
; gate, its sibling arm's gate, or the merge φ must be provably BEFORE the region.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm   = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %mark = call i32 @cq_measure_si32(i32 %r)
  %mr   = call i32 @cq_measure_si32(i32 %rm)
  %s    = add i32 %mark, %mr
  ret i32 %s
}
