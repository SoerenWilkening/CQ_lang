; HAND-WRITTEN. Rules: 14 (nested K-loops), 8, 7, 5.
; Checked: acc (the copied-out result %32 -> %66).
; Clean: every rail except a_K and the K rails b_K: every trip's values and intermediate predicates, popped and uncomputed
; by the mirror loops; a_0 through the guard compare; the |0> seed of acc (%62); the guard compare itself (%6).
; Kept: x (%4, the rotated register); the outer chain's last predicate a_K (%28 of outer trip K-1, popped as %36 on the first
; outer reverse trip); the K inner last predicates b_K (%22 of inner trip K-1 of each outer trip, popped as %38); the result
; %32 (measured).
; Rotations: (Ry, x, th, 1).
; A quantum-bounded loop nested inside a quantum-bounded loop, the k_rem_pio2 shape: this is example 05 composed with
; itself. -O1 made both loops bottom-tested (do-while) behind one guard x == 0. The outer loop runs K trips under the chain
; a_k (a_0 = NOT(x == 0), a_{k+1} = a_k & NOT(i - 1 == 0)); each outer trip runs an inner rolled loop of K trips under its
; own chain seeded from the outer predicate (b_0 = a_k, b_{m+1} = b_m & NOT(j + 1 == i)); the inner j is the classical trip
; index (it equals m whenever the trip is live), the outer i is quantum (it starts at x). Stack discipline: every inner trip
; pushes its handles, then the outer trip pushes its own (i, a_k, i - 1, the exit flag, the inner chain's final predicate).
; The reverse pops in stack order: an outer reverse trip pops its own handles, uncomputes them, then runs the inner reverse
; loop (popping the inner trips in reverse order); the pops match the pushes because the inner pushes of outer trip k sit
; above outer trip k's own pushes. This is not the exact gate mirror (forward ran the inner trips before the outer
; trip's i - 1, select, compare and a_{k+1}), and it need not be: rule 5 asks for dependency order, and those outer rails
; read only i and a_k, which the inner trips also only read, while no inner rail reads them; both groups' sources
; (i, a_k) stay live until the next reverse trip, so the two groups commute. K = 4 here; every literal K is tagged [K].
; Output rails (rule 14): the outer chain's last predicate a_K (a_K = 1 means the outer loop would have run past K trips) is
; kept allocated, neither uncomputed nor freed; the outer reverse loop skips its uncompute on reverse index 0 by a classical
; branch. Likewise each outer trip's inner chain keeps ITS last predicate b_K (pushed by the outer trip): K inner output
; rails in all, one per outer trip (b_K of a dead outer trip is |0>); the inner reverse loop skips the uncompute on reverse
; inner index K-1. Every other predicate is uncomputed as before; a_0 is uncomputed through the guard compare.
source_filename = "nested_quantum_loops.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @nested_quantum_loops(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %8 / %10
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 0)    ; IR: %5 = icmp eq i32 %4, 0  [guard]
  %7 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of entering the outer loop = NOT %5
  call void @cqrt_not_i1(i32 %6)    ; IR: bracket: NOT %5
  call void @cqrt_xor_i1(i32 %6, i32 %7)    ; IR: a_0 = NOT %5  (CNOT into the |0> rail)
  call void @cqrt_not_i1(i32 %6)    ; IR: bracket
  br label %8

8:
  %9 = phi i32 [ 0, %3 ], [ %29, %24 ]    ; IR: outer trip index, bounded by K
  %10 = phi i32 [ %4, %3 ], [ %26, %24 ]    ; IR: %7 = phi i32 [ %13, %12 ], [ %4, %3 ]
  %11 = phi i32 [ %5, %3 ], [ %19, %24 ]    ; IR: %8 = phi i32 [ %19, %12 ], [ 0, %3 ]
  %12 = phi i32 [ %7, %3 ], [ %28, %24 ]    ; IR: predicate of this outer trip (a_k)
  br label %13    ; IR: br label %15

13:
  %14 = phi i32 [ 0, %8 ], [ %20, %13 ]    ; IR: %16 = phi i32 [ 0, %6 ], [ %20, %15 ]  (j: classical trip index)
  %15 = phi i32 [ %11, %8 ], [ %19, %13 ]    ; IR: %17 = phi i32 [ %8, %6 ], [ %19, %15 ]
  %16 = phi i32 [ %12, %8 ], [ %22, %13 ]    ; IR: predicate of this inner trip (b_m; b_0 = a_k)
  %17 = call i32 @cq_template_mul_i32_hl(i32 %15, i32 %2)    ; IR: %18 = mul i32 %17, %2
  %18 = call i32 @cq_template_add_i32_hl(i32 %17, i32 %14)    ; IR: %19 = add i32 %18, %16
  %19 = call i32 @cq_template_select_i32(i32 %16, i32 %18, i32 %15)    ; IR: next %17 / %8 = b_m ? %19 : %17
  %20 = add nuw i32 %14, 1    ; IR: %20 = add nuw i32 %16, 1  (classical)
  %21 = call i32 @cq_template_icmp_eq_i32_hl(i32 %10, i32 %20)    ; IR: %21 = icmp eq i32 %20, %7  (commutative: quantum %7 in the _hl slot)
  %22 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of the next inner trip
  call void @cqrt_not_i1(i32 %21)    ; IR: bracket: NOT %21
  call void @cqrt_and_i1(i32 %16, i32 %21, i32 %22)    ; IR: br i1 %21 not taken: b_{m+1} = b_m & NOT %21
  call void @cqrt_not_i1(i32 %21)    ; IR: bracket
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %21)
  %23 = icmp ult i32 %20, 4    ; IR: K-bounded br i1 %21, label %12, label %15  [K]
  br i1 %23, label %13, label %24

24:
  %25 = call i32 @cq_template_add_i32_hl(i32 %10, i32 -1)    ; IR: %13 = add i32 %7, -1
  %26 = call i32 @cq_template_select_i32(i32 %12, i32 %25, i32 %10)    ; IR: next %7 = a_k ? %13 : %7
  %27 = call i32 @cq_template_icmp_eq_i32_hl(i32 %25, i32 0)    ; IR: %14 = icmp eq i32 %13, 0
  %28 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of the next outer trip
  call void @cqrt_not_i1(i32 %27)    ; IR: bracket: NOT %14
  call void @cqrt_and_i1(i32 %12, i32 %27, i32 %28)    ; IR: br i1 %14 not taken: a_{k+1} = a_k & NOT %14
  call void @cqrt_not_i1(i32 %27)    ; IR: bracket
  call void @cqrt_push(i32 %10)
  call void @cqrt_push(i32 %12)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %22)    ; IR: the inner chain's final predicate b_K of this outer trip
  %29 = add nuw nsw i32 %9, 1
  %30 = icmp ult i32 %29, 4    ; IR: K-bounded br i1 %14, label %9, label %6  [K]
  br i1 %30, label %8, label %31

31:
  %32 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %10 = phi i32 [ 0, %3 ], [ %19, %12 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %19, i32 %32)    ; IR: %10
  br label %33

33:
  %34 = phi i32 [ 0, %31 ], [ %63, %61 ]    ; IR: reverse outer trip index
  %35 = phi i32 [ %26, %31 ], [ %42, %61 ]    ; IR: %7 written by this outer trip
  %36 = phi i32 [ %28, %31 ], [ %41, %61 ]    ; IR: predicate of the next outer trip (a_{k+1})
  %37 = phi i32 [ %19, %31 ], [ %62, %61 ]    ; IR: acc after this outer trip
  %38 = call i32 @cqrt_pop()
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()
  %43 = icmp eq i32 %34, 0    ; IR: reverse index 0 is outer trip K-1: its a_{k+1} = a_K is an output rail (rule 14)
  br i1 %43, label %45, label %44

44:
  call void @cqrt_not_i1(i32 %39)    ; IR: bracket
  call void @cqrt_and_i1(i32 %41, i32 %39, i32 %36)    ; IR: uncompute a_{k+1} (outer trips 0..K-2)
  call void @cqrt_not_i1(i32 %39)    ; IR: bracket
  call void @cqrt_free(i32 %36)    ; IR: release a_{k+1} (|0>)
  br label %45

45:
  call void @cq_template_select_i32_unc(i32 %35, i32 %41, i32 %40, i32 %42)    ; IR: uncompute next %7
  call void @cqrt_free(i32 %35)    ; IR: release next %7 (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %39, i32 %40, i32 0)    ; IR: uncompute %14
  call void @cqrt_free(i32 %39)    ; IR: release %14 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %40, i32 %42, i32 -1)    ; IR: uncompute %13
  call void @cqrt_free(i32 %40)    ; IR: release %13 (|0>)
  br label %46

46:
  %47 = phi i32 [ 3, %45 ], [ %59, %58 ]    ; IR: reverse inner trip index (K - 1 down to 0)  [K]
  %48 = phi i32 [ %38, %45 ], [ %51, %58 ]    ; IR: b_{m+1} of this inner trip
  %49 = phi i32 [ %37, %45 ], [ %54, %58 ]    ; IR: %17 / %8 written by this inner trip
  %50 = call i32 @cqrt_pop()
  %51 = call i32 @cqrt_pop()
  %52 = call i32 @cqrt_pop()
  %53 = call i32 @cqrt_pop()
  %54 = call i32 @cqrt_pop()
  %55 = add nuw i32 %47, 1    ; IR: %20 of this trip (classical)
  %56 = icmp eq i32 %47, 3    ; IR: reverse inner index K-1 is inner trip K-1: its b_{m+1} = b_K is an output rail (rule 14)  [K]
  br i1 %56, label %58, label %57

57:
  call void @cqrt_not_i1(i32 %50)    ; IR: bracket
  call void @cqrt_and_i1(i32 %51, i32 %50, i32 %48)    ; IR: uncompute b_{m+1} (inner trips 0..K-2)
  call void @cqrt_not_i1(i32 %50)    ; IR: bracket
  call void @cqrt_free(i32 %48)    ; IR: release b_{m+1} (|0>)
  br label %58

58:
  call void @cq_template_select_i32_unc(i32 %49, i32 %51, i32 %52, i32 %54)    ; IR: uncompute next %17
  call void @cqrt_free(i32 %49)    ; IR: release next %17 (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %50, i32 %42, i32 %55)    ; IR: uncompute %21
  call void @cqrt_free(i32 %50)    ; IR: release %21 (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %52, i32 %53, i32 %47)    ; IR: uncompute %19
  call void @cqrt_free(i32 %52)    ; IR: release %19 (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %53, i32 %54, i32 %2)    ; IR: uncompute %18
  call void @cqrt_free(i32 %53)    ; IR: release %18 (|0>)
  %59 = sub i32 %47, 1
  %60 = icmp sge i32 %59, 0
  br i1 %60, label %46, label %61

61:
  %62 = phi i32 [ %54, %58 ]    ; IR: acc at the start of this outer trip (the last popped %17 incoming)
  %63 = add nuw nsw i32 %34, 1
  %64 = icmp ult i32 %63, 4    ; IR: [K]
  br i1 %64, label %33, label %65

65:
  call void @cqrt_not_i1(i32 %6)    ; IR: bracket
  call void @cqrt_xor_i1(i32 %6, i32 %41)    ; IR: uncompute a_0 (the last popped a_k is a_0)
  call void @cqrt_not_i1(i32 %6)    ; IR: bracket
  call void @cqrt_free(i32 %41)    ; IR: release a_0 (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %4, i32 0)    ; IR: uncompute %5
  call void @cqrt_free(i32 %6)    ; IR: release %5 (|0>)
  call void @cqrt_free(i32 %62)    ; IR: release incoming 0 of phi %8 (never written, |0>)
  %66 = call i32 @cqrt_measure_i32(i32 %32)    ; IR: %11 = cq_measure_ui32(%10)
  ret i32 %66    ; IR: ret i32 %11
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_xor_i1(i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
