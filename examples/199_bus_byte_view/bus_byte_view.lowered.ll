; HAND-WRITTEN. Rules: 2, 4, 5, 7, 16, 20, 21.
; Checked: r = w' + lo (measured, %22 -> %23), lo = byte (k & 3) of x read BEFORE the byte store, w' = x with byte
; ((k >> 2) & 3) replaced by c, bytes counted little-endian (byte 0 = the low 8 bits), the sum mod 2^32. Memory: the
; four cells of w hold w' at exit.
; Clean: the two address chains (k & 3, its zext, the address rail P + (k & 3); k >> 2, the and, its zext, the address
; rail P + ((k >> 2) & 3)), the first uncomputed and freed right after the _unc of its load, the second right after its
; store; the word load copy %20 (rule 5 sentence
; 1: un-copied by its load _unc, no memory version change follows the load); the zext of lo.
; Kept: k and x (rotated; x is also the value rail of the i32 store), r (measured). Rule 5: the tape slot of the i32
; store (4 cells) and of the i8 store (1 cell), the seed c (%19, the i8 store's value rail), the byte load copy lo
; (%14: un-copied after its last reader, the zext _unc, but not freed: the i8 store, a memory version change, lies
; between the load and that point).
; Rotations: (Ry, k, tk, 1); (Ry, x, tx, 1).
; Expected: bus_byte_view(1, .5, 0x04030201, 0, 0xAA): Ry(0) leaves x = 0x04030201 (bytes 1, 2, 3, 4), and Ry(.5) on
; every qubit of k = 1 flips each bit with p = sin^2(.25) = 0.061209 (q = 1 - p), so i = k & 3 and j = (k >> 2) & 3 are
; independent: P(i = 1) = P(j = 0) = q^2 = 0.881329, P(i = 0) = P(i = 3) = P(j = 1) = P(j = 2) = pq = 0.057462,
; P(i = 2) = P(j = 3) = p^2 = 0.003747. r = (x with byte j := 0xAA) + (i + 1), 16 distinct values with P(i) P(j):
;   j = 0: 0x040302AB 0.050643, 0x040302AC 0.776741, 0x040302AD 0.003302, 0x040302AE 0.050643   (i = 0, 1, 2, 3)
;   j = 1: 0x0403AA02 0.003302, 0x0403AA03 0.050643, 0x0403AA04 0.000215, 0x0403AA05 0.003302
;   j = 2: 0x04AA0202 0.003302, 0x04AA0203 0.050643, 0x04AA0204 0.000215, 0x04AA0205 0.003302
;   j = 3: 0xAA030202 0.000215, 0xAA030203 0.003302, 0xAA030204 0.000014, 0xAA030205 0.000215
; (worked by hand from the C program; no simulator). For tx != 0 the same table holds per basis value of x, weighted
; by the product distribution of its 32 bits.
; w: its address is the base of two getelementptrs with a tainted index and it is stored a tainted value, so the
; alloca is bus-resident (rule 20): __cq_alloc(4, 4) at the alloca's program point, no alloca remains, the lifetime
; markers are dropped (rule 16). P = its run-time address, a classical i64.
; STORE SIZE (rule 20, §1.3): every access is ONE call of the type and at the address its instruction names. The word
; store is qram_store_i32_hl(m, P, x): the 4 cells P..P+3, little-endian, so cell P + n holds byte n of x. b[k & 3] is
; ONE qram_load_i8 at the address rail P + (k & 3): one cell, whichever of the four the branch of k names. The byte
; store is ONE qram_store_i8 at the address rail P + ((k >> 2) & 3) of the seed c: it displaces one cell of the word
; into its tape slot. The final qram_load_i32_hl(m, P) reads the same 4 cells as one i32: three bytes of x and the
; byte c at position j. No access is split into bytes or widened to the object, and nothing is asked about what the
; cells hold or which object the address lies in.
; ADDRESS ARITHMETIC (rule 20): the gep's tainted index is already i64 (-O1's zext, emitted as the template), the
; element size is 1, so the address rail is add_i64_hl(index, P): the classical base is the _hl literal. The mul by
; the element size 1 is the identity and is not emitted (§6 compares semantics).
; UNCOMPUTE (rule 5): lo's copy is overtaken by the byte store: it is un-copied after its last reader, the zext _unc,
; and stays allocated; its address chain is template garbage that stays alive until that _unc and is uncomputed after it. The byte store is KEPT
; (slot and seed); its address chain is uncomputed after the store. The word load %20 has one consumer, the add r, and
; no memory version change follows the load, so it is un-copied right after the add (cqrt_qram_load_i32_hl_unc: the
; cells still hold w') and freed; then the zext is uncomputed against lo, and lo is un-copied. Rule 6 is not used: both operands
; of the add are rule-5 garbage.
source_filename = "bus_byte_view.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @bus_byte_view(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i8 noundef zeroext %4) {
  %6 = call i32 @__cq_mem()    ; IR: m = the bus handle (once, at function entry)
  %7 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %6 = alloca i32, align 4  [bus-resident: 4 zeroed cells; lifetime.start dropped]
  %8 = ptrtoint ptr %7 to i64    ; IR: P = the run-time address of w (classical i64)
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %7 = cq_theta_ui32(%0, %1)  [Ry]
  %10 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %8 = cq_theta_ui32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %10, double %3)    ; IR: %8 = cq_theta_ui32(%2, %3)  [Ry]
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %8, i32 %10)    ; IR: store i32 %8, ptr %6  [ONE i32 store: cells P..P+3, little-endian; kept: slot, value rail x]
  %11 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)    ; IR: %9 = and i32 %7, 3
  %12 = call i32 @cq_template_zext_i32_to_i64(i32 %11)    ; IR: %10 = zext nneg i32 %9 to i64
  %13 = call i32 @cq_template_add_i64_hl(i32 %12, i64 %8)    ; IR: %11 = getelementptr inbounds i8, ptr %6, i64 %10  [address rail P + (k & 3); element size 1]
  %14 = call i32 @cqrt_qram_load_i8(i32 %6, i32 %13)    ; IR: %12 = load i8, ptr %11  [ONE i8 load at the address rail: lo; overtaken by the i8 store: un-copied after its last reader, not freed]
  %15 = call i32 @cq_template_lshr_i32_hl(i32 %9, i32 2)    ; IR: %13 = lshr i32 %7, 2
  %16 = call i32 @cq_template_and_i32_hl(i32 %15, i32 3)    ; IR: %14 = and i32 %13, 3
  %17 = call i32 @cq_template_zext_i32_to_i64(i32 %16)    ; IR: %15 = zext nneg i32 %14 to i64
  %18 = call i32 @cq_template_add_i64_hl(i32 %17, i64 %8)    ; IR: %16 = getelementptr inbounds i8, ptr %6, i64 %15  [address rail P + ((k >> 2) & 3)]
  %19 = call i32 @cqrt_alloc_i8(i8 %4)    ; IR: store i8 %4, ptr %16  [seed c: the store's value rail, kept with it (rule 7)]
  call void @cqrt_qram_store_i8(i32 %6, i32 %18, i32 %19)    ; IR: store i8 %4, ptr %16  [ONE i8 store at the address rail; kept: slot, seed]
  call void @cq_template_add_i64_hl_unc(i32 %18, i32 %17, i64 %8)    ; IR: uncompute %16 (the address rail, after the store)
  call void @cqrt_free(i32 %18)    ; IR: release the %16 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %17, i32 %16)    ; IR: uncompute %15
  call void @cqrt_free(i32 %17)    ; IR: release the %15 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %15, i32 3)    ; IR: uncompute %14
  call void @cqrt_free(i32 %16)    ; IR: release the %14 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %15, i32 %9, i32 2)    ; IR: uncompute %13
  call void @cqrt_free(i32 %15)    ; IR: release the %13 rail (|0>)
  %20 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %8)    ; IR: %17 = load i32, ptr %6  [ONE i32 load of the 4 cells: w']
  %21 = call i32 @cq_template_zext_i8_to_i32(i32 %14)    ; IR: %18 = zext i8 %12 to i32
  %22 = call i32 @cq_template_add_i32(i32 %20, i32 %21)    ; IR: %19 = add i32 %17, %18
  call void @cqrt_qram_load_i32_hl_unc(i32 %20, i32 %6, i64 %8)    ; IR: un-copy %17 (rule 5 sentence 1: no memory version change since the load; the cells still hold w')  ; SPEC GAP: sentence 1 asks for the last consumer's uncompute, and the consumer %19 is measured (never uncomputed); read as 197/198: un-copied right after the add
  call void @cqrt_free(i32 %20)    ; IR: release the %17 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %21, i32 %14)    ; IR: uncompute %18
  call void @cqrt_free(i32 %21)    ; IR: release the %18 rail (|0>)
  call void @cqrt_qram_load_i8_unc(i32 %14, i32 %6, i32 %13)    ; IR: un-copy %12 (lo) after its last reader, the zext _unc; the i8 store lies between, so it stays allocated (rule 5 sentence 1)
  call void @cq_template_add_i64_hl_unc(i32 %13, i32 %12, i64 %8)    ; IR: uncompute %11 (the address rail, after the _unc of its load)
  call void @cqrt_free(i32 %13)    ; IR: release the %11 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %12, i32 %11)    ; IR: uncompute %10
  call void @cqrt_free(i32 %12)    ; IR: release the %10 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %9, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  %23 = call i32 @cqrt_measure_i32(i32 %22)    ; IR: %20 = cq_measure_ui32(%19)  [lifetime.end dropped]
  ret i32 %23    ; IR: ret i32 %20
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare i32 @cqrt_qram_load_i8(i32, i32)
declare void @cqrt_qram_load_i8_unc(i32, i32, i32)
declare void @cqrt_qram_store_i8(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
