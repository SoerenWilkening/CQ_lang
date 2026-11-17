; HAND-WRITTEN. Rules: 20 (bool x[nq] is -O1's `alloca i8, i64 nq`; it stores tainted values, so it is BUS-RESIDENT:
; __cq_alloc(nq, 16), every access a bus access at its run-time address), 5 (each cq_theta of a cell is the in-place form
; through the Width-casts clause; Memory sentences 1 and 3), 2 (the cq_theta's own width i1; the measured load copies),
; 21 (gep, then ptrtoint: classical addresses, _hl), 16 (__cq_alloc), 14 (the H^n loop, the value loop, the H^n loop and
; the measure loop have the classical bound nq and stay ROLLED classical loops; the value loop pushes its four trip-local
; rails per trip, the load copy included, and a reverse loop pops and uncomputes them), 7 (v's |0> seed is freed directly;
; on the nq <= 0 path the literal 0 reaching `phi i32 %20` is materialised as a seed rail too, so the phi is all handles;
; the seed of each `store i8 0` is that kept store's value rail), 4 (v is zext_i8_to_i32 / shl_i32_hl / or_i32 into
; fresh rails; the oracle is and_i32_hl against the runtime s, ctpop_i32, and_i32_hl 1, icmp_eq_i32_hl 0, every one a
; fresh rail), 8 (the compare rail is the branch flag; the phase arm sits on the FALSE edge of `parity == 0`, so it is the
; X-bracketed kickback), 12 (the cq_phi is under a quantum predicate: not deleted); §1.3 (the bus, __cq_mem, __cq_alloc).
; Checked: m = sum x[i] << i: each measured x[i] (the i1 load copy of cell i, IR %60/%61 -> %62). The cells of the block on
; the bus at exit: the low bit of x[i] holds the measured outcome of x[i] (its high 7 bits 0), 0 <= i < nq.
; Clean: per H^n trip (both loops), the swap rail of the in-place form (|0> after the swap-in, freed); per value trip, the
; i8 load copy of x[i] (IR %29, un-copied by the reverse loop after the zext _unc, before H^n swaps the cells: rule 5
; sentence 1) and the zext, shl and or rails; the flag, the three oracle rails (and, ctpop, and) and the seed of v.
; Kept: the cells x[0..nq-1] themselves (the registers live in memory: rotated in place, read through load copies); by
; rule 5 sentence 3, per trip of the FIRST H^n loop only (the second H^n loop stores nothing: its store is the in-place
; form's swap-in), the tape slot of the kept store `store i8 0, ptr %14` and its value seed alloc_i8(0) (classical-valued,
; no qubit, rule 7); by rule 2, the nq measured i1 load copies (IR %60).
; Rotations: Ry(pi/2) on cell x[i], i = 0..nq-1 (control 1); P(pi) on NOT flag(popcount(v & s) & 1 == 0)  [control
;   predicate: the parity of x & s is odd, i.e. (-1)^{x.s}]; Ry(-pi/2) on cell x[i], i = 0..nq-1 (control 1); each Ry in
;   place on its cell through the form's swap rail.
; Expected: m = s mod 2^nq with probability 1 (analytic: the cells are the registers and nothing outside them stays
;   entangled with them when H^n runs the second time). bernstein_vazirani(4, 11) -> m = 11; bernstein_vazirani(5, 19)
;   -> m = 19; every free hits |0>.
; -O1 keeps the source structure: H^n as a rolled loop that stores 0 into x[i] and calls cq_theta_i1(false, pi/2) (the
; 0 forwarded from that store), v as an nq-trip accumulator loop (zext nneg i8 -> i32 of the cell, shl by the trip index,
; or into the carried i32 seeded by the literal 0), the oracle as `and`, ctpop, `and 1`, `icmp eq 0` with the cq_phi
; block on the FALSE edge, H^n again as `load i8; trunc nuw to i1; cq_theta_i1; zext; store i8`, and the measure loop
; as `load i8; trunc nuw to i1; cq_measure_i1`. Each loop is guarded by its own `nq > 0` test.
; ONE BUS (rules 16, 20, 21). The alloca's users include stores of a tainted value (the rotated bit), which rule 20 (b)
; does not allow: the block is __cq_alloc(nq, 16) at its program point (zeroed, an address never reused) and no alloca
; remains. The size is classical (nq is a parameter): no K2, no overflow predicate. Every gep has an untainted index and
; stays; its ptrtoint is the classical _hl address. m = __cq_mem() is called once, at entry (§5). No handle is ever
; stored (§1.1): the cells hold the qubits.
; THE FIRST H^n LOOP. `store i8 0, ptr %14` is an ordinary bus store of a classical value: the seed alloc_i8(0) and
; qram_store_i8_hl, KEPT (rule 5 sentence 3; value, address and control classical-valued, so the cell stays HOST). The
; cq_theta_i1(false, pi/2) rotates the value -O1 forwarded from that store to the same SSA pointer %14, and its result is
; stored back through %14 (zext to i8) with no memory version change between: rule 5's in-place form (Readers: y is the
; forwarded value; Width casts: the form at width i1): alloc_i1(0), qram_swap_i1_hl, ry_i1 on the swap rail,
; qram_swap_i1_hl, free (SPEC GAP 1).
; THE VALUE LOOP is the accumulator of 117's value(x): a bus load of the i8 cell (qram_load_i8_hl), zext_i8_to_i32, shl,
; or into fresh rails; the trip's previous accumulator, load copy, zext and shl rails are pushed. Its mirror runs after
; the kickback and before H^n swaps the cells, and only when the value loop ran (the same classical nq > 0 test): the
; load copy's last reader is the zext _unc in the mirror, and no memory version change lies between the load and that
; point, so it is un-copied there (rule 5 sentence 1). `v & s` has a quantum and a classical operand: the _hl template
; with the runtime literal s; ctpop is the unary intrinsic template of 56. The kickback P(pi) under `parity odd` is the
; phase oracle (-1)^{x.s}, so H^n (-1)^{x.s} H^n |0> = |s>.
; THE SECOND H^n LOOP: `load i8; trunc nuw to i1; cq_theta_i1(-pi/2); zext; store i8` on one SSA pointer is the in-place
; form through the Width-casts clause, as 58 and 117.
; THE MEASURE LOOP: each `load i8; trunc nuw to i1` is a plain bus load at width i1 (SPEC GAP 2, as 117, 205), measured
; and kept (rule 2: a measured load copy is never un-copied).
; SPEC GAP 1: rule 5's Readers clause forwards y from "the preceding store to p", and its Width-casts clause starts from
; `load T p; trunc T to U`. Here -O1 forwarded the stored i8 0 as the i1 literal false straight into cq_theta (no load,
; no trunc). Chosen: the in-place form at width i1 from the kept store's position (the cell holds the forwarded 0), not
; rule 2's mint alloc_i1(false) + a kept store of its zext copy, which would leave the register's rail and the store's
; value rail entangled with the cell.
; SPEC GAP 2: the measure loop's `load i8; trunc nuw i8 to i1` is no reader of a form's SSA value (another loop). Chosen
; as 117 and 205: one qram_load_i1_hl at the trunc's width (§1.3: the low bit of the cell), no trunc template.
source_filename = "bernstein_vazirani.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @bernstein_vazirani(i32 noundef %0, i32 noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: (no instruction) the bus handle m (once, at function entry, §5)
  %4 = zext i32 %0 to i64    ; IR: %3 = zext i32 %0 to i64  (classical nq: the block's size in bytes)
  %5 = call ptr @__cq_alloc(i64 %4, i64 16)    ; IR: %4 = alloca i8, i64 %3, align 16  [bus-resident (a store of a tainted value): one zeroed block, no alloca remains (rules 16, 20)]
  %6 = icmp sgt i32 %0, 0    ; IR: %5  (classical)
  br i1 %6, label %7, label %17    ; IR: br i1 %5, label %6, label %8

7:; IR: block %6
  %8 = zext nneg i32 %0 to i64    ; IR: %7  (classical bound)
  br label %9    ; IR: br label %12

9:; IR: block %12  (x[i] = false; H^n: the Ry(pi/2) loop, classical bound nq)
  %10 = phi i64 [ 0, %7 ], [ %15, %9 ]    ; IR: %13  (classical i)
  %11 = getelementptr inbounds i8, ptr %5, i64 %10    ; IR: %14 = getelementptr inbounds i8, ptr %4, i64 %13  (untainted index: stays)
  %12 = ptrtoint ptr %11 to i64    ; IR: %14 as its run-time address (rule 21)
  %13 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i8 0, ptr %14: the classical value as a seed (rule 7), the store's value rail, kept with it
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %12, i32 %13)    ; IR: store i8 0, ptr %14  (a kept store at a classical address, rule 5 sentence 3; classical-valued, the cell stays HOST)
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %15 = cq_theta_i1(false, pi/2) on the 0 forwarded from that store: in-place form at width i1, the swap rail (|0>)  ; SPEC GAP 1
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %12, i32 %14)    ; IR: %15 = cq_theta_i1(false, pi/2): swap-out of the low bit: the rail holds x[i], the cell's bit |0>
  call void @cqrt_ry_i1(i32 %14, double 0x3FF921FB54442D18)    ; IR: %15 = cq_theta_i1(false, pi/2)  [Ry(pi/2) in place on x[i]'s content]
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %12, i32 %14)    ; IR: %16 = zext i1 %15 to i8; store i8 %16, ptr %14: swap-in: the cell holds the rotated bit (its high bits never left)
  call void @cqrt_free(i32 %14)    ; IR: release the swap rail (|0>)
  %15 = add nuw nsw i64 %10, 1    ; IR: %17  (classical)
  %16 = icmp eq i64 %15, %8    ; IR: %18  (classical)
  br i1 %16, label %17, label %9    ; IR: br i1 %18, label %8, label %12

17:; IR: block %8
  %18 = icmp sgt i32 %0, 0    ; IR: %9  (classical)
  br i1 %18, label %21, label %19    ; IR: br i1 %9, label %10, label %19

19:; IR: edge %8 -> %19 (nq <= 0: v = 0)
  %20 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %20 [ 0, %8 ]  [a |0> seed rail: the phi is all handles (rule 7)]
  br label %36    ; IR: br label %19

21:; IR: block %10
  %22 = zext nneg i32 %0 to i64    ; IR: %11  (classical bound)
  %23 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %27 [ 0, %10 ]  [v before trip 0: a |0> seed rail]
  br label %24    ; IR: br label %25

24:; IR: block %25  (v |= x[i] << i, classical bound nq)
  %25 = phi i64 [ 0, %21 ], [ %34, %24 ]    ; IR: %26  (classical i)
  %26 = phi i32 [ %23, %21 ], [ %33, %24 ]    ; IR: %27 = phi i32 [ 0, %10 ], [ %33, %25 ]  (the carried accumulator rail)
  %27 = getelementptr inbounds i8, ptr %5, i64 %25    ; IR: %28 = getelementptr inbounds i8, ptr %4, i64 %26  (untainted index: stays)
  %28 = ptrtoint ptr %27 to i64    ; IR: %28 as its run-time address
  %29 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %28)    ; IR: %29 = load i8, ptr %28  [a bus load of the cell: fresh rail ^= cell x[i] (rule 20)]
  %30 = call i32 @cq_template_zext_i8_to_i32(i32 %29)    ; IR: %30 = zext nneg i8 %29 to i32  [fresh rail]
  %31 = trunc nuw nsw i64 %25 to i32    ; IR: %31  (classical)
  %32 = call i32 @cq_template_shl_i32_hl(i32 %30, i32 %31)    ; IR: %32 = shl nuw i32 %30, %31  [fresh rail]
  %33 = call i32 @cq_template_or_i32(i32 %32, i32 %26)    ; IR: %33 = or i32 %32, %27  [fresh rail: the next accumulator]
  call void @cqrt_push(i32 %26)    ; IR: trip-local rails on the handle stack (rule 14): the previous accumulator
  call void @cqrt_push(i32 %29)    ; IR: ... the load copy of x[i] (un-copied by the mirror, rule 5 sentence 1)
  call void @cqrt_push(i32 %30)    ; IR: ... the zext rail
  call void @cqrt_push(i32 %32)    ; IR: ... the shl rail
  %34 = add nuw nsw i64 %25, 1    ; IR: %34  (classical)
  %35 = icmp eq i64 %34, %22    ; IR: %35  (classical)
  br i1 %35, label %36, label %24    ; IR: br i1 %35, label %19, label %25

36:; IR: block %19  (the oracle)
  %37 = phi i32 [ %20, %19 ], [ %33, %24 ]    ; IR: %20 = phi i32 [ 0, %8 ], [ %33, %25 ]  (v: a rail on both edges)
  %38 = call i32 @cq_template_and_i32_hl(i32 %37, i32 %1)    ; IR: %21 = and i32 %20, %1  [v & s, s a runtime literal; fresh rail]
  %39 = call i32 @cq_template_ctpop_i32(i32 %38)    ; IR: %22 = llvm.ctpop.i32(%21)  [fresh rail]
  %40 = call i32 @cq_template_and_i32_hl(i32 %39, i32 1)    ; IR: %23 = and i32 %22, 1  [fresh rail]
  %41 = call i32 @cq_template_icmp_eq_i32_hl(i32 %40, i32 0)    ; IR: %24 = icmp eq i32 %23, 0  [the branch flag]
  call void @cqrt_not_i1(i32 %41)    ; IR: bracket: block %36 is the FALSE edge of br i1 %24 (rule 8)
  call void @cqrt_rz_i1(i32 %41, double 0x400921FB54442D18)    ; IR: block %36: cq_phi(pi)  [kickback: (-1)^{x.s}]
  call void @cqrt_not_i1(i32 %41)    ; IR: bracket
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %41, i32 %40, i32 0)    ; IR: uncompute %24
  call void @cqrt_free(i32 %41)    ; IR: release the flag (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %40, i32 %39, i32 1)    ; IR: uncompute %23
  call void @cqrt_free(i32 %40)    ; IR: release the %23 rail (|0>)
  call void @cq_template_ctpop_i32_unc(i32 %39, i32 %38)    ; IR: uncompute %22
  call void @cqrt_free(i32 %39)    ; IR: release the %22 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %38, i32 %37, i32 %1)    ; IR: uncompute %21
  call void @cqrt_free(i32 %38)    ; IR: release the %21 rail (|0>)
  %42 = icmp sgt i32 %0, 0    ; IR: (classical: did the value loop run? the mirror runs exactly when it did)
  br i1 %42, label %43, label %57    ; IR: (classical)

43:; IR: (mirror of the value loop: pops trip nq-1 down to 0 before H^n swaps the cells)
  %44 = add nsw i64 %4, -1    ; IR: (classical)
  br label %45    ; IR: (mirror)

45:; IR: reverse loop over the value trips
  %46 = phi i64 [ %44, %43 ], [ %55, %45 ]    ; IR: i of the trip being undone  (classical)
  %47 = phi i32 [ %37, %43 ], [ %51, %45 ]    ; IR: %33 of the trip being undone
  %48 = call i32 @cqrt_pop()    ; IR: the trip's shl rail (%32)
  %49 = call i32 @cqrt_pop()    ; IR: the trip's zext rail (%30)
  %50 = call i32 @cqrt_pop()    ; IR: the trip's load copy (%29)
  %51 = call i32 @cqrt_pop()    ; IR: the trip's incoming accumulator (%27)
  %52 = trunc nuw nsw i64 %46 to i32    ; IR: %31 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %47, i32 %48, i32 %51)    ; IR: uncompute %33
  call void @cqrt_free(i32 %47)    ; IR: release the %33 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %48, i32 %49, i32 %52)    ; IR: uncompute %32
  call void @cqrt_free(i32 %48)    ; IR: release the %32 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %49, i32 %50)    ; IR: uncompute %30
  call void @cqrt_free(i32 %49)    ; IR: release the %30 rail (|0>)
  %53 = getelementptr inbounds i8, ptr %5, i64 %46    ; IR: (the cell x[i], recomputed from the trip index)
  %54 = ptrtoint ptr %53 to i64    ; IR: its run-time address
  call void @cqrt_qram_load_i8_hl_unc(i32 %50, i32 %3, i64 %54)    ; IR: un-copy %29 (its last reader, the zext _unc, is done; no memory version change since the load: H^n has not run yet)
  call void @cqrt_free(i32 %50)    ; IR: release the %29 rail (|0>)
  %55 = add nsw i64 %46, -1    ; IR: (classical)
  %56 = icmp eq i64 %46, 0    ; IR: (classical)
  br i1 %56, label %57, label %45    ; IR: (classical)

57:; IR: (the join after the oracle)
  %58 = phi i32 [ %37, %36 ], [ %51, %45 ]    ; IR: the seed: incoming 0 of phi %27 (after the mirror) or of phi %20 (nq <= 0)
  call void @cqrt_free(i32 %58)    ; IR: release the seed (never written, |0>; rule 7)
  br label %59    ; IR: br i1 %24, label %37, label %36 -> block %37

59:; IR: block %37
  %60 = icmp sgt i32 %0, 0    ; IR: %38  (classical)
  br i1 %60, label %61, label %63    ; IR: br i1 %38, label %39, label %41

61:; IR: block %39
  %62 = zext nneg i32 %0 to i64    ; IR: %40  (classical bound)
  br label %67    ; IR: br label %45

63:; IR: block %41
  %64 = icmp sgt i32 %0, 0    ; IR: %42  (classical)
  br i1 %64, label %65, label %74    ; IR: br i1 %42, label %43, label %54

65:; IR: block %43
  %66 = zext nneg i32 %0 to i64    ; IR: %44  (classical bound)
  br label %76    ; IR: br label %56

67:; IR: block %45  (H^n: the Ry(-pi/2) loop, classical bound nq)
  %68 = phi i64 [ 0, %61 ], [ %72, %67 ]    ; IR: %46  (classical i)
  %69 = getelementptr inbounds i8, ptr %5, i64 %68    ; IR: %47 = getelementptr inbounds i8, ptr %4, i64 %46  (untainted index: stays)
  %70 = ptrtoint ptr %69 to i64    ; IR: %47 as its run-time address
  %71 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %48 = load i8, ptr %47; %49 = trunc nuw i8 %48 to i1: in-place form at width i1 (Width casts), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %70, i32 %71)    ; IR: %48/%49: swap-out of the low bit: the rail holds x[i], the cell's bit |0>
  call void @cqrt_ry_i1(i32 %71, double 0xBFF921FB54442D18)    ; IR: %50 = cq_theta_i1(%49, -pi/2)  [Ry(-pi/2) in place on x[i]'s content]
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %70, i32 %71)    ; IR: %51 = zext i1 %50 to i8; store i8 %51, ptr %47: swap-in: the cell holds the rotated bit
  call void @cqrt_free(i32 %71)    ; IR: release the swap rail (|0>)
  %72 = add nuw nsw i64 %68, 1    ; IR: %52  (classical)
  %73 = icmp eq i64 %72, %62    ; IR: %53  (classical)
  br i1 %73, label %63, label %67    ; IR: br i1 %53, label %41, label %45

74:; IR: block %54
  %75 = phi i32 [ 0, %63 ], [ %86, %76 ]    ; IR: %55  (classical m)
  ret i32 %75    ; IR: ret i32 %55

76:; IR: block %56  (the measure loop, classical bound nq)
  %77 = phi i64 [ 0, %65 ], [ %87, %76 ]    ; IR: %57  (classical i)
  %78 = phi i32 [ 0, %65 ], [ %86, %76 ]    ; IR: %58  (classical m)
  %79 = getelementptr inbounds i8, ptr %5, i64 %77    ; IR: %59 = getelementptr inbounds i8, ptr %4, i64 %57  (untainted index: stays)
  %80 = ptrtoint ptr %79 to i64    ; IR: %59 as its run-time address
  %81 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %80)    ; IR: %60 = load i8, ptr %59; %61 = trunc nuw i8 %60 to i1  [a plain bus load of x[i] at width i1; measured below, so never un-copied (rule 2)]  ; SPEC GAP 2
  %82 = call i1 @cqrt_measure_i1(i32 %81)    ; IR: %62 = cq_measure_i1(%61)  (the measured rail stays allocated, rule 2)
  %83 = zext i1 %82 to i32    ; IR: %63  (classical)
  %84 = trunc nuw nsw i64 %77 to i32    ; IR: %64  (classical)
  %85 = shl nuw i32 %83, %84    ; IR: %65  (classical)
  %86 = or i32 %85, %78    ; IR: %66  (classical)
  %87 = add nuw nsw i64 %77, 1    ; IR: %67  (classical)
  %88 = icmp eq i64 %87, %66    ; IR: %68  (classical)
  br i1 %88, label %74, label %76    ; IR: br i1 %68, label %54, label %56
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_not_i1(i32)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_ctpop_i32(i32)
declare void @cq_template_ctpop_i32_unc(i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
