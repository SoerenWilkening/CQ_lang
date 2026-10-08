; lowering_stale_speccall_lifted_phi_accept.ll — ACCEPT, the accept twin of
; lowering_stale_speccall_reject_lifted_phi.ll (bd test_C_libtooling-r2j3.6).
;
;   __attribute__((noinline)) int g(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 7; cq_theta(&q, .5);
;     if (argc > 1) cq_theta(&q, .125);
;     int t = g(q);                    // reads the merged record of q
;     return (int)cq_measure(t) + (int)cq_measure(q);
;   }
;
; `%8 = phi [%6, %5], [%3, %2]` is a one-register merge phi; the lift RAUWs it onto the
; base `%3`, and the lifted call then reads the base after the arm's `.125` gate. That
; gate IS on the record the call read (the phi's own incoming), so the post-lift
; re-sweep's per-use exemption (`LiftCoverage`, bd r2j3.11 / dm7f.1) keeps the call:
; the dm7f.1 boundary, for the lifted-call reader. Asking the lifted call without the
; exemption would decline this well-formed program.
;
; The warning pin: the re-sweep also records the call as a COVERED reader of the lift
; (`LiftedMergePhi::Readers`), so the late live-record pass knows the clone's out
; rail is minted after the arm's `.125` gate. Before r2j3.6 this module printed one
; false `non-diagonal gate over a live derived record` warning for that gate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=WARN --allow-empty %s < %t.err
; WARN-NOT: warning:
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK:      %[[T:.*]] = tail call i32 @__cq_q_g_1(i32 noundef %[[H]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[T]])

define i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01) #2
  %4 = icmp sgt i32 %0, 1
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.250000e-01) #2
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = tail call i32 @g(i32 noundef %8)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
