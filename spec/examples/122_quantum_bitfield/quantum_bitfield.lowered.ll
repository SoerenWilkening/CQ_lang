; HAND-WRITTEN. Rules: 2, 4, 5, 6, 8, 12, 16, 18, 19, 20, 21; §1.3 (the bus, qram_swap), §1.4.
; Checked: quantum_bitfield's updated word w (the new word %14 -> %15, measured); bitfield_through_pointer's f.c (the
; lshr-8 result %12 -> %13, measured); the 4 cells of f at exit (read from the bus): w + (d << 8) mod 2^32.
; Clean: quantum_bitfield's field chain (a %7, a + v %8, b %9, the flag %10, the shifted and masked new field %11, %12,
; the cleared word %13); bitfield_through_pointer's field-a rail %10, its flag %11 and the load copy of f (%9),
; un-copied after its last reader (no memory version change follows the load), all freed; in bump_c the one rail of
; the in-place form (the swap rail %6, updated in place and |0> after the swap back), freed.
; Kept: the register w in each function (%6 / %7, rotated; frozen; in bitfield_through_pointer also the value rail of
; the kept store f = w) and the measured result rail; by rule 5 the tape slot of the store of w into f. The in-place
; form in bump_c keeps nothing.
; Rotations: (Ry, w, th, 1); (P, flag, ph, f.b > k) in quantum_bitfield; (Ry, w, th, 1); (P, flag, ph, f.a == 5) in
; bitfield_through_pointer.
; A bit-field is not a memory object: it is a view of its storage unit (here one i32), and -O1 has already spelled every
; field access as integer arithmetic on that word. A read of field b is `lshr`+`and`, a write is the read-modify-write
; `(word & ~mask) | ((v << off) & mask)`: two `and`s and a disjoint `or`, each a fresh rail (nothing in place). When the
; struct is a local whose bytes never escape, SROA dissolves it and the word is an SSA value (first function; -O1 even
; forwards f.b from the computed field instead of re-reading the new word): no bus access. The condition on the field
; just written is a phase arm on that field's compare flag. The garbage of the RMW (the two masked halves and the field
; computation) is uncomputed after the disjoint or; the new word is measured. Uncompute order is dependency order (rule
; 5): the cleared word (%13) reads only w and is independent of the field chain, so it is undone last; the chain is
; undone in reverse.
; When the struct's address is passed to a callee (second function), the alloca is bus-resident (rule 20 (b): a call
; argument is a user that demotes it): one __cq_alloc(4, 4) block at its program point, the lifetime markers dropped
; (rule 16). Storing w into it is a kept bus store at the block's classical address (rule 5 sentence 3): its tape slot
; and its value rail (the register w) stay. The pointer &f is a classical ptr and d is classical, so the call is
; all-classical: bump_c's OWN symbol (the all-zero mask, §1.4), lowered; nothing about the pointee crosses the call
; (rules 18, 21). In bump_c, `p->c += d` is the RMW of the 24-bit field c at bit 8, which -O1 folded to `load p; add
; (d << 8); store p` on the same SSA pointer with no memory version change between: rule 5's in-place form at the
; classical address p (rule 6, a memory cell): swap the cell out into a fresh rail, add there as rule 6's in-place
; update (addc_i32 on the swap rail: the old word is dead after the add), swap back. bump_c writes memory, so it has no twin (rule 18) and its call is a memory version
; change. The caller's load of f after the call is a bus load (a rail, rule 3); the condition on field a and the result
; c = `lshr 8` read that copy, and the copy is un-copied after its last reader (the `and`'s _unc and the lshr), before
; the measurement of c (rule 5 sentence 1). Nothing asks whether the cells at p are the cells of f.
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
  %5 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %6 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %5 = alloca %struct.fields, align 4: bus-resident (passed to a callee, rule 20), one zeroed block (rule 16; lifetime markers dropped)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register w]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address (classical)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %8, i32 %7)    ; IR: store i32 %6, ptr %5  (kept store: the tape slot and the value rail w stay, rule 5 sentence 3)
  call fastcc void @bump_c(ptr noundef %6, i32 noundef %2)    ; IR: call fastcc void @bump_c(ptr %5, i32 %2): classical ptr and classical d, bump_c's own symbol (all-zero mask, §1.4); it writes memory: no twin, a memory version change
  %9 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %8)    ; IR: %7 = load i32, ptr %5  (bus load: the word after the callee's update, a rail)
  %10 = call i32 @cq_template_and_i32_hl(i32 %9, i32 7)    ; IR: %8 = and i32 %7, 7  (read field a)
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %10, i32 5)    ; IR: %9 = icmp eq i32 %8, 5  [flag f.a == 5]
  call void @cqrt_rz_i1(i32 %11, double %3)    ; IR: br i1 %9 -> block %10: cq_phi(%3)  [kickback onto the flag]
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %10, i32 5)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the flag (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %9, i32 7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  %12 = call i32 @cq_template_lshr_i32_hl(i32 %9, i32 8)    ; IR: %12 = lshr i32 %7, 8  (read field c)  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %9, i32 %5, i64 %8)    ; IR: un-copy %7 (its last readers are done; no memory version change since the load, rule 5 sentence 1)
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  %13 = call i32 @cqrt_measure_i32(i32 %12)    ; IR: %13 = cq_measure_ui32(%12)
  ret i32 %13    ; IR: ret i32 %13  (llvm.lifetime.end dropped)
}

define internal fastcc void @bump_c(ptr noundef %0, i32 noundef %1) unnamed_addr {
  %3 = call i32 @__cq_mem()    ; IR: the bus M
  %4 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address (classical)
  %5 = shl i32 %1, 8    ; IR: %4 = shl i32 %1, 8  (classical: d at field c's offset)
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %3 = load i32, ptr %0 ... store i32 %5, ptr %0: the in-place form (rule 5), a fresh |0> rail
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 %4, i32 %6)    ; IR: %3 = load i32, ptr %0: swap out: the rail holds the storage unit, the cell |0>
  call void @cqrt_addc_i32(i32 %6, i32 %5)    ; IR: %5 = add i32 %3, %4  (the word with c += d)  [rule 6, in-place update: the old word is dead after the add, so the new word IS the swap rail]
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 %4, i32 %6)    ; IR: store i32 %5, ptr %0: swap in: the cell holds the new word, the rail |0>
  call void @cqrt_free(i32 %6)    ; IR: release the swap rail (|0>): nothing remains of the update
  ret void    ; IR: ret void
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_addc_i32(i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)
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
