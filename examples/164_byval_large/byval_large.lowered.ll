; HAND-WRITTEN. Rules: 26, 20, 18, 2, 4, 5, §1.4.
; Checked: sum3(p, c) = p.a + p.b * c + p.c (measured, both entries).
; Clean: every clone-internal rail (the clone copies its result out and uncomputes its chain).
; Kept: the rotated field registers p.a (and p.b in _two), frozen, each living in its byval slot cell; the measured
;       result rail.
; Rotations: Ry(tx) on p.a; Ry(tx) on p.a and Ry(ty) on p.b.
; A 24-byte struct passed BY VALUE travels as a `byval` pointer to a caller-made copy: -O1 builds the copy in an alloca
; field by field, rotates the field VALUE (cq_theta on the plain i64) and stores the result back into the cell. By rule
; 26 the byval pointer is a SLOT parameter (rule 20): the copy is a record of one cell per field, kind by what is
; stored (129): a rotated field is a 4-byte HANDLE cell, an untouched field stays a classical i64 cell (classical
; fields stay classical). byval_large_one: { i32, i64, i64 } (a quantum; b, c classical; the record's own offsets are
; 8 and 16, the same as the original's); byval_large_two: { i32, i32, i64 } (a, b quantum; c classical; offsets 4
; and 8). The classical seed store of x0 into cell a and the cq_theta that overwrites it collapse into one mint: the
; register is cqrt_alloc_i64(x0) + Ry and its HANDLE is what the cell holds (129's ptr_select_rmw). The clone takes the
; slot pointer and c (§1.4: one digit per field of the slot, 100 / 110, then c): __cq_q_sum3_1000 and __cq_q_sum3_1100.
; It loads the handles (no gate) and the classical cells, forms the sum out of place (the classical product b * c
; stays classical in _one and is a template in _two), copies the result into a fresh rail and uncomputes its chain
; (rule 18). The result is measured directly by the caller, so no twin runs (51 / 71) and no slot is written by the
; callee (readonly byval), so the twin would take no old slot handles.
source_filename = "byval_large.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @byval_large_one(i64 noundef %0, double noundef %1, i64 noundef %2, i64 noundef %3) {
  %5 = alloca { i32, i64, i64 }, align 8    ; IR: %5 = alloca %struct.big  (the byval copy: a handle cell for a, classical i64 cells for b and c)
  %6 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: store i64 %0, ptr %5 (the seed) and %8 = cq_theta_sl(%0, %1): one mint  [register p.a]
  call void @cqrt_ry_i64(i32 %6, double %1)    ; IR: %8 = cq_theta_sl(%0, %1)  [Ry]
  store i32 %6, ptr %5, align 8    ; IR: store i64 %8, ptr %5  (the handle into cell a)
  %7 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %6 = getelementptr %5, 8  (cell b)
  store i64 %2, ptr %7, align 8    ; IR: store i64 %2, ptr %6  (classical)
  %8 = getelementptr inbounds i8, ptr %5, i64 16    ; IR: %7 = getelementptr %5, 16  (cell c)
  store i64 %3, ptr %8, align 8    ; IR: store i64 %3, ptr %7  (classical)
  %9 = call fastcc i32 @__cq_q_sum3_1000(ptr %5, i64 %3)    ; IR: %9 = call @sum3(byval %5, %3): clone for mask (slot a quantum, b, c classical; c classical); the result rail
  %10 = call i64 @cqrt_measure_i64(i32 %9)    ; IR: %10 = cq_measure_sl(%9)
  ret i64 %10    ; IR: llvm.lifetime.end(%5) (nothing); ret i64 %10
}

define internal fastcc i32 @__cq_q_sum3_1000(ptr %0, i64 %1) {
  %3 = load i32, ptr %0, align 8    ; IR: %3 = load i64, ptr %0  (the handle of p.a, no gate)
  %4 = getelementptr inbounds i8, ptr %0, i64 8    ; IR: %4 = getelementptr %0, 8  (cell b)
  %5 = load i64, ptr %4, align 8    ; IR: %5 = load i64, ptr %4  (classical p.b)
  %6 = mul nsw i64 %5, %1    ; IR: %6 = mul nsw i64 %5, %1  (classical)
  %7 = call i32 @cq_template_add_i64_hl(i32 %3, i64 %6)    ; IR: %7 = add nsw i64 %6, %3  (commutative: handle first)
  %8 = getelementptr inbounds i8, ptr %0, i64 16    ; IR: %8 = getelementptr %0, 16  (cell c)
  %9 = load i64, ptr %8, align 8    ; IR: %9 = load i64, ptr %8  (classical p.c)
  %10 = call i32 @cq_template_add_i64_hl(i32 %7, i64 %9)    ; IR: %10 = add nsw i64 %7, %9
  %11 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: ret i64 %10  [result rail of the call]
  call void @cqrt_copy_i64(i32 %10, i32 %11)    ; IR: copy the result out
  call void @cq_template_add_i64_hl_unc(i32 %10, i32 %7, i64 %9)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %7, i32 %3, i64 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  ret i32 %11    ; IR: ret i64 %10
}

define i64 @byval_large_two(i64 noundef %0, double noundef %1, i64 noundef %2, double noundef %3, i64 noundef %4) {
  %6 = alloca { i32, i32, i64 }, align 8    ; IR: %6 = alloca %struct.big  (the byval copy: handle cells for a and b, a classical i64 cell for c)
  %7 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: store i64 %0, ptr %6 (the seed) and %9 = cq_theta_sl(%0, %1): one mint  [register p.a]
  call void @cqrt_ry_i64(i32 %7, double %1)    ; IR: %9 = cq_theta_sl(%0, %1)  [Ry]
  store i32 %7, ptr %6, align 8    ; IR: store i64 %9, ptr %6  (the handle into cell a)
  %8 = call i32 @cqrt_alloc_i64(i64 %2)    ; IR: store i64 %2, ptr %7 (the seed) and %10 = cq_theta_sl(%2, %3): one mint  [register p.b]
  call void @cqrt_ry_i64(i32 %8, double %3)    ; IR: %10 = cq_theta_sl(%2, %3)  [Ry]
  %9 = getelementptr inbounds i8, ptr %6, i64 4    ; IR: %7 = getelementptr %6, 8  (cell b)
  store i32 %8, ptr %9, align 4    ; IR: store i64 %10, ptr %7  (the handle into cell b)
  %10 = getelementptr inbounds i8, ptr %6, i64 8    ; IR: %8 = getelementptr %6, 16  (cell c)
  store i64 %4, ptr %10, align 8    ; IR: store i64 %4, ptr %8  (classical)
  %11 = call fastcc i32 @__cq_q_sum3_1100(ptr %6, i64 %4)    ; IR: %11 = call @sum3(byval %6, %4): clone for mask (slot a, b quantum, c classical; c classical); the result rail
  %12 = call i64 @cqrt_measure_i64(i32 %11)    ; IR: %12 = cq_measure_sl(%11)
  ret i64 %12    ; IR: llvm.lifetime.end(%6) (nothing); ret i64 %12
}

define internal fastcc i32 @__cq_q_sum3_1100(ptr %0, i64 %1) {
  %3 = load i32, ptr %0, align 8    ; IR: %3 = load i64, ptr %0  (the handle of p.a, no gate)
  %4 = getelementptr inbounds i8, ptr %0, i64 4    ; IR: %4 = getelementptr %0, 8  (cell b)
  %5 = load i32, ptr %4, align 4    ; IR: %5 = load i64, ptr %4  (the handle of p.b)
  %6 = call i32 @cq_template_mul_i64_hl(i32 %5, i64 %1)    ; IR: %6 = mul nsw i64 %5, %1
  %7 = call i32 @cq_template_add_i64(i32 %6, i32 %3)    ; IR: %7 = add nsw i64 %6, %3
  %8 = getelementptr inbounds i8, ptr %0, i64 8    ; IR: %8 = getelementptr %0, 16  (cell c)
  %9 = load i64, ptr %8, align 8    ; IR: %9 = load i64, ptr %8  (classical p.c)
  %10 = call i32 @cq_template_add_i64_hl(i32 %7, i64 %9)    ; IR: %10 = add nsw i64 %7, %9
  %11 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: ret i64 %10  [result rail of the call]
  call void @cqrt_copy_i64(i32 %10, i32 %11)    ; IR: copy the result out
  call void @cq_template_add_i64_hl_unc(i32 %10, i32 %7, i64 %9)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_add_i64_unc(i32 %7, i32 %6, i32 %3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %6, i32 %5, i64 %1)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  ret i32 %11    ; IR: ret i64 %10
}

declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i64(i32, double)
declare void @cqrt_copy_i64(i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i64 @cqrt_measure_i64(i32)
