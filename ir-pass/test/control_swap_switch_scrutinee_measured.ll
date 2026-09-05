; control_swap_switch_scrutinee_measured.ll — ACCEPT probe (test_C_libtooling-2aqe):
; the tainted SCRUTINEE has an OWNED data use beyond the switch/merge — it is itself
; measured directly (`%md = cq_measure(%q)`, the ATK12 measured-before-the-switch
; shape). G10's owned-use allowlist (SwitchClassify.cpp) must ALLOW this: a recognized
; `@cq_measure_<sfx>` sink owns the handle.
;
; This pins the G10 measure-allowance ACCEPT under the EXACT-MEMBERSHIP check
; (`taint.MeasureCalls`, hardened from a `starts_with("cq_measure_")` prefix match —
; the prefix-on-accept was spoofable in principle, masked here only because the
; scrutinee is always tainted so `declineTaintEscapes` pre-filters unknown callees).
; A regression that mis-wires the membership set would mistakenly DECLINE this
; legitimate measured scrutinee — caught here. The decline twin is
; control_swap_reject_switch_datause.ll (an UNOWNED `add` use → loud decline).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
merge:
  %md = call i32 @cq_measure_si32(i32 %q)   ; OWNED: the scrutinee is measured directly
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; theta -> alloc+ry handle (RAUW q -> handle); the route emits per case.
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 0)
; CHECK:     call void @cqrt_cswap(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[Q]], i32 %{{[a-zA-Z0-9_.]+}})
; both the DIRECT scrutinee measure and the merge measure resolve to the same handle:
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])

; exactly 4 cswaps (2 per case) then exactly TWO measurements of the scrutinee
; handle (CNT directives scan in program order — route first, measures last):
; CNT-COUNT-4: call void @cqrt_cswap(
; CNT-NOT:     call void @cqrt_cswap(
; CNT-COUNT-2: call i32 @cqrt_measure_i32(
; CNT-NOT:     call i32 @cqrt_measure_i32(

; ACCEPTS (no decline); §5 re-anchor held (no surviving folded cq_phi / data-mux phi):
; ACC-NOT: under quantum control
; ACC-NOT: cq_phi
; ACC-NOT: phi i32
