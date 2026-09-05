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
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: nested control flow under quantum control
; NEW: cq controlled lowering: nested control flow under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
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
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
