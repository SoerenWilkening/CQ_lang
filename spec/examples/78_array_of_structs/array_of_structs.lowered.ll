; HAND-WRITTEN. Rules: 20 (witness: a classical table read at a quantum index is a bus load at an address rail; no
; QROM), 21, 5, 4, 3, 2.
; Checked: p[x & 7].v + p[x & 7].k, the returned double (the fadd rail %15 -> %16).
; Clean: the index rail x & 7 (%7), its zext (%8), the scaled index (%9), the two address rails (%10 = &p[x & 7] for k,
; %11 = &p[x & 7].v for v), the two load copies (%12 for v, %13 for k) and the sitofp of k (%14), uncomputed in LIFO
; order and freed before the measurement.
; Kept: x (%6, the rotated register) and the sum (%15, measured).
; Rotations: (Ry, x, th, 1).
; Expected for the driver array_of_structs(0, .5, P8): element i holds k = i + 1, v = i + .5, so the sum is 2i + 1.5 at
; i = x & 7.
; ONE BUS (rule 20): nothing is known about an address, so the classical table behind the parameter p is not told apart
; from any other memory: its cells are HOST and each load reads the host bytes at the access (§1.3); nothing is
; allocated, seeded or registered for it. p is not a constant global or an alloca, so it is not host-resident, and the
; index is a rail anyway. No QROM exists.
; ADDRESS ARITHMETIC (rules 20, 21): the classical base is p's run-time address, ptrtoint of the argument, placed once
; at function entry after __cq_mem() (as 206). -O1's zext of the index to i64 is a tainted cast and is the zext
; template. The getelementptr %struct.P (size 16) is mul_i64_hl(., 16) and add_i64_hl(., p): the address rail of
; p[x & 7], which is also the address of field k (offset 0). The getelementptr i8 (+8) has a tainted base and only a
; constant offset: add_i64_hl(., 8), no scale, the address rail of field v. Each getelementptr emits its own template;
; the struct layout enters only as the stride 16 and the byte offset 8 that -O1 already wrote. No index is narrowed,
; bounded or checked. -O1 reads v before k; the lowering keeps that order: ONE qram_load_f64 at the v rail and ONE
; qram_load_i32 at the k rail (rule 20: one call per access of store-size S cells, 8 and 4).
; UNCOMPUTE (rule 5 sentence 1): no memory version change follows the loads, and their last reader, the fadd (through
; the sitofp for k), is measured and never uncomputed, so both copies are un-copied right after the sitofp's _unc,
; before the measurement, while the cells still hold what was loaded; each address rail outlives its load's _unc
; (rule 20), the v rail before the k rail it was computed from, then the scale, the zext and the and.
source_filename = "array_of_structs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @array_of_structs(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) {
  %4 = call i32 @__cq_mem()    ; IR: (none)  [m: the one bus, fetched once at function entry]
  %5 = ptrtoint ptr %2 to i64    ; IR: %2 as its run-time address (the classical base p, rule 21)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 7)    ; IR: %5 = and i32 %4, 7  [index, range [0, 8)]
  %8 = call i32 @cq_template_zext_i32_to_i64(i32 %7)    ; IR: %6 = zext nneg i32 %5 to i64
  %9 = call i32 @cq_template_mul_i64_hl(i32 %8, i64 16)    ; IR: %7 = getelementptr inbounds %struct.P, ptr %2, i64 %6  [the tainted index scaled by the struct size 16 (rule 20)]
  %10 = call i32 @cq_template_add_i64_hl(i32 %9, i64 %5)    ; IR: %7 = getelementptr  [+ the classical base p: the address rail of &p[x & 7], field k at offset 0]
  %11 = call i32 @cq_template_add_i64_hl(i32 %10, i64 8)    ; IR: %8 = getelementptr inbounds i8, ptr %7, i64 8  [tainted base + the constant offset: the address rail of &p[x & 7].v]
  %12 = call i32 @cqrt_qram_load_f64(i32 %4, i32 %11)    ; IR: %9 = load double, ptr %8  [bus load at an address rail: fresh rail ^= the 8 cells (HOST)]
  %13 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %10)    ; IR: %10 = load i32, ptr %7  [bus load at an address rail: fresh rail ^= the 4 cells (HOST)]
  %14 = call i32 @cq_template_sitofp_i32_to_f64(i32 %13)    ; IR: %11 = sitofp i32 %10 to double
  %15 = call i32 @cq_template_fadd_f64(i32 %12, i32 %14)    ; IR: %12 = fadd double %9, %11  [result rail]
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %14, i32 %13)    ; IR: uncompute %11
  call void @cqrt_free(i32 %14)    ; IR: release the %11 rail (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %13, i32 %4, i32 %10)    ; IR: un-copy %10  [after its last reader; no memory version change since the load (rule 5)]
  call void @cqrt_free(i32 %13)    ; IR: release the %10 rail (|0>)
  call void @cqrt_qram_load_f64_unc(i32 %12, i32 %4, i32 %11)    ; IR: un-copy %9  [after its last reader, the fadd (measured, no _unc)]
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %11, i32 %10, i64 8)    ; IR: uncompute %8  [the address rail outlives its access (rule 20)]
  call void @cqrt_free(i32 %11)    ; IR: release the %8 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %10, i32 %9, i64 %5)    ; IR: uncompute %7  [the address rail outlives its access and the %8 rail]
  call void @cqrt_free(i32 %10)    ; IR: release the %7 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %9, i32 %8, i64 16)    ; IR: uncompute %7 (the scaled index)
  call void @cqrt_free(i32 %9)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %8, i32 %7)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 7)    ; IR: uncompute %5
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  %16 = call double @cqrt_measure_f64(i32 %15)    ; IR: %13 = cq_measure_f64(%12)
  ret double %16    ; IR: ret double %13
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
declare i32 @cqrt_qram_load_f64(i32, i32)
declare void @cqrt_qram_load_f64_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cq_template_sitofp_i32_to_f64(i32)
declare void @cq_template_sitofp_i32_to_f64_unc(i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
