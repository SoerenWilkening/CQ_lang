; HAND-WRITTEN. Rules: 26, 20, 18, 25, 4, 5, 2.
; Checked: creall(q) + cimagl(q), q = scale2(re + im*I) (measured).
; Clean: the real part of z (the slot's rail), the clone's result rail (zeroed by the twin, then freed), and every
; rail inside the clone and its twin.
; Kept: the user register re; the result rail (measured).
; Rotations: Ry(th) on re.
; On x86-64 a `long double complex` does not travel in registers: the caller builds it in an
; `alloca { x86_fp80, x86_fp80 }` and passes the pointer `byval`; the return comes back as the aggregate
; { x86_fp80, x86_fp80 } (rule 26). The alloca is a non-escaping slot pair (31, 52, rule 20): a field that holds a
; quantum value holds its HANDLE (type i32), a classical field stays a classical x86_fp80, so the slot type is the
; clone's mask applied field-wise, { i32, x86_fp80 } here (mask 10: real part quantum, imaginary part classical), and
; the GEP by byte offset becomes a field GEP. The clone reads the handle from the slot, computes out of place, copies
; its quantum result out, and returns a mask-typed aggregate { i32, x86_fp80 }: a handle for the quantum field, the
; classical value for the other (64 is the all-quantum case). The _unc twin takes the result handle and the slot
; pointer. Everything the caller allocated is uncomputed except the user register and the measured sum.
source_filename = "complex_long_double.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define x86_fp80 @complex_long_double(x86_fp80 noundef %0, double noundef %1, x86_fp80 noundef %2) {
  %4 = alloca { i32, x86_fp80 }, align 16    ; IR: %4 = alloca { x86_fp80, x86_fp80 }  (slot pair: field 0 holds a handle, field 1 a classical value)
  %5 = call i32 @cqrt_alloc_f80(x86_fp80 %0)    ; IR: %5 = cq_theta_f80(%0, %1)  [register re]
  call void @cqrt_ry_f80(i32 %5, double %1)    ; IR: %5 = cq_theta_f80(%0, %1)  [Ry]
  %6 = fmul x86_fp80 %2, 0xK00000000000000000000    ; IR: %6 = fmul x86_fp80 %2, 0  (classical)
  %7 = call i32 @cq_template_fadd_f80_hl(i32 %5, x86_fp80 %6)    ; IR: %7 = fadd x86_fp80 %6, %5  (real part of z; commutative, quantum operand first)
  %8 = getelementptr inbounds { i32, x86_fp80 }, ptr %4, i32 0, i32 1    ; IR: %8 = getelementptr i8, ptr %4, i64 16  (field 1)
  store i32 %7, ptr %4, align 16    ; IR: store x86_fp80 %7, ptr %4  (the slot takes the handle of the real part)
  store x86_fp80 %2, ptr %8, align 16    ; IR: store x86_fp80 %2, ptr %8  (classical imaginary part)
  %9 = call fastcc { i32, x86_fp80 } @__cq_q_scale2_10(ptr %4)    ; IR: %9 = call @scale2(byval %4), quantum clone (field 0 of the pointee quantum)
  %10 = extractvalue { i32, x86_fp80 } %9, 0    ; IR: %10 = extractvalue %9, 0  (handle of the real result; classical)
  %11 = extractvalue { i32, x86_fp80 } %9, 1    ; IR: %11 = extractvalue %9, 1  (classical imaginary result)
  %12 = call i32 @cq_template_fadd_f80_hl(i32 %10, x86_fp80 %11)    ; IR: %12 = fadd x86_fp80 %10, %11  [result rail]
  call fastcc void @__cq_q_scale2_10_unc(i32 %10, ptr %4)    ; IR: uncompute %10 (the call's quantum result)
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fadd_f80_hl_unc(i32 %7, i32 %5, x86_fp80 %6)    ; IR: uncompute %7 (the slot's rail)
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>); the slot's handle is dead
  %13 = call x86_fp80 @cqrt_measure_f80(i32 %12)    ; IR: %13 = cq_measure_f80(%12)
  ret x86_fp80 %13    ; IR: ret x86_fp80 %13
}

define internal fastcc { i32, x86_fp80 } @__cq_q_scale2_10(ptr %0) {
  %2 = load i32, ptr %0, align 16    ; IR: %2 = load x86_fp80, ptr %0  (the handle of z.real; no gate)
  %3 = getelementptr inbounds { i32, x86_fp80 }, ptr %0, i32 0, i32 1    ; IR: %3 = getelementptr i8, ptr %0, i64 16  (field 1)
  %4 = load x86_fp80, ptr %3, align 16    ; IR: %4 = load x86_fp80, ptr %3  (classical z.imag)
  %5 = call i32 @cq_template_fadd_f80(i32 %2, i32 %2)    ; IR: %5 = fadd x86_fp80 %2, %2  (the same rail in both slots)
  %6 = fadd x86_fp80 %4, %4    ; IR: %6 = fadd x86_fp80 %4, %4  (classical)
  %7 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)    ; IR: %7 = insertvalue poison, %5, 0  [result rail: real]
  call void @cqrt_copy_f80(i32 %5, i32 %7)    ; IR: copy the real part out
  call void @cq_template_fadd_f80_unc(i32 %5, i32 %2, i32 %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %8 = insertvalue { i32, x86_fp80 } poison, i32 %7, 0    ; IR: %7  (handle of the quantum field)
  %9 = insertvalue { i32, x86_fp80 } %8, x86_fp80 %6, 1    ; IR: %8 = insertvalue %7, %6, 1  (classical field)
  ret { i32, x86_fp80 } %9    ; IR: ret { x86_fp80, x86_fp80 } %8
}

define internal fastcc void @__cq_q_scale2_10_unc(i32 %0, ptr %1) {
  %3 = load i32, ptr %1, align 16    ; IR: the handle of z.real
  %4 = call i32 @cq_template_fadd_f80(i32 %3, i32 %3)    ; IR: recompute %5
  call void @cqrt_copy_f80(i32 %4, i32 %0)    ; IR: xor the real part out of the result rail
  call void @cq_template_fadd_f80_unc(i32 %4, i32 %3, i32 %3)    ; IR: uncompute %5
  call void @cqrt_free(i32 %4)    ; IR: release the %5 rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_f80(x86_fp80)
declare void @cqrt_ry_f80(i32, double)
declare void @cqrt_copy_f80(i32, i32)
declare void @cqrt_free(i32)
declare x86_fp80 @cqrt_measure_f80(i32)
declare i32 @cq_template_fadd_f80(i32, i32)
declare void @cq_template_fadd_f80_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f80_hl(i32, x86_fp80)
declare void @cq_template_fadd_f80_hl_unc(i32, i32, x86_fp80)
