; control_classical_call_arm_accept_onward_phase.ll — ACCEPT (dugh, Phase 4×6): a
; 6.5 classical-call arm whose UNTAINTED merge (`int y = 5; if (q>3) y = f(a)`) feeds
; an ONWARD-QUANTUM PHASE (`cq_phi(y, 0.25)` = Rz) that terminates at a measurement.
;
; PRE-dugh this DECLINED at the classifier's merge-out gate (the merge is
; data-untainted, so `cq_phi(y, …)` read the i32 %out handle as a classical value).
; dugh RE-SEEDS a second propagation from the emitted `%out`
; (`repropagateControlMerges`): the onward `cq_phi` is re-tainted and lowers IN PLACE
; to `cqrt_rz_i32(%out, 0.25)` (a phase arm — the answer stays on %out, zero
; controlled gates); `%m` measures %out. The onward phase is the (A2) subset the bead
; accepts. NOTE the phase applies to %out in place (Rule 7 — never method-B on a
; phase), and %out (a ControlOwnedRail) is left allocated.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0
define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %p = call i32 @cq_phi_si32(i32 %y, double 0.25)   ; ONWARD QUANTUM PHASE on %out
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; the controlled-XOR copy merge builds %out, then the ONWARD phase lowers IN PLACE to
; an Rz on %out, then the measure reads %out:
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_rz_i32(i32 %[[OUT]], double 2.500000e-01)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; the onward phase is NOT a controlled Rz (a phase arm keeps the answer on %out —
; zero controlled gates), the surviving @cq_phi is gone, and the region ACCEPTS:
; CHECK-NOT: cqrt_rz{{.*}}_controlled
; CHECK-NOT: @cq_phi
; ACC-NOT: under quantum control
