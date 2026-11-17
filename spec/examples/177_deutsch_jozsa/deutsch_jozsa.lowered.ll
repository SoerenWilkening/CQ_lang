; HAND-WRITTEN. Rules: 20 (bool x[nq] stores rails (the cq_theta results): a BUS-RESIDENT runtime-sized alloca,
; __cq_alloc(nq, 16) at its program point (rule 16: one zeroed block, a classical size); every access is a bus access at
; the cell's run-time address, gep then ptrtoint, classical: _hl), 5 / 2 (each `cq_theta(x[i])` stored straight back is
; the in-place form at width i1 (Width casts: alloc_i1(0), qram_swap_i1_hl, ry_i1 on the swap rail, qram_swap_i1_hl,
; free; 205's bool_cell_rotate): the cells are the registers and no handle is ever stored (§1.1); the init loop's
; `store i8 0` is a kept store of a seed (rules 5, 7) and opens the interval of the first form, whose y is the false -O1
; forwarded from it (rule 5, Readers)), 5 sentence 1 (every other read of x[i] is a plain bus load at width i1: the
; parity loop's copies are un-copied by the reverse loop after the parity _unc that reads them, the default arm's copy
; right after its kickback, the measure loop's copies are measured and stay), 14 (every loop has the classical bound nq
; and stays a ROLLED classical loop; the case-2 parity loop is a classical-bound loop with a quantum body: each trip loads
; x[i] and computes the next parity into a fresh rail, pushes the previous parity and the load copy, and a reverse loop
; pops and uncomputes them after the kickback), 7 (the |0> parity seed is freed directly; each `store i8 0` seed is kept
; with its store), 13 / 8 (the `switch` on the classical selector stays a classical switch; the one quantum branch
; `br i1 %24` is a flag kickback per incoming arm), 4 (p ^= x[i], -O1's `icmp ne i8 cell, zext(p)` on two i1-valued i8s
; (!range [0,2)), is cq_template_xor_i1 into a fresh rail, as 113: the zext i1 -> i8 of the parity rail is that rail's
; i1-valued view, no gate), 12 (the case-1 edge reaches cq_phi(pi) under no quantum predicate at any depth: a global
; phase, deleted; the other two edges are under the quantum flag and kick back), 21 (the cell addresses are classical
; integers; inbounds is never consulted).
; Checked: m = sum x[i] << i, x[i] the cells x + i of the bus block (read by the measure loop's load copies).
; Clean: the case-2 parity rails (nq of them), the parity seed and the nq load copies of x[i] the parity loop takes; the
; default arm's load copy of x[0]; the swap rail of every in-place form (2 nq of them, |0> after the swap-in).
; Kept: per cell, the seed alloc_i8(0) of `store i8 0` and that store's tape slot (rule 5 sentence 3, rule 7; nq each);
; the nq load copies of x[i] the measure loop measures (rule 2). The cells are the registers.
; Rotations: Ry(pi/2) on the cells x[0..nq-1] (control 1); then exactly one of (classical switch on sel):
;   sel == 0: nothing;  sel == 1: nothing (global phase deleted);
;   sel == 2: P(pi) on flag(x0 ^ ... ^ x[nq-1])   [control predicate: the parity of x; nothing when nq <= 0];
;   default:  P(pi) on the load copy of x[0]     [control predicate x0: a basis copy of the cell, un-copied at once];
; then Ry(-pi/2) on the cells x[0..nq-1] (control 1).
; Expected: m == 0 iff f is constant. Replayed against the old slot-array lowering (state vector over the trace):
;   deutsch_jozsa(3, 2) -> m = 7, p = 1; deutsch_jozsa(3, 0) -> m = 0, p = 1; deutsch_jozsa(5, 3) -> m = 1, p = 1;
;   deutsch_jozsa(5, 1) -> m = 0, p = 1. The bus lowering is the same unitary on the cells: the kept seeds and tape
;   slots are classical |0> records (the cells hold 0 when the store is made), every load copy that a phase or a parity
;   reads is un-copied before the next swap of its cell, and the default arm's P(pi) on a basis copy of x[0] is P(pi) on
;   the cell; so the outcomes are unchanged (analytic, not replayed; the trace stubs compute nothing).
; FLAT MEMORY. -O1 inlined f_eval: the `switch i32 %1` sends case 0 to the join, case 1 straight to the cq_phi block,
; case 2 to the parity loop (guarded by nq > 0; nq <= 0 goes to the join with p = false), and the default to a load of
; x[0]; the two quantum arms meet in `phi i1 %24` and `br i1 %24` guards the phase block. The handle phi under classical
; control is not emitted: its only consumer is the kickback, which is emitted per arm because the case-2 arm must
; uncompute its own parity rails and load copies, and the default arm its load copy. The parity loop's carried
; `phi i1 %13`, seeded by the literal false, is a carried rail seeded by alloc_i1(0) (rule 7). No memory version change
; lies between a parity load and its _unc (the loop and its mirror only load), so sentence 1 un-copies them all; the
; same holds for the default arm's load.
; The init loop: `store i8 0, ptr %27; %28 = cq_theta_i1(false, pi/2); %29 = zext; store i8 %29, ptr %27`. The
; cq_theta's operand is the value -O1 forwarded from the store of 0 to the same SSA pointer, and nothing lies between
; that store and the store of %29: the in-place form, emitted at the second store's position (the swap-out reads the 0
; the cell holds).
; SPEC GAPS (marked at the line):
;  1. The forwarded y of rule 5's Readers clause is here a classical literal (false, from `store i8 0`), not a rail and
;     not a `load; trunc`, and rule 2 says a cq_theta of a classical v mints alloc_<W>(v). Chosen: the in-place form at
;     width i1 (the cell is the register). The mint read would rotate a fresh rail and make `store i8 %29` a kept
;     store of it: the cell would then hold a CNOT copy of a kept register, and the later in-place Ry(-pi/2) on the cell
;     would act on a dephased qubit (DJ would no longer give m == 0 iff f is constant).
source_filename = "deutsch_jozsa.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @deutsch_jozsa(i32 noundef %0, i32 noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: the bus handle m (once, at function entry)
  %4 = zext i32 %0 to i64    ; IR: %3 = zext i32 %0 to i64  (classical cell count)
  %5 = call ptr @__cq_alloc(i64 %4, i64 16)    ; IR: %4 = alloca i8, i64 %3, align 16  [bus-resident (rule 20 (b): a rail is stored into it): one zeroed block of nq cells, no alloca]
  %6 = icmp sgt i32 %0, 0    ; IR: %5  (classical)
  br i1 %6, label %7, label %17    ; IR: br i1 %5, label %6, label %8

7:; IR: block %6
  %8 = zext nneg i32 %0 to i64    ; IR: %7  (classical bound)
  br label %9    ; IR: br label %25

9:; IR: block %25  (x[i] = false; H^n: the Ry(pi/2) loop, classical bound nq)
  %10 = phi i64 [ 0, %7 ], [ %15, %9 ]    ; IR: %26  (classical i)
  %11 = getelementptr inbounds i8, ptr %5, i64 %10    ; IR: %27  (the cell x[i])
  %12 = ptrtoint ptr %11 to i64    ; IR: %27 as its run-time address (classical)
  %13 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i8 0, ptr %27  [the stored literal as a seed rail (rule 7), kept with its store]
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %12, i32 %13)    ; IR: store i8 0, ptr %27  (a kept store: no _unc, its tape slot and its seed stay, rule 5 sentence 3)
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %28 = cq_theta_i1(false, pi/2): in-place form at width i1 on the value forwarded from that store (rule 5, Readers, Width casts), the swap rail (|0>)  SPEC GAP 1: a forwarded classical literal opens the form (not rule 2's mint)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %12, i32 %14)    ; IR: %28: swap-out: the rail holds x[i] (0), the cell's low bit |0>
  call void @cqrt_ry_i1(i32 %14, double 0x3FF921FB54442D18)    ; IR: %28 = cq_theta_i1(false, pi/2)  [Ry(pi/2) on x[i]]
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %12, i32 %14)    ; IR: %29 = zext; store i8 %29, ptr %27: swap-in: the cell holds %28
  call void @cqrt_free(i32 %14)    ; IR: release the swap rail (|0>)
  %15 = add nuw nsw i64 %10, 1    ; IR: %30  (classical)
  %16 = icmp eq i64 %15, %8    ; IR: %31  (classical)
  br i1 %16, label %17, label %9    ; IR: br i1 %31, label %8, label %25

17:; IR: block %8
  switch i32 %1, label %43 [    ; IR: switch i32 %1 (classical: the function selector); case 0 -> the join (no phase); case 1 -> cq_phi(pi) under no quantum predicate: a global phase, deleted (rule 12), so the edge goes to the join
    i32 0, label %46
    i32 1, label %46
    i32 2, label %18
  ]

18:; IR: block %9  (case 2: f = parity of x)
  %19 = icmp sgt i32 %0, 0    ; IR: %10  (classical)
  br i1 %19, label %20, label %46    ; IR: br i1 %10, label %11, label %33  (nq <= 0: p = false, no phase)

20:; IR: edge %9 -> %11
  %21 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: incoming false of phi %13  [p before trip 0: a |0> seed rail]
  br label %22    ; IR: br label %11

22:; IR: block %11  (p ^= x[i], classical bound nq)
  %23 = phi i64 [ %29, %22 ], [ 0, %20 ]    ; IR: %12  (classical i)
  %24 = phi i32 [ %28, %22 ], [ %21, %20 ]    ; IR: %13 = phi i1 [ %17, %11 ], [ false, %9 ]  (the carried parity rail)
  %25 = getelementptr inbounds i8, ptr %5, i64 %23    ; IR: %14  (the cell x[i])
  %26 = ptrtoint ptr %25 to i64    ; IR: %14 as its run-time address (classical)
  %27 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %26)    ; IR: %15 = load i8, ptr %14  (!range [0,2): a plain bus load of the form's cell, taken at width i1, rule 5 Width casts)
  %28 = call i32 @cq_template_xor_i1(i32 %27, i32 %24)    ; IR: %16 = zext i1 %13 to i8 (a view, no gate); %17 = icmp ne i8 %15, %16  [= x[i] ^ p on i1-valued i8s: the next parity, a fresh rail]
  call void @cqrt_push(i32 %24)    ; IR: trip-local rail on the handle stack (rule 14): the previous parity
  call void @cqrt_push(i32 %27)    ; IR: trip-local rail on the handle stack (rule 14): the load copy of x[i] (un-copied by the mirror, rule 5 sentence 1)
  %29 = add nuw nsw i64 %23, 1    ; IR: %18  (classical)
  %30 = icmp eq i64 %29, %4    ; IR: %19  (classical)
  br i1 %30, label %31, label %22    ; IR: br i1 %19, label %23, label %11

31:; IR: block %23 reached from %11  (%24 = phi i1 [ %17, %11 ]; br i1 %24 -> block %32)
  call void @cqrt_rz_i1(i32 %28, double 0x400921FB54442D18)    ; IR: %24 = phi i1 [ %17, %11 ]; br i1 %24 -> block %32: cq_phi(pi)  [kickback on the parity flag]
  %32 = add nsw i64 %4, -1    ; IR: (mirror of the parity loop: undoes trip nq-1 down to 0; classical)
  br label %33    ; IR: (mirror)

33:; IR: reverse loop over the parity trips
  %34 = phi i64 [ %32, %31 ], [ %40, %33 ]    ; IR: i of the trip being undone  (classical)
  %35 = phi i32 [ %28, %31 ], [ %37, %33 ]    ; IR: %17 of the trip being undone
  %36 = call i32 @cqrt_pop()    ; IR: the trip's load copy of x[i] (%15)
  %37 = call i32 @cqrt_pop()    ; IR: the trip's incoming parity (%13)
  call void @cq_template_xor_i1_unc(i32 %35, i32 %36, i32 %37)    ; IR: uncompute %17 of that trip
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  %38 = getelementptr i8, ptr %5, i64 %34    ; IR: (the cell x[i], recomputed from the trip index)
  %39 = ptrtoint ptr %38 to i64    ; IR: (its run-time address, classical)
  call void @cqrt_qram_load_i1_hl_unc(i32 %36, i32 %3, i64 %39)    ; IR: un-copy %15 of that trip after its last reader (rule 5 sentence 1: the cells unchanged since the load)
  call void @cqrt_free(i32 %36)    ; IR: release it (|0>)
  %40 = add nsw i64 %34, -1    ; IR: (classical)
  %41 = icmp eq i64 %34, 0    ; IR: (classical)
  br i1 %41, label %42, label %33    ; IR: (classical)

42:; IR: end of the mirror
  call void @cqrt_free(i32 %37)    ; IR: release incoming false of phi %13 (the seed; never written, |0>; rule 7)
  br label %46    ; IR: br label %33

43:; IR: block %20  (default: f = x[0])
  %44 = ptrtoint ptr %5 to i64    ; IR: %4 as its run-time address (classical)
  %45 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %44)    ; IR: %21 = load i8, ptr %4; %22 = trunc nuw to i1  (a plain bus load of x[0] at width i1, rule 5 Width casts)
  call void @cqrt_rz_i1(i32 %45, double 0x400921FB54442D18)    ; IR: %24 = phi i1 [ %22, %20 ]; br i1 %24 -> block %32: cq_phi(pi)  [phase on the bare rail %22 itself: a diagonal gate on a basis copy of the cell, no flag]
  call void @cqrt_qram_load_i1_hl_unc(i32 %45, i32 %3, i64 %44)    ; IR: un-copy %21 right after its last reader (rule 5 sentence 1)
  call void @cqrt_free(i32 %45)    ; IR: release it (|0>)
  br label %46    ; IR: br label %23 -> br label %33

46:; IR: block %33 (the join)
  %47 = icmp sgt i32 %0, 0    ; IR: %34  (classical)
  br i1 %47, label %48, label %50    ; IR: br i1 %34, label %35, label %37

48:; IR: block %35
  %49 = zext nneg i32 %0 to i64    ; IR: %36  (classical bound)
  br label %54    ; IR: br label %41

50:; IR: block %37
  %51 = icmp sgt i32 %0, 0    ; IR: %38  (classical)
  br i1 %51, label %52, label %61    ; IR: br i1 %38, label %39, label %50

52:; IR: block %39
  %53 = zext nneg i32 %0 to i64    ; IR: %40  (classical bound)
  br label %63    ; IR: br label %52

54:; IR: block %41  (H^n: the Ry(-pi/2) loop, classical bound nq)
  %55 = phi i64 [ 0, %48 ], [ %59, %54 ]    ; IR: %42  (classical i)
  %56 = getelementptr inbounds i8, ptr %5, i64 %55    ; IR: %43  (the cell x[i])
  %57 = ptrtoint ptr %56 to i64    ; IR: %43 as its run-time address (classical)
  %58 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %44 = load i8, ptr %43; %45 = trunc nuw to i1: in-place form at width i1 (rule 5, Width casts), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %57, i32 %58)    ; IR: %44/%45: swap-out: the rail holds x[i], the cell's low bit |0>
  call void @cqrt_ry_i1(i32 %58, double 0xBFF921FB54442D18)    ; IR: %46 = cq_theta_i1(%45, -pi/2)  [Ry(-pi/2) on x[i]]
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %57, i32 %58)    ; IR: %47 = zext; store i8 %47, ptr %43: swap-in: the cell holds %46
  call void @cqrt_free(i32 %58)    ; IR: release the swap rail (|0>)
  %59 = add nuw nsw i64 %55, 1    ; IR: %48  (classical)
  %60 = icmp eq i64 %59, %49    ; IR: %49  (classical)
  br i1 %60, label %50, label %54    ; IR: br i1 %49, label %37, label %41

61:; IR: block %50
  %62 = phi i32 [ 0, %50 ], [ %73, %63 ]    ; IR: %51  (classical m)
  ret i32 %62    ; IR: ret i32 %51

63:; IR: block %52  (the measure loop, classical bound nq)
  %64 = phi i64 [ 0, %52 ], [ %74, %63 ]    ; IR: %53  (classical i)
  %65 = phi i32 [ 0, %52 ], [ %73, %63 ]    ; IR: %54  (classical m)
  %66 = getelementptr inbounds i8, ptr %5, i64 %64    ; IR: %55  (the cell x[i])
  %67 = ptrtoint ptr %66 to i64    ; IR: %55 as its run-time address (classical)
  %68 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %67)    ; IR: %56 = load i8, ptr %55; %57 = trunc nuw to i1  (a plain bus load at width i1; measured, so it stays: rule 2)
  %69 = call i1 @cqrt_measure_i1(i32 %68)    ; IR: %58 = cq_measure_i1(%57)
  %70 = zext i1 %69 to i32    ; IR: %59  (classical)
  %71 = trunc nuw nsw i64 %64 to i32    ; IR: %60  (classical)
  %72 = shl nuw i32 %70, %71    ; IR: %61  (classical)
  %73 = or i32 %72, %65    ; IR: %62  (classical)
  %74 = add nuw nsw i64 %64, 1    ; IR: %63  (classical)
  %75 = icmp eq i64 %74, %53    ; IR: %64  (classical)
  br i1 %75, label %61, label %63    ; IR: br i1 %64, label %50, label %52
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare void @cqrt_qram_load_i1_hl_unc(i32, i32, i64)
declare i32 @cq_template_xor_i1(i32, i32)
declare void @cq_template_xor_i1_unc(i32, i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
