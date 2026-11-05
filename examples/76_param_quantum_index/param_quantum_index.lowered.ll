; HAND-WRITTEN. Rules: 2, 4, 5, 20, 21 (a load through a classical pointer parameter at a quantum index: one bus load
; at an address rail).
; Checked: param_bounded: t[x % n] (measured, %12 -> %13). param_unbounded: t[x] (measured, %10 -> %11).
; Clean: param_bounded: the address chain x % n, its zext, the scaled index, the address rail (%8..%11), each uncomputed
; and freed right after the load. param_unbounded: the zext of x, the scaled index, the address rail (%7..%9), likewise.
; Kept: the register x in each function (%7 i32 / %6 i8, rotated); each load copy (%12 / %10, measured, rule 2: never
; un-copied, it stays allocated).
; Rotations: param_bounded: (Ry, x, th, 1). param_unbounded: (Ry, x, th, 1).
; ONE BUS (rule 20): the pointer parameter is an integer, its run-time address, a classical i64 (ptrtoint once at
; entry, after __cq_mem(); rule 21). Nothing is known about what it points to: not the object, its length, or whether
; the index lies inside it, and none of that is asked. The getelementptr with a tainted index is 64-bit template
; arithmetic into an address rail: -O1's zext of the index to i64 (zext_i32_to_i64 / zext_i8_to_i64), mul_i64_hl by
; the element size 4, add_i64_hl of the classical base. The load is ONE qram_load_i32 at that rail; the cells are
; HOST (the driver's host array) and are read at the access through the overlay, nothing seeded. No index is
; narrowed, bounded or checked: x % n and a bare 8-bit x are the same construction, and an address past the object
; reads whatever the bus holds there (§2 totalizes an address that is not memory). The load copy is measured, so it is
; never un-copied and the load is its address rail's last reader: the chain is uncomputed right after the load, before
; the measurement.
source_filename = "param_quantum_index.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @param_bounded(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %6 = ptrtoint ptr %2 to i64    ; IR: (no instruction) t: the run-time address in %2, a classical i64 (rule 21)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_urem_i32_hl(i32 %7, i32 %3)    ; IR: %6 = urem i32 %5, %3
  %9 = call i32 @cq_template_zext_i32_to_i64(i32 %8)    ; IR: %7 = zext i32 %6 to i64
  %10 = call i32 @cq_template_mul_i64_hl(i32 %9, i64 4)    ; IR: %8 = getelementptr inbounds i32, ptr %2, i64 %7  [the tainted index scaled by the element size (rule 20)]
  %11 = call i32 @cq_template_add_i64_hl(i32 %10, i64 %6)    ; IR: %8 = getelementptr  [+ the classical base: the address rail of &t[x % n]]
  %12 = call i32 @cqrt_qram_load_i32(i32 %5, i32 %11)    ; IR: %9 = load i32, ptr %8, align 4  [a bus load at an address rail: fresh rail ^= the 4 cells; measured below, so never un-copied (rules 2, 5)]
  call void @cq_template_add_i64_hl_unc(i32 %11, i32 %10, i64 %6)    ; IR: uncompute %8  [the load is the address rail's last reader (rule 20)]
  call void @cqrt_free(i32 %11)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %10, i32 %9, i64 4)    ; IR: uncompute %8 (the scaled index)
  call void @cqrt_free(i32 %10)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %9, i32 %8)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_urem_i32_hl_unc(i32 %8, i32 %7, i32 %3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  %13 = call i32 @cqrt_measure_i32(i32 %12)    ; IR: %10 = cq_measure_si32(%9)
  ret i32 %13    ; IR: ret i32 %10
}

define i32 @param_unbounded(i8 noundef zeroext %0, double noundef %1, ptr nocapture noundef readonly %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = ptrtoint ptr %2 to i64    ; IR: (no instruction) t: the run-time address in %2, a classical i64 (rule 21)
  %6 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %4 = cq_theta_ui8(%0, %1)  [register x, 8 bits]
  call void @cqrt_ry_i8(i32 %6, double %1)    ; IR: %4 = cq_theta_ui8(%0, %1)  [Ry]
  %7 = call i32 @cq_template_zext_i8_to_i64(i32 %6)    ; IR: %5 = zext i8 %4 to i64
  %8 = call i32 @cq_template_mul_i64_hl(i32 %7, i64 4)    ; IR: %6 = getelementptr inbounds i32, ptr %2, i64 %5  [the tainted index scaled by the element size (rule 20)]
  %9 = call i32 @cq_template_add_i64_hl(i32 %8, i64 %5)    ; IR: %6 = getelementptr  [+ the classical base: the address rail of &t[x]]
  %10 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %9)    ; IR: %7 = load i32, ptr %6, align 4  [a bus load at an address rail, no bound: x up to 255 reaches past the driver's 4 entries, read as the bus holds it (§2); measured below, so never un-copied (rules 2, 5)]
  call void @cq_template_add_i64_hl_unc(i32 %9, i32 %8, i64 %5)    ; IR: uncompute %6  [the load is the address rail's last reader (rule 20)]
  call void @cqrt_free(i32 %9)    ; IR: release the %6 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %8, i32 %7, i64 4)    ; IR: uncompute %6 (the scaled index)
  call void @cqrt_free(i32 %8)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i8_to_i64_unc(i32 %7, i32 %6)    ; IR: uncompute %5
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  %11 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %11    ; IR: ret i32 %8
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i8(i32, double)
declare i32 @cq_template_urem_i32_hl(i32, i32)
declare void @cq_template_urem_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_zext_i8_to_i64(i32)
declare void @cq_template_zext_i8_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
