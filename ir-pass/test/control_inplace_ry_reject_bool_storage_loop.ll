; control_inplace_ry_reject_bool_storage_loop.ll — DECLINE: the _Bool storage web in a loop (W4).
;
; bd test_C_libtooling-dm7f.53 — a BOUNDARY of `narrowBoolStoragePhis`
; (BoolStorageNarrow.h). The narrowing is accept-only: a web that fails a
; condition is left BYTE-UNTOUCHED, so the region reaches its pre-dm7f.53 loud
; owner with the pre-dm7f.53 string (the retired-route message, bd OQ-13).
;
; (W4): `for (k<3) if (a) cq_theta(&t,.3);` keeps t in a loop-header i8 web.
; The narrowing does not enter a cycle (the loop-carried handle machinery owns
; loop phis), so the region keeps the retired-route string. The int twin
; declines `control flow inside a loop body` (loop scope, bd 8h7d), so this is
; a loop gap, not a storage-width one. RETIREMENT TRIGGER: the day the int twin
; accepts, drop W4 for that shape and flip this file.
;
; FOLLOW-UP: bd test_C_libtooling-dm7f.61 (the `_Bool` phi web in a loop / 8h7d).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  br label %9

2:
  %3 = call i1 @cq_measure_i1(i1 %1)
  %4 = zext i1 %3 to i32
  %5 = trunc nuw i8 %17 to i1
  %6 = call i1 @cq_measure_i1(i1 %5)
  %7 = zext i1 %6 to i32
  %8 = add nuw nsw i32 %7, %4
  ret i32 %8

9:
  %10 = phi i32 [ 0, %0 ], [ %18, %16 ]
  %11 = phi i8 [ 0, %0 ], [ %17, %16 ]
  br i1 %1, label %12, label %16

12:
  %13 = trunc nuw i8 %11 to i1
  %14 = call i1 @cq_theta_i1(i1 %13, double 3.000000e-01)
  %15 = zext i1 %14 to i8
  br label %16

16:
  %17 = phi i8 [ %15, %12 ], [ %11, %9 ]
  %18 = add nuw nsw i32 %10, 1
  %19 = icmp eq i32 %18, 3
  br i1 %19, label %2, label %9
}

; CHECK: cq controlled lowering: value-arm swap-route under quantum control
