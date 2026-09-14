; P-C — the SHIPPED P3b negative shape (control_peel_reject_undef_incoming.ll)
; with ONE change: the undef-carrying merge phi also CARRIES THE THETA'S RESULT,
; and the theta's seed is undef.  bd z9t1's phi clause then rewrites that
; incoming, so MergePhiPeel's P3b (a deliberate decline-KEEPING gate) no longer
; refuses it.  Note `%6` is a DIFFERENT C object from the seed object and is
; undefined on ONE edge only.
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
define i32 @example()  {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %5, label %3
3:
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %5
5:
  %6 = phi i32 [ %1, %3 ], [ 0, %0 ]
  %7 = phi i32 [ %4, %3 ], [ 0, %0 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %12 = add i32 %8, %9
  %13 = add i32 %12, %11
  ret i32 %13
}
