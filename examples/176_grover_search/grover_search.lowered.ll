; HAND-WRITTEN. Rules: 20 (bool x[nq] is a bus-resident alloca: __cq_alloc(nq, 16) at its program point, every access a bus
; access at its run-time address, classical, _hl), 16 (the allocation: one zeroed block, a classical size, no K2), 2 and 5
; (each cq_theta on a cell is rule 5's in-place form at the cq_theta's width i1: alloc_i1(0), qram_swap_i1_hl, ry_i1 on the
; swap rail, qram_swap_i1_hl, free; the H loop's form runs from the `store i8 0` whose 0 -O1 forwarded into the cq_theta,
; rule 5 Readers; the measure loop measures plain load copies; Memory sentences 1 and 3), 7 (the stored 0 is a seed kept
; with its store; the |0> accumulator seed of each value(x) is freed directly), 14 (every loop has a classical runtime
; bound: the three Ry loops, the two value(x) loops and the measure loop run nq trips, the outer loop iters trips; all stay
; ROLLED classical loops; each value(x) trip pushes its trip-local rails and its load copy, and a reverse loop of nq trips
; pops and uncomputes them), 4 (value(x) is zext_i8_to_i32 / shl_i32_hl / or_i32 into fresh rails; the oracle compare is
; icmp_eq_i32_hl against the runtime target), 8 (the compare rail is the branch flag: the oracle phase arm is rz_i1 on it;
; R0's phase arm sits on the FALSE edge of `v == 0`, so it is the X-bracketed kickback), 3 (every load of x[i] is a bus
; load and a rail), 12 (every cq_phi is under a quantum predicate: none is deleted), 21 (x is a classical pointer, its
; cells' addresses classical i64); §1.3 (the bus, qram_swap).
; Checked: m = sum x[i] << i, the nq measured load copies of the cells x + i (one byte cell each, the register in its low
; bit), taken by the measure loop after the last A; the cells themselves hold the same outcomes at exit.
; Clean: every flag, every value-chain rail (zext, shl, or) and both accumulator seeds, in every iteration; the load copy of
; x[i] taken by every value(x) trip (un-copied by its walk's mirror after the zext _unc, its last reader, and before A^dag
; / A swap a cell: rule 5 sentence 1); the swap rail of every in-place form (|0> after its swap-in).
; Kept: the nq seeds alloc_i8(0) and the tape slots of the nq kept stores `x[i] = 0` (rule 5 sentence 3, rule 7;
; classical-valued: each cell stays HOST until its first swap); the nq load copies the measure loop
; measures (rule 2). The cells are the registers: x[i] lives in the bus cell x + i from the H loop on and is never copied
; out except by the un-copied value(x) loads and the measured copies.
; Rotations: Ry(pi/2) on the cells x[0..nq-1] (A; control 1); then per iteration r = 0 .. iters-1:
;   P(pi)  on flag(v == target)       [O;  control predicate: value(x) == target, v = sum_i x[i] << i]
;   Ry(-pi/2) on the cells x[0..nq-1] [A^dag; control 1]
;   P(pi)  on NOT flag(v == 0)        [R0; control predicate: value(x) != 0, the X-bracketed flag]
;   Ry(pi/2) on the cells x[0..nq-1]  [A; control 1]
; Expected: P(target) = sin^2((2 iters + 1) theta) with sin^2 theta = 2^-nq (analytic: the cells undergo exactly A,
; then (A R0 A^dag O)^iters; every value(x) load copy is un-copied before any cell is swapped again, every flag is
; uncomputed after its one diagonal kickback, every swap rail is |0> at its free, and the kept seeds and tape slots hold
; classical 0). grover_search(3, 5, 2): P(5) = 0.945312; grover_search(4, 11, 3): P(11) = 0.961319; every other outcome
; (1 - P) / (2^nq - 1). Not replayed (the replayer has no bus model).
; The source is Nielsen & Chuang's G = A R0 A^dag O with A = Ry(pi/2)^nq, written as plain C with the qubit count an
; input. FLAT MEMORY (rule 20). `bool x[nq]` is -O1's `alloca i8, i64 nq`; a rail is stored into it (the rotated bit), a
; user rule 20 (b) does not allow, so it is BUS-RESIDENT: __cq_alloc(nq, 16) at its program point (rule 16), no alloca
; remains, and every access below is a bus access at the cell's run-time address (getelementptr, then ptrtoint:
; classical, _hl). m = __cq_mem() is called once, at entry (§5). The H loop is `store i8 0, x + i;
; cq_theta_i1(false, pi/2); zext; store i8, x + i`: the `store i8 0` is an ordinary bus store of the classical 0, i.e.
; the seed alloc_i8(0) and a kept qram_store_i8_hl (emitted although the block is zero already, §0); the cq_theta's
; operand is the value -O1 forwarded from that store to the same SSA pointer, so the rotation is rule 5's in-place form
; with the interval running from that store (Readers) at the cq_theta's width i1 (rule 2): alloc_i1(0), swap-out, Ry,
; swap-in, free. A^dag and A are `load i8; trunc nuw to i1; cq_theta_i1; zext; store i8` on one SSA pointer: the same
; form through the Width-casts clause. -O1 inlines value(nq, x) twice as an nq-trip accumulator loop (`load i8` of the
; cell, zext nneg i8 -> i32, shl by the trip index, or into the carried i32) whose carried value starts from the literal
; 0 (a |0> seed rail, minted before the nq > 0 guard so that the zero-trip path reads the seed too: the exit phis %42 /
; %59 are the seed or the last trip's or-rail). Each trip's load is a plain bus load qram_load_i8_hl (no trunc follows it,
; so the access width i8 and zext_i8_to_i32); its copy is a trip-local rail pushed with the accumulator rails, and the
; mirror, right after the flag's kickback and before A^dag / A swap the cells, uncomputes or / shl / zext and then
; un-copies the load (qram_load_i8_hl_unc at the cell address recomputed from the trip index: no memory version change
; lies between the load and its _unc). The mirror runs only when the forward loop ran (the same classical nq > 0 test);
; its last pop is the seed, which is then freed directly. `value(x) != 0` is spelled by -O1 as `icmp eq %59, 0` with the
; phase block on the false edge, so the kickback is bracketed by X on the flag; P(pi) under `v != 0` is R0 = 2|0><0| - I
; up to a global phase. No quantum data crosses the outer back edge except the cells (in place), so the handle stack is
; empty at every latch. The measure loop's `load i8; trunc nuw to i1; cq_measure_i1` is a plain bus load at width i1,
; measured (rule 2: the copy stays allocated, never un-copied).
; SPEC GAP: the measure loop reads a _Bool cell with the program's own `load i8; trunc nuw i8 to i1`, outside any
; in-place form. Rule 5's Width-casts clause fixes the width U only for a reader's plain load of a form, and 58 instead
; takes qram_load_i8_hl and the trunc template. Chosen as 117 and 205: a plain load whose only user is a `trunc nuw` is
; one access at the trunc's width, qram_load_i1_hl (§1.3: the low bit of the cell), measured. Either choice gives the
; same unitary here (the high 7 bits of every cell are classical 0: the zeroed block and the kept store of 0).
; SPEC GAP: the H loop's cq_theta reads the literal `false` that -O1 forwarded from `store i8 0` (the trunc folded away).
; Rule 2's first sentence mints alloc_i1(v) for a cq_theta on a classical v; rule 5 Readers lets y be the value
; forwarded from the preceding store to p. Chosen: Readers, the in-place form at width i1 from that store (the result is
; stored straight back through the same SSA pointer); the store stays an ordinary bus store. A mint and a kept store
; would leave the minted rail beside the cell as a which-path copy of each register and lose the amplification.
source_filename = "grover_search.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @grover_search(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: (no instruction) the bus M (once, at function entry, §5)
  %5 = zext i32 %0 to i64    ; IR: %4 = zext i32 %0 to i64  (classical byte count nq)
  %6 = call ptr @__cq_alloc(i64 %5, i64 16)    ; IR: %5 = alloca i8, i64 %4, align 16: bool x[nq] is bus-resident (rule 20 (b): a rail is stored into it), one zeroed block (rule 16; a classical size, no K2); no alloca remains
  %7 = icmp sgt i32 %0, 0    ; IR: %6  (classical)
  br i1 %7, label %8, label %10    ; IR: br i1 %6, label %7, label %9

8:; IR: block %7
  %9 = zext nneg i32 %0 to i64    ; IR: %8  (classical)
  br label %18    ; IR: br label %17

10:; IR: block %9
  %11 = icmp sgt i32 %2, 0    ; IR: %10  (classical: iters > 0)
  br i1 %11, label %12, label %26    ; IR: br i1 %10, label %11, label %24

12:; IR: block %11
  %13 = icmp sgt i32 %0, 0    ; IR: %12  (classical)
  %14 = icmp sgt i32 %0, 0    ; IR: %13  (classical)
  %15 = icmp sgt i32 %0, 0    ; IR: %14  (classical)
  %16 = zext nneg i32 %0 to i64    ; IR: %15  (classical)
  %17 = zext nneg i32 %0 to i64    ; IR: %16  (classical)
  br label %30    ; IR: br label %28

18:; IR: block %17  (A: the first Ry loop, classical bound nq)
  %19 = phi i64 [ 0, %8 ], [ %24, %18 ]    ; IR: %18  (classical i)
  %20 = getelementptr inbounds i8, ptr %6, i64 %19    ; IR: %19 = getelementptr i8, ptr %5, %18  (the cell x[i])
  %21 = ptrtoint ptr %20 to i64    ; IR: %19 as its run-time address (classical, rule 20)
  %22 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i8 0, ptr %19: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %21, i32 %22)    ; IR: store i8 0, ptr %19  (x[i] = 0: a kept store, rule 5 sentence 3; classical-valued, the cell stays HOST)
  %23 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %20 = cq_theta_i1(false, pi/2): the operand is the 0 -O1 forwarded from the store above, so in-place form at width i1 from that store (rule 5 Readers, rule 2; SPEC GAP), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %21, i32 %23)    ; IR: %20: swap-out: the rail holds the cell's low bit (the stored 0), that bit |0>
  call void @cqrt_ry_i1(i32 %23, double 0x3FF921FB54442D18)    ; IR: %20 = cq_theta_i1(false, pi/2)  [A: Ry(pi/2) on x[i]]
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %21, i32 %23)    ; IR: %21 = zext %20; store i8 %21, ptr %19: swap-in: the cell holds %20
  call void @cqrt_free(i32 %23)    ; IR: release the swap rail (|0>)
  %24 = add nuw nsw i64 %19, 1    ; IR: %22  (classical)
  %25 = icmp eq i64 %24, %9    ; IR: %23  (classical)
  br i1 %25, label %10, label %18    ; IR: br i1 %23, label %9, label %17

26:; IR: block %24
  %27 = icmp sgt i32 %0, 0    ; IR: %25  (classical)
  br i1 %27, label %28, label %112    ; IR: br i1 %25, label %26, label %84

28:; IR: block %26
  %29 = zext nneg i32 %0 to i64    ; IR: %27  (classical)
  br label %114    ; IR: br label %86

30:; IR: block %28  (the outer iteration loop, classical bound iters)
  %31 = phi i32 [ 0, %12 ], [ %103, %102 ]    ; IR: %29  (classical r)
  %32 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phis %32 and %42  [v before trip 0: a |0> seed rail]
  br i1 %13, label %33, label %45    ; IR: br i1 %12, label %30, label %41

33:; IR: block %30  (value(x) of the oracle, classical bound nq)
  %34 = phi i64 [ %43, %33 ], [ 0, %30 ]    ; IR: %31  (classical i)
  %35 = phi i32 [ %42, %33 ], [ %32, %30 ]    ; IR: %32 = phi i32 [ %38, %30 ], [ 0, %28 ]  (the carried accumulator rail)
  %36 = getelementptr inbounds i8, ptr %6, i64 %34    ; IR: %33 = getelementptr i8, ptr %5, %31  (the cell x[i])
  %37 = ptrtoint ptr %36 to i64    ; IR: %33 as its run-time address
  %38 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %37)    ; IR: %34 = load i8, ptr %33  [a bus load of x[i]: a fresh rail (rules 3, 20)]
  %39 = call i32 @cq_template_zext_i8_to_i32(i32 %38)    ; IR: %35 = zext nneg i8 %34 to i32  [x[i] widened into a fresh rail]
  %40 = trunc nuw nsw i64 %34 to i32    ; IR: %36  (classical)
  %41 = call i32 @cq_template_shl_i32_hl(i32 %39, i32 %40)    ; IR: %37 = shl nuw i32 %35, %36  [fresh rail]
  %42 = call i32 @cq_template_or_i32(i32 %41, i32 %35)    ; IR: %38 = or i32 %37, %32  [fresh rail: the next accumulator]
  call void @cqrt_push(i32 %35)    ; IR: trip-local rails on the handle stack (rule 14): the previous accumulator
  call void @cqrt_push(i32 %38)    ; IR: ... the load copy %34 (un-copied by the mirror, rule 5 sentence 1)
  call void @cqrt_push(i32 %39)    ; IR: ... the zext rail
  call void @cqrt_push(i32 %41)    ; IR: ... the shl rail
  %43 = add nuw nsw i64 %34, 1    ; IR: %39  (classical)
  %44 = icmp eq i64 %43, %5    ; IR: %40  (classical)
  br i1 %44, label %45, label %33    ; IR: br i1 %40, label %41, label %30

45:; IR: block %41
  %46 = phi i32 [ %32, %30 ], [ %42, %33 ]    ; IR: %42 = phi i32 [ 0, %28 ], [ %38, %30 ]  (v: the seed, or the last trip's rail)
  %47 = call i32 @cq_template_icmp_eq_i32_hl(i32 %46, i32 %1)    ; IR: %43 = icmp eq i32 %42, %1  [the oracle flag: v == target, target a runtime literal]
  call void @cqrt_rz_i1(i32 %47, double 0x400921FB54442D18)    ; IR: br i1 %43 -> block %44: cq_phi(pi)  [O: kickback on the flag]
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %47, i32 %46, i32 %1)    ; IR: uncompute %43 after its only controlled gate
  call void @cqrt_free(i32 %47)    ; IR: release the flag (|0>)
  br i1 %13, label %48, label %62    ; IR: (mirror of the oracle's value(x) loop iff it ran: pops trip nq-1 .. 0 before A^dag)

48:; IR: reverse loop over the oracle's value(x) trips
  %49 = phi i64 [ 0, %45 ], [ %60, %48 ]    ; IR: reverse trip index (undoes trip nq-1-k)
  %50 = phi i32 [ %46, %45 ], [ %54, %48 ]    ; IR: %38 of the trip being undone
  %51 = call i32 @cqrt_pop()    ; IR: the trip's shl rail (%37)
  %52 = call i32 @cqrt_pop()    ; IR: the trip's zext rail (%35)
  %53 = call i32 @cqrt_pop()    ; IR: the trip's load copy (%34)
  %54 = call i32 @cqrt_pop()    ; IR: the trip's incoming accumulator (%32)
  %55 = xor i64 %49, -1    ; IR: (classical: -1 - k)
  %56 = add nsw i64 %5, %55    ; IR: i of the trip being undone = nq - 1 - k  (classical)
  %57 = trunc nuw nsw i64 %56 to i32    ; IR: %36 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %50, i32 %51, i32 %54)    ; IR: uncompute %38
  call void @cqrt_free(i32 %50)    ; IR: release the %38 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %51, i32 %52, i32 %57)    ; IR: uncompute %37
  call void @cqrt_free(i32 %51)    ; IR: release the %37 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %52, i32 %53)    ; IR: uncompute %35
  call void @cqrt_free(i32 %52)    ; IR: release the %35 rail (|0>)
  %58 = getelementptr inbounds i8, ptr %6, i64 %56    ; IR: (the cell x[i], recomputed from the trip index)
  %59 = ptrtoint ptr %58 to i64    ; IR: its run-time address
  call void @cqrt_qram_load_i8_hl_unc(i32 %53, i32 %4, i64 %59)    ; IR: un-copy %34 (its last reader, the zext _unc, is done; no memory version change since the load: A^dag has not run yet)
  call void @cqrt_free(i32 %53)    ; IR: release the %34 rail (|0>)
  %60 = add nuw nsw i64 %49, 1    ; IR: (classical)
  %61 = icmp eq i64 %60, %5    ; IR: (classical)
  br i1 %61, label %62, label %48    ; IR: (classical; the last pop of an accumulator is the seed)

62:; IR: block %45 (the join after the oracle)
  call void @cqrt_free(i32 %32)    ; IR: release incoming 0 of phis %32 / %42 (the seed; never written, |0>; rule 7)
  br i1 %14, label %95, label %63    ; IR: br i1 %13, label %61, label %46

63:; IR: block %46
  %64 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phis %49 and %59  [v before trip 0: a |0> seed rail]
  br i1 %13, label %65, label %77    ; IR: br i1 %12, label %47, label %58

65:; IR: block %47  (value(x) of R0, classical bound nq)
  %66 = phi i64 [ %75, %65 ], [ 0, %63 ]    ; IR: %48  (classical i)
  %67 = phi i32 [ %74, %65 ], [ %64, %63 ]    ; IR: %49 = phi i32 [ %55, %47 ], [ 0, %46 ]  (the carried accumulator rail)
  %68 = getelementptr inbounds i8, ptr %6, i64 %66    ; IR: %50  (the cell x[i])
  %69 = ptrtoint ptr %68 to i64    ; IR: %50 as its run-time address
  %70 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %69)    ; IR: %51 = load i8, ptr %50  [a bus load of x[i]: a fresh rail]
  %71 = call i32 @cq_template_zext_i8_to_i32(i32 %70)    ; IR: %52 = zext nneg i8 %51 to i32  [fresh rail]
  %72 = trunc nuw nsw i64 %66 to i32    ; IR: %53  (classical)
  %73 = call i32 @cq_template_shl_i32_hl(i32 %71, i32 %72)    ; IR: %54 = shl nuw i32 %52, %53  [fresh rail]
  %74 = call i32 @cq_template_or_i32(i32 %73, i32 %67)    ; IR: %55 = or i32 %54, %49  [fresh rail]
  call void @cqrt_push(i32 %67)    ; IR: trip-local rails on the handle stack
  call void @cqrt_push(i32 %70)    ; IR: ... (the load copy %51)
  call void @cqrt_push(i32 %71)    ; IR: ...
  call void @cqrt_push(i32 %73)    ; IR: ...
  %75 = add nuw nsw i64 %66, 1    ; IR: %56  (classical)
  %76 = icmp eq i64 %75, %5    ; IR: %57  (classical)
  br i1 %76, label %77, label %65    ; IR: br i1 %57, label %58, label %47

77:; IR: block %58
  %78 = phi i32 [ %64, %63 ], [ %74, %65 ]    ; IR: %59 = phi i32 [ 0, %46 ], [ %55, %47 ]
  %79 = call i32 @cq_template_icmp_eq_i32_hl(i32 %78, i32 0)    ; IR: %60 = icmp eq i32 %59, 0  [the R0 flag]
  call void @cqrt_not_i1(i32 %79)    ; IR: bracket: block %70 is the FALSE edge of br i1 %60 (rule 8)
  call void @cqrt_rz_i1(i32 %79, double 0x400921FB54442D18)    ; IR: block %70: cq_phi(pi)  [R0: kickback under v != 0]
  call void @cqrt_not_i1(i32 %79)    ; IR: bracket
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %79, i32 %78, i32 0)    ; IR: uncompute %60
  call void @cqrt_free(i32 %79)    ; IR: release the flag (|0>)
  br i1 %13, label %80, label %94    ; IR: (mirror of R0's value(x) loop iff it ran, before A swaps the cells)

80:; IR: reverse loop over R0's value(x) trips
  %81 = phi i64 [ 0, %77 ], [ %92, %80 ]    ; IR: reverse trip index
  %82 = phi i32 [ %78, %77 ], [ %86, %80 ]    ; IR: %55 of the trip being undone
  %83 = call i32 @cqrt_pop()    ; IR: the trip's shl rail (%54)
  %84 = call i32 @cqrt_pop()    ; IR: the trip's zext rail (%52)
  %85 = call i32 @cqrt_pop()    ; IR: the trip's load copy (%51)
  %86 = call i32 @cqrt_pop()    ; IR: the trip's incoming accumulator (%49)
  %87 = xor i64 %81, -1    ; IR: (classical: -1 - k)
  %88 = add nsw i64 %5, %87    ; IR: i of the trip being undone = nq - 1 - k  (classical)
  %89 = trunc nuw nsw i64 %88 to i32    ; IR: %53 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %82, i32 %83, i32 %86)    ; IR: uncompute %55
  call void @cqrt_free(i32 %82)    ; IR: release the %55 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %83, i32 %84, i32 %89)    ; IR: uncompute %54
  call void @cqrt_free(i32 %83)    ; IR: release the %54 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %84, i32 %85)    ; IR: uncompute %52
  call void @cqrt_free(i32 %84)    ; IR: release the %52 rail (|0>)
  %90 = getelementptr inbounds i8, ptr %6, i64 %88    ; IR: (the cell x[i], recomputed from the trip index)
  %91 = ptrtoint ptr %90 to i64    ; IR: its run-time address
  call void @cqrt_qram_load_i8_hl_unc(i32 %85, i32 %4, i64 %91)    ; IR: un-copy %51 (no memory version change since the load: A has not run yet)
  call void @cqrt_free(i32 %85)    ; IR: release the %51 rail (|0>)
  %92 = add nuw nsw i64 %81, 1    ; IR: (classical)
  %93 = icmp eq i64 %92, %5    ; IR: (classical)
  br i1 %93, label %94, label %80    ; IR: (classical; the last pop of an accumulator is the seed)

94:; IR: block %71 (the join after R0)
  call void @cqrt_free(i32 %64)    ; IR: release incoming 0 of phis %49 / %59 (the seed; never written, |0>; rule 7)
  br i1 %15, label %105, label %102    ; IR: br i1 %14, label %75, label %72

95:; IR: block %61  (A^dag: the Ry(-pi/2) loop, classical bound nq)
  %96 = phi i64 [ %100, %95 ], [ 0, %62 ]    ; IR: %62  (classical i)
  %97 = getelementptr inbounds i8, ptr %6, i64 %96    ; IR: %63  (the cell x[i])
  %98 = ptrtoint ptr %97 to i64    ; IR: %63 as its run-time address
  %99 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %64 = load i8, ptr %63; %65 = trunc nuw to i1: in-place form at width i1 (rule 5, Width casts), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %98, i32 %99)    ; IR: %64/%65: swap-out: the rail holds x[i], the cell's low bit |0>
  call void @cqrt_ry_i1(i32 %99, double 0xBFF921FB54442D18)    ; IR: %66 = cq_theta_i1(%65, -pi/2)  [A^dag: Ry(-pi/2) on x[i]]
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %98, i32 %99)    ; IR: %67 = zext %66; store i8 %67, ptr %63: swap-in: the cell holds %66
  call void @cqrt_free(i32 %99)    ; IR: release the swap rail (|0>)
  %100 = add nuw nsw i64 %96, 1    ; IR: %68  (classical)
  %101 = icmp eq i64 %100, %16    ; IR: %69  (classical)
  br i1 %101, label %63, label %95    ; IR: br i1 %69, label %46, label %61

102:; IR: block %72  (the outer latch)
  %103 = add nuw nsw i32 %31, 1    ; IR: %73  (classical)
  %104 = icmp eq i32 %103, %2    ; IR: %74  (classical)
  br i1 %104, label %26, label %30    ; IR: br i1 %74, label %24, label %28

105:; IR: block %75  (A: the Ry(pi/2) loop, classical bound nq)
  %106 = phi i64 [ %110, %105 ], [ 0, %94 ]    ; IR: %76  (classical i)
  %107 = getelementptr inbounds i8, ptr %6, i64 %106    ; IR: %77  (the cell x[i])
  %108 = ptrtoint ptr %107 to i64    ; IR: %77 as its run-time address
  %109 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %78 = load i8, ptr %77; %79 = trunc nuw to i1: in-place form at width i1, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %108, i32 %109)    ; IR: %78/%79: swap-out
  call void @cqrt_ry_i1(i32 %109, double 0x3FF921FB54442D18)    ; IR: %80 = cq_theta_i1(%79, pi/2)  [A: Ry(pi/2) on x[i]]
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %108, i32 %109)    ; IR: %81 = zext %80; store i8 %81, ptr %77: swap-in: the cell holds %80
  call void @cqrt_free(i32 %109)    ; IR: release the swap rail (|0>)
  %110 = add nuw nsw i64 %106, 1    ; IR: %82  (classical)
  %111 = icmp eq i64 %110, %17    ; IR: %83  (classical)
  br i1 %111, label %102, label %105    ; IR: br i1 %83, label %72, label %75

112:; IR: block %84
  %113 = phi i32 [ 0, %26 ], [ %124, %114 ]    ; IR: %85  (classical m)
  ret i32 %113    ; IR: ret i32 %85

114:; IR: block %86  (the measure loop, classical bound nq)
  %115 = phi i64 [ 0, %28 ], [ %125, %114 ]    ; IR: %87  (classical i)
  %116 = phi i32 [ 0, %28 ], [ %124, %114 ]    ; IR: %88  (classical m)
  %117 = getelementptr inbounds i8, ptr %6, i64 %115    ; IR: %89  (the cell x[i])
  %118 = ptrtoint ptr %117 to i64    ; IR: %89 as its run-time address
  %119 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %118)    ; IR: %90 = load i8, ptr %89; %91 = trunc nuw to i1  (a plain bus load of x[i] at width i1, SPEC GAP)
  %120 = call i1 @cqrt_measure_i1(i32 %119)    ; IR: %92 = cq_measure_i1(%91)  [the load copy is the measured rail, rule 2: never un-copied]
  %121 = zext i1 %120 to i32    ; IR: %93  (classical)
  %122 = trunc nuw nsw i64 %115 to i32    ; IR: %94  (classical)
  %123 = shl nuw i32 %121, %122    ; IR: %95  (classical)
  %124 = or i32 %123, %116    ; IR: %96  (classical)
  %125 = add nuw nsw i64 %115, 1    ; IR: %97  (classical)
  %126 = icmp eq i64 %125, %29    ; IR: %98  (classical)
  br i1 %126, label %112, label %114    ; IR: br i1 %98, label %84, label %86
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_not_i1(i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
