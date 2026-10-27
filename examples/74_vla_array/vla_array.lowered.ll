; HAND-WRITTEN. Rules: 2, 4, 5, 20 (QROM at a quantum index over runtime-length classical memory).
; Checked: a[x % n] (the QROM read %20 -> %21).
; Clean: the index rail x % n (%19), uncomputed and freed after the QROM read.
; Kept: x (%5, the rotated register) and the read value (%20, measured).
; Rotations: (Ry, x, th, 1).
; A variable-length array holding classical values is classical memory of runtime length: the alloca, its classical fill
; loop and every classical value stay exactly as clang wrote them. The quantum-index read is the QROM of 29 and 30 with the
; runtime element count %6 as its length operand and the logical index rail x % n (i32) as its index; -O1's zext to i64
; and the gep scaling are address arithmetic and are not emitted (rule 20). The index is x % n, which lies in [0, n) for
; n > 0, so the QROM never reads past the array. n == 0 needs no guard: the urem template is total (§2: urem(x, 0) = x)
; and the QROM reads 0 at an index >= its length 0 (§2: out-of-range qrom_load), so the same calls cover it. At -O1 a
; VLA at function scope needs no llvm.stacksave/stackrestore (none is emitted here); inside a loop or a block they appear
; and stay classical calls around the classical alloca. The read value is the measured result, so only the index chain
; is uncomputed.
source_filename = "vla_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @vla_array(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = zext i32 %2 to i64    ; IR: %6 = zext i32 %2 to i64  (classical element count)
  %7 = alloca i32, i64 %6, align 16    ; IR: %7 = alloca i32, i64 %6  (classical memory of runtime length)
  %8 = icmp sgt i32 %2, 0    ; IR: %8 = icmp sgt i32 %2, 0  (classical)
  br i1 %8, label %9, label %18    ; IR: br i1 %8, label %9, label %11

9:
  %10 = zext nneg i32 %2 to i64    ; IR: %10 = zext nneg i32 %2 to i64  (classical)
  br label %11    ; IR: br label %17

11:
  %12 = phi i64 [ 0, %9 ], [ %16, %11 ]    ; IR: %18 = phi i64 [ 0, %9 ], [ %22, %17 ]  (classical i)
  %13 = getelementptr inbounds i32, ptr %7, i64 %12    ; IR: %19 = getelementptr i32, ptr %7, %18
  %14 = trunc i64 %12 to i32    ; IR: %20 = trunc i64 %18 to i32  (classical)
  %15 = mul i32 %14, %3    ; IR: %21 = mul i32 %20, %3  (classical)
  store i32 %15, ptr %13, align 4    ; IR: store i32 %21, ptr %19  (classical)
  %16 = add nuw nsw i64 %12, 1    ; IR: %22 = add nuw nsw i64 %18, 1  (classical)
  %17 = icmp eq i64 %16, %10    ; IR: %23 = icmp eq i64 %22, %10  (classical bound)
  br i1 %17, label %18, label %11    ; IR: br i1 %23, label %11, label %17

18:
  %19 = call i32 @cq_template_urem_i32_hl(i32 %5, i32 %2)    ; IR: %12 = urem i32 %5, %2
  %20 = call i32 @cq_template_qrom_load_i32(ptr %7, i64 %6, i32 %19)    ; IR: %13 = zext %12; %14 = getelementptr i32, ptr %7, %13; %15 = load i32, ptr %14  [QROM, runtime length %6, index = the logical-i32 rail]
  call void @cq_template_urem_i32_hl_unc(i32 %19, i32 %5, i32 %2)    ; IR: uncompute %12
  call void @cqrt_free(i32 %19)    ; IR: release the %12 rail (|0>)
  %21 = call i32 @cqrt_measure_i32(i32 %20)    ; IR: %16 = cq_measure_si32(%15)
  ret i32 %21    ; IR: ret i32 %16
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_urem_i32_hl(i32, i32)
declare void @cq_template_urem_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
