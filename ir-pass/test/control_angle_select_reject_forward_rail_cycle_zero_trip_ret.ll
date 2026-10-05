; control_angle_select_reject_forward_rail_cycle_zero_trip_ret.ll — DECLINE
; (bd g35c, the `ret` reader). `clang -O1` output of (attributes and metadata
; dropped):
;
;     volatile int cq_n = 0;
;     volatile int cq_o;
;     int slice(void) {
;       int q = 3, r = 7, n = cq_n;
;       cq_theta(&q, .5); cq_theta(&r, .25);
;       int z = r;                                   // PRE-gate name of r
;       cq_theta(&r, (q == 5) ? .9 : .3);            // T: the angle select
;       for (int i = 0; i < n; i++) { cq_theta(&r, .1); z = r; }
;       cq_o = cq_measure(q);
;       return z;                                    // n == 0: the PRE-gate record
;     }
;
; The exit φ `%9 = phi [%3, %0], [%14, %11]` is returned. A `ret` is no
; `cq_theta`/`cq_measure` reader, so `recordStaleQuantumReaders` never asks it;
; on bd 3paw's commit 7e784d6c the module lowered to `ret i32 %h1`, handing the
; caller the POST-gate rail. The straight-line `ret` of a pre-gate record
; declines at S9 (`control_angle_select_reject_stale_ret.ll`). Since bd g35c the
; member φ's zero-trip edge is asked by `tryCaseA`'s record-liveness fence.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

@cq_n = global i32 0, align 4
@cq_o = global i32 0, align 4

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
  br i1 %7, label %11, label %8

8:
  %9 = phi i32 [ %3, %0 ], [ %14, %11 ]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %2)
  store volatile i32 %10, ptr @cq_o, align 4
  ret i32 %9

11:
  %12 = phi i32 [ %15, %11 ], [ 0, %0 ]
  %13 = phi i32 [ %14, %11 ], [ %6, %0 ]
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 1.000000e-01)
  %15 = add nuw nsw i32 %12, 1
  %16 = icmp eq i32 %15, %1
  br i1 %16, label %8, label %11
}
