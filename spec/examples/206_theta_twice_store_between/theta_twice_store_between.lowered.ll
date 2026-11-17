; HAND-WRITTEN. Rules: 5 (in-place form, Readers clause; Memory, sentences 1 to 3), 2, 6 (a memory cell), 20, 21, 3, 7; §1.3 (the bus, qram_swap).
; Two functions, ONE construction: theta_twice_store_between (p = &cell, q = &g: two globals) and
; theta_twice_store_between_ptr (p, q = the pointer arguments). Below, "the cell" is the 4 cells at p, "the other cell"
; the 4 cells at q; the value names in parentheses are those of the first function / of the _ptr function.
; Checked: the returned value = the cell after both rotations (measured: the phi %22 -> %23 / %26 -> %27); the cell at
; exit (read from the bus) holds that same value; on the DISJOINT path the other cell at exit = its old value + 1.
; Clean: the swap rail of the first form (%4 / %8, |0> after its swap-in); of the increment: the swapped-out old value
; (%14 / %18, rule 6), the inverse t = g' - 1 (%16 / %20) and the rail the cell's |0> went to (%15 / %19). On the DISJOINT
; path also the swap rail of the second form (%18 / %22, |0> after its swap-in).
; Kept: on the DISJOINT path: the load copy of the cell taken after the second swap-in (%19 / %23, measured, rule 2);
; nothing else: three in-place forms keep no rail, no tape slot and no old value. On the OVERLAP path: the load copy of
; the cell (%11 / %15: rotated by the second cq_theta, so a FROZEN register, rule 2; it is also the value rail of the
; kept store and the measured rail) and the tape slot of the kept store (rule 5 sentence 3).
; Rotations: DISJOINT path: (Ry, the cell, t1, 1); (Ry, the cell, t2, 1). OVERLAP path: (Ry, the cell, t1, 1); (Ry, the
; load copy of the cell, t2, 1). The path is chosen by a CLASSICAL run-time branch, never a control.
; Expected for the driver (analytic, not replayed; the trace stubs compute nothing, so each call is stated for the
; content v the cell holds when the call starts; s1 = sin^2(t1/2) = 0.0612087, s2 = sin^2(t2/2) = 0.0155438):
;   theta_twice_store_between(.5, .25) and theta_twice_store_between_ptr(&cell, &g, .5, .25): distinct objects, the
;   DISJOINT path. The trace shows swap, Ry(t1), swap, free on P0; the increment between two swaps on the other
;   address; swap, Ry(t2), swap, free on P0; qram_load_i32_hl(P0), measure of that copy; no qram_store. Ry(.5) then
;   Ry(.25) on every qubit of the cell is Ry(.75) on every qubit: each of the 32 bits of v flips independently with
;   probability s = sin^2(.375) = 0.1341556. P(v') = s^d (1 - s)^(32 - d), d the Hamming distance of v' from v:
;   P(v) = 0.009956, each single-bit neighbour 0.001543 (first call: v = 1, neighbours 0, 3, 5, 9, ...). The increment
;   does not change this; g is one larger after each of the two calls (a HOST cell while address and content are
;   classical-valued, so the swaps write the host bytes, §1.3).
;   theta_twice_store_between_ptr(&cell, &cell, .5, .25): q == p, the OVERLAP path. The trace shows swap, Ry(t1), swap,
;   free on P0; qram_load_i32_hl(P0) BEFORE the increment; the increment between two swaps on P0 itself; Ry(t2) on the
;   load copy; ONE qram_store_i32_hl(P0, the copy); measure of the copy; no second form and no later load. The copy is
;   a basis copy of the cell after Ry(t1), taken before the increment, and Ry(t2) acts on the copy alone: each bit of
;   the measured value differs from v with probability f = s1 (1 - s2) + (1 - s1) s2 = 0.0748497 (NOT Ry(t1 + t2):
;   the cell's own qubits stay entangled with the copy), so P(v) = (1 - f)^32 = 0.082946, each single-bit neighbour
;   0.006711. The kept store puts the copy into the cell (the incremented content goes to the tape slot), so the cell
;   at exit holds the measured value. C gives this call no meaning (two restrict pointers to one object, both written);
;   the lowered code never consults restrict/noalias (rule 21) and is defined for every pair of addresses.
; THE THREE UPDATES (first function; the _ptr function is the same with %0, %1 for @cell, @g and its values two/four
; higher). (1) `%3 = load @cell; %4 = cq_theta(%3, t1); store %4, @cell`: the rotation of a cell, rule 5's in-place
; form with the Ry as its one step (rule 2); the store closes the form, emitted at the store's position.
; (2) `%5 = load @g; %6 = add %5, 1; store %6, @g`: the in-place form with a rule-6 bijection as its step (rule 6, "a
; memory cell"), at the classical address &g. It is a MEMORY VERSION CHANGE. (3) `%7 = cq_theta(%4, t2); store %7, @cell`:
; the operand %4 is the value -O1 forwarded from store (1) to the same SSA pointer, so the interval of this form runs
; from that store (rule 5, Readers), and the change (2) lies inside it. %4 is the result of form (1) and has no rail of
; its own: it lives in the cell. The second cq_theta is the first step of the next form on the same SSA pointer, not
; "another reader" that would end form (1) with a load copy.
; READERS. Nothing is known at compile time about the two addresses: not for @cell and @g (rule 20; §0 "no pointer is
; resolved") and not for the restrict arguments (rule 21: noalias is never consulted). So whether (2) touches the cells
; of p is asked at RUN TIME: the change is an in-place form at the classical address q (S_q = 4 cells), p is classical
; (S_p = 4), and the classical i1 d tests q - p >= 4 && p - q >= 4 (mod 2^64, unsigned): exact for the circular cell
; ranges of §1.3, where p + S_p may wrap.
;   DISJOINT (d = 1): the cell still holds %4 at (3), so no copy is taken and the form stands: swap-out, Ry(t2),
;   swap-in, free. The reader cq_measure(%7) is a later reader of y': a plain load taken after the swap-in, measured.
;   OVERLAP (d = 0): before the change the lowered code takes a plain load of p as %4's copy. The second cq_theta
;   rotates that copy (rule 2: frozen from there on, never un-copied), `store %7, p` is an ordinary kept store of it,
;   and cq_measure(%7) measures the copy rail itself (no second load: that would be a second kept copy).
; d is computed ONCE, immediately before the change, and branched on TWICE; nothing is duplicated: `br d` around the
; copy load, then the change (2) emitted once, then `br d` at the second store's position choosing the form or the
; steps on the copy with the kept store. The copy's handle reaches the second branch through a classical phi whose
; d = 1 incoming is poison (never read on that path); the measured rail is a classical phi of two handles.
; Two distinct globals never overlap, so the first function's OVERLAP blocks are emitted and never run; the _ptr
; function's third driver call runs them.
source_filename = "theta_twice_store_between.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cell = local_unnamed_addr global i32 1, align 4
@g = local_unnamed_addr global i32 0, align 4

define i32 @theta_twice_store_between(double noundef %0, double noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %4 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %3 = load i32, ptr @cell: in-place form (1), the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @cell to i64), i32 %4)    ; IR: %3 = load i32, ptr @cell: swap-out: the rail holds the cell, the cell |0>
  call void @cqrt_ry_i32(i32 %4, double %0)    ; IR: %4 = cq_theta_si32(%3, %0)  [Ry on the cell's content]
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @cell to i64), i32 %4)    ; IR: store i32 %4, ptr @cell: swap-in: the cell holds %4; the store closes form (1)
  call void @cqrt_free(i32 %4)    ; IR: release the swap rail (|0>)
  %5 = sub i64 ptrtoint (ptr @g to i64), ptrtoint (ptr @cell to i64)    ; IR: (no instruction) Readers: q - p mod 2^64, p = the address of @cell, q = that of @g
  %6 = icmp uge i64 %5, 4    ; IR: (no instruction) Readers: q - p >= S_p, S_p = 4 cells
  %7 = sub i64 ptrtoint (ptr @cell to i64), ptrtoint (ptr @g to i64)    ; IR: (no instruction) Readers: p - q mod 2^64
  %8 = icmp uge i64 %7, 4    ; IR: (no instruction) Readers: p - q >= S_q, S_q = 4 cells
  %9 = and i1 %6, %8    ; IR: (no instruction) Readers: d: the cells at p and at q are disjoint (classical, run time), computed immediately before the change
  br i1 %9, label %12, label %10    ; IR: (no instruction) Readers: d = 1 DISJOINT: no copy is taken; d = 0 OVERLAP: the copy below

10:
  %11 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 ptrtoint (ptr @cell to i64))    ; IR: the forwarded %4 as a rail: a plain load of @cell taken before the memory version change (rule 5, Readers)  [OVERLAP path only]
  br label %12    ; IR: (no instruction)

12:
  %13 = phi i32 [ poison, %2 ], [ %11, %10 ]    ; IR: (no instruction) the copy's handle on the OVERLAP path (classical phi; poison, never read, on the DISJOINT path)
  %14 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %5 = load i32, ptr @g: in-place form (2), the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @g to i64), i32 %14)    ; IR: %5 = load i32, ptr @g: swap-out: the rail holds the cell at q, that cell |0>  (the memory version change inside the interval, emitted once)
  %15 = call i32 @cq_template_add_i32_hl(i32 %14, i32 1)    ; IR: %6 = add nsw i32 %5, 1
  %16 = call i32 @cq_template_sub_i32_hl(i32 %15, i32 1)    ; IR: rule 6: t = g' - 1 recomputes the old value
  call void @cqrt_copy_i32(i32 %16, i32 %14)    ; IR: rule 6: the old rail ^= t: |0>
  call void @cq_template_sub_i32_hl_unc(i32 %16, i32 %15, i32 1)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %16)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %14)    ; IR: release the old-value rail (|0> after the copy)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @g to i64), i32 %15)    ; IR: store i32 %6, ptr @g: swap-in: the cell at q holds the sum, the rail that cell's |0>
  call void @cqrt_free(i32 %15)    ; IR: release the rail (|0>): nothing remains of the increment
  br i1 %9, label %17, label %20    ; IR: (no instruction) Readers: the same d, at the second store's position: DISJOINT: form (3) stands; OVERLAP: the steps act on the copy

17:
  %18 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %7 = cq_theta_si32(%4, %1): in-place form (3) on the forwarded %4, the swap rail (|0>)  [DISJOINT path]
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @cell to i64), i32 %18)    ; IR: %7 = cq_theta_si32(%4, %1): swap-out: the rail holds %4 (the cell was not touched by the change), the cell |0>
  call void @cqrt_ry_i32(i32 %18, double %1)    ; IR: %7 = cq_theta_si32(%4, %1)  [Ry on the cell's content]
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @cell to i64), i32 %18)    ; IR: store i32 %7, ptr @cell: swap-in: the cell holds %7
  call void @cqrt_free(i32 %18)    ; IR: release the swap rail (|0>)
  %19 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 ptrtoint (ptr @cell to i64))    ; IR: the reader of %7: a plain load of @cell taken after the swap-in (rule 5, Readers)
  br label %21    ; IR: (no instruction)

20:
  call void @cqrt_ry_i32(i32 %13, double %1)    ; IR: %7 = cq_theta_si32(%4, %1)  [Ry on the load copy: a frozen register from here on, rule 2]  [OVERLAP path]
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 ptrtoint (ptr @cell to i64), i32 %13)    ; IR: store i32 %7, ptr @cell  (a kept store: no _unc, its tape slot and its value rail stay, rule 5 sentence 3)
  br label %21    ; IR: (no instruction)

21:
  %22 = phi i32 [ %19, %17 ], [ %13, %20 ]    ; IR: (no instruction) the rail of %7 for its reader: the load after the swap-in or the copy itself (classical phi of handles)
  %23 = call i32 @cqrt_measure_i32(i32 %22)    ; IR: %8 = cq_measure_si32(%7)  (the measured rail stays allocated, rule 2)
  ret i32 %23    ; IR: ret i32 %8
}

define i32 @theta_twice_store_between_ptr(ptr noundef %0, ptr noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %6 = ptrtoint ptr %0 to i64    ; IR: (no instruction) p: the run-time address in %0, a classical i64 (rule 21)
  %7 = ptrtoint ptr %1 to i64    ; IR: (no instruction) q: the run-time address in %1, a classical i64 (rule 21)
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %5 = load i32, ptr %0: in-place form (1), the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %5, i64 %6, i32 %8)    ; IR: %5 = load i32, ptr %0: swap-out: the rail holds the cell, the cell |0>
  call void @cqrt_ry_i32(i32 %8, double %2)    ; IR: %6 = cq_theta_si32(%5, %2)  [Ry on the cell's content]
  call void @cqrt_qram_swap_i32_hl(i32 %5, i64 %6, i32 %8)    ; IR: store i32 %6, ptr %0: swap-in: the cell holds %6; the store closes form (1)
  call void @cqrt_free(i32 %8)    ; IR: release the swap rail (|0>)
  %9 = sub i64 %7, %6    ; IR: (no instruction) Readers: q - p mod 2^64, p = the address of %0, q = that of %1
  %10 = icmp uge i64 %9, 4    ; IR: (no instruction) Readers: q - p >= S_p, S_p = 4 cells
  %11 = sub i64 %6, %7    ; IR: (no instruction) Readers: p - q mod 2^64
  %12 = icmp uge i64 %11, 4    ; IR: (no instruction) Readers: p - q >= S_q, S_q = 4 cells
  %13 = and i1 %10, %12    ; IR: (no instruction) Readers: d: the cells at p and at q are disjoint (classical, run time), computed immediately before the change
  br i1 %13, label %16, label %14    ; IR: (no instruction) Readers: d = 1 DISJOINT: no copy is taken; d = 0 OVERLAP: the copy below

14:
  %15 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %6)    ; IR: the forwarded %6 as a rail: a plain load of %0 taken before the memory version change (rule 5, Readers)  [OVERLAP path only]
  br label %16    ; IR: (no instruction)

16:
  %17 = phi i32 [ poison, %4 ], [ %15, %14 ]    ; IR: (no instruction) the copy's handle on the OVERLAP path (classical phi; poison, never read, on the DISJOINT path)
  %18 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %7 = load i32, ptr %1: in-place form (2), the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %5, i64 %7, i32 %18)    ; IR: %7 = load i32, ptr %1: swap-out: the rail holds the cell at q, that cell |0>  (the memory version change inside the interval, emitted once)
  %19 = call i32 @cq_template_add_i32_hl(i32 %18, i32 1)    ; IR: %8 = add nsw i32 %7, 1
  %20 = call i32 @cq_template_sub_i32_hl(i32 %19, i32 1)    ; IR: rule 6: t = g' - 1 recomputes the old value
  call void @cqrt_copy_i32(i32 %20, i32 %18)    ; IR: rule 6: the old rail ^= t: |0>
  call void @cq_template_sub_i32_hl_unc(i32 %20, i32 %19, i32 1)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %20)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %18)    ; IR: release the old-value rail (|0> after the copy)
  call void @cqrt_qram_swap_i32_hl(i32 %5, i64 %7, i32 %19)    ; IR: store i32 %8, ptr %1: swap-in: the cell at q holds the sum, the rail that cell's |0>
  call void @cqrt_free(i32 %19)    ; IR: release the rail (|0>): nothing remains of the increment
  br i1 %13, label %21, label %24    ; IR: (no instruction) Readers: the same d, at the second store's position: DISJOINT: form (3) stands; OVERLAP: the steps act on the copy

21:
  %22 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %9 = cq_theta_si32(%6, %3): in-place form (3) on the forwarded %6, the swap rail (|0>)  [DISJOINT path]
  call void @cqrt_qram_swap_i32_hl(i32 %5, i64 %6, i32 %22)    ; IR: %9 = cq_theta_si32(%6, %3): swap-out: the rail holds %6 (the cell was not touched by the change), the cell |0>
  call void @cqrt_ry_i32(i32 %22, double %3)    ; IR: %9 = cq_theta_si32(%6, %3)  [Ry on the cell's content]
  call void @cqrt_qram_swap_i32_hl(i32 %5, i64 %6, i32 %22)    ; IR: store i32 %9, ptr %0: swap-in: the cell holds %9
  call void @cqrt_free(i32 %22)    ; IR: release the swap rail (|0>)
  %23 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %6)    ; IR: the reader of %9: a plain load of %0 taken after the swap-in (rule 5, Readers)
  br label %25    ; IR: (no instruction)

24:
  call void @cqrt_ry_i32(i32 %17, double %3)    ; IR: %9 = cq_theta_si32(%6, %3)  [Ry on the load copy: a frozen register from here on, rule 2]  [OVERLAP path]
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %6, i32 %17)    ; IR: store i32 %9, ptr %0  (a kept store: no _unc, its tape slot and its value rail stay, rule 5 sentence 3)
  br label %25    ; IR: (no instruction)

25:
  %26 = phi i32 [ %23, %21 ], [ %17, %24 ]    ; IR: (no instruction) the rail of %9 for its reader: the load after the swap-in or the copy itself (classical phi of handles)
  %27 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: %10 = cq_measure_si32(%9)  (the measured rail stays allocated, rule 2)
  ret i32 %27    ; IR: ret i32 %10
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
