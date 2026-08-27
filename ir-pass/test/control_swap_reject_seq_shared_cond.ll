; control_swap_reject_seq_shared_cond.ll — DECLINE (bd hcrg decline partition):
; two sequential regions branching on ONE CSE'd condition.
;
; `if(q>5){rz a}; if(q>5){rz b}` after CSE: a single `%c1` in `entry` feeding
; BOTH conditional branches. The second region's condition is therefore defined
; OUTSIDE its own Pred block, and `nonDiagonalGateBeforeBranch` declines any
; condition it cannot bound a positional scan for:
;   `if (Cond->getParent() != R.Pred) return true;  // unbounded gap`
;
; NOTE THE MESSAGE IS IMPRECISE AND THAT IS PRE-EXISTING, not something hcrg
; introduced: there is no non-diagonal gate anywhere in this module. The string
; is the one that branch has always fired, and it is mirrored here
; character-for-character so code and fixture cannot drift. If that branch ever
; gets its own string, this file is where it will surface.
;
; Why it belongs in the hcrg partition: before hcrg this module declined at
; DETECTION (`nested control flow`) and the shared-condition guard was never
; reached. Sequential regions now reach arm classification, so the guard is on
; the live path for the first time — and it must hold, because a flag minted at
; region 2's branch from a compare that dominates region 1 has no proven
; relationship to the wire region 1 left behind.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  %g1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %m1
m1:
  %p1 = phi i32 [ %g1, %arm1 ], [ %q, %entry ]
  br i1 %c1, label %arm2, label %m2    ; the SAME %c1, defined in %entry
arm2:
  %g2 = call i32 @cq_phi_si32(i32 %p1, double %b)
  br label %m2
m2:
  %p2 = phi i32 [ %g2, %arm2 ], [ %p1, %m1 ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
