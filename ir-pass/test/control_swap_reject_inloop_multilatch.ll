; control_swap_reject_inloop_multilatch.ll — DECLINE (bd test_C_libtooling-8h7d.5,
; gate (C) of `ControlDetect::flatRegionRollableInLoop`). A flat tainted-condition
; phase diamond inside a MULTI-LATCH natural loop (two back edges into `%head`).
;
; `L->getLoopLatch()` returns null for such a loop, and every downstream reader
; this increment relies on assumes ONE — `collapseFlattenedLoopRails` identifies
; the persistent rail by "the header phi's incoming from THE latch peels back to
; the phi", which has no meaning with two. `tryCaseA` (round 1) already refuses a
; multi-latch loop for the same reason ("an unproven shape; leave it"); gate (C)
; is that refusal moved to DETECTION, before the flatten mutates anything
; (Rule 9), so the region is never emitted into a shape round 2 cannot finish.
;
; Note what is NOT wrong with this program: the loop bound is classical, the arm
; is a clean phase arm, nothing is irreducible. It declines because the shape is
; UNPROVEN, which is the Prime Directive's direction. A multi-latch widening is
; the 7.x-widenings tracker's (bd test_C_libtooling-8h7d).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: Broken module
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %x0, double %b, i32 %n) {
entry:
  br label %head
head:                                    ; preds = %entry, %la, %lb  (TWO latches)
  %i = phi i32 [ 0, %entry ], [ %n1, %la ], [ %n2, %lb ]
  %q = call i32 @cq_theta_si32(i32 %x0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5                ; TAINTED (quantum) condition
  br i1 %c, label %arm, label %merge
arm:
  %g = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge
merge:                                   ; preds = %arm, %head
  %qm = phi i32 [ %g, %arm ], [ %q, %head ]
  %m = call i32 @cq_measure_si32(i32 %qm)   ; the measure result is CLASSICAL
  %sw = icmp slt i32 %m, 3
  br i1 %sw, label %la, label %lb
la:
  %n1 = add i32 %i, 1
  %d1 = icmp slt i32 %n1, %n
  br i1 %d1, label %head, label %exit
lb:
  %n2 = add i32 %i, 2
  %d2 = icmp slt i32 %n2, %n
  br i1 %d2, label %head, label %exit
exit:                                    ; preds = %la, %lb
  ret i32 %i
}
