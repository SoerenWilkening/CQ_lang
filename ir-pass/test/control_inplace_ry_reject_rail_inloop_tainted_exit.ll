; control_inplace_ry_reject_rail_inloop_tainted_exit.ll — DECLINE: the Q1
; QUANTUM-BOUNDED EXIT, with a bare-`_Bool` in-place controlled-Ry arm in the
; body. The loop's exiting condition is a live tainted value, i.e. a run-time
; branch on a qubit.
;
; bd `test_C_libtooling-wx8g` retires an ARM-class carve-out and leaves Q1
; UNCONDITIONAL — the Rule-18 bound derivation (bd `m57l`) is NOT built and no
; quantum-dependent trip count is lowered as a loop today. `lowerLoops` runs
; BEFORE control detection and `LLVMContext::diagnose` EXITS on the first
; `DS_Error`, so this module never reaches `classifyArms` at all and the string
; below is the LOOP layer's, not the control layer's. That ordering is what the
; fixture pins: if a future widening ever let a quantum-bounded loop reach R7,
; this string would move and this file would go red.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}loop under quantum control

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  br i1 %b, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %stop = icmp sgt i32 %rm, 100
  br i1 %stop, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
