; HAND-WRITTEN. Rules: 20, 22, 5, 2, 11, 15, 3, 7, 14, 16, 21, 4; §1.3 (the bus, __cq_mem, __cq_alloc).
; Checked: e = sum of cq_measure(q[i]) over i < n: each measured q[i] (the i1 load copy of cell i,
; IR %33/%34 -> %35). The cells of the block on the bus at exit: the low bit of q[i] holds the measured outcome of q[i]
; (its high 7 bits 0), 0 <= i < n.
; Clean: per rotate trip, the swap rail of the in-place form (|0> after the swap-in, freed).
; Kept: the cells q[0..n-1] themselves (the registers live in memory: rotated in place, read and measured through load
; copies); by rule 5 sentence 3, the n tape slots of the memset's byte stores and their ONE value seed alloc_i8(0) (rules
; 7, 22; classical-valued, no qubit); by rule 5 sentence 1, the n angle load copies theta[i] (IR %22: each is un-copied
; right after its last reader, the Ry, and left allocated, since the in-place form's swap-out, a memory version change,
; lies between the load and that point (it is placed after the swap-in: no bus access between the form's swaps); HOST cells, classical-valued, no qubit); by rule 2, the n measured i1 load
; copies (IR %33/%34).
; Rotations: (Ry, q[i], A_i, 1) for i = 0..n-1 in loop order, A_i the f64 angle rail loaded from theta[i] (rules 11, 15: a
; value loaded from the bus is a quantum angle, rule 3), each in place on cell i through the in-place form's swap rail.
; Driver register_array(coef, 3); register_array(coef, 4), coef = {1, 2, 3, 4} a host array: Ry(theta[i]) on |0> gives
; 1 with probability sin^2(theta[i] / 2) = 0.2298, 0.7081, 0.9950, 0.8268, so e is a sum of independent Bernoullis
; (mean 1.9329 for n = 3, 2.7597 for n = 4).
; ONE BUS (rules 16, 20, 21). `bool q[n]` is -O1's `alloca i8, i64 n`. Its users are the memset (allowed by rule 20 (b)),
; the rotate loop's load and its STORE of a tainted value (the rotated bit): a store of a tainted value is no user rule
; 20 (b) allows, so the alloca is BUS-RESIDENT: __cq_alloc(n, 16) at its program point (rule 16: a VLA alike; zeroed host
; memory at an address never reused), and no alloca remains. The size is classical (n is a parameter): no K2, no
; overflow predicate. Nothing is known about the block: its base is its run-time address, a classical i64, and every
; access below is _hl at a classical address. m = __cq_mem() is called once, at entry (§5). The register size n is a
; function input, never a compile-time constant; this is the register-array shape of VQE/QPE (59, 60, 114).
; The zero-init loop is folded by -O1 into `llvm.memset(q, 0, n)` under `n > 0`: rule 22's ONE host loop of n byte
; stores of one i8 value rail, the seed alloc_i8(0), each a kept store at q + j (its tape slot and the seed stay, rule 5
; sentence 3). It is emitted although the __cq_alloc block is already zero (§0). Value, address and control are
; classical-valued, so the cells stay HOST.
; The rotate loop: `load i8 q[i] (!range [0, 2)); trunc nuw to i1; cq_theta_i1; zext to i8; store i8 q[i]` on the same
; SSA pointer with no memory version change between is rule 5's IN-PLACE FORM through the Width-casts clause, at width
; i1 (rule 2: the cq_theta's own width): alloc_i1(0), qram_swap_i1_hl (the rail holds the cell's bit, the cell |0>),
; the Ry, qram_swap_i1_hl back, free. The cell is the register; nothing of it remains outside the cell. The angle
; theta[i] is a bus load like any other (rule 3: nothing is asked about what the cell holds; theta is a pointer
; argument), so the angle is an f64 rail and the rotation is cqrt_ry_i1_qangle(h, A) (rules 11, 15: a value loaded from the bus is a quantum angle). That load is a load a
; step reads: a plain load at its own program point, before the swap-out, and the form overtakes it: it is un-copied
; after the Ry (its last reader), right after the swap-in, and stays allocated, not freed (rule 5 sentence 1).
; SPEC GAP: rule 15's "The angle rail is uncomputed afterwards" disagrees with rule 5 for this shape; the lowering
; follows: "An angle rail that is a bus load copy (or computed from one) follows rule 5: it is un-copied by sentence 1
; after its last reader, and freed only when no memory version change lies between the load and that point."
; The measure loop has a classical bound and a classical sum (each outcome is classical, rule 2): each trip reads the
; _Bool cell used as i1 (-O1's `load i8; trunc nuw i8 to i1`) as ONE bus access at width i1 (qram_load_i1_hl, as 205),
; with no i8 load and no trunc template; the load copy is measured, so it is never un-copied and stays (rules 2, 5).
; Nothing is pushed: no trip rail outlives its trip except the measured one, so there is no reverse loop (rule 14).
; SPEC GAP: rule 22 describes a classical length as "host loops of n trips" without fixing the loop shape; the memset
; is emitted as a top-tested loop that is correct for n = 0 by itself, without relying on -O1's `n > 0` guard.
source_filename = "register_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @register_array(ptr noundef %0, i32 noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: (no instruction) the bus handle m (once, at function entry, §5)
  %4 = zext i32 %1 to i64    ; IR: %3 = zext i32 %1 to i64  (classical n: the block's size in bytes)
  %5 = call ptr @__cq_alloc(i64 %4, i64 16)    ; IR: %4 = alloca i8, i64 %3, align 16  [bus-resident (a store of a tainted value): one zeroed block, no alloca remains (rules 16, 20)]
  %6 = ptrtoint ptr %5 to i64    ; IR: %4 as its run-time address, the memset's classical base (rule 21)
  %7 = icmp sgt i32 %1, 0    ; IR: %5  (classical)
  br i1 %7, label %8, label %17    ; IR: br i1 %5

8:
  %9 = zext nneg i32 %1 to i64    ; IR: %7  (classical memset length n)
  %10 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%4, i8 0, %7): the byte value as ONE seed rail (rules 7, 22), kept with its stores
  br label %11    ; IR: block %6: llvm.memset(%4, 0, %7) becomes rule 22's host loop of n byte stores

11:
  %12 = phi i64 [ 0, %8 ], [ %16, %14 ]    ; IR: llvm.memset(%4, 0, %7): byte j (classical)
  %13 = icmp ult i64 %12, %9    ; IR: llvm.memset: j < n (classical; SPEC GAP: the loop shape)
  br i1 %13, label %14, label %17    ; IR: llvm.memset: next byte or done

14:
  %15 = add i64 %6, %12    ; IR: llvm.memset: the classical address q + j
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %15, i32 %10)    ; IR: call @llvm.memset(%4, i8 0, %7): byte store j  (kept store at a classical address, rule 5 sentence 3; classical-valued, the cell stays HOST)
  %16 = add nuw nsw i64 %12, 1    ; IR: llvm.memset: j + 1 (classical)
  br label %11    ; IR: llvm.memset: loop

17:
  %18 = icmp sgt i32 %1, 0    ; IR: %9  (classical)
  br i1 %18, label %19, label %21    ; IR: br i1 %9

19:
  %20 = zext nneg i32 %1 to i64    ; IR: %11  (classical)
  br label %25    ; IR: br label %16

21:
  %22 = icmp sgt i32 %1, 0    ; IR: %13  (classical)
  br i1 %22, label %23, label %35    ; IR: br i1 %13

23:
  %24 = zext nneg i32 %1 to i64    ; IR: %15  (classical)
  br label %37    ; IR: br label %29

25:
  %26 = phi i64 [ 0, %19 ], [ %33, %25 ]    ; IR: %17 = phi i64  (classical trip counter i)
  %27 = getelementptr inbounds i8, ptr %5, i64 %26    ; IR: %18 = getelementptr inbounds i8, ptr %4, i64 %17  (untainted index: stays)
  %28 = ptrtoint ptr %27 to i64    ; IR: %18 as its run-time address (the _hl operand of the form's swaps)
  %29 = getelementptr inbounds double, ptr %0, i64 %26    ; IR: %21 = getelementptr inbounds double, ptr %0, i64 %17  (untainted index: stays)
  %30 = ptrtoint ptr %29 to i64    ; IR: %21 as its run-time address
  %31 = call i32 @cqrt_qram_load_f64_hl(i32 %3, i64 %30)    ; IR: %22 = load double, ptr %21  [a bus load at its own program point, before the swap-out: the angle rail A_i (rules 3, 11, 15); overtaken by the form, KEPT (rule 5 sentence 1)]
  %32 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %19 = load i8, ptr %18; %20 = trunc nuw i8 %19 to i1: in-place form at width i1 (Width casts), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %28, i32 %32)    ; IR: %19 = load i8, ptr %18; %20 = trunc: swap-out of the low bit: the rail holds q[i], the cell's bit |0>
  call void @cqrt_ry_i1_qangle(i32 %32, i32 %31)    ; IR: %23 = cq_theta_i1(%20, %22)  [Ry(val(A_i)) in place on q[i]'s content]
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %28, i32 %32)    ; IR: %24 = zext i1 %23 to i8; store i8 %24, ptr %18: swap-in: the cell holds the rotated bit (its high bits never left)
  call void @cqrt_qram_load_f64_hl_unc(i32 %31, i32 %3, i64 %30)    ; IR: un-copy %22 after its last reader, the Ry, once the form has closed (no bus access between its swaps); the swap-out lies between, so it stays allocated (rule 5 sentence 1)
  call void @cqrt_free(i32 %32)    ; IR: release the swap rail (|0>)
  %33 = add nuw nsw i64 %26, 1    ; IR: %25  (classical)
  %34 = icmp eq i64 %33, %20    ; IR: %26  (classical)
  br i1 %34, label %21, label %25    ; IR: br i1 %26

35:
  %36 = phi i32 [ 0, %21 ], [ %45, %37 ]    ; IR: %28 = phi i32  (classical sum of outcomes)
  ret i32 %36    ; IR: ret i32 %28

37:
  %38 = phi i64 [ 0, %23 ], [ %46, %37 ]    ; IR: %30  (classical trip counter)
  %39 = phi i32 [ 0, %23 ], [ %45, %37 ]    ; IR: %31  (classical running sum)
  %40 = getelementptr inbounds i8, ptr %5, i64 %38    ; IR: %32 = getelementptr inbounds i8, ptr %4, i64 %30  (untainted index: stays)
  %41 = ptrtoint ptr %40 to i64    ; IR: %32 as its run-time address
  %42 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %41)    ; IR: %33 = load i8, ptr %32; %34 = trunc nuw i8 %33 to i1  [the _Bool cell read as i1: ONE bus load at width i1 (rule 20)]
  %43 = call i1 @cqrt_measure_i1(i32 %42)    ; IR: %35 = cq_measure_i1(%34)  (the load copy is the measured rail; never un-copied, it stays allocated, rules 2, 5)
  %44 = zext i1 %43 to i32    ; IR: %36 = zext i1 %35 to i32  (classical)
  %45 = add nuw nsw i32 %39, %44    ; IR: %37  (classical)
  %46 = add nuw nsw i64 %38, 1    ; IR: %38  (classical)
  %47 = icmp eq i64 %46, %24    ; IR: %39  (classical)
  br i1 %47, label %35, label %37    ; IR: br i1 %39
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_f64_hl(i32, i64)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare void @cqrt_ry_i1_qangle(i32, i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_load_f64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare i1 @cqrt_measure_i1(i32)
