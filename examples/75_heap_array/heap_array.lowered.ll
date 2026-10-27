; HAND-WRITTEN. Rules: 20, 16, 14, 4, 5, 2.
; Checked: r = a[k] + a[n - 1] over the heap array a[i] = x + i (measured).
; Clean: every cell rail x + i (uncomputed by the reverse loop that reads the handles back from the block, before
; free(a)).
; Kept: the user register x; the result rail (measured).
; Rotations: Ry(th) on x.
; A heap array accessed only at classical indices is a slot array (rule 20): a heap block of i32 HANDLE slots. malloc
; and free stay the classical calls clang wrote (rule 16: an allocation with a classical size whose block never
; becomes a QRAM is classical), and each cell stores the handle of its rail. Here the element type is i32, so a handle
; slot and an element have the same size and the allocation size and every GEP stand as written. For any other element
; type the block holds one i32 handle per element: the size n * sizeof(T) becomes n * 4 and every GEP stride and byte
; offset is rescaled from sizeof(T) to 4. The cells are uncomputed by a reverse loop that reads their handles back from
; the block, and it runs before free(a), while the block still holds them; only the result r is left for the
; measurement. Reading a[k] with k outside [0, n) is the program's own undefined behaviour and is emitted as written.
source_filename = "heap_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @heap_array(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = sext i32 %2 to i64    ; IR: %6 = sext i32 %2 to i64  (classical)
  %7 = shl nsw i64 %6, 2    ; IR: %7 = shl nsw i64 %6, 2  (classical: n i32 handles, the same size as n ints)
  %8 = call ptr @malloc(i64 %7)    ; IR: %8 = call @malloc(%7)  (classical heap block of handle slots)
  %9 = icmp sgt i32 %2, 0    ; IR: %9 = icmp sgt i32 %2, 0  (classical)
  br i1 %9, label %10, label %19    ; IR: br i1 %9, label %10, label %12

10:
  %11 = zext nneg i32 %2 to i64    ; IR: %11 = zext nneg i32 %2 to i64  (classical)
  br label %12    ; IR: br label %21

12:
  %13 = phi i64 [ 0, %10 ], [ %17, %12 ]    ; IR: %22 = phi i64 [ 0, %10 ], [ %26, %21 ]  (classical i)
  %14 = trunc nuw nsw i64 %13 to i32    ; IR: %23 = trunc nuw nsw i64 %22 to i32  (classical)
  %15 = call i32 @cq_template_add_i32_hl(i32 %5, i32 %14)    ; IR: %24 = add i32 %5, %23  [a[i]'s rail]
  %16 = getelementptr inbounds i32, ptr %8, i64 %13    ; IR: %25 = getelementptr i32, ptr %8, %22
  store i32 %15, ptr %16, align 4    ; IR: store i32 %24, ptr %25  (the heap cell takes the handle)
  %17 = add nuw nsw i64 %13, 1    ; IR: %26 = add nuw nsw i64 %22, 1  (classical)
  %18 = icmp eq i64 %17, %11    ; IR: %27 = icmp eq i64 %26, %11  (classical bound)
  br i1 %18, label %19, label %12    ; IR: br i1 %27, label %12, label %21

19:
  %20 = sext i32 %3 to i64    ; IR: %13 = sext i32 %3 to i64  (classical)
  %21 = getelementptr inbounds i32, ptr %8, i64 %20    ; IR: %14 = getelementptr i32, ptr %8, %13
  %22 = load i32, ptr %21, align 4    ; IR: %15 = load i32, ptr %14  (the handle of a[k])
  %23 = getelementptr i32, ptr %8, i64 %6    ; IR: %16 = getelementptr i32, ptr %8, %6
  %24 = getelementptr i8, ptr %23, i64 -4    ; IR: %17 = getelementptr i8, ptr %16, -4  (one handle slot back)
  %25 = load i32, ptr %24, align 4    ; IR: %18 = load i32, ptr %17  (the handle of a[n - 1])
  %26 = call i32 @cq_template_add_i32(i32 %25, i32 %22)    ; IR: %19 = add nsw i32 %18, %15  [result rail]
  br i1 %9, label %27, label %34    ; IR: uncompute the cells written by the fill loop (none when n <= 0)

27:
  %28 = phi i64 [ %6, %19 ], [ %29, %27 ]    ; IR: reverse of the fill loop: i from n - 1 down to 0
  %29 = add nsw i64 %28, -1    ; IR: this trip's i
  %30 = getelementptr inbounds i32, ptr %8, i64 %29    ; IR: a[i]'s heap slot
  %31 = load i32, ptr %30, align 4    ; IR: the handle of %24 for this i (read back from the heap block)
  %32 = trunc nuw nsw i64 %29 to i32    ; IR: %23 of that trip (classical)
  call void @cq_template_add_i32_hl_unc(i32 %31, i32 %5, i32 %32)    ; IR: uncompute %24
  call void @cqrt_free(i32 %31)    ; IR: release the %24 rail (|0>)
  %33 = icmp sgt i64 %29, 0
  br i1 %33, label %27, label %34

34:
  call void @free(ptr %8)    ; IR: call @free(%8)  (classical, after the cells' rails are released)
  %35 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: %20 = cq_measure_si32(%19)
  ret i32 %35    ; IR: ret i32 %20
}

declare ptr @malloc(i64)
declare void @free(ptr)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
