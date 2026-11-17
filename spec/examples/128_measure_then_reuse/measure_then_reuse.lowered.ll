; HAND-WRITTEN. Rules: 2, 10, 4, 3.
; Checked: measure_then_reuse: cq_measure(x) + m, m the first measurement of x; measure_entangled_rotate_other:
; cq_measure(x) + m, m the measurement of y = x + c.
; Clean: none (no garbage rail is minted).
; Kept: measure_then_reuse: the measured x rail (never reused, uncomputed or freed), the then-arm's fresh rotated
; register and the else-arm's classical-value rail (one of them measured at the join); measure_entangled_rotate_other:
; x (rotated in place, measured) and the measured y rail (not provably |0> once x is rotated).
; Rotations: measure_then_reuse: Ry(th) on x; Ry(t) on a fresh register seeded with m, under the classical condition
; m > k. measure_entangled_rotate_other: Ry(th) on x; Ry(t) on x under the classical condition m > k.
; A measurement is the one place where a NAME and its register diverge (rule 2): after `m = cq_measure(x)` the source
; keeps reading x, and every later read of %5 denotes m, a classical value. So the branch on m is ordinary classical
; control (a real br, handle phi at the join, no flag), the then-arm rotation is a fresh register seeded with m and
; rotated, and the else-arm `x += 1` is classical m + 1, put on a rail only because the join merges it with a quantum
; value. The measured rail itself is never reused, uncomputed or freed (it is not provably |0>). In
; measure_entangled_rotate_other the MEASURED name is y; x is never measured, so x keeps naming its own rail (collapsed
; to m - c by the measurement of y, but the compiler never derives that) and the classical-controlled rotation fires in
; place on it. The measured y rail stays allocated: uncomputing y = x + c against x is only valid until x is rotated,
; and a measured rail is never touched.
source_filename = "measure_then_reuse.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @measure_then_reuse(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)  [from here on, %5 reads as %6]
  %7 = icmp sgt i32 %6, %2    ; IR: %7  (classical)
  br i1 %7, label %8, label %10    ; IR: br i1 %7  (classical control)

8:; preds = %4
  %9 = call i32 @cqrt_alloc_i32(i32 %6)    ; IR: %9 = cq_theta_si32(%5, %3)  [fresh register seeded with the measured value]
  call void @cqrt_ry_i32(i32 %9, double %3)    ; IR: %9 = cq_theta_si32(%5, %3)  [Ry]
  br label %13

10:; preds = %4
  %11 = add nsw i32 %6, 1    ; IR: %11 = add nsw i32 %5, 1  (classical: %5 reads as %6)
  %12 = call i32 @cqrt_alloc_i32(i32 %11)    ; IR: %13 = phi  [the classical arm value on a rail, to meet the quantum arm]
  br label %13

13:; preds = %10, %8
  %14 = phi i32 [ %9, %8 ], [ %12, %10 ]    ; IR: %13 = phi i32 [ %9, %8 ], [ %11, %10 ]  (handle phi under classical control)
  %15 = call i32 @cqrt_measure_i32(i32 %14)    ; IR: %14 = cq_measure_si32(%13)
  %16 = add nsw i32 %15, %6    ; IR: %15  (classical)
  ret i32 %16    ; IR: ret i32 %15
}

define i32 @measure_entangled_rotate_other(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_add_i32_hl(i32 %6, i32 %2)    ; IR: %7 = add nsw i32 %6, %2  [y entangled with x]
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_si32(%7)  [y measured: its rail stays allocated]
  %9 = icmp sgt i32 %8, %3    ; IR: %9  (classical)
  br i1 %9, label %10, label %11    ; IR: br i1 %9  (classical control)

10:; preds = %5
  call void @cqrt_ry_i32(i32 %6, double %4)    ; IR: %11 = cq_theta_si32(%6, %4)  [Ry in place on x: x itself was not measured]
  br label %11

11:; preds = %10, %5
  %12 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %13 = phi i32 [ %11, %10 ], [ %6, %5 ] (one rail in both arms); %14 = cq_measure_si32(%13)
  %13 = add nsw i32 %12, %8    ; IR: %15  (classical)
  ret i32 %13    ; IR: ret i32 %15
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cqrt_measure_i32(i32)
