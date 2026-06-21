; control_swap_reject_value_i128_merge.ll — an i128 integer value-merge phi is
; not routable data (4.2 WI-3 hardening, §8 review 2026-06-10; the "supported"
; half of §0 criterion 2: stem AND a COPYABLE width, like ArithLowering).
;
; i128 IS isIntegerTy and `add` IS a supported stem, and (since the n0ui Tier-1
; follow-up) cq_template_*_i128 producers EXIST — but there is NO cqrt_copy_i128
; (i128 is an INTERMEDIATE-only width; source/sink stay i64), so a routed value
; merge has no reversible copy. The decline now rides
; `widthHasReversibleCopy(abiWidthFromType(T))` == false (NOT the legacy `.empty()`
; arm — abiWidthFromType(i128) is now NON-empty). NECESSARY-not-sufficient and
; consulted only AFTER the FP fence (never key the DECISION on width alone — f64
; has a valid width yet is an angle, the f64 trap). Fixture pair partner:
; control_swap_reject_value_vector_merge.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: value-arm swap-route
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_theta_sll(i64, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i64 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w = call i64 @cq_theta_sll(i64 %v0, double 2.500000e-01)
  %v = zext i64 %w to i128                  ; tainted NON-ABI-width register
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %a = add i128 %v, 3                       ; supported stem, unsupported width
  br label %merge
merge:
  %vm = phi i128 [ %a, %arm ], [ %v, %entry ]
  %s  = trunc i128 %vm to i32
  %m  = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
