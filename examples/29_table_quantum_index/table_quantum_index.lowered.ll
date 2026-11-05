; HAND-WRITTEN. Rules: 20, 21, 5, 4, 2, 3; §1.3 (the overlay).
; Checked: v = TABLE[x & 7] (measured, the load copy %9 -> %10).
; Clean: the index rail %5 = x & 7, its zext %6, the scaled index %7 and the address rail %8, uncomputed and freed
; right after the load, before the measurement.
; Kept: x (%4, the rotated register) and the load copy %9 (measured, rule 2: never un-copied, it stays allocated);
; no bus store, so no tape slot.
; Rotations: (Ry, x, th, 1).
; ONE BUS (rule 20): a table of classical data read at a quantum index is an ordinary bus load at an ADDRESS RAIL; no
; QROM exists. @TABLE is a constant global, but it is host-resident only through getelementptrs with UNTAINTED indices;
; here the index is the rail x & 7, so the read is the bus load qram_load_i32 at the address rail. @TABLE stays an
; ordinary LLVM global at its host address; nothing is allocated, seeded or registered for it, and its cells are HOST:
; the load reads the host bytes at the access (§1.3). m = __cq_mem() is called once, at function entry (§5).
; ADDRESS ARITHMETIC (rule 20): the getelementptr with a tainted index is 64-bit template arithmetic: -O1's zext to i64
; (zext_i32_to_i64), scaled by mul_i64_hl(., 4) (sizeof(int)) and added to the classical base by
; add_i64_hl(., ptrtoint @TABLE) (the constant index 0 contributes 0). No index is narrowed, bounded or checked.
; UNCOMPUTE (rules 5, 20): the load copy is measured, so the load is the address rail's last reader and the address
; chain (add, mul, zext) is uncomputed right after it, then the and that fed the zext; the rotated register x stays.
source_filename = "table_quantum_index.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@TABLE = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @table_quantum_index(i32 noundef %0, double noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: (none)  [m: the one bus, fetched once at function entry]
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %3 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 7)    ; IR: %4 = and i32 %3, 7
  %6 = call i32 @cq_template_zext_i32_to_i64(i32 %5)    ; IR: %5 = zext nneg i32 %4 to i64  [the i64 index rail]
  %7 = call i32 @cq_template_mul_i64_hl(i32 %6, i64 4)    ; IR: %6 = getelementptr @TABLE, 0, %5  [index scaled by sizeof(i32)]
  %8 = call i32 @cq_template_add_i64_hl(i32 %7, i64 ptrtoint (ptr @TABLE to i64))    ; IR: %6 = getelementptr @TABLE, 0, %5  [address rail: &TABLE + 4 (x & 7)]
  %9 = call i32 @cqrt_qram_load_i32(i32 %3, i32 %8)    ; IR: %7 = load i32, ptr %6  [bus load at an address rail; HOST cells of a constant global; measured below, so never un-copied (rules 2, 5)]
  call void @cq_template_add_i64_hl_unc(i32 %8, i32 %7, i64 ptrtoint (ptr @TABLE to i64))    ; IR: uncompute the address rail of %6  [the load is its last reader (rule 20)]
  call void @cqrt_free(i32 %8)    ; IR: release the %6 address rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %7, i32 %6, i64 4)    ; IR: uncompute the scaled index of %6
  call void @cqrt_free(i32 %7)    ; IR: release the scaled index (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %6, i32 %5)    ; IR: uncompute %5
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 7)    ; IR: uncompute %4
  call void @cqrt_free(i32 %5)    ; IR: release the %4 rail (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %10    ; IR: ret i32 %8
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
