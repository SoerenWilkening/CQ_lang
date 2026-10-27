; HAND-WRITTEN. Rules: 2, 4, 5, 8, 12, 18, 20.
; Checked: quantum_bitfield's updated word w (the new word %14 -> %15, measured); bitfield_through_pointer's f.c (the
; lshr-8 result %10 -> %11, measured).
; Clean: quantum_bitfield's field chain (a %7, a + v %8, b %9, the flag %10, the shifted and masked new field %11, %12,
; the cleared word %13); bitfield_through_pointer's field-a rail %8, its flag %9 and the clone's new-word rail %7 (zeroed
; by the _unc twin), all freed.
; Kept: the register w in each function (%6, rotated; frozen) and the measured result rail.
; Rotations: (Ry, w, th, 1); (P, flag, ph, f.b > k) in quantum_bitfield; (Ry, w, th, 1); (P, flag, ph, f.a == 5) in
; bitfield_through_pointer.
; A bit-field is not a memory object: it is a view of its storage unit (here one i32), and -O1 has already spelled every
; field access as integer arithmetic on that word. A read of field b is `lshr`+`and`, a write is the read-modify-write
; `(word & ~mask) | ((v << off) & mask)`: two `and`s and a disjoint `or`, each a fresh rail (nothing in place). When the
; struct is a local whose bytes never escape, SROA dissolves it and the word is an SSA value (first function; -O1 even
; forwards f.b from the computed field instead of re-reading the new word). The condition on the field just written is a
; phase arm on that field's compare flag. The garbage of the RMW (the two masked halves and the field computation) is
; uncomputed after the disjoint or; the new word is measured. Uncompute order is dependency order (rule 5): the cleared
; word (%13) reads only w and is independent of the field chain, so it is undone last; the chain is undone in reverse.
; When the struct's address is passed to a callee (second function), the storage unit stays in an alloca: it is the
; classical slot of examples 31/106/108 holding the HANDLE of the word's rail. The callee's `p->c += d` is the RMW of the
; 24-bit field c at bit 8, which -O1 folded to `word + (d << 8)` (the carry out of bit 31 is the field's own wraparound):
; the clone loads the handle, adds into a fresh rail and stores the new handle (mask per §1.4, left to right: the
; pointer-to-slot formal p carries one quantum field, d is classical: __cq_q_bump_c_10). The caller's condition on field a
; reads the new word (a is untouched by the add, but the field view is of the current storage unit). The result c is
; `lshr 8` of the new word; the clone's _unc twin, (args..., old slot handles in slot order) = (p, d, the previous
; handle), then zeroes the new word, restores the slot's previous handle (the rotated register, which is frozen and never
; freed) and the caller frees the new rail.
source_filename = "quantum_bitfield.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @quantum_bitfield(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register w: the whole storage unit]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 7)    ; IR: %7 = and i32 %6, 7  (read field a)
  %8 = call i32 @cq_template_add_i32_hl(i32 %7, i32 %2)    ; IR: %8 = add i32 %7, %2  (a + v)
  %9 = call i32 @cq_template_and_i32_hl(i32 %8, i32 31)    ; IR: %9 = and i32 %8, 31  (the 5-bit field b as stored)
  %10 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %9, i32 %3)    ; IR: %10 = icmp ugt i32 %9, %3  [flag f.b > k]
  call void @cqrt_rz_i1(i32 %10, double %4)    ; IR: br i1 %10 -> block %11: cq_phi(%4)  [kickback onto the flag]
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %10, i32 %9, i32 %3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the flag (|0>)
  %11 = call i32 @cq_template_shl_i32_hl(i32 %8, i32 3)    ; IR: %13 = shl i32 %8, 3  (field b moved to bits 3-7)
  %12 = call i32 @cq_template_and_i32_hl(i32 %11, i32 248)    ; IR: %14 = and i32 %13, 248  (masked new field)
  %13 = call i32 @cq_template_and_i32_hl(i32 %6, i32 -249)    ; IR: %15 = and i32 %6, -249  (the word with field b cleared)
  %14 = call i32 @cq_template_or_i32(i32 %12, i32 %13)    ; IR: %16 = or disjoint i32 %14, %15  [the new word]
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %11, i32 248)    ; IR: uncompute %14
  call void @cqrt_free(i32 %12)    ; IR: release the %14 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %11, i32 %8, i32 3)    ; IR: uncompute %13
  call void @cqrt_free(i32 %11)    ; IR: release the %13 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %8, i32 31)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %7, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 7)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %6, i32 -249)    ; IR: uncompute %15
  call void @cqrt_free(i32 %13)    ; IR: release the %15 rail (|0>)
  %15 = call i32 @cqrt_measure_i32(i32 %14)    ; IR: %17 = cq_measure_ui32(%16)
  ret i32 %15    ; IR: ret i32 %17
}

define i32 @bitfield_through_pointer(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = alloca %struct.fields, align 4    ; IR: %5 = alloca %struct.fields  (classical slot: holds the handle of the storage unit)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register w]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  store i32 %6, ptr %5, align 4    ; IR: store i32 %6, ptr %5  (the slot takes the handle of w)
  call fastcc void @__cq_q_bump_c_10(ptr %5, i32 %2)    ; IR: call @bump_c(%5, %2): clone, mask 10 (the slot parameter carries one quantum field, d is classical)
  %7 = load i32, ptr %5, align 4    ; IR: %7 = load i32, ptr %5  (the handle the clone stored: the new word)
  %8 = call i32 @cq_template_and_i32_hl(i32 %7, i32 7)    ; IR: %8 = and i32 %7, 7  (read field a)
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %8, i32 5)    ; IR: %9 = icmp eq i32 %8, 5  [flag f.a == 5]
  call void @cqrt_rz_i1(i32 %9, double %3)    ; IR: br i1 %9 -> block %10: cq_phi(%3)  [kickback onto the flag]
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %8, i32 5)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the flag (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %7, i32 7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %10 = call i32 @cq_template_lshr_i32_hl(i32 %7, i32 8)    ; IR: %12 = lshr i32 %7, 8  (read field c)  [result rail]
  call fastcc void @__cq_q_bump_c_10_unc(ptr %5, i32 %2, i32 %6)    ; IR: twin (args..., old slot handle): the new word is zeroed, the slot holds w again
  call void @cqrt_free(i32 %7)    ; IR: release the clone's rail (|0>)
  %11 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %13 = cq_measure_ui32(%12)
  ret i32 %11    ; IR: ret i32 %13
}

define internal fastcc void @__cq_q_bump_c_10(ptr noundef %0, i32 noundef %1) {
  %3 = load i32, ptr %0, align 4    ; IR: %3 = load i32, ptr %0  (the cell's handle: the storage unit)
  %4 = shl i32 %1, 8    ; IR: %4 = shl i32 %1, 8  (classical: d at field c's offset)
  %5 = call i32 @cq_template_add_i32_hl(i32 %3, i32 %4)    ; IR: %5 = add i32 %3, %4  [fresh rail: the word with c += d]
  store i32 %5, ptr %0, align 4    ; IR: store i32 %5, ptr %0  (the cell takes the new handle)
  ret void    ; IR: ret void
}

define internal fastcc void @__cq_q_bump_c_10_unc(ptr noundef %0, i32 noundef %1, i32 %2) {
  %4 = load i32, ptr %0, align 4    ; IR: the cell's current handle (%5)
  %5 = shl i32 %1, 8    ; IR: %4 (classical)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %2, i32 %5)    ; IR: uncompute %5 in place (|0>)
  store i32 %2, ptr %0, align 4    ; IR: the cell holds the previous handle again
  ret void    ; IR: ret void
}

%struct.fields = type { i32 }

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
