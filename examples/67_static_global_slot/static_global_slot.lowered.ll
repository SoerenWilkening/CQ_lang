; HAND-WRITTEN. Rules: 20, 18, 16, 4, 5, 2.
; Checked: y + saved, saved = x * c, y = bump(saved) (measured).
; Clean: the product x * c (the slot's rail), the clone's result rail (zeroed by the twin, then freed), and every rail
; inside the clone and its twin.
; Kept: the user register x; the result rail (measured); the clone's tape rail (never freed).
; Rotations: Ry(th) on x.
; A function-local `static` is a global with internal linkage whose address never escapes (the casin shape: openlibm
; keeps `static double complex ca, ct, zz, z2;` and stores quantum values into them between calls to csqrt/clog,
; which is what stops -O1 from localizing them). Such a global is a classical SLOT exactly like the non-escaping
; alloca of example 31 (rule 20): it keeps its i32 type and holds the HANDLE of the rail stored into it; the load after
; the call yields that handle. The callee is cloned for its quantum argument (rule 18); its printf is the output tape
; of example 47 (rule 16: one tape per function, the entry appended once). The clone's _unc twin recomputes the pure
; chain only: tape operations are write-once and are never replayed, so the twin has no tape. Both the stored product
; and the call result are uncomputed after the final add.
source_filename = "static_global_slot.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@static_global_slot.saved = internal unnamed_addr global i32 0, align 4    ; IR: @static_global_slot.saved  (classical slot: holds a handle)
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1    ; IR: @.str  (format string of the tape entry)

define i32 @static_global_slot(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_mul_i32_hl(i32 %4, i32 %2)    ; IR: %5 = mul nsw i32 %4, %2
  store i32 %5, ptr @static_global_slot.saved, align 4    ; IR: store i32 %5, ptr @static_global_slot.saved  (the slot takes the handle)
  %6 = call fastcc i32 @__cq_q_bump_1(i32 %5)    ; IR: %6 = call @bump(%5), quantum clone (arg 0 quantum)
  %7 = load i32, ptr @static_global_slot.saved, align 4    ; IR: %7 = load i32, ptr @static_global_slot.saved  (the handle of %5)
  %8 = call i32 @cq_template_add_i32(i32 %7, i32 %6)    ; IR: %8 = add nsw i32 %7, %6  [result rail]
  call fastcc void @__cq_q_bump_1_unc(i32 %6, i32 %5)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %5, i32 %4, i32 %2)    ; IR: uncompute %5 (the slot's rail)
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>); the slot's handle is dead
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %9    ; IR: ret i32 %9
}

define internal fastcc i32 @__cq_q_bump_1(i32 %0) {
  %2 = call i32 @cqrt_tape_alloc()    ; IR: the clone's output tape
  call void @cqrt_tape_fmt(i32 %2, ptr @.str)    ; IR: %2 = printf(@.str, %0): open the entry with its format string
  %3 = call i32 @cqrt_tape_write_i32(i32 %2, i32 %0)    ; IR: %2 = printf(..., %0): field 0, a quantum value copied onto a fresh tape rail
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 1)    ; IR: %3 = add nsw i32 %0, 1
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %3  [result rail of the call]
  call void @cqrt_copy_i32(i32 %4, i32 %5)    ; IR: copy the result out
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  ret i32 %5    ; IR: ret i32 %3
}

define internal fastcc void @__cq_q_bump_1_unc(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_add_i32_hl(i32 %1, i32 1)    ; IR: recompute %3 (no tape: the entry was appended once by the forward clone)
  call void @cqrt_copy_i32(i32 %3, i32 %0)    ; IR: xor the result out of %out
  call void @cq_template_add_i32_hl_unc(i32 %3, i32 %1, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cqrt_tape_alloc()
declare void @cqrt_tape_fmt(i32, ptr)
declare i32 @cqrt_tape_write_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
