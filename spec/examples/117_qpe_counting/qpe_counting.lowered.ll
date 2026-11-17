; HAND-WRITTEN. Rules: 2, 3, 4, 5, 7, 8, 10, 12, 14, 16, 18, 19, 20, 21, 22; §1.3 (the bus, qram_swap), §1.4 (the clone mask).
; Checked: m; the t counting bits c[j]: the cells c + j of the bus block %7 (one byte each), read at the end by the measure
; loop's load copies (c[j] lands in bit t-1-j); the nq cells x + i of the block %9.
; Clean: inside every __cq_q_grover_0000_ctl call: the load copies of the cells x[i] taken by both value(x) walks (each
; un-copied under the clone's predicate by its walk's mirror, before A^dag / A swap a cell: rule 5 sentence 1), both
; accumulator walks (zext, shl, or rails and the |0> seed of each, pushed per trip and uncomputed by their mirror loops),
; the load copies of marked[k] (k = 0 .. nmark-1; un-copied by is_marked's mirror under the predicate each was loaded
; under), the compare flags marked[k] == v and v == 0, the edge flags of the phase blocks, is_marked's predicate chain
; (the seed a_0 = pred & marked[0] != v and every continue predicate a_k, the last included, rule 14 classical bound with
; a quantum exit), and the swap rail of every in-place form of A^dag and A (|0> after its swap-in). In the caller: the
; swap rail of every in-place form (H^t, A, the QFT^-1 Ry), the QFT^-1 Toffoli flags (one per (k, j) pair) with the two
; load copies of c[k] and c[j] each flag reads (the c[j] copy loaded under c[k]), and the load copy of c[j] that carries
; the phase cq_phi(pi) of block %103 (all un-copied right after their last reader, before the next swap).
; Kept: the two memset value seeds (alloc_i8(0), rule 7) and the tape slots of the t + nq byte stores of the memsets
; (rule 5 sentence 3, rule 22); per j != 31, the load copy of c[j] that is the predicate of the 2^j grover calls, overtaken
; by the first __cq_q_grover_0000_ctl call (a call of a function that writes memory: a memory version change), un-copied
; right after the last grover call and then left allocated, never freed (SPEC GAP 3; |0> at run time, since grover never
; writes c); the t load copies of c[j] the measure loop measures (rule 2). The cells are the registers: x[i] is never
; measured, rotated under control by A and A^dag inside the composite and left entangled.
; Rotations: (Ry, cell c[j], pi/2, 1) for j = 0..t-1; (Ry, cell x[i], pi/2, 1) for i = 0..nq-1; then for j = 0..t-1,
; repeated 2^j times (one controlled grover call each, under the copy q_j of c[j]): (P, flag, pi, q_j & marked[0] == v),
; and for k = 1..nmark-1 (P, flag, pi, q_j & marked[0] != v & .. & marked[k-1] != v & marked[k] == v) [O over the marked
; list, v = value(x)], (Ry, cell x[i], -pi/2, q_j) for i = 0..nq-1 [A^dag], (P, flag, pi, q_j & value(x) != 0) [R],
; (Ry, cell x[i], pi/2, q_j) for i = 0..nq-1 [A]; then for j = t-1..0: (P, flag, -pi / 2^(k-j), c[k] & c[j]) for
; k = t-1..j+1, (P, copy of c[j], pi, c[j]) (rz_i1 on the bare load copy), (Ry, cell c[j], pi/2, 1). nq <= 0 skips both
; value walks and R; nmark <= 0 skips O. As a Boolean function of the inputs q_j is c[j]: the copy is a basis copy.
; Quantum counting (QPE on the Grover iterate), general size: nq, t and the marked list are inputs. FLAT MEMORY (rule 20).
; `bool c[t], x[nq]` are runtime-sized allocas that store rails (the cq_theta results) and, for x, are passed to a
; callee: both are BUS-RESIDENT, so each is __cq_alloc(size, 16) at its program point (rule 16: zeroed, a classical size,
; no K2), and every access is a bus access at its run-time address (gep, then ptrtoint: classical, _hl). The zero-fill
; loops -O1 turned into memsets are rule 22's host loop of byte stores of ONE i8 seed, kept (emitted although the block
; is zero already: §0). Each `load i8; trunc nuw to i1; cq_theta_i1; zext; store i8` on one SSA pointer is rule 5's
; in-place form through the Width-casts clause: alloc_i1(0), qram_swap_i1_hl, ry_i1 on the swap rail, qram_swap_i1_hl,
; free (205's bool_cell_rotate). The cells are the registers; no handle is ever stored (§1.1).
; The defining operation is a CONTROLLED COMPOSITE U: `if (c[j]) grover(x, nq, marked, nmark)` where grover holds loops,
; rotations and phases. The condition is a plain bus load of c[j] (-O1 loads it once per j, before the k loop); the
; callee runs as a CONTROLLED CLONE (rule 19: the predicate is the first parameter) and the control is pushed into every
; operation of the composite that is not a template on SSA values: every bus access is its _controlled form (the loads of
; x[i] and of marked[k], the swaps of A^dag and A), a rotation is ry_i1_controlled on the swap rail, a phase block is a
; kickback on a Toffoli flag pred & <edge predicate>, one kickback per incoming edge (the edges are disjoint, so the
; phases add). Clone mask 0000 (§1.4): every actual is classical (x and marked are classical ptrs, digit 0 each: a
; pointer is one scalar and nothing about the pointee crosses the call, rule 18), so the clone is __cq_q_grover_0000_ctl
; with grover's C parameter list after the predicate. grover writes memory (its in-place forms), so it has no twin.
; THE CONTROL IS UN-COPIED AND LEFT ALLOCATED (SPEC GAP 3). The load copy of c[j] has its last reader in the last grover
; call of the k loop, and the first grover call (a call of a function that writes memory: a memory version change) comes
; before that point: no rule asks at compile time whether grover's cells are disjoint from c[j]'s. The copy is still
; un-copied (qram_load_i1_hl_unc at the same address) on the k loop's exit edge, right after its last reader, and is
; not freed. At run time grover never writes c, so the cell holds the loaded value, the rail returns to |0> and no
; which-path record of c[j] survives: the circuit performs QPE. Had the cell changed, the rail would hold old ^ new, a
; record no worse than the copy itself; that is why it is never freed (a free is a reset). Analytic outcome (not
; replayed): call 1 (nq = 3, t = 4, marked {3, 5}; M = 2 of 8, eigenphases +-1/6) gives P(round(M~) = 2) =
; P(m in {3, 13}) = 0.6885; call 2 (nq = 3, t = 3, marked {1}) gives P(round(M~) = 1) = 0.9816. Under rule 5 sentence 1
; as written (the copy KEPT, never un-copied) each c[j] would carry a basis record from before the controlled powers of
; G and m would be uniform (0.125 and 0.25).
; Inside grover: value(x) is the quantum accumulator of 28 over the cells (a controlled bus load of x[i], zext from i8,
; shl, or into fresh rails; the trip-local rails and the load copy are pushed and the mirror pops them right after
; their consumers, before A^dag swaps the cells); its seed rail also stands for the phi incoming 0 of the nq <= 0 path.
; is_marked(v) is the early-return list loop with a classical bound and a quantum exit: -O1 peels trip 0 into the edge
; `marked[0] == v` -> %38 and keeps a loop whose exhausted edge carries %35 = false (classical: no phase) and whose found
; edge from %30 carries %35 = true, so each found edge is a kickback on a_k & (marked[k+1] == v); every trip computes its
; continue predicate as the general rule does (the last one is read by no gate: the exhausted edge carries no phase).
; marked[] is program memory: every load of it is a bus load and a rail (rule 3; over-taint, a basis copy of HOST
; cells), so the compares are icmp_eq_i32 of two rails in IR operand order. Trip 0's load is under the clone's
; predicate; the load of trip k + 1 is read by that trip's exit test and is under a_k, the predicate of reaching the test
; (rule 14, SPEC GAP 2), and is pushed with the trip's rails and un-copied by the mirror under the same a_k. Every chain
; predicate is a function of the inputs and is uncomputed by the mirror, then the seed, the trip-0 compare and its load.
; R = 2|0><0| - I is the kickback on pred & NOT (value == 0). The caller's part is the H^t and A loops, the classical
; repetition loop `for (k < 2^j)` (-O1 skips j == 31 and runs smax(1 << j, 1) trips), the QFT^-1 (two nested branches
; c[k], c[j] are one Toffoli flag of two load copies, the c[j] load sitting in the arm of c[k] and so controlled by it;
; `if (c[j]) cq_phi(pi)` is cqrt_rz_i1 on a plain load copy of c[j] taken before the swap-out of the in-place Ry, rule 5
; Readers: another reader of y) and the classical measure loop (plain load copies, measured).
; SPEC GAP 1: every read of a _Bool cell here is the program's own `load i8; trunc nuw i8 to i1` with no in-place form
; around it (the grover control, the QFT^-1 flags and phase, the measure loop). Rule 5's Width-casts clause fixes the
; width U only for a reader's plain load of a form. Chosen: the same, one qram_load_i1[_hl] at the trunc's width (§1.3:
; the low bit of the cell), not a qram_load_i8 and a trunc template (as 205's SPEC GAP 5). The accumulator's load
; `load i8; zext nneg i8 to i32` has no trunc and is qram_load_i8 with zext_i8_to_i32.
; SPEC GAP 3: rule 5 sentence 1 keeps a load copy that a memory version change overtakes before its last reader, and
; says nothing of un-copying it. Kept outright, the control copy of `if (c[j]) grover(...)` is a which-path record and
; the program is no longer QPE. Chosen: such a copy is still un-copied (`_unc`) right after its last reader and then KEPT
; unfreed: it reads |0> exactly when its cells hold the loaded value at run time, and otherwise holds old ^ new.
; SPEC GAP 2: rule 14 places a load that a trip's exit test reads under the predicate of reaching the test only in the
; K-loop bullet; the classical-bound-with-quantum-exit bullet (is_marked's loop) says nothing. Chosen: the same, a_k for
; trip k + 1's load of marked[k+1], and its _unc under the same a_k in the mirror (the clone's predicate for trip 0).
source_filename = "qpe_counting.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @qpe_counting(i32 noundef %0, i32 noundef %1, ptr noundef %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %6 = zext i32 %1 to i64    ; IR: %5  (classical byte count t)
  %7 = call ptr @__cq_alloc(i64 %6, i64 16)    ; IR: %6 = alloca i8, i64 %5, align 16: c[t] is bus-resident (rule 20 (b): a rail is stored into it), one zeroed block (rule 16; a classical size, no K2)
  %8 = zext i32 %0 to i64    ; IR: %7  (classical byte count nq)
  %9 = call ptr @__cq_alloc(i64 %8, i64 16)    ; IR: %8 = alloca i8, i64 %7, align 16: x[nq] is bus-resident (a rail is stored into it; passed to a callee), one zeroed block
  %10 = icmp sgt i32 %1, 0    ; IR: %9  (classical)
  br i1 %10, label %11, label %20    ; IR: br i1 %9, label %10, label %12

11:; IR: block %10
  %12 = zext nneg i32 %1 to i64    ; IR: %11  (classical memset length)
  %13 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%6, i8 0, %11): the byte value as ONE seed rail (rules 7, 22), kept with its stores
  br label %14

14:; IR: call @llvm.memset(%6, i8 0, %11): host loop of %11 byte stores (rule 22, classical length)
  %15 = phi i64 [ 0, %11 ], [ %18, %14 ]    ; IR: (classical byte j)
  %16 = getelementptr inbounds i8, ptr %7, i64 %15    ; IR: (the byte c + j)
  %17 = ptrtoint ptr %16 to i64    ; IR: (its run-time address, classical)
  call void @cqrt_qram_store_i8_hl(i32 %5, i64 %17, i32 %13)    ; IR: memset: byte store j  (kept store, rule 5)
  %18 = add nuw nsw i64 %15, 1    ; IR: (classical)
  %19 = icmp eq i64 %18, %12    ; IR: (classical: j + 1 == t)
  br i1 %19, label %20, label %14

20:; IR: block %12
  %21 = icmp sgt i32 %0, 0    ; IR: %13  (classical)
  br i1 %21, label %22, label %31    ; IR: br i1 %13, label %14, label %16

22:; IR: block %14
  %23 = zext nneg i32 %0 to i64    ; IR: %15  (classical memset length)
  %24 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%8, i8 0, %15): ONE seed rail, kept with its stores
  br label %25

25:; IR: call @llvm.memset(%8, i8 0, %15): host loop of %15 byte stores (rule 22)
  %26 = phi i64 [ 0, %22 ], [ %29, %25 ]    ; IR: (classical byte i)
  %27 = getelementptr inbounds i8, ptr %9, i64 %26    ; IR: (the byte x + i)
  %28 = ptrtoint ptr %27 to i64    ; IR: (its run-time address, classical)
  call void @cqrt_qram_store_i8_hl(i32 %5, i64 %28, i32 %24)    ; IR: memset: byte store i  (kept store, rule 5)
  %29 = add nuw nsw i64 %26, 1    ; IR: (classical)
  %30 = icmp eq i64 %29, %23    ; IR: (classical: i + 1 == nq)
  br i1 %30, label %31, label %25

31:; IR: block %16
  %32 = icmp sgt i32 %1, 0    ; IR: %17  (classical)
  br i1 %32, label %33, label %42    ; IR: br i1 %17, label %18, label %20

33:; IR: block %18
  %34 = zext nneg i32 %1 to i64    ; IR: %19  (classical)
  br label %35

35:; IR: block %24  (H^t, classical bound t)
  %36 = phi i64 [ 0, %33 ], [ %40, %35 ]    ; IR: %25  (classical j)
  %37 = getelementptr inbounds i8, ptr %7, i64 %36    ; IR: %26  (the cell c[j])
  %38 = ptrtoint ptr %37 to i64    ; IR: %26 as its run-time address
  %39 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %27 = load i8, ptr %26; %28 = trunc nuw to i1: in-place form at width i1 (rule 5, Width casts), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %5, i64 %38, i32 %39)    ; IR: %27/%28: swap-out: the rail holds c[j], the cell's low bit |0>
  call void @cqrt_ry_i1(i32 %39, double 0x3FF921FB54442D18)    ; IR: %29 = cq_theta_i1(%28, pi/2)  [H|0>: Ry(pi/2) on c[j]]
  call void @cqrt_qram_swap_i1_hl(i32 %5, i64 %38, i32 %39)    ; IR: %30 = zext; store i8 %30, ptr %26: swap-in: the cell holds %29
  call void @cqrt_free(i32 %39)    ; IR: release the swap rail (|0>)
  %40 = add nuw nsw i64 %36, 1    ; IR: %31  (classical)
  %41 = icmp eq i64 %40, %34    ; IR: %32  (classical)
  br i1 %41, label %42, label %35    ; IR: br i1 %32, label %20, label %24

42:; IR: block %20
  %43 = icmp sgt i32 %0, 0    ; IR: %21  (classical)
  br i1 %43, label %44, label %53    ; IR: br i1 %21, label %22, label %33

44:; IR: block %22
  %45 = zext nneg i32 %0 to i64    ; IR: %23  (classical)
  br label %46

46:; IR: block %37  (A, classical bound nq)
  %47 = phi i64 [ 0, %44 ], [ %51, %46 ]    ; IR: %38  (classical i)
  %48 = getelementptr inbounds i8, ptr %9, i64 %47    ; IR: %39  (the cell x[i])
  %49 = ptrtoint ptr %48 to i64    ; IR: %39 as its run-time address
  %50 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %40 = load i8, ptr %39; %41 = trunc nuw to i1: in-place form at width i1, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %5, i64 %49, i32 %50)    ; IR: %40/%41: swap-out
  call void @cqrt_ry_i1(i32 %50, double 0x3FF921FB54442D18)    ; IR: %42 = cq_theta_i1(%41, pi/2)  [A: Ry(pi/2) on x[i]]
  call void @cqrt_qram_swap_i1_hl(i32 %5, i64 %49, i32 %50)    ; IR: %43 = zext; store i8 %43, ptr %39: swap-in
  call void @cqrt_free(i32 %50)    ; IR: release the swap rail (|0>)
  %51 = add nuw nsw i64 %47, 1    ; IR: %44  (classical)
  %52 = icmp eq i64 %51, %45    ; IR: %45  (classical)
  br i1 %52, label %53, label %46    ; IR: br i1 %45, label %33, label %37

53:; IR: block %33
  %54 = icmp sgt i32 %1, 0    ; IR: %34  (classical)
  br i1 %54, label %55, label %75    ; IR: br i1 %34, label %35, label %56

55:; IR: block %35
  %56 = zext nneg i32 %1 to i64    ; IR: %36  (classical)
  br label %57

57:; IR: block %46  (controlled G^(2^j), classical j)
  %58 = phi i64 [ 0, %55 ], [ %73, %72 ]    ; IR: %47  (classical j)
  %59 = icmp eq i64 %58, 31    ; IR: %48  (classical: 1 << 31 is negative, the k loop runs no trip)
  br i1 %59, label %72, label %60    ; IR: br i1 %48, label %62, label %49

60:; IR: block %49
  %61 = trunc nuw nsw i64 %58 to i32    ; IR: %50  (classical)
  %62 = shl nuw i32 1, %61    ; IR: %51  (classical 1 << j)
  %63 = getelementptr inbounds i8, ptr %7, i64 %58    ; IR: %52  (the cell c[j])
  %64 = ptrtoint ptr %63 to i64    ; IR: %52 as its run-time address
  %65 = call i32 @cqrt_qram_load_i1_hl(i32 %5, i64 %64)    ; IR: %53 = load i8, ptr %52; %54 = trunc nuw to i1  [a plain bus load of c[j] at width i1 (SPEC GAP 1): the bare rail that is the control of block %67; overtaken by the first grover call, un-copied after the k loop and left allocated (SPEC GAP 3)]
  %66 = call i32 @llvm.smax.i32(i32 %62, i32 1)    ; IR: %55  (classical trip count of the k loop)
  br label %67    ; IR: br label %65

67:; IR: block %65  (classical k < 2^j)
  %68 = phi i32 [ 0, %60 ], [ %69, %67 ]    ; IR: %66  (classical k)
  call fastcc void @__cq_q_grover_0000_ctl(i32 %65, ptr %9, i32 %0, ptr %2, i32 %3)    ; IR: br i1 %54 -> block %67: call @grover(%8, %0, %2, %3)  [the controlled clone, mask 0000: every operation of G under the rail %54; a memory version change]
  %69 = add nuw nsw i32 %68, 1    ; IR: %69  (classical)
  %70 = icmp eq i32 %69, %66    ; IR: %70  (classical)
  br i1 %70, label %71, label %67    ; IR: br i1 %70, label %62, label %65

71:; IR: (no block) exit edge %65 -> %62 of the k loop, j != 31
  call void @cqrt_qram_load_i1_hl_unc(i32 %65, i32 %5, i64 %64)    ; IR: un-copy %53 right after its last reader (the last grover call), although the grover calls overtook it (rule 5 sentence 1, SPEC GAP 3): |0> exactly when c[j]'s cell still holds the loaded value at run time (it does: grover never touches c), otherwise old ^ new; never freed
  br label %72

72:; IR: block %62
  %73 = add nuw nsw i64 %58, 1    ; IR: %63  (classical)
  %74 = icmp eq i64 %73, %56    ; IR: %64  (classical)
  br i1 %74, label %75, label %57    ; IR: br i1 %64, label %56, label %46

75:; IR: block %56  (QFT^-1 without the final swaps)
  %76 = add i32 %1, -1    ; IR: %57  (classical t - 1)
  %77 = icmp sgt i32 %1, 0    ; IR: %58  (classical)
  br i1 %77, label %78, label %110    ; IR: br i1 %58, label %59, label %77

78:; IR: block %59
  %79 = zext i32 %76 to i64    ; IR: %60  (classical)
  %80 = sext i32 %76 to i64    ; IR: %61  (classical)
  br label %81    ; IR: br label %71

81:; IR: block %71
  %82 = phi i64 [ %79, %78 ], [ %108, %103 ]    ; IR: %72  (classical j, t-1 down to 0)
  %83 = icmp slt i64 %82, %80    ; IR: %73  (classical: j < t - 1, the inner loop runs)
  br i1 %83, label %84, label %103    ; IR: br i1 %73, label %74, label %81

84:; IR: block %74
  %85 = getelementptr inbounds i8, ptr %7, i64 %82    ; IR: %75  (the cell c[j])
  %86 = ptrtoint ptr %85 to i64    ; IR: %75 as its run-time address
  %87 = trunc nuw nsw i64 %82 to i32    ; IR: %76  (classical)
  br label %88    ; IR: br label %85

88:; IR: block %85  (classical k = t-1 down to j+1)
  %89 = phi i32 [ %76, %84 ], [ %100, %88 ]    ; IR: %86  (classical k)
  %90 = zext nneg i32 %89 to i64    ; IR: %87  (classical)
  %91 = getelementptr inbounds i8, ptr %7, i64 %90    ; IR: %88  (the cell c[k])
  %92 = ptrtoint ptr %91 to i64    ; IR: %88 as its run-time address
  %93 = call i32 @cqrt_qram_load_i1_hl(i32 %5, i64 %92)    ; IR: %89 = load i8, ptr %88; %90 = trunc nuw to i1  (a plain bus load of c[k], SPEC GAP 1; the flag of br i1 %90)
  %94 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %93, i32 %5, i64 %86)    ; IR: block %91: %92 = load i8, ptr %75; %93 = trunc nuw to i1  (in the arm of %90: the _controlled load, rule 5)
  %95 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %94 = %90 & %93 (br i1 %90 -> block %91, br i1 %93 -> block %94)
  call void @cqrt_and_i1(i32 %93, i32 %94, i32 %95)    ; IR: one Toffoli flag (rule 8)
  %96 = sub nsw i32 %89, %87    ; IR: %95  (classical k - j)
  %97 = shl nuw i32 1, %96    ; IR: %96  (classical 1 << (k - j))
  %98 = sitofp i32 %97 to double    ; IR: %97  (classical)
  %99 = fdiv double 0xC00921FB54442D18, %98    ; IR: %98  (classical angle -pi / 2^(k-j))
  call void @cqrt_rz_i1(i32 %95, double %99)    ; IR: block %94: cq_phi(%98)  [kickback on the flag]
  call void @cqrt_and_i1(i32 %93, i32 %94, i32 %95)    ; IR: uncompute the %94 predicate
  call void @cqrt_free(i32 %95)    ; IR: release the flag (|0>)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %94, i32 %93, i32 %5, i64 %86)    ; IR: un-copy %92 under the same %90 (its last reader is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %94)    ; IR: release the %92 rail (|0>)
  call void @cqrt_qram_load_i1_hl_unc(i32 %93, i32 %5, i64 %92)    ; IR: un-copy %89
  call void @cqrt_free(i32 %93)    ; IR: release the %89 rail (|0>)
  %100 = add nsw i32 %89, -1    ; IR: %100  (classical)
  %101 = sext i32 %100 to i64    ; IR: %101  (classical)
  %102 = icmp slt i64 %82, %101    ; IR: %102  (classical)
  br i1 %102, label %88, label %103    ; IR: br i1 %102, label %85, label %81

103:; IR: blocks %81, %103, %104
  %104 = getelementptr inbounds i8, ptr %7, i64 %82    ; IR: %82  (the cell c[j])
  %105 = ptrtoint ptr %104 to i64    ; IR: %82 as its run-time address
  %106 = call i32 @cqrt_qram_load_i1_hl(i32 %5, i64 %105)    ; IR: %83 = load i8, ptr %82; %84 = trunc nuw to i1: y of the in-place form below has another reader (br i1 %84): a plain load taken before the swap-out (rule 5, Readers; width i1, SPEC GAP 1)
  call void @cqrt_rz_i1(i32 %106, double 0x400921FB54442D18)    ; IR: br i1 %84 -> block %103: cq_phi(pi)  [phase on the bare rail itself: a diagonal gate on the copy, no flag]
  call void @cqrt_qram_load_i1_hl_unc(i32 %106, i32 %5, i64 %105)    ; IR: un-copy the reader's copy (before the swap-out, the next memory version change)
  call void @cqrt_free(i32 %106)    ; IR: release it (|0>)
  %107 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %83/%84: in-place form at width i1 on %82, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %5, i64 %105, i32 %107)    ; IR: %83/%84: swap-out
  call void @cqrt_ry_i1(i32 %107, double 0x3FF921FB54442D18)    ; IR: %105 = cq_theta_i1(%84, pi/2)  [Ry on c[j]]
  call void @cqrt_qram_swap_i1_hl(i32 %5, i64 %105, i32 %107)    ; IR: %106 = zext; store i8 %106, ptr %82: swap-in
  call void @cqrt_free(i32 %107)    ; IR: release the swap rail (|0>)
  %108 = add nsw i64 %82, -1    ; IR: %107  (classical)
  %109 = icmp sgt i64 %82, 0    ; IR: %108  (classical)
  br i1 %109, label %81, label %110    ; IR: br i1 %108, label %71, label %77

110:; IR: block %77
  %111 = icmp sgt i32 %1, 0    ; IR: %78  (classical)
  br i1 %111, label %112, label %128    ; IR: br i1 %78, label %79, label %109

112:; IR: block %79
  %113 = zext nneg i32 %1 to i64    ; IR: %80  (classical)
  br label %114

114:; IR: block %111  (measure loop, classical)
  %115 = phi i64 [ 0, %112 ], [ %126, %114 ]    ; IR: %112  (classical j)
  %116 = phi i32 [ 0, %112 ], [ %125, %114 ]    ; IR: %113  (classical m)
  %117 = getelementptr inbounds i8, ptr %7, i64 %115    ; IR: %114  (the cell c[j])
  %118 = ptrtoint ptr %117 to i64    ; IR: %114 as its run-time address
  %119 = call i32 @cqrt_qram_load_i1_hl(i32 %5, i64 %118)    ; IR: %115 = load i8, ptr %114; %116 = trunc nuw to i1  (a plain bus load, SPEC GAP 1)
  %120 = call i1 @cqrt_measure_i1(i32 %119)    ; IR: %117 = cq_measure_i1(%116)  [the load copy is the measured rail, rule 2: never un-copied]
  %121 = zext i1 %120 to i32    ; IR: %118  (classical)
  %122 = trunc i64 %115 to i32    ; IR: %119  (classical)
  %123 = sub i32 %76, %122    ; IR: %120  (classical t - 1 - j)
  %124 = shl nuw i32 %121, %123    ; IR: %121  (classical)
  %125 = or i32 %124, %116    ; IR: %122  (classical)
  %126 = add nuw nsw i64 %115, 1    ; IR: %123  (classical)
  %127 = icmp eq i64 %126, %113    ; IR: %124  (classical)
  br i1 %127, label %128, label %114    ; IR: br i1 %124, label %109, label %111

128:; IR: block %109
  %129 = phi i32 [ 0, %110 ], [ %125, %114 ]    ; IR: %110  (classical)
  ret i32 %129    ; IR: ret i32 %110
}

define internal fastcc void @__cq_q_grover_0000_ctl(i32 %0, ptr %1, i32 %2, ptr %3, i32 %4) {    ; IR: grover(x, nq, marked, nmark), all four classical (mask 0000), under the predicate %0
  %6 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %7 = ptrtoint ptr %3 to i64    ; IR: (no instruction) %2 (marked) as its run-time address, a classical i64 (rule 20)
  %8 = icmp sgt i32 %2, 0    ; IR: %5  (classical: nq > 0)
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %10 and of phi %20  [v before trip 0, and v itself when nq <= 0: one |0> seed rail]
  br i1 %8, label %10, label %24    ; IR: br i1 %5, label %6, label %19

10:; IR: block %6
  %11 = zext nneg i32 %2 to i64    ; IR: %7  (classical)
  br label %12

12:; IR: block %8  (value(x), classical bound nq)
  %13 = phi i64 [ 0, %10 ], [ %22, %12 ]    ; IR: %9  (classical i)
  %14 = phi i32 [ %9, %10 ], [ %21, %12 ]    ; IR: %10 = phi i32 [ 0, %6 ], [ %16, %8 ]
  %15 = getelementptr inbounds i8, ptr %1, i64 %13    ; IR: %11  (the cell x[i])
  %16 = ptrtoint ptr %15 to i64    ; IR: %11 as its run-time address
  %17 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %6, i64 %16)    ; IR: %12 = load i8, ptr %11  [a bus load under the clone's predicate (rule 5)]
  %18 = call i32 @cq_template_zext_i8_to_i32(i32 %17)    ; IR: %13 = zext nneg i8 %12 to i32
  %19 = trunc nuw nsw i64 %13 to i32    ; IR: %14  (classical)
  %20 = call i32 @cq_template_shl_i32_hl(i32 %18, i32 %19)    ; IR: %15 = shl nuw i32 %13, %14
  %21 = call i32 @cq_template_or_i32(i32 %20, i32 %14)    ; IR: %16 = or i32 %15, %10
  call void @cqrt_push(i32 %14)    ; IR: trip-local rails of the accumulator and the trip's load copy, for the mirror (rule 14)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %20)
  %22 = add nuw nsw i64 %13, 1    ; IR: %17  (classical)
  %23 = icmp eq i64 %22, %11    ; IR: %18  (classical)
  br i1 %23, label %24, label %12    ; IR: br i1 %18, label %19, label %8

24:; IR: block %19
  %25 = phi i32 [ %9, %5 ], [ %21, %12 ]    ; IR: %20 = phi i32 [ 0, %4 ], [ %16, %8 ]  (v = value(x))
  %26 = icmp sgt i32 %4, 0    ; IR: %21  (classical: nmark > 0)
  br i1 %26, label %27, label %57    ; IR: br i1 %21, label %22, label %36 (%37 = %21 = false: no phase)

27:; IR: block %22  (trip 0 of is_marked, peeled by -O1)
  %28 = zext nneg i32 %4 to i64    ; IR: %23  (classical)
  %29 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %0, i32 %6, i64 %7)    ; IR: %24 = load i32, ptr %2  [marked[0]: a bus load, a rail (rule 3), under the clone's predicate]
  %30 = call i32 @cq_template_icmp_eq_i32(i32 %29, i32 %25)    ; IR: %25 = icmp eq i32 %24, %20  [two rails, IR operand order]
  %31 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: the edge %22 -> %38 under the clone's control: pred & %25
  call void @cqrt_and_i1(i32 %0, i32 %30, i32 %31)    ; IR: br i1 %25 -> block %38 (Toffoli flag)
  call void @cqrt_rz_i1(i32 %31, double 0x400921FB54442D18)    ; IR: block %38 via %22: cq_phi(pi)  [kickback: O on v == marked[0]]
  call void @cqrt_and_i1(i32 %0, i32 %30, i32 %31)    ; IR: uncompute the edge flag
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  %32 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %26 = pred & NOT %25: the seed of the loop's chain (rule 14, classical bound with a quantum exit)
  call void @cqrt_not_i1(i32 %30)    ; IR: bracket: NOT %25
  call void @cqrt_and_i1(i32 %0, i32 %30, i32 %32)    ; IR: br i1 %25 not taken, under the control
  call void @cqrt_not_i1(i32 %30)    ; IR: bracket
  br label %33    ; IR: br label %26

33:; IR: block %26  (classical trip k + 1 = 1 .. nmark - 1)
  %34 = phi i64 [ 0, %27 ], [ %36, %38 ]    ; IR: %27  (classical k)
  %35 = phi i32 [ %32, %27 ], [ %44, %38 ]    ; IR: predicate of reaching this trip (a_k)
  %36 = add nuw nsw i64 %34, 1    ; IR: %28  (classical)
  %37 = icmp eq i64 %36, %28    ; IR: %29  (classical: the list is exhausted; edge %26 -> %34 has %35 = false: no phase)
  br i1 %37, label %45, label %38    ; IR: br i1 %29, label %34, label %30

38:; IR: block %30
  %39 = getelementptr inbounds i32, ptr %3, i64 %36    ; IR: %31  (&marked[k + 1])
  %40 = ptrtoint ptr %39 to i64    ; IR: %31 as its run-time address
  %41 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %35, i32 %6, i64 %40)    ; IR: %32 = load i32, ptr %31  [marked[k + 1], a rail; read by this trip's exit test %33, so under a_k, the predicate of reaching the test (rule 14, SPEC GAP 2)]
  %42 = call i32 @cq_template_icmp_eq_i32(i32 %41, i32 %25)    ; IR: %33 = icmp eq i32 %32, %20
  %43 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: the edge %30 -> %34 (then %35 = k + 1 < nmark = true, %37 true -> block %38): a_k & %33
  call void @cqrt_and_i1(i32 %35, i32 %42, i32 %43)    ; IR: br i1 %33 -> block %34 -> block %38 (Toffoli flag)
  call void @cqrt_rz_i1(i32 %43, double 0x400921FB54442D18)    ; IR: block %38 via %34: cq_phi(pi)  [kickback: O on v == marked[k + 1]]
  call void @cqrt_and_i1(i32 %35, i32 %42, i32 %43)    ; IR: uncompute the edge flag
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  %44 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: the next trip's predicate a_{k+1} = a_k & NOT %33
  call void @cqrt_not_i1(i32 %42)    ; IR: bracket: NOT %33
  call void @cqrt_and_i1(i32 %35, i32 %42, i32 %44)    ; IR: br i1 %33 not taken -> block %26
  call void @cqrt_not_i1(i32 %42)    ; IR: bracket
  call void @cqrt_push(i32 %35)    ; IR: trip-local rails for the mirror (the load copy %32 included)
  call void @cqrt_push(i32 %41)
  call void @cqrt_push(i32 %42)
  br label %33    ; IR: br label %26

45:; IR: block %34 reached by the exhausted edge; mirror of the chain, trips nmark - 1 .. 1
  %46 = phi i64 [ %34, %33 ], [ %55, %49 ]    ; IR: (classical index of the trip being undone)
  %47 = phi i32 [ %35, %33 ], [ %52, %49 ]    ; IR: the predicate that trip computed
  %48 = icmp eq i64 %46, 0    ; IR: (classical: back at the seed)
  br i1 %48, label %56, label %49

49:
  %50 = call i32 @cqrt_pop()    ; IR: %33 of that trip
  %51 = call i32 @cqrt_pop()    ; IR: its load copy %32
  %52 = call i32 @cqrt_pop()    ; IR: its reach predicate
  call void @cqrt_not_i1(i32 %50)    ; IR: bracket
  call void @cqrt_and_i1(i32 %52, i32 %50, i32 %47)    ; IR: uncompute that trip's continue predicate
  call void @cqrt_not_i1(i32 %50)    ; IR: bracket
  call void @cqrt_free(i32 %47)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_unc(i32 %50, i32 %51, i32 %25)    ; IR: uncompute that trip's %33
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  %53 = getelementptr i32, ptr %3, i64 %46    ; IR: (&marked[k], recomputed from the trip index)
  %54 = ptrtoint ptr %53 to i64    ; IR: its run-time address
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %51, i32 %52, i32 %6, i64 %54)    ; IR: un-copy that trip's %32 under the a_k it was loaded under (no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %51)    ; IR: release it (|0>)
  %55 = add i64 %46, -1    ; IR: (classical)
  br label %45

56:
  call void @cqrt_not_i1(i32 %30)    ; IR: bracket
  call void @cqrt_and_i1(i32 %0, i32 %30, i32 %47)    ; IR: uncompute the seed a_0 (the phi holds it here)
  call void @cqrt_not_i1(i32 %30)    ; IR: bracket
  call void @cqrt_free(i32 %47)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_unc(i32 %30, i32 %29, i32 %25)    ; IR: uncompute %25
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %29, i32 %0, i32 %6, i64 %7)    ; IR: un-copy %24 under the clone's predicate
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  br label %57    ; IR: br label %39 (the phases of block %38 are already applied)

57:; IR: block %36 / %39: mirror of value(x), before A^dag swaps the cells
  br i1 %8, label %58, label %74

58:
  %59 = zext nneg i32 %2 to i64    ; IR: (classical trip count nq)
  %60 = add i64 %59, -1    ; IR: (classical nq - 1)
  br label %61

61:; IR: reverse trip index of value(x) (undoes trip nq - 1 - r)
  %62 = phi i64 [ 0, %58 ], [ %72, %61 ]    ; IR: (classical r)
  %63 = phi i32 [ %25, %58 ], [ %67, %61 ]    ; IR: %16 of the trip being undone
  %64 = call i32 @cqrt_pop()    ; IR: that trip's %15
  %65 = call i32 @cqrt_pop()    ; IR: its %13
  %66 = call i32 @cqrt_pop()    ; IR: its load copy %12
  %67 = call i32 @cqrt_pop()    ; IR: its %10
  %68 = sub i64 %60, %62    ; IR: i of the trip being undone  (classical)
  %69 = trunc i64 %68 to i32    ; IR: %14 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %63, i32 %64, i32 %67)    ; IR: uncompute %16
  call void @cqrt_free(i32 %63)    ; IR: release the %16 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %64, i32 %65, i32 %69)    ; IR: uncompute %15
  call void @cqrt_free(i32 %64)    ; IR: release the %15 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %65, i32 %66)    ; IR: uncompute %13
  call void @cqrt_free(i32 %65)    ; IR: release the %13 rail (|0>)
  %70 = getelementptr i8, ptr %1, i64 %68    ; IR: (the cell x[i], recomputed from the trip index)
  %71 = ptrtoint ptr %70 to i64    ; IR: its run-time address
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %66, i32 %0, i32 %6, i64 %71)    ; IR: un-copy %12 (its last reader, the zext _unc, is done; no memory version change since the load: A^dag has not run yet)
  call void @cqrt_free(i32 %66)    ; IR: release the %12 rail (|0>)
  %72 = add i64 %62, 1
  %73 = icmp eq i64 %72, %59
  br i1 %73, label %74, label %61

74:
  call void @cqrt_free(i32 %9)    ; IR: release the seed of phi %10 / %20 (never written, |0>)
  %75 = icmp sgt i32 %2, 0    ; IR: %40  (classical)
  br i1 %75, label %76, label %85    ; IR: br i1 %40, label %41, label %43

76:; IR: block %41
  %77 = zext nneg i32 %2 to i64    ; IR: %42  (classical)
  br label %78

78:; IR: block %59  (A^dag)
  %79 = phi i64 [ 0, %76 ], [ %83, %78 ]    ; IR: %60  (classical i)
  %80 = getelementptr inbounds i8, ptr %1, i64 %79    ; IR: %61  (the cell x[i])
  %81 = ptrtoint ptr %80 to i64    ; IR: %61 as its run-time address
  %82 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %62 = load i8, ptr %61; %63 = trunc nuw to i1: in-place form at width i1 under the clone's predicate, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %0, i32 %6, i64 %81, i32 %82)    ; IR: %62/%63: swap-out under the predicate
  call void @cqrt_ry_i1_controlled(i32 %0, i32 %82, double 0xBFF921FB54442D18)    ; IR: %64 = cq_theta_i1(%63, -pi/2)  [A^dag: Ry(-pi/2) on x[i] under the clone's control]
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %0, i32 %6, i64 %81, i32 %82)    ; IR: %65 = zext; store i8 %65, ptr %61: swap-in under the predicate
  call void @cqrt_free(i32 %82)    ; IR: release the swap rail (|0> on both branches of the predicate)
  %83 = add nuw nsw i64 %79, 1    ; IR: %66  (classical)
  %84 = icmp eq i64 %83, %77    ; IR: %67  (classical)
  br i1 %84, label %85, label %78    ; IR: br i1 %67, label %43, label %59

85:; IR: block %43
  br i1 %8, label %86, label %119    ; IR: br i1 %5, label %44, label %69 (nq <= 0: value(x) = 0, no phase)

86:; IR: block %44
  %87 = zext nneg i32 %2 to i64    ; IR: %45  (classical)
  %88 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %48  [v before trip 0]
  br label %89

89:; IR: block %46  (the second value(x))
  %90 = phi i64 [ 0, %86 ], [ %99, %89 ]    ; IR: %47  (classical i)
  %91 = phi i32 [ %88, %86 ], [ %98, %89 ]    ; IR: %48 = phi i32 [ 0, %44 ], [ %54, %46 ]
  %92 = getelementptr inbounds i8, ptr %1, i64 %90    ; IR: %49  (the cell x[i])
  %93 = ptrtoint ptr %92 to i64    ; IR: %49 as its run-time address
  %94 = call i32 @cqrt_qram_load_i8_hl_controlled(i32 %0, i32 %6, i64 %93)    ; IR: %50 = load i8, ptr %49  [a bus load under the clone's predicate]
  %95 = call i32 @cq_template_zext_i8_to_i32(i32 %94)    ; IR: %51 = zext nneg i8 %50 to i32
  %96 = trunc nuw nsw i64 %90 to i32    ; IR: %52  (classical)
  %97 = call i32 @cq_template_shl_i32_hl(i32 %95, i32 %96)    ; IR: %53 = shl nuw i32 %51, %52
  %98 = call i32 @cq_template_or_i32(i32 %97, i32 %91)    ; IR: %54 = or i32 %53, %48
  call void @cqrt_push(i32 %91)
  call void @cqrt_push(i32 %94)
  call void @cqrt_push(i32 %95)
  call void @cqrt_push(i32 %97)
  %99 = add nuw nsw i64 %90, 1    ; IR: %55  (classical)
  %100 = icmp eq i64 %99, %87    ; IR: %56  (classical)
  br i1 %100, label %101, label %89    ; IR: br i1 %56, label %57, label %46

101:; IR: block %57
  %102 = call i32 @cq_template_icmp_eq_i32_hl(i32 %98, i32 0)    ; IR: %58 = icmp eq i32 %54, 0
  %103 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %68 = pred & NOT %58
  call void @cqrt_not_i1(i32 %102)    ; IR: bracket: NOT %58
  call void @cqrt_and_i1(i32 %0, i32 %102, i32 %103)    ; IR: br i1 %58 not taken -> block %68, under the control
  call void @cqrt_not_i1(i32 %102)    ; IR: bracket
  call void @cqrt_rz_i1(i32 %103, double 0x400921FB54442D18)    ; IR: block %68: cq_phi(pi)  [kickback: R = 2|0><0| - I]
  call void @cqrt_not_i1(i32 %102)    ; IR: bracket
  call void @cqrt_and_i1(i32 %0, i32 %102, i32 %103)    ; IR: uncompute the flag
  call void @cqrt_not_i1(i32 %102)    ; IR: bracket
  call void @cqrt_free(i32 %103)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %102, i32 %98, i32 0)    ; IR: uncompute %58
  call void @cqrt_free(i32 %102)    ; IR: release the %58 rail (|0>)
  %104 = add i64 %87, -1    ; IR: (classical nq - 1)
  br label %105

105:; IR: reverse trip index of the second value(x)
  %106 = phi i64 [ 0, %101 ], [ %116, %105 ]    ; IR: (classical r)
  %107 = phi i32 [ %98, %101 ], [ %111, %105 ]    ; IR: %54 of the trip being undone
  %108 = call i32 @cqrt_pop()    ; IR: that trip's %53
  %109 = call i32 @cqrt_pop()    ; IR: its %51
  %110 = call i32 @cqrt_pop()    ; IR: its load copy %50
  %111 = call i32 @cqrt_pop()    ; IR: its %48
  %112 = sub i64 %104, %106    ; IR: i of the trip being undone  (classical)
  %113 = trunc i64 %112 to i32    ; IR: %52 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %107, i32 %108, i32 %111)    ; IR: uncompute %54
  call void @cqrt_free(i32 %107)    ; IR: release the %54 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %108, i32 %109, i32 %113)    ; IR: uncompute %53
  call void @cqrt_free(i32 %108)    ; IR: release the %53 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %109, i32 %110)    ; IR: uncompute %51
  call void @cqrt_free(i32 %109)    ; IR: release the %51 rail (|0>)
  %114 = getelementptr i8, ptr %1, i64 %112    ; IR: (the cell x[i], recomputed from the trip index)
  %115 = ptrtoint ptr %114 to i64    ; IR: its run-time address
  call void @cqrt_qram_load_i8_hl_controlled_unc(i32 %110, i32 %0, i32 %6, i64 %115)    ; IR: un-copy %50 (before A swaps the cells)
  call void @cqrt_free(i32 %110)    ; IR: release the %50 rail (|0>)
  %116 = add i64 %106, 1
  %117 = icmp eq i64 %116, %87
  br i1 %117, label %118, label %105

118:
  call void @cqrt_free(i32 %88)    ; IR: release incoming 0 of phi %48 (never written, |0>)
  br label %119

119:; IR: block %69
  %120 = icmp sgt i32 %2, 0    ; IR: %70  (classical)
  br i1 %120, label %121, label %130    ; IR: br i1 %70, label %71, label %73

121:; IR: block %71
  %122 = zext nneg i32 %2 to i64    ; IR: %72  (classical)
  br label %123

123:; IR: block %74  (A)
  %124 = phi i64 [ 0, %121 ], [ %128, %123 ]    ; IR: %75  (classical i)
  %125 = getelementptr inbounds i8, ptr %1, i64 %124    ; IR: %76  (the cell x[i])
  %126 = ptrtoint ptr %125 to i64    ; IR: %76 as its run-time address
  %127 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %77 = load i8, ptr %76; %78 = trunc nuw to i1: in-place form at width i1 under the clone's predicate, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %0, i32 %6, i64 %126, i32 %127)    ; IR: %77/%78: swap-out under the predicate
  call void @cqrt_ry_i1_controlled(i32 %0, i32 %127, double 0x3FF921FB54442D18)    ; IR: %79 = cq_theta_i1(%78, pi/2)  [A: Ry(pi/2) on x[i] under the clone's control]
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %0, i32 %6, i64 %126, i32 %127)    ; IR: %80 = zext; store i8 %80, ptr %76: swap-in under the predicate
  call void @cqrt_free(i32 %127)    ; IR: release the swap rail (|0>)
  %128 = add nuw nsw i64 %124, 1    ; IR: %81  (classical)
  %129 = icmp eq i64 %128, %122    ; IR: %82  (classical)
  br i1 %129, label %130, label %123    ; IR: br i1 %82, label %73, label %74

130:; IR: block %73
  ret void    ; IR: ret void
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i1_hl_controlled(i32, i32, i64, i32)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare void @cqrt_qram_load_i1_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i1_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i1_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i8_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cqrt_qram_load_i32_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i32_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32(i32, i32)
declare void @cq_template_icmp_eq_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @llvm.smax.i32(i32, i32)
