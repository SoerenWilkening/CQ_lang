; HAND-WRITTEN. Rules: 8, 5, 2.
; Checked: x (measured) in each function.
; Clean: every compare flag and every conjunction rail (two in depth3_phase_nest, eight in nine_leaf_tree).
; Kept: the user register x.
; Rotations: depth3_phase_nest: Ry(th) on x; P(p1) on (x > k1); P(p2) on (x > k1) & (x < k2); P(p3) on
; (x > k1) & (x < k2) & NOT (x == k3). nine_leaf_tree: Ry(th) on x; P(p) on (x > k1) & (x < k2) & (x != k3) & (x > k4)
; & (x < k5) & (x != k6) & (x > k7) & (x < k8) & (x != k9).
; Nesting depth and tree width are unbounded (rule 8). A DEPTH-N PHASE NEST is 08 continued: the predicate of each
; level is the conjunction of its parent's predicate and its own compare, one Toffoli into a fresh |0> rail per level,
; each level's phase a kickback on its predicate, torn down LIFO (N-1 Toffolis for depth N). A negated inner condition
; (the eq compare whose FALSE edge carries the phase) is bracketed by cqrt_not_i1 on the compare flag, never on a user
; register. A WIDE CONDITION TREE is 23's and-ladder continued: -O1 folds the nine && into eight i1 ands; each is one
; Toffoli into a fresh rail, the phase fires on the last, and the ladder is uncomputed in reverse. Ancilla count grows
; with the tree (8 rails here), which is the only cost.
source_filename = "deep_nest_wide_tree.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @depth3_phase_nest(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, double noundef %6, double noundef %7) {
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %9 = cq_theta_si32(%0, %1)  [Ry]
  %10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %9, i32 %2)    ; IR: %10 = icmp sgt i32 %9, %2  [path predicate of block %11]
  call void @cqrt_rz_i1(i32 %10, double %5)    ; IR: block %11: cq_phi(%5)
  %11 = call i32 @cq_template_icmp_slt_i32_hl(i32 %9, i32 %3)    ; IR: %12 = icmp slt i32 %9, %3
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %13 = %10 & %12
  call void @cqrt_and_i1(i32 %10, i32 %11, i32 %12)    ; IR: br i1 %12 inside block %11
  call void @cqrt_rz_i1(i32 %12, double %6)    ; IR: block %13: cq_phi(%6)
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 %4)    ; IR: %14 = icmp eq i32 %9, %4  (block %15 is its FALSE edge)
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %15 = %10 & %12 & NOT %14
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket: block %15 runs under NOT %14
  call void @cqrt_and_i1(i32 %12, i32 %13, i32 %14)    ; IR: br i1 %14 inside block %13, false edge
  call void @cqrt_rz_i1(i32 %14, double %7)    ; IR: block %15: cq_phi(%7)
  call void @cqrt_and_i1(i32 %12, i32 %13, i32 %14)    ; IR: uncompute the %15 predicate
  call void @cqrt_not_i1(i32 %13)    ; IR: bracket
  call void @cqrt_free(i32 %14)    ; IR: release the %15 predicate (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %9, i32 %4)    ; IR: uncompute %14
  call void @cqrt_free(i32 %13)    ; IR: release the %14 rail (|0>)
  call void @cqrt_and_i1(i32 %10, i32 %11, i32 %12)    ; IR: uncompute the %13 predicate
  call void @cqrt_free(i32 %12)    ; IR: release the %13 predicate (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %11, i32 %9, i32 %3)    ; IR: uncompute %12
  call void @cqrt_free(i32 %11)    ; IR: release the %12 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %10, i32 %9, i32 %2)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  %15 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %17 = cq_measure_si32(%9)
  ret i32 %15    ; IR: ret i32 %17
}

define i32 @nine_leaf_tree(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, i32 noundef %5, i32 noundef %6, i32 noundef %7, i32 noundef %8, i32 noundef %9, i32 noundef %10, double noundef %11) {
  %13 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %13 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %13, double %1)    ; IR: %13 = cq_theta_si32(%0, %1)  [Ry]
  %14 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %13, i32 %2)    ; IR: %14 = icmp sgt i32 %13, %2
  %15 = call i32 @cq_template_icmp_slt_i32_hl(i32 %13, i32 %3)    ; IR: %15 = icmp slt i32 %13, %3
  %16 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %16 = and i1 %14, %15
  call void @cqrt_and_i1(i32 %14, i32 %15, i32 %16)    ; IR: %16
  %17 = call i32 @cq_template_icmp_ne_i32_hl(i32 %13, i32 %4)    ; IR: %17 = icmp ne i32 %13, %4
  %18 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %18 = and i1 %17, %16
  call void @cqrt_and_i1(i32 %17, i32 %16, i32 %18)    ; IR: %18
  %19 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %13, i32 %5)    ; IR: %19 = icmp sgt i32 %13, %5
  %20 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %20 = and i1 %19, %18
  call void @cqrt_and_i1(i32 %19, i32 %18, i32 %20)    ; IR: %20
  %21 = call i32 @cq_template_icmp_slt_i32_hl(i32 %13, i32 %6)    ; IR: %21 = icmp slt i32 %13, %6
  %22 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %22 = and i1 %21, %20
  call void @cqrt_and_i1(i32 %21, i32 %20, i32 %22)    ; IR: %22
  %23 = call i32 @cq_template_icmp_ne_i32_hl(i32 %13, i32 %7)    ; IR: %23 = icmp ne i32 %13, %7
  %24 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %24 = and i1 %23, %22
  call void @cqrt_and_i1(i32 %23, i32 %22, i32 %24)    ; IR: %24
  %25 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %13, i32 %8)    ; IR: %25 = icmp sgt i32 %13, %8
  %26 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %26 = and i1 %25, %24
  call void @cqrt_and_i1(i32 %25, i32 %24, i32 %26)    ; IR: %26
  %27 = call i32 @cq_template_icmp_slt_i32_hl(i32 %13, i32 %9)    ; IR: %27 = icmp slt i32 %13, %9
  %28 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %28 = and i1 %27, %26
  call void @cqrt_and_i1(i32 %27, i32 %26, i32 %28)    ; IR: %28
  %29 = call i32 @cq_template_icmp_ne_i32_hl(i32 %13, i32 %10)    ; IR: %29 = icmp ne i32 %13, %10
  %30 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %30 = and i1 %29, %28  [path predicate of block %31]
  call void @cqrt_and_i1(i32 %29, i32 %28, i32 %30)    ; IR: %30
  call void @cqrt_rz_i1(i32 %30, double %11)    ; IR: block %31 under br i1 %30: cq_phi(%11)
  call void @cqrt_and_i1(i32 %29, i32 %28, i32 %30)    ; IR: uncompute %30
  call void @cqrt_free(i32 %30)    ; IR: release the %30 rail (|0>)
  call void @cq_template_icmp_ne_i32_hl_unc(i32 %29, i32 %13, i32 %10)    ; IR: uncompute %29
  call void @cqrt_free(i32 %29)    ; IR: release the %29 rail (|0>)
  call void @cqrt_and_i1(i32 %27, i32 %26, i32 %28)    ; IR: uncompute %28
  call void @cqrt_free(i32 %28)    ; IR: release the %28 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %27, i32 %13, i32 %9)    ; IR: uncompute %27
  call void @cqrt_free(i32 %27)    ; IR: release the %27 rail (|0>)
  call void @cqrt_and_i1(i32 %25, i32 %24, i32 %26)    ; IR: uncompute %26
  call void @cqrt_free(i32 %26)    ; IR: release the %26 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %25, i32 %13, i32 %8)    ; IR: uncompute %25
  call void @cqrt_free(i32 %25)    ; IR: release the %25 rail (|0>)
  call void @cqrt_and_i1(i32 %23, i32 %22, i32 %24)    ; IR: uncompute %24
  call void @cqrt_free(i32 %24)    ; IR: release the %24 rail (|0>)
  call void @cq_template_icmp_ne_i32_hl_unc(i32 %23, i32 %13, i32 %7)    ; IR: uncompute %23
  call void @cqrt_free(i32 %23)    ; IR: release the %23 rail (|0>)
  call void @cqrt_and_i1(i32 %21, i32 %20, i32 %22)    ; IR: uncompute %22
  call void @cqrt_free(i32 %22)    ; IR: release the %22 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %21, i32 %13, i32 %6)    ; IR: uncompute %21
  call void @cqrt_free(i32 %21)    ; IR: release the %21 rail (|0>)
  call void @cqrt_and_i1(i32 %19, i32 %18, i32 %20)    ; IR: uncompute %20
  call void @cqrt_free(i32 %20)    ; IR: release the %20 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %19, i32 %13, i32 %5)    ; IR: uncompute %19
  call void @cqrt_free(i32 %19)    ; IR: release the %19 rail (|0>)
  call void @cqrt_and_i1(i32 %17, i32 %16, i32 %18)    ; IR: uncompute %18
  call void @cqrt_free(i32 %18)    ; IR: release the %18 rail (|0>)
  call void @cq_template_icmp_ne_i32_hl_unc(i32 %17, i32 %13, i32 %4)    ; IR: uncompute %17
  call void @cqrt_free(i32 %17)    ; IR: release the %17 rail (|0>)
  call void @cqrt_and_i1(i32 %14, i32 %15, i32 %16)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %15, i32 %13, i32 %3)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the %15 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %14, i32 %13, i32 %2)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  %31 = call i32 @cqrt_measure_i32(i32 %13)    ; IR: %33 = cq_measure_si32(%13)
  ret i32 %31    ; IR: ret i32 %33
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ne_i32_hl(i32, i32)
declare void @cq_template_icmp_ne_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
