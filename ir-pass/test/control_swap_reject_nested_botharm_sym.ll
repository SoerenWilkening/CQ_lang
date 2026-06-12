; control_swap_reject_nested_botharm_sym.ll — DECLINE: SYMMETRIC both-arm nest.
;
; `if (q>5) { if (q<20) rz(q,a); } else { if (q>2) rz(q,a); }` — clang -O1 hoists
; the identical shared gate into a 2-pred block, giving a 3-incoming i32 merge
; (NOT 4-incoming; identical-angle arms are the simplest valid fixture and add
; NO FP angle phi — FA1 measured). The OUTER branch has tainted inner gates on
; BOTH successors → it is NOT a one-content-arm diamond → criterion 1 declines
; `nested control flow` (§12.4 invariant-(i)). The §4 routing is framed for
; nesting in ONE arm; both-arm waits on two sibling subtrees.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %then, label %else
then:
  %ct = icmp slt i32 %q, 20
  br i1 %ct, label %gate, label %merge
else:
  %ce = icmp sgt i32 %q, 2
  br i1 %ce, label %gate, label %merge
gate:
  %g  = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q, %then ], [ %q, %else ], [ %g, %gate ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}nested control flow under quantum control
