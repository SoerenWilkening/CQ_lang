; control_angle_select_reject_overflow_difference.ll — DECLINE (S1, the ARM-VALUE
; fence): BOTH arms are FINITE `ConstantFP`s, and their DIFFERENCE overflows.
;
; ROUND-1 RULE-13 REVIEW FINDING (bd drbq Inc 2b, lens L7-F2) — the cell that
; shows an arm-by-arm finiteness check is NOT enough. `A = DBL_MAX`,
; `B = -DBL_MAX`: each arm is a perfectly ordinary finite double, and the source
; names no infinity anywhere. The emitted difference is
; `fl(DBL_MAX − (−DBL_MAX)) = +inf`, so the stream is
;
;     ry(h, −DBL_MAX) ; ry_controlled(f, h, +inf)
;
; On the TRUE edge the composed angle is `−DBL_MAX + inf = +inf`, not `DBL_MAX`.
; The unitary is wrong AND a non-finite value has been manufactured out of two
; finite ones, which is precisely the structural class the Prime Directive says to
; refuse: a value the source never named appears in an emitted gate slot.
;
; THE CLAUSE: when BOTH arms are `ConstantFP`, S1 computes `A − B` with APFloat at
; `rmNearestTiesToEven` (bit-for-bit what `IRBuilder`'s folder will do in the
; emitter) and returns `NotApplicable` unless the result is FINITE. It runs
; BEFORE the rounding fence, which needs a finite difference to be an error-free
; transformation at all.
;
; NOTE that `1e300 / −1e300` — one binade down — does NOT overflow and stays an
; ACCEPT with an EXACT difference (δ = 0, measured). The fence is on the computed
; difference, not on magnitude; see
; `control_angle_select_accept_exact_difference_large.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 0x7FEFFFFFFFFFFFFF, double 0xFFEFFFFFFFFFFFFF
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}
