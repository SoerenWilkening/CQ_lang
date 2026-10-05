; control_angle_select_reject_forward_rail_cycle_zero_trip_stale.ll — DECLINE
; (bd g35c; the angle-select population bd 3paw added to it). `clang -O1`
; output of (attributes and metadata dropped):
;
;     volatile int cq_n = 0;
;     int slice(void) {
;       int q = 3, r = 7, n = cq_n;
;       cq_theta(&q, .5); cq_theta(&r, .25);
;       int z = r;                                   // PRE-gate name of r
;       cq_theta(&r, (q == 5) ? .9 : .3);            // T: the angle select
;       for (int i = 0; i < n; i++) { cq_theta(&r, .1); z = r; }
;       z ^= 1;
;       return cq_measure(q) + cq_measure(z);        // n == 0: the PRE-gate record
;     }
;
; The uncontrolled hole `lowering_reject_loop_rail_record_zero_trip_merge.ll`
; with the gate replaced by an angle select. Case-A collapsed the exit φ
; `%9 = phi [%3, %0], [%17, %14]`, whose zero-trip incoming is the PRE-gate `%3`,
; onto the root `%3` = the select's base, so the `xor` and the measure read the
; base under `T`'s dominance and bd 3paw's skip let them through: the module
; lowered BYTE-IDENTICAL to its post-gate twin
; `control_angle_select_forward_rail_cycle_zero_trip_post_gate.ll` (`@slice`),
; a different program (measured on bd 3paw's commit 7e784d6c). Since bd g35c
; `tryCaseA`'s record-liveness fence asks a member φ's incoming edges, so the
; shape declines in `lowerLoops`, before detection, with the stale-record
; dialect.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

@cq_n = global i32 0, align 4

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
  %1 = load volatile i32, ptr @cq_n, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01)
  %4 = icmp eq i32 %2, 5
  %5 = select i1 %4, double 9.000000e-01, double 3.000000e-01
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %5)
  %7 = icmp sgt i32 %1, 0
  br i1 %7, label %14, label %8

8:
  %9 = phi i32 [ %3, %0 ], [ %17, %14 ]
  %10 = xor i32 %9, 1
  %11 = tail call i32 @cq_measure_si32(i32 noundef %2)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %13 = add nsw i32 %12, %11
  ret i32 %13

14:
  %15 = phi i32 [ %18, %14 ], [ 0, %0 ]
  %16 = phi i32 [ %17, %14 ], [ %6, %0 ]
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 1.000000e-01)
  %18 = add nuw nsw i32 %15, 1
  %19 = icmp eq i32 %18, %1
  br i1 %19, label %8, label %14
}
