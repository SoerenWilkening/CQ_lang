; lowering_reject_loop_rail_record_zero_trip_merge.ll — DECLINE (bd g35c, P1
; silent miscompile on main). `clang -O1` output of (attributes and metadata
; dropped):
;
;     volatile int cq_n = 0;
;     int slice(void) {
;       int q = 3, r = 7, n = cq_n;
;       cq_theta(&q, .5); cq_theta(&r, .25);
;       int z = r;                                   // PRE-gate name of r
;       cq_theta(&r, .3);                            // the gate
;       for (int i = 0; i < n; i++) { cq_theta(&r, .1); z = r; }
;       z ^= 1;
;       return cq_measure(q) + cq_measure(z);        // n == 0: the PRE-gate record
;     }
;
; THE HOLE. The loop's exit φ `%7 = phi [%3, %0], [%15, %12]` reads the
; PRE-gate name `%3` on the zero-trip edge, after the gate `%4`. Case-A
; (`tryCaseA`) claims the rail: both incomings peel to the mint `%3`, so the φ
; joins `railRoot` and is collapsed onto `%3`, and the `xor` and the measure then
; read the post-gate rail. `staleReadOfValue` skipped every MEMBER user before
; its φ incoming-edge test, so a member φ's edges were never asked. Emitted on
; main: `ry(h1,.25); ry(h1,.3); xorc(h1,1); measure(h1)` — the zero-trip run
; measures `(post-gate r) ^ 1` where the source measures `(pre-gate r) ^ 1`.
; The straight-line spelling (no loop) declines `rotation/measure operand
; predates a non-diagonal gate`.
;
; THE FIX (bd g35c): a member φ's incoming edges get the same record-liveness
; test as a non-member φ's — the read position is the incoming block's
; terminator, and a rail gate between the incoming's definition and that edge
; is a stale record. The non-φ member skip (a chain gate is the rail moving,
; not a read) is unchanged. Accept twin, where `z` starts from the POST-gate
; name: `control_angle_select_forward_rail_cycle_zero_trip_post_gate.ll`
; (`@slice_plain`).
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
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01)
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %12, label %6

6:
  %7 = phi i32 [ %3, %0 ], [ %15, %12 ]
  %8 = xor i32 %7, 1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %2)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %11 = add nsw i32 %10, %9
  ret i32 %11

12:
  %13 = phi i32 [ %16, %12 ], [ 0, %0 ]
  %14 = phi i32 [ %15, %12 ], [ %4, %0 ]
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 1.000000e-01)
  %16 = add nuw nsw i32 %13, 1
  %17 = icmp eq i32 %16, %1
  br i1 %17, label %6, label %12
}
