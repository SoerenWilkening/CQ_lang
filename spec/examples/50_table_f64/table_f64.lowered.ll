; HAND-WRITTEN. Rules: 20 (witness: a constant table of doubles read at an address rail is the bus load), 21, 5, 4,
; 3, 2.
; Checked: r = x * c + HALF[sb] (%12, measured as %13).
; Clean: the bitcast of x (%6), the sign-bit index lshr (%7), the scaled index (%8), the address rail &HALF + 8 sb
; (%9), the bus load copy HALF[sb] (%10, un-copied by its load _unc) and the product rail x * c (%11), all uncomputed
; and freed before the measurement.
; Kept: x (%5, the rotated register, a source of r) and r (%12, measured).
; Rotations: (Ry_f64, x, th, 1).
; ONE BUS (rule 20): a constant table of doubles read at a quantum index is an ordinary bus load; no QROM exists.
; @HALF stays an ordinary LLVM global at its host address; nothing is allocated, seeded or registered for it, and its
; cells are HOST: the load reads the host bytes at the access (§1.3). A constant global is host-resident only through
; getelementptrs with UNTAINTED indices; here the index is a rail, so the load is the bus load. m = __cq_mem() is
; called once, at entry (§5).
; ADDRESS ARITHMETIC (rules 20, 21): the C index expression is sb = (unsigned)(bits >> 63); -O1 folds its trunc/zext
; pair into the i64 shift itself, so the i64 index rail is the lshr result and no cast is emitted. The getelementptr is
; 64-bit template arithmetic: the index rail scaled by mul_i64_hl(., 8) (sizeof(double)) and added to the classical
; base, the constant expression ptrtoint (ptr @HALF to i64), by add_i64_hl. The access is ONE qram_load_f64 of the
; 8 cells at that address rail (store-size(double) = 8); no index is narrowed, bounded or checked.
; UNCOMPUTE (rule 5 sentence 1): the load copy's only reader is the fadd, whose result is measured and has no _unc to
; wait for, and no memory version change follows the load in this function, so the copy is un-copied right after its
; last reader (the cells still hold what the load read) and freed; the address rail outlives that _unc and is then
; uncomputed with its scaled index (rule 20), before the lshr and the bitcast that produced the index.
; The fmuladd that consumes the loaded entry is UNFUSED (§2, cf. 14): fmul_f64_hl of x and the literal c into a fresh
; product rail, then fadd_f64 of the product and the loaded entry (its quantum addend) into the result rail; the
; product rail is uncomputed by its fmul _unc and freed (rule 5).
; NOT SHOWN (§5): table_f64 is externally visible but its address is never taken, so its clone-table row, table clone,
; _t_ctl and their twins (rule 19, §1.3) are omitted; they emit no gate and §6 does not compare them.
source_filename = "table_f64.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@HALF = internal unnamed_addr constant [2 x double] [double 5.000000e-01, double -5.000000e-01], align 16    ; IR: @HALF: the classical table, an ordinary global at its host address (HOST cells)

define double @table_f64(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: (none)  [m: the one bus, fetched once at function entry]
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @cq_template_bitcast_f64_to_i64(i32 %5)    ; IR: %5 = bitcast double %4 to i64
  %7 = call i32 @cq_template_lshr_i64_hl(i32 %6, i64 63)    ; IR: %6 = lshr i64 %5, 63  [the i64 index rail]
  %8 = call i32 @cq_template_mul_i64_hl(i32 %7, i64 8)    ; IR: %7 = getelementptr [2 x double], @HALF, 0, %6  [index scaled by sizeof(double)]
  %9 = call i32 @cq_template_add_i64_hl(i32 %8, i64 ptrtoint (ptr @HALF to i64))    ; IR: %7 = getelementptr @HALF, 0, %6  [address rail: &HALF + 8 sb]
  %10 = call i32 @cqrt_qram_load_f64(i32 %4, i32 %9)    ; IR: %8 = load double, ptr %7  [bus load at an address rail: fresh rail ^= the 8 HOST cells of the constant global]
  %11 = call i32 @cq_template_fmul_f64_hl(i32 %5, double %2)    ; IR: %9 = llvm.fmuladd.f64(%4, %2, %8)  [product x * c]
  %12 = call i32 @cq_template_fadd_f64(i32 %11, i32 %10)    ; IR: %9 = llvm.fmuladd.f64(%4, %2, %8)  [sum + HALF[sb], result rail]
  call void @cq_template_fmul_f64_hl_unc(i32 %11, i32 %5, double %2)    ; IR: uncompute the %9 product
  call void @cqrt_free(i32 %11)    ; IR: release the product rail (|0>)
  call void @cqrt_qram_load_f64_unc(i32 %10, i32 %4, i32 %9)    ; IR: un-copy %8 (its last reader %9 is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %9, i32 %8, i64 ptrtoint (ptr @HALF to i64))    ; IR: uncompute the address rail of %7  [it outlives the load's _unc (rule 20)]
  call void @cqrt_free(i32 %9)    ; IR: release the %7 address rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %8, i32 %7, i64 8)    ; IR: uncompute the scaled index of %7
  call void @cqrt_free(i32 %8)    ; IR: release the scaled index (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %7, i32 %6, i64 63)    ; IR: uncompute %6
  call void @cqrt_free(i32 %7)    ; IR: release the %6 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %6, i32 %5)    ; IR: uncompute %5
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  %13 = call double @cqrt_measure_f64(i32 %12)    ; IR: %10 = cq_measure_f64(%9)
  ret double %13    ; IR: ret double %10
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_bitcast_f64_to_i64(i32)
declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_f64(i32, i32)
declare void @cqrt_qram_load_f64_unc(i32, i32, i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cqrt_free(i32)
declare double @cqrt_measure_f64(i32)
