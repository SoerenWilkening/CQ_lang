; HAND-WRITTEN. Rules: 19, 10, 8, 18, 20, 5, 2.
; Checked: r + x + b (measured).
; Clean: inside every trip's clone call, the callee flag f = (x > k + i) and the composed flag g = b & f.
; Kept: the user registers x and b (control and compare inputs only, measured); r (rotated in place under control,
; frozen, measured).
; Rotations: Ry(tx) on x; Ry(tb) on b; for each trip i = 0..n-1 (classical, n > 0): Ry(t) on r under b & (x > k + i).
; A CONTROLLED RY UNDER A COMPOSED CONTROL, ACROSS A CALL, INSIDE A CLASSICAL LOOP THAT SITS IN A QUANTUM ARM. Three
; pieces, each from an existing example:
;   (1) -O1 fuses the outer `if (b)` with the loop guard `n > 0` into one `and i1 %10, %11`. One operand is the bare
;       _Bool rail b (59: a rail is a condition by itself), the other is classical. A classical conjunct is split off as
;       a classical branch (rule 8): when it is false nothing runs, when it is true the predicate IS b. No AND flag is
;       computed in the caller, and the trip counter, the bound and `k + i` all stay classical.
;   (2) The call to step runs under the quantum predicate b, and step has an effect (the store through r that rotates
;       the caller's register in place), so it becomes a CONTROLLED CLONE with the predicate as its first parameter
;       (rule 19, 102: __cq_q_<fn>_ctl_<mask>). The mask is over step's four arguments: the slot pointee *r is quantum
;       (r's address escapes, so r lives in a classical slot holding its handle, 61) and x is quantum; k and t are
;       classical.
;   (3) Inside the clone, the callee's own condition x > k becomes a flag f, and the composed control pred AND f is a
;       Toffoli into a fresh |0> flag g (59). The Ry on *r fires under g, in place (cqrt_ry_i32_controlled, r frozen
;       afterwards, rule 10). Then g is uncomputed with the same Toffoli (pred and f are unchanged), and f with its
;       compare's _unc. Both are freed provably |0>. One clone call per trip; g and f are trip-local, so nothing
;       survives the loop.
; Nothing non-diagonal touches a user register except the controlled Ry itself. b and x are only control or compare
; inputs, so they are left untouched and measured by the user.
source_filename = "callee_controlled_ry_in_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @callee_controlled_ry_in_loop(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, i32 noundef %6) {
  %8 = alloca i32, align 4    ; IR: %8 = alloca i32  (classical slot: holds the handle of r, whose address escapes to step)
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %9 = cq_theta_si32(%0, %1)  [Ry]
  %10 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %10 = cq_theta_i1(false, %2)  [register b]
  call void @cqrt_ry_i1(i32 %10, double %2)    ; IR: %10 = cq_theta_i1(false, %2)  [Ry]
  %11 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: store i32 %3, ptr %8: r = r0  [register r, classical start]
  store i32 %11, ptr %8, align 4    ; IR: store i32 %3, ptr %8  (the slot holds the handle)
  %12 = icmp sgt i32 %6, 0    ; IR: %11 = icmp sgt i32 %6, 0  (classical)
  br i1 %12, label %13, label %18    ; IR: %12 = and i1 %10, %11; br i1 %12  (classical conjunct split off; the quantum conjunct b is the predicate of every call below)

13:; preds = %7, %13
  %14 = phi i32 [ %16, %13 ], [ 0, %7 ]    ; IR: %14  (classical trip counter i)
  %15 = add nsw i32 %14, %4    ; IR: %15 = add nsw i32 %14, %4  (classical k + i)
  call fastcc void @__cq_q_step_1100_ctl(i32 %10, ptr %8, i32 %9, i32 %15, double %5)    ; IR: call @step(%8, %9, %15, %5) under predicate %10: controlled clone
  %16 = add nuw nsw i32 %14, 1    ; IR: %16  (classical)
  %17 = icmp eq i32 %16, %6    ; IR: %17  (classical)
  br i1 %17, label %18, label %13    ; IR: br i1 %17

18:; preds = %13, %7
  %19 = load i32, ptr %8, align 4    ; IR: %19 = load i32, ptr %8  (the handle of r)
  %20 = call i32 @cqrt_measure_i32(i32 %19)    ; IR: %20 = cq_measure_si32(%19)
  %21 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %21 = cq_measure_si32(%9)
  %22 = add nsw i32 %21, %20    ; IR: %22  (classical)
  %23 = call i1 @cqrt_measure_i1(i32 %10)    ; IR: %23 = cq_measure_i1(%10)
  %24 = zext i1 %23 to i32    ; IR: %24  (classical)
  %25 = add nsw i32 %22, %24    ; IR: %25  (classical)
  ret i32 %25    ; IR: ret i32 %25
}

define internal fastcc void @__cq_q_step_1100_ctl(i32 %0, ptr %1, i32 %2, i32 %3, double %4) {
  %6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %2, i32 %3)    ; IR: %5 = icmp sgt i32 %1, %2  [the callee's own predicate]
  %7 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %6 = pred & %5  [fresh |0> flag]
  call void @cqrt_and_i1(i32 %0, i32 %6, i32 %7)    ; IR: pred & %5  (Toffoli into the |0> flag)
  %8 = load i32, ptr %1, align 4    ; IR: %7 = load i32, ptr %0  (the handle of *r, hoisted from block %6: pure)
  call void @cqrt_ry_i32_controlled(i32 %7, i32 %8, double %4)    ; IR: block %6: %8 = cq_theta_si32(%7, %3); store i32 %8, ptr %0  [Ry in place on *r under pred & %5; the handle is unchanged, no store]
  call void @cqrt_and_i1(i32 %0, i32 %6, i32 %7)    ; IR: uncompute pred & %5 (pred, %5 unchanged)
  call void @cqrt_free(i32 %7)    ; IR: release the composed flag (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %6, i32 %2, i32 %3)    ; IR: uncompute %5 (x unchanged: it is not the rotated register)
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  ret void    ; IR: ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i1 @cqrt_measure_i1(i32)
