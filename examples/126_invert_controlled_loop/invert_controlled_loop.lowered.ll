; HAND-WRITTEN. Rules: 17, 14, 10, 8, 12, 5, 2, §1.3.
; Checked: r + x (measured).
; Clean: the hoisted chain d = sext(x) - k and every trip flag f_i = (i < d), each uncomputed and freed inside the region.
; Kept: the user register x; r (rotated in place under control, frozen, measured).
; Rotations: Ry(tx) on x; then, as the backend emits the region: for i = n-1 down to 0 (classical n > 0): P(-ph) on the
; flag (i < x - k), Ry(-th[i]) on r under (i < x - k).
; A CLASSICAL LOOP WHOSE BODY IS A QUANTUM ARM, INSIDE cq_invert (rule 17). The region is lowered as it would be anywhere
; else (rule 14, classical bound: the loop stays a classical loop; each trip computes its flag, rotates r in place under
; it, kicks the phase back on it and uncomputes it; the LICM-hoisted chain d = sext(x) - k is computed once before the
; loop and uncomputed once after it) and sits between cqrt_invert_begin() and cqrt_invert_end() (§1.3). The backend,
; which builds the circuit as this program runs (§0), emits the gates recorded between the two calls reversed with each
; gate inverted; so the trips come out in reverse order (the adjoint of U_{n-1}...U_0 is U_0^dag...U_{n-1}^dag, and the
; trips do not commute: each rotates r by a different angle under a different flag), every angle is negated, the controls
; stay, and inside a trip the Ry and the kickback swap places. Each compute/uncompute pair (the hoisted chain, each f_i)
; reverses into itself, so the backend recomputes and uncomputes it inside the adjoint; the frees it recorded are
; performed after the reversed list. The compiler reverses no loop and negates no angle. -O1 spelled `x > k + i` as
; `i < x - k` with `sext x` and `x - k` hoisted; the compare is `i < d` with the classical i first, and a compare never
; takes _lh (§1.2), so it is spelled by flipping the predicate: `d > i` (icmp_sgt_i64_hl). r is a loop-carried phi
; (%22/%29 in the -O1 IR) whose arm rotates in place, so its handle never changes and both phis are that handle. The two
; empty asm memory fences that CQ.h's markers carry are compiler fences with no gate and are dropped with the markers.
; Regenerated 2026-11-02 (the first version constructed the reversed loop at compile time).
source_filename = "invert_controlled_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @invert_controlled_loop(i32 noundef %0, double noundef %1, i32 noundef %2, ptr nocapture noundef readonly %3, i32 noundef %4, i32 noundef %5, double noundef %6) {
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %8 = cq_theta_si32(%0, %1)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: incoming %2 of phis %16 / %22  [register r, classical start]
  call void @cqrt_invert_begin()    ; IR: call @__cq_invert_begin(); its asm fence is consumed (rule 17)
  %10 = icmp sgt i32 %4, 0    ; IR: %9 = icmp sgt i32 %4, 0  (classical)
  br i1 %10, label %11, label %24    ; IR: br i1 %9

11:; preds = %7
  %12 = sext i32 %5 to i64    ; IR: %11 = sext i32 %5 to i64  (classical)
  %13 = call i32 @cq_template_sext_i32_to_i64(i32 %8)    ; IR: %12 = sext i32 %8 to i64
  %14 = zext nneg i32 %4 to i64    ; IR: %13 = zext nneg i32 %4 to i64  (classical)
  %15 = call i32 @cq_template_sub_i64_hl(i32 %13, i64 %12)    ; IR: %14 = sub nsw i64 %12, %11  (LICM-hoisted: d = x - k)
  br label %16    ; IR: br label %20

16:; preds = %11, %16
  %17 = phi i64 [ 0, %11 ], [ %21, %16 ]    ; IR: %21 = phi i64 [ 0, %10 ], [ %30, %28 ]  (classical trip index i)
  %18 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %15, i64 %17)    ; IR: %23 = icmp slt i64 %21, %14  (d > i: a compare never takes _lh, §1.2)  [path predicate of block %24]
  %19 = getelementptr inbounds double, ptr %3, i64 %17    ; IR: %25  (classical)
  %20 = load double, ptr %19, align 8    ; IR: %26 = load double  (classical angle th[i])
  call void @cqrt_ry_i32_controlled(i32 %18, i32 %9, double %20)    ; IR: block %24: %27 = cq_theta_si32(%22, %26)  [controlled Ry in place on r; phi %29 is the same handle]
  call void @cqrt_rz_i1(i32 %18, double %6)    ; IR: block %24: cq_phi(%6)  (kickback on the flag)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %18, i32 %15, i64 %17)    ; IR: uncompute %23
  call void @cqrt_free(i32 %18)    ; IR: release the %23 rail (|0>)
  %21 = add nuw nsw i64 %17, 1    ; IR: %30 = add nuw nsw i64 %21, 1  (classical)
  %22 = icmp eq i64 %21, %14    ; IR: %31 = icmp eq i64 %30, %13  (classical)
  br i1 %22, label %23, label %16    ; IR: br i1 %31

23:; preds = %16
  call void @cq_template_sub_i64_hl_unc(i32 %15, i32 %13, i64 %12)    ; IR: uncompute %14
  call void @cqrt_free(i32 %15)    ; IR: release the %14 rail (|0>)
  call void @cq_template_sext_i32_to_i64_unc(i32 %13, i32 %8)    ; IR: uncompute %12
  call void @cqrt_free(i32 %13)    ; IR: release the %12 rail (|0>)
  br label %24    ; IR: br label %15

24:; preds = %23, %7
  call void @cqrt_invert_end()    ; IR: %16 = phi [ %2, %7 ], [ %29, %28 ] is the handle of r (unchanged); call @__cq_invert_end(); fence consumed: the backend emits the recorded gates reversed and inverted
  %25 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %17 = cq_measure_si32(%16)
  %26 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %18 = cq_measure_si32(%8)
  %27 = add nsw i32 %26, %25    ; IR: %19  (classical)
  ret i32 %27    ; IR: ret i32 %19
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_invert_begin()
declare void @cqrt_invert_end()
declare i32 @cq_template_sext_i32_to_i64(i32)
declare void @cq_template_sext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_sub_i64_hl(i32, i64)
declare void @cq_template_sub_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_sgt_i64_hl(i32, i64)
declare void @cq_template_icmp_sgt_i64_hl_unc(i32, i32, i64)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
