; spec_accept_gate_sub_round2_switch.ll — ACCEPT (bd test_C_libtooling-p3kd.21, R11 r1
; item 3, L1; reviewer probe revS3/p4_round2_switch.ll). A gate subroutine whose
; argument is quantum only from ROUND 2 on: `%y` is a switch-merge φ of constants
; under the quantum scrutinee `%q`, a data mux the control chain mints a rail for.
; Asked on round-1 taint alone the call was not compiled at its site, and round 2's
; specializer then declined `callee contains a quantum primitive`. The question
; now also asks `LaterTaintOracle` (`makeLaterTaintQuery`, the drain's own
; over-approximation of later growth), so `g` is compiled at its site in round 1;
; `declineMissedGateSubroutines` re-asks it on the round-2 taint, loudly.
; ⚠ DISCLOSED (L9): the -O1 re-run turns the switch into a select chain, and the
; first select's merge rail is left live under the later Ry: the warning below,
; the open silent-miscompile class bd r2j3.32 (a straight-line 4.4 select merge
; `%out` never uncomputed). The hand-inlined twin of the raw IR keeps the switch
; data mux (no intermediate rail) and warns too.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; CHECK-LABEL: define i32 @example(
; CHECK: [[Q:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK: [[OUT:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: [[Y:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_copy_i32_controlled(i32 {{%[0-9a-z_.]+}}, i32 [[OUT]], i32 [[Y]])
; CHECK: call void @cqrt_ry_i32(i32 [[Y]], double 0x3FE6666666666666)
; CHECK-NEXT: [[M:%[0-9a-z.]+]] = call i32 @cqrt_measure_i32(i32 [[Y]])
; CHECK-NEXT: ret i32 [[M]]
; CHECK-NOT: call {{.*}}@g(

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @g(i32 %k) noinline {
  %t = call i32 @cq_theta_si32(i32 %k, double 7.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %c0
                                i32 1, label %c1 ]
c0:
  br label %merge
c1:
  br label %merge
merge:
  %y = phi i32 [ 10, %c0 ], [ 20, %c1 ], [ 5, %entry ]
  %r = call i32 @g(i32 %y)
  ret i32 %r
}
