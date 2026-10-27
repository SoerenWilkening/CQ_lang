; HAND-WRITTEN. Rules: 20 (QRAM, QROM), 22, 14, 4, 5, 7, 2.
; Checked: histogram: h[0] | h[1] << 4 | h[2] << 8 | h[3] << 12 with h[b] = #{i < 4 : (x >> 2i) & 3 == b} (measured).
; gather_scatter: s = sum over i < 4 of t[(x >> 3i) & 7] (copied out, measured) and out[0] | out[1] << 8 | out[2] << 16 |
; out[3] << 24 after out[(x >> 2i) & 3] = v0 + i for i = 0..3 in order (measured); the classical result is their sum.
; Clean: histogram: every trip's shift rail, bucket index rail, loaded old count and incremented count (popped and
; uncomputed by the reverse loop, the trip's store popped first), the four fixed-index copy-outs, the three shl rails and
; two inner ors, the shared memset handle 0, every store's tape slot, and the QRAM h (every store popped, then
; cqrt_qram_free). gather_scatter: the same for out, plus every trip's two shift rails, table index rail, QROM read, the
; partial sums s_1..s_4 and the basis-state value handle v0 + i (rule 7), and the |0> seed of s (never written).
; Kept: histogram: the user register x and the pack result rail (measured). gather_scatter: x, the copied-out sum and the
; pack result rail (both measured).
; Rotations: (Ry, x, th, 1) in each entry.
; h is read AND written at the quantum bucket (x >> 2i) & 3, so it is a QRAM (rule 20: a quantum-offset store): ONE
; cqrt_qram_alloc_i32(4) at the alloca, the `= {0}` memset is one cqrt_qram_store_i32_hl per cell sharing one basis-state
; handle 0 (rule 22, as in 30), and `h[b]++` is a read-modify-write at the logical-i32 index rail (-O1's zext to i64 and
; the gep scaling are not emitted): cqrt_qram_load_i32(h, idx) -> old (copy-out), new = old + 1 into a fresh rail,
; cqrt_qram_store_i32(h, idx, new) (the store owns a tape slot; the displaced cell, old, goes into it). The loop bound is
; classical, so it stays a classical loop (rule 14): the shift amount 2i is classical (an _hl literal recomputed from the
; trip index by the mirror) and each trip pushes its four rails. The post-loop reads are fixed-index copy-outs
; cqrt_qram_load_i32_hl. The reverse loop runs after the pack's garbage is uncomputed and the copy-outs are un-copied:
; every bucket store may touch every cell, so the pops are strictly last-in-first-out; popping trip i's store puts old
; back into cell[idx] (and its tape slot back to |0>), so old's un-copy finds the value it copied, then idx and the shift
; rail are uncomputed. The memset stores (distinct cells, they commute) are popped last.
; gather_scatter: t is a constant global that never holds a handle, read at the quantum index (x >> 3i) & 7, so each read
; is one QROM cq_template_qrom_load_i32(@t, 8, idx) over its contents at the load (rule 20: length = the object's 8 cells;
; the _unc takes the same table and index). The sum s is a loop-carried value seeded by a |0> rail (the phi's classical 0
; incoming as a seed, rule 7) and copied out after the loop (rule 14). out is written at a quantum offset, so it is a QRAM;
; each value v0 + i is classical, materialised as a basis-state handle (a QRAM store value is always a handle) and stored
; by cqrt_qram_store_i32(out, idx, v); a later store to the same cell displaces the earlier one onto its own tape slot, so
; the cell ends with the LAST value written to it, as in C. The trip pushes s (the carried input), both shift rails, the
; table index, the QROM read, the value handle and the store index. -O1 measures s before reading out; both measurements
; read result rails only and are placed after the cleanup, in program order.
; Basis check: x = 0x1b = 0b00_01_10_11 (buckets 3, 2, 1, 0): h = {1, 1, 1, 1}, result 0x1111. For gather_scatter with
; x = 0x1b and v0 = 10: table indices 3, 3, 0, 0 give s = 1 + 1 + 3 + 3 = 8; out[3] = 10, out[2] = 11, out[1] = 12,
; out[0] = 13, pack = 0x0a0b0c0d; result 8 + 0x0a0b0c0d.
source_filename = "histogram_scatter.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@t = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @histogram(i32 noundef %0, double noundef %1) {
  %3 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %3 = alloca [4 x i32]: a 4-cell QRAM, cells |0> (written at a quantum index)
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: call @llvm.memset(%3, 0, 16): the classical value 0 as ONE basis-state handle, shared by the four cell stores (rule 22)
  call void @cqrt_qram_store_i32_hl(i32 %3, i32 0, i32 %5)    ; IR: memset: h[0] = 0
  call void @cqrt_qram_store_i32_hl(i32 %3, i32 1, i32 %5)    ; IR: memset: h[1] = 0
  call void @cqrt_qram_store_i32_hl(i32 %3, i32 2, i32 %5)    ; IR: memset: h[2] = 0
  call void @cqrt_qram_store_i32_hl(i32 %3, i32 3, i32 %5)    ; IR: memset: h[3] = 0
  br label %6    ; IR: br label %20

6:
  %7 = phi i32 [ 0, %2 ], [ %13, %6 ]    ; IR: %21 = phi i32  (classical trip counter)
  %8 = shl nuw nsw i32 %7, 1    ; IR: %22 = shl nuw nsw i32 %21, 1  (classical shift amount 2i)
  %9 = call i32 @cq_template_lshr_i32_hl(i32 %4, i32 %8)    ; IR: %23 = lshr i32 %4, %22
  %10 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)    ; IR: %24 = and i32 %23, 3  [the bucket index rail; the %25 zext and the %26 gep are not emitted]
  %11 = call i32 @cqrt_qram_load_i32(i32 %3, i32 %10)    ; IR: %27 = load i32, ptr %26: old = h[idx]  (one access, copy-out)
  %12 = call i32 @cq_template_add_i32_hl(i32 %11, i32 1)    ; IR: %28 = add nsw i32 %27, 1
  call void @cqrt_qram_store_i32(i32 %3, i32 %10, i32 %12)    ; IR: store i32 %28, ptr %26: h[idx] = new  (one access; old goes onto the store's tape slot)
  call void @cqrt_push(i32 %9)    ; IR: %23 of this trip, for the mirror
  call void @cqrt_push(i32 %10)    ; IR: %24 of this trip
  call void @cqrt_push(i32 %11)    ; IR: %27 of this trip
  call void @cqrt_push(i32 %12)    ; IR: %28 of this trip
  %13 = add nuw nsw i32 %7, 1    ; IR: %29  (classical)
  %14 = icmp eq i32 %13, 4    ; IR: %30 = icmp eq i32 %29, 4  (classical)
  br i1 %14, label %15, label %6    ; IR: br i1 %30, label %5, label %20

15:
  %16 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i32 0)    ; IR: %6 = load h[0]  (fixed index into the QRAM: copy-out)
  %17 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i32 1)    ; IR: %8 = load h[1]
  %18 = call i32 @cq_template_shl_i32_hl(i32 %17, i32 4)    ; IR: %9 = shl i32 %8, 4
  %19 = call i32 @cq_template_or_i32(i32 %18, i32 %16)    ; IR: %10 = or i32 %9, %6
  %20 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i32 2)    ; IR: %12 = load h[2]
  %21 = call i32 @cq_template_shl_i32_hl(i32 %20, i32 8)    ; IR: %13 = shl i32 %12, 8
  %22 = call i32 @cq_template_or_i32(i32 %19, i32 %21)    ; IR: %14 = or i32 %10, %13
  %23 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i32 3)    ; IR: %16 = load h[3]
  %24 = call i32 @cq_template_shl_i32_hl(i32 %23, i32 12)    ; IR: %17 = shl i32 %16, 12
  %25 = call i32 @cq_template_or_i32(i32 %22, i32 %24)    ; IR: %18 = or i32 %14, %17  [result rail]
  call void @cq_template_shl_i32_hl_unc(i32 %24, i32 %23, i32 12)    ; IR: uncompute %17
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %23, i32 %3, i32 3)    ; IR: un-copy %16 (h[3])
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %22, i32 %19, i32 %21)    ; IR: uncompute %14
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %21, i32 %20, i32 8)    ; IR: uncompute %13
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %20, i32 %3, i32 2)    ; IR: un-copy %12 (h[2])
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %19, i32 %18, i32 %16)    ; IR: uncompute %10
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %18, i32 %17, i32 4)    ; IR: uncompute %9
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %17, i32 %3, i32 1)    ; IR: un-copy %8 (h[1])
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %16, i32 %3, i32 0)    ; IR: un-copy %6 (h[0])
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  br label %26

26:
  %27 = phi i32 [ 3, %15 ], [ %33, %26 ]    ; IR: reverse trip counter (3 down to 0)
  %28 = call i32 @cqrt_pop()    ; IR: %28 of that trip
  %29 = call i32 @cqrt_pop()    ; IR: %27 of that trip
  %30 = call i32 @cqrt_pop()    ; IR: %24 of that trip
  %31 = call i32 @cqrt_pop()    ; IR: %23 of that trip
  %32 = shl nuw nsw i32 %27, 1    ; IR: %22 of that trip (classical)
  call void @cqrt_qram_store_i32_unc(i32 %3, i32 %30, i32 %28)    ; IR: pop store i32 %28 of that trip (the latest live store on h): cell[idx] holds old again, the tape slot is |0> and released
  call void @cq_template_add_i32_hl_unc(i32 %28, i32 %29, i32 1)    ; IR: uncompute %28
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %29, i32 %3, i32 %30)    ; IR: un-copy %27 against the restored cell[idx]
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %30, i32 %31, i32 3)    ; IR: uncompute %24
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %31, i32 %4, i32 %32)    ; IR: uncompute %23
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  %33 = add nsw i32 %27, -1
  %34 = icmp eq i32 %27, 0
  br i1 %34, label %35, label %26

35:
  call void @cqrt_qram_store_i32_hl_unc(i32 %3, i32 3, i32 %5)    ; IR: pop the memset stores (after every bucket store; distinct cells commute, written in reverse): h[3] back to |0>
  call void @cqrt_qram_store_i32_hl_unc(i32 %3, i32 2, i32 %5)    ; IR: h[2]
  call void @cqrt_qram_store_i32_hl_unc(i32 %3, i32 1, i32 %5)    ; IR: h[1]
  call void @cqrt_qram_store_i32_hl_unc(i32 %3, i32 0, i32 %5)    ; IR: h[0]
  call void @cqrt_free(i32 %5)    ; IR: release the basis-state handle 0 (its last store was popped)
  call void @cqrt_qram_free(i32 %3)    ; IR: llvm.lifetime.end: release the array (every store popped, all cells |0>)
  %36 = call i32 @cqrt_measure_i32(i32 %25)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %36    ; IR: ret i32 %19
}

define i32 @gather_scatter(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %4 = alloca [4 x i32]: a 4-cell QRAM, cells |0> (written at a quantum index)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: call @llvm.memset(%4, 0, 16): the classical value 0 as ONE basis-state handle, shared by the four cell stores (rule 22)
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 0, i32 %6)    ; IR: memset: out[0] = 0
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 1, i32 %6)    ; IR: memset: out[1] = 0
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 2, i32 %6)    ; IR: memset: out[2] = 0
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 3, i32 %6)    ; IR: memset: out[3] = 0
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %25  [s before trip 0, a |0> seed]
  br label %8    ; IR: br label %23

8:
  %9 = phi i32 [ 0, %3 ], [ %21, %8 ]    ; IR: %24 = phi i32  (classical trip counter)
  %10 = phi i32 [ %7, %3 ], [ %15, %8 ]    ; IR: %25 = phi i32 [ 0, %3 ], [ %32, %23 ]
  %11 = mul nuw nsw i32 %9, 3    ; IR: %26 = mul nuw nsw i32 %24, 3  (classical shift amount 3i)
  %12 = call i32 @cq_template_lshr_i32_hl(i32 %5, i32 %11)    ; IR: %27 = lshr i32 %5, %26
  %13 = call i32 @cq_template_and_i32_hl(i32 %12, i32 7)    ; IR: %28 = and i32 %27, 7  [the table index rail; the %29 zext and the %30 gep are not emitted]
  %14 = call i32 @cq_template_qrom_load_i32(ptr @t, i64 8, i32 %13)    ; IR: %31 = load i32, ptr %30: t[j]  (a QROM over the constant table, 8 cells)
  %15 = call i32 @cq_template_add_i32(i32 %14, i32 %10)    ; IR: %32 = add nsw i32 %31, %25
  %16 = add nsw i32 %9, %2    ; IR: %33 = add nsw i32 %24, %2  (classical)
  %17 = call i32 @cqrt_alloc_i32(i32 %16)    ; IR: store i32 %33: the classical value v0 + i as a basis-state handle
  %18 = shl nuw nsw i32 %9, 1    ; IR: %34 = shl nuw nsw i32 %24, 1  (classical shift amount 2i)
  %19 = call i32 @cq_template_lshr_i32_hl(i32 %5, i32 %18)    ; IR: %35 = lshr i32 %5, %34
  %20 = call i32 @cq_template_and_i32_hl(i32 %19, i32 3)    ; IR: %36 = and i32 %35, 3  [the store index rail; the %37 zext and the %38 gep are not emitted]
  call void @cqrt_qram_store_i32(i32 %4, i32 %20, i32 %17)    ; IR: store i32 %33, ptr %38: out[k] = v0 + i  (one access; the displaced cell goes onto the store's tape slot)
  call void @cqrt_push(i32 %10)    ; IR: %25 of this trip, for the mirror
  call void @cqrt_push(i32 %12)    ; IR: %27 of this trip
  call void @cqrt_push(i32 %13)    ; IR: %28 of this trip
  call void @cqrt_push(i32 %14)    ; IR: %31 of this trip
  call void @cqrt_push(i32 %17)    ; IR: the value handle of this trip's store
  call void @cqrt_push(i32 %19)    ; IR: %35 of this trip
  call void @cqrt_push(i32 %20)    ; IR: %36 of this trip
  %21 = add nuw nsw i32 %9, 1    ; IR: %39  (classical)
  %22 = icmp eq i32 %21, 4    ; IR: %40 = icmp eq i32 %39, 4  (classical)
  br i1 %22, label %23, label %8    ; IR: br i1 %40, label %6, label %23

23:
  %24 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %32 as read by %7 = cq_measure_si32(%32)  [copied-out sum]
  call void @cqrt_copy_i32(i32 %15, i32 %24)    ; IR: %32
  %25 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i32 0)    ; IR: %8 = load out[0]  (fixed index into the QRAM: copy-out)
  %26 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i32 1)    ; IR: %10 = load out[1]
  %27 = call i32 @cq_template_shl_i32_hl(i32 %26, i32 8)    ; IR: %11 = shl i32 %10, 8
  %28 = call i32 @cq_template_or_i32(i32 %27, i32 %25)    ; IR: %12 = or i32 %11, %8
  %29 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i32 2)    ; IR: %14 = load out[2]
  %30 = call i32 @cq_template_shl_i32_hl(i32 %29, i32 16)    ; IR: %15 = shl i32 %14, 16
  %31 = call i32 @cq_template_or_i32(i32 %28, i32 %30)    ; IR: %16 = or i32 %12, %15
  %32 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i32 3)    ; IR: %18 = load out[3]
  %33 = call i32 @cq_template_shl_i32_hl(i32 %32, i32 24)    ; IR: %19 = shl i32 %18, 24
  %34 = call i32 @cq_template_or_i32(i32 %31, i32 %33)    ; IR: %20 = or i32 %16, %19  [result rail]
  call void @cq_template_shl_i32_hl_unc(i32 %33, i32 %32, i32 24)    ; IR: uncompute %19
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %32, i32 %4, i32 3)    ; IR: un-copy %18 (out[3])
  call void @cqrt_free(i32 %32)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %31, i32 %28, i32 %30)    ; IR: uncompute %16
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %30, i32 %29, i32 16)    ; IR: uncompute %15
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %29, i32 %4, i32 2)    ; IR: un-copy %14 (out[2])
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %28, i32 %27, i32 %25)    ; IR: uncompute %12
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %27, i32 %26, i32 8)    ; IR: uncompute %11
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %26, i32 %4, i32 1)    ; IR: un-copy %10 (out[1])
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %25, i32 %4, i32 0)    ; IR: un-copy %8 (out[0])
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  br label %35

35:
  %36 = phi i32 [ 3, %23 ], [ %47, %35 ]    ; IR: reverse trip counter (3 down to 0)
  %37 = phi i32 [ %15, %23 ], [ %44, %35 ]    ; IR: %32 of the trip being undone
  %38 = call i32 @cqrt_pop()    ; IR: %36 of that trip
  %39 = call i32 @cqrt_pop()    ; IR: %35 of that trip
  %40 = call i32 @cqrt_pop()    ; IR: the value handle of that trip's store
  %41 = call i32 @cqrt_pop()    ; IR: %31 of that trip
  %42 = call i32 @cqrt_pop()    ; IR: %28 of that trip
  %43 = call i32 @cqrt_pop()    ; IR: %27 of that trip
  %44 = call i32 @cqrt_pop()    ; IR: %25 of that trip
  %45 = shl nuw nsw i32 %36, 1    ; IR: %34 of that trip (classical)
  %46 = mul nuw nsw i32 %36, 3    ; IR: %26 of that trip (classical)
  call void @cqrt_qram_store_i32_unc(i32 %4, i32 %38, i32 %40)    ; IR: pop store i32 %33 of that trip (the latest live store on out): cell[k] holds its earlier value again, the tape slot is |0> and released
  call void @cqrt_free(i32 %40)    ; IR: release the value handle (basis state v0 + i)
  call void @cq_template_and_i32_hl_unc(i32 %38, i32 %39, i32 3)    ; IR: uncompute %36
  call void @cqrt_free(i32 %38)    ; IR: release it (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %39, i32 %5, i32 %45)    ; IR: uncompute %35
  call void @cqrt_free(i32 %39)    ; IR: release it (|0>)
  call void @cq_template_add_i32_unc(i32 %37, i32 %41, i32 %44)    ; IR: uncompute %32
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %41, ptr @t, i64 8, i32 %42)    ; IR: uncompute %31 (the same table, the same index)
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %42, i32 %43, i32 7)    ; IR: uncompute %28
  call void @cqrt_free(i32 %42)    ; IR: release it (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %43, i32 %5, i32 %46)    ; IR: uncompute %27
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  %47 = add nsw i32 %36, -1
  %48 = icmp eq i32 %36, 0
  br i1 %48, label %49, label %35

49:
  call void @cqrt_free(i32 %44)    ; IR: release incoming 0 of phi %25 (never written, |0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 3, i32 %6)    ; IR: pop the memset stores (after every scatter store; distinct cells commute, written in reverse): out[3] back to |0>
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 2, i32 %6)    ; IR: out[2]
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 1, i32 %6)    ; IR: out[1]
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 0, i32 %6)    ; IR: out[0]
  call void @cqrt_free(i32 %6)    ; IR: release the basis-state handle 0 (its last store was popped)
  call void @cqrt_qram_free(i32 %4)    ; IR: llvm.lifetime.end: release the array (every store popped, all cells |0>)
  %50 = call i32 @cqrt_measure_i32(i32 %24)    ; IR: %7 = cq_measure_si32(%32)
  %51 = call i32 @cqrt_measure_i32(i32 %34)    ; IR: %21 = cq_measure_si32(%20)
  %52 = add nsw i32 %51, %50    ; IR: %22 = add nsw i32 %21, %7  (classical)
  ret i32 %52    ; IR: ret i32 %22
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_free(i32)
declare void @cqrt_qram_store_i32_hl(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare void @cq_template_qrom_load_i32_unc(i32, ptr, i64, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
