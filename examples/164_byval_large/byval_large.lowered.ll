; HAND-WRITTEN. Rules: 26, 22, 20, 21, 16, 18, 5, 7, 2, 3, 4; §1.4.
; Checked: sum3(p, c) = p.a + p.b * c + p.c (the clone's copied-out result rail, measured, both entries); the cells of
; the caller's block of p at exit (read from the bus at its address): a = the rotated register, b, c as stored; the
; cells of the byval copy at exit: the same 24 bytes.
; Clean: the swap rail of each in-place form (|0> after its swap-in, freed); inside __cq_q_sum3_00 (both calls): the three load copies p.a, p.b, p.c (un-copied after their last reader,
; no memory version change follows them in the clone, rule 5 sentence 1) and the template rails b * c, the two adds
; (uncomputed by their _unc after the copy-out, rule 18).
; Kept: the cells that hold the rotated registers (p.a in _one; p.a and p.b in _two: rotated in place, rule 5's
; in-place form); the measured result rail (rule 2; no twin is called); by rule 5 (sentence 3) and rule
; 7: the three seed stores of the initializer {x0, b, c} / {x0, y0, c} with their seeds (tape slot + seed rail each);
; by rule 22: the 24 byte load copies of
; the byval copy, each the value rail of a kept byte store, and the 24 byte stores' tape slots.
; Rotations: byval_large_one: (Ry, p.a, tx, 1). byval_large_two: (Ry, p.a, tx, 1); (Ry, p.b, ty, 1).
; Expected (driver): byval_large_one(0, .5, 2, 3) measures a + 2 * 3 + 3 = a + 9, a = 0 with every bit flipped
; independently with p = sin^2(.25) = 0.061209 (P(9) = (1 - p)^64 = 0.0176); byval_large_two(0, .5, 1, .25, 3) measures
; a + 3 * b + 3, b = 1 with every bit flipped with q = sin^2(.125) = 0.015544 (the unflipped branch a = 0, b = 1 gives 6 with (1 - p)^64 (1 - q)^64 = 0.0064).
; ONE BUS (rules 20, 21, 26). A 24-byte struct passed BY VALUE travels as a `byval` pointer to a caller-made copy. The
; caller's alloca %struct.big is BUS-RESIDENT (rule 20 (b): a store of a tainted value and the call are among its
; users), so it is __cq_alloc(24, 8) at its program point and its lifetime markers are dropped (rule 16). The struct
; initializer is three ordinary kept bus stores at the run-time addresses p, p + 8, p + 16, each value a seed (rule 7).
; cq_theta(&p.a, tx) is, after -O1, cq_theta_sl on the parameter x0 forwarded from the store to cell a, followed by
; `store %8, ptr %5` to the same cell: rule 5's IN-PLACE FORM on the cell, not a fresh register: alloc_i64(0),
; qram_swap_i64_hl (the rail holds the cell's x0, the cell |0>), the Ry on the rail, qram_swap_i64_hl back, free. The
; register lives in cell a. The same for p.b in _two.
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
  call void @cqrt_qram_store_i64_hl(i32 %5, i64 %7, i32 %8)    ; IR: store i64 %0, ptr %5  (kept store, rule 5)
  %9 = getelementptr inbounds i8, ptr %6, i64 8    ; IR: %6 = getelementptr inbounds i8, ptr %5, i64 8  (nothing tainted: the gep stays)
  %10 = ptrtoint ptr %9 to i64    ; IR: %6 as its run-time address (cell b)
  %11 = call i32 @cqrt_alloc_i64(i64 %2)    ; IR: store i64 %2, ptr %6: the seed (rule 7)
  call void @cqrt_qram_store_i64_hl(i32 %5, i64 %10, i32 %11)    ; IR: store i64 %2, ptr %6  (kept store)
  %12 = getelementptr inbounds i8, ptr %6, i64 16    ; IR: %7 = getelementptr inbounds i8, ptr %5, i64 16
  %13 = ptrtoint ptr %12 to i64    ; IR: %7 as its run-time address (cell c)
  %14 = call i32 @cqrt_alloc_i64(i64 %3)    ; IR: store i64 %3, ptr %7: the seed (rule 7)
  call void @cqrt_qram_store_i64_hl(i32 %5, i64 %13, i32 %14)    ; IR: store i64 %3, ptr %7  (kept store)
  %15 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: %8 = cq_theta_sl(%0, %1); store i64 %8, ptr %5: %0 is forwarded from the store to the same cell: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i64_hl(i32 %5, i64 %7, i32 %15)    ; IR: %8 = cq_theta_sl(%0, %1): swap-out: the rail holds the cell's %0, the cell |0>
  call void @cqrt_ry_i64(i32 %15, double %1)    ; IR: %8 = cq_theta_sl(%0, %1)  [Ry in place on p.a]
  call void @cqrt_qram_swap_i64_hl(i32 %5, i64 %7, i32 %15)    ; IR: store i64 %8, ptr %5: swap-in: the cell holds register p.a
  call void @cqrt_free(i32 %15)    ; IR: release the swap rail (|0>)
  %16 = call ptr @__cq_alloc(i64 24, i64 8)    ; IR: %9 = call @sum3(byval(%struct.big) align 8 %5, ...): the byval copy q (rule 26)
  %17 = ptrtoint ptr %16 to i64    ; IR: q as its run-time address
  br label %18    ; IR: the byval copy: a rule-22 bus copy of 24 bytes from %5 to q (load all, then store all)

18:
  %19 = phi i64 [ 0, %4 ], [ %22, %18 ]    ; byte index of the load loop (classical)
  %20 = add i64 %7, %19    ; the source byte's address (classical)
  %21 = call i32 @cqrt_qram_load_i8_hl(i32 %5, i64 %20)    ; IR: byval copy  [source byte j: a bus load; the copy is the value rail of byte j's store, KEPT (rule 22)]
  call void @cqrt_push(i32 %21)    ; the handle outlives its SSA value (§1.1, rule 22)
  %22 = add nuw nsw i64 %19, 1
  %23 = icmp eq i64 %22, 24
  br i1 %23, label %24, label %18

24:
  %25 = phi i64 [ 24, %18 ], [ %26, %24 ]    ; bytes left to store (classical)
  %26 = add nsw i64 %25, -1    ; byte index of this store: 23 down to 0 (the pop order)
  %27 = call i32 @cqrt_pop()    ; the load copy of byte %26
  %28 = add i64 %17, %26    ; the destination byte's address (classical)
  call void @cqrt_qram_store_i8_hl(i32 %5, i64 %28, i32 %27)    ; IR: byval copy  [destination byte: a kept store (rule 22)]
  %29 = icmp eq i64 %26, 0
  br i1 %29, label %30, label %24

30:
  %31 = call fastcc i32 @__cq_q_sum3_00(ptr noundef %16, i64 noundef %3)    ; IR: %9 = call fastcc @sum3(ptr byval %5, i64 %3): the plain-ptr form (§1.4, rule 26), mask 00 (classical q, classical c); the result rail
  %32 = call i64 @cqrt_measure_i64(i32 %31)    ; IR: %10 = cq_measure_sl(%9)  (the measured rail stays allocated; no twin, rule 2)
  ret i64 %32    ; IR: llvm.lifetime.end(%5) dropped (rule 16); ret i64 %10
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
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %8, i32 %9)    ; IR: store i64 %0, ptr %6  (kept store)
  %10 = getelementptr inbounds i8, ptr %7, i64 8    ; IR: %7 = getelementptr inbounds i8, ptr %6, i64 8  (nothing tainted: the gep stays)
  %11 = ptrtoint ptr %10 to i64    ; IR: %7 as its run-time address (cell b)
  %12 = call i32 @cqrt_alloc_i64(i64 %2)    ; IR: store i64 %2, ptr %7: the seed (rule 7)
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %11, i32 %12)    ; IR: store i64 %2, ptr %7  (kept store)
  %13 = getelementptr inbounds i8, ptr %7, i64 16    ; IR: %8 = getelementptr inbounds i8, ptr %6, i64 16
  %14 = ptrtoint ptr %13 to i64    ; IR: %8 as its run-time address (cell c)
  %15 = call i32 @cqrt_alloc_i64(i64 %4)    ; IR: store i64 %4, ptr %8: the seed (rule 7)
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %14, i32 %15)    ; IR: store i64 %4, ptr %8  (kept store)
  %16 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: %9 = cq_theta_sl(%0, %1); store i64 %9, ptr %6: %0 is forwarded from the store to the same cell: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i64_hl(i32 %6, i64 %8, i32 %16)    ; IR: %9 = cq_theta_sl(%0, %1): swap-out: the rail holds the cell's %0, the cell |0>
  call void @cqrt_ry_i64(i32 %16, double %1)    ; IR: %9 = cq_theta_sl(%0, %1)  [Ry in place on p.a]
  call void @cqrt_qram_swap_i64_hl(i32 %6, i64 %8, i32 %16)    ; IR: store i64 %9, ptr %6: swap-in: the cell holds register p.a
  call void @cqrt_free(i32 %16)    ; IR: release the swap rail (|0>)
  %17 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: %10 = cq_theta_sl(%2, %3); store i64 %10, ptr %7: %2 is forwarded from the store to the same cell: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i64_hl(i32 %6, i64 %11, i32 %17)    ; IR: %10 = cq_theta_sl(%2, %3): swap-out: the rail holds the cell's %2, the cell |0>
  call void @cqrt_ry_i64(i32 %17, double %3)    ; IR: %10 = cq_theta_sl(%2, %3)  [Ry in place on p.b]
  call void @cqrt_qram_swap_i64_hl(i32 %6, i64 %11, i32 %17)    ; IR: store i64 %10, ptr %7: swap-in: the cell holds register p.b
  call void @cqrt_free(i32 %17)    ; IR: release the swap rail (|0>)
  %18 = call ptr @__cq_alloc(i64 24, i64 8)    ; IR: %11 = call @sum3(byval(%struct.big) align 8 %6, ...): the byval copy q (rule 26)
  %19 = ptrtoint ptr %18 to i64    ; IR: q as its run-time address
  br label %20    ; IR: the byval copy: a rule-22 bus copy of 24 bytes from %6 to q (load all, then store all)

20:
  %21 = phi i64 [ 0, %5 ], [ %24, %20 ]    ; byte index of the load loop (classical)
  %22 = add i64 %8, %21    ; the source byte's address (classical)
  %23 = call i32 @cqrt_qram_load_i8_hl(i32 %6, i64 %22)    ; IR: byval copy  [source byte j: a bus load; the copy is the value rail of byte j's store, KEPT (rule 22)]
  call void @cqrt_push(i32 %23)    ; the handle outlives its SSA value (§1.1, rule 22)
  %24 = add nuw nsw i64 %21, 1
  %25 = icmp eq i64 %24, 24
  br i1 %25, label %26, label %20

26:
  %27 = phi i64 [ 24, %20 ], [ %28, %26 ]    ; bytes left to store (classical)
  %28 = add nsw i64 %27, -1    ; byte index of this store: 23 down to 0 (the pop order)
  %29 = call i32 @cqrt_pop()    ; the load copy of byte %28
  %30 = add i64 %19, %28    ; the destination byte's address (classical)
  call void @cqrt_qram_store_i8_hl(i32 %6, i64 %30, i32 %29)    ; IR: byval copy  [destination byte: a kept store (rule 22)]
  %31 = icmp eq i64 %28, 0
  br i1 %31, label %32, label %26

32:
  %33 = call fastcc i32 @__cq_q_sum3_00(ptr noundef %18, i64 noundef %4)    ; IR: %11 = call fastcc @sum3(ptr byval %6, i64 %4): the same plain-ptr clone, mask 00; the result rail
  %34 = call i64 @cqrt_measure_i64(i32 %33)    ; IR: %12 = cq_measure_sl(%11)  (the measured rail stays allocated; no twin, rule 2)
  ret i64 %34    ; IR: llvm.lifetime.end(%6) dropped (rule 16); ret i64 %12
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
