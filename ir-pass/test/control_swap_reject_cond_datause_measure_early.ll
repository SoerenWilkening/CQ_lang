; control_swap_reject_cond_datause_measure_early.ll — DECLINE probe (ziov WI-1,
; Rule-13 adversarial finding atk9): the condition compare is reused as data AND
; that data is MEASURED in the route block, BEFORE the route controls on the flag.
;
; `bool f = cq_measure(q>5); if (q>5) { ... }` — clang -O1 CSEs to ONE `icmp`, and
; the `cq_measure` of the flag-derived value lands in the PRED (route) block,
; ahead of the conditional `br`. Sharing the flag and skipping its strip+free
; would emit `cqrt_measure` on the flag BEFORE the `cqrt_cswap` route — the cswap
; would then be controlled by an ALREADY-COLLAPSED flag, silently destroying the
; coherent `if(q>5)` control (a verify-clean wrong unitary). A measure of the
; flag's lineage in the route block is NOT a safe owner; decline LOUDLY. (A
; measure DOWNSTREAM of the route — the merge block — is fine and ACCEPTS; see
; control_swap_cond_datause_measured.ll.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition measured before the control route under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %z = zext i1 %c to i32
  %mz = call i32 @cq_measure_si32(i32 %z)   ; MEASURE the flag-derived value in PRED
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  %r  = add i32 %m, %mz
  ret i32 %r
}
