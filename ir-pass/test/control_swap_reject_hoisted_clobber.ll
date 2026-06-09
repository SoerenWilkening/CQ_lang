; control_swap_reject_hoisted_clobber.ll — §3c reject when clang -O1 HOISTS the
; clobbering value op out of the arm (regression for the WI-1 adversarial finding).
;
; The value op `%v = add %q, 7` is branch-invariant, so clang -O1 (LICM/sinking/
; GVN) routinely hoists it OUT of the arm into a dominating block, leaving an
; (almost) empty arm whose merge contribution is the hoisted %v. The arm result
; is q+7 != q — a genuine integer DATA MUX and a §3c clobber (the condition reads
; q). A detector that classified phase-vs-value by the op's DEFINING BLOCK would
; treat %v as a tainted phase LEAF and silently mis-accept this as a phase region
; (a verify-clean silent miscompile: WI-2 would CSWAP q into a rail and never
; produce q+7). Classification MUST be by opcode + base-identity (the arm spine
; must bottom at the routed straight-through handle %q), never by getParent().
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = add i32 %q, 7         ; clobbering value op HOISTED out of the arm
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  br label %merge            ; arm body is empty; its merge contribution is %v
merge:
  %qm = phi i32 [ %v, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
