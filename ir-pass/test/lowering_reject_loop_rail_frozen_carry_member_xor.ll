; lowering_reject_loop_rail_frozen_carry_member_xor.ll — DECLINE (bd hk9y,
; silent on main; HAND IR). Round 1's twin of
; `lowering_reject_inloop_rail_frozen_gate_first.ll`: a zero-hop identity carry
; `%rec` of r's post-gate record, read every trip by an in-place dtzb `xor`
; while the loop's own `cq_theta` moves the same rail.
;
; Source meaning: each trip measures `rec ^ 5` where `rec` is the record from
; BEFORE the loop and r itself is only rotated. One rail cannot hold both the
; frozen record and the rotating register (no-cloning), so this must decline.
; On main `cq-opt` exits 0 and emits, per trip, `xorc(h_r, 5); measure(h_r);
; ry(h_r, .1)`: the xor lands on r's rail for good and, from trip 2 on, reads
; the rotated register through iteration 0's name. Stage 2b is clean.
;
; WHY NOTHING ASKED IT. `tryCaseA` claims the rail (both header φs peel to the
; mint `%5`; `%rec`'s latch incoming is itself), its (a) fixpoint absorbs `%z`
; as an in-place rail op, and `staleRailRecordRead` received the whole
; `railRoot` as its skip set: `%z` was skipped as "the rail moving", and g35c's
; self-edge exception skipped `%rec`'s own edge. A `cq_theta` reader of `%rec`
; is held by `recordStaleQuantumReaders`; a dtzb `xor` reader is not.
;
; THE FIX (bd hk9y, `staleReadOfValue`): a member gate is skipped only when its
; record refreshes. `%rec` does not (`recordRefreshedByDef`: a gate-free self
; carry), so `%z`'s read gets the positional test and the loop's `cq_theta`
; between `%rec` and the next trip's `%z` declines it. The angle-select spelling
; is `control_angle_select_reject_forward_rail_cycle_frozen_carry_xor.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01)
  br label %10

4:
  %5 = phi i32 [ %13, %10 ]
  %6 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %8 = add nsw i32 %7, %6
  %9 = add nsw i32 %8, %acc
  ret i32 %9

10:
  %11 = phi i32 [ %14, %10 ], [ 0, %0 ]
  %acc0 = phi i32 [ %acc, %10 ], [ 0, %0 ]
  %12 = phi i32 [ %13, %10 ], [ %3, %0 ]
  %rec = phi i32 [ %rec, %10 ], [ %3, %0 ]
  %z = xor i32 %rec, 5
  %mz = tail call i32 @cq_measure_si32(i32 noundef %z)
  %acc = add nsw i32 %acc0, %mz
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 1.000000e-01)
  %14 = add nuw i32 %11, 1
  %15 = icmp eq i32 %14, 3
  br i1 %15, label %4, label %10
}
