; lowering_control_escape_break.ll — Phase 4.1 WP17 (PRD §8.6, epic `-aht.2`),
; negative. A `break` out of a quantum-controlled region — `for(){ if(q) break; }`
; — is a NON-reconverging exit: the tainted-condition arm leaves the region
; instead of falling through to a merge. The Quantum Control Machine result
; (arXiv:2304.15000) proves a superposed jump is non-injective and cannot be a
; unitary; the necessary-and-sufficient conditions are injectivity +
; synchronization (all branches reconverge). Rejected by default (PRD §8.6); the
; safety net diagnoses it ("control flow under quantum control") rather than
; branching on the handle id (a silent miscompile) or crashing.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %n) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inc, %body ]
  %q = call i32 @cq_theta_si32(i32 %i, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %exit, label %body   ; if (q > 5) break;
body:
  %inc = add i32 %i, 1
  %lc = icmp slt i32 %inc, %n
  br i1 %lc, label %loop, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
