; HAND-WRITTEN. Rules: 20, 4, 2, 5, 7, §1.3 (QRAM contract).
; Checked: r = table[(i + 1) & 7] + c (measured).
; Clean: the index rails (i & 7, i + 1, (i + 1) & 7), the load's copy-out rail and the value handle of v.
; Kept: the register i (frozen); the global QRAM `table` with the store LEFT IN PLACE (an output: the next call reads
;       it, so its store is never popped and the array is never freed); the unpopped store's tape slot (holding the
;       displaced cell, entangled with i; §1.3: an unpopped store keeps its slot allocated), one more slot per call, so
;       the kept slots grow with the number of calls; the measured result rail.
; Rotations: Ry(ti) on i.
; `static int table[8]` is a global with internal linkage written and read at a QUANTUM index: by rule 20 the whole
; object is a QRAM, one call per access (§1.3). A global's storage exists for the whole program, so its 8 cells are
; allocated ONCE, before any entry runs: a module constructor (@llvm.global_ctors) calls cqrt_qram_alloc_host_i32(@table,
; 8): the bus whose cells start as the host object's contents at program start (here the zeroinitializer: all |0>; the
; compiler never reads an initializer, so an extern of unknown extent takes the same call with n = 0, rule 20). The
; global keeps its definition (its storage is what seeds the bus) and the array handle lives in the compiler-made
; @table.qram (a classical word, like the slot globals of 67 / 71). The entry loads the handle and issues the accesses: the store is ONE
; cqrt_qram_store_i32(table, idx, val) with the logical-i32 index rail i & 7 (-O1's zext to i64 and the gep scaling are
; address arithmetic and are not emitted) and the classical v materialised as a basis-state handle (the contract: a value
; is always a handle); the load is ONE cqrt_qram_load_i32(table, idx2) -> fresh rail with idx2 = (i + 1) & 7. The
; global PERSISTS: table[i & 7] = v is the program's visible state after the call, so the store is NOT popped: its
; fresh tape slot (§1.3: the displaced cell[i & 7] is swapped into it, then the cell ^= v) stays allocated for the rest
; of the program, a Kept item, and every call adds one such slot; cqrt_qram_free never runs; the v handle is a seed rail (rule 7:
; minted from a parameter, never written; the store copies it) and is freed once nothing reads it. Everything else is
; uncomputed LIFO before the measurement. `static int slots[4]` of the C source is gone from the .O1.ll: slots[1] = c
; is forwarded to its only read and the global is dropped as dead, so there is no slot array to lower (rule 20's slot
; array form for a classically indexed global is witnessed by 67 / 71).
; Regenerated 2026-11-02 (the first version called cqrt_qram_alloc_i32(8) and kept the handle in @table itself).
source_filename = "global_qram.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@table = internal unnamed_addr global [8 x i32] zeroinitializer, align 16    ; IR: @table = internal global [8 x i32] zeroinitializer  (kept as it is: the host object the constructor seeds the bus from)
@table.qram = internal global i32 0, align 4    ; IR: (compiler-made: holds the QRAM handle of @table's 8 cells, set by the constructor below)
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_qram_init_table, ptr null }]    ; IR: program start: the global's storage comes into existence before any entry runs

define internal void @__cq_qram_init_table() {
  %1 = call i32 @cqrt_qram_alloc_host_i32(ptr @table, i64 8)    ; IR: @table's storage: an 8-cell i32 QRAM whose cells start as the host object's contents (the zeroinitializer: all |0>), allocated once for the program
  store i32 %1, ptr @table.qram, align 4    ; IR: the handle cell keeps the array handle (classical)
  ret void
}

define i32 @global_qram(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register i]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = load i32, ptr @table.qram, align 4    ; IR: @table  (the QRAM handle of the global, classical)
  %7 = call i32 @cq_template_and_i32_hl(i32 %5, i32 7)    ; IR: %6 = and i32 %5, 7  [the store's index rail; %7 = zext to i64 and the gep %8 are not emitted]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %8: the classical v as a basis-state handle (a store value is always a handle)
  call void @cqrt_qram_store_i32(i32 %6, i32 %7, i32 %8)    ; IR: store i32 %2, ptr %8: table[i & 7] = v  (one access; the global persists, so this store is never popped and its tape slot stays allocated: Kept)
  %9 = call i32 @cq_template_add_i32_hl(i32 %5, i32 1)    ; IR: %9 = add i32 %5, 1
  %10 = call i32 @cq_template_and_i32_hl(i32 %9, i32 7)    ; IR: %10 = and i32 %9, 7  [the load's index rail; %11 = zext and the gep %12 are not emitted]
  %11 = call i32 @cqrt_qram_load_i32(i32 %6, i32 %10)    ; IR: %13 = load i32, ptr %12: table[(i + 1) & 7]  (copy-out into a fresh rail, cells preserved)
  %12 = call i32 @cq_template_add_i32_hl(i32 %11, i32 %3)    ; IR: %14 = add nsw i32 %13, %3  [result rail]
  call void @cqrt_qram_load_i32_unc(i32 %11, i32 %6, i32 %10)    ; IR: un-copy %13 against the (persisting) cells
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %9, i32 7)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %5, i32 1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cqrt_free(i32 %8)    ; IR: release the value handle (basis state v; the store copied it into the cell and is never popped, rule 7)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %5, i32 7)    ; IR: uncompute %6 (the store's index: a function of i, which stays)
  call void @cqrt_free(i32 %7)    ; IR: release the %6 rail (|0>)
  %13 = call i32 @cqrt_measure_i32(i32 %12)    ; IR: %15 = cq_measure_si32(%14)
  ret i32 %13    ; IR: ret i32 %15  (the QRAM table stays allocated: a global is an output)
}

declare i32 @cqrt_qram_alloc_host_i32(ptr, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
