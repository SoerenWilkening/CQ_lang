; HAND-WRITTEN. Rules: 26, 22, 20, 21, 16, 18, 5 (in-place form, Readers clause), 7, 2, 3, 4; §1.3, §1.4.
; Checked: sum3(p, c) = p.a + p.b * c + p.c (the clone's copied-out result rail, measured, both entries); the cells of
; the caller's block of p at exit (read from the bus at its address): a = the rotated register, b, c as stored (_two: b
; the rotated register too); the cells of the byval copy at exit: the same 24 bytes. Both paths of each run-time
; disjointness test d (below) give these values.
; Clean: on each DISJOINT path (d = 1) the swap rail of the in-place form (|0> after its swap-in, freed); inside
; __cq_q_sum3_00 (both calls): the three load copies p.a, p.b, p.c (un-copied after their last reader,
; no memory version change follows them in the clone, rule 5 sentence 1) and the template rails b * c, the two adds
; (uncomputed by their _unc after the copy-out, rule 18).
; Kept: on each DISJOINT path the cell that holds the rotated register (p.a in _one; p.a and p.b in _two: rotated in
; place, rule 5's in-place form); on each OVERLAP path (d = 0) the load copy of the cell taken before the first
; intervening store (rotated, so a FROZEN register, rule 2; the value rail of the kept store) and that kept store's tape
; slot (rule 5 sentence 3); the measured result rail (rule 2; no twin is called); by rule 5 (sentence 3) and rule
; 7: the three seed stores of the initializer {x0, b, c} / {x0, y0, c} with their seeds (tape slot + seed rail each);
; by rule 22: the 24 byte load copies of
; the byval copy, each the value rail of a kept byte store, and the 24 byte stores' tape slots.
; Rotations: byval_large_one: DISJOINT (Ry, p.a, tx, 1); OVERLAP (Ry, the load copy of p.a, tx, 1).
; byval_large_two: (Ry, p.a, tx, 1) on DISJOINT d_a, (Ry, the load copy of p.a, tx, 1) on OVERLAP d_a; then (Ry, p.b,
; ty, 1) on DISJOINT d_b, (Ry, the load copy of p.b, ty, 1) on OVERLAP d_b. Each path is chosen by a CLASSICAL run-time
; branch, never a control.
; Expected (driver): the three cells of one 24-byte block never overlap, so every d is 1 and every OVERLAP block is
; emitted and never runs. byval_large_one(0, .5, 2, 3) measures a + 2 * 3 + 3 = a + 9, a = 0 with every bit flipped
; independently with p = sin^2(.25) = 0.061209 (P(9) = (1 - p)^64 = 0.0176); byval_large_two(0, .5, 1, .25, 3) measures
; a + 3 * b + 3, b = 1 with every bit flipped with q = sin^2(.125) = 0.015544 (the unflipped branch a = 0, b = 1 gives 6 with (1 - p)^64 (1 - q)^64 = 0.0064).
; ONE BUS (rules 20, 21, 26). A 24-byte struct passed BY VALUE travels as a `byval` pointer to a caller-made copy. The
; caller's alloca %struct.big is BUS-RESIDENT (rule 20 (b): a store of a tainted value and the call are among its
; users), so it is __cq_alloc(24, 8) at its program point and its lifetime markers are dropped (rule 16). The struct
; initializer is three ordinary kept bus stores at the run-time addresses p, p + 8, p + 16, each value a seed (rule 7).
; cq_theta(&p.a, tx) is, after -O1, cq_theta_sl on the parameter x0 forwarded from the store to cell a, followed by
; `store %8, ptr %5` to the same cell: rule 5's IN-PLACE FORM on the cell, whose interval runs from the store of x0
; (rule 5, Readers: the forwarded y). The same for p.b in _two (y0 forwarded from the store to cell b).
; READERS (rule 5). The interval of each form holds memory version changes: in _one the stores to b and c lie between
; the store of x0 and the rotation; in _two the form on a has the stores to b and c in its interval, and the form on b
; has the store to c and the form (or kept store) on a in its. Every change is a bus store or in-place form at a
; classical address (S_q = 8 cells) and every cell address is a getelementptr/ptrtoint chain over the block's address,
; computable before the first change (the lowered code computes the chain of c there, ahead of where -O1 places it).
; So d is the AND of one test per change, q - p >= 8 && p - q >= 8 (mod 2^64, unsigned, S_p = 8), computed ONCE
; immediately before the first change of the interval, where the one copy is taken, and branched on TWICE: `br d`
; around a plain load of p (the copy, taken when d = 0), the changes emitted once, then `br d` at the rotation's store:
;   DISJOINT (d = 1): the cell still holds the forwarded value; the in-place form stands: alloc_i64(0),
;   qram_swap_i64_hl (the rail holds the cell, the cell |0>), the Ry on the rail, qram_swap_i64_hl back, free.
;   OVERLAP (d = 0): the Ry acts on the copy (frozen from there on, never un-copied) and the store is an ordinary kept
;   store of it.
; The copy's handle reaches the second branch through a classical phi whose d = 1 incoming is poison. The rotated value
; has no SSA reader (the byval copy reads the block through the bus), so no join phi of handles follows the form.
; In _two the two intervals interleave: d_a and a's copy come before the store to b, d_b and b's copy after it and
; before the store to c; a's second branch precedes b's (the program order of the two rotations).
; THE BYVAL COPY (rule 26): at the call the caller makes the copy, q = __cq_alloc(24, 8) (the byval's size and align),
; and a rule-22 bus copy of 24 bytes from p to q: a host loop of 24 qram_load_i8_hl at p + j, each handle pushed, then a
; host loop of 24 qram_store_i8_hl at q + j popping them (bytes 23 down to 0); every byte store is kept with its load
; copy as value rail (rule 22). The call passes q as a PLAIN pointer: no `byval` on a lowered call, and the callee is
; the plain-ptr form of §1.4, spelled by the clone grammar even with the all-zero mask: q is a classical ptr (digit 0)
; and c classical (digit 0), so both entries call the ONE clone __cq_q_sum3_00. Nothing about the pointee (which fields
; are quantum) crosses the call. sum3's own symbol keeps the C signature for host callers; it is internal and has no
; caller left, so it is dropped (§1.4).
; THE CLONE (rules 3, 18): every load is a bus load and its result is a rail, also in the all-zero mask, so all three
; fields are rails whatever the caller stored (over-taint, §0: a classical-valued rail costs no qubit), and the result
; is a rail. It forms the sum out of place (mul_i64_hl, then two add_i64 of rails), copies the result into a fresh
; rail and uncomputes its chain; each load copy is un-copied right after its last reader (the _unc of its consumer).
; The clone writes no memory, so a twin could exist; the caller measures the result (rule 2: the measured rail stays),
; so no twin is called and none is defined (§1.4).
; SPEC GAP (rule 26, byval): the copy is made at the call's program point, immediately before the call: __cq_alloc,
; then rule 22's load loop over the source and its store loop into q.
source_filename = "byval_large.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @byval_large_one(i64 noundef %0, double noundef %1, i64 noundef %2, i64 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %6 = call ptr @__cq_alloc(i64 24, i64 8)    ; IR: %5 = alloca %struct.big, align 8: bus-resident (rule 20), one zeroed block (rule 16); llvm.lifetime.start dropped
  %7 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address (cell a)
  %8 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: store i64 %0, ptr %5: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i64_hl(i32 %5, i64 %7, i32 %8)    ; IR: store i64 %0, ptr %5  (kept store, rule 5); the interval of the form on cell a starts here (x0 is forwarded)
  %9 = getelementptr inbounds i8, ptr %6, i64 8    ; IR: %6 = getelementptr inbounds i8, ptr %5, i64 8  (nothing tainted: the gep stays)
  %10 = ptrtoint ptr %9 to i64    ; IR: %6 as its run-time address (cell b)
  %11 = getelementptr inbounds i8, ptr %6, i64 16    ; IR: %7 = getelementptr inbounds i8, ptr %5, i64 16  (computed here, before the first change: rule 5, Readers)
  %12 = ptrtoint ptr %11 to i64    ; IR: %7 as its run-time address (cell c)
  %13 = sub i64 %10, %7    ; IR: (no instruction) Readers: q - p mod 2^64, p = cell a, q = cell b (the first change)
  %14 = icmp uge i64 %13, 8    ; IR: (no instruction) Readers: q - p >= S_p, S_p = 8 cells
  %15 = sub i64 %7, %10    ; IR: (no instruction) Readers: p - q mod 2^64
  %16 = icmp uge i64 %15, 8    ; IR: (no instruction) Readers: p - q >= S_q, S_q = 8 cells
  %17 = and i1 %14, %16    ; IR: (no instruction) Readers: cells a and b disjoint
  %18 = sub i64 %12, %7    ; IR: (no instruction) Readers: q - p mod 2^64, q = cell c (the second change)
  %19 = icmp uge i64 %18, 8    ; IR: (no instruction) Readers: q - p >= S_p
  %20 = sub i64 %7, %12    ; IR: (no instruction) Readers: p - q mod 2^64
  %21 = icmp uge i64 %20, 8    ; IR: (no instruction) Readers: p - q >= S_q
  %22 = and i1 %19, %21    ; IR: (no instruction) Readers: cells a and c disjoint
  %23 = and i1 %17, %22    ; IR: (no instruction) Readers: d = the AND of the tests of both changes, computed immediately before the first of them
  br i1 %23, label %26, label %24    ; IR: (no instruction) Readers: d = 1 DISJOINT: no copy is taken; d = 0 OVERLAP: the copy below

24:
  %25 = call i32 @cqrt_qram_load_i64_hl(i32 %5, i64 %7)    ; IR: the forwarded %0 as a rail: a plain load of %5 taken before the memory version changes (rule 5, Readers)  [OVERLAP path only]
  br label %26    ; IR: (no instruction)

26:
  %27 = phi i32 [ poison, %4 ], [ %25, %24 ]    ; IR: (no instruction) the copy's handle on the OVERLAP path (classical phi; poison, never read, on the DISJOINT path)
  %28 = call i32 @cqrt_alloc_i64(i64 %2)    ; IR: store i64 %2, ptr %6: the seed (rule 7)
  call void @cqrt_qram_store_i64_hl(i32 %5, i64 %10, i32 %28)    ; IR: store i64 %2, ptr %6  (kept store; a memory version change in the interval, emitted once)
  %29 = call i32 @cqrt_alloc_i64(i64 %3)    ; IR: store i64 %3, ptr %7: the seed (rule 7)
  call void @cqrt_qram_store_i64_hl(i32 %5, i64 %12, i32 %29)    ; IR: store i64 %3, ptr %7  (kept store; a memory version change in the interval, emitted once)
  br i1 %23, label %30, label %32    ; IR: (no instruction) Readers: the same d, at the store's position: DISJOINT: the form stands; OVERLAP: the step acts on the copy

30:
  %31 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: %8 = cq_theta_sl(%0, %1); store i64 %8, ptr %5: %0 is forwarded from the store to the same cell: in-place form, the swap rail (|0>)  [DISJOINT path]
  call void @cqrt_qram_swap_i64_hl(i32 %5, i64 %7, i32 %31)    ; IR: %8 = cq_theta_sl(%0, %1): swap-out: the rail holds the cell's %0 (untouched by the changes), the cell |0>
  call void @cqrt_ry_i64(i32 %31, double %1)    ; IR: %8 = cq_theta_sl(%0, %1)  [Ry in place on p.a]
  call void @cqrt_qram_swap_i64_hl(i32 %5, i64 %7, i32 %31)    ; IR: store i64 %8, ptr %5: swap-in: the cell holds register p.a
  call void @cqrt_free(i32 %31)    ; IR: release the swap rail (|0>)
  br label %33    ; IR: (no instruction)

32:
  call void @cqrt_ry_i64(i32 %27, double %1)    ; IR: %8 = cq_theta_sl(%0, %1)  [Ry on the load copy: a frozen register from here on, rule 2]  [OVERLAP path]
  call void @cqrt_qram_store_i64_hl(i32 %5, i64 %7, i32 %27)    ; IR: store i64 %8, ptr %5  (a kept store: no _unc, its tape slot and its value rail stay, rule 5 sentence 3)
  br label %33    ; IR: (no instruction)

33:
  %34 = call ptr @__cq_alloc(i64 24, i64 8)    ; IR: %9 = call @sum3(byval(%struct.big) align 8 %5, ...): the byval copy q (rule 26)
  %35 = ptrtoint ptr %34 to i64    ; IR: q as its run-time address
  br label %36    ; IR: the byval copy: a rule-22 bus copy of 24 bytes from %5 to q (load all, then store all)

36:
  %37 = phi i64 [ 0, %33 ], [ %40, %36 ]    ; byte index of the load loop (classical)
  %38 = add i64 %7, %37    ; the source byte's address (classical)
  %39 = call i32 @cqrt_qram_load_i8_hl(i32 %5, i64 %38)    ; IR: byval copy  [source byte j: a bus load; the copy is the value rail of byte j's store, KEPT (rule 22)]
  call void @cqrt_push(i32 %39)    ; the handle outlives its SSA value (§1.1, rule 22)
  %40 = add nuw nsw i64 %37, 1
  %41 = icmp eq i64 %40, 24
  br i1 %41, label %42, label %36

42:
  %43 = phi i64 [ 24, %36 ], [ %44, %42 ]    ; bytes left to store (classical)
  %44 = add nsw i64 %43, -1    ; byte index of this store: 23 down to 0 (the pop order)
  %45 = call i32 @cqrt_pop()    ; the load copy of byte %44
  %46 = add i64 %35, %44    ; the destination byte's address (classical)
  call void @cqrt_qram_store_i8_hl(i32 %5, i64 %46, i32 %45)    ; IR: byval copy  [destination byte: a kept store (rule 22)]
  %47 = icmp eq i64 %44, 0
  br i1 %47, label %48, label %42

48:
  %49 = call fastcc i32 @__cq_q_sum3_00(ptr noundef %34, i64 noundef %3)    ; IR: %9 = call fastcc @sum3(ptr byval %5, i64 %3): the plain-ptr form (§1.4, rule 26), mask 00 (classical q, classical c); the result rail
  %50 = call i64 @cqrt_measure_i64(i32 %49)    ; IR: %10 = cq_measure_sl(%9)  (the measured rail stays allocated; no twin, rule 2)
  ret i64 %50    ; IR: llvm.lifetime.end(%5) dropped (rule 16); ret i64 %10
}

define internal fastcc i32 @__cq_q_sum3_00(ptr noundef %0, i64 noundef %1) unnamed_addr {
  %3 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %4 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address (mask digit 0: the formal is the C ptr)
  %5 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %4)    ; IR: %3 = load i64, ptr %0  [p.a: every load is a bus load, a rail (rule 3)]
  %6 = getelementptr inbounds i8, ptr %0, i64 8    ; IR: %4 = getelementptr inbounds i8, ptr %0, i64 8  (nothing tainted: the gep stays)
  %7 = ptrtoint ptr %6 to i64    ; IR: %4 as its run-time address
  %8 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %7)    ; IR: %5 = load i64, ptr %4  [p.b, a rail]
  %9 = call i32 @cq_template_mul_i64_hl(i32 %8, i64 %1)    ; IR: %6 = mul nsw i64 %5, %1
  %10 = call i32 @cq_template_add_i64(i32 %9, i32 %5)    ; IR: %7 = add nsw i64 %6, %3
  %11 = getelementptr inbounds i8, ptr %0, i64 16    ; IR: %8 = getelementptr inbounds i8, ptr %0, i64 16
  %12 = ptrtoint ptr %11 to i64    ; IR: %8 as its run-time address
  %13 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %12)    ; IR: %9 = load i64, ptr %8  [p.c, a rail]
  %14 = call i32 @cq_template_add_i64(i32 %10, i32 %13)    ; IR: %10 = add nsw i64 %7, %9
  %15 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: ret i64 %10  [result rail of the call]
  call void @cqrt_copy_i64(i32 %14, i32 %15)    ; IR: copy the result out (rule 18)
  call void @cq_template_add_i64_unc(i32 %14, i32 %10, i32 %13)    ; IR: uncompute %10
  call void @cqrt_free(i32 %14)    ; IR: release the %10 rail (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %13, i32 %3, i64 %12)    ; IR: un-copy %9 (its last reader is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %13)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i64_unc(i32 %10, i32 %9, i32 %5)    ; IR: uncompute %7
  call void @cqrt_free(i32 %10)    ; IR: release the %7 rail (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %5, i32 %3, i64 %4)    ; IR: un-copy %3
  call void @cqrt_free(i32 %5)    ; IR: release the %3 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %9, i32 %8, i64 %1)    ; IR: uncompute %6
  call void @cqrt_free(i32 %9)    ; IR: release the %6 rail (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %8, i32 %3, i64 %7)    ; IR: un-copy %5
  call void @cqrt_free(i32 %8)    ; IR: release the %5 rail (|0>)
  ret i32 %15    ; IR: ret i64 %10
}

define i64 @byval_large_two(i64 noundef %0, double noundef %1, i64 noundef %2, double noundef %3, i64 noundef %4) {
  %6 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %7 = call ptr @__cq_alloc(i64 24, i64 8)    ; IR: %6 = alloca %struct.big, align 8: bus-resident (rule 20), one zeroed block (rule 16); llvm.lifetime.start dropped
  %8 = ptrtoint ptr %7 to i64    ; IR: %6 as its run-time address (cell a)
  %9 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: store i64 %0, ptr %6: the seed (rule 7)
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %8, i32 %9)    ; IR: store i64 %0, ptr %6  (kept store); the interval of the form on cell a starts here (x0 is forwarded)
  %10 = getelementptr inbounds i8, ptr %7, i64 8    ; IR: %7 = getelementptr inbounds i8, ptr %6, i64 8  (nothing tainted: the gep stays)
  %11 = ptrtoint ptr %10 to i64    ; IR: %7 as its run-time address (cell b)
  %12 = getelementptr inbounds i8, ptr %7, i64 16    ; IR: %8 = getelementptr inbounds i8, ptr %6, i64 16  (computed here, before the first change of a's interval: rule 5, Readers)
  %13 = ptrtoint ptr %12 to i64    ; IR: %8 as its run-time address (cell c)
  %14 = sub i64 %11, %8    ; IR: (no instruction) Readers (form on a): q - p mod 2^64, p = cell a, q = cell b (the first change)
  %15 = icmp uge i64 %14, 8    ; IR: (no instruction) Readers: q - p >= S_p, S_p = 8 cells
  %16 = sub i64 %8, %11    ; IR: (no instruction) Readers: p - q mod 2^64
  %17 = icmp uge i64 %16, 8    ; IR: (no instruction) Readers: p - q >= S_q, S_q = 8 cells
  %18 = and i1 %15, %17    ; IR: (no instruction) Readers: cells a and b disjoint
  %19 = sub i64 %13, %8    ; IR: (no instruction) Readers: q - p mod 2^64, q = cell c (the second change)
  %20 = icmp uge i64 %19, 8    ; IR: (no instruction) Readers: q - p >= S_p
  %21 = sub i64 %8, %13    ; IR: (no instruction) Readers: p - q mod 2^64
  %22 = icmp uge i64 %21, 8    ; IR: (no instruction) Readers: p - q >= S_q
  %23 = and i1 %20, %22    ; IR: (no instruction) Readers: cells a and c disjoint
  %24 = and i1 %18, %23    ; IR: (no instruction) Readers: d_a = the AND of the tests of both changes, computed immediately before the first of them
  br i1 %24, label %27, label %25    ; IR: (no instruction) Readers: d_a = 1 DISJOINT: no copy is taken; d_a = 0 OVERLAP: the copy below

25:
  %26 = call i32 @cqrt_qram_load_i64_hl(i32 %6, i64 %8)    ; IR: the forwarded %0 as a rail: a plain load of %6 taken before the memory version changes (rule 5, Readers)  [OVERLAP a path only]
  br label %27    ; IR: (no instruction)

27:
  %28 = phi i32 [ poison, %5 ], [ %26, %25 ]    ; IR: (no instruction) a's copy handle on the OVERLAP a path (classical phi; poison, never read, on the DISJOINT path)
  %29 = call i32 @cqrt_alloc_i64(i64 %2)    ; IR: store i64 %2, ptr %7: the seed (rule 7)
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %11, i32 %29)    ; IR: store i64 %2, ptr %7  (kept store; a change in a's interval, emitted once); the interval of the form on cell b starts here (y0 is forwarded)
  %30 = sub i64 %13, %11    ; IR: (no instruction) Readers (form on b): q - p mod 2^64, p = cell b, q = cell c (the first change)
  %31 = icmp uge i64 %30, 8    ; IR: (no instruction) Readers: q - p >= S_p, S_p = 8 cells
  %32 = sub i64 %11, %13    ; IR: (no instruction) Readers: p - q mod 2^64
  %33 = icmp uge i64 %32, 8    ; IR: (no instruction) Readers: p - q >= S_q, S_q = 8 cells
  %34 = and i1 %31, %33    ; IR: (no instruction) Readers: cells b and c disjoint
  %35 = sub i64 %8, %11    ; IR: (no instruction) Readers: q - p mod 2^64, q = cell a (the second change: a's form or kept store)
  %36 = icmp uge i64 %35, 8    ; IR: (no instruction) Readers: q - p >= S_p
  %37 = sub i64 %11, %8    ; IR: (no instruction) Readers: p - q mod 2^64
  %38 = icmp uge i64 %37, 8    ; IR: (no instruction) Readers: p - q >= S_q
  %39 = and i1 %36, %38    ; IR: (no instruction) Readers: cells b and a disjoint
  %40 = and i1 %34, %39    ; IR: (no instruction) Readers: d_b = the AND of the tests of both changes, computed immediately before the first of them
  br i1 %40, label %43, label %41    ; IR: (no instruction) Readers: d_b = 1 DISJOINT: no copy is taken; d_b = 0 OVERLAP: the copy below

41:
  %42 = call i32 @cqrt_qram_load_i64_hl(i32 %6, i64 %11)    ; IR: the forwarded %2 as a rail: a plain load of %7 taken before the memory version changes (rule 5, Readers)  [OVERLAP b path only]
  br label %43    ; IR: (no instruction)

43:
  %44 = phi i32 [ poison, %27 ], [ %42, %41 ]    ; IR: (no instruction) b's copy handle on the OVERLAP b path (classical phi; poison, never read, on the DISJOINT path)
  %45 = call i32 @cqrt_alloc_i64(i64 %4)    ; IR: store i64 %4, ptr %8: the seed (rule 7)
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %13, i32 %45)    ; IR: store i64 %4, ptr %8  (kept store; a change in both intervals, emitted once)
  br i1 %24, label %46, label %48    ; IR: (no instruction) Readers: d_a, at the store to a's position: DISJOINT: the form stands; OVERLAP: the step acts on a's copy

46:
  %47 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: %9 = cq_theta_sl(%0, %1); store i64 %9, ptr %6: %0 is forwarded from the store to the same cell: in-place form, the swap rail (|0>)  [DISJOINT a path]
  call void @cqrt_qram_swap_i64_hl(i32 %6, i64 %8, i32 %47)    ; IR: %9 = cq_theta_sl(%0, %1): swap-out: the rail holds the cell's %0 (untouched by the changes), the cell |0>
  call void @cqrt_ry_i64(i32 %47, double %1)    ; IR: %9 = cq_theta_sl(%0, %1)  [Ry in place on p.a]
  call void @cqrt_qram_swap_i64_hl(i32 %6, i64 %8, i32 %47)    ; IR: store i64 %9, ptr %6: swap-in: the cell holds register p.a (a change in b's interval)
  call void @cqrt_free(i32 %47)    ; IR: release the swap rail (|0>)
  br label %49    ; IR: (no instruction)

48:
  call void @cqrt_ry_i64(i32 %28, double %1)    ; IR: %9 = cq_theta_sl(%0, %1)  [Ry on a's load copy: a frozen register from here on, rule 2]  [OVERLAP a path]
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %8, i32 %28)    ; IR: store i64 %9, ptr %6  (a kept store: no _unc, its tape slot and its value rail stay, rule 5 sentence 3; a change in b's interval)
  br label %49    ; IR: (no instruction)

49:
  br i1 %40, label %50, label %52    ; IR: (no instruction) Readers: d_b, at the store to b's position: DISJOINT: the form stands; OVERLAP: the step acts on b's copy

50:
  %51 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: %10 = cq_theta_sl(%2, %3); store i64 %10, ptr %7: %2 is forwarded from the store to the same cell: in-place form, the swap rail (|0>)  [DISJOINT b path]
  call void @cqrt_qram_swap_i64_hl(i32 %6, i64 %11, i32 %51)    ; IR: %10 = cq_theta_sl(%2, %3): swap-out: the rail holds the cell's %2 (untouched by the changes), the cell |0>
  call void @cqrt_ry_i64(i32 %51, double %3)    ; IR: %10 = cq_theta_sl(%2, %3)  [Ry in place on p.b]
  call void @cqrt_qram_swap_i64_hl(i32 %6, i64 %11, i32 %51)    ; IR: store i64 %10, ptr %7: swap-in: the cell holds register p.b
  call void @cqrt_free(i32 %51)    ; IR: release the swap rail (|0>)
  br label %53    ; IR: (no instruction)

52:
  call void @cqrt_ry_i64(i32 %44, double %3)    ; IR: %10 = cq_theta_sl(%2, %3)  [Ry on b's load copy: a frozen register from here on, rule 2]  [OVERLAP b path]
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %11, i32 %44)    ; IR: store i64 %10, ptr %7  (a kept store: no _unc, its tape slot and its value rail stay, rule 5 sentence 3)
  br label %53    ; IR: (no instruction)

53:
  %54 = call ptr @__cq_alloc(i64 24, i64 8)    ; IR: %11 = call @sum3(byval(%struct.big) align 8 %6, ...): the byval copy q (rule 26)
  %55 = ptrtoint ptr %54 to i64    ; IR: q as its run-time address
  br label %56    ; IR: the byval copy: a rule-22 bus copy of 24 bytes from %6 to q (load all, then store all)

56:
  %57 = phi i64 [ 0, %53 ], [ %60, %56 ]    ; byte index of the load loop (classical)
  %58 = add i64 %8, %57    ; the source byte's address (classical)
  %59 = call i32 @cqrt_qram_load_i8_hl(i32 %6, i64 %58)    ; IR: byval copy  [source byte j: a bus load; the copy is the value rail of byte j's store, KEPT (rule 22)]
  call void @cqrt_push(i32 %59)    ; the handle outlives its SSA value (§1.1, rule 22)
  %60 = add nuw nsw i64 %57, 1
  %61 = icmp eq i64 %60, 24
  br i1 %61, label %62, label %56

62:
  %63 = phi i64 [ 24, %56 ], [ %64, %62 ]    ; bytes left to store (classical)
  %64 = add nsw i64 %63, -1    ; byte index of this store: 23 down to 0 (the pop order)
  %65 = call i32 @cqrt_pop()    ; the load copy of byte %64
  %66 = add i64 %55, %64    ; the destination byte's address (classical)
  call void @cqrt_qram_store_i8_hl(i32 %6, i64 %66, i32 %65)    ; IR: byval copy  [destination byte: a kept store (rule 22)]
  %67 = icmp eq i64 %64, 0
  br i1 %67, label %68, label %62

68:
  %69 = call fastcc i32 @__cq_q_sum3_00(ptr noundef %54, i64 noundef %4)    ; IR: %11 = call fastcc @sum3(ptr byval %6, i64 %4): the same plain-ptr clone, mask 00; the result rail
  %70 = call i64 @cqrt_measure_i64(i32 %69)    ; IR: %12 = cq_measure_sl(%11)  (the measured rail stays allocated; no twin, rule 2)
  ret i64 %70    ; IR: llvm.lifetime.end(%6) dropped (rule 16); ret i64 %12
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i64(i32, double)
declare void @cqrt_copy_i64(i32, i32)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i64_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i64 @cqrt_measure_i64(i32)
