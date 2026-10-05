; control_angle_select_reject_forward_rail_cycle_stale_alias.ll — DECLINE
; (`tryCaseA`'s record-liveness fence; bd 3paw's adversarial twin, moved by bd
; g35c). `clang -O1` output of (attributes and `!llvm.loop` dropped):
;
;     int slice(int u0, int u1, int n) {
;       int q = u0; cq_theta(&q, .5);  int r = u1; cq_theta(&r, .25);
;       int z = r;                                     // the PRE-gate record
;       cq_theta(&r, q == 5 ? .9 : .3);
;       for (int i = 0; i <= n; i++) cq_theta(&z, .1); // rotates the STALE name
;       return cq_measure(q);
;     }
;
; WHY THIS IS THE ATTACK ON bd 3paw. It passes every Case-A claim clause except
; the record-liveness fence: the header φ `%14 = phi [%15, loop], [%5, entry]`
; reads the pre-gate name `%5`, its latch peels back to itself, and its
; external incoming peels to the clean mint `%5`.
; Had the collapse gone ahead it would have RAUW'd `%14` to `%5`, and at
; detection the function would be IR-IDENTICAL to `@slice_dead` in
; `control_angle_select_forward_rail_cycle_frozen.ll` (a legal program), which
; bd 3paw's skip admits. So the decline has to come from a fence that asks the
; question on the PRE-collapse IR.
;
; WHICH FENCE, AND WHY IT MOVED. On bd 3paw's commit 7e784d6c `tryCaseA` did NOT
; refuse it: `staleReadOfValue` skipped every MEMBER user, and the header φ is
; one. The collapse ran, the angle select lowered, and the late
; `recordStaleQuantumReaders` slot declined it (`rotation/measure operand
; predates a non-diagonal gate`) because its reader is a `cq_theta`. With a `ret`
; or a dtzb `xor` + measure in that reader's place the same member-φ read was
; never asked at all (bd g35c:
; `control_angle_select_reject_forward_rail_cycle_zero_trip_{stale,ret}.ll`).
; Since bd g35c a member φ's incoming edges get the record-liveness test, so the
; entry edge of `%14`, which carries `%5` past the gate `%8`, declines in
; `lowerLoops` with the stale-record dialect, before detection.
; If it ever ACCEPTS, the fence bd 3paw's skip rests on is gone.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01)
  %6 = icmp eq i32 %4, 5
  %7 = select i1 %6, double 9.000000e-01, double 3.000000e-01
  %8 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %7)
  %9 = icmp slt i32 %2, 0
  br i1 %9, label %10, label %12

10:
  %11 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %11

12:
  %13 = phi i32 [ %16, %12 ], [ 0, %3 ]
  %14 = phi i32 [ %15, %12 ], [ %5, %3 ]
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 1.000000e-01)
  %16 = add nuw i32 %13, 1
  %17 = icmp eq i32 %13, %2
  br i1 %17, label %10, label %12
}
