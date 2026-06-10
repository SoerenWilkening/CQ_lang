; control_swap_reject_value_vector_merge.ll — an integer-VECTOR merge is not
; routable data (4.2 WI-3 hardening, §8 review 2026-06-10; §0 criterion 3
; "merge type is integer" — the POSITIVE half, beyond the FP fence).
;
; A tainted <2 x i32> register (minted via the escape-whitelisted bitcast of a
; tainted i64) with a structurally perfect add-chain arm. isIntegerTy() is
; FALSE for a vector of integers, and no alloc/copy/template symbol exists for
; it — accepting would hand WI-4 a region whose emission crashes on a null
; FunctionCallee AFTER the route bracket is emitted (a mutate-then-fail on
; valid input, violating detect-before-mutate). Fixture pair partner:
; control_swap_reject_value_i128_merge.ll (the non-ABI-width scalar half).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: value-arm swap-route
declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)
define i64 @example(i32 %u0, i64 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w = call i64 @cq_theta_sll(i64 %v0, double 2.500000e-01)
  %v = bitcast i64 %w to <2 x i32>          ; tainted integer VECTOR register
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %a = add <2 x i32> %v, <i32 3, i32 3>     ; routable-LOOKING vector chain
  br label %merge
merge:
  %vm = phi <2 x i32> [ %a, %arm ], [ %v, %entry ]
  %s  = bitcast <2 x i32> %vm to i64        ; whitelisted cast back (no escape)
  %m  = call i64 @cq_measure_sll(i64 %s)
  ret i64 %m
}
