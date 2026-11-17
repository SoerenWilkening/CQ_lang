; HAND-WRITTEN. Rules: 2, 4, 5, 7, 8, 9, 14, 16, 20, 21, 22; §1.3 (the bus, __cq_mem, qram_swap).
; Checked: m, the three counting bits x[T-1-j] (the byte cells x + 2 - j of the bus block %2; the measure loop takes a
; plain load copy of each at width i1, %91, and measures it, %92), and y = a^x mod N (the copied-out rail %35 -> %82); the
; result is m | y << 8.
; Clean: per H trip the swap rail of the in-place form on x[j] (|0> after its swap-in); every mod-exp trip rail (the load
; copy of x[j] that is the trip's condition, the product, the remainder and the select of each trip, pushed and popped by
; the mirror loop right after the loop: the select, then the load copy un-copied, then the remainder and the product),
; the rail holding the classical seed y = 1 (%18, popped as %43, never written); in the QFT^-1 the Toffoli flags (one per
; (j, k) pair) with the two load copies each reads (x[T-1-k] plain, x[T-1-j] loaded under x[T-1-k] and un-copied under
; it), the load copy of x[T-1-j] that carries cq_phi(pi) (un-copied before the swap-out) and the swap rail of every
; in-place Ry.
; Kept: the memset value seed (alloc_i8(0), rule 7) and the tape slots of its three byte stores (rule 5 sentence 3,
; rule 22); the three load copies the measure loop measures (rule 2) and the measured y result rail. The cells are the
; registers: entangled with y as |x>|a^x mod N> until measured.
; Rotations: (Ry, cell x[j], pi/2, 1) for j = 0, 1, 2 (H on |0>); then for j = 0, 1, 2 over the logical qubit x[T-1-j]:
; (P, flag, -pi / 2^(j-k), x[T-1-k] & x[T-1-j]) for each k < j, (P, copy of x[T-1-j], pi, x[T-1-j]) (rz_i1 on the bare
; load copy), and (Ry, cell x[T-1-j], pi/2, 1). The mod-exp is a permutation (no rotation).
; Shor order finding for N = 15, a = 7, T = 3 counting qubits, end to end: the three parts are examples 58 (a bool
; array of registers), 62 (the controlled modular multiply in a classical loop) and 60 (the QFT^-1 loops), composed.
; FLAT MEMORY (rule 20). `bool x[T]` stores rails (the cq_theta results), so the alloca is BUS-RESIDENT (rule 20 (b)):
; __cq_alloc(3, 1) at its program point (rule 16: zeroed; the lifetime markers are dropped), and every access is a bus
; access at its run-time address (gep, then ptrtoint: classical, _hl). The initializer -O1 turned into a memset is rule
; 22's host loop of byte stores of ONE i8 seed, kept (emitted although the block is zero already: §0). The cells are the
; registers; no handle is ever stored (§1.1). H|0>: each `load i8; trunc nuw to i1; cq_theta_i1; zext; store i8` on one
; SSA pointer is rule 5's in-place form through the Width-casts clause: alloc_i1(0), qram_swap_i1_hl, ry_i1 on the swap
; rail, qram_swap_i1_hl, free.
; Mod-exp: the condition `if (x[j])` is a plain bus load of x[j] at width i1 (SPEC GAP 1), a BARE RAIL that is its own
; flag (59); the arm's mul/urem are hoisted out of the arm into fresh rails and the phi is one select on that rail; y is
; loop-carried, seeded with a rail holding the classical 1; the classical recurrence ap = ap*ap % N runs beside it and is
; pushed for the mirror. The loop is MIRRORED RIGHT AFTER IT (62's placement): the final y is copied out and every
; trip's rails are uncomputed. The load copy of x[j] is a trip-local rail that rule 5 does not keep: its last reader is
; the select's _unc in the mirror, and the forward loop, the copy-out and the mirror make no memory version change (loads
; only), so it is pushed with the trip's rails and un-copied right after that _unc (rule 5 sentence 1; the reverse trip
; recomputes the classical address from its trip index). After the mirror only the three cells and the y result rail
; remain, entangled: |x>|a^x mod N>.
; QFT^-1: `if (x[T-1-k] && x[T-1-j]) cq_phi` is two nested branches (-O1 keeps the short-circuit): the load of x[T-1-k]
; is plain, the reload of x[T-1-j] sits in the arm of the x[T-1-k] flag and is the _controlled load under it (rule 5);
; the two are ONE Toffoli flag (rule 8), a kickback with the classical angle, un-Toffoli, free, then both copies are
; un-copied (60). `if (x[T-1-j]) cq_phi(pi)` reads y of the in-place Ry that follows (load %36, store %59 through %35):
; rule 5 Readers, a plain load taken before the swap-out; the phase is rz_i1 on that bare copy (a diagonal gate needs
; no flag), the copy is un-copied, then the in-place Ry(pi/2) (H = Ry(pi/2)·Z on a superposed qubit). The measure loop
; takes plain load copies of the cells and measures them; y is measured last. Every load copy before the measure loop is
; un-copied, so the state is the old slot-array lowering's: m uniform on {0, 2, 4, 6}, y in {1, 7, 4, 13} (analytic;
; the replayer of _tools/replay reads the retired slot model and was not re-run on this trace).
; SPEC GAP 1: every read of a _Bool cell here is the program's own `load i8; trunc nuw i8 to i1` with no in-place form
; around it (the mod-exp condition, the QFT^-1 flag loads, the measure loop). Rule 5's Width-casts clause fixes the width
; U only for a reader's plain load of a form. Chosen as 60, 117 and 205: one qram_load_i1_hl at the trunc's width (§1.3:
; the low bit of the cell), not a qram_load_i8 and a trunc template.
source_filename = "shor15.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @shor15() {
  %1 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %2 = call ptr @__cq_alloc(i64 3, i64 1)    ; IR: %1 = alloca [3 x i8], align 1: x is bus-resident (rule 20 (b): a rail is stored into it), one zeroed block (rule 16); lifetime.start dropped
  %3 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%1, i8 0, i64 3): the byte value as ONE seed rail (rules 7, 22), kept with its stores
  br label %4

4:; IR: call @llvm.memset(%1, i8 0, i64 3): host loop of 3 byte stores (rule 22, classical length; never unrolled)
  %5 = phi i64 [ 0, %0 ], [ %8, %4 ]    ; IR: (classical byte b)
  %6 = getelementptr inbounds i8, ptr %2, i64 %5    ; IR: (the byte x + b)
  %7 = ptrtoint ptr %6 to i64    ; IR: (its run-time address, classical)
  call void @cqrt_qram_store_i8_hl(i32 %1, i64 %7, i32 %3)    ; IR: memset: byte store b  (kept store, rule 5)
  %8 = add nuw nsw i64 %5, 1    ; IR: (classical)
  %9 = icmp eq i64 %8, 3    ; IR: (classical: b + 1 == 3)
  br i1 %9, label %10, label %4

10:; IR: block %2  (H on every counting cell)
  %11 = phi i64 [ 0, %4 ], [ %15, %10 ]    ; IR: %3  (classical j)
  %12 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %11    ; IR: %4 = getelementptr [3 x i8], ptr %1, 0, %3  (the cell x[j])
  %13 = ptrtoint ptr %12 to i64    ; IR: %4 as its run-time address (rule 20)
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %5 = load i8, ptr %4; %6 = trunc nuw to i1: in-place form at width i1 (rule 5, Width casts), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %1, i64 %13, i32 %14)    ; IR: %5/%6: swap-out: the rail holds x[j], the cell's low bit |0>
  call void @cqrt_ry_i1(i32 %14, double 0x3FF921FB54442D18)    ; IR: %7 = cq_theta_i1(%6, pi/2)  [H|0>: Ry(pi/2) on x[j]]
  call void @cqrt_qram_swap_i1_hl(i32 %1, i64 %13, i32 %14)    ; IR: %8 = zext; store i8 %8, ptr %4: swap-in: the cell holds %7
  call void @cqrt_free(i32 %14)    ; IR: release the swap rail (|0>)
  %15 = add nuw nsw i64 %11, 1    ; IR: %9  (classical)
  %16 = icmp eq i64 %15, 3    ; IR: %10  (classical)
  br i1 %16, label %17, label %10    ; IR: br i1 %10

17:
  %18 = call i32 @cqrt_alloc_i32(i32 1)    ; IR: incoming 1 of phi %14  [y before trip 0: a rail holding the classical 1]
  br label %19

19:; IR: block %11  (mod-exp, classical bound)
  %20 = phi i64 [ %32, %29 ], [ 0, %17 ]    ; IR: %12  (classical j)
  %21 = phi i32 [ %31, %29 ], [ 7, %17 ]    ; IR: %13  (classical ap = 7^(2^j) mod 15)
  %22 = phi i32 [ %28, %29 ], [ %18, %17 ]    ; IR: %14 = phi i32 [ %22, %21 ], [ 1, %2 ]
  %23 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %20    ; IR: %15  (the cell x[j])
  %24 = ptrtoint ptr %23 to i64    ; IR: %15 as its run-time address
  %25 = call i32 @cqrt_qram_load_i1_hl(i32 %1, i64 %24)    ; IR: %16 = load i8, ptr %15; %17 = trunc nuw to i1  (a plain bus load of x[j] at width i1, SPEC GAP 1: a bare rail, the condition of block %18 by itself)
  %26 = call i32 @cq_template_mul_i32_hl(i32 %22, i32 %21)    ; IR: %19 = mul i32 %13, %14  (block %18, hoisted: pure; commutative, classical operand to _hl)
  %27 = call i32 @cq_template_urem_i32_hl(i32 %26, i32 15)    ; IR: %20 = urem i32 %19, 15  (block %18, hoisted)
  %28 = call i32 @cq_template_select_i32(i32 %25, i32 %27, i32 %22)    ; IR: %22 = phi i32 [ %20, %18 ], [ %14, %11 ] = x[j] ? %20 : %14
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %21)    ; IR: classical ap of this trip, needed by the reverse loop
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %25)    ; IR: the load copy of x[j]: un-copied by the reverse loop (rule 5 sentence 1, rule 14)
  br label %29    ; IR: br label %21

29:; IR: block %21
  %30 = mul nuw nsw i32 %21, %21    ; IR: %23  (classical)
  %31 = urem i32 %30, 15    ; IR: %24  (classical)
  %32 = add nuw nsw i64 %20, 1    ; IR: %25  (classical)
  %33 = icmp eq i64 %32, 3    ; IR: %26  (classical)
  br i1 %33, label %34, label %19    ; IR: br i1 %26, label %27, label %11

34:
  %35 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %22 of the last trip  [copied-out y = a^x mod N, entangled with x]
  call void @cqrt_copy_i32(i32 %28, i32 %35)    ; IR: %22
  br label %36

36:; IR: the mirror of block %11 (no memory version change since the forward loads)
  %37 = phi i64 [ 0, %34 ], [ %47, %36 ]    ; IR: reverse trip index (undoes trip 2 - r)
  %38 = phi i32 [ %28, %34 ], [ %43, %36 ]    ; IR: %22 of the trip being undone
  %39 = call i32 @cqrt_pop()    ; IR: that trip's load copy of x[j]
  %40 = call i32 @cqrt_pop()
  %41 = call i32 @cqrt_pop()
  %42 = call i32 @cqrt_pop()    ; IR: classical ap of that trip
  %43 = call i32 @cqrt_pop()
  %44 = sub nuw nsw i64 2, %37    ; IR: j of the trip being undone  (classical)
  %45 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %44    ; IR: (the cell x[j], recomputed from the trip index)
  %46 = ptrtoint ptr %45 to i64    ; IR: (its run-time address, classical)
  call void @cq_template_select_i32_unc(i32 %38, i32 %39, i32 %40, i32 %43)    ; IR: uncompute %22
  call void @cqrt_free(i32 %38)    ; IR: release the %22 rail (|0>)
  call void @cqrt_qram_load_i1_hl_unc(i32 %39, i32 %1, i64 %46)    ; IR: un-copy %16/%17 (its last reader, the select _unc, is done)
  call void @cqrt_free(i32 %39)    ; IR: release the %16 rail (|0>)
  call void @cq_template_urem_i32_hl_unc(i32 %40, i32 %41, i32 15)    ; IR: uncompute %20
  call void @cqrt_free(i32 %40)    ; IR: release the %20 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %41, i32 %43, i32 %42)    ; IR: uncompute %19
  call void @cqrt_free(i32 %41)    ; IR: release the %19 rail (|0>)
  %47 = add nuw nsw i64 %37, 1
  %48 = icmp eq i64 %47, 3
  br i1 %48, label %49, label %36

49:
  call void @cqrt_free(i32 %43)    ; IR: release incoming 1 of phi %14 (never written, holds the classical 1)
  br label %50    ; IR: br label %27

50:; IR: block %27  (QFT^-1 outer loop)
  %51 = phi i64 [ %63, %57 ], [ 0, %49 ]    ; IR: %28  (classical j of the QFT^-1)
  %52 = icmp eq i64 %51, 0    ; IR: %29  (classical)
  br i1 %52, label %57, label %53    ; IR: br i1 %29

53:; IR: block %30
  %54 = sub nuw nsw i64 2, %51    ; IR: %31  (classical T - 1 - j)
  %55 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %54    ; IR: %32  (the cell x[T-1-j])
  %56 = ptrtoint ptr %55 to i64    ; IR: %32 as its run-time address
  br label %65    ; IR: br label %38

57:; IR: blocks %33, %56, %57
  %58 = sub nuw nsw i64 2, %51    ; IR: %34  (classical)
  %59 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %58    ; IR: %35  (the cell x[T-1-j])
  %60 = ptrtoint ptr %59 to i64    ; IR: %35 as its run-time address
  %61 = call i32 @cqrt_qram_load_i1_hl(i32 %1, i64 %60)    ; IR: %36 = load i8, ptr %35; %37 = trunc nuw to i1: y of the in-place form below has another reader (br i1 %37): a plain load taken before the swap-out (rule 5, Readers; width i1, SPEC GAP 1)
  call void @cqrt_rz_i1(i32 %61, double 0x400921FB54442D18)    ; IR: br i1 %37 -> block %56: cq_phi(pi)  [phase on the bare rail itself: a diagonal gate on the copy, no flag]
  call void @cqrt_qram_load_i1_hl_unc(i32 %61, i32 %1, i64 %60)    ; IR: un-copy the reader's copy (before the swap-out, the next memory version change)
  call void @cqrt_free(i32 %61)    ; IR: release it (|0>)
  %62 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %36/%37: in-place form at width i1 on %35, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %1, i64 %60, i32 %62)    ; IR: %36/%37: swap-out
  call void @cqrt_ry_i1(i32 %62, double 0x3FF921FB54442D18)    ; IR: %58 = cq_theta_i1(%37, pi/2)  [Ry on x[T-1-j]]
  call void @cqrt_qram_swap_i1_hl(i32 %1, i64 %60, i32 %62)    ; IR: %59 = zext; store i8 %59, ptr %35: swap-in
  call void @cqrt_free(i32 %62)    ; IR: release the swap rail (|0>)
  %63 = add nuw nsw i64 %51, 1    ; IR: %60  (classical)
  %64 = icmp eq i64 %63, 3    ; IR: %61  (classical)
  br i1 %64, label %85, label %50    ; IR: br i1 %61

65:; IR: block %38  (classical k)
  %66 = phi i64 [ 0, %53 ], [ %79, %78 ]    ; IR: %39  (classical k)
  %67 = sub nuw nsw i64 2, %66    ; IR: %40  (classical T - 1 - k)
  %68 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %67    ; IR: %41  (the cell x[T-1-k])
  %69 = ptrtoint ptr %68 to i64    ; IR: %41 as its run-time address
  %70 = call i32 @cqrt_qram_load_i1_hl(i32 %1, i64 %69)    ; IR: %42 = load i8, ptr %41; %43 = trunc nuw to i1  (a plain bus load of x[T-1-k], SPEC GAP 1; the flag of br i1 %43)
  %71 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %70, i32 %1, i64 %56)    ; IR: block %44: %45 = load i8, ptr %32; %46 = trunc nuw to i1  (in the arm of %43: the _controlled load, rule 5)
  %72 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %47 = %43 & %46
  call void @cqrt_and_i1(i32 %70, i32 %71, i32 %72)    ; IR: br i1 %43 -> block %44, br i1 %46 -> block %47: one Toffoli flag (rule 8)
  %73 = sub nuw nsw i64 %51, %66    ; IR: %48  (classical j - k)
  %74 = trunc nuw i64 %73 to i32    ; IR: %49  (classical)
  %75 = shl nuw nsw i32 1, %74    ; IR: %50  (classical 1 << (j - k))
  %76 = uitofp nneg i32 %75 to double    ; IR: %51  (classical)
  %77 = fdiv double 0xC00921FB54442D18, %76    ; IR: %52  (classical angle -pi / 2^(j-k))
  call void @cqrt_rz_i1(i32 %72, double %77)    ; IR: block %47: cq_phi(%52)  [kickback on the flag]
  call void @cqrt_and_i1(i32 %70, i32 %71, i32 %72)    ; IR: uncompute the %47 predicate
  call void @cqrt_free(i32 %72)    ; IR: release the flag (|0>)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %71, i32 %70, i32 %1, i64 %56)    ; IR: un-copy %45 under the same %43 (its last reader is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %71)    ; IR: release the %45 rail (|0>)
  call void @cqrt_qram_load_i1_hl_unc(i32 %70, i32 %1, i64 %69)    ; IR: un-copy %42
  call void @cqrt_free(i32 %70)    ; IR: release the %42 rail (|0>)
  br label %78    ; IR: br label %53

78:; IR: block %53
  %79 = add nuw nsw i64 %66, 1    ; IR: %54  (classical)
  %80 = icmp eq i64 %79, %51    ; IR: %55  (classical)
  br i1 %80, label %57, label %65    ; IR: br i1 %55

81:; IR: block %62
  %82 = call i32 @cqrt_measure_i32(i32 %35)    ; IR: %63 = cq_measure_ui32(%22)
  %83 = shl i32 %82, 8    ; IR: %64  (classical)
  %84 = or i32 %83, %96    ; IR: %65  (classical); lifetime.end dropped
  ret i32 %84    ; IR: ret i32 %65

85:; IR: block %66  (measure loop, classical)
  %86 = phi i64 [ %97, %85 ], [ 0, %57 ]    ; IR: %67  (classical j)
  %87 = phi i32 [ %96, %85 ], [ 0, %57 ]    ; IR: %68  (classical m)
  %88 = sub nuw nsw i64 2, %86    ; IR: %69  (classical)
  %89 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %88    ; IR: %70  (the cell x[T-1-j])
  %90 = ptrtoint ptr %89 to i64    ; IR: %70 as its run-time address
  %91 = call i32 @cqrt_qram_load_i1_hl(i32 %1, i64 %90)    ; IR: %71 = load i8, ptr %70; %72 = trunc nuw to i1  (a plain bus load, SPEC GAP 1)
  %92 = call i1 @cqrt_measure_i1(i32 %91)    ; IR: %73 = cq_measure_i1(%72)  [the load copy is the measured rail, rule 2: never un-copied]
  %93 = zext i1 %92 to i32    ; IR: %74  (classical)
  %94 = trunc nuw nsw i64 %86 to i32    ; IR: %75  (classical)
  %95 = shl nuw nsw i32 %93, %94    ; IR: %76  (classical)
  %96 = or i32 %95, %87    ; IR: %77  (classical)
  %97 = add nuw nsw i64 %86, 1    ; IR: %78  (classical)
  %98 = icmp eq i64 %97, 3    ; IR: %79  (classical)
  br i1 %98, label %81, label %85    ; IR: br i1 %79
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare void @cqrt_qram_load_i1_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i1_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i1_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_urem_i32_hl(i32, i32)
declare void @cq_template_urem_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
