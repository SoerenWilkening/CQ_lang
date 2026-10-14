; control_inplace_ry_reject_seq_counter_stateprep_f2.ll — DECLINE: the counter spelling with an UNPREPPED target (F2).
;
; bd test_C_libtooling-dm7f.53. `int x (rotated); bool t = 0; if (x == 0)
; cq_theta(&t,.3); if (x == 1) cq_theta(&t,.7);` — region 1 is a state prep
; whose seed `false` equals, on the x==0 edge, the live tainted compare
; `x == 1` (region 2's condition). F2 declines, and the decline is NOT an
; artefact: MEASURED, the rival program `if (x == 0) { t = (x == 1);
; cq_theta(&t,.3); }` (t ALIASES the flag register under CQ's value model)
; produces BYTE-IDENTICAL -O1 IR, and its unitary differs (it rotates the
; flag region 2 then reads). The IR cannot tell the two apart. The prepped
; spelling accepts (control_inplace_ry_seq_counter_prepped.ll). Owner
; question filed with dm7f.53's report; flip only on that ruling.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %2 = icmp eq i32 %1, 0
  br i1 %2, label %3, label %6

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %5 = zext i1 %4 to i8
  br label %6

6:
  %7 = phi i8 [ %5, %3 ], [ 0, %0 ]
  %8 = icmp eq i32 %1, 1
  br i1 %8, label %9, label %13

9:
  %10 = trunc nuw i8 %7 to i1
  %11 = call i1 @cq_theta_i1(i1 %10, double 0x3FE6666666666666)
  %12 = zext i1 %11 to i8
  br label %13

13:
  %14 = phi i8 [ %12, %9 ], [ %7, %6 ]
  %15 = call i32 @cq_measure_si32(i32 %1)
  %16 = trunc nuw i8 %14 to i1
  %17 = call i1 @cq_measure_i1(i1 %16)
  %18 = zext i1 %17 to i32
  %19 = add nsw i32 %15, %18
  ret i32 %19
}

; CHECK: cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
