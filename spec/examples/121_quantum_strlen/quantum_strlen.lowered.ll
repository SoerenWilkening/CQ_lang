; HAND-WRITTEN. Rules: 2, 3, 4, 5, 7, 8, 9, 14, 15, 16, 20, 21; §1.3 (the bus, __cq_mem, __cq_alloc, qram_swap).
; Checked: quantum_strlen's n (the result rail %39 of the after-loop select, through %56, measured into %57);
; quantum_strcmp's `i < cap ? a[i] - b[i] : 0` (the copied-out result %107 -> %108, measured). The cells on the bus
; at exit, read at each block's address: s[i] (strlen), a[i] and b[i] (strcmp) = Ry(th[i]) (resp. Ry(ta[i]),
; Ry(tb[i])) applied to 'a' (97) for i < cap, 0 for cap <= i < 4 (the zero store; zeroed __cq_alloc memory).
; Clean: every trip rail (the trip predicates, exit flags, per-trip selects, strcmp's difference and its sexts), popped
; and uncomputed by the reverse loop; every load copy of a cell in the scan loops (strlen's s[i]; strcmp's a[i], b[i] in
; block %33 and b[i] again in block %37), each pushed with its trip and un-copied in the reverse loop right after its
; last reader's _unc, under the control it was loaded with (rule 5 sentence 1: no memory version change follows the
; fill loop); the swap rail of each in-place form (|0> after the swap-in, freed); the |1> seed and the chain's |0>
; seed rail, freed directly (rule 7).
; Kept: the cells s[i] (strlen) and a[i], b[i] (strcmp): the registers live on the bus, rotated in place by rule 5's
; in-place form. By rule 5 sentence 3, the tape slot of every bus store with its value seed (rule 7): the zero
; initializer `store i32 0` of each block (alloc_i32(0)) and each trip's `store i8 97` (alloc_i8(97)); strcmp's
; OVERLAP path (d = 0, never taken at run time: a and b are distinct blocks) adds the kept store of b[i] with its
; rotated load copy as value rail (frozen, rule 2). By rule 5 sentence 1, the angle load copies th[i], ta[i], tb[i]
; (each overtaken by the in-place form, a memory version change: un-copied after its last reader, the Ry, past the
; form's second swap, and left allocated). The measured result rail. No predicate is kept: the bound cap is classical, so every trip and
; exit predicate, the last trip's a_last included, is a function of the inputs and is uncomputed by the reverse loop
; (rule 14, classical bound with a quantum exit); no bus access is under a predicate that controls a store.
; Rotations: (Ry, s[i], A_i, 1) per trip i of the fill loop, A_i the f64 angle rail loaded from th[i] (rule 15: a loaded
; angle is a rail, rule 3); (Ry, a[i], ta[i] rail, 1), (Ry, b[i], tb[i] rail, 1) per trip i, each in place on its cell
; through the form's swap rail (on strcmp's OVERLAP path, b[i]'s Ry acts on the load copy instead).
; A STRING SEARCH OVER QUANTUM CHARS: -O1 turns `while (n < cap && s[n] != 0) n++` into a classical counted loop over
; cap (the buffer bound) with a quantum EARLY EXIT, and computes n from the classical induction variable in the exit
; block (%28 = trunc %20) merged by the exit phi %30 [0 (cap <= 0), %28 (NUL at trip i), %1 (no NUL)]. So n is never a
; loop-carried quantum value: which EXIT is taken is quantum. The loop stays a classical loop of cap trips (26's shape)
; under the trip predicate a_i = a_(i-1) & NOT z_i (seed |1>), and each exit gets its own predicate: e_i = a_(i-1) & z_i
; for the NUL exit at trip i, a_last for the fall-through exit. These predicates are MUTUALLY EXCLUSIVE and exactly one is
; 1. The exit phi is merged per rule 9: one cq_template_select_i32 per incoming, chained with the complement arm innermost
; into fresh rails: r_i = select(e_i, i, r_(i-1)) in trip i (the literal incoming %28 is the trip index: _lh), seeded by
; a |0> rail (the incoming 0 of the cap <= 0 edge; a seed, rule 7), and after the loop r = select(a_last, cap, r_last),
; the result. Each trip pushes its load copy, its predicates and r_(i-1); a reverse loop pops them, uncomputes r_i by its
; select's _unc, then the predicates and the test, and un-copies the load (the result does not depend on them staying
; alive).
; quantum_strcmp has two quantum exits from one trip into the same exit block %37 (NUL in a, or a[i] != b[i]): the exit
; flag of the trip is x_i = e1_i | e2_i (or_i1 into a fresh flag, rule 8; e1, e2 exclusive), the block's value
; d = a[i] - b[i] (classical trip index i, quantum chars) is computed unconditionally (pure), merged by
; r_i = select(x_i, d, r_(i-1)); d and its two sexts stay alive (pushed with the trip) and the reverse trip uncomputes
; r_i, x_i, d and the sexts in exact LIFO order (rule 5);
; the fall-through exit and the cap <= 0 edge contribute 0, the value of the |0> seed, so no select is spent on them. The
; last trip's r is copied out (alloc + copy, rule 14) and the reverse loop uncomputes every trip's r.
; ONE BUS (rules 16, 20, 21). Each `char x[4]` is stored to with a tainted value (the cq_theta result), a user rule 20 (b)
; does not allow, so it is BUS-RESIDENT: __cq_alloc(4, 4) at the alloca's program point (zeroed host memory at an
; address never reused), no alloca remains and the lifetime markers are dropped (rule 16). Its base is its run-time
; address, a classical i64, and every gep below has untainted indices, so every access is _hl at a classical address.
; m = __cq_mem() is called once, at entry (§5). th, ta, tb are pointer arguments: their loads are bus loads (rule 20),
; so each angle is an f64 rail and each rotation is cqrt_ry_i8_qangle (rule 15).
; The punned zero initializer `store i32 0, ptr x` is a bus store of the seed alloc_i32(0) (rule 20: a classical value
; is first a seed), kept (rule 5 sentence 3), classical-valued: the cells stay HOST.
; The fill loop: `store i8 97, ptr p; t = load th[i]; y' = cq_theta_c(97, t); store i8 y', ptr p`. The store of 97 is a
; kept store of the seed alloc_i8(97). -O1 forwarded 97 to the cq_theta: by rule 5's Readers clause the interval of the
; in-place form runs from that store to the store of y' on the same SSA pointer, so the cq_theta is the form (rule 2):
; alloc_i8(0), qram_swap_i8_hl (the rail holds 97, the cell |0>), the Ry, qram_swap_i8_hl back, free, emitted at the
; second store's position. The angle load is a load a step reads: a plain load at its own program point, before the
; swap-out, overtaken by the form: un-copied after the second swap and not freed (rule 5, the `*p += *q` case).
; SPEC GAP: rule 2's first sentence ("cq_theta on a classical v mints alloc_<W>(v) then ry") and rule 5's Readers clause
; (y forwarded from the preceding store) both read on `cq_theta_c(97, ...)` stored back through the pointer the 97 was
; stored to. The Readers clause is taken (the form, as 206); the other reading (a fresh seed rotated and a second kept
; store of it) leaves the same cell value and differs only in which rails are kept.
; The angle rail is un-copied after the form (rule 15's 'uncomputed afterwards', rule 5 sentence 1) and, overtaken by
; the form, left allocated.
; In strcmp the interval of b[i]'s form (store 97 to b[i] .. store %22 to b[i]) contains two memory version changes at
; the classical address a[i]: the store of 97 to a[i] and a[i]'s own form. The Readers clause applies with p = &b[i]
; and q = &a[i] (S_p = S_q = 1): d is the AND of the two changes' tests (q - p >= 1 && p - q >= 1, mod 2^64, unsigned),
; computed before the first change; br d around the plain load of b[i] (the copy, taken when d = 0), the changes
; emitted once, then br d at the store's position: d = 1 the form on b[i], d = 0 the Ry on the copy (frozen, rule 2)
; and a kept store. a[i]'s own interval contains no change: its form stands with no test.
; The scan loops: each load of a cell is a bus load (a rail, rule 3) under the predicate of its block at that trip
; (rule 5: every bus access under a quantum predicate is _controlled): strlen's s[i] and strcmp's a[i] under the
; predicate of reaching the trip's test (the |1> seed for trip 0); strcmp's b[i] in block %33 under that block's
; predicate; the reload of b[i] in block %37 (%40) is its own bus load under x_i, the predicate of block %37 (no bus
; access is hoisted: the old shared handle of %35 and %40 is gone). The reverse loop recomputes each address from
; the trip index and pops the load copies.
source_filename = "quantum_strlen.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @quantum_strlen(ptr nocapture noundef readonly %0, i32 noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: (no instruction) the bus handle m (once, at function entry, §5)
  %4 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %3 = alloca [4 x i8], align 4  [bus-resident (a store of a tainted value): one zeroed block, no alloca; the lifetime markers are dropped (rule 16)]
  %5 = ptrtoint ptr %4 to i64    ; IR: %3 as its run-time address (rule 21)
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: store i32 0, ptr %3: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %5, i32 %6)    ; IR: store i32 0, ptr %3  (kept store, rule 5 sentence 3; classical-valued, the cells stay HOST)
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %30 = phi i32 [ 0, %7 ], [ %28, %27 ], [ %1, %24 ]: the innermost arm of the exit select chain, the incoming 0 of the cap <= 0 edge  [seed rail]
  %8 = icmp sgt i32 %1, 0    ; IR: %4 / %8  (classical; -O1 tests it twice)
  br i1 %8, label %9, label %55    ; IR: br i1 %4

9:
  %10 = zext nneg i32 %1 to i64    ; IR: %6 / %10  (classical)
  br label %11

11:
  %12 = phi i64 [ 0, %9 ], [ %20, %11 ]    ; IR: %12  (classical i)
  %13 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %12    ; IR: %13 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %12  (untainted index: stays)
  %14 = ptrtoint ptr %13 to i64    ; IR: %13 as its run-time address
  %15 = call i32 @cqrt_alloc_i8(i8 97)    ; IR: store i8 97, ptr %13: the classical 'a' as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %14, i32 %15)    ; IR: store i8 97, ptr %13  (kept store, rule 5 sentence 3; the interval of the form below runs from here)
  %16 = getelementptr inbounds double, ptr %0, i64 %12    ; IR: %14  (untainted index: stays)
  %17 = ptrtoint ptr %16 to i64    ; IR: %14 as its run-time address
  %18 = call i32 @cqrt_qram_load_f64_hl(i32 %3, i64 %17)    ; IR: %15 = load double, ptr %14  [a bus load at its own program point, before the swap-out: the angle rail A_i (rules 3, 15); overtaken by the form: un-copied after the second swap, not freed (rule 5 sentence 1)]
  %19 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: %16 = cq_theta_c(97, %15): in-place form on the 97 forwarded from the store (rule 5, Readers), the swap rail (|0>)
  call void @cqrt_qram_swap_i8_hl(i32 %3, i64 %14, i32 %19)    ; IR: %16 = cq_theta_c(97, %15): swap-out: the rail holds s[i] (97), the cell |0>
  call void @cqrt_ry_i8_qangle(i32 %19, i32 %18)    ; IR: %16 = cq_theta_c(97, %15)  [Ry(val(A_i)) in place on s[i]'s content]
  call void @cqrt_qram_swap_i8_hl(i32 %3, i64 %14, i32 %19)    ; IR: store i8 %16, ptr %13: swap-in: the cell holds %16
  call void @cqrt_free(i32 %19)    ; IR: release the swap rail (|0>)
  call void @cqrt_qram_load_f64_hl_unc(i32 %18, i32 %3, i64 %17)    ; IR: un-copy %15 after its last reader, the Ry (past the second swap); overtaken by the form, left allocated (rule 5 sentence 1)
  %20 = add nuw nsw i64 %12, 1    ; IR: %17  (classical)
  %21 = icmp eq i64 %20, %10    ; IR: %18  (classical)
  br i1 %21, label %22, label %11    ; IR: br i1 %18

22:
  %23 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the first test in %19 (always 1)
  br label %24

24:
  %25 = phi i64 [ 0, %22 ], [ %36, %24 ]    ; IR: %20  (classical trip i)
  %26 = phi i32 [ %23, %22 ], [ %35, %24 ]    ; IR: predicate of reaching this trip's test
  %27 = phi i32 [ %7, %22 ], [ %34, %24 ]    ; IR: %30: the exit select chain so far (r_(i-1))
  %28 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %25    ; IR: %21  (untainted index: stays)
  %29 = ptrtoint ptr %28 to i64    ; IR: %21 as its run-time address
  %30 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %26, i32 %3, i64 %29)    ; IR: %22 = load i8, ptr %21  [a bus load (a rail), under the predicate of reaching this trip's test]
  %31 = call i32 @cq_template_icmp_eq_i8_hl(i32 %30, i8 0)    ; IR: %23 = icmp eq i8 %22, 0
  %32 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %27 at this trip (the NUL exit)
  call void @cqrt_and_i1(i32 %26, i32 %31, i32 %32)    ; IR: br i1 %23, label %27  taken
  %33 = trunc nuw nsw i64 %25 to i32    ; IR: %28 = trunc nuw nsw i64 %20 to i32  (classical)
  %34 = call i32 @cq_template_select_i32_lh(i32 %32, i32 %33, i32 %27)    ; IR: %30 incoming %28 from %27: r_i = e_i ? i : r_(i-1)  [fresh rail]
  call void @cqrt_not_i1(i32 %31)    ; IR: NOT %23
  %35 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %24 at this trip (continue)
  call void @cqrt_and_i1(i32 %26, i32 %31, i32 %35)    ; IR: br i1 %23, ..., label %24  taken
  call void @cqrt_not_i1(i32 %31)    ; IR: restore %23
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %27)
  %36 = add nuw nsw i64 %25, 1    ; IR: %25  (classical)
  %37 = icmp eq i64 %36, %10    ; IR: %26  (classical bound: the buffer size)
  br i1 %37, label %38, label %24    ; IR: br i1 %26

38:
  %39 = call i32 @cq_template_select_i32_lh(i32 %35, i32 %1, i32 %34)    ; IR: %30 incoming %1 from %24 (no NUL in the buffer): r = a_last ? cap : r_last  [result rail; exclusive with every e_i]
  br label %40

40:
  %41 = phi i64 [ %10, %38 ], [ %44, %40 ]    ; IR: reverse trip index (counts down)
  %42 = phi i32 [ %35, %38 ], [ %48, %40 ]    ; IR: continue-predicate of this trip
  %43 = phi i32 [ %34, %38 ], [ %45, %40 ]    ; IR: r_i of this trip
  %44 = add nsw i64 %41, -1    ; IR: the trip being undone
  %45 = call i32 @cqrt_pop()    ; IR: r_(i-1)
  %46 = call i32 @cqrt_pop()    ; IR: e_i
  %47 = call i32 @cqrt_pop()    ; IR: %23 of that trip
  %48 = call i32 @cqrt_pop()    ; IR: a_(i-1)
  %49 = call i32 @cqrt_pop()    ; IR: %22 of that trip (the load copy of s[i])
  %50 = trunc nuw nsw i64 %44 to i32    ; IR: %28 of that trip (classical)
  call void @cq_template_select_i32_lh_unc(i32 %43, i32 %46, i32 %50, i32 %45)    ; IR: uncompute r_i
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %47)
  call void @cqrt_and_i1(i32 %48, i32 %47, i32 %42)    ; IR: uncompute the continue-predicate
  call void @cqrt_not_i1(i32 %47)
  call void @cqrt_free(i32 %42)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %48, i32 %47, i32 %46)    ; IR: uncompute the exit predicate
  call void @cqrt_free(i32 %46)    ; IR: release it (|0>)
  %51 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %44    ; IR: %21 of that trip, recomputed from the trip index
  %52 = ptrtoint ptr %51 to i64    ; IR: its address
  call void @cq_template_icmp_eq_i8_hl_unc(i32 %47, i32 %49, i8 0)    ; IR: uncompute %23
  call void @cqrt_free(i32 %47)    ; IR: release the %23 rail (|0>)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %49, i32 %48, i32 %3, i64 %52)    ; IR: un-copy %22 after its last reader's _unc, under the control it was loaded with (rule 5 sentence 1: no memory version change since the load)
  call void @cqrt_free(i32 %49)    ; IR: release the %22 rail (|0>)
  %53 = icmp eq i64 %44, 0
  br i1 %53, label %54, label %40

54:
  call void @cqrt_not_i1(i32 %48)    ; IR: seed predicate back to |0>
  call void @cqrt_free(i32 %48)    ; IR: release the seed (|0>)
  call void @cqrt_free(i32 %7)    ; IR: release the chain's seed rail (never written, |0>)
  br label %55

55:
  %56 = phi i32 [ %7, %2 ], [ %39, %54 ]    ; IR: %30: the seed itself when cap <= 0 (incoming 0), else the chain's result
  %57 = call i32 @cqrt_measure_i32(i32 %56)    ; IR: %31 = cq_measure_si32(%30)
  ret i32 %57    ; IR: ret i32 %31  (llvm.lifetime.end of %3 dropped: bus-resident, rule 16)
}

define i32 @quantum_strcmp(ptr nocapture noundef readonly %0, ptr nocapture noundef readonly %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: (no instruction) the bus handle m (once, at function entry, §5)
  %5 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %4 = alloca [4 x i8], align 4  [a: bus-resident (a store of a tainted value): one zeroed block, no alloca; lifetime markers dropped]
  %6 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %5 = alloca [4 x i8], align 4  [b: likewise]
  %7 = ptrtoint ptr %5 to i64    ; IR: %4 as its run-time address (rule 21)
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: store i32 0, ptr %4: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %7, i32 %8)    ; IR: store i32 0, ptr %4  (kept store, rule 5 sentence 3; classical-valued, the cells stay HOST)
  %9 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address
  %10 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: store i32 0, ptr %5: the seed, kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %9, i32 %10)    ; IR: store i32 0, ptr %5  (kept store)
  %11 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %44 = phi i32 [ %42, %37 ], [ 0, %9 ], [ 0, %25 ]: the innermost arm of the exit select chain; both 0 incomings are its value  [seed rail]
  %12 = icmp sgt i32 %2, 0    ; IR: %6 / %10  (classical)
  br i1 %12, label %13, label %106    ; IR: br i1 %6

13:
  %14 = zext nneg i32 %2 to i64    ; IR: %8 / %12  (classical)
  br label %15

15:
  %16 = phi i64 [ 0, %13 ], [ %49, %48 ]    ; IR: %14  (classical i)
  %17 = getelementptr inbounds [4 x i8], ptr %6, i64 0, i64 %16    ; IR: %15 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %14  (untainted index: stays)
  %18 = ptrtoint ptr %17 to i64    ; IR: %15 as its run-time address: p of b[i]'s form
  %19 = call i32 @cqrt_alloc_i8(i8 97)    ; IR: store i8 97, ptr %15: the seed, kept with its store
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %18, i32 %19)    ; IR: store i8 97, ptr %15  (kept store; the interval of b[i]'s form runs from here)
  %20 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %16    ; IR: %16 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %14  (untainted index: stays)
  %21 = ptrtoint ptr %20 to i64    ; IR: %16 as its run-time address: q, the address of both changes in b[i]'s interval
  %22 = sub i64 %21, %18    ; IR: (no instruction) Readers, change 1 (store 97 to a[i]): q - p mod 2^64
  %23 = icmp uge i64 %22, 1    ; IR: (no instruction) q - p >= S_p, S_p = 1 cell
  %24 = sub i64 %18, %21    ; IR: (no instruction) p - q mod 2^64
  %25 = icmp uge i64 %24, 1    ; IR: (no instruction) p - q >= S_q, S_q = 1 cell
  %26 = and i1 %23, %25    ; IR: (no instruction) the test of change 1
  %27 = sub i64 %21, %18    ; IR: (no instruction) Readers, change 2 (a[i]'s in-place form): q - p
  %28 = icmp uge i64 %27, 1    ; IR: (no instruction) q - p >= S_p
  %29 = sub i64 %18, %21    ; IR: (no instruction) p - q
  %30 = icmp uge i64 %29, 1    ; IR: (no instruction) p - q >= S_q
  %31 = and i1 %28, %30    ; IR: (no instruction) the test of change 2
  %32 = and i1 %26, %31    ; IR: (no instruction) d: b[i]'s cell is disjoint from every change in its interval (classical, run time), computed before the first change
  br i1 %32, label %35, label %33    ; IR: (no instruction) Readers: d = 1 DISJOINT: no copy; d = 0 OVERLAP: the copy below

33:
  %34 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %18)    ; IR: the forwarded 97 as a rail: a plain load of b[i] taken before the changes (rule 5, Readers)  [OVERLAP path only]
  br label %35    ; IR: (no instruction)

35:
  %36 = phi i32 [ poison, %15 ], [ %34, %33 ]    ; IR: (no instruction) the copy's handle on the OVERLAP path (classical phi; poison, never read, on the DISJOINT path)
  %37 = call i32 @cqrt_alloc_i8(i8 97)    ; IR: store i8 97, ptr %16: the seed, kept with its store
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %21, i32 %37)    ; IR: store i8 97, ptr %16  (kept store; change 1 of b[i]'s interval; the interval of a[i]'s form runs from here)
  %38 = getelementptr inbounds double, ptr %0, i64 %16    ; IR: %17  (untainted index: stays)
  %39 = ptrtoint ptr %38 to i64    ; IR: %17 as its run-time address
  %40 = call i32 @cqrt_qram_load_f64_hl(i32 %4, i64 %39)    ; IR: %18 = load double, ptr %17  [the angle rail of a[i] (rules 3, 15), a plain load before the swap-out; overtaken by the form: un-copied after the second swap, not freed]
  %41 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: %19 = cq_theta_c(97, %18): in-place form on a[i] (the 97 forwarded from its store), the swap rail (|0>)
  call void @cqrt_qram_swap_i8_hl(i32 %4, i64 %21, i32 %41)    ; IR: %19 = cq_theta_c(97, %18): swap-out: the rail holds a[i], the cell |0>  (change 2 of b[i]'s interval)
  call void @cqrt_ry_i8_qangle(i32 %41, i32 %40)    ; IR: %19 = cq_theta_c(97, %18)  [Ry in place on a[i]'s content]
  call void @cqrt_qram_swap_i8_hl(i32 %4, i64 %21, i32 %41)    ; IR: store i8 %19, ptr %16: swap-in: the cell holds %19
  call void @cqrt_free(i32 %41)    ; IR: release the swap rail (|0>)
  call void @cqrt_qram_load_f64_hl_unc(i32 %40, i32 %4, i64 %39)    ; IR: un-copy %18 after its last reader, the Ry (past the second swap); overtaken by the form, left allocated (rule 5 sentence 1)
  %42 = getelementptr inbounds double, ptr %1, i64 %16    ; IR: %20  (untainted index: stays)
  %43 = ptrtoint ptr %42 to i64    ; IR: %20 as its run-time address
  %44 = call i32 @cqrt_qram_load_f64_hl(i32 %4, i64 %43)    ; IR: %21 = load double, ptr %20  [the angle rail of b[i], a plain load before the swap-out; overtaken by the changes: un-copied after its Ry on either path, not freed]
  br i1 %32, label %45, label %47    ; IR: (no instruction) Readers: the same d, at the store's position: DISJOINT: b[i]'s form stands; OVERLAP: the step acts on the copy

45:
  %46 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: %22 = cq_theta_c(97, %21): in-place form on b[i] (the forwarded 97), the swap rail (|0>)  [DISJOINT path]
  call void @cqrt_qram_swap_i8_hl(i32 %4, i64 %18, i32 %46)    ; IR: %22 = cq_theta_c(97, %21): swap-out: the rail holds b[i] (untouched by the changes), the cell |0>
  call void @cqrt_ry_i8_qangle(i32 %46, i32 %44)    ; IR: %22 = cq_theta_c(97, %21)  [Ry in place on b[i]'s content]
  call void @cqrt_qram_swap_i8_hl(i32 %4, i64 %18, i32 %46)    ; IR: store i8 %22, ptr %15: swap-in: the cell holds %22
  call void @cqrt_free(i32 %46)    ; IR: release the swap rail (|0>)
  call void @cqrt_qram_load_f64_hl_unc(i32 %44, i32 %4, i64 %43)    ; IR: un-copy %21 after its last reader, the Ry (past the second swap); overtaken, left allocated (rule 5 sentence 1)
  br label %48    ; IR: (no instruction)

47:
  call void @cqrt_ry_i8_qangle(i32 %36, i32 %44)    ; IR: %22 = cq_theta_c(97, %21)  [Ry on the load copy: a frozen register from here on, rule 2]  [OVERLAP path]
  call void @cqrt_qram_load_f64_hl_unc(i32 %44, i32 %4, i64 %43)    ; IR: un-copy %21 after its last reader, the Ry; overtaken by the changes, left allocated (rule 5 sentence 1)
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %18, i32 %36)    ; IR: store i8 %22, ptr %15  (a kept store: its tape slot and its value rail stay, rule 5 sentence 3)
  br label %48    ; IR: (no instruction)

48:
  %49 = add nuw nsw i64 %16, 1    ; IR: %23  (classical)
  %50 = icmp eq i64 %49, %14    ; IR: %24  (classical)
  br i1 %50, label %51, label %15    ; IR: br i1 %24

51:
  %52 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the first test in %28 (always 1)
  br label %53

53:
  %54 = phi i64 [ 0, %51 ], [ %77, %53 ]    ; IR: %29  (classical trip i)
  %55 = phi i32 [ %52, %51 ], [ %67, %53 ]    ; IR: predicate of block %28 at this trip
  %56 = phi i32 [ %11, %51 ], [ %76, %53 ]    ; IR: %44: the exit select chain so far (r_(i-1))
  %57 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %54    ; IR: %30  (untainted index: stays)
  %58 = ptrtoint ptr %57 to i64    ; IR: %30 as its run-time address
  %59 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %55, i32 %4, i64 %58)    ; IR: %31 = load i8, ptr %30  [a bus load (a rail), under the predicate of block %28]
  %60 = call i32 @cq_template_icmp_eq_i8_hl(i32 %59, i8 0)    ; IR: %32 = icmp eq i8 %31, 0
  %61 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of %28 -> %37 (NUL in a)
  call void @cqrt_and_i1(i32 %55, i32 %60, i32 %61)    ; IR: br i1 %32, label %37  taken
  call void @cqrt_not_i1(i32 %60)    ; IR: NOT %32
  %62 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %33
  call void @cqrt_and_i1(i32 %55, i32 %60, i32 %62)    ; IR: br i1 %32, ..., label %33  taken
  call void @cqrt_not_i1(i32 %60)    ; IR: restore %32
  %63 = getelementptr inbounds [4 x i8], ptr %6, i64 0, i64 %54    ; IR: %34  (untainted index: stays)
  %64 = ptrtoint ptr %63 to i64    ; IR: %34 as its run-time address
  %65 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %62, i32 %4, i64 %64)    ; IR: %35 = load i8, ptr %34  [a bus load, under the predicate of block %33: not hoisted]
  %66 = call i32 @cq_template_icmp_eq_i8(i32 %59, i32 %65)    ; IR: %36 = icmp eq i8 %31, %35  (computed unconditionally: pure)
  %67 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %25 (continue)
  call void @cqrt_and_i1(i32 %62, i32 %66, i32 %67)    ; IR: br i1 %36, label %25  taken
  call void @cqrt_not_i1(i32 %66)    ; IR: NOT %36
  %68 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of %33 -> %37 (a[i] != b[i])
  call void @cqrt_and_i1(i32 %62, i32 %66, i32 %68)    ; IR: br i1 %36, ..., label %37  taken
  call void @cqrt_not_i1(i32 %66)    ; IR: restore %36
  %69 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: block %37's edge flag at this trip: x_i = e1_i | e2_i
  call void @cqrt_or_i1(i32 %61, i32 %68, i32 %69)    ; IR: the disjunction of the two exit predicates (exclusive)
  %70 = call i32 @cq_template_sext_i8_to_i32(i32 %59)    ; IR: %38 = sext i8 %31 to i32  (block %37, computed unconditionally: pure)
  %71 = getelementptr inbounds [4 x i8], ptr %6, i64 0, i64 %54    ; IR: %39  (untainted index: stays)
  %72 = ptrtoint ptr %71 to i64    ; IR: %39 as its run-time address
  %73 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %69, i32 %4, i64 %72)    ; IR: %40 = load i8, ptr %39  [its own bus load, under x_i, the predicate of block %37]
  %74 = call i32 @cq_template_sext_i8_to_i32(i32 %73)    ; IR: %41 = sext i8 %40 to i32
  %75 = call i32 @cq_template_sub_i32(i32 %70, i32 %74)    ; IR: %42 = sub nsw i32 %38, %41
  %76 = call i32 @cq_template_select_i32(i32 %69, i32 %75, i32 %56)    ; IR: %44 incoming %42 from %37: r_i = x_i ? d : r_(i-1)  [fresh rail]
  call void @cqrt_push(i32 %59)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %60)
  call void @cqrt_push(i32 %61)
  call void @cqrt_push(i32 %62)
  call void @cqrt_push(i32 %65)
  call void @cqrt_push(i32 %66)
  call void @cqrt_push(i32 %68)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %73)
  call void @cqrt_push(i32 %70)
  call void @cqrt_push(i32 %74)
  call void @cqrt_push(i32 %75)
  %77 = add nuw nsw i64 %54, 1    ; IR: %26  (classical)
  %78 = icmp eq i64 %77, %14    ; IR: %27  (classical bound)
  br i1 %78, label %79, label %53    ; IR: br i1 %27  (the fall-through exit contributes 0: the seed's value, no select)

79:
  %80 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %44  [result rail: the last trip's r copied out]
  call void @cqrt_copy_i32(i32 %76, i32 %80)    ; IR: %44 = r_last
  br label %81

81:
  %82 = phi i64 [ %14, %79 ], [ %85, %81 ]    ; IR: reverse trip index (counts down)
  %83 = phi i32 [ %67, %79 ], [ %98, %81 ]    ; IR: continue-predicate of this trip
  %84 = phi i32 [ %76, %79 ], [ %90, %81 ]    ; IR: r_i of this trip
  %85 = add nsw i64 %82, -1    ; IR: the trip being undone
  %86 = call i32 @cqrt_pop()    ; IR: %42 of that trip (d, kept alive for the select's _unc)
  %87 = call i32 @cqrt_pop()    ; IR: %41 of that trip
  %88 = call i32 @cqrt_pop()    ; IR: %38 of that trip
  %89 = call i32 @cqrt_pop()    ; IR: %40 of that trip (the load copy of b[i] in block %37)
  %90 = call i32 @cqrt_pop()    ; IR: r_(i-1)
  %91 = call i32 @cqrt_pop()    ; IR: x_i
  %92 = call i32 @cqrt_pop()    ; IR: e2_i
  %93 = call i32 @cqrt_pop()    ; IR: %36 of that trip
  %94 = call i32 @cqrt_pop()    ; IR: %35 of that trip (the load copy of b[i] in block %33)
  %95 = call i32 @cqrt_pop()    ; IR: predicate of %33
  %96 = call i32 @cqrt_pop()    ; IR: e1_i
  %97 = call i32 @cqrt_pop()    ; IR: %32 of that trip
  %98 = call i32 @cqrt_pop()    ; IR: predicate of %28
  %99 = call i32 @cqrt_pop()    ; IR: %31 of that trip (the load copy of a[i])
  %100 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %85    ; IR: %30 of that trip, recomputed from the trip index
  %101 = ptrtoint ptr %100 to i64    ; IR: its address
  %102 = getelementptr inbounds [4 x i8], ptr %6, i64 0, i64 %85    ; IR: %34 / %39 of that trip, recomputed from the trip index
  %103 = ptrtoint ptr %102 to i64    ; IR: its address
  call void @cq_template_select_i32_unc(i32 %84, i32 %91, i32 %86, i32 %90)    ; IR: uncompute r_i
  call void @cqrt_free(i32 %84)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_unc(i32 %86, i32 %88, i32 %87)    ; IR: uncompute %42
  call void @cqrt_free(i32 %86)    ; IR: release the %42 rail (|0>)
  call void @cq_template_sext_i8_to_i32_unc(i32 %87, i32 %89)    ; IR: uncompute %41
  call void @cqrt_free(i32 %87)    ; IR: release the %41 rail (|0>)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %89, i32 %91, i32 %4, i64 %103)    ; IR: un-copy %40 after its last reader's _unc, under x_i as at the load (rule 5 sentence 1)
  call void @cqrt_free(i32 %89)    ; IR: release the %40 rail (|0>)
  call void @cq_template_sext_i8_to_i32_unc(i32 %88, i32 %99)    ; IR: uncompute %38
  call void @cqrt_free(i32 %88)    ; IR: release the %38 rail (|0>)
  call void @cqrt_or_i1(i32 %96, i32 %92, i32 %91)    ; IR: uncompute x_i (t ^= e1 | e2 is an involution)
  call void @cqrt_free(i32 %91)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %93)
  call void @cqrt_and_i1(i32 %95, i32 %93, i32 %92)    ; IR: uncompute the mismatch-exit predicate
  call void @cqrt_not_i1(i32 %93)
  call void @cqrt_free(i32 %92)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %95, i32 %93, i32 %83)    ; IR: uncompute the continue-predicate
  call void @cqrt_free(i32 %83)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i8_unc(i32 %93, i32 %99, i32 %94)    ; IR: uncompute %36
  call void @cqrt_free(i32 %93)    ; IR: release the %36 rail (|0>)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %94, i32 %95, i32 %4, i64 %103)    ; IR: un-copy %35 after its last reader's _unc, under the predicate of %33 as at the load
  call void @cqrt_free(i32 %94)    ; IR: release the %35 rail (|0>)
  call void @cqrt_not_i1(i32 %97)
  call void @cqrt_and_i1(i32 %98, i32 %97, i32 %95)    ; IR: uncompute the predicate of %33
  call void @cqrt_not_i1(i32 %97)
  call void @cqrt_free(i32 %95)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %98, i32 %97, i32 %96)    ; IR: uncompute the NUL-exit predicate
  call void @cqrt_free(i32 %96)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i8_hl_unc(i32 %97, i32 %99, i8 0)    ; IR: uncompute %32
  call void @cqrt_free(i32 %97)    ; IR: release the %32 rail (|0>)
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %99, i32 %98, i32 %4, i64 %101)    ; IR: un-copy %31 after its last reader's _unc, under the predicate of %28 as at the load
  call void @cqrt_free(i32 %99)    ; IR: release the %31 rail (|0>)
  %104 = icmp eq i64 %85, 0
  br i1 %104, label %105, label %81

105:
  call void @cqrt_not_i1(i32 %98)    ; IR: seed predicate back to |0>
  call void @cqrt_free(i32 %98)    ; IR: release the seed (|0>)
  call void @cqrt_free(i32 %11)    ; IR: release the chain's seed rail (never written, |0>)
  br label %106

106:
  %107 = phi i32 [ %11, %3 ], [ %80, %105 ]    ; IR: %44: the seed itself when cap <= 0 (incoming 0), else the copied-out result
  %108 = call i32 @cqrt_measure_i32(i32 %107)    ; IR: %45 = cq_measure_si32(%44)
  ret i32 %108    ; IR: ret i32 %45  (the lifetime ends of %4, %5 dropped: bus-resident, rule 16)
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_f64_hl(i32, i64)
declare void @cqrt_qram_load_f64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i8_hl_controlled_unc(i32, i32, i32, i64)
declare void @cqrt_qram_swap_i8_hl(i32, i64, i32)
declare void @cqrt_ry_i8_qangle(i32, i32)
declare i32 @cq_template_icmp_eq_i8_hl(i32, i8)
declare void @cq_template_icmp_eq_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_icmp_eq_i8(i32, i32)
declare void @cq_template_icmp_eq_i8_unc(i32, i32, i32)
declare i32 @cq_template_sext_i8_to_i32(i32)
declare void @cq_template_sext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_or_i1(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
