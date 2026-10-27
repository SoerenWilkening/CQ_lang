; HAND-WRITTEN. Rules: 17, 10, 8, 12, 5, 2.
; Checked: r + x (measured).
; Clean: the hoisted chain d = sext(x) - k and every trip flag f_i = (i < d) (each recomputed and uncomputed inside the
; adjoint, freed |0>).
; Kept: the user register x; r (rotated in place under control, frozen, measured).
; Rotations: Ry(tx) on x; then, for i = n-1 down to 0 (classical n > 0): P(-ph) on the flag (i < x - k), Ry(-th[i]) on r
; under (i < x - k).
; THE ADJOINT OF A CLASSICAL LOOP WHOSE BODY IS A QUANTUM ARM (rule 17). The bracketed region, as -O1 shapes it:
; `x > k + i` became `i < x - k`, with `sext x` and `x - k` LICM-hoisted out of the loop and computed once before it. So
; the region's forward gate list is
;   [d = sext x; d -= k;  for i = 0..n-1: { f_i = (i < d); cRy(f_i, r, th[i]); Rz(f_i, ph) kickback; unc f_i; free f_i };
;    unc d; unc sext]
; and r is a loop-carried phi (%22/%29) whose arm rotates in place, so its handle never changes and the phi is that
; handle. The adjoint is that list REVERSED, with every gate inverted (44, 61):
;   [sext x; d -= k;  for i = n-1..0: { f_i = (i < d); Rz(f_i, -ph); cRy(f_i, r, -th[i]); unc f_i; free f_i };
;    unc d; unc sext]
; Three things change: (a) the TRIP ORDER runs backwards. The adjoint of U_{n-1}...U_0 is U_0^dag...U_{n-1}^dag, and
; the trips do not commute because each one rotates r by a different angle th[i] under a different flag. The bound is
; classical, so the reverse loop just counts down. (b) Every angle is negated; the controls stay as they are. (c) Inside
; a trip, the Ry and the kickback swap places (they commute, since the kickback is diagonal on the control, but the
; adjoint is spelled literally). Each compute/uncompute pair (the hoisted d chain, each f_i) reverses into itself, so it
; is recomputed and uncomputed inside the adjoint and freed |0>. The two empty asm memory fences that CQ.h's markers
; carry are compiler fences with no gate; they are dropped with the markers.
; The compare is `i < d`, with the classical i first; a compare never takes _lh (§1.2), so it is spelled by flipping the
; predicate: `d > i` (icmp_sgt_i64_hl).
source_filename = "invert_controlled_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @invert_controlled_loop(i32 noundef %0, double noundef %1, i32 noundef %2, ptr nocapture noundef readonly %3, i32 noundef %4, i32 noundef %5, double noundef %6) {
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %8 = cq_theta_si32(%0, %1)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: incoming %2 of phis %16 / %22  [register r, classical start]
  %10 = icmp sgt i32 %4, 0    ; IR: %9 = icmp sgt i32 %4, 0  (classical; __cq_invert_begin and its asm fence consumed above)
  br i1 %10, label %11, label %27    ; IR: br i1 %9

11:; preds = %7
  %12 = sext i32 %5 to i64    ; IR: %11 = sext i32 %5 to i64  (classical)
  %13 = call i32 @cq_template_sext_i32_to_i64(i32 %8)    ; IR: (adjoint, last step reversed) %12 = sext i32 %8 to i64: inverse of its own uncompute
  %14 = call i32 @cq_template_sub_i64_hl(i32 %13, i64 %12)    ; IR: %14 = sub nsw i64 %12, %11: inverse of its own uncompute
  %15 = add nsw i32 %4, -1    ; IR: the adjoint loop starts at the forward loop's last trip, n - 1  (classical)
  %16 = zext nneg i32 %15 to i64    ; IR: (classical)
  br label %17

17:; preds = %10, %20
  %18 = phi i64 [ %16, %11 ], [ %24, %17 ]    ; IR: %21 = phi i64 [ 0, %10 ], [ %30, %28 ]  REVERSED: counts n-1 down to 0
  %19 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %14, i64 %18)    ; IR: %23 = icmp slt i64 %21, %14  (mirrored: d > i)  [path predicate of block %24; inverse of its own uncompute]
  %20 = fneg double %6    ; IR: adjoint of cq_phi(%6) is cq_phi(-%6)  (classical)
  call void @cqrt_rz_i1(i32 %19, double %20)    ; IR: block %24: cq_phi(%6) inverted (kickback on the flag)
  %21 = getelementptr inbounds double, ptr %3, i64 %18    ; IR: %25  (classical)
  %22 = load double, ptr %21, align 8    ; IR: %26 = load double  (classical angle th[i])
  %23 = fneg double %22    ; IR: adjoint of cq_theta(r, %26) is Ry(-%26)  (classical)
  call void @cqrt_ry_i32_controlled(i32 %19, i32 %9, double %23)    ; IR: block %24: %27 = cq_theta_si32(%22, %26) inverted, under the same predicate; phi %29 = the same handle
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %19, i32 %14, i64 %18)    ; IR: inverse of computing %23
  call void @cqrt_free(i32 %19)    ; IR: release the %23 rail (|0>)
  %24 = add nsw i64 %18, -1    ; IR: %30 = add nuw nsw i64 %21, 1  REVERSED  (classical)
  %25 = icmp slt i64 %24, 0    ; IR: %31 = icmp eq i64 %30, %13  REVERSED: past trip 0  (classical)
  br i1 %25, label %26, label %17    ; IR: br i1 %31

26:; preds = %20
  call void @cq_template_sub_i64_hl_unc(i32 %14, i32 %13, i64 %12)    ; IR: inverse of computing %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  call void @cq_template_sext_i32_to_i64_unc(i32 %13, i32 %8)    ; IR: inverse of computing %12
  call void @cqrt_free(i32 %13)    ; IR: release the %12 rail (|0>)
  br label %27

27:; preds = %done, %7
  %28 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %16 = phi [ %2, %7 ], [ %29, %28 ] is the handle of r; __cq_invert_end and its fence consumed; %17 = cq_measure_si32(%16)
  %29 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %18 = cq_measure_si32(%8)
  %30 = add nsw i32 %29, %28    ; IR: %19  (classical)
  ret i32 %30    ; IR: ret i32 %19
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_rz_i1(i32, double)
declare i32 @cq_template_sext_i32_to_i64(i32)
declare void @cq_template_sext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_sub_i64_hl(i32, i64)
declare void @cq_template_sub_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_sgt_i64_hl(i32, i64)
declare void @cq_template_icmp_sgt_i64_hl_unc(i32, i32, i64)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
