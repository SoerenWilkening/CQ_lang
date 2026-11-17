; HAND-WRITTEN. Rules: 20, 21, 5, 7, 4, 3, 2; §1.3 (the bus and its overlay).
; Checked: r = table[(i + 1) & 7] + c (measured, %18 -> %19); the cells of table at exit, read from the bus at
; &table + 4 j: table[j] = (j == (i & 7)) ? v : 0 (its initial host bytes, the zeroinitializer, elsewhere).
; Clean: the store's address chain (and / zext / mul / add: %7..%10), uncomputed and freed right after the store; the
; load's address chain (add / and / zext / mul / add: %12..%16) and the load copy %17, un-copied and uncomputed before
; the measurement.
; Kept: the register i (%6, frozen); the store's tape slot (it holds the displaced 4 cells of table[i & 7]: their prior
; content, 0 on every branch for a first call, earlier calls' values otherwise) and its value rail, the seed %11 = |v> (rule 5 sentence 3, rule 7: a basis state, no qubit); the measured
; result rail %18. One tape slot per call: the kept slots grow with the number of calls.
; Rotations: (Ry, i, ti, 1).
; Expected for global_qram(0, .5, 9, 4): (i + 1) & 7 never equals i & 7, so the load reads a cell the store did not
; write, which still holds its initial 0 on every branch, and r = 4 with probability 1; the 4 bytes at
; &table + 4 (i & 7) hold 9 on each branch of i.
; ONE BUS (rule 20): `static int table[8]` is an ordinary global at its host address. Nothing is allocated, seeded or
; registered for it (no constructor, no handle cell, no QRAM of its own): its cells are on the one bus M through the
; overlay and start HOST, holding the zeroinitializer's host bytes. m = __cq_mem() is fetched once at function entry.
; @table is not isConstant, so it is not host-resident and both accesses are bus accesses (rule 20); the indices are
; tainted, so each address is a rail and the plain (not _hl) forms are used. Nothing is known about an
; address at compile time: each getelementptr with a tainted index is 64-bit template arithmetic into an address
; rail: the index rail brought to i64 (-O1's zext nneg, the zext template), scaled by mul_i64_hl(., 4) and added to
; the classical base ptrtoint (ptr @table to i64) by add_i64_hl. No index is narrowed, bounded or checked.
; THE STORE is ONE qram_store_i32 at the address rail of &table[i & 7] with the value v as the seed alloc_i32(v) (a
; value is always a handle). It is KEPT (rule 5 sentence 3): no _unc exists, its tape slot and its seed stay. The
; global persists after the call: the store's cells are the program's visible state, and a later call or host code
; reads them through the same bus. The store's address rail is template garbage, uncomputed right after the store
; together with the chain that produced it (its last reader is the store).
; THE LOAD is ONE qram_load_i32 at the address rail of &table[(i + 1) & 7] -> a fresh rail. No memory version change
; follows it in this function and its only consumer, the add, is measured, so the copy is un-copied right after the
; add (rule 5 sentence 1) and freed; its address rail outlives the _unc and is uncomputed after it.
; `static int slots[4]` of the C source is gone from the .O1.ll: slots[1] = c is forwarded to its only read and the
; global is dropped as dead, so there is no access to lower.
; Regenerated 2026-11-05 for the one-bus memory model (the 2026-11-02 version allocated a per-object QRAM with
; cqrt_qram_alloc_host_i32 in a module constructor, kept its handle in @table.qram, used logical i32 indices and freed
; the store's value handle).
source_filename = "global_qram.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@table = internal unnamed_addr global [8 x i32] zeroinitializer, align 16    ; IR: @table = internal global [8 x i32] zeroinitializer  (unchanged: its host bytes are the bus cells, rule 20)

define i32 @global_qram(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: (none)  [m: the one bus, fetched once at function entry]
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register i]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 7)    ; IR: %6 = and i32 %5, 7
  %8 = call i32 @cq_template_zext_i32_to_i64(i32 %7)    ; IR: %7 = zext nneg i32 %6 to i64
  %9 = call i32 @cq_template_mul_i64_hl(i32 %8, i64 4)    ; IR: %8 = getelementptr inbounds [8 x i32], ptr @table, i64 0, i64 %7  [index scaled by sizeof(i32)]
  %10 = call i32 @cq_template_add_i64_hl(i32 %9, i64 ptrtoint (ptr @table to i64))    ; IR: %8 = getelementptr  [+ the classical base: the address rail of &table[i & 7]]
  %11 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %8  [the value is always a handle: the seed |v>, kept with the store (rule 7)]
  call void @cqrt_qram_store_i32(i32 %5, i32 %10, i32 %11)    ; IR: store i32 %2, ptr %8, align 4  [bus store at an address rail; kept: no _unc, its tape slot and its seed stay (rule 5)]
  call void @cq_template_add_i64_hl_unc(i32 %10, i32 %9, i64 ptrtoint (ptr @table to i64))    ; IR: uncompute %8  [the store is the address rail's last reader (rule 20)]
  call void @cqrt_free(i32 %10)    ; IR: release the %8 address rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %9, i32 %8, i64 4)    ; IR: uncompute %8 (the scaled index)
  call void @cqrt_free(i32 %9)    ; IR: release the scaled index (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %8, i32 %7)    ; IR: uncompute %7
  call void @cqrt_free(i32 %8)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 7)    ; IR: uncompute %6
  call void @cqrt_free(i32 %7)    ; IR: release the %6 rail (|0>)
  %12 = call i32 @cq_template_add_i32_hl(i32 %6, i32 1)    ; IR: %9 = add i32 %5, 1
  %13 = call i32 @cq_template_and_i32_hl(i32 %12, i32 7)    ; IR: %10 = and i32 %9, 7
  %14 = call i32 @cq_template_zext_i32_to_i64(i32 %13)    ; IR: %11 = zext nneg i32 %10 to i64
  %15 = call i32 @cq_template_mul_i64_hl(i32 %14, i64 4)    ; IR: %12 = getelementptr inbounds [8 x i32], ptr @table, i64 0, i64 %11  [index scaled by sizeof(i32)]
  %16 = call i32 @cq_template_add_i64_hl(i32 %15, i64 ptrtoint (ptr @table to i64))    ; IR: %12 = getelementptr  [+ the classical base: the address rail of &table[(i + 1) & 7]]
  %17 = call i32 @cqrt_qram_load_i32(i32 %5, i32 %16)    ; IR: %13 = load i32, ptr %12, align 4  [bus load at an address rail: a fresh rail ^= the 4 cells]
  %18 = call i32 @cq_template_add_i32_hl(i32 %17, i32 %3)    ; IR: %14 = add nsw i32 %13, %3  [result rail]
  call void @cqrt_qram_load_i32_unc(i32 %17, i32 %5, i32 %16)    ; IR: un-copy %13 (no memory version change since the load)
  call void @cqrt_free(i32 %17)    ; IR: release the %13 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %16, i32 %15, i64 ptrtoint (ptr @table to i64))    ; IR: uncompute %12  [the address rail outlives its load's _unc (rule 20)]
  call void @cqrt_free(i32 %16)    ; IR: release the %12 address rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %15, i32 %14, i64 4)    ; IR: uncompute %12 (the scaled index)
  call void @cqrt_free(i32 %15)    ; IR: release the scaled index (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %14, i32 %13)    ; IR: uncompute %11
  call void @cqrt_free(i32 %14)    ; IR: release the %11 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %12, i32 7)    ; IR: uncompute %10
  call void @cqrt_free(i32 %13)    ; IR: release the %10 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %12, i32 %6, i32 1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  %19 = call i32 @cqrt_measure_i32(i32 %18)    ; IR: %15 = cq_measure_si32(%14)
  ret i32 %19    ; IR: ret i32 %15  (the cells of table stay on the bus: a global is program state)
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
