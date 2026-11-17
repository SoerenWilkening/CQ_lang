; HAND-WRITTEN. Rules: 14, 4, 5 (Memory, sentence 1), 20, 21, 3, 2.
; Checked: s = Horner evaluation of coef[0..n-1] at x (measured).
; Clean: every trip's accumulator rail and product rail s * x (both popped and uncomputed by the mirror, the sum
; before the product it read) and every load copy of coef[i] (popped by the mirror and un-copied right after the sum's
; _unc, its last reader); the load copy of coef[0] (the incoming accumulator, un-copied after the mirror, whose last
; reader is trip 1's fmul _unc, the mirror's final step). No memory version change occurs in the function, so every load copy whose
; consumer is uncomputed is un-copied (rule 5 sentence 1).
; Kept: the user register x; the copied-out result rail (measured); on the n <= 1 path the load copy of coef[0]
; (measured directly: rule 2's measured rail, never un-copied).
; Rotations: Ry(th) on x.
; MEMORY. coef is a pointer PARAMETER: nothing is known about the object it addresses (rule 21), so every load through
; it is a bus load and its value a RAIL (rules 3, 20), although the program only reads classical host bytes (over-taint
; is accepted; such a rail costs no qubit). m = __cq_mem() is taken once at entry, and the run-time address of %2 once
; after it, as the classical i64 of the _hl form (rule 20). The index i is a classical induction, so &coef[i] is the
; classical getelementptr's ptrtoint (no inbounds: rule 21) and every access is cqrt_qram_load_f64_hl. coef[0] is the
; incoming accumulator: a load copy, not a seed. clang contracts s * x + coef[i] into llvm.fmuladd.f64, which is
; UNFUSED (§2): each trip is an fmul into a fresh product rail and an fadd of the product and the loaded coef[i] rail
; (both operands rails now: cq_template_fadd_f64, rule 4) into a fresh accumulator rail. The accumulator chain is a
; classical loop with the handle stack (rule 14, classical bound): each trip pushes the old accumulator, its product
; rail and its load copy, and the mirror (after the result is copied out) pops them, uncomputes the sum, un-copies the
; load at the address recomputed from the trip index (rule 14: classical, never pushed), then uncomputes the product
; (rule 5, dependency order). n <= 1 takes the classical edge and measures the coef[0] load copy itself.
source_filename = "horner_accumulator.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @horner(double noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: (no instruction) the bus m, once at function entry
  %6 = ptrtoint ptr %2 to i64    ; IR: (no instruction) the run-time address in %2, a classical i64 (rule 21)
  %7 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %7, double %1)    ; IR: %5 = cq_theta_f64(%0, %1)  [Ry]
  %8 = call i32 @cqrt_qram_load_f64_hl(i32 %5, i64 %6)    ; IR: %6 = load double, ptr %2  [a bus load: a rail (rule 3); s before trip 1]
  %9 = icmp sgt i32 %3, 1    ; IR: %7 = icmp sgt i32 %3, 1
  br i1 %9, label %12, label %10    ; IR: br i1 %7, label %8, label %10

10:
  %11 = call double @cqrt_measure_f64(i32 %8)    ; IR: %12 = cq_measure_f64(%11), %11 = %6 from %4  [the load copy is measured: never un-copied (rule 2)]
  ret double %11    ; IR: ret double %12

12:
  %13 = zext nneg i32 %3 to i64    ; IR: %9 = zext nneg i32 %3 to i64
  br label %14

14:
  %15 = phi i64 [ 1, %12 ], [ %22, %14 ]    ; IR: %14 = phi i64 [ 1, %8 ], [ %19, %13 ]  (classical)
  %16 = phi i32 [ %8, %12 ], [ %21, %14 ]    ; IR: %15 = phi double [ %6, %8 ], [ %18, %13 ]
  %17 = getelementptr double, ptr %2, i64 %15    ; IR: %16 = getelementptr inbounds double, ptr %2, i64 %14  [classical index: classical address]
  %18 = ptrtoint ptr %17 to i64    ; IR: %16 as its run-time address, the _hl operand
  %19 = call i32 @cqrt_qram_load_f64_hl(i32 %5, i64 %18)    ; IR: %17 = load double, ptr %16  [a bus load: a rail (rule 3)]
  %20 = call i32 @cq_template_fmul_f64(i32 %16, i32 %7)    ; IR: %18 = llvm.fmuladd.f64(%15, %5, %17)  [product s * x]
  %21 = call i32 @cq_template_fadd_f64(i32 %20, i32 %19)    ; IR: %18 = llvm.fmuladd.f64(%15, %5, %17)  [sum + coef[i]]
  call void @cqrt_push(i32 %16)    ; IR: %15 [old accumulator, kept for the mirror]
  call void @cqrt_push(i32 %20)    ; IR: %18 [product rail, kept for the mirror]
  call void @cqrt_push(i32 %19)    ; IR: %17 [load copy, un-copied by the mirror]
  %22 = add nuw nsw i64 %15, 1    ; IR: %19 = add nuw nsw i64 %14, 1
  %23 = icmp eq i64 %22, %13    ; IR: %20 = icmp eq i64 %19, %9
  br i1 %23, label %24, label %14    ; IR: br i1 %20, label %10, label %13

24:
  %25 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: %11 = phi double [ %18, %13 ]  [copied-out result]
  call void @cqrt_copy_f64(i32 %21, i32 %25)    ; IR: %11
  br label %26

26:
  %27 = phi i64 [ %15, %24 ], [ %34, %26 ]    ; IR: trip being undone, from the last down to 1
  %28 = phi i32 [ %21, %24 ], [ %33, %26 ]
  %29 = getelementptr double, ptr %2, i64 %27    ; IR: %16 of that trip, recomputed from the trip index
  %30 = ptrtoint ptr %29 to i64    ; IR: its run-time address
  %31 = call i32 @cqrt_pop()    ; IR: that trip's load copy %17
  %32 = call i32 @cqrt_pop()    ; IR: that trip's product rail
  %33 = call i32 @cqrt_pop()    ; IR: that trip's %15
  call void @cq_template_fadd_f64_unc(i32 %28, i32 %32, i32 %31)    ; IR: uncompute %18 [sum]
  call void @cqrt_free(i32 %28)    ; IR: release the %18 rail (|0>)
  call void @cqrt_qram_load_f64_hl_unc(i32 %31, i32 %5, i64 %30)    ; IR: un-copy %17: the sum's _unc was its last reader, no memory version change since (rule 5 sentence 1)
  call void @cqrt_free(i32 %31)    ; IR: release the %17 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %32, i32 %33, i32 %7)    ; IR: uncompute %18 [product]
  call void @cqrt_free(i32 %32)    ; IR: release the product rail (|0>)
  %34 = add i64 %27, -1
  %35 = icmp sgt i64 %34, 0
  br i1 %35, label %26, label %36

36:
  call void @cqrt_qram_load_f64_hl_unc(i32 %33, i32 %5, i64 %6)    ; IR: un-copy %6 (the first s rail): trip 1's fmul _unc was its last reader (rule 5 sentence 1)
  call void @cqrt_free(i32 %33)    ; IR: release the %6 rail (|0>)
  %37 = call double @cqrt_measure_f64(i32 %25)    ; IR: %12 = cq_measure_f64(%11)
  ret double %37    ; IR: ret double %12
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cqrt_qram_load_f64_hl(i32, i64)
declare void @cqrt_qram_load_f64_hl_unc(i32, i32, i64)
declare i32 @cq_template_fmul_f64(i32, i32)
declare void @cq_template_fmul_f64_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
declare void @cqrt_copy_f64(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
