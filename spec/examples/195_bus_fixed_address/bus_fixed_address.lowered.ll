; HAND-WRITTEN. Rules: 2, 3, 4, 5, 6, 16, 18, 19, 20, 21; §1.3 (the bus, __cq_mem, __cq_alloc), §1.4 (own symbol).
; Checked: bus_global_cell: cell + y = x + y (the y rail %7 after the in-place add, measured -> %9), and the cell `cell` = x (read from the bus at exit).
;          bus_escaped_local: w = x + 1 (the load copy %7, measured -> %8), the cell w = x + 1.
;          bus_rotate_cell: reg (the load copy %4, measured -> %5), the cell `reg` = the rotated 2.
; Clean: bus_global_cell: the load copy of cell (%8, un-copied: its last consumer precedes every memory version change);
;        y is not freed: cell + y is rule 6's in-place update of the dead y on its rail.
;        bump: the swap rail (%4: *p, updated in place by rule 6, then the cell's |0> after the swap-in).
;        bus_rotate_cell: the swap rail (%3, |0> after the swap-in).
; Kept: bus_global_cell: x (%6: rotated, and the value rail of the kept store, rule 5), the tape slot of the store
;       `store i32 %5, ptr @cell` (no handle: it is in the backend and holds the displaced `cell`), the sum (%7, the y rail updated in place, measured).
;       bus_escaped_local: x (%6: rotated, value rail of the kept store), the tape slot of the store `store i32 %4,
;       ptr %3` (no handle), the load copy of w (%7, measured). bus_rotate_cell: the load copy of reg (%4, measured).
;       bump keeps nothing (the in-place form leaves no rail, tape slot or old value).
; Rotations: bus_global_cell: (Ry, x, tx, 1); (Ry, y, ty, 1). bus_escaped_local: (Ry, x, tx, 1).
;            bus_rotate_cell: (Ry, the cell reg, tr, 1).
; Expected (Ry(th) acts on every qubit of an i32 rail, so each of the 32 bits flips with probability s(th) = sin^2(th/2),
;   independently: P(v) = s^d (1 - s)^(32 - d), d the Hamming distance of v from the start value):
;   bus_global_cell(3, .5, 4, .25): x from 3 with s = 0.0612087, y from 4 with s = 0.0155438; the measured sum is the
;     convolution mod 2^32, mode 7 with probability 0.080597 (0.080259 of it from x = 3, y = 4).
;   bus_escaped_local(3, .5): w = x + 1, x from 3 with s = 0.0612087: mode 4 with probability 0.132498 (x unchanged); each
;     single-bit flip of x has probability 0.008639.
;   bus_rotate_cell(.75): reg from 2 with s = 0.1341556: 2 with probability 0.009956, each single-bit neighbour 0.001543.
; ONE BUS, CLASSICAL ADDRESSES (rule 20). All memory is the bus m = __cq_mem(), called once at the entry of every function
; that accesses the bus (§5). A global lives at its host address: nothing is allocated, seeded or registered for `cell`
; and `reg`, and the address operand of the _hl forms is the pointer's run-time i64 (ptrtoint). Every store is a bus
; store and every load a bus load whose result is a rail (rule 3), whatever the cell holds.
; bus_global_cell. `cell = x` is a KEPT store (rule 5, sentence 3): no _unc exists, its tape slot stays for the shot and
; so does its value rail x. The load of cell is a fresh copy of the cells. cell + y is an add of two rails that are both
; dead after it: the load copy is garbage rule 5 uncomputes anyway, so rule 6 applies to y: the in-place update
; add_i32(copy, y) makes the y rail the sum (the gate reads the copy), and then the copy is un-copied (sentence 1: its consumers and their uncompute precede every memory
; version change; the cells still hold what they held at the load) and freed. The sum is measured.
; bus_escaped_local. The alloca of w has a store of a rail and a call among its users, so it is bus-resident (rule 20 b):
; it is __cq_alloc(4, 4) at the alloca's program point (rule 16), no alloca remains and the lifetime markers are dropped.
; `int w = x` is a kept store at the block's address. bump is called with a classical pointer: mask 0, bump's OWN symbol
; (§1.4, rule 19), never inlined. The call is a memory version change (bump writes memory); the load of w after it is a
; fresh copy, measured, so it stays as rule 2's measured rail.
; bump. `*p += 1` is load, add, store on the same SSA pointer with nothing between: rule 5's IN-PLACE FORM with rule 6's
; in-place update as its one step (rule 6, "a memory cell"). Swap-out into a fresh |0> rail, y' = y + 1 as addc_i32 on
; that rail, swap-in of y', free of the rail that now holds the cell's |0>. Nothing remains: no copy, no tape slot.
; The same body serves host callers and all-classical calls: on a classical-valued cell every rail here is
; classical-valued and the swaps write host bytes (§1.3 overlay).
; bus_rotate_cell. cq_theta(&reg, tr) is `load @reg; cq_theta; store @reg` straight back through the same pointer: rule
; 2's rotation of a cell, the in-place form with the Ry as its step. The gate acts on the cell's content while it sits in
; the swap rail; the swap-in returns it and the rail is freed. cq_measure(reg) reads the stored value y' (-O1 forwarded
; it): a later reader of y' is a plain load taken after the swap-in (rule 5, Readers), and that copy is measured.
source_filename = "bus_fixed_address.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@reg = local_unnamed_addr global i32 2, align 4
@cell = local_unnamed_addr global i32 0, align 4

define i32 @bus_global_cell(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 ptrtoint (ptr @cell to i64), i32 %6)    ; IR: store i32 %5, ptr @cell: cell = x  (kept store at a classical address: tape slot and value rail stay, no _unc)
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %6 = cq_theta_si32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %6 = cq_theta_si32(%2, %3)  [Ry]
  %8 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 ptrtoint (ptr @cell to i64))    ; IR: %7 = load i32, ptr @cell  (a bus load at the same classical address: a fresh rail)
  call void @cqrt_add_i32(i32 %8, i32 %7)    ; IR: %8 = add nsw i32 %7, %6  [rule 6, in-place update: y is dead after the add (the other operand is the load copy, rule-5 garbage), so the sum IS the y rail]  ; SPEC GAP: rule 6 'both operands dead' does not say that a bus load copy is 'garbage that rule 5 uncomputes anyway' (its un-copy is itself conditional, rule 5 sentence 1); taken as such here, since no memory version change follows
  call void @cqrt_qram_load_i32_hl_unc(i32 %8, i32 %5, i64 ptrtoint (ptr @cell to i64))    ; IR: un-copy %7 (rule 5: no memory version change since the load; the cells hold the loaded value)  ; SPEC GAP: sentence 1 asks for the last consumer's uncompute, and the consumer %8 is measured (never uncomputed); read as for a template operand of a measured result (29): un-copied before the measurement
  call void @cqrt_free(i32 %8)    ; IR: release the %7 rail (|0>)
  %9 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %9    ; IR: ret i32 %9
}

define i32 @bus_escaped_local(i32 noundef %0, double noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %4 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %3 = alloca i32, align 4: w is bus-resident (a rail is stored through it, it is a call argument): a zeroed block, no alloca remains
  %5 = ptrtoint ptr %4 to i64    ; IR: the address of w as the _hl operand (classical, run time)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %5, i32 %6)    ; IR: store i32 %4, ptr %3: int w = x  (kept store; llvm.lifetime.start is dropped)
  call fastcc void @bump(ptr %4)    ; IR: call fastcc void @bump(ptr %3): a classical pointer, mask 0 = bump's own symbol (a memory version change)
  %7 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %5)    ; IR: %5 = load i32, ptr %3: w  (a fresh copy of the cell after bump's update)
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %6 = cq_measure_si32(%5)  (the measured load copy stays allocated; llvm.lifetime.end is dropped)
  ret i32 %8    ; IR: ret i32 %6
}

; SPEC GAP: §1.4 fixes the own symbol's name and parameter list, not its linkage or calling convention; -O1's `internal fastcc` is kept.
define internal fastcc void @bump(ptr %0) unnamed_addr {
  %2 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %3 = ptrtoint ptr %0 to i64    ; IR: the address p as the _hl operand (classical, run time)
  %4 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %2 = load i32, ptr %0: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %2, i64 %3, i32 %4)    ; IR: %2 = load i32, ptr %0: swap-out: the rail holds *p, the cell |0>
  call void @cqrt_addc_i32(i32 %4, i32 1)    ; IR: %3 = add nsw i32 %2, 1  [rule 6, in-place update: the old *p is dead after the add, so y' IS the swap rail]
  call void @cqrt_qram_swap_i32_hl(i32 %2, i64 %3, i32 %4)    ; IR: store i32 %3, ptr %0: swap-in: the cell holds *p + 1, the rail the cell's |0>
  call void @cqrt_free(i32 %4)    ; IR: release the swap rail (|0>): nothing remains of the update
  ret void    ; IR: ret void
}

define i32 @bus_rotate_cell(double noundef %0) {
  %2 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %3 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %2 = load i32, ptr @reg: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %2, i64 ptrtoint (ptr @reg to i64), i32 %3)    ; IR: %2 = load i32, ptr @reg: swap-out: the rail holds reg, the cell |0>
  call void @cqrt_ry_i32(i32 %3, double %0)    ; IR: %3 = cq_theta_si32(%2, %0)  [Ry on the cell's content]
  call void @cqrt_qram_swap_i32_hl(i32 %2, i64 ptrtoint (ptr @reg to i64), i32 %3)    ; IR: store i32 %3, ptr @reg: swap-in: the cell holds the rotated value
  call void @cqrt_free(i32 %3)    ; IR: release the swap rail (|0>)
  %4 = call i32 @cqrt_qram_load_i32_hl(i32 %2, i64 ptrtoint (ptr @reg to i64))    ; IR: the reader of %3: a plain load of @reg taken after the swap-in (rule 5, Readers)
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %4 = cq_measure_si32(%3)  (the measured load copy stays allocated)
  ret i32 %5    ; IR: ret i32 %4
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_add_i32(i32, i32)
declare void @cqrt_addc_i32(i32, i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)
