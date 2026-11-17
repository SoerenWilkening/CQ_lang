; HAND-WRITTEN. Rules: 14, 6, 5, 4, 2.
; Checked: acc = sum over i < n, j < m of (x ^ (i * c + j)) (measured: the carried rail acc_{n,m}, %26 -> %30; rule 6 leaves
; it the only acc rail).
; Clean: every inner trip's xor rail g = x ^ (i * c + j) (uncomputed in place after the add and the rule-6 clean-up; its
; _unc reads x, not acc) and the OLD acc of every inner trip (rule 6, in the body: acc' = acc + g is a bijection in acc for
; every g and nothing reads the old acc after the add, so t = acc' - g is computed fresh, copied onto the old acc,
; uncomputed and both freed; trip (0, 0)'s old acc is the |0> incoming %7).
; Kept: the user register x (%6); acc (%26, measured). Nothing is pushed, so there is no mirror.
; Rotations: Ry(th) on x.
; Both bounds are classical (rule 14): the lowering is the same nested classical loop. The quantum body computes g and
; acc' = acc + g, then RULE 6 IN A ROLLED LOOP (2026-10-31, as 05): a carried value whose trip update is a bijection and whose
; trip predicate (none here: classical bounds) does not read it is cleaned in the body of the same trip: t = acc' - g is
; copied onto the old acc, uncomputed and freed, the old acc is freed, and the garbage g is uncomputed in place (its _unc
; reads x and the classical i * c + j). The new acc rail is the only one that survives each trip, nothing is pushed, no
; reverse loop is needed and no copy-out: the measurement reads the carried acc directly. n <= 0, and n > 0 with m <= 0,
; take the classical edges and measure the seed rail itself.
source_filename = "nested_loops.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @nested_loops(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %12 / %16  [acc before any trip: trip (0, 0)'s old acc, cleaned by rule 6 in the body; measured itself when no inner trip runs]
  %8 = icmp sgt i32 %2, 0    ; IR: %7 = icmp sgt i32 %2, 0
  br i1 %8, label %11, label %9    ; IR: br i1 %7, label %8, label %15

9:
  %10 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %17 = cq_measure_si32(%16), %16 = 0 from %5
  ret i32 %10    ; IR: ret i32 %17

11:
  %12 = phi i32 [ 0, %5 ], [ %27, %25 ]    ; IR: %11 = phi i32 [ 0, %8 ], [ %20, %18 ]  (classical)
  %13 = phi i32 [ %7, %5 ], [ %26, %25 ]    ; IR: %12 = phi i32 [ 0, %8 ], [ %19, %18 ]
  %14 = icmp sgt i32 %3, 0    ; IR: %9 = icmp sgt i32 %3, 0
  %15 = mul nsw i32 %12, %4    ; IR: %14 = mul nsw i32 %11, %4  (classical)
  br i1 %14, label %16, label %25    ; IR: br i1 %9, label %13, label %18

16:
  %17 = phi i32 [ 0, %11 ], [ %23, %16 ]    ; IR: %23 = phi i32 [ 0, %13 ], [ %28, %22 ]  (classical)
  %18 = phi i32 [ %13, %11 ], [ %21, %16 ]    ; IR: %24 = phi i32 [ %12, %13 ], [ %27, %22 ]
  %19 = add nsw i32 %17, %15    ; IR: %25 = add nsw i32 %23, %14  (classical)
  %20 = call i32 @cq_template_xor_i32_hl(i32 %6, i32 %19)    ; IR: %26 = xor i32 %25, %6  [g: garbage, uncomputed in place below]
  %21 = call i32 @cq_template_add_i32(i32 %20, i32 %18)    ; IR: %27 = add nsw i32 %26, %24  [acc_{i,j+1}: the only acc rail after this trip]
  %22 = call i32 @cq_template_sub_i32(i32 %21, i32 %20)    ; IR: rule 6: t = acc' - g recomputes the old acc (acc' = acc + g is a bijection in acc for every g)
  call void @cqrt_copy_i32(i32 %22, i32 %18)    ; IR: rule 6: old acc ^= t: |0> (trip (0, 0): the |0> incoming %7, unchanged)
  call void @cq_template_sub_i32_unc(i32 %22, i32 %21, i32 %20)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %22)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %18)    ; IR: rule 6: release the old acc rail (|0> after the copy); it is not pushed
  call void @cq_template_xor_i32_hl_unc(i32 %20, i32 %6, i32 %19)    ; IR: uncompute %26 in place (its _unc reads x and the classical %25, not acc)
  call void @cqrt_free(i32 %20)    ; IR: release the %26 rail (|0>)
  %23 = add nuw nsw i32 %17, 1    ; IR: %28 = add nuw nsw i32 %23, 1
  %24 = icmp eq i32 %23, %3    ; IR: %29 = icmp eq i32 %28, %3
  br i1 %24, label %25, label %16    ; IR: br i1 %29, label %18, label %22

25:
  %26 = phi i32 [ %13, %11 ], [ %21, %16 ]    ; IR: %19 = phi i32 [ %12, %10 ], [ %27, %22 ]
  %27 = add nuw nsw i32 %12, 1    ; IR: %20 = add nuw nsw i32 %11, 1
  %28 = icmp eq i32 %27, %2    ; IR: %21 = icmp eq i32 %20, %2
  br i1 %28, label %29, label %11    ; IR: br i1 %21, label %15, label %10

29:
  %30 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: %17 = cq_measure_si32(%16)  [the carried acc: rule 6 left no other acc rail, so no copy-out and no mirror]
  ret i32 %30    ; IR: ret i32 %17
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_xor_i32_hl(i32, i32)
declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
