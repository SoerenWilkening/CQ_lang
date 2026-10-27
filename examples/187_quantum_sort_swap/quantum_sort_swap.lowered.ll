; HAND-WRITTEN. Rules: 20 (slot array), 9, 8, 14, 4, 5, 2.
; Checked: the packed array a[0] | a[1] << 2 | a[2] << 4 | a[3] << 6 after one bubble pass over the cells
; a[k] = (x >> 2k) & 3 (measured), and m = max(a[0..3]) after the pass (copied out, measured); the classical result is
; pack | m << 8.
; Clean: the four cell rails (x & 3, (x >> 2) & 3, (x >> 4) & 3, (x >> 6) & 3) and the three shift rails beneath them;
; every sort trip's flag a[i] > a[i+1] and its two select rails (popped and uncomputed by the reverse sort loop); every
; scan trip's umax rail (popped and uncomputed by the reverse scan loop); the three shl rails and the two inner ors of the
; pack.
; Kept: the user register x; the pack result rail and the copied-out maximum (both measured).
; Rotations: (Ry, x, th, 1).
; `a` is read and written only at CLASSICAL offsets (the constant initializer cells, the trip counters i and i + 1, the
; scan counter, the fixed post-loop reads), so it is a SLOT ARRAY (rule 20): a classical `alloca [4 x i32]` of handles,
; a load is the handle in the slot (no gate), a store replaces the handle. The swap `if (a[i] > a[i+1]) { ... }` is a
; quantum arm (rule 8: the flag is the icmp template over the two loaded handles) whose only content is two slot stores:
; under a quantum predicate a slot store is a `select` into a fresh rail (rule 20 table, rule 9 spelling
; cq_template_select_i32(f, then, else)): a[i] <- f ? a[i+1] : a[i] and a[i+1] <- f ? a[i] : a[i+1], each slot then
; holds the select rail. The old handles are not garbage of this trip: they are the select operands, so the trip pushes
; them with the flag (rule 14, classical bound: the loop stays a classical loop) and the reverse sort loop pops them,
; uncomputes both selects and the flag, and writes the old handles back into their slots, so the trip before it finds
; its own select rails in the slots. -O1 folded the scan's `if (a[i] > m) m = a[i]` into llvm.umax (one template per
; trip, rule 4); m is a loop-carried value (seeded by the handle a[0], not a fresh seed), copied out after the scan
; (alloc + copy) and the reverse scan loop uncomputes each trip; the scan's v = a[k] is re-read from the slot by the
; mirror (the slots are unchanged until the sort mirror). The pack is straight-line (rule 4) and uncomputed down to its
; result rail before the sort mirror reverses the slots. Both measurements read result rails only and are placed after
; the cleanup, in program order.
; Basis check: for x = 0xc9 = 0b11_00_10_01 (cells 1, 2, 0, 3) the pass gives 1, 0, 2, 3 (one swap at i = 1), pack = 0xe1 and
; m = 3: result 0x3e1. For every basis x the pass moves the maximum to a[3], so m = a[3].
source_filename = "quantum_sort_swap.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @quantum_sort_swap(i32 noundef %0, double noundef %1) {
  %3 = alloca [4 x i32], align 16    ; IR: %3 = alloca [4 x i32]  (a slot array: one handle per cell, classical offsets only)
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)    ; IR: %5 = and i32 %4, 3
  store i32 %5, ptr %3, align 16    ; IR: store i32 %5, ptr %3  (slot 0 holds the handle)
  %6 = getelementptr inbounds i8, ptr %3, i64 4    ; IR: %6  (slot 1)
  %7 = call i32 @cq_template_lshr_i32_hl(i32 %4, i32 2)    ; IR: %7 = lshr i32 %4, 2
  %8 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)    ; IR: %8 = and i32 %7, 3
  store i32 %8, ptr %6, align 4    ; IR: store i32 %8, ptr %6
  %9 = getelementptr inbounds i8, ptr %3, i64 8    ; IR: %9  (slot 2)
  %10 = call i32 @cq_template_lshr_i32_hl(i32 %4, i32 4)    ; IR: %10 = lshr i32 %4, 4
  %11 = call i32 @cq_template_and_i32_hl(i32 %10, i32 3)    ; IR: %11 = and i32 %10, 3
  store i32 %11, ptr %9, align 8    ; IR: store i32 %11, ptr %9
  %12 = getelementptr inbounds i8, ptr %3, i64 12    ; IR: %12  (slot 3)
  %13 = call i32 @cq_template_lshr_i32_hl(i32 %4, i32 6)    ; IR: %13 = lshr i32 %4, 6
  %14 = call i32 @cq_template_and_i32_hl(i32 %13, i32 3)    ; IR: %14 = and i32 %13, 3
  store i32 %14, ptr %12, align 4    ; IR: store i32 %14, ptr %12
  br label %15    ; IR: br label %17

15:
  %16 = phi i64 [ 0, %2 ], [ %19, %15 ]    ; IR: %18 = phi i64  (classical trip counter i)
  %17 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %16    ; IR: %19  (slot of a[i])
  %18 = load i32, ptr %17, align 4    ; IR: %20 = load a[i]  (the handle; no gate)
  %19 = add nuw nsw i64 %16, 1    ; IR: %21  (classical)
  %20 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %19    ; IR: %22  (slot of a[i + 1])
  %21 = load i32, ptr %20, align 4    ; IR: %23 = load a[i + 1]  (the handle; no gate)
  %22 = call i32 @cq_template_icmp_ugt_i32(i32 %18, i32 %21)    ; IR: %24 = icmp ugt i32 %20, %23  [the arm flag of block %25]
  %23 = call i32 @cq_template_select_i32(i32 %22, i32 %21, i32 %18)    ; IR: store i32 %23, ptr %19 in block %25 merged at %26: a[i] = %24 ? %23 : %20  (fresh rail)
  %24 = call i32 @cq_template_select_i32(i32 %22, i32 %18, i32 %21)    ; IR: store i32 %20, ptr %22 in block %25 merged at %26: a[i + 1] = %24 ? %20 : %23  (fresh rail)
  store i32 %23, ptr %17, align 4    ; IR: slot i now holds the merged handle
  store i32 %24, ptr %20, align 4    ; IR: slot i + 1 now holds the merged handle
  call void @cqrt_push(i32 %18)    ; IR: %20 of this trip, for the mirror
  call void @cqrt_push(i32 %21)    ; IR: %23 of this trip
  call void @cqrt_push(i32 %22)    ; IR: %24 of this trip
  %25 = icmp eq i64 %19, 3    ; IR: %27 = icmp eq i64 %21, 3  (classical)
  br i1 %25, label %26, label %15    ; IR: br i1 %27, label %15, label %17

26:
  %27 = load i32, ptr %3, align 16    ; IR: %16 = load a[0]  (the handle; no gate)
  br label %28    ; IR: br label %42

28:
  %29 = phi i64 [ 1, %26 ], [ %34, %28 ]    ; IR: %43 = phi i64  (classical scan counter)
  %30 = phi i32 [ %27, %26 ], [ %33, %28 ]    ; IR: %44 = phi i32 [ %16, %15 ], [ %47, %42 ]
  %31 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %29    ; IR: %45  (slot of a[k])
  %32 = load i32, ptr %31, align 4    ; IR: %46 = load a[k]  (the handle; no gate)
  %33 = call i32 @cq_template_umax_i32(i32 %32, i32 %30)    ; IR: %47 = call i32 @llvm.umax.i32(i32 %46, i32 %44)
  call void @cqrt_push(i32 %30)    ; IR: %44 of this trip, for the mirror
  %34 = add nuw nsw i64 %29, 1    ; IR: %48  (classical)
  %35 = icmp eq i64 %34, 4    ; IR: %49 = icmp eq i64 %48, 4  (classical)
  br i1 %35, label %36, label %28    ; IR: br i1 %49, label %28, label %42

36:
  %37 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %47 as read by %39 = cq_measure_ui32(%47)  [copied-out maximum]
  call void @cqrt_copy_i32(i32 %33, i32 %37)    ; IR: %47
  br label %38

38:
  %39 = phi i64 [ 3, %36 ], [ %44, %38 ]    ; IR: reverse scan counter (3 down to 1)
  %40 = phi i32 [ %33, %36 ], [ %41, %38 ]    ; IR: %47 of the trip being undone
  %41 = call i32 @cqrt_pop()    ; IR: %44 of that trip
  %42 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %39    ; IR: %45 of that trip
  %43 = load i32, ptr %42, align 4    ; IR: %46 of that trip (the slot is unchanged since the scan)
  call void @cq_template_umax_i32_unc(i32 %40, i32 %43, i32 %41)    ; IR: uncompute %47
  call void @cqrt_free(i32 %40)    ; IR: release the %47 rail (|0>)
  %44 = add nsw i64 %39, -1
  %45 = icmp eq i64 %44, 0
  br i1 %45, label %46, label %38    ; IR: the last pop is %16 = a[0]'s handle, owned by the sort (not freed here)

46:
  %47 = load i32, ptr %6, align 4    ; IR: %29 = load a[1]  (the handle; no gate)
  %48 = call i32 @cq_template_shl_i32_hl(i32 %47, i32 2)    ; IR: %30 = shl i32 %29, 2
  %49 = load i32, ptr %9, align 8    ; IR: %31 = load a[2]
  %50 = call i32 @cq_template_shl_i32_hl(i32 %49, i32 4)    ; IR: %32 = shl i32 %31, 4
  %51 = load i32, ptr %12, align 4    ; IR: %33 = load a[3]
  %52 = call i32 @cq_template_shl_i32_hl(i32 %51, i32 6)    ; IR: %34 = shl i32 %33, 6
  %53 = call i32 @cq_template_or_i32(i32 %48, i32 %50)    ; IR: %35 = or i32 %30, %32
  %54 = call i32 @cq_template_or_i32(i32 %53, i32 %52)    ; IR: %36 = or i32 %35, %34
  %55 = call i32 @cq_template_or_i32(i32 %54, i32 %27)    ; IR: %37 = or i32 %36, %16  [pack result rail]
  call void @cq_template_or_i32_unc(i32 %54, i32 %53, i32 %52)    ; IR: uncompute %36
  call void @cqrt_free(i32 %54)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %53, i32 %48, i32 %50)    ; IR: uncompute %35
  call void @cqrt_free(i32 %53)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %52, i32 %51, i32 6)    ; IR: uncompute %34
  call void @cqrt_free(i32 %52)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %50, i32 %49, i32 4)    ; IR: uncompute %32
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %48, i32 %47, i32 2)    ; IR: uncompute %30
  call void @cqrt_free(i32 %48)    ; IR: release it (|0>)
  br label %56

56:
  %57 = phi i64 [ 2, %46 ], [ %66, %56 ]    ; IR: reverse trip counter (2 down to 0)
  %58 = call i32 @cqrt_pop()    ; IR: %24 of that trip
  %59 = call i32 @cqrt_pop()    ; IR: %23 of that trip
  %60 = call i32 @cqrt_pop()    ; IR: %20 of that trip
  %61 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %57    ; IR: %19 of that trip
  %62 = load i32, ptr %61, align 4    ; IR: the a[i] select rail of that trip (the later trips are already undone)
  %63 = add nuw nsw i64 %57, 1    ; IR: %21 of that trip
  %64 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %63    ; IR: %22 of that trip
  %65 = load i32, ptr %64, align 4    ; IR: the a[i + 1] select rail of that trip
  call void @cq_template_select_i32_unc(i32 %65, i32 %58, i32 %60, i32 %59)    ; IR: uncompute the a[i + 1] merge
  call void @cqrt_free(i32 %65)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %62, i32 %58, i32 %59, i32 %60)    ; IR: uncompute the a[i] merge
  call void @cqrt_free(i32 %62)    ; IR: release it (|0>)
  call void @cq_template_icmp_ugt_i32_unc(i32 %58, i32 %60, i32 %59)    ; IR: uncompute %24
  call void @cqrt_free(i32 %58)    ; IR: release the flag (|0>)
  store i32 %60, ptr %61, align 4    ; IR: slot i holds %20 of that trip again
  store i32 %59, ptr %64, align 4    ; IR: slot i + 1 holds %23 of that trip again
  %66 = add nsw i64 %57, -1
  %67 = icmp eq i64 %57, 0
  br i1 %67, label %68, label %56

68:
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %13, i32 3)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %13, i32 %4, i32 6)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %10, i32 3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %10, i32 %4, i32 4)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %7, i32 3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %7, i32 %4, i32 2)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 3)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release it (|0>)
  %69 = call i32 @cqrt_measure_i32(i32 %55)    ; IR: %38 = cq_measure_ui32(%37)
  %70 = call i32 @cqrt_measure_i32(i32 %37)    ; IR: %39 = cq_measure_ui32(%47)
  %71 = shl i32 %70, 8    ; IR: %40  (classical)
  %72 = or i32 %71, %69    ; IR: %41  (classical)
  ret i32 %72    ; IR: ret i32 %41
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i32(i32, i32)
declare void @cq_template_icmp_ugt_i32_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_umax_i32(i32, i32)
declare void @cq_template_umax_i32_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
