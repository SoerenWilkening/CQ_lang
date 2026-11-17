; HAND-WRITTEN. Rules: 26, 18, 1, 3, 4, 5, §1.4.
; Checked: r.a + r.b (struct_byvalue_one, measured); r.a and r.b (struct_byvalue_both, each measured).
; Clean: struct_byvalue_one: the clone's chain and the result rail r.a (uncomputed by the twin, freed by the caller).
;        struct_byvalue_both: the clone's chain (both result rails are measured and stay).
; Kept: the rotated registers p.a (and p.b in _both), frozen; the measured rails.
; Rotations: Ry(ta) on p.a; Ry(ta) on p.a and Ry(tb) on p.b.
; A 8-byte struct { int, int } crosses the call as ONE i64 at the C ABI: -O1 packs it (zext / shl 32 / or disjoint) in
; the caller and unpacks it (trunc / lshr 32 / trunc) in the callee and again on the way back. Under rule 26 the struct is
; a tuple of fields, one rail per quantum field, classical fields as values: the packing and unpacking instructions are
; CLASSICAL ABI ARITHMETIC ON THE COERCION and emit NO gate; the fields are separate rails and never share a register.
; The clone takes the field handles / values in field order (§1.4, one mask digit per field of the aggregate, left to
; right: p.a, p.b, then c): __cq_q_shift_100(a handle, b value, c) for the one-quantum-field entry, returning
; { i32 handle of r.a, i32 classical r.b }; __cq_q_shift_110(a handle, b handle, c) returning { i32, i32 } of two
; handles. Each clone copies its quantum results into fresh rails and uncomputes its chain (rule 18); the one-field twin
; _unc(out r.a, a, b, c) recomputes r.a = a + c, XORs it out of the result rail and uncomputes. In the caller the
; extractvalues stand for -O1's trunc / lshr-trunc of the returned i64: classical, no gate. struct_byvalue_one adds the
; handle r.a and the classical r.b by the _hl shape (commutative: handle first), then the twin zeroes r.a before the
; measurement. struct_byvalue_both measures both result rails directly, so no twin runs (as 51 / 71).
source_filename = "struct_byvalue_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @struct_byvalue_one(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register p.a]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call fastcc { i32, i32 } @__cq_q_shift_100(i32 %5, i32 %2, i32 %3)    ; IR: %6..%9 (zext %2, shl 32, zext %5, or disjoint: the i64 coercion of p, classical ABI packing, no gate) and %10 = call @shift(%9, %3): clone for mask (p.a quantum, p.b classical, c classical); result { handle r.a, classical r.b }
  %7 = extractvalue { i32, i32 } %6, 0    ; IR: %11 = trunc i64 %10 to i32  (r.a: the handle of the result rail; the unpack of the coercion is classical)
  %8 = extractvalue { i32, i32 } %6, 1    ; IR: %12 = lshr i64 %10, 32; %13 = trunc nuw i64 %12 to i32  (r.b: a classical value)
  %9 = call i32 @cq_template_add_i32_hl(i32 %7, i32 %8)    ; IR: %14 = add nsw i32 %13, %11  [result rail; commutative: handle first]
  call fastcc void @__cq_q_shift_100_unc(i32 %7, i32 %5, i32 %2, i32 %3)    ; IR: uncompute r.a (adjoint of the call: the twin zeroes the result rail)
  call void @cqrt_free(i32 %7)    ; IR: release the r.a rail (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %15 = cq_measure_si32(%14)
  ret i32 %10    ; IR: ret i32 %15
}

define internal fastcc { i32, i32 } @__cq_q_shift_100(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 %2)    ; IR: %3 = trunc i64 %0 to i32 (p.a: the handle itself, no gate); %6 = add nsw i32 %3, %1
  %5 = mul nsw i32 %1, %2    ; IR: %4 = lshr, %5 = trunc (p.b: the classical field); %7 = mul nsw i32 %5, %1  (classical)
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i64 %11  [result rail r.a]
  call void @cqrt_copy_i32(i32 %4, i32 %6)    ; IR: copy r.a out
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %4)    ; IR: release the %6 rail (|0>)
  %7 = insertvalue { i32, i32 } poison, i32 %6, 0    ; IR: %8..%11 (zext, shl 32, zext, or disjoint: the i64 coercion of r, classical packing, no gate): the aggregate carries the handle of r.a
  %8 = insertvalue { i32, i32 } %7, i32 %5, 1    ; IR: and the classical r.b
  ret { i32, i32 } %8    ; IR: ret i64 %11
}

define internal fastcc void @__cq_q_shift_100_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @cq_template_add_i32_hl(i32 %1, i32 %3)    ; IR: recompute %6 (r.a)
  call void @cqrt_copy_i32(i32 %5, i32 %0)    ; IR: xor r.a out of the result rail
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %1, i32 %3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %5)    ; IR: release the %6 rail (|0>)
  ret void
}

define i32 @struct_byvalue_both(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register p.a]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %7 = cq_theta_si32(%2, %3)  [register p.b]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %7 = cq_theta_si32(%2, %3)  [Ry]
  %8 = call fastcc { i32, i32 } @__cq_q_shift_110(i32 %6, i32 %7, i32 %4)    ; IR: %8..%11 (the i64 coercion of p: classical packing, no gate) and %12 = call @shift(%11, %4): clone for mask (p.a quantum, p.b quantum, c classical); result { handle r.a, handle r.b }
  %9 = extractvalue { i32, i32 } %8, 0    ; IR: %13 = trunc i64 %12 to i32  (r.a: handle)
  %10 = extractvalue { i32, i32 } %8, 1    ; IR: %14 = lshr i64 %12, 32; %15 = trunc nuw i64 %14 to i32  (r.b: handle)
  %11 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %16 = cq_measure_si32(%13)
  %12 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %17 = cq_measure_si32(%15)
  %13 = add nsw i32 %12, %11    ; IR: %18 = add nsw i32 %17, %16  (classical)
  ret i32 %13    ; IR: ret i32 %18
}

define internal fastcc { i32, i32 } @__cq_q_shift_110(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 %2)    ; IR: %6 = add nsw i32 %3, %1  (%3 = trunc: p.a's handle, no gate)
  %5 = call i32 @cq_template_mul_i32_hl(i32 %1, i32 %2)    ; IR: %7 = mul nsw i32 %5, %1  (%5 = lshr, trunc: p.b's handle, no gate)
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i64 %11  [result rail r.a]
  call void @cqrt_copy_i32(i32 %4, i32 %6)    ; IR: copy r.a out
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i64 %11  [result rail r.b]
  call void @cqrt_copy_i32(i32 %5, i32 %7)    ; IR: copy r.b out
  call void @cq_template_mul_i32_hl_unc(i32 %5, i32 %1, i32 %2)    ; IR: uncompute %7
  call void @cqrt_free(i32 %5)    ; IR: release the %7 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %4)    ; IR: release the %6 rail (|0>)
  %8 = insertvalue { i32, i32 } poison, i32 %6, 0    ; IR: %8..%11 (the i64 coercion of r: classical packing, no gate): the aggregate of the two handles
  %9 = insertvalue { i32, i32 } %8, i32 %7, 1    ; IR: r.b's handle
  ret { i32, i32 } %9    ; IR: ret i64 %11
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
