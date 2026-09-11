; control_phase_kickback_cmp_inplace_xor_other_register.ll — ACCEPT, the
; DISCRIMINATING control for
; `control_phase_kickback_reject_cmp_inplace_xor_measured_parent.ll` (Track A.1,
; Rule-13 ROUND-2 finding F-A1R2-2; probe `review_a1_r2_probes/f4h.c`, plain
; `clang -O1` C).
;
;     int slice(int u) {
;       int q = cq_theta(u, 0.5);
;       int r = cq_theta(u + 1, 0.25);
;       int acc = 0;
;       for (int i = 0; i < 3; ++i) {
;         acc += cq_measure(r);          /* a DIFFERENT register collapses */
;         q = q ^ 9;                     /* the same in-place relabelling */
;         if (q > 5) cq_phi(0.3);
;       }
;       return acc + cq_measure(q);
;     }
;
; The `taint.InPlaceRailOps` crossing in `railWireNamesBackward` must reach the
; condition register's OTHER SSA names and must NOT turn into "some register in
; this loop was measured". `%h` (`q`) carries the `cqrt_xorc` and is never
; measured inside the body; `%h1` (`r`) is measured every trip and is not the
; condition's wire. If this file goes red, the crossing has stopped being a wire
; question. GREEN on the ORACLE (`main` 0c7380c), on b439944 and here — MEASURED
; on all three.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @slice(i32 %u) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %u1 = add nsw i32 %u, 1
  %r  = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %body

exit:                                             ; preds = %latch
  %mq = call i32 @cq_measure_si32(i32 %post)
  %s  = add nsw i32 %mq, %acc.next
  ret i32 %s

body:                                             ; preds = %entry, %latch
  %i    = phi i32 [ 0, %entry ], [ %i.next, %latch ]
  %acc  = phi i32 [ 0, %entry ], [ %acc.next, %latch ]
  %cur  = phi i32 [ %q, %entry ], [ %post, %latch ]
  %m    = call i32 @cq_measure_si32(i32 %r)
  %acc.next = add nsw i32 %m, %acc
  %post = xor i32 %cur, 9
  %c    = icmp sgt i32 %post, 5
  br i1 %c, label %arm, label %latch

arm:                                              ; preds = %body
  call void @cq_phi(double 3.000000e-01)
  br label %latch

latch:                                            ; preds = %body, %arm
  %i.next = add nuw nsw i32 %i, 1
  %done   = icmp eq i32 %i.next, 3
  br i1 %done, label %exit, label %body, !llvm.loop !0
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.mustprogress"}

; The loop stays ROLLED, the xor is in place on the condition rail, the flag is
; minted from that rail, kicked back, stripped and freed INSIDE the body, and the
; other register's measurement is untouched:
; CHECK:      %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cqrt_ry_i32(i32 %[[HQ]], double 5.000000e-01)
; CHECK:      %[[HR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cqrt_ry_i32(i32 %[[HR]], double 2.500000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[HR]])
; CHECK-NEXT: %{{.*}} = add nsw i32
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[HQ]], i32 9)
; CHECK:      %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[HQ]], i32 5)
; CHECK:      call void @cqrt_rz_i1(i32 %[[FLAG]], double 3.000000e-01)
; CHECK:      call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[FLAG]], i32 %[[HQ]], i32 5)
; CHECK:      call void @cqrt_free(i32 %[[FLAG]])

; Whole-file exact counts and whole-file negatives (a trailing CHECK-NOT after
; the positives is windowed and asserts nothing):
; RYCNT-COUNT-2: call void @cqrt_ry_i32(
; RYCNT-NOT:     call void @cqrt_ry
; MCNT-COUNT-2:  = call i32 @cqrt_measure_i32(
; MCNT-NOT:      call i32 @cqrt_measure
; FCNT-COUNT-1:  call void @cqrt_free
; FCNT-NOT:      call void @cqrt_free
; NOROUTE-NOT:   cqrt_cswap
; NOROUTE-NOT:   call void @cqrt_x(
; NOROUTE-NOT:   _controlled
; NOROUTE-NOT:   call i32 @cq_theta
; NOROUTE-NOT:   call void @cq_phi

; SILENT-NOT: cq controlled lowering
; SILENT-NOT: cq loop lowering
