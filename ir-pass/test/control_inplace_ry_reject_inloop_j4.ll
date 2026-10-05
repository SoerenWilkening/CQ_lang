; control_inplace_ry_reject_inloop_j4.ll — DECLINE (PRD §13.2 row R6-2), the
; **j4** shape: an in-place gate written on the PRE-region name of the rotated
; register, after the region, inside the body. `clang -O1` output (attribute
; groups and metadata trimmed) for
;
;     int example(int u0, int u1) {
;       int q = u0; cq_theta(&q, 0.5);
;       int r = u1; cq_theta(&r, 0.25);
;       int d = 0;
;       for (int i = 0; i < 4; i++) {
;         int r_pre = r;
;         if (q > 5) cq_theta(&r, 0.9);
;         d = r_pre; cq_theta(&d, 0.2);   /* the hop, off the PRE-region name */
;       }
;       return cq_measure(r) + cq_measure(d);
;     }
;
; `%17 = cq_theta(%12, .2)` is an ALIAS HOP off the member `%12` (the header phi,
; the pre-region name), and R6's per-activation certificate asks the same
; question of a hop as of a read: every `BI -> %17` path must re-execute `%12`
; first. It does not — `BI -> merge -> %17` stays inside one activation — so the
; record is stale where it is used.
;
; AND THE PHYSICS AGREES, which is why this is a decline and not a bookkeeping
; artefact: an `Ry` applied AFTER the controlled `Ry` is a different unitary from
; one applied before it. Writing the hop on `r_pre` means the SOURCE'S `r` before
; the arm fired; the emitted gate would land on the relabelled register (the
; wrong-VALUE class of bd 0njv).
;
; History: pre-3qlq the hop was the register form `d = cq_phi(r_pre, .2)` (an
; in-place Rz). The 3qlq migration deleted it as an uncontrolled phase, so the
; exit read the pre-region name directly; bd jttf (2026-10-05) re-spelled the hop
; as the in-place Ry above, which restores the hop this row is about.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define i32 @example(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01) #2
  %5 = icmp sgt i32 %3, 5
  br label %10

6:                                                ; preds = %15
  %7 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  %8 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  %9 = add nsw i32 %8, %7
  ret i32 %9

10:                                               ; preds = %2, %15
  %11 = phi i32 [ 0, %2 ], [ %18, %15 ]
  %12 = phi i32 [ %4, %2 ], [ %16, %15 ]
  br i1 %5, label %13, label %15

13:                                               ; preds = %10
  %14 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 9.000000e-01) #2
  br label %15

15:                                               ; preds = %13, %10
  %16 = phi i32 [ %14, %13 ], [ %12, %10 ]
  %17 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 2.000000e-01) #2
  %18 = add nuw nsw i32 %11, 1
  %19 = icmp eq i32 %18, 4
  br i1 %19, label %6, label %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
