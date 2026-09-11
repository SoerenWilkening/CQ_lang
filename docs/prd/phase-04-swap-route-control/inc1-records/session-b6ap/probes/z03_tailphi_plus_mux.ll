; control_phase_kickback_negated_tail_phi.ll + a SECOND phi (an int data mux).
; ORACLE: 2 phis => phaseAngleTail false => classifyPhaseKickback NotApplicable
; => recoverRegion OffPattern => decline `control flow`.
@off = internal global i32 0
define i32 @slice() local_unnamed_addr {
entry:
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %o = load volatile i32, ptr @off, align 4
  %q = add nsw i32 %o, %t
  %c = icmp eq i32 %q, 5
  br i1 %c, label %mrg, label %arm
arm:
  tail call void @cq_phi(double noundef 9.000000e-01)
  br label %mrg
mrg:
  %a = phi double [ 1.100000e-01, %entry ], [ 3.000000e-01, %arm ]
  %d = phi i32 [ 2, %entry ], [ 5, %arm ]
  tail call void @cq_phi(double noundef %a)
  %m = tail call i32 @cq_measure_si32(i32 noundef %q)
  %md = tail call i32 @cq_measure_si32(i32 noundef %d)
  %s = add nsw i32 %m, %md
  ret i32 %s
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)
