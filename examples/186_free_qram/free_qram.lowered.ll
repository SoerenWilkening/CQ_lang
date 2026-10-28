; HAND-WRITTEN. Rules: 2, 4, 5, 6, 7, 16, 20, 21.
; Checked: free_uncond and free_classical_cond: a[1] + a[k % 6] and k * 3 (both measured). free_entangled: a[1] + 1
; (measured). qram_ptr_addr: p == other (0), p < a + 2, (uintptr_t)p - (uintptr_t)a = 4 * idx and a[1] (all measured).
; Clean: free_uncond: the index rails k & 3 and k % 6, the value handles v and 2, both copy-outs; both stores popped LIFO,
; the realloc undone and the QRAM a released, all at the free call. free_classical_cond: the same rails, popped and
; released at the free call when c != 0 and at the end of the scope when c == 0. free_entangled: the copy-out a[1], the
; value handle 1, the index rail k & 3; the store a[0] = 1 is popped. qram_ptr_addr: k << 1, the byte offset, p's address
; rail, both compare flags, the index rail k & 3 and the value handle 5; the store popped and the QRAM a released.
; free_uncond and free_classical_cond also: the old k rail (rule 6: s = k * 3 is a bijection in k, 3 being odd; t = s *
; 0xAAAAAAAB, the inverse of 3 mod 2^32) and t, both freed: right after the mul in free_uncond, after the scope-end
; clean-up that still reads k in free_classical_cond.
; Kept: free_uncond and free_classical_cond: both results (measured). free_entangled: k and
; x (the rotated registers), the result (measured) and the QRAM a (4 cells): it is NEVER released (no qram_free).
; qram_ptr_addr: k, and the four results eq, lt, d, a[1] (measured).
; Rotations: free_uncond, free_classical_cond: (Ry, k, tk, 1). free_entangled: (Ry, k, tk, 1); (Ry, x, tx, 1);
; (Ry, x, t2, 1). qram_ptr_addr: (Ry, k, tk, 1).
; In every function a[k & 3] = ... is a QUANTUM-OFFSET store, so the heap block (malloc site and its realloc: one object)
; is a QRAM for its whole lifetime (rule 20); malloc is cqrt_qram_alloc_i8(4), realloc(a, 6) is cqrt_qram_realloc_i8
; (§1.3), no host block is kept, and every fixed-index access is the _hl form. free(a) is a LIFETIME END (rule 16), not a
; host call: at the free point the block is cleaned in exact reverse order of its accesses (un-copy each load, pop each
; store, undo the realloc after the store made through a' is popped) and then qram_free'd. A copy-out is un-copied only
; after its last consumer, so a pure template that -O1 sank past the free is scheduled before the clean-up (it reads
; only rails that are ready; rule 5).
; free_uncond: the clean-up and qram_free sit at the free call, before k * 3 is computed (not deferred to scope end).
; free_classical_cond: the condition c is CLASSICAL, so a classical branch selects where the lifetime ends: c != 0 runs
; the clean-up and qram_free at the free call; c == 0 is C's leak of a, whose pointer never escapes the function, so its
; lifetime ends with the enclosing scope (rule 16's scope-end rule) and the same clean-up and qram_free run there, after
; the measurements (which read neither the cells nor the copy-outs). Garbage that can be cleaned must be (§0): a QRAM
; holding cells entangled with k is never left allocated when it can be popped.
; free_entangled: the stored value is the register x itself, and x is ROTATED (Ry t2, a non-diagonal gate) while cell
; k & 3 still holds x's old value, which is read after the rotation (a[1]). Popping that store would XOR x's CURRENT
; value out of the cell, so the cell (one of 4, chosen by k) cannot be returned to |0> and the QRAM cannot be proven
; clean: per §0 / rule 16 the provably clean parts are cleaned (un-copy a[1], pop the later store a[0] = 1 which is
; above it on the LIFO tape, uncompute k & 3 from the untouched k) and the block STAYS ALLOCATED: no qram_free. Rule 5
; could not pop the store before the rotation either: the read a[1] after the rotation is its last consumer.
; -O1 forwarded the read a[0] to the literal 1 (r = a[1] + 1).
; qram_ptr_addr: a (malloc(16), int cells) is a QRAM (a[k & 3] = 5); p = a + ((k >> 1) & 3) is a fat pointer into it
; with a QUANTUM idx (rule 21). QRAM ADDRESS RANGE (rule 21: reserved x86-64 NON-CANONICAL addresses, which no host
; pointer can take): object n has base 0x4000_0000_0000_0000 + 0x1000 * n, 4 KiB aligned; a is object 1, base
; 0x4000000000001000 = 4611686018427392000. An address is base + size * idx as an i64 rail. p == other (other a host
; pointer parameter, which may alias: an address compare) is icmp_eq_i64 of p's address rail against other's real host
; address: 0 on every branch. -O1 cancelled the base in p < a + 2 (byte offset 4 * idx < 8) and in (uintptr_t)p -
; (uintptr_t)a (the byte offset 4 * idx, zext to i64), so those depend only on idx, never on the assigned base. The
; copy-out a[1] is a measured result, so free(a) pops the store without un-copying it (the pop is a permutation of the
; cells) and releases the QRAM.
source_filename = "free_qram.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @free_uncond(i32 noundef %0, double noundef %1, i8 noundef zeroext %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cqrt_qram_alloc_i8(i32 4)    ; IR: %5 = call @malloc(4): the QRAM a, 4 byte cells |0> (no host block)
  %6 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)    ; IR: %6 = and i32 %4, 3  [index rail; zext %7 and gep %8 not emitted]
  %7 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: store i8 %2, ptr %8: v as a basis-state handle
  call void @cqrt_qram_store_i8(i32 %5, i32 %6, i32 %7)    ; IR: store i8 %2, ptr %8: a[k & 3] = v
  %8 = call i32 @cqrt_qram_load_i8_hl(i32 %5, i32 1)    ; IR: %10 = load i8, ptr %9: a[1]  (fixed-index copy-out)
  %9 = call i32 @cqrt_qram_realloc_i8(i32 %5, i32 6)    ; IR: %11 = call @realloc(%5, 6): same object, cells 4, 5 |0>
  %10 = call i32 @cqrt_alloc_i8(i8 2)    ; IR: store i8 2, ptr %12: 2 as a basis-state handle
  call void @cqrt_qram_store_i8_hl(i32 %9, i32 5, i32 %10)    ; IR: store i8 2, ptr %12: a[5] = 2  (a new cell)
  %11 = call i32 @cq_template_urem_i32_hl(i32 %4, i32 6)    ; IR: %13 = urem i32 %4, 6  [index rail; %14, %15 not emitted]
  %12 = call i32 @cqrt_qram_load_i8(i32 %9, i32 %11)    ; IR: %16 = load i8, ptr %15: a[k % 6]  (QRAM load)
  %13 = call i32 @cq_template_add_i8(i32 %12, i32 %8)    ; IR: %17 = add i8 %16, %10  [result rail r]
  ; IR: call @free(%11): the lifetime of a ends here; clean-up in exact reverse order of its accesses
  call void @cqrt_qram_load_i8_unc(i32 %12, i32 %9, i32 %11)    ; IR: un-copy %16 (a[k % 6])
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_urem_i32_hl_unc(i32 %11, i32 %4, i32 6)    ; IR: uncompute %13
  call void @cqrt_free(i32 %11)    ; IR: release the %13 rail (|0>)
  call void @cqrt_qram_store_i8_hl_unc(i32 %9, i32 5, i32 %10)    ; IR: pop a[5] = 2 (the last store, made through a')
  call void @cqrt_free(i32 %10)    ; IR: release the value handle (basis state 2, rule 7)
  call void @cqrt_qram_realloc_i8_unc(i32 %9, i32 4)    ; IR: undo the realloc: cells 4, 5 are |0> and dropped; %5 is the bus again
  call void @cqrt_qram_load_i8_hl_unc(i32 %8, i32 %5, i32 1)    ; IR: un-copy %10 (a[1]): the cell is as it was at the copy-out
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i8_unc(i32 %5, i32 %6, i32 %7)    ; IR: pop a[k & 3] = v: every cell back to |0>
  call void @cqrt_free(i32 %7)    ; IR: release the value handle (basis state v, rule 7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %4, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cqrt_qram_free(i32 %5)    ; IR: call @free(%11): release the QRAM a (every store popped, all cells |0>)
  %14 = call i32 @cq_template_mul_i32_hl(i32 %4, i32 3)    ; IR: %18 = mul i32 %4, 3  [result rail s; after the free]
  %15 = call i32 @cq_template_mul_i32_hl(i32 %14, i32 -1431655765)    ; IR: rule 6: t = s * 3^-1 (0xAAAAAAAB, the inverse of 3 mod 2^32) recomputes the old k (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %15, i32 %4)    ; IR: rule 6: k ^= t: the dead k rail is now |0>
  call void @cq_template_mul_i32_hl_unc(i32 %15, i32 %14, i32 -1431655765)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %15)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the old k rail (|0> after the copy)
  %16 = call i8 @cqrt_measure_i8(i32 %13)    ; IR: %19 = cq_measure_ui8(%17)
  %17 = zext i8 %16 to i32    ; IR: %20 = zext i8 %19 to i32  (classical)
  %18 = call i32 @cqrt_measure_i32(i32 %14)    ; IR: %21 = cq_measure_ui32(%18)
  %19 = add i32 %18, %17    ; IR: %22 = add i32 %21, %20  (classical)
  ret i32 %19    ; IR: ret i32 %22
}

define i32 @free_classical_cond(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call i32 @cqrt_qram_alloc_i8(i32 4)    ; IR: %6 = call @malloc(4): the QRAM a, 4 byte cells |0>
  %7 = call i32 @cq_template_and_i32_hl(i32 %5, i32 3)    ; IR: %7 = and i32 %5, 3  [index rail]
  %8 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: store i8 %2, ptr %9: v as a basis-state handle
  call void @cqrt_qram_store_i8(i32 %6, i32 %7, i32 %8)    ; IR: store i8 %2, ptr %9: a[k & 3] = v
  %9 = call i32 @cqrt_qram_load_i8_hl(i32 %6, i32 1)    ; IR: %11 = load i8, ptr %10: a[1]
  %10 = call i32 @cqrt_qram_realloc_i8(i32 %6, i32 6)    ; IR: %12 = call @realloc(%6, 6)
  %11 = call i32 @cqrt_alloc_i8(i8 2)    ; IR: store i8 2, ptr %13: 2 as a basis-state handle
  call void @cqrt_qram_store_i8_hl(i32 %10, i32 5, i32 %11)    ; IR: store i8 2, ptr %13: a[5] = 2
  %12 = call i32 @cq_template_urem_i32_hl(i32 %5, i32 6)    ; IR: %14 = urem i32 %5, 6  [index rail]
  %13 = call i32 @cqrt_qram_load_i8(i32 %10, i32 %12)    ; IR: %17 = load i8, ptr %16: a[k % 6]
  %14 = call i32 @cq_template_add_i8(i32 %13, i32 %9)    ; IR: %21 = add i8 %17, %11  [result rail r; scheduled before the free: its operands are the copy-outs]
  %15 = icmp eq i32 %3, 0    ; IR: %18 = icmp eq i32 %3, 0  (classical)
  br i1 %15, label %17, label %16    ; IR: br i1 %18, label %20, label %19  (classical branch)
16:
  ; IR: block %19: call @free(%12): the lifetime of a ends here (c != 0)
  call void @cqrt_qram_load_i8_unc(i32 %13, i32 %10, i32 %12)    ; IR: un-copy %17 (a[k % 6])
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_urem_i32_hl_unc(i32 %12, i32 %5, i32 6)    ; IR: uncompute %14
  call void @cqrt_free(i32 %12)    ; IR: release the %14 rail (|0>)
  call void @cqrt_qram_store_i8_hl_unc(i32 %10, i32 5, i32 %11)    ; IR: pop a[5] = 2
  call void @cqrt_free(i32 %11)    ; IR: release the value handle (basis state 2)
  call void @cqrt_qram_realloc_i8_unc(i32 %10, i32 4)    ; IR: undo the realloc
  call void @cqrt_qram_load_i8_hl_unc(i32 %9, i32 %6, i32 1)    ; IR: un-copy %11 (a[1])
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i8_unc(i32 %6, i32 %7, i32 %8)    ; IR: pop a[k & 3] = v
  call void @cqrt_free(i32 %8)    ; IR: release the value handle (basis state v)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %5, i32 3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cqrt_qram_free(i32 %6)    ; IR: call @free(%12): release the QRAM a
  br label %17
17:
  %18 = call i32 @cq_template_mul_i32_hl(i32 %5, i32 3)    ; IR: %22 = mul i32 %5, 3  [result rail s]
  %19 = call i8 @cqrt_measure_i8(i32 %14)    ; IR: %23 = cq_measure_ui8(%21)
  %20 = zext i8 %19 to i32    ; IR: %24 = zext i8 %23 to i32  (classical)
  %21 = call i32 @cqrt_measure_i32(i32 %18)    ; IR: %25 = cq_measure_ui32(%22)
  %22 = add i32 %21, %20    ; IR: %26 = add i32 %25, %24  (classical)
  br i1 %15, label %23, label %24    ; IR: scope end: was a freed? (classical, %18)
23:
  ; IR: c == 0: C leaks a (its pointer never escapes); its lifetime ends with the scope: the same clean-up
  call void @cqrt_qram_load_i8_unc(i32 %13, i32 %10, i32 %12)    ; IR: un-copy %17 (a[k % 6])
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_urem_i32_hl_unc(i32 %12, i32 %5, i32 6)    ; IR: uncompute %14
  call void @cqrt_free(i32 %12)    ; IR: release the %14 rail (|0>)
  call void @cqrt_qram_store_i8_hl_unc(i32 %10, i32 5, i32 %11)    ; IR: pop a[5] = 2
  call void @cqrt_free(i32 %11)    ; IR: release the value handle (basis state 2)
  call void @cqrt_qram_realloc_i8_unc(i32 %10, i32 4)    ; IR: undo the realloc
  call void @cqrt_qram_load_i8_hl_unc(i32 %9, i32 %6, i32 1)    ; IR: un-copy %11 (a[1])
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i8_unc(i32 %6, i32 %7, i32 %8)    ; IR: pop a[k & 3] = v
  call void @cqrt_free(i32 %8)    ; IR: release the value handle (basis state v)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %5, i32 3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cqrt_qram_free(i32 %6)    ; IR: scope end: release the QRAM a
  br label %24
24:
  %25 = call i32 @cq_template_mul_i32_hl(i32 %18, i32 -1431655765)    ; IR: rule 6: t = s * 3^-1 (0xAAAAAAAB) after the scope-end uncomputes that read k (both paths) recomputes the old k (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %25, i32 %5)    ; IR: rule 6: k ^= t: the dead k rail is now |0>
  call void @cq_template_mul_i32_hl_unc(i32 %25, i32 %18, i32 -1431655765)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %25)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the old k rail (|0> after the copy)
  ret i32 %22    ; IR: ret i32 %26
}

define i32 @free_entangled(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: %7 = cq_theta_ui8(%2, %3)  [register x]
  call void @cqrt_ry_i8(i32 %7, double %3)    ; IR: %7 = cq_theta_ui8(%2, %3)  [Ry]
  %8 = call i32 @cqrt_qram_alloc_i8(i32 4)    ; IR: %8 = call @malloc(4): the QRAM a, 4 byte cells |0>
  %9 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %9 = and i32 %6, 3  [index rail]
  call void @cqrt_qram_store_i8(i32 %8, i32 %9, i32 %7)    ; IR: store i8 %7, ptr %11: a[k & 3] = x  (the cell copies x's value now)
  call void @cqrt_ry_i8(i32 %7, double %4)    ; IR: %12 = cq_theta_ui8(%7, %4): x rotated in place (rule 2)  [Ry]
  %10 = call i32 @cqrt_alloc_i8(i8 1)    ; IR: store i8 1, ptr %8: 1 as a basis-state handle
  call void @cqrt_qram_store_i8_hl(i32 %8, i32 0, i32 %10)    ; IR: store i8 1, ptr %8: a[0] = 1
  %11 = call i32 @cqrt_qram_load_i8_hl(i32 %8, i32 1)    ; IR: %14 = load i8, ptr %13: a[1]  (old x when k & 3 == 1)
  %12 = call i32 @cq_template_add_i8_hl(i32 %11, i8 1)    ; IR: %15 = add i8 %14, 1  (a[0] forwarded to 1)  [result rail]
  ; IR: call @free(%8): lifetime end; clean what is provably clean
  call void @cqrt_qram_load_i8_hl_unc(i32 %11, i32 %8, i32 1)    ; IR: un-copy %14 (cell 1 unchanged since the copy-out)
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i8_hl_unc(i32 %8, i32 0, i32 %10)    ; IR: pop a[0] = 1 (top of the LIFO tape)
  call void @cqrt_free(i32 %10)    ; IR: release the value handle (basis state 1)
  ; IR: a[k & 3] = x is NOT popped: x was rotated after the store, the cell holds its old value (entangled, §0)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %6, i32 3)    ; IR: uncompute %9 from the untouched k
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  ; IR: no cqrt_qram_free: the QRAM a stays allocated (one cell not provably clean)
  %13 = call i8 @cqrt_measure_i8(i32 %12)    ; IR: %16 = cq_measure_ui8(%15)
  %14 = zext i8 %13 to i32    ; IR: %17 = zext i8 %16 to i32  (classical)
  ret i32 %14    ; IR: ret i32 %17
}

define i32 @qram_ptr_addr(i32 noundef %0, double noundef %1, ptr noundef readnone %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %5 = call @malloc(16): the QRAM a, 4 i32 cells |0>; QRAM base 0x4000000000001000 (object 1 of the non-canonical QRAM address range)
  %6 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)    ; IR: %6 = and i32 %4, 3  [index rail; zext %7 and gep %8 not emitted]
  %7 = call i32 @cqrt_alloc_i32(i32 5)    ; IR: store i32 5, ptr %8: 5 as a basis-state handle
  call void @cqrt_qram_store_i32(i32 %5, i32 %6, i32 %7)    ; IR: store i32 5, ptr %8: a[k & 3] = 5
  %8 = call i32 @cq_template_shl_i32_hl(i32 %4, i32 1)    ; IR: %9 = shl i32 %4, 1
  %9 = call i32 @cq_template_and_i32_hl(i32 %8, i32 12)    ; IR: %10 = and i32 %9, 12: the byte offset 4 * idx of p (idx = (k >> 1) & 3)
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)    ; IR: %11 = zext nneg i32 %10 to i64  [result rail d = (uintptr_t)p - (uintptr_t)a]
  %11 = call i32 @cq_template_add_i64_hl(i32 %10, i64 4611686018427392000)    ; IR: %12 = getelementptr i8, ptr %5, i64 %11: p's address = base 0x4000000000001000 + 4 * idx (i64 rail)
  %12 = ptrtoint ptr %2 to i64    ; IR: %13: other's real host address (classical)
  %13 = call i32 @cq_template_icmp_eq_i64_hl(i32 %11, i64 %12)    ; IR: %13 = icmp eq ptr %12, %2: an ADDRESS compare (a parameter may alias); 0 on every branch (a non-canonical QRAM address never equals a host address)
  %14 = call i32 @cq_template_zext_i1_to_i32(i32 %13)    ; IR: %14 = zext i1 %13 to i32  [result rail eq]
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %13, i32 %11, i64 %12)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %11, i32 %10, i64 4611686018427392000)    ; IR: uncompute p's address
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  %15 = call i32 @cq_template_icmp_ult_i32_hl(i32 %9, i32 8)    ; IR: %15 = icmp ult i32 %10, 8: p < a + 2 (-O1 cancelled the common base: base + 4 * idx < base + 8)
  %16 = call i32 @cq_template_zext_i1_to_i32(i32 %15)    ; IR: %16 = zext i1 %15 to i32  [result rail lt]
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %15, i32 %9, i32 8)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %8, i32 12)    ; IR: uncompute %10 (its consumers %11, %15 done)
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %8, i32 %4, i32 1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  %17 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i32 1)    ; IR: %17 = gep %5, 4; %18 = load i32, ptr %17: a[1]  (fixed-index copy-out)  [result rail r]
  ; IR: call @free(%5): lifetime end. a[1] is a measured result (kept), so the store is popped with the copy-out left standing: valid, the pop is a permutation of the cells only
  call void @cqrt_qram_store_i32_unc(i32 %5, i32 %6, i32 %7)    ; IR: pop a[k & 3] = 5: every cell back to |0>
  call void @cqrt_free(i32 %7)    ; IR: release the value handle (basis state 5)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %4, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @cqrt_qram_free(i32 %5)    ; IR: call @free(%5): release the QRAM a
  %18 = call i32 @cqrt_measure_i32(i32 %14)    ; IR: %19 = cq_measure_si32(%14)
  %19 = call i32 @cqrt_measure_i32(i32 %16)    ; IR: %20 = cq_measure_si32(%16)
  %20 = add nsw i32 %19, %18    ; IR: %21 = add nsw i32 %20, %19  (classical)
  %21 = call i64 @cqrt_measure_i64(i32 %10)    ; IR: %22 = cq_measure_sl(%11)
  %22 = call i32 @cqrt_measure_i32(i32 %17)    ; IR: %23 = cq_measure_si32(%18)
  %23 = trunc i64 %21 to i32    ; IR: %24 = trunc i64 %22 to i32  (classical)
  %24 = add i32 %20, %23    ; IR: %25 = add i32 %21, %24  (classical)
  %25 = add i32 %24, %22    ; IR: %26 = add i32 %25, %23  (classical)
  ret i32 %25    ; IR: ret i32 %26
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i8(i32, double)
declare i8 @cqrt_measure_i8(i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_qram_alloc_i8(i32)
declare i32 @cqrt_qram_realloc_i8(i32, i32)
declare void @cqrt_qram_realloc_i8_unc(i32, i32)
declare void @cqrt_qram_free(i32)
declare void @cqrt_qram_store_i8(i32, i32, i32)
declare void @cqrt_qram_store_i8_unc(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i8(i32, i32)
declare void @cqrt_qram_load_i8_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i32)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_urem_i32_hl(i32, i32)
declare void @cq_template_urem_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i8(i32, i32)
declare i32 @cq_template_add_i8_hl(i32, i8)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare i64 @cqrt_measure_i64(i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)
declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)
