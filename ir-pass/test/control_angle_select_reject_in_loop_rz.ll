; control_angle_select_reject_in_loop_rz.ll — DECLINE (S7), the `cq_phi` stem
; (bd drbq Inc 2b).
;
; The Rz stem is EXEMPT from S8 and S9 (a diagonal gate moves no basis label), so
; it is worth pinning that it is NOT exempt from S7: the loop clause is asked
; before the stem split and refuses both stems with the same string. Rolling this
; is Increment 3's job for BOTH stems — the 8h7d.5 machinery
; (`collapseFlattenedLoopRails`, `markIfRailLocal`, `staleRailRecordRead`) has to
; be re-asked with an angle-select gate in the body, and nothing has done that.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: control flow inside a loop body under quantum control
; NEW: cq controlled lowering: control flow inside a loop body under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow inside a loop body under quantum control
; 3qlq: migrated from register cq_phi (angle select -> void call on the select (PRD P2))

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  br label %body
body:
  %i = phi i32 [ 0, %entry ], [ %inext, %body ]
  %rp = phi i32 [ %r, %entry ], [ %rp, %body ]
  call void @cq_phi(double %ang)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %body
exit:
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rp)
  %s = add i32 %mq, %mr
  ret i32 %s
}
