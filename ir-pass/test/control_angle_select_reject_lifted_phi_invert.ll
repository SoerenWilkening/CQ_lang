; control_angle_select_reject_lifted_phi_invert.ll — DECLINE (S9): the stale record is laundered
; through a LIFTABLE ONE-REGISTER CLASSICAL JOIN PHI (bd drbq Inc 2b; the select
; form of Inc-1 finding K, a CONFIRMED silent miscompile).
;
;     int m; if (cc) m = r; else m = r;   // classical cc — a join phi
;     cq_theta(&r, q == 5 ? .9 : .3);             // the 2b gate
;     cq_invert_begin(); cq_theta(&m, .7); cq_invert_end();   // the consumer
;     cq_measure(m);
;
; `%m` is a phi over two SSA names of ONE physical rail. It passes a position
; proof HONESTLY (it dominates the gate), so a fence that stopped AT it would
; never enumerate ITS users — and `liftOneRegisterMergePhi` later RAUWs it to the
; base, handing this consumer the POST-Ry register. Inc 1 shipped exactly that
; gap across five consumer kinds, all six reproducers accepting, `opt` exit 0.
; The fix is that the rail closure crosses phi/select/freeze FORWARD from a
; tainted member, so `%m` is a MEMBER and its own users owe the position proof.
;
; CONSUMER PINNED HERE: an in-place gate on the laundered record INSIDE a
; `cq_invert_begin/_end` bracket (`%mi = cq_theta(%m, .7)`), then a measure of
; its result. The source names the PRE-gate record; the emitted Ry would land on
; the post-gate register. (The bracket itself is not lowered yet, bd 42t: an
; accepted module keeps the two marker calls and does not link. That is why the
; fence has to fire here, before anything is emitted.)
;
; Hand IR: the join phi's two incomings are the same SSA value, which `clang
; -O1` folds away; this is the spelling the whole family uses (see
; control_angle_select_reject_lifted_phi_measure.ll).
;
; History: pre-3qlq the alias arm held `m = cq_phi(r, .1)` and the bracket
; `m = cq_phi(m, .7)` (register form, in-place Rz). The 3qlq migration deleted
; both and left an EMPTY bracket, so the file duplicated the measure sibling;
; bd jttf (2026-10-05) re-spelled the bracketed gate as the in-place Ry above.
; (The alias arm stays empty, as in the measure sibling: an in-place Ry there is
; the chained-theta launder, a different spelling of the launder itself.)
;
; The accept control is `control_angle_select_ry_lifted_phi_base.ll` (the phi as
; the BASE, which must keep lowering). Five consumer kinds, five fixtures — read
; them as one family.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

declare void @__cq_invert_begin()
declare void @__cq_invert_end()

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
  call void @__cq_invert_begin()
  %mi = call i32 @cq_theta_si32(i32 %m, double 7.000000e-01)  ; in-place gate on the laundered record
  call void @__cq_invert_end()
  %a = call i32 @cq_measure_si32(i32 %mi)
  %b = call i32 @cq_measure_si32(i32 %rt)
  %s = add i32 %a, %b
  ret i32 %s
}
