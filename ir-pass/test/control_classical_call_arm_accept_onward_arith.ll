; control_classical_call_arm_accept_onward_arith.ll — ACCEPT (dugh, Phase 4×6): a
; 6.5 classical-call arm whose UNTAINTED merge (`int y = 5; if (q>3) y = f(a)`, a
; classical constant straight-through + a pure classical call) feeds ONWARD-QUANTUM
; stock arithmetic (`z = y + 1`) that terminates at a measurement.
;
; PRE-dugh this DECLINED at the classifier's merge-out gate: the merge phi is
; data-untainted (constant 5 + classical call %r), so the FIRST forward propagation
; classified `%z` classical, and the gate rejected any non-measure/non-i32-ret merge
; user. dugh retires that gate and RE-SEEDS a second propagation from the emitted
; `%out` (`repropagateControlMerges`): `%z` is re-tainted and lowers as the reversible
; quantum producer `cq_template_add_i32_hl(%out, 1)`; `%m` measures it. This is the
; (A2) onward-QUANTUM subset the bead accepts.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
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
  %z = add i32 %y, 1                 ; ONWARD QUANTUM: was a classical-over-quantum leak
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; the controlled-XOR copy merge builds %out, then the ONWARD add re-tainted and
; lowered over %out, then the measure:
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[OUT]], i32 1)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OP]])

; the onward add is NOT left as a stock `add`, and the region ACCEPTS (no decline):
; CHECK-NOT: = add i32
; ACC-NOT: under quantum control
