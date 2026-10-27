; HAND-WRITTEN. Rules: 2, 4, 5, 7, 8, 9, 16, 20, §0 (run-time circuit), §1.3 (QRAM contract, qram_realloc), §2, §6.
; Checked: realloc_shrink: r = a[k & 1] (measured): v iff k & 3 < 2, else 0 (the never-written cell, §6).
; realloc_qsize: r = a[k & 1] + a[1] (measured): v + 7 for k & 3 == 0, 2v for k & 3 odd, v for k & 3 == 2.
; vla_qram: a[0] (measured): y iff x % n == 0, else 0 (§6). guarded_global: table[i & 7] (measured): y if x > k, else
; the cell's previous value (0 on the first call); the global's cells after the call (table[i & 7] == y iff x > k).
; Clean: realloc_shrink: k & 1, k & 3, the seed v, the store's tape slot, the realloc (undone), the QRAM a.
; realloc_qsize: k & 1, k & 3, the size rail (k & 3) + 2, the cell index (k & 3) + 1, both copy-outs, the seeds v and 7,
; both tape slots, the realloc (undone), the QRAM a. vla_qram: x % n, the seed y, the tape slot, the n-cell QRAM a.
; guarded_global: the flag x > k, both i & 7 rails, the seed y.
; Kept: realloc_shrink, realloc_qsize: k and the measured result. vla_qram: x and the measured result. guarded_global:
; x, i, the measured result, and the global QRAM table WITH its controlled store (never popped: an output, 160; the
; store's tape slot stays allocated, |0> on the x <= k branch).
; Rotations: realloc_shrink, realloc_qsize: (Ry, k, tk, 1). vla_qram: (Ry, x, tx, 1). guarded_global: (Ry, x, tx, 1);
; (Ry, i, ti, 1).
; realloc_shrink: a[k & 3] = v makes the malloc/realloc block one QRAM (186). realloc(a, 2) SHRINKS it:
; cqrt_qram_realloc_i8(a, 2) changes the logical size only; no gate runs and no cell moves (§1.3). When k & 3 >= 2 the
; stored v sits in a cell >= 2 that stays PHYSICALLY present but is out of range for every later access through a'
; (§2: a load there reads 0, a store is a no-op); C's realloc discards that cell, and the program never reads it
; again, so the circuit agrees with C on every basis input. The hidden cells are never re-exposed to the program: a
; later realloc that GREW a' back to 4 or more would map the new logical indices 2, 3 to FRESH |0> cells, never to the
; cells this shrink hid (§1.3), so a v hidden in cell 2 or 3 could not reappear (C's grown part is indeterminate = 0,
; §6); the hidden cells stay allocated, out of the program's reach, until the _unc chain re-exposes them for the pop.
; The read a[k & 1] (index < 2, in range) is the measured result, so it is never un-copied and its index rail is
; uncomputed right after it. At free(a) (rule 16) the realloc is undone FIRST (no store was made through a'),
; restoring the logical size 4, and then the store a[k & 3] = v is popped: its cell is still physically present (a
; shrink never detaches), so the pop returns it to |0> on every branch. The QRAM is released.
; realloc_qsize: realloc(a, (k & 3) + 2) has a QUANTUM size. The size rail (k & 3) + 2 is computed like any tainted
; value (-O1's zext to i64 is the size argument's representation and is not emitted) and the QRAM is resized to the
; size's UPPER BOUND 5 from LLVM's range facts (k & 3 <= 3; §1.3: a quantum n allocates at its upper bound): the call
; reads no rail, so the size rail has no consumer and is uncomputed at once (computed, never removed). The cells 2..4
; are FRESH |0> cells (§1.3: growing never maps to cells a shrink hid; C's grown part is indeterminate = 0, §6). a[(k
; & 3) + 1] = 7 stores at cell index (k & 3) + 1 (-O1's two geps; byte = cell for i8), in range (<= 4 < 5) on every
; branch, and in range of C's block too ((k & 3) + 1 < (k & 3) + 2). At free(a): un-copy both loads, pop the store
; made through a' (cell index rail recomputed-free afterwards), undo the realloc to the old size 2 (§1.3: after every
; store made through a' was popped), pop a[k & 1] = v, release the QRAM.
; vla_qram: int a[n] is an alloca of RUN-TIME length n (classical); a[x % n] = y is a quantum-offset store, so a is a
; QRAM of n cells: cqrt_qram_alloc_i32(n) with the host value n. The lowered program is a host program that builds the
; circuit at run time (§0), so the QRAM's size is a run-time parameter of the circuit. The index rail is urem_i32_hl(x,
; n) with the classical n as the literal operand. a[0] is read with load_hl and measured. A VLA's lifetime ends at its
; scope's end (rule 20: llvm.stackrestore or the function return; -O1 emits no stackrestore here), so its clean-up (pop
; the store, free the seed y, uncompute x % n, qram_free) runs at the return, after the measurement, not after the
; last access.
; guarded_global: static int table[8] is a global QRAM (rule 20, 160): a module constructor allocates its 8 cells once.
; The store sits in an arm under the quantum flag x > k (rule 8): its index chain i & 7 is pure and hoisted unguarded
; (rule 9), and the store is ONE cqrt_qram_store_i32_controlled(flag, table, idx, y): under flag = 0 nothing happens and
; its tape slot stays |0> (§1.3). The global persists, so the store is never popped (160); its value seed y, its index
; rail and the flag are functions of parameters and of the untouched registers x, i, and are uncomputed and freed (the
; precondition of a pop no longer matters: there is none). The read table[i & 7] after the merge is -O1's separate
; %15 = and i32 %8, 7 and a QRAM load whose copy-out is the measured result.
source_filename = "realloc_vla_global_guarded.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@table = internal global i32 0, align 4    ; IR: @table = internal global [8 x i32] zeroinitializer  (now holds the QRAM handle of its 8 cells)
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_qram_init_table, ptr null }]    ; IR: program start: the global's storage exists before any entry runs

define internal void @__cq_qram_init_table() {
  %1 = call i32 @cqrt_qram_alloc_i32(i32 8)    ; IR: @table's zeroinitializer: an 8-cell i32 QRAM, all cells |0>
  store i32 %1, ptr @table, align 4    ; IR: the global keeps the array handle (classical)
  ret void
}

define i32 @realloc_shrink(i32 noundef %0, double noundef %1, i8 noundef zeroext %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cqrt_qram_alloc_i8(i32 4)    ; IR: %5 = call @malloc(4): the QRAM a, 4 byte cells |0>
  %6 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)    ; IR: %6 = and i32 %4, 3  [index rail; zext %7 and gep %8 not emitted]
  %7 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: store i8 %2, ptr %8: v as a basis-state handle
  call void @cqrt_qram_store_i8(i32 %5, i32 %6, i32 %7)    ; IR: store i8 %2, ptr %8: a[k & 3] = v
  %8 = call i32 @cqrt_qram_realloc_i8(i32 %5, i32 2)    ; IR: %9 = call @realloc(%5, 2): SHRINK, logical size 2; cells 2, 3 stay physically present (out of range)
  %9 = call i32 @cq_template_and_i32_hl(i32 %4, i32 1)    ; IR: %10 = and i32 %4, 1  [index rail; zext %11 and gep %12 not emitted]
  %10 = call i32 @cqrt_qram_load_i8(i32 %8, i32 %9)    ; IR: %13 = load i8, ptr %12: a[k & 1]  [result rail r]
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %4, i32 1)    ; IR: uncompute %10 (the load is a measured result, never un-copied)
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  ; IR: call @free(%9): the lifetime of a ends
  call void @cqrt_qram_realloc_i8_unc(i32 %8, i32 4)    ; IR: undo the shrink (no store was made through a'): logical size 4
  call void @cqrt_qram_store_i8_unc(i32 %5, i32 %6, i32 %7)    ; IR: pop a[k & 3] = v (its cell was never detached): every cell |0>
  call void @cqrt_free(i32 %7)    ; IR: release the seed v (rule 7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %4, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @cqrt_qram_free(i32 %5)    ; IR: call @free(%9): release the QRAM a
  %11 = call i8 @cqrt_measure_i8(i32 %10)    ; IR: %14 = cq_measure_ui8(%13)
  %12 = zext i8 %11 to i32    ; IR: %15 = zext i8 %14 to i32  (classical)
  ret i32 %12    ; IR: ret i32 %15
}

define i32 @realloc_qsize(i32 noundef %0, double noundef %1, i8 noundef zeroext %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cqrt_qram_alloc_i8(i32 2)    ; IR: %5 = call @malloc(2): the QRAM a, 2 byte cells |0>
  %6 = call i32 @cq_template_and_i32_hl(i32 %4, i32 1)    ; IR: %6 = and i32 %4, 1  [index rail; zext %7 and gep %8 not emitted]
  %7 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: store i8 %2, ptr %8: v as a basis-state handle
  call void @cqrt_qram_store_i8(i32 %5, i32 %6, i32 %7)    ; IR: store i8 %2, ptr %8: a[k & 1] = v
  %8 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)    ; IR: %9 = and i32 %4, 3
  %9 = call i32 @cq_template_add_i32_hl(i32 %8, i32 2)    ; IR: %10 = add nuw nsw i32 %9, 2  [the quantum size rail; zext %11 not emitted]
  %10 = call i32 @cqrt_qram_realloc_i8(i32 %5, i32 5)    ; IR: %12 = call @realloc(%5, %11): QUANTUM size in [2, 5], resized at its upper bound 5; cells 2..4 new |0>
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %8, i32 2)    ; IR: uncompute %10 (the realloc read only its bound)
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  %11 = call i32 @cq_template_add_i32_hl(i32 %8, i32 1)    ; IR: %13 = zext %9; %14 = gep %12, %13; %15 = gep %14, 1: cell index (k & 3) + 1
  %12 = call i32 @cqrt_alloc_i8(i8 7)    ; IR: store i8 7, ptr %15: 7 as a basis-state handle
  call void @cqrt_qram_store_i8(i32 %10, i32 %11, i32 %12)    ; IR: store i8 7, ptr %15: a[(k & 3) + 1] = 7
  %13 = call i32 @cqrt_qram_load_i8(i32 %10, i32 %6)    ; IR: %16 = gep %12, %7; %17 = load i8, ptr %16: a[k & 1]
  %14 = call i32 @cqrt_qram_load_i8_hl(i32 %10, i32 1)    ; IR: %18 = gep %12, 1; %19 = load i8, ptr %18: a[1]
  %15 = call i32 @cq_template_add_i8(i32 %14, i32 %13)    ; IR: %20 = add i8 %19, %17  [result rail r]
  ; IR: call @free(%12): the lifetime of a ends; clean-up in reverse order of its accesses
  call void @cqrt_qram_load_i8_hl_unc(i32 %14, i32 %10, i32 1)    ; IR: un-copy %19
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i8_unc(i32 %13, i32 %10, i32 %6)    ; IR: un-copy %17
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i8_unc(i32 %10, i32 %11, i32 %12)    ; IR: pop a[(k & 3) + 1] = 7 (the store made through a')
  call void @cqrt_free(i32 %12)    ; IR: release the seed 7 (rule 7)
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %8, i32 1)    ; IR: uncompute the cell index (k & 3) + 1
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %4, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cqrt_qram_realloc_i8_unc(i32 %10, i32 2)    ; IR: undo the realloc: cells 2..4 are |0> and dropped
  call void @cqrt_qram_store_i8_unc(i32 %5, i32 %6, i32 %7)    ; IR: pop a[k & 1] = v
  call void @cqrt_free(i32 %7)    ; IR: release the seed v (rule 7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %4, i32 1)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @cqrt_qram_free(i32 %5)    ; IR: call @free(%12): release the QRAM a
  %16 = call i8 @cqrt_measure_i8(i32 %15)    ; IR: %21 = cq_measure_ui8(%20)
  %17 = zext i8 %16 to i32    ; IR: %22 = zext i8 %21 to i32  (classical)
  ret i32 %17    ; IR: ret i32 %22
}

define i32 @vla_qram(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call i32 @cqrt_qram_alloc_i32(i32 %3)    ; IR: %6 = zext i32 %3 to i64; %7 = alloca i32, i64 %6: a QRAM of n cells, n known at run time
  %7 = call i32 @cq_template_urem_i32_hl(i32 %5, i32 %3)    ; IR: %8 = urem i32 %5, %3  [index rail; zext %9 and gep %10 not emitted]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %10: y as a basis-state handle
  call void @cqrt_qram_store_i32(i32 %6, i32 %7, i32 %8)    ; IR: store i32 %2, ptr %10: a[x % n] = y
  %9 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i32 0)    ; IR: %11 = load i32, ptr %7: a[0]  [result rail]
  %10 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %12 = cq_measure_si32(%11)
  ; IR: ret: the VLA's scope ends at the function return (rule 20); its clean-up runs here, after the measurement
  call void @cqrt_qram_store_i32_unc(i32 %6, i32 %7, i32 %8)    ; IR: pop a[x % n] = y (the copy-out a[0] was measured: it stands)
  call void @cqrt_free(i32 %8)    ; IR: release the seed y (rule 7)
  call void @cq_template_urem_i32_hl_unc(i32 %7, i32 %5, i32 %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  call void @cqrt_qram_free(i32 %6)    ; IR: release the QRAM a
  ret i32 %10    ; IR: ret i32 %12
}

define i32 @guarded_global(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %8 = cq_theta_ui32(%3, %4)  [register i]
  call void @cqrt_ry_i32(i32 %8, double %4)    ; IR: %8 = cq_theta_ui32(%3, %4)  [Ry]
  %9 = load i32, ptr @table, align 4    ; IR: @table  (the QRAM handle of the global, classical)
  %10 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %7, i32 %2)    ; IR: %9 = icmp ugt i32 %7, %2  [flag]
  %11 = call i32 @cq_template_and_i32_hl(i32 %8, i32 7)    ; IR: %11 = and i32 %8, 7  [block %10, pure: hoisted unguarded; zext %12 and gep %13 not emitted]
  %12 = call i32 @cqrt_alloc_i32(i32 %5)    ; IR: store i32 %5, ptr %13: y as a basis-state handle
  call void @cqrt_qram_store_i32_controlled(i32 %10, i32 %9, i32 %11, i32 %12)    ; IR: store i32 %5, ptr %13 under %9: table[i & 7] = y iff x > k (never popped: the global persists)
  call void @cqrt_free(i32 %12)    ; IR: release the seed y (basis state; the store copied it)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %8, i32 7)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %10, i32 %7, i32 %2)    ; IR: uncompute %9 after its last controlled gate
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  %13 = call i32 @cq_template_and_i32_hl(i32 %8, i32 7)    ; IR: %15 = and i32 %8, 7  [block %14; zext %16 and gep %17 not emitted]
  %14 = call i32 @cqrt_qram_load_i32(i32 %9, i32 %13)    ; IR: %18 = load i32, ptr %17: table[i & 7]  [result rail]
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %8, i32 7)    ; IR: uncompute %15 (the load is a measured result)
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  %15 = call i32 @cqrt_measure_i32(i32 %14)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %15    ; IR: ret i32 %19  (the QRAM table stays allocated: a global is an output)
}

declare i32 @cqrt_alloc_i8(i8)
declare i8 @cqrt_measure_i8(i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_qram_alloc_i8(i32)
declare i32 @cqrt_qram_realloc_i8(i32, i32)
declare void @cqrt_qram_realloc_i8_unc(i32, i32)
declare void @cqrt_qram_free(i32)
declare void @cqrt_qram_store_i8(i32, i32, i32)
declare void @cqrt_qram_store_i8_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i8(i32, i32)
declare void @cqrt_qram_load_i8_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i32)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32_controlled(i32, i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i8(i32, i32)
declare i32 @cq_template_urem_i32_hl(i32, i32)
declare void @cq_template_urem_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
