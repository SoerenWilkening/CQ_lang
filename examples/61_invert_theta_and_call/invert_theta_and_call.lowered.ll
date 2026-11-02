; HAND-WRITTEN. Rules: 17, 2, 18, 10, 20, 8, §1.3.
; Checked: invert_theta: x (%4 -> %5). invert_call: x (the slot pointee, %10 -> %11) and y (%9 -> %12), summed classically.
; Clean: the flag f = (y > k) of the clone (%7 of __cq_q_prep_11000), uncomputed and freed after its controlled rotation
;        (in the bracketed activation the backend recomputes and uncomputes it as the reversed list runs, rule 17).
; Kept: the user registers x and y in both functions (rotated, measured).
; Rotations: invert_theta: (Ry, x, th, 1); then the region as the backend emits it: (Ry, x, -t2, 1).
; invert_call: (Ry, y, ty, 1); (Ry, x, t1, 1); (Ry, x, t2, y > k); then the region: (Ry, x, -t2, y > k); (Ry, x, -t1, 1).
; cq_invert is the run-time pair cqrt_invert_begin()/cqrt_invert_end() (rule 17, §1.3): the code between the markers is
; lowered as anywhere else, and the backend emits the gates recorded between the two calls reversed with each gate
; inverted. invert_theta: the recorded list is [Ry(x, t2)], emitted as Ry(x, -t2). invert_call: `prep(&x, ...)` takes
; the register's ADDRESS, so x lives in a classical slot holding its handle (31) and the clone rotates that handle in
; place with no result rail; the conditional rotation is controlled by a flag computed from the OTHER register y. The
; clone __cq_q_prep_11000 (mask over all five args, §1.4: a pointer-to-slot field's digit is 1 iff the cell holds a
; handle AT THE CALL; x's cell does: it holds a handle after the clone's rotation, so it is a handle on every path (rule
; 20's homogeneous cell) and the caller's classical x = x0 is the seed rail alloc_i32(x0) stored before the call; y is a
; quantum scalar; k and the angles are classical) is [Ry(x, t1); f = (y > k); cRy(f, x, t2); unc f; free f]. The
; bracketed call is the SAME clone (no `_adj` kind exists, §1.4): the backend's reversal of the gates it records is
; [unc f (= compute f); cRy(f, x, -t2); f's uncompute; Ry(x, -t1); free f], the compare/uncompute pair reversing into
; itself. Had the condition read x itself (`if (*x > k) cq_theta(x, t2)`), the flag could not be uncomputed after the
; rotation changed x; that shape is example 66, where the flag stays allocated. Regenerated 2026-11-02 (the first version
; constructed __cq_q_prep_11000_adj at compile time).
source_filename = "invert_theta_and_call.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @invert_theta(i32 noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  call void @cqrt_invert_begin()    ; IR: call @__cq_invert_begin(); fence consumed (rule 17)
  call void @cqrt_ry_i32(i32 %4, double %2)    ; IR: %5 = cq_theta_si32(%4, %2)  [Ry in place; the backend emits it as Ry(-%2) when the region closes]
  call void @cqrt_invert_end()    ; IR: call @__cq_invert_end(); fence consumed
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %5    ; IR: ret i32 %6
}

define i32 @invert_call(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, double noundef %4, i32 noundef %5) {
  %7 = alloca i32, align 4    ; IR: %7 = alloca i32  (classical slot: holds the handle of x, whose address escapes to prep)
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: store i32 %0, ptr %7: x = x0  [register x: the seed rail of the slot cell (rule 20), classical start]
  store i32 %8, ptr %7, align 4    ; IR: store i32 %0, ptr %7  (the slot holds the handle)
  %9 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %8 = cq_theta_ui32(%1, %2)  [register y]
  call void @cqrt_ry_i32(i32 %9, double %2)    ; IR: %8 = cq_theta_ui32(%1, %2)  [Ry]
  call fastcc void @__cq_q_prep_11000(ptr %7, i32 %9, double %3, double %4, i32 %5)    ; IR: call @prep(%7, %8, %3, %4, %5), quantum clone (slot pointee and y quantum)
  call void @cqrt_invert_begin()    ; IR: call @__cq_invert_begin(); fence consumed (rule 17)
  call fastcc void @__cq_q_prep_11000(ptr %7, i32 %9, double %3, double %4, i32 %5)    ; IR: bracketed call @prep(%7, %8, %3, %4, %5): the same clone; the backend reverses and inverts the gates it records
  call void @cqrt_invert_end()    ; IR: call @__cq_invert_end(); fence consumed
  %10 = load i32, ptr %7, align 4    ; IR: %9 = load i32, ptr %7  (the handle of x)
  %11 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %10 = cq_measure_ui32(%9)
  %12 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %11 = cq_measure_ui32(%8)
  %13 = add i32 %12, %11    ; IR: %12 = add i32 %11, %10  (classical)
  ret i32 %13    ; IR: ret i32 %12
}

define internal fastcc void @__cq_q_prep_11000(ptr %0, i32 %1, double %2, double %3, i32 %4) {
  %6 = load i32, ptr %0, align 4    ; IR: %6 = load i32, ptr %0  (the handle of *x)
  call void @cqrt_ry_i32(i32 %6, double %2)    ; IR: %7 = cq_theta_ui32(%6, %2); store i32 %7, ptr %0  [Ry in place on *x; the handle is unchanged, no store]
  %7 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %1, i32 %4)    ; IR: %8 = icmp ugt i32 %1, %4  [path predicate of block %9]
  call void @cqrt_ry_i32_controlled(i32 %7, i32 %6, double %3)    ; IR: block %9: %10 = cq_theta_ui32(%7, %3); store i32 %10, ptr %0  [Ry under the predicate]
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %7, i32 %1, i32 %4)    ; IR: uncompute %8
  call void @cqrt_free(i32 %7)    ; IR: release the %8 rail (|0>)
  ret void    ; IR: ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_invert_begin()
declare void @cqrt_invert_end()
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
