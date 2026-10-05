; control_angle_select_reject_forward_rail_cycle_frozen_carry_xor.ll — DECLINE
; (bd hk9y; HAND IR, the Rule-11 round-2 reviewer's `p5.ll`). The 3paw accept
; `control_angle_select_forward_rail_cycle_frozen.ll` plus, in the loop body
; before r's gate, a zero-hop identity carry `%rec` of the select's result read
; by an in-place `xor` and measured:
;
;     %rec = phi i32 [ %rec, %15 ], [ %8, %0 ]   ; frozen post-T record
;     %z   = xor i32 %rec, 5                     ; dtzb, absorbed as a rail op
;     %mz  = cq_measure(%z)
;
; On bd g35c's commit c2a6cfeb it lowered (exit 0, stage 2b clean) with, per
; trip, `xorc(h_r, 5); measure(h_r); ry(h_r, .1)` after the controlled Ry. The
; source measures `record ^ 5` each trip with r untouched by the xor, and from
; trip 2 the record is stale (the loop's `cq_theta` moved the rail). The uncontrolled twin
; `lowering_reject_loop_rail_frozen_carry_member_xor.ll` has the argument and the
; fix (`staleReadOfValue`: a member gate on a record that does not refresh is a
; read). Declines in `lowerLoops`, before the angle select is classified.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01)
  %6 = icmp eq i32 %4, 5
  %7 = select i1 %6, double 9.000000e-01, double 3.000000e-01
  %8 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %7)
  br label %15

10:
  %11 = phi i32 [ %18, %15 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %14 = add nsw i32 %13, %12
  %s = add nsw i32 %14, %acc
  ret i32 %s

15:
  %16 = phi i32 [ %19, %15 ], [ 0, %0 ]
  %acc0 = phi i32 [ %acc, %15 ], [ 0, %0 ]
  %17 = phi i32 [ %18, %15 ], [ %8, %0 ]
  %rec = phi i32 [ %rec, %15 ], [ %8, %0 ]
  %z = xor i32 %rec, 5
  %mz = tail call i32 @cq_measure_si32(i32 noundef %z)
  %acc = add nsw i32 %acc0, %mz
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 1.000000e-01)
  %19 = add nuw i32 %16, 1
  %20 = icmp eq i32 %19, 3
  br i1 %20, label %10, label %15
}
