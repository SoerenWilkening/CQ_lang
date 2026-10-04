; control_angle_select_reject_lifted_phi_clone_arg.ll — DECLINE (S9): the stale record is laundered
; through a LIFTABLE ONE-REGISTER CLASSICAL JOIN PHI (bd drbq Inc 2b; the select
; form of Inc-1 finding K, a CONFIRMED silent miscompile).
;
;     int m; if (cc) m = cq_phi(r,.1); else m = r;   // classical cc — a join phi
;     cq_theta(&r, q == 5 ? .9 : .3);             // the 2b gate
;     sink(m);                  // a Phase-6 clone-on-taint argument
;
; `%m` is a phi over two SSA names of ONE physical rail. It passes a position
; proof HONESTLY (it dominates the gate), so a fence that stopped AT it would
; never enumerate ITS users — and `liftOneRegisterMergePhi` later RAUWs it to the
; base, handing this consumer the POST-Ry register. Inc 1 shipped exactly that
; gap across five consumer kinds, all six reproducers accepting, `opt` exit 0.
; The fix is that the rail closure crosses phi/select/freeze FORWARD from a
; tainted member, so `%m` is a MEMBER and its own users owe the position proof.
;
; The accept control is `control_angle_select_ry_lifted_phi_base.ll` (the phi as
; the BASE, which must keep lowering). Five consumer kinds, five fixtures — read
; them as one family.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal fastcc i32 @sink(i32 %x) noinline {
  %y = add i32 %x, 1
  ret i32 %y
}

define i32 @example(i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.500000e-01)
  %cc = icmp eq i32 %c, 0
  br i1 %cc, label %join, label %alias
alias:
  br label %join
join:
  %m = phi i32 [ %r, %alias ], [ %r, %entry ]
  %t = icmp eq i32 %q, 5
  %ang = select i1 %t, double 9.000000e-01, double 3.000000e-01
  %rt = call i32 @cq_theta_si32(i32 %r, double %ang)
  %k = call fastcc i32 @sink(i32 %m)
  %b = call i32 @cq_measure_si32(i32 %rt)
  %s = add i32 %k, %b
  ret i32 %s
}
