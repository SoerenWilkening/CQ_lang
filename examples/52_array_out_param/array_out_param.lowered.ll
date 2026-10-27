; HAND-WRITTEN. Rules: 18, 20, 14, 7, 5, §1.4.
; Checked: r (the classical phi of handles %28: the case-0 copy %17, the case-1 copy %21 or the default fsub %26;
; measured as %32).
; Clean: y[0] and y[1] (the clone's out rails %29/%31, zeroed by the _unc twin and freed), tx[1] (%9) and tx[2] (%11),
; and every clone-internal rail (the trip accumulator and product rails popped by the mirror loop and the 0.0 seed).
; Kept: x (%8, the rotated register, also tx[0] by handle) and the result rail r (measured).
; Rotations: (Ry_f64, x, th, 1).
; A local array that receives quantum values is an array of classical SLOTS holding handles (example 30 holds classical
; cells, example 31 one slot); it is passed to the callee by the slot array's pointer in BOTH directions: the clone loads
; input handles with the classical loop index and stores output handles into the out array. tx[0] = x stores the user
; register's own handle (no copy). The clone's return value is classical (n + 1), so the caller's switch stays a
; classical switch whose arms load handles; each arm produces a fresh result rail (a CNOT copy or an fsub) so that the
; clone's _unc twin can zero both out rails before the measurement, whichever arm ran. The twin takes (args, old slot
; handles in slot order): it recomputes, XORs both out rails back to |0> and restores the slots' content from before the
; call (y was never written: poison); the caller loads both out handles before the twin and frees them after it. The
; clone follows example 36 (classical-bound loop, handle stack, copy-out, mirror); its exit-0 path (n <= 0) hands out
; the classical-valued 0.0 rail itself, which is already |0>. The loop's s + in[i] * c is contracted to
; llvm.fmuladd.f64, which is UNFUSED (§2, cf. 14): fmul_f64_hl of in[i] and c into a fresh product rail, then fadd_f64
; of the product and s into a fresh accumulator rail; each trip pushes the old accumulator and the product, and the
; mirror uncomputes the sum before the product it read (rule 5).
source_filename = "array_out_param.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @array_out_param(double noundef %0, double noundef %1, double noundef %2, double noundef %3, i32 noundef %4) {
  %6 = alloca [3 x i32], align 16    ; IR: %6 = alloca [3 x double]  (slot array: three handles)
  %7 = alloca [2 x i32], align 16    ; IR: %7 = alloca [2 x double]  (slot array: two handles)
  %8 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %8 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %8, double %1)    ; IR: %8 = cq_theta_f64(%0, %1)  [Ry]
  store i32 %8, ptr %6, align 16    ; IR: store double %8, ptr %6  (tx[0] holds the register's handle)
  %9 = call i32 @cq_template_fmul_f64_hl(i32 %8, double %2)    ; IR: %9 = fmul double %8, %2
  %10 = getelementptr inbounds i8, ptr %6, i64 4    ; IR: %10 = getelementptr %6, 8  (slot 1)
  store i32 %9, ptr %10, align 4    ; IR: store double %9, ptr %10
  %11 = call i32 @cq_template_fadd_f64_hl(i32 %8, double %2)    ; IR: %11 = fadd double %8, %2
  %12 = getelementptr inbounds i8, ptr %6, i64 8    ; IR: %12 = getelementptr %6, 16  (slot 2)
  store i32 %11, ptr %12, align 8    ; IR: store double %11, ptr %12
  %13 = call fastcc i32 @__cq_q_reduce_10000(ptr %6, i32 %4, double %3, ptr %7)    ; IR: %13 = call @reduce(%6, %4, %3, %7), clone for mask (quantum array, classical, classical, out array); classical result
  %14 = and i32 %13, 3    ; IR: %14 = and i32 %13, 3  (classical)
  switch i32 %14, label %22 [    ; IR: switch i32 %14  (classical)
    i32 0, label %15
    i32 1, label %18
  ]

15:
  %16 = load i32, ptr %7, align 16    ; IR: %16 = load double, ptr %7  (handle of y[0])
  %17 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: %26 = phi: [ %16, %15 ]  [fresh result rail for case 0]
  call void @cqrt_copy_f64(i32 %16, i32 %17)    ; IR: r = y[0]
  br label %27

18:
  %19 = getelementptr inbounds i8, ptr %7, i64 4    ; IR: %18 = getelementptr %7, 8  (slot 1)
  %20 = load i32, ptr %19, align 4    ; IR: %19 = load double, ptr %18  (handle of y[1])
  %21 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: %26 = phi: [ %19, %17 ]  [fresh result rail for case 1]
  call void @cqrt_copy_f64(i32 %20, i32 %21)    ; IR: r = y[1]
  br label %27

22:
  %23 = load i32, ptr %7, align 16    ; IR: %21 = load double, ptr %7
  %24 = getelementptr inbounds i8, ptr %7, i64 4    ; IR: %22 = getelementptr %7, 8
  %25 = load i32, ptr %24, align 4    ; IR: %23 = load double, ptr %22
  %26 = call i32 @cq_template_fsub_f64(i32 %23, i32 %25)    ; IR: %24 = fsub double %21, %23  [result rail for default]
  br label %27

27:
  %28 = phi i32 [ %17, %15 ], [ %21, %18 ], [ %26, %22 ]    ; IR: %26 = phi double  (classical phi of handles)
  %29 = load i32, ptr %7, align 16    ; IR: handle of y[0] (the clone's out rail), kept before the twin restores the slot
  %30 = getelementptr inbounds i8, ptr %7, i64 4
  %31 = load i32, ptr %30, align 4    ; IR: handle of y[1], kept likewise
  call fastcc void @__cq_q_reduce_10000_unc(ptr %6, i32 %4, double %3, ptr %7, i32 poison, i32 poison)    ; IR: uncompute the clone's two out rails (y[0], y[1] back to |0>); the last two arguments are the slots' content before the call (y was never written: poison), restored by the twin
  call void @cqrt_free(i32 %29)    ; IR: release y[0] (|0>)
  call void @cqrt_free(i32 %31)    ; IR: release y[1] (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %11, i32 %8, double %2)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release tx[2] (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %9, i32 %8, double %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release tx[1] (|0>)
  %32 = call double @cqrt_measure_f64(i32 %28)    ; IR: %27 = cq_measure_f64(%26)
  ret double %32    ; IR: ret double %27
}

define internal fastcc i32 @__cq_q_reduce_10000(ptr %0, i32 %1, double %2, ptr %3) {
  %5 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: incoming 0.0 of phi %9 / %16  [s before trip 0, a classical-valued rail]
  %6 = icmp sgt i32 %1, 0    ; IR: %5 = icmp sgt i32 %1, 0  (classical)
  br i1 %6, label %12, label %7    ; IR: br i1 %5, label %6, label %8

7:
  store i32 %5, ptr %3, align 4    ; IR: store double %9, ptr %3 with %9 = 0.0: out[0] is the 0.0 rail itself
  %8 = load i32, ptr %0, align 4    ; IR: %10 = load double, ptr %0  (handle of in[0])
  %9 = call i32 @cq_template_fsub_f64(i32 %5, i32 %8)    ; IR: %11 = fsub double %9, %10  [out[1] rail]
  %10 = getelementptr inbounds i8, ptr %3, i64 4    ; IR: %12 = getelementptr %3, 8  (slot 1)
  store i32 %9, ptr %10, align 4    ; IR: store double %11, ptr %12
  %11 = add nsw i32 %1, 1    ; IR: %13 = add nsw i32 %1, 1  (classical)
  ret i32 %11    ; IR: ret i32 %13

12:
  %13 = zext nneg i32 %1 to i64    ; IR: %7 = zext nneg i32 %1 to i64
  br label %14

14:
  %15 = phi i64 [ 0, %12 ], [ %21, %14 ]    ; IR: %15 = phi i64 [ 0, %6 ], [ %20, %14 ]  (classical)
  %16 = phi i32 [ %5, %12 ], [ %20, %14 ]    ; IR: %16 = phi double [ 0.0, %6 ], [ %19, %14 ]
  %17 = getelementptr inbounds i32, ptr %0, i64 %15    ; IR: %17 = getelementptr inbounds double, ptr %0, i64 %15  (slot i)
  %18 = load i32, ptr %17, align 4    ; IR: %18 = load double, ptr %17  (handle of in[i])
  %19 = call i32 @cq_template_fmul_f64_hl(i32 %18, double %2)    ; IR: %19 = fmuladd(%18, %2, %16)  [product in[i] * c]
  %20 = call i32 @cq_template_fadd_f64(i32 %19, i32 %16)    ; IR: %19 = fmuladd(%18, %2, %16)  [sum + s]
  call void @cqrt_push(i32 %16)    ; IR: %16 [old accumulator, kept for the mirror]
  call void @cqrt_push(i32 %19)    ; IR: %19 [product rail, kept for the mirror]
  %21 = add nuw nsw i64 %15, 1    ; IR: %20 = add nuw nsw i64 %15, 1
  %22 = icmp eq i64 %21, %13    ; IR: %21 = icmp eq i64 %20, %7
  br i1 %22, label %23, label %14    ; IR: br i1 %21, label %8, label %14

23:
  %24 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: store double %9, ptr %3 with %9 = %19  [out[0] rail]
  call void @cqrt_copy_f64(i32 %20, i32 %24)    ; IR: copy s out
  store i32 %24, ptr %3, align 4    ; IR: store double %9, ptr %3
  %25 = load i32, ptr %0, align 4    ; IR: %10 = load double, ptr %0  (handle of in[0])
  %26 = call i32 @cq_template_fsub_f64(i32 %20, i32 %25)    ; IR: %11 = fsub double %9, %10  [out[1] rail]
  %27 = getelementptr inbounds i8, ptr %3, i64 4    ; IR: %12 = getelementptr %3, 8  (slot 1)
  store i32 %26, ptr %27, align 4    ; IR: store double %11, ptr %12
  br label %28

28:
  %29 = phi i64 [ %15, %23 ], [ %35, %28 ]    ; IR: trip being undone, from the last down to 0
  %30 = phi i32 [ %20, %23 ], [ %34, %28 ]    ; IR: %19 of that trip
  %31 = getelementptr inbounds i32, ptr %0, i64 %29    ; IR: slot j
  %32 = load i32, ptr %31, align 4    ; IR: %18 of that trip
  %33 = call i32 @cqrt_pop()    ; IR: that trip's product rail
  %34 = call i32 @cqrt_pop()    ; IR: that trip's %16
  call void @cq_template_fadd_f64_unc(i32 %30, i32 %33, i32 %34)    ; IR: uncompute %19 [sum]
  call void @cqrt_free(i32 %30)    ; IR: release the %19 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %33, i32 %32, double %2)    ; IR: uncompute %19 [product]
  call void @cqrt_free(i32 %33)    ; IR: release the product rail (|0>)
  %35 = add nsw i64 %29, -1
  %36 = icmp sgt i64 %35, -1
  br i1 %36, label %28, label %37

37:
  call void @cqrt_free(i32 %34)    ; IR: release the s rail before trip 0 (never written, holds 0.0)
  %38 = add nsw i32 %1, 1    ; IR: %13 = add nsw i32 %1, 1  (classical)
  ret i32 %38    ; IR: ret i32 %13
}

define internal fastcc void @__cq_q_reduce_10000_unc(ptr %0, i32 %1, double %2, ptr %3, i32 %4, i32 %5) {
  %7 = load i32, ptr %3, align 4    ; IR: handle of out[0] (the clone's rail)
  %8 = getelementptr inbounds i8, ptr %3, i64 4
  %9 = load i32, ptr %8, align 4    ; IR: handle of out[1]
  %10 = load i32, ptr %0, align 4    ; IR: handle of in[0]
  %11 = icmp sgt i32 %1, 0    ; IR: %5  (classical)
  br i1 %11, label %13, label %12
12:
  call void @cq_template_fsub_f64_unc(i32 %9, i32 %7, i32 %10)    ; IR: uncompute %11 (out[0] is the 0.0 rail)
  br label %36    ; IR: out[0] held 0.0 = |0> already
13:
  %14 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: recompute: s before trip 0
  %15 = zext nneg i32 %1 to i64
  br label %16
16:
  %17 = phi i64 [ 0, %13 ], [ %23, %16 ]
  %18 = phi i32 [ %14, %13 ], [ %22, %16 ]
  %19 = getelementptr inbounds i32, ptr %0, i64 %17
  %20 = load i32, ptr %19, align 4
  %21 = call i32 @cq_template_fmul_f64_hl(i32 %20, double %2)    ; IR: recompute %19 [product]
  %22 = call i32 @cq_template_fadd_f64(i32 %21, i32 %18)    ; IR: recompute %19 [sum]
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %21)
  %23 = add nuw nsw i64 %17, 1
  %24 = icmp eq i64 %23, %15
  br i1 %24, label %25, label %16
25:
  call void @cqrt_copy_f64(i32 %22, i32 %7)    ; IR: xor s back out of out[0]
  call void @cq_template_fsub_f64_unc(i32 %9, i32 %22, i32 %10)    ; IR: uncompute %11
  br label %26
26:
  %27 = phi i64 [ %17, %25 ], [ %33, %26 ]
  %28 = phi i32 [ %22, %25 ], [ %32, %26 ]
  %29 = getelementptr inbounds i32, ptr %0, i64 %27
  %30 = load i32, ptr %29, align 4
  %31 = call i32 @cqrt_pop()
  %32 = call i32 @cqrt_pop()
  call void @cq_template_fadd_f64_unc(i32 %28, i32 %31, i32 %32)    ; IR: uncompute %19 [sum]
  call void @cqrt_free(i32 %28)
  call void @cq_template_fmul_f64_hl_unc(i32 %31, i32 %30, double %2)    ; IR: uncompute %19 [product]
  call void @cqrt_free(i32 %31)
  %33 = add nsw i64 %27, -1
  %34 = icmp sgt i64 %33, -1
  br i1 %34, label %26, label %35
35:
  call void @cqrt_free(i32 %32)    ; IR: release the recomputed s rail before trip 0
  br label %36
36:
  store i32 %4, ptr %3, align 4    ; IR: restore out[0]'s content from before the call (§1.4: old slot handles last)
  store i32 %5, ptr %8, align 4    ; IR: restore out[1]'s content
  ret void
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare void @cqrt_copy_f64(i32, i32)
declare double @cqrt_measure_f64(i32)
declare void @cqrt_free(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fsub_f64(i32, i32)
declare void @cq_template_fsub_f64_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
