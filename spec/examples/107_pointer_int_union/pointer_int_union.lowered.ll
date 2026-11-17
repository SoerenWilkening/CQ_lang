; HAND-WRITTEN. Rules: 2, 4, 5, 6, 7, 9, 16, 18, 19, 20, 21; §1.3, §1.4.
; Checked: union_ptr_to_int: *u.p + w (the add rail %17, measured -> %18): x odd: the address a + 4, a[1] + w = 2 + w;
; x even: the address b + 4, b[1] + w = 4 + w. The cells of a and b at exit: a = {1, 2}, b = {3, 4}.
; union_int_to_ptr: *u.p = a[x & 3] = w + (x & 3) (the load copy %25, measured -> %26); the
; cells of a at exit: {w, w + 1, w + 2, w + 3}. union_slot: *u.p + w (the add rail %19, measured -> %20): x odd:
; a[1] + w = 2 + w; x even: b[1] + w = 4 + w; the cells at exit: a = {1, 2}, b = {3, 4}, and u's 8 cells hold the
; address (x & 1 ? &a : &b) + 4.
; Clean: union_ptr_to_int: x & 1 (%12), its flag (%13), the pointer rail (the select, %14), the address rail u.v + 4
; (%15), the load copy *u.p (%16, un-copied after the add, before the measurement: no memory version change follows
; the load). union_int_to_ptr: the address chain 4 * x (%21), & 12 (%22), its zext (%23), u.v = that | &a (%24),
; uncomputed right after the load (the load copy is measured, so the load is the address rail's last reader).
; union_slot: x & 1 (%13) and its flag (%14), uncomputed after the store of the pointer; the load copy of u.p (%17, the
; address rail of the next load) and the load copy *u.p (%18), un-copied after the add, before the measurement (no
; memory version change follows either load). bump: the three rails of the in-place form (the swap rail %4, the rule-6
; inverse %6, the updated rail %5).
; Kept: x (%7 in union_ptr_to_int, %6 in union_int_to_ptr, %8 in union_slot: the rotated user registers) and the measured
; rails (%17 and %25 above; %19 in union_slot). By rule 5, for the shot: union_ptr_to_int: the tape slots of the stores
; a = {1, 2} and b = {3, 4} and their i64 seed value rails %9, %11. union_int_to_ptr: the tape slots of the four
; stores a[0..3] = w .. w + 3 and their seed value rails %8, %12, %16, %20. union_slot: the tape slots of the stores
; a = {1, 2}, b = {3, 4} (seeds %10, %12) and u.p = (x & 1) ? a : b, whose value rail is the pointer rail %15 (the
; select). The in-place form in bump keeps nothing.
; Rotations: (Ry, x, th, 1) in each of the three functions.
; A UNION of a pointer and an integer on quantum data. The IR never says "union": with plain code SROA folds the union
; into its value, and the member punning is ptrtoint / inttoptr ON VALUES. A POINTER IS AN INTEGER (rule 21): its
; x86-64 address, a classical ptr / i64 or ONE 64-bit address rail, so ptrtoint and inttoptr are identities and emit
; nothing; the punning needs no rule of its own (rule 20: each access is of the type and at the address its
; instruction names). Nothing about an object, base, extent or origin is carried, so no index is recovered from an
; address and no access is guarded, bounded or checked.
; union_ptr_to_int: p = (x & 1) ? a : b is a pointer select under a quantum flag: select_i64_ll of the two
; classical run-time addresses (rule 21 merge, rule 9) into the address rail p; u.v += 4 (-O1 writes it as or disjoint,
; both arrays being 8-aligned) is or_i64_hl on that rail;
; *u.p is ONE qram_load_i32 at it. union_int_to_ptr: u.v = (uintptr_t)a | 4 * (x & 3) is integer template arithmetic
; whose result is the address rail; *u.p is ONE qram_load_i32 at it. union_slot: the union's address escapes to bump, so
; u stays memory; p (an address rail) is stored into u's 8 cells as an i64 value (a kept store), bump loads it as i64,
; adds 4 and stores it back (the in-place form of rules 5 and 6 at a classical address), and the caller loads the cell
; as a pointer: the qram_load_i64 rail IS the address of the next access (rule 21, nested pointers).
; MEMORY (rule 20). Every alloca is bus-resident: a and b are operands of a pointer select (union_ptr_to_int,
; union_slot), a is an operand of ptrtoint (union_int_to_ptr), u receives a store of a rail and is passed to a call
; (union_slot). Each is one __cq_alloc(size, align) block at its program point, no alloca remains and the lifetime
; markers are dropped (rule 16). The -O1 initializers are bus stores at classical addresses (_hl) of seed value rails
; (rule 7), kept with their tape slots; the cells stay HOST (every value, address and control classical-valued).
; bump(&u) passes a classical pointer, so the call is bump's OWN symbol (the all-zero mask, §1.4) with its C parameter
; list, lowered; it writes memory, so it has no twin and the call is a memory version change (rules 5, 18). The loads
; of u.p and *u.p follow it and are un-copied with no memory version change after them.
; Regenerated 2026-11-05 for the one-bus memory model: the previous version carried fat pointers (tag, cell index), an
; object table of classical bases, per-object QROM loads merged by a select on the object flag, a slot cell of two
; handles and the clone __cq_q_bump_0011 with its _unc twin; all retired (§0).
source_filename = "pointer_int_union.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @union_ptr_to_int(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %4 = alloca [2 x i32], align 8: a is bus-resident (an operand of the pointer select %9, rule 20)
  %6 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %5 = alloca [2 x i32], align 8: b is bus-resident (an operand of the pointer select %9)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = ptrtoint ptr %5 to i64    ; IR: %4 as its run-time address (classical; llvm.lifetime.start dropped, rule 16)
  %9 = call i32 @cqrt_alloc_i64(i64 8589934593)    ; IR: store i64 8589934593, ptr %4: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %8, i32 %9)    ; IR: store i64 8589934593, ptr %4: a = {1, 2}  (kept store, classical address)
  %10 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address (classical)
  %11 = call i32 @cqrt_alloc_i64(i64 17179869187)    ; IR: store i64 17179869187, ptr %5: the value seed (kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %10, i32 %11)    ; IR: store i64 17179869187, ptr %5: b = {3, 4}  (kept store)
  %12 = call i32 @cq_template_and_i32_hl(i32 %7, i32 1)    ; IR: %7 = and i32 %6, 1
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 0)    ; IR: %8 = icmp eq i32 %7, 0
  %14 = call i32 @cq_template_select_i64_ll(i32 %13, i64 %10, i64 %8)    ; IR: %9 = select i1 %8, ptr %5, ptr %4  [the pointer: a 64-bit address rail, rule 21; flag true (x even) picks b]
  %15 = call i32 @cq_template_or_i64_hl(i32 %14, i64 4)    ; IR: %10 = ptrtoint (identity); %11 = or disjoint i64 %10, 4; %12 = inttoptr (identity)  [u.v += 4: the address rail of the load]
  %16 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %15)    ; IR: %13 = load i32, ptr %12  [*u.p: one bus load at the address rail, no guard]
  %17 = call i32 @cq_template_add_i32_hl(i32 %16, i32 %2)    ; IR: %14 = add nsw i32 %13, %2  [result rail]
  call void @cqrt_qram_load_i32_unc(i32 %16, i32 %4, i32 %15)    ; IR: un-copy %13 (its last reader %14 is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %16)    ; IR: release the %13 rail (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %15, i32 %14, i64 4)    ; IR: uncompute %11 (the address rail outlived its load's _unc, rule 20)
  call void @cqrt_free(i32 %15)    ; IR: release the %11 rail (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %14, i32 %13, i64 %10, i64 %8)    ; IR: uncompute the pointer %9
  call void @cqrt_free(i32 %14)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %12, i32 0)    ; IR: uncompute %8
  call void @cqrt_free(i32 %13)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %7, i32 1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %12)    ; IR: release the %7 rail (|0>)
  %18 = call i32 @cqrt_measure_i32(i32 %17)    ; IR: %15 = cq_measure_si32(%14)
  ret i32 %18    ; IR: ret i32 %15  (llvm.lifetime.end dropped)
}

define i32 @union_int_to_ptr(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %4 = alloca [4 x i32], align 16: a is bus-resident (an operand of ptrtoint %12, rule 20)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = ptrtoint ptr %5 to i64    ; IR: %4 as its run-time address (classical; also %12 = ptrtoint ptr %4; llvm.lifetime.start dropped)
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %4: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %7, i32 %8)    ; IR: store i32 %2, ptr %4: a[0] = w  (kept store, classical address)
  %9 = getelementptr inbounds i8, ptr %5, i64 4    ; IR: %6 = &a[1]  (nothing tainted: the gep stays)
  %10 = add nsw i32 %2, 1    ; IR: %7 = add nsw i32 %2, 1  (classical)
  %11 = ptrtoint ptr %9 to i64    ; IR: %6 as its run-time address
  %12 = call i32 @cqrt_alloc_i32(i32 %10)    ; IR: store i32 %7, ptr %6: the value seed
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %11, i32 %12)    ; IR: store i32 %7, ptr %6: a[1] = w + 1  (kept store)
  %13 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %8 = &a[2]
  %14 = add nsw i32 %2, 2    ; IR: %9 = add nsw i32 %2, 2  (classical)
  %15 = ptrtoint ptr %13 to i64    ; IR: %8 as its run-time address
  %16 = call i32 @cqrt_alloc_i32(i32 %14)    ; IR: store i32 %9, ptr %8: the value seed
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %15, i32 %16)    ; IR: store i32 %9, ptr %8: a[2] = w + 2  (kept store)
  %17 = getelementptr inbounds i8, ptr %5, i64 12    ; IR: %10 = &a[3]
  %18 = add nsw i32 %2, 3    ; IR: %11 = add nsw i32 %2, 3  (classical)
  %19 = ptrtoint ptr %17 to i64    ; IR: %10 as its run-time address
  %20 = call i32 @cqrt_alloc_i32(i32 %18)    ; IR: store i32 %11, ptr %10: the value seed
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %19, i32 %20)    ; IR: store i32 %11, ptr %10: a[3] = w + 3  (kept store)
  %21 = call i32 @cq_template_shl_i32_hl(i32 %6, i32 2)    ; IR: %13 = shl i32 %5, 2
  %22 = call i32 @cq_template_and_i32_hl(i32 %21, i32 12)    ; IR: %14 = and i32 %13, 12
  %23 = call i32 @cq_template_zext_i32_to_i64(i32 %22)    ; IR: %15 = zext nneg i32 %14 to i64
  %24 = call i32 @cq_template_or_i64_hl(i32 %23, i64 %7)    ; IR: %16 = or disjoint i64 %15, %12; %17 = inttoptr (identity)  [u.v: the address rail of the load]
  %25 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %24)    ; IR: %18 = load i32, ptr %17  [*u.p: one bus load at the address rail, no guard; the load copy is the measured rail]
  call void @cq_template_or_i64_hl_unc(i32 %24, i32 %23, i64 %7)    ; IR: uncompute %16 (a measured load copy: the load is its last reader, rule 20)
  call void @cqrt_free(i32 %24)    ; IR: release the %16 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %23, i32 %22)    ; IR: uncompute %15
  call void @cqrt_free(i32 %23)    ; IR: release the %15 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %22, i32 %21, i32 12)    ; IR: uncompute %14
  call void @cqrt_free(i32 %22)    ; IR: release the %14 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %21, i32 %6, i32 2)    ; IR: uncompute %13
  call void @cqrt_free(i32 %21)    ; IR: release the %13 rail (|0>)
  %26 = call i32 @cqrt_measure_i32(i32 %25)    ; IR: %19 = cq_measure_si32(%18)  [the load copy stays allocated, rule 2]
  ret i32 %26    ; IR: ret i32 %19  (llvm.lifetime.end dropped)
}

define i32 @union_slot(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %4 = alloca [2 x i32], align 8: a is bus-resident (an operand of the pointer select %10)
  %6 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %5 = alloca [2 x i32], align 8: b is bus-resident
  %7 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %6 = alloca %union.pv, align 8: u is bus-resident (a rail is stored into it; passed to bump)
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %7 = cq_theta_ui32(%0, %1)  [Ry]
  %9 = ptrtoint ptr %5 to i64    ; IR: %4 as its run-time address (classical; llvm.lifetime.start dropped, rule 16)
  %10 = call i32 @cqrt_alloc_i64(i64 8589934593)    ; IR: store i64 8589934593, ptr %4: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %9, i32 %10)    ; IR: store i64 8589934593, ptr %4: a = {1, 2}  (kept store, classical address)
  %11 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address (classical)
  %12 = call i32 @cqrt_alloc_i64(i64 17179869187)    ; IR: store i64 17179869187, ptr %5: the value seed (kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %11, i32 %12)    ; IR: store i64 17179869187, ptr %5: b = {3, 4}  (kept store)
  %13 = call i32 @cq_template_and_i32_hl(i32 %8, i32 1)    ; IR: %8 = and i32 %7, 1
  %14 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 0)    ; IR: %9 = icmp eq i32 %8, 0
  %15 = call i32 @cq_template_select_i64_ll(i32 %14, i64 %11, i64 %9)    ; IR: %10 = select i1 %9, ptr %5, ptr %4  [the pointer: a 64-bit address rail, rule 21]
  %16 = ptrtoint ptr %7 to i64    ; IR: %6 as its run-time address (classical)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %16, i32 %15)    ; IR: store ptr %10, ptr %6  [u.p = p: the address stored as an i64 cell value (rule 21); kept store, its value rail %10 is kept (rule 5)]
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %14, i32 %13, i32 0)    ; IR: uncompute %9 (its last consumer, the select, is done; the select's rail is kept, not uncomputed)
  call void @cqrt_free(i32 %14)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %8, i32 1)    ; IR: uncompute %8
  call void @cqrt_free(i32 %13)    ; IR: release the %8 rail (|0>)
  call fastcc void @bump(ptr noundef %7)    ; IR: call fastcc void @bump(ptr %6): a classical pointer, the all-zero mask: bump's own symbol, lowered (§1.4); it writes memory: no twin, a memory version change (rule 5)
  %17 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %16)    ; IR: %11 = load ptr, ptr %6  [u.p: a bus load at a classical address; the rail is the pointer, a 64-bit address rail]
  %18 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %17)    ; IR: %12 = load i32, ptr %11  [*u.p: one bus load at the address rail %11, no guard]
  %19 = call i32 @cq_template_add_i32_hl(i32 %18, i32 %2)    ; IR: %13 = add nsw i32 %12, %2  [result rail]
  call void @cqrt_qram_load_i32_unc(i32 %18, i32 %4, i32 %17)    ; IR: un-copy %12 (its last reader %13 is done; no memory version change since the load)
  call void @cqrt_free(i32 %18)    ; IR: release the %12 rail (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %17, i32 %4, i64 %16)    ; IR: un-copy %11 (its last reader is %12's load and that load's _unc; no memory version change since the load)
  call void @cqrt_free(i32 %17)    ; IR: release the %11 rail (|0>)
  %20 = call i32 @cqrt_measure_i32(i32 %19)    ; IR: %14 = cq_measure_si32(%13)
  ret i32 %20    ; IR: ret i32 %14  (llvm.lifetime.end dropped)
}

define internal fastcc void @bump(ptr noundef %0) {
  %2 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %3 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address (mask digit 0: the formal is the C ptr)
  %4 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: %2 = load i64, ptr %0 ... store i64 %3, ptr %0: the in-place form (rules 5, 6), a fresh |0> rail
  call void @cqrt_qram_swap_i64_hl(i32 %2, i64 %3, i32 %4)    ; IR: %2 = load i64, ptr %0: swap out: the rail holds u->v (the stored pointer read as an integer), the cells |0>
  %5 = call i32 @cq_template_add_i64_hl(i32 %4, i64 4)    ; IR: %3 = add i64 %2, 4
  %6 = call i32 @cq_template_sub_i64_hl(i32 %5, i64 4)    ; IR: rule 6: t = y' - 4 recomputes the old value (the update is a bijection in it)
  call void @cqrt_copy_i64(i32 %6, i32 %4)    ; IR: rule 6: the old rail ^= t: now |0>
  call void @cq_template_sub_i64_hl_unc(i32 %6, i32 %5, i64 4)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %6)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the old rail (|0> after the copy)
  call void @cqrt_qram_swap_i64_hl(i32 %2, i64 %3, i32 %5)    ; IR: store i64 %3, ptr %0: swap in: the cells hold u->v + 4, the rail |0>
  call void @cqrt_free(i32 %5)    ; IR: release the %3 rail (|0>)
  ret void    ; IR: ret void
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_copy_i64(i32, i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare void @cqrt_qram_swap_i64_hl(i32, i64, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_or_i64_hl(i32, i64)
declare void @cq_template_or_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare i32 @cq_template_sub_i64_hl(i32, i64)
declare void @cq_template_sub_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
