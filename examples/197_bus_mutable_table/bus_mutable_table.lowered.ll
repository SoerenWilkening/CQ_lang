; HAND-WRITTEN. Rules: 20 (witness: an address-rail load of a constant global and of a mutable global are the same bus
; load), 19 (witness: an all-classical function is lowered under its own symbol), 5, 7, 2, 3, 4, 21; §1.3 (the overlay).
; Checked: tab_set: the cell tab[i & 3] = v, read from the bus at exit at &tab + 4 (i & 3) (HOST cells: the host
; bytes). bus_mutable_table: v = ROM[k & 3] + tab[k & 3] (measured, the add rail %13 -> %14).
; Clean: tab_set: nothing to clean. bus_mutable_table: the index rail k & 3 (%5), its zext (%6), the two scaled indices
; (%7, %10), the two address rails (%8, %11) and the two load copies (%9, %12), all uncomputed and freed before the
; measurement.
; Kept: tab_set: the store's tape slot (it holds the displaced tab[i & 3]) and its value rail, the seed %8 = |v>
; (rule 5 sentence 3, rule 7). bus_mutable_table: k (%4, the rotated register) and the sum (%13, measured).
; Rotations: tab_set: none. bus_mutable_table: (Ry, k, tk, 1).
; Expected for the driver tab_set(1, 9); bus_mutable_table(1, .5): tab = {2, 9, 1, 8} when the second call runs, so the
; sum is 5, 10, 5, 9 at k & 3 = 0, 1, 2, 3. Ry(.5) acts on every qubit of k = 1: with c = cos^2(.25) = 0.938791 and
; s = sin^2(.25) = 0.061209, bit 0 reads 1 with probability c and bit 1 reads 1 with probability s, so k & 3 = 0, 1, 2,
; 3 has probability sc, cc, ss, cs and the measured value is 10 with p = c^2 = 0.881329, 5 with p = s = 0.061209 and
; 9 with p = cs = 0.057462. Without the tab_set call the 10 would read 8: the load sees the byte the store wrote.
; ONE BUS (rule 20): nothing is known about an address, so @ROM (isConstant) and @tab (mutable) are not told apart at
; an address rail. Both globals stay ordinary LLVM globals at their host addresses; nothing is allocated, seeded or
; registered for them, and their cells are HOST: each load reads the host bytes at the access (§1.3). A constant
; global is host-resident only through getelementptrs with UNTAINTED indices; here the index is the rail k & 3, so the
; ROM read is the bus load like the tab read. No QROM exists.
; ADDRESS ARITHMETIC (rule 20): each getelementptr with a tainted index is emitted: the i64 index rail (-O1's zext,
; one rail for both geps, as it is one SSA value) scaled by mul_i64_hl(., 4) and added to the classical base's
; run-time address by add_i64_hl(., ptrtoint @G). The two address rails are rule-5 garbage that outlive their loads'
; _unc.
; UNCOMPUTE (rule 5 sentence 1): no memory version change follows the loads in this function, and their only
; consumer, the add, is measured and never uncomputed, so both copies are un-copied right after the add (the cells
; still hold what the loads read) and freed; then the address chains, the ROM chain last in first out after the tab
; chain, the shared zext and the and.
; tab_set (rule 19, §1.4): the all-zero mask is the function's OWN symbol with its C parameter list, and its body is
; lowered although nothing in it is quantum: @tab is not host-resident (not isConstant), so the store is a bus store
; (rule 20). The getelementptr has nothing tainted and stays; the address is its run-time i64 and the value is the seed
; alloc_i32(v) (rule 7). Address, value and (absent) control are classical-valued, so the backend writes the four host
; bytes and the cells stay HOST (§1.3): host code and the later bus load both see v. The store is a kept store.
; SPEC GAP: rule 19 / §1.3 ask for a __cq_clone_register row (the _t clone, _t_ctl and their twins) per externally
; visible function. No conforming example of the corpus emits one; this module follows the corpus and registers
; nothing for tab_set and bus_mutable_table: no table clone, no constructor. Neither function's address is taken.
; SPEC GAP: rule 5 sentence 1 asks for the uncompute of the load's last consumer. Here the consumer (the add) is the
; measured rail, which has none; read as satisfied (as 204 reads it): the copy is un-copied after its last reader,
; before the next memory version change.
; SPEC GAP: rule 20 does not say whether two getelementptrs on one index rail share the scaled index. Emission is per
; getelementptr instruction: each emits its own mul_i64_hl and add_i64_hl; only what is one SSA value at -O1 (the
; zext) is one rail.
; SPEC GAP: rule 20 gives no spelling for a classical address. It is ptrtoint of the pointer: the instruction for an
; instruction-valued pointer (tab_set's %7), the constant expression ptrtoint (ptr @G to i64) for a global, also as
; an _hl literal (as 195, 196).
source_filename = "bus_mutable_table.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tab = local_unnamed_addr global [4 x i32] [i32 2, i32 7, i32 1, i32 8], align 16
@ROM = internal unnamed_addr constant [4 x i32] [i32 3, i32 1, i32 4, i32 1], align 16

define void @tab_set(i32 noundef %0, i32 noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: (none)  [m: the one bus, fetched once at function entry]
  %4 = and i32 %0, 3    ; IR: %3 = and i32 %0, 3  [classical, unchanged]
  %5 = zext nneg i32 %4 to i64    ; IR: %4 = zext nneg i32 %3 to i64  [classical, unchanged]
  %6 = getelementptr inbounds [4 x i32], ptr @tab, i64 0, i64 %5    ; IR: %5 = getelementptr @tab, 0, %4  [nothing tainted: the gep stays]
  %7 = ptrtoint ptr %6 to i64    ; IR: store i32 %1, ptr %5  [the classical address as its run-time i64]
  %8 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: store i32 %1, ptr %5  [the value is always a handle: the seed |v>, kept with the store]
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %7, i32 %8)    ; IR: store i32 %1, ptr %5  [bus store at a classical address; all classical-valued: the host bytes are written, the cells stay HOST; kept, no _unc]
  ret void    ; IR: ret void
}

define i32 @bus_mutable_table(i32 noundef %0, double noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: (none)  [m: the one bus, fetched once at function entry]
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %3 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)    ; IR: %4 = and i32 %3, 3
  %6 = call i32 @cq_template_zext_i32_to_i64(i32 %5)    ; IR: %5 = zext nneg i32 %4 to i64  [the index rail, shared by both geps]
  %7 = call i32 @cq_template_mul_i64_hl(i32 %6, i64 4)    ; IR: %6 = getelementptr @ROM, 0, %5  [index scaled by sizeof(i32)]
  %8 = call i32 @cq_template_add_i64_hl(i32 %7, i64 ptrtoint (ptr @ROM to i64))    ; IR: %6 = getelementptr @ROM, 0, %5  [address rail: &ROM + 4 (k & 3)]
  %9 = call i32 @cqrt_qram_load_i32(i32 %3, i32 %8)    ; IR: %7 = load i32, ptr %6  [bus load at an address rail; HOST cells of a constant global]
  %10 = call i32 @cq_template_mul_i64_hl(i32 %6, i64 4)    ; IR: %8 = getelementptr @tab, 0, %5  [index scaled by sizeof(i32)]
  %11 = call i32 @cq_template_add_i64_hl(i32 %10, i64 ptrtoint (ptr @tab to i64))    ; IR: %8 = getelementptr @tab, 0, %5  [address rail: &tab + 4 (k & 3)]
  %12 = call i32 @cqrt_qram_load_i32(i32 %3, i32 %11)    ; IR: %9 = load i32, ptr %8  [the same bus load; HOST cells of a mutable global]
  %13 = call i32 @cq_template_add_i32(i32 %12, i32 %9)    ; IR: %10 = add nsw i32 %9, %7
  call void @cqrt_qram_load_i32_unc(i32 %12, i32 %3, i32 %11)    ; IR: un-copy %9 (no memory version change since the load)
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %11, i32 %10, i64 ptrtoint (ptr @tab to i64))    ; IR: uncompute the address rail of %8
  call void @cqrt_free(i32 %11)    ; IR: release the %8 address rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %10, i32 %6, i64 4)    ; IR: uncompute the scaled index of %8
  call void @cqrt_free(i32 %10)    ; IR: release the scaled index (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %9, i32 %3, i32 %8)    ; IR: un-copy %7 (no memory version change since the load)
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %8, i32 %7, i64 ptrtoint (ptr @ROM to i64))    ; IR: uncompute the address rail of %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 address rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %7, i32 %6, i64 4)    ; IR: uncompute the scaled index of %6
  call void @cqrt_free(i32 %7)    ; IR: release the scaled index (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %6, i32 %5)    ; IR: uncompute %5
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 3)    ; IR: uncompute %4
  call void @cqrt_free(i32 %5)    ; IR: release the %4 rail (|0>)
  %14 = call i32 @cqrt_measure_i32(i32 %13)    ; IR: %11 = cq_measure_si32(%10)
  ret i32 %14    ; IR: ret i32 %11
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32(i32, i32)
