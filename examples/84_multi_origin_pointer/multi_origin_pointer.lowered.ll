; HAND-WRITTEN. Rules: 21, 20, 8, 7, 4, 5.
; Checked: a[0] + b[1], the returned sum (the add rail %24 -> %25).
; Clean: every rail and both arrays but the register x: the block predicate B = (x > 5) (%11), the tag chain (%12..%14), the
; idx chain (%15, %16), the two object compares (%18, %20) and guards g_a, g_b (%19, %21), the two fixed-index loads (%22,
; %23), the shared value handle v (%17) and the four initializer handles (%7..%10), all freed; the two stores are popped
; LIFO and both QRAM objects (%4, %5) are released.
; Kept: x (%6, the rotated register) and the sum (%24, measured).
; Rotations: (Ry, x, th, 1).
; The object guards g_o = B & (tag == o) are branch flags: cqrt_and_i1 into a fresh |0> rail, re-applied to uncompute
; (rule 8). A QUANTUM POINTER IS A FAT POINTER (tag, idx) (rule 21): tag is an i32 rail naming the OBJECT (0 = NULL,
; then the function's objects in definition order: here a = 1, b = 2; a compile-time object table holds each object's
; storage, cell width and size), idx is an i32 rail holding the CELL index inside it (the logical index; -O1's byte
; scaling and i64 extension are not emitted; a provenance of mixed cell widths would carry a byte offset and rescale at
; the access). Either half may be classical when the IR makes it so (here both selected pointers are object bases: idx is
; the classical 0 until the gep adds the index). Pointer instructions never touch memory: select/phi select the halves,
; gep adds to idx, icmp compares the halves, ptrtoint would materialise base[tag] + idx. Only load/store consume the
; pointer, and a deref is ONE ACCESS OF EVERY OBJECT in the pointer's provenance, guarded by g_o = B and tag == o (B the
; predicate of the block holding the access). Its offset is idx. Here idx = (x >> 1) & 1 is QUANTUM, so the store is a
; quantum-offset store into a and into b, which makes both objects QRAMs (rule 20) for their whole lifetime:
; cqrt_qram_alloc at the alloca, the classical initializer one cqrt_qram_store_<W>_hl per cell (classical index), the
; store one cqrt_qram_store_<W>_controlled(g_o, arr_o, idx, val) per object (the value always a handle: the classical v
; is materialised once by cqrt_alloc_<W>, shared by both origins, freed once the stores are popped), and the later
; fixed-index reads a[0], b[1] cqrt_qram_load_<W>_hl copy-outs. (Were idx classical, the tag alone being quantum, the
; store would instead be a guarded classical-offset slot store merged by select, no QRAM: rule 21, example 129.) The
; arm's pure ops run unguarded (a value computed under a false predicate is read by nothing). Stores are popped LIFO per
; array by their _unc, then the arrays are released. The address decoding of the controlled store is the backend's
; circuit (Bennett.jl memory.jl, fan-out per origin guarded by block AND origin predicate).
source_filename = "multi_origin_pointer.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @ptr_select_store(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_qram_alloc_i32(i32 2)    ; IR: %4 = alloca [2 x i32]  (object 1: a, a 2-cell QRAM: a store reaches it at a quantum offset)
  %5 = call i32 @cqrt_qram_alloc_i32(i32 2)    ; IR: %5 = alloca [2 x i32]  (object 2: b)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 1)    ; IR: store i64 8589934593, ptr %4  (a = {1, 2}: the classical initializer, cell by cell, values as basis-state handles)
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 0, i32 %7)    ; IR: a[0] = 1
  %8 = call i32 @cqrt_alloc_i32(i32 2)    ; IR: a[1] = 2
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 1, i32 %8)    ; IR: a[1] = 2
  %9 = call i32 @cqrt_alloc_i32(i32 3)    ; IR: store i64 17179869187, ptr %5  (b = {3, 4})
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 0, i32 %9)    ; IR: b[0] = 3
  %10 = call i32 @cqrt_alloc_i32(i32 4)    ; IR: b[1] = 4
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 1, i32 %10)    ; IR: b[1] = 4
  %11 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %6, i32 5)    ; IR: %7 = icmp ugt i32 %6, 5  [predicate B of block %8]
  %12 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)    ; IR: %9 = and i32 %6, 1
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 0)    ; IR: %10 = icmp eq i32 %9, 0
  %14 = call i32 @cq_template_select_i32_ll(i32 %13, i32 2, i32 1)    ; IR: %11 = select i1 %10, ptr %5, ptr %4  [the pointer's tag: b (2) or a (1); its idx is the classical 0]
  %15 = call i32 @cq_template_lshr_i32_hl(i32 %6, i32 1)    ; IR: %12 = lshr i32 %6, 1
  %16 = call i32 @cq_template_and_i32_hl(i32 %15, i32 1)    ; IR: %13 = and i32 %12, 1  [the pointer's idx after the gep: cell 0 + ((x >> 1) & 1); %14 zext and the %15 scaling are not emitted]
  %17 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %15: the classical value v as a basis-state handle, shared by both origins
  %18 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 1)    ; IR: object a addressed iff tag == 1
  %19 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: guard g_a = B and tag == 1  [fresh flag rail]
  call void @cqrt_and_i1(i32 %11, i32 %18, i32 %19)    ; IR: guard g_a = B and tag == 1
  call void @cqrt_qram_store_i32_controlled(i32 %19, i32 %4, i32 %16, i32 %17)    ; IR: store i32 %2, ptr %15 into a: a[idx] = v under g_a (one access; the backend fans out over the cells)
  %20 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 2)    ; IR: object b addressed iff tag == 2
  %21 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: guard g_b = B and tag == 2  [fresh flag rail]
  call void @cqrt_and_i1(i32 %11, i32 %20, i32 %21)    ; IR: guard g_b = B and tag == 2
  call void @cqrt_qram_store_i32_controlled(i32 %21, i32 %5, i32 %16, i32 %17)    ; IR: store into b: b[idx] = v under g_b
  %22 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i32 0)    ; IR: %17 = load a[0]  (fixed index into the quantum array: copy-out)
  %23 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i32 1)    ; IR: %19 = load b[1]
  %24 = call i32 @cq_template_add_i32(i32 %23, i32 %22)    ; IR: %20 = add nsw i32 %19, %17  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %23, i32 %5, i32 1)    ; IR: uncompute %19
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %22, i32 %4, i32 0)    ; IR: uncompute %17
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_controlled_unc(i32 %21, i32 %5, i32 %16, i32 %17)    ; IR: pop the store into b
  call void @cqrt_and_i1(i32 %11, i32 %20, i32 %21)    ; IR: uncompute g_b  [self-inverse]
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %20, i32 %14, i32 2)    ; IR: uncompute the b tag flag
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_controlled_unc(i32 %19, i32 %4, i32 %16, i32 %17)    ; IR: pop the store into a
  call void @cqrt_and_i1(i32 %11, i32 %18, i32 %19)    ; IR: uncompute g_a  [self-inverse]
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %18, i32 %14, i32 1)    ; IR: uncompute the a tag flag
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %17)    ; IR: release the value handle (basis state v)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %15, i32 1)    ; IR: uncompute %13
  call void @cqrt_free(i32 %16)    ; IR: release the %13 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %15, i32 %6, i32 1)    ; IR: uncompute %12
  call void @cqrt_free(i32 %15)    ; IR: release the %12 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %14, i32 %13, i32 2, i32 1)    ; IR: uncompute the pointer's tag %11
  call void @cqrt_free(i32 %14)    ; IR: release the %11 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %12, i32 0)    ; IR: uncompute %10
  call void @cqrt_free(i32 %13)    ; IR: release the %10 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %6, i32 1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %11, i32 %6, i32 5)    ; IR: uncompute %7
  call void @cqrt_free(i32 %11)    ; IR: release the %7 rail (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 1, i32 %10)    ; IR: pop the initializer of b (LIFO)
  call void @cqrt_free(i32 %10)    ; IR: release the basis-state handle 4
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 0, i32 %9)    ; IR: b[0]
  call void @cqrt_free(i32 %9)    ; IR: release the basis-state handle 3
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 1, i32 %8)    ; IR: a[1]
  call void @cqrt_free(i32 %8)    ; IR: release the basis-state handle 2
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 0, i32 %7)    ; IR: a[0]
  call void @cqrt_free(i32 %7)    ; IR: release the basis-state handle 1
  call void @cqrt_qram_free(i32 %5)    ; IR: release object b (all cells |0>)
  call void @cqrt_qram_free(i32 %4)    ; IR: release object a
  %25 = call i32 @cqrt_measure_i32(i32 %24)    ; IR: %21 = cq_measure_si32(%20)
  ret i32 %25    ; IR: ret i32 %21
}

declare void @cqrt_and_i1(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1 zeroext)

declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_free(i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32_controlled(i32, i32, i32, i32)
declare void @cqrt_qram_store_i32_controlled_unc(i32, i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_unc(i32, i32, i32)
declare void @cqrt_ry_i32(i32, double)
