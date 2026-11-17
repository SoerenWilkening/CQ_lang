; HAND-WRITTEN. Rules: 20, 21, 16, 5, 14, 8, 9, 4, 2.
; Checked: the packed array a[0] | a[1] << 2 | a[2] << 4 | a[3] << 6 after one bubble pass over the cells
; a[k] = (x >> 2k) & 3 (measured), and m = max(a[0..3]) after the pass (copied out, measured); the classical result is
; pack | m << 8. Memory: the four cells of the block (P + 4k) hold the sorted a[k] at exit (not a named output).
; Clean: the three shift rails (x >> 2, x >> 4, x >> 6); every scan trip's load copy of a[k] and its umax rail (pushed,
; popped and uncomputed by the reverse scan loop; the load is un-copied there, rule 5 sentence 1); the load copy of a[0]
; read after the sort; the three post-loop load copies a[1..3], the three shl rails and the two inner ors of the pack.
; Nothing of the sort loop is pushed and it has no reverse loop.
; Kept: the user register x; the four cell rails (x & 3, (x >> 2) & 3, (x >> 4) & 3, (x >> 6) & 3), the value rails of
; the four initializer stores, with their four tape slots (rule 5 sentence 3); per sort trip the two load copies of
; a[i] and a[i+1] (the value rails of the trip's two controlled stores), the flag a[i] > a[i+1] (their control rail)
; and the two tape slots; the pack result rail and the copied-out maximum (both measured).
; Rotations: (Ry, x, th, 1).
; ONE BUS (rule 20): `a` is stored tainted values, so the alloca is BUS-RESIDENT (rule 20 (b)): one zeroed block
; __cq_alloc(16, 16) at the alloca's program point, no alloca remains, the lifetime markers are dropped (rule 16).
; m = __cq_mem() once at function entry. Every index is classical (the constant initializer offsets, the trip counter i
; and i + 1, the scan counter k, the fixed post-loop reads), so -O1's getelementptrs stay classical instructions and
; every access is _hl at their ptrtoint (rules 20, 21). The four initializer stores are KEPT bus stores of the cell
; rails (rule 5 sentence 3), which makes the cells QUANTUM; each cell rail is a store's value rail and stays allocated,
; so only the shift rails beneath them are uncomputed, each right after its `and` (its last reader; rule 5).
; The swap `if (a[i] > a[i+1]) { t = a[i]; a[i] = a[i+1]; a[i+1] = t; }`: both loads are bus loads (rails), the flag is
; the icmp template over the two load copies (rule 8), and the arm's only content is two stores. A bus access is never
; hoisted (rule 9): each store stays in its arm as qram_store_i32_hl_controlled under the flag (rule 5), so a[i] <- a[i+1]
; and a[i+1] <- a[i] happen on the flag = 1 branch only and each displaced cell goes to its own tape slot. Neither store
; is an in-place form (each stores the value loaded through the OTHER pointer), so both are kept stores: their value
; rails (the two load copies) and their control rail (the flag) are KEPT (rule 5 sentence 3). The trip therefore has no
; trip-local rail that rule 5 does not keep: nothing is pushed and the classical loop has no reverse loop (rule 14).
; After the sort no memory version change follows (the lifetime end is dropped), so every later load is un-copied after
; its last reader (rule 5 sentence 1). -O1 folded the scan's `if (a[i] > m) m = a[i]` into llvm.umax (one template per
; trip, rule 4); m is a loop-carried value seeded by the load copy of a[0], copied out after the scan (alloc + copy), and
; the reverse scan loop pops each trip's load copy and old m, uncomputes the umax, then un-copies the load at the
; address recomputed from the trip index (rule 14: no inbounds/nsw in the reverse loop). The pack is straight-line
; (rule 4) and uncomputed down to its result rail, each post-loop load copy un-copied after its shl's _unc; the load
; copy of a[0] (read by the scan's trip 1, whose umax _unc runs in the reverse scan loop, and by the pack's last or) is
; un-copied right after that or. Both measurements read result rails only and are placed after the cleanup, in program
; order.
; Basis check: for x = 0xc9 = 0b11_00_10_01 (cells 1, 2, 0, 3) the pass gives 1, 0, 2, 3 (one swap at i = 1), pack = 0xe1 and
; m = 3: result 0x3e1. For every basis x the pass moves the maximum to a[3], so m = a[3].
source_filename = "quantum_sort_swap.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @quantum_sort_swap(i32 noundef %0, double noundef %1) {
  %3 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %4 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %3 = alloca [4 x i32], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %5 = ptrtoint ptr %4 to i64    ; IR: %3  (the block's run-time address P, a classical i64, rule 21)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: llvm.lifetime.start(16, %3) dropped (rule 16); %5 = and i32 %4, 3
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %5, i32 %7)    ; IR: store i32 %5, ptr %3  [a[0]: kept store (rule 5); the cell rail is its value rail, kept]
  %8 = getelementptr inbounds i8, ptr %4, i64 4    ; IR: %6  (nothing tainted: the getelementptr stays, rule 20)
  %9 = ptrtoint ptr %8 to i64    ; IR: %6  (the run-time address P + 4 of a[1], classical)
  %10 = call i32 @cq_template_lshr_i32_hl(i32 %6, i32 2)    ; IR: %7 = lshr i32 %4, 2
  %11 = call i32 @cq_template_and_i32_hl(i32 %10, i32 3)    ; IR: %8 = and i32 %7, 3
  call void @cq_template_lshr_i32_hl_unc(i32 %10, i32 %6, i32 2)    ; IR: uncompute the shift x >> 2 (its only reader, the cell rail %11, is a kept store value rail, never uncomputed)
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %9, i32 %11)    ; IR: store i32 %8, ptr %6  [a[1]: kept store]
  %12 = getelementptr inbounds i8, ptr %4, i64 8    ; IR: %9
  %13 = ptrtoint ptr %12 to i64    ; IR: %9  (P + 8, a[2])
  %14 = call i32 @cq_template_lshr_i32_hl(i32 %6, i32 4)    ; IR: %10 = lshr i32 %4, 4
  %15 = call i32 @cq_template_and_i32_hl(i32 %14, i32 3)    ; IR: %11 = and i32 %10, 3
  call void @cq_template_lshr_i32_hl_unc(i32 %14, i32 %6, i32 4)    ; IR: uncompute the shift x >> 4 (its only reader, the cell rail %15, is a kept store value rail, never uncomputed)
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %13, i32 %15)    ; IR: store i32 %11, ptr %9  [a[2]: kept store]
  %16 = getelementptr inbounds i8, ptr %4, i64 12    ; IR: %12
  %17 = ptrtoint ptr %16 to i64    ; IR: %12  (P + 12, a[3])
  %18 = call i32 @cq_template_lshr_i32_hl(i32 %6, i32 6)    ; IR: %13 = lshr i32 %4, 6
  %19 = call i32 @cq_template_and_i32_hl(i32 %18, i32 3)    ; IR: %14 = and i32 %13, 3
  call void @cq_template_lshr_i32_hl_unc(i32 %18, i32 %6, i32 6)    ; IR: uncompute the shift x >> 6 (its only reader, the cell rail %19, is a kept store value rail, never uncomputed)
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %17, i32 %19)    ; IR: store i32 %14, ptr %12  [a[3]: kept store]
  br label %20    ; IR: br label %17

20:
  %21 = phi i64 [ 0, %2 ], [ %25, %20 ]    ; IR: %18 = phi i64  (classical trip counter i)
  %22 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %21    ; IR: %19  (the cell a[i]: classical index, the instruction stays)
  %23 = ptrtoint ptr %22 to i64    ; IR: %19  (its run-time address, classical)
  %24 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %23)    ; IR: %20 = load i32, ptr %19  [a bus load, a rail; the value rail of the store to a[i + 1] below: KEPT (rule 5)]
  %25 = add nuw nsw i64 %21, 1    ; IR: %21  (classical)
  %26 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %25    ; IR: %22  (the cell a[i + 1])
  %27 = ptrtoint ptr %26 to i64    ; IR: %22  (its run-time address, classical)
  %28 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %27)    ; IR: %23 = load i32, ptr %22  [a bus load, a rail; the value rail of the store to a[i] below: KEPT]
  %29 = call i32 @cq_template_icmp_ugt_i32(i32 %24, i32 %28)    ; IR: %24 = icmp ugt i32 %20, %23  [the arm flag of block %25; the control of two kept stores: KEPT (rule 5)]
  call void @cqrt_qram_store_i32_hl_controlled(i32 %29, i32 %3, i64 %23, i32 %28)    ; IR: store i32 %23, ptr %19 in block %25  [a[i] <- a[i + 1] under the flag (rule 9: not hoisted); kept store, its own tape slot]
  call void @cqrt_qram_store_i32_hl_controlled(i32 %29, i32 %3, i64 %27, i32 %24)    ; IR: store i32 %20, ptr %22 in block %25  [a[i + 1] <- a[i] under the flag; kept store]
  %30 = icmp eq i64 %25, 3    ; IR: %27 = icmp eq i64 %21, 3  (classical)
  br i1 %30, label %31, label %20    ; IR: br i1 %27, label %15, label %17  (nothing pushed: every trip rail is kept)

31:
  %32 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %5)    ; IR: %16 = load i32, ptr %3  [a[0]: a bus load at P; un-copied after the pack (no memory version change follows)]
  br label %33    ; IR: br label %42

33:
  %34 = phi i64 [ 1, %31 ], [ %40, %33 ]    ; IR: %43 = phi i64  (classical scan counter k)
  %35 = phi i32 [ %32, %31 ], [ %39, %33 ]    ; IR: %44 = phi i32 [ %16, %15 ], [ %47, %42 ]
  %36 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %34    ; IR: %45  (the cell a[k])
  %37 = ptrtoint ptr %36 to i64    ; IR: %45  (its run-time address, classical)
  %38 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %37)    ; IR: %46 = load i32, ptr %45  [a bus load; un-copied by the reverse scan loop after the umax _unc]
  %39 = call i32 @cq_template_umax_i32(i32 %38, i32 %35)    ; IR: %47 = call i32 @llvm.umax.i32(i32 %46, i32 %44)
  call void @cqrt_push(i32 %35)    ; IR: %44 of this trip, for the reverse scan loop (rule 14)
  call void @cqrt_push(i32 %38)    ; IR: %46 of this trip (the load copy), for the reverse scan loop (rule 14)
  %40 = add nuw nsw i64 %34, 1    ; IR: %48  (classical)
  %41 = icmp eq i64 %40, 4    ; IR: %49 = icmp eq i64 %48, 4  (classical)
  br i1 %41, label %42, label %33    ; IR: br i1 %49, label %28, label %42

42:
  %43 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %47 as read by %39 = cq_measure_ui32(%47)  [copied-out maximum]
  call void @cqrt_copy_i32(i32 %39, i32 %43)    ; IR: %47
  br label %44

44:
  %45 = phi i64 [ 3, %42 ], [ %51, %44 ]    ; IR: reverse scan counter (3 down to 1)
  %46 = phi i32 [ %39, %42 ], [ %48, %44 ]    ; IR: %47 of the trip being undone
  %47 = call i32 @cqrt_pop()    ; IR: %46 of that trip (the load copy)
  %48 = call i32 @cqrt_pop()    ; IR: %44 of that trip
  %49 = getelementptr [4 x i32], ptr %4, i64 0, i64 %45    ; IR: %45 of that trip (recomputed from the trip index, rule 14)
  %50 = ptrtoint ptr %49 to i64    ; IR: %45 of that trip  (its run-time address, classical)
  call void @cq_template_umax_i32_unc(i32 %46, i32 %47, i32 %48)    ; IR: uncompute %47
  call void @cqrt_free(i32 %46)    ; IR: release the %47 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %47, i32 %3, i64 %50)    ; IR: un-copy %46 (rule 5: no memory version change since the load)
  call void @cqrt_free(i32 %47)    ; IR: release the %46 rail (|0>)
  %51 = add i64 %45, -1
  %52 = icmp eq i64 %51, 0
  br i1 %52, label %53, label %44    ; IR: the last pop is %16 = a[0]'s load copy, un-copied after the pack (not freed here)

53:
  %54 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %9)    ; IR: %29 = load i32, ptr %6  [a[1]: a bus load]
  %55 = call i32 @cq_template_shl_i32_hl(i32 %54, i32 2)    ; IR: %30 = shl i32 %29, 2
  %56 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %13)    ; IR: %31 = load i32, ptr %9  [a[2]]
  %57 = call i32 @cq_template_shl_i32_hl(i32 %56, i32 4)    ; IR: %32 = shl i32 %31, 4
  %58 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %17)    ; IR: %33 = load i32, ptr %12  [a[3]]
  %59 = call i32 @cq_template_shl_i32_hl(i32 %58, i32 6)    ; IR: %34 = shl i32 %33, 6
  %60 = call i32 @cq_template_or_i32(i32 %55, i32 %57)    ; IR: %35 = or i32 %30, %32
  %61 = call i32 @cq_template_or_i32(i32 %60, i32 %59)    ; IR: %36 = or i32 %35, %34
  %62 = call i32 @cq_template_or_i32(i32 %61, i32 %32)    ; IR: %37 = or i32 %36, %16  [pack result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %32, i32 %3, i64 %5)    ; IR: un-copy %16 (a[0]: its last readers, the trip-1 umax _unc and %37 just above, are done; rule 5 sentence 1)
  call void @cqrt_free(i32 %32)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %61, i32 %60, i32 %59)    ; IR: uncompute %36
  call void @cqrt_free(i32 %61)    ; IR: release it (|0>)
  call void @cq_template_or_i32_unc(i32 %60, i32 %55, i32 %57)    ; IR: uncompute %35
  call void @cqrt_free(i32 %60)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %59, i32 %58, i32 6)    ; IR: uncompute %34
  call void @cqrt_free(i32 %59)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %58, i32 %3, i64 %17)    ; IR: un-copy %33 (a[3]; rule 5: no memory version change since the load)
  call void @cqrt_free(i32 %58)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %57, i32 %56, i32 4)    ; IR: uncompute %32
  call void @cqrt_free(i32 %57)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %56, i32 %3, i64 %13)    ; IR: un-copy %31 (a[2])
  call void @cqrt_free(i32 %56)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %55, i32 %54, i32 2)    ; IR: uncompute %30
  call void @cqrt_free(i32 %55)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %54, i32 %3, i64 %9)    ; IR: un-copy %29 (a[1])
  call void @cqrt_free(i32 %54)    ; IR: release it (|0>)
  %63 = call i32 @cqrt_measure_i32(i32 %62)    ; IR: %38 = cq_measure_ui32(%37)
  %64 = call i32 @cqrt_measure_i32(i32 %43)    ; IR: %39 = cq_measure_ui32(%47)
  %65 = shl i32 %64, 8    ; IR: %40  (classical)
  %66 = or i32 %65, %63    ; IR: %41  (classical)
  ret i32 %66    ; IR: llvm.lifetime.end(16, %3) dropped (rule 16); ret i32 %41
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i32(i32, i32)
declare i32 @cq_template_umax_i32(i32, i32)
declare void @cq_template_umax_i32_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
