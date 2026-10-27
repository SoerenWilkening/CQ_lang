; HAND-WRITTEN. Rules: 22, 20, 14, 4, 5, 7, 2.
; Checked: memcpy_classical: a[0] + a[3] after a[x & 3] += 1 over the memcpy'd src; memcpy_quantum: a[1] + b[1] with
; b a copy of a = {x + i} and b[y & 3] = c (measured).
; Clean: memcpy_classical: the four basis-state source handles (rule 7), the index rail x & 3, the read-modify-write
; load and its increment, both fixed-index copy-outs, and the QRAM a; memcpy_quantum: the four fill rails x + i (the
; cells of the slot array a, uncomputed by the reverse fill loop once no store on b reads them), the index rail y & 3,
; the basis-state handle c, the copy-out b[1], and the QRAM b (every store popped, then cqrt_qram_free).
; Kept: the user registers (x; x and y); the result rail (measured).
; Rotations: Ry(th) on x (memcpy_classical); Ry(tx) on x and Ry(ty) on y (memcpy_quantum).
; Rule 20 classifies each object by its accesses' offsets. An object with a quantum-offset store (or a quantum-offset
; load while it may hold a handle) is a QRAM for its whole lifetime (ABI = the QRAM contract of §1.3): cqrt_qram_alloc_<W>(n)
; at the alloca (cells |0>), every access ONE call, the classical-offset accesses in their _hl form (_hl = classical
; INDEX). An object with only classical offsets that may hold a handle is a SLOT ARRAY: a classical array of handles,
; loads and stores move handles and emit no gate. llvm.memcpy with a classical length works per cell (rule 22).
; memcpy_classical: a[x & 3] += 1 is a quantum-offset read-modify-write, so a is a QRAM from its alloca, and the memcpy
; from the classical source is, per cell, a classical load of src[j] materialised as a basis-state handle by
; cqrt_alloc_<W> (a QRAM store value is ALWAYS a handle) and one store_hl; the read is one cqrt_qram_load_<W>(arr, idx)
; -> fresh rail (cell preserved) with the logical-i32 index rail (x & 3; -O1's zext to i64 and the gep scaling are not
; emitted), the write-back one cqrt_qram_store_<W>(arr, idx, val) of the incremented rail; a[0], a[3] are fixed-index
; copy-outs cqrt_qram_load_<W>_hl. memcpy_quantum: a is only accessed at classical offsets (the fill a[i], the memcpy
; source cells, a[1]), so a is a slot array (alloca [4 x i32] of handles): the fill loop stores the rail x + i into slot
; i. b is written at the quantum index y & 3, so b is a QRAM, and memcpy(b, a) is a QRAM memcpy: per cell one slot load
; of a[j] (a handle, no gate) and one cqrt_qram_store_<W>_hl(b, j, handle); the quantum-index write b[y & 3] = c is one
; cqrt_qram_store_<W> of c as a handle; a[1] is a slot load (the rail x + 1 itself), b[1] a fixed-index copy-out. The
; backend keeps each displaced cell on its own tape; the stores are popped LIFO per array by their _unc (same args),
; copy-outs are un-copied, the fill rails are uncomputed by the reverse fill loop (reading each handle back from its
; slot) after b's stores that read them are popped, then cqrt_qram_free releases each all-|0> QRAM.
source_filename = "memcpy_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @memcpy_classical(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) {
  %4 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %4 = alloca [4 x i32]: a 4-cell QRAM, cells |0> (the array is read-modify-written at a quantum index: a quantum-offset store)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = load i32, ptr %2, align 4    ; IR: call @llvm.memcpy(%4, %2, 16): src[0]  (classical load from the classical source)
  %7 = call i32 @cqrt_alloc_i32(i32 %6)    ; IR: memcpy: the classical src[0] as a basis-state handle
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 0, i32 %7)    ; IR: memcpy: a[0] = src[0]  (fixed-index store)
  %8 = getelementptr inbounds i8, ptr %2, i64 4    ; IR: memcpy: &src[1]  (classical)
  %9 = load i32, ptr %8, align 4    ; IR: memcpy: src[1]  (classical)
  %10 = call i32 @cqrt_alloc_i32(i32 %9)    ; IR: memcpy: src[1] as a basis-state handle
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 1, i32 %10)    ; IR: memcpy: a[1] = src[1]
  %11 = getelementptr inbounds i8, ptr %2, i64 8    ; IR: memcpy: &src[2]  (classical)
  %12 = load i32, ptr %11, align 4    ; IR: memcpy: src[2]  (classical)
  %13 = call i32 @cqrt_alloc_i32(i32 %12)    ; IR: memcpy: src[2] as a basis-state handle
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 2, i32 %13)    ; IR: memcpy: a[2] = src[2]
  %14 = getelementptr inbounds i8, ptr %2, i64 12    ; IR: memcpy: &src[3]  (classical)
  %15 = load i32, ptr %14, align 4    ; IR: memcpy: src[3]  (classical)
  %16 = call i32 @cqrt_alloc_i32(i32 %15)    ; IR: memcpy: src[3] as a basis-state handle
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 3, i32 %16)    ; IR: memcpy: a[3] = src[3]
  %17 = call i32 @cq_template_and_i32_hl(i32 %5, i32 3)    ; IR: %6 = and i32 %5, 3  [the index rail; the %7 zext and the %8 gep are not emitted]
  %18 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %17)    ; IR: %9 = load i32, ptr %8: a[x & 3]  (one access: copy-out at the quantum index, cell preserved)
  %19 = call i32 @cq_template_add_i32_hl(i32 %18, i32 1)    ; IR: %10 = add nsw i32 %9, 1
  call void @cqrt_qram_store_i32(i32 %4, i32 %17, i32 %19)    ; IR: store i32 %10, ptr %8: a[x & 3] = a[x & 3] + 1  (one access; the displaced cell goes onto the backend's tape)
  %20 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i32 0)    ; IR: %11 = load i32, ptr %4: a[0]  (fixed-index copy-out)
  %21 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i32 3)    ; IR: %13 = load i32, ptr %12: a[3]  (the %12 gep is not emitted)
  %22 = call i32 @cq_template_add_i32(i32 %21, i32 %20)    ; IR: %14 = add nsw i32 %13, %11  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %21, i32 %4, i32 3)    ; IR: uncompute %13 (un-copy)
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %20, i32 %4, i32 0)    ; IR: uncompute %11 (un-copy)
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_unc(i32 %4, i32 %17, i32 %19)    ; IR: pop the quantum-index store: a[x & 3] holds src[x & 3] again
  call void @cq_template_add_i32_hl_unc(i32 %19, i32 %18, i32 1)    ; IR: uncompute %10
  call void @cqrt_free(i32 %19)    ; IR: release the %10 rail (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %18, i32 %4, i32 %17)    ; IR: uncompute %9: the cell holds the value it had at the copy-out, so it un-copies
  call void @cqrt_free(i32 %18)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %17, i32 %5, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %17)    ; IR: release the %6 rail (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 3, i32 %16)    ; IR: pop the memcpy stores LIFO: a[3] back to |0>
  call void @cqrt_free(i32 %16)    ; IR: release the basis-state handle src[3]
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 2, i32 %13)    ; IR: a[2]
  call void @cqrt_free(i32 %13)    ; IR: release the basis-state handle src[2]
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 1, i32 %10)    ; IR: a[1]
  call void @cqrt_free(i32 %10)    ; IR: release the basis-state handle src[1]
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 0, i32 %7)    ; IR: a[0]
  call void @cqrt_free(i32 %7)    ; IR: release the basis-state handle src[0]
  call void @cqrt_qram_free(i32 %4)    ; IR: llvm.lifetime.end: release the array (every store popped, all cells |0>)
  %23 = call i32 @cqrt_measure_i32(i32 %22)    ; IR: %15 = cq_measure_si32(%14)
  ret i32 %23    ; IR: ret i32 %15
}

define i32 @memcpy_quantum(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4) {
  %6 = alloca [4 x i32], align 4    ; IR: %6 = alloca [4 x i32]: a, a SLOT ARRAY (every access has a classical offset; its cells hold handles)
  %7 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %7 = alloca [4 x i32]: b, a 4-cell QRAM, cells |0> (b is written at a quantum index)
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_ui32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %2)    ; IR: %8 = cq_theta_ui32(%0, %2)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %9 = cq_theta_ui32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %9, double %3)    ; IR: %9 = cq_theta_ui32(%1, %3)  [Ry]
  br label %10    ; IR: br label %20

10:
  %11 = phi i64 [ 0, %5 ], [ %15, %10 ]    ; IR: %21 = phi i64 [ 0, %5 ], [ %25, %20 ]  (classical i)
  %12 = trunc nuw nsw i64 %11 to i32    ; IR: %22 = trunc nuw nsw i64 %21 to i32  (classical)
  %13 = call i32 @cq_template_add_i32_hl(i32 %8, i32 %12)    ; IR: %23 = add i32 %8, %22  [a[i]'s value rail]
  %14 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %11    ; IR: %24  (slot of a[i])
  store i32 %13, ptr %14, align 4    ; IR: store i32 %23, ptr %24: a[i] = x + i  (the slot takes the handle; no gate)
  %15 = add nuw nsw i64 %11, 1    ; IR: %25 = add nuw nsw i64 %21, 1  (classical)
  %16 = icmp eq i64 %15, 4    ; IR: %26 = icmp eq i64 %25, 4  (classical bound)
  br i1 %16, label %17, label %10    ; IR: br i1 %26, label %10, label %20

17:
  %18 = load i32, ptr %6, align 4    ; IR: call @llvm.memcpy(%7, %6, 16): a[0]  (the handle in slot 0, no gate)
  call void @cqrt_qram_store_i32_hl(i32 %7, i32 0, i32 %18)    ; IR: memcpy: b[0] = a[0]  (fixed-index store of a's cell rail)
  %19 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 1
  %20 = load i32, ptr %19, align 4    ; IR: memcpy: a[1]  (slot load)
  call void @cqrt_qram_store_i32_hl(i32 %7, i32 1, i32 %20)    ; IR: memcpy: b[1] = a[1]
  %21 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 2
  %22 = load i32, ptr %21, align 4    ; IR: memcpy: a[2]  (slot load)
  call void @cqrt_qram_store_i32_hl(i32 %7, i32 2, i32 %22)    ; IR: memcpy: b[2] = a[2]
  %23 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 3
  %24 = load i32, ptr %23, align 4    ; IR: memcpy: a[3]  (slot load)
  call void @cqrt_qram_store_i32_hl(i32 %7, i32 3, i32 %24)    ; IR: memcpy: b[3] = a[3]
  %25 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)    ; IR: %11 = and i32 %9, 3  [the index rail; the %12 zext and the %13 gep are not emitted]
  %26 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: store i32 %4, ptr %13: the classical value c as a basis-state handle
  call void @cqrt_qram_store_i32(i32 %7, i32 %25, i32 %26)    ; IR: store i32 %4, ptr %13: b[y & 3] = c  (one access; the backend fans out over the cells)
  %27 = load i32, ptr %19, align 4    ; IR: %15 = load i32, ptr %14: a[1]  (the handle in slot 1, no gate; the %14 gep is cell 1)
  %28 = call i32 @cqrt_qram_load_i32_hl(i32 %7, i32 1)    ; IR: %17 = load i32, ptr %16: b[1]  (fixed-index copy-out; the %16 gep is not emitted)
  %29 = call i32 @cq_template_add_i32(i32 %28, i32 %27)    ; IR: %18 = add nsw i32 %17, %15  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %28, i32 %7, i32 1)    ; IR: uncompute %17 (un-copy)
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_unc(i32 %7, i32 %25, i32 %26)    ; IR: pop the quantum-index store: every b cell holds its copy again
  call void @cqrt_free(i32 %26)    ; IR: release the value handle (basis state c)
  call void @cq_template_and_i32_hl_unc(i32 %25, i32 %9, i32 3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %25)    ; IR: release the %11 rail (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %7, i32 3, i32 %24)    ; IR: pop the memcpy stores LIFO: b[3] back to |0>
  call void @cqrt_qram_store_i32_hl_unc(i32 %7, i32 2, i32 %22)    ; IR: b[2]
  call void @cqrt_qram_store_i32_hl_unc(i32 %7, i32 1, i32 %20)    ; IR: b[1]
  call void @cqrt_qram_store_i32_hl_unc(i32 %7, i32 0, i32 %18)    ; IR: b[0]
  br label %30

30:
  %31 = phi i64 [ 3, %17 ], [ %35, %30 ]    ; IR: reverse of the fill loop: i from 3 down to 0
  %32 = trunc nuw nsw i64 %31 to i32    ; IR: %22 of that trip (classical)
  %33 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %31    ; IR: %24 of that trip
  %34 = load i32, ptr %33, align 4    ; IR: the %23 rail of that trip (the handle a[i] holds)
  call void @cq_template_add_i32_hl_unc(i32 %34, i32 %8, i32 %32)    ; IR: uncompute %23 (no store on b reads it any more)
  call void @cqrt_free(i32 %34)    ; IR: release the %23 rail (|0>)
  %35 = add nsw i64 %31, -1
  %36 = icmp sgt i64 %31, 0
  br i1 %36, label %30, label %37

37:
  call void @cqrt_qram_free(i32 %7)    ; IR: llvm.lifetime.end(%7): release b (every store popped, all cells |0>)
  %38 = call i32 @cqrt_measure_i32(i32 %29)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %38    ; IR: ret i32 %19
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_free(i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
