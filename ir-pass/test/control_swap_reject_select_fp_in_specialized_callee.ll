; control_swap_reject_select_fp_in_specialized_callee.ll — DECLINE (kjd1
; Rule-13 implementation clearance, scope-lens pin §5.9d): an fp select INSIDE
; a callee body lifted by Phase-6 clone-on-taint. The fp-DATA un-staging is
; select-in-the-caller-NARROW: in-body control declines at specialization
; (`SpecializeReject::InBodyControl`) BEFORE any select classification runs on
; the clone, and this fence is type-agnostic — the fixture is the fp tripwire
; the suite lacked (the fence was previously confirmed only by ad-hoc probes).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %c) {
entry:
  %t  = icmp sgt i32 %c, 5
  %s  = select i1 %t, double 3.000000e+00, double 1.000000e+00  ; fp select in-body
  %si = fptoui double %s to i32
  ret i32 %si
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)                    ; quantum lift of helper
  %z = call i32 @cq_measure_si32(i32 %r)
  ret i32 %z
}
