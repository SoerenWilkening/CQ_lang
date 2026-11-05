; HAND-WRITTEN. Rules: 17, 14, 10, 8, 12, 5, 2, 3, 11, 15, 20, 21; §1.3 (the bus, __cq_mem).
; Checked: r + x (measured).
; Clean: the hoisted chain d = sext(x) - k, every trip flag f_i = (i < d) and every trip's controlled load copy A_i of
; th[i], each uncomputed (un-copied) and freed inside the region.
; Kept: the user register x; r (rotated in place under control, frozen, measured).
; Rotations: Ry(tx) on x; then, as the backend emits the region: for i = n-1 down to 0 (classical n > 0): P(-ph) on the
; flag (i < x - k), Ry(-val(A_i)) on r under (i < x - k), A_i the f64 rail loaded from th[i] under that flag.
; A CLASSICAL LOOP WHOSE BODY IS A QUANTUM ARM, INSIDE cq_invert (rule 17). The region is lowered as it would be anywhere
; else (rule 14, classical bound: the loop stays a classical loop; each trip computes its flag, loads th[i], rotates r in
; place under the flag, kicks the phase back on it and uncomputes it; the LICM-hoisted chain d = sext(x) - k is computed
; once before the loop and uncomputed once after it) and sits between cqrt_invert_begin() and cqrt_invert_end() (§1.3).
; The backend, which builds the circuit as this program runs (§0), emits the gates recorded between the two calls
; reversed with each gate inverted; so the trips come out in reverse order (the adjoint of U_{n-1}...U_0 is
; U_0^dag...U_{n-1}^dag, and the trips do not commute: each rotates r by a different angle under a different flag), every
; angle is negated, the controls stay, and inside a trip the Ry and the kickback swap places. Each compute/uncompute pair
; (the hoisted chain, each f_i, each A_i: a load un-copied inside the region reverses into itself, rule 17 Memory)
; reverses into itself, so the backend recomputes and uncomputes it inside the adjoint; the frees it recorded are
; performed after the reversed list. The compiler reverses no loop and negates no angle. -O1 spelled `x > k + i` as
; `i < x - k` with `sext x` and `x - k` hoisted; the compare is `i < d` with the classical i first, and a compare never
; takes _lh (§1.2), so it is spelled by flipping the predicate: `d > i` (icmp_sgt_i64_hl). r is a loop-carried phi
; (%22/%29 in the -O1 IR) whose arm rotates in place, so its handle never changes and both phis are that handle. The two
; empty asm memory fences that CQ.h's markers carry are compiler fences with no gate and are dropped with the markers.
; THE ANGLE th[i] (rules 3, 20, 21, 11, 15). th is a pointer argument, program memory like any other: `load double` of
; th[i] is a bus load and its result is an f64 rail (rule 3; over-taint: a basis copy of HOST cells, no qubit). The
; getelementptr has a classical base and the classical index i, so it stays, and the address is its run-time i64
; (ptrtoint, the _hl operand). The load sits in the arm block %24 and a bus access is never hoisted (rule 9): it is
; qram_load_f64_hl_controlled under the trip flag, |0> on the flag-0 branch (rule 5). An angle loaded from the bus is a
; quantum angle (rule 11), so the controlled Ry is rule 15's single primitive ry_i32_qangle_controlled(f, r, A). Its last
; reader is that rotation and no memory version change follows in the trip (no store, swap, allocation or host call), so
; the copy is un-copied right after it under the same flag (rule 5 sentence 1) and freed, before the flag's own _unc.
; m = __cq_mem() is called once, at function entry (§5).
; Regenerated 2026-11-02 (the first version constructed the reversed loop at compile time); regenerated 2026-11-05 for
; the flat memory model (th[i] is a bus load and a quantum angle).
source_filename = "invert_controlled_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @invert_controlled_loop(i32 noundef %0, double noundef %1, i32 noundef %2, ptr nocapture noundef readonly %3, i32 noundef %4, i32 noundef %5, double noundef %6) {
  %8 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %8 = cq_theta_si32(%0, %1)  [Ry]
  %10 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: incoming %2 of phis %16 / %22  [register r, classical start]
  call void @cqrt_invert_begin()    ; IR: call @__cq_invert_begin(); its asm fence is consumed (rule 17)
  %11 = icmp sgt i32 %4, 0    ; IR: %9 = icmp sgt i32 %4, 0  (classical)
  br i1 %11, label %12, label %26    ; IR: br i1 %9

12:; preds = %7
  %13 = sext i32 %5 to i64    ; IR: %11 = sext i32 %5 to i64  (classical)
  %14 = call i32 @cq_template_sext_i32_to_i64(i32 %9)    ; IR: %12 = sext i32 %8 to i64
  %15 = zext nneg i32 %4 to i64    ; IR: %13 = zext nneg i32 %4 to i64  (classical)
  %16 = call i32 @cq_template_sub_i64_hl(i32 %14, i64 %13)    ; IR: %14 = sub nsw i64 %12, %11  (LICM-hoisted: d = x - k)
  br label %17    ; IR: br label %20

17:; preds = %12, %17
  %18 = phi i64 [ 0, %12 ], [ %23, %17 ]    ; IR: %21 = phi i64 [ 0, %10 ], [ %30, %28 ]  (classical trip index i)
  %19 = call i32 @cq_template_icmp_sgt_i64_hl(i32 %16, i64 %18)    ; IR: %23 = icmp slt i64 %21, %14  (d > i: a compare never takes _lh, §1.2)  [path predicate of block %24]
  %20 = getelementptr inbounds double, ptr %3, i64 %18    ; IR: %25  (classical &th[i]; untainted index: stays)
  %21 = ptrtoint ptr %20 to i64    ; IR: %25 as its run-time address (the _hl operand, rule 20)
  %22 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %19, i32 %8, i64 %21)    ; IR: block %24: %26 = load double, ptr %25  [a bus load in the arm, never hoisted: _controlled under the flag (rules 3, 5, 9); the angle rail A_i, rule 11]
  call void @cqrt_ry_i32_qangle_controlled(i32 %19, i32 %10, i32 %22)    ; IR: block %24: %27 = cq_theta_si32(%22, %26)  [controlled Ry(val(A_i)) in place on r, rule 15; phi %29 is the same handle]
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %22, i32 %19, i32 %8, i64 %21)    ; IR: un-copy %26 under the same flag after its last reader (rule 5 sentence 1)
  call void @cqrt_free(i32 %22)    ; IR: release the %26 rail (|0>)
  call void @cqrt_rz_i1(i32 %19, double %6)    ; IR: block %24: cq_phi(%6)  (kickback on the flag)
  call void @cq_template_icmp_sgt_i64_hl_unc(i32 %19, i32 %16, i64 %18)    ; IR: uncompute %23
  call void @cqrt_free(i32 %19)    ; IR: release the %23 rail (|0>)
  %23 = add nuw nsw i64 %18, 1    ; IR: %30 = add nuw nsw i64 %21, 1  (classical)
  %24 = icmp eq i64 %23, %15    ; IR: %31 = icmp eq i64 %30, %13  (classical)
  br i1 %24, label %25, label %17    ; IR: br i1 %31

25:; preds = %17
  call void @cq_template_sub_i64_hl_unc(i32 %16, i32 %14, i64 %13)    ; IR: uncompute %14
  call void @cqrt_free(i32 %16)    ; IR: release the %14 rail (|0>)
  call void @cq_template_sext_i32_to_i64_unc(i32 %14, i32 %9)    ; IR: uncompute %12
  call void @cqrt_free(i32 %14)    ; IR: release the %12 rail (|0>)
  br label %26    ; IR: br label %15

26:; preds = %25, %7
  call void @cqrt_invert_end()    ; IR: %16 = phi [ %2, %7 ], [ %29, %28 ] is the handle of r (unchanged); call @__cq_invert_end(); fence consumed: the backend emits the recorded gates reversed and inverted
  %27 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %17 = cq_measure_si32(%16)
  %28 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %18 = cq_measure_si32(%8)
  %29 = add nsw i32 %28, %27    ; IR: %19  (classical)
  ret i32 %29    ; IR: ret i32 %19
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_qangle_controlled(i32, i32, i32)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_invert_begin()
declare void @cqrt_invert_end()
declare i32 @cqrt_qram_load_f64_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_f64_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cq_template_sext_i32_to_i64(i32)
declare void @cq_template_sext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_sub_i64_hl(i32, i64)
declare void @cq_template_sub_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_sgt_i64_hl(i32, i64)
declare void @cq_template_icmp_sgt_i64_hl_unc(i32, i32, i64)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
