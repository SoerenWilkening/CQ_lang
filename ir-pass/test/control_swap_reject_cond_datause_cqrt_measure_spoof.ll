; control_swap_reject_cond_datause_cqrt_measure_spoof.ll — DECLINE
; (test_C_libtooling-2aqe): the ONE observable behavioral delta of the prefix ->
; exact-membership hardening of the owned-use measurement allowlists.
;
; A hand-authored `@cqrt_measure_<W>` (a RUNTIME-ABI symbol name, compiler-emitted
; only — the frontend/CQ.h NEVER emit it pre-detection) consumes the tainted
; condition's data lineage (`%c -> %d = zext -> cqrt_measure_i32(%d)`, downstream of
; the route). The OLD allowlist (`condDataUseDisposition`, ArmClassify.cpp) matched the
; `cqrt_measure_` prefix and treated this as an owning sink -> ShareOk -> verify-clean
; shared-flag ACCEPT. EXACT-MEMBERSHIP against `taint.MeasureCalls` (the recognized
; front-end `@cq_measure_<sfx>` sites only) finds it ABSENT -> Unowned -> loud DECLINE.
;
; This is the SAFE direction (over-decline; Prime Directive) and exactly the spoof-
; hardening intent — a `cqrt_`-named callee is NOT pre-masked by `declineTaintEscapes`
; (its branch 1b whitelists the `cqrt_` prefix), so unlike the `cq_measure_evil` spoof
; family it genuinely REACHES the allowlist; only the exact-membership check rejects it.
; Regression-locks that a hand-authored runtime-symbol measure cannot confer false
; ownership of a live control-condition lineage.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition data use neither escaped nor measured under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cqrt_measure_i32(i32)
define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %d = zext i1 %c to i32                  ; DATA use of the condition compare
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %md = call i32 @cqrt_measure_i32(i32 %d) ; runtime-ABI measure name (off-pattern)
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
