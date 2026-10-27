; HAND-WRITTEN. Rules: 2, 4, 5, 6, 7, 9, 18, 20, 21, §1.4.
; Checked: ptr_select_rmw's a and b after the two increments, a + 2*[x > k] and b + 2*[x <= k] (the cells %29 and %30,
; measured and summed); guarded_field_store's s[0].f + s[1].f + s[i].g (the result rail %32 -> %33, measured).
; Clean: ptr_select_rmw's flag x > k (%14), the tag (%15), the two object flags (%16, %21), the load (%19), the sum
; (%20), the OLD registers a (%12) and b (%13) and the first-increment cells (%22, %23), each cleaned by rule 6 in the
; caller (inverses %24..%27 before the call, %31..%34 after it), and the clone's own rails; guarded_field_store's
; predicate B (%17), the hoisted arm chain (%18..%20), the in-arm select (%21), the stored cell (%25), the post-merge add
; (%28) and the two f seed rails (%11, %15, never written, rule 7), all freed.
; Kept: ptr_select_rmw's x (%11, the rotated register) and the final a and b cells (%29, %30: the clone's stores,
; measured); guarded_field_store's x (%9), y (%10) and the measured result rail %32.
; Rotations: (Ry, x, th, 1); (Ry, a, ta, 1); (Ry, b, tb, 1) in ptr_select_rmw; (Ry, x, th, 1); (Ry, y, ty, 1) in
; guarded_field_store.
; ptr_select_rmw: -O1 keeps a and b in memory because the select of their addresses escapes into bump. The two allocas
; are SLOTS (31): each holds the HANDLE of its register. The selected pointer is a fat pointer (84): tag rail =
; select(x > k, 1, 2) over the object table a = 1, b = 2, idx the classical cell 0 (one cell per object). The load
; through it is a select over the reachable cells on the flag tag == 1 (77's read over quantum cells); the store gives
; each reachable cell a new rail w_o = (tag == o) ? sum : cell_o and writes that handle into o's slot. The update is a
; BIJECTION of each old cell for the given tag (w_o = cell_o + [tag == o]) and the old cells are dead once the load and
; the sum (their only other readers) are uncomputed, so rule 6 cleans them: t_o = (tag == o) ? w_o - 1 : w_o is computed
; fresh, copy_i32(t_o, cell_o) zeroes the old rail, t_o is uncomputed and the old rail freed. The registers a and b are
; thereby MOVED into the new cells: nothing stays beside them. A QUANTUM POINTER ARGUMENT crosses the clone boundary as
; the rule-21 triple (object, tag, idx): the object part of a fat pointer over several objects is the caller's OBJECT
; TABLE (%10: the host address of each object in its provenance, in tag order, filled by the caller), the tag its rail,
; idx the i32 cell index. The mask is per §1.4 over the triple: the table gets no digit, tag 1, idx 0, then one digit
; per pointee cell the callee accesses (a's and b's cells, both holding handles at the call): __cq_q_bump_1011. The clone
; repeats the read-add-write on the slots at cell idx of each object and returns with the slots holding the new cells.
; It does NOT clean the cells it overwrote: a clone is shared by every call site with its mask and only the caller knows
; whether the old handles are dead (rule 18). Here they are (nothing else reads %22, %23 after the call), so the CALLER
; cleans them by rule 6 after the call, with the same inverse t_o = (tag == o) ? w_o - 1 : w_o. Nothing is left for an
; _unc twin to undo, and none is defined (§1.4: a twin nobody calls is not defined). The flags and the tag are then
; uncomputed and the final cells measured in place.
; guarded_field_store: a classical index i keeps s in memory, the store s[i].f = ... sits in an arm under the quantum
; predicate B = x > k, and the stored value is an IN-ARM SELECT. The object table gives s one cell kind per field column:
; the store's gep reaches only the f cells (offsets 0 and 8, stride 8), so those hold handles from the start (fresh
; rails holding c and c + 1), the g cells stay classical. The arm's chain (%17..%20) is hoisted and runs unguarded
; (pure); the guarded store is w = B ? %20 : old with old the handle in cell s[i].f, resolved at run time by the
; classical gep. After the merge the loads read whatever handle each f cell holds. Before the measurement the post-merge
; add, the stored w (the slot gets old back), the in-arm select AND its operand chain %19, %18, %17, then B are
; uncomputed. The f seed rails were never written and hold the classical c, c + 1; they are released like 28's seed rail
; (rule 7).
source_filename = "quantum_ptr_select_store.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.pair = type { i32, i32 }

define i32 @ptr_select_rmw(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, double noundef %6) {
  %8 = alloca i32, align 4    ; IR: %8 = alloca i32  (object 1: a, a slot holding a's handle)
  %9 = alloca i32, align 4    ; IR: %9 = alloca i32  (object 2: b, a slot holding b's handle)
  %10 = alloca [2 x ptr], align 8    ; IR: the object table of %14's provenance {a, b}: host address per tag, classical (the object part of the rule-21 triple)
  %11 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %10 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %11, double %1)    ; IR: %10 = cq_theta_si32(%0, %1)  [Ry]
  %12 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: store i32 %3, ptr %8; %11 = cq_theta_si32(%3, %4)  [register a]
  call void @cqrt_ry_i32(i32 %12, double %4)    ; IR: %11 = cq_theta_si32(%3, %4)  [Ry]
  store i32 %12, ptr %8, align 4    ; IR: store i32 %11, ptr %8  (the handle into slot a)
  %13 = call i32 @cqrt_alloc_i32(i32 %5)    ; IR: store i32 %5, ptr %9; %12 = cq_theta_si32(%5, %6)  [register b]
  call void @cqrt_ry_i32(i32 %13, double %6)    ; IR: %12 = cq_theta_si32(%5, %6)  [Ry]
  store i32 %13, ptr %9, align 4    ; IR: store i32 %12, ptr %9  (the handle into slot b)
  %14 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %11, i32 %2)    ; IR: %13 = icmp sgt i32 %10, %2
  %15 = call i32 @cq_template_select_i32_ll(i32 %14, i32 1, i32 2)    ; IR: %14 = select i1 %13, ptr %8, ptr %9  [the pointer's tag: a (1) or b (2); its idx is the classical cell 0]
  %16 = call i32 @cq_template_icmp_eq_i32_hl(i32 %15, i32 1)    ; IR: %15 = load i32, ptr %14: object a addressed iff tag == 1, else b
  %17 = load i32, ptr %8, align 4    ; IR: %15: the handle in slot a (no gate)
  %18 = load i32, ptr %9, align 4    ; IR: %15: the handle in slot b (no gate)
  %19 = call i32 @cq_template_select_i32(i32 %16, i32 %17, i32 %18)    ; IR: %15 = load i32, ptr %14  [the read over both quantum cells]
  %20 = call i32 @cq_template_add_i32_hl(i32 %19, i32 1)    ; IR: %16 = add nsw i32 %15, 1
  %21 = call i32 @cq_template_icmp_eq_i32_hl(i32 %15, i32 2)    ; IR: store i32 %16, ptr %14: object b addressed iff tag == 2
  %22 = call i32 @cq_template_select_i32(i32 %16, i32 %20, i32 %17)    ; IR: store: a = (tag == 1) ? %16 : a
  %23 = call i32 @cq_template_select_i32(i32 %21, i32 %20, i32 %18)    ; IR: store: b = (tag == 2) ? %16 : b
  store i32 %22, ptr %8, align 4    ; IR: store i32 %16, ptr %14  (slot a holds the new cell)
  store i32 %23, ptr %9, align 4    ; IR: store i32 %16, ptr %14  (slot b holds the new cell)
  call void @cq_template_add_i32_hl_unc(i32 %20, i32 %19, i32 1)    ; IR: uncompute %16 (the new cells keep its value)
  call void @cqrt_free(i32 %20)    ; IR: release the %16 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %19, i32 %16, i32 %17, i32 %18)    ; IR: uncompute the load %15 (the old cells' last reader)
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  %24 = call i32 @cq_template_add_i32_hl(i32 %22, i32 -1)    ; IR: rule 6 on the old a: new a - 1
  %25 = call i32 @cq_template_select_i32(i32 %16, i32 %24, i32 %22)    ; IR: rule 6: t = (tag == 1) ? new a - 1 : new a, the old a recomputed fresh
  call void @cqrt_copy_i32(i32 %25, i32 %17)    ; IR: rule 6: the old a rail ^= t: |0>
  call void @cq_template_select_i32_unc(i32 %25, i32 %16, i32 %24, i32 %22)    ; IR: uncompute t
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %24, i32 %22, i32 -1)    ; IR: uncompute new a - 1
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %17)    ; IR: release the old a rail (|0>)
  %26 = call i32 @cq_template_add_i32_hl(i32 %23, i32 -1)    ; IR: rule 6 on the old b: new b - 1
  %27 = call i32 @cq_template_select_i32(i32 %21, i32 %26, i32 %23)    ; IR: rule 6: t = (tag == 2) ? new b - 1 : new b, the old b recomputed fresh
  call void @cqrt_copy_i32(i32 %27, i32 %18)    ; IR: rule 6: the old b rail ^= t: |0>
  call void @cq_template_select_i32_unc(i32 %27, i32 %21, i32 %26, i32 %23)    ; IR: uncompute t
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %26, i32 %23, i32 -1)    ; IR: uncompute new b - 1
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %18)    ; IR: release the old b rail (|0>)
  store ptr %8, ptr %10, align 8    ; IR: table[1] = &a  (classical)
  %28 = getelementptr inbounds i8, ptr %10, i64 8    ; IR: table[2]
  store ptr %9, ptr %28, align 8    ; IR: table[2] = &b  (classical)
  call fastcc void @__cq_q_bump_1011(ptr %10, i32 %15, i32 0)    ; IR: call fastcc void @bump(ptr %14): clone, %14 as the rule-21 triple (object table, tag, cell idx 0); mask 1011: tag quantum, idx classical, the two accessed pointee cells (a, b) hold handles
  %29 = load i32, ptr %8, align 4    ; IR: %17 = load i32, ptr %8  (the handle the clone stored: a)
  %30 = load i32, ptr %9, align 4    ; IR: %19 = load i32, ptr %9  (the handle the clone stored: b)
  %31 = call i32 @cq_template_add_i32_hl(i32 %29, i32 -1)    ; IR: rule 6 in the CALLER on the first-increment a cell %22 (dead after the call): new a - 1
  %32 = call i32 @cq_template_select_i32(i32 %16, i32 %31, i32 %29)    ; IR: rule 6: t = (tag == 1) ? new a - 1 : new a, the old cell recomputed fresh
  call void @cqrt_copy_i32(i32 %32, i32 %22)    ; IR: rule 6: the old a cell ^= t: |0>
  call void @cq_template_select_i32_unc(i32 %32, i32 %16, i32 %31, i32 %29)    ; IR: uncompute t
  call void @cqrt_free(i32 %32)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %31, i32 %29, i32 -1)    ; IR: uncompute new a - 1
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %22)    ; IR: release the first-increment a cell (|0>)
  %33 = call i32 @cq_template_add_i32_hl(i32 %30, i32 -1)    ; IR: rule 6 in the caller on the first-increment b cell %23: new b - 1
  %34 = call i32 @cq_template_select_i32(i32 %21, i32 %33, i32 %30)    ; IR: rule 6: t = (tag == 2) ? new b - 1 : new b
  call void @cqrt_copy_i32(i32 %34, i32 %23)    ; IR: rule 6: the old b cell ^= t: |0>
  call void @cq_template_select_i32_unc(i32 %34, i32 %21, i32 %33, i32 %30)    ; IR: uncompute t
  call void @cqrt_free(i32 %34)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %33, i32 %30, i32 -1)    ; IR: uncompute new b - 1
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %23)    ; IR: release the first-increment b cell (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %21, i32 %15, i32 2)    ; IR: uncompute the b flag
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %16, i32 %15, i32 1)    ; IR: uncompute the a flag
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %15, i32 %14, i32 1, i32 2)    ; IR: uncompute the tag
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %14, i32 %11, i32 %2)    ; IR: uncompute %13
  call void @cqrt_free(i32 %14)    ; IR: release the %13 rail (|0>)
  %35 = call i32 @cqrt_measure_i32(i32 %29)    ; IR: %18 = cq_measure_si32(%17)
  %36 = call i32 @cqrt_measure_i32(i32 %30)    ; IR: %20 = cq_measure_si32(%19)
  %37 = add nsw i32 %36, %35    ; IR: %21 = add nsw i32 %20, %18  (classical)
  ret i32 %37    ; IR: ret i32 %21
}

define internal fastcc void @__cq_q_bump_1011(ptr %0, i32 %1, i32 %2) {
  %4 = load ptr, ptr %0, align 8    ; IR: %0: object 1 (a's slot) from the table
  %5 = getelementptr inbounds i8, ptr %0, i64 8    ; IR: table[2]
  %6 = load ptr, ptr %5, align 8    ; IR: %0: object 2 (b's slot)
  %7 = getelementptr inbounds i32, ptr %4, i32 %2    ; IR: %0 in a: cell idx (classical)
  %8 = getelementptr inbounds i32, ptr %6, i32 %2    ; IR: %0 in b: cell idx
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 1)    ; IR: %2 = load i32, ptr %0: object a iff tag == 1, else b
  %10 = load i32, ptr %7, align 4    ; IR: %2: the handle in a's cell
  %11 = load i32, ptr %8, align 4    ; IR: %2: the handle in b's cell
  %12 = call i32 @cq_template_select_i32(i32 %9, i32 %10, i32 %11)    ; IR: %2 = load i32, ptr %0
  %13 = call i32 @cq_template_add_i32_hl(i32 %12, i32 1)    ; IR: %3 = add nsw i32 %2, 1
  %14 = call i32 @cq_template_icmp_eq_i32_hl(i32 %1, i32 2)    ; IR: store i32 %3, ptr %0: object b iff tag == 2
  %15 = call i32 @cq_template_select_i32(i32 %9, i32 %13, i32 %10)    ; IR: store: a = (tag == 1) ? %3 : a
  %16 = call i32 @cq_template_select_i32(i32 %14, i32 %13, i32 %11)    ; IR: store: b = (tag == 2) ? %3 : b
  store i32 %15, ptr %7, align 4    ; IR: store i32 %3, ptr %0  (a's cell)
  store i32 %16, ptr %8, align 4    ; IR: store i32 %3, ptr %0  (b's cell)
  call void @cq_template_add_i32_hl_unc(i32 %13, i32 %12, i32 1)    ; IR: uncompute %3 (the new cells keep its value)
  call void @cqrt_free(i32 %13)    ; IR: release the %3 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %12, i32 %9, i32 %10, i32 %11)    ; IR: uncompute %2
  call void @cqrt_free(i32 %12)    ; IR: release the %2 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %14, i32 %1, i32 2)    ; IR: uncompute the b flag
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %1, i32 1)    ; IR: uncompute the a flag
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  ret void    ; IR: ret void  (the slots hold the new cells; the old cells stay the caller's, which cleans them by rule 6)
}

define i32 @guarded_field_store(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, i32 noundef %6) {
  %8 = alloca [2 x %struct.pair], align 16    ; IR: %8 = alloca [2 x %struct.pair]  (object 1: s; f cells hold handles, g cells classical)
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %9 = cq_theta_si32(%0, %1)  [Ry]
  %10 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %10 = cq_theta_si32(%3, %4)  [register y]
  call void @cqrt_ry_i32(i32 %10, double %4)    ; IR: %10 = cq_theta_si32(%3, %4)  [Ry]
  %11 = call i32 @cqrt_alloc_i32(i32 %5)    ; IR: store i32 %5, ptr %8  [s[0].f: a quantum store reaches it, so it is a rail holding c]
  store i32 %11, ptr %8, align 16    ; IR: store i32 %5, ptr %8  (the handle into cell s[0].f)
  %12 = getelementptr inbounds i8, ptr %8, i64 4    ; IR: %11
  store i32 7, ptr %12, align 4    ; IR: store i32 7, ptr %11  (classical: s[0].g)
  %13 = getelementptr inbounds i8, ptr %8, i64 8    ; IR: %12
  %14 = add nsw i32 %5, 1    ; IR: %13 = add nsw i32 %5, 1  (classical)
  %15 = call i32 @cqrt_alloc_i32(i32 %14)    ; IR: store i32 %13, ptr %12  [s[1].f: a rail holding c + 1]
  store i32 %15, ptr %13, align 8    ; IR: store i32 %13, ptr %12  (the handle into cell s[1].f)
  %16 = getelementptr inbounds i8, ptr %8, i64 12    ; IR: %14
  store i32 8, ptr %16, align 4    ; IR: store i32 8, ptr %14  (classical: s[1].g)
  %17 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %9, i32 %2)    ; IR: %15 = icmp sgt i32 %9, %2  [predicate B of block %16]
  %18 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %10, i32 %5)    ; IR: %17 = icmp sgt i32 %10, %5  (block %16, hoisted: pure)
  %19 = call i32 @cq_template_mul_i32_hl(i32 %10, i32 3)    ; IR: %18 = mul nsw i32 %10, 3  (hoisted)
  %20 = call i32 @cq_template_sub_i32_hl(i32 %10, i32 %5)    ; IR: %19 = sub nsw i32 %10, %5  (hoisted)
  %21 = call i32 @cq_template_select_i32(i32 %18, i32 %19, i32 %20)    ; IR: %20 = select i1 %17, i32 %18, i32 %19  [the in-arm select]
  %22 = sext i32 %6 to i64    ; IR: %21 = sext i32 %6 to i64  (classical)
  %23 = getelementptr inbounds [2 x %struct.pair], ptr %8, i64 0, i64 %22    ; IR: %22  (classical address of s[i].f)
  %24 = load i32, ptr %23, align 8    ; IR: store i32 %20, ptr %22: the handle the cell held before
  %25 = call i32 @cq_template_select_i32(i32 %17, i32 %21, i32 %24)    ; IR: store i32 %20, ptr %22 under B: s[i].f = B ? %20 : s[i].f
  store i32 %25, ptr %23, align 8    ; IR: store i32 %20, ptr %22  (the cell holds the new rail)
  %26 = load i32, ptr %8, align 16    ; IR: %24 = load i32, ptr %8  (handle of s[0].f)
  %27 = load i32, ptr %13, align 8    ; IR: %25 = load i32, ptr %12  (handle of s[1].f)
  %28 = call i32 @cq_template_add_i32(i32 %27, i32 %26)    ; IR: %26 = add nsw i32 %25, %24
  %29 = sext i32 %6 to i64    ; IR: %27  (classical)
  %30 = getelementptr inbounds [2 x %struct.pair], ptr %8, i64 0, i64 %29, i32 1    ; IR: %28  (classical address of s[i].g)
  %31 = load i32, ptr %30, align 4    ; IR: %29 = load i32, ptr %28  (classical: a g cell)
  %32 = call i32 @cq_template_add_i32_hl(i32 %28, i32 %31)    ; IR: %30 = add nsw i32 %26, %29  [result rail]
  call void @cq_template_add_i32_unc(i32 %28, i32 %27, i32 %26)    ; IR: uncompute %26
  call void @cqrt_free(i32 %28)    ; IR: release the %26 rail (|0>)
  call void @cq_template_select_i32_unc(i32 %25, i32 %17, i32 %21, i32 %24)    ; IR: uncompute the stored cell
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  store i32 %24, ptr %23, align 8    ; IR: adjoint of the store: the cell holds its old handle
  call void @cq_template_select_i32_unc(i32 %21, i32 %18, i32 %19, i32 %20)    ; IR: uncompute the in-arm select %20
  call void @cqrt_free(i32 %21)    ; IR: release the %20 rail (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %20, i32 %10, i32 %5)    ; IR: uncompute %19
  call void @cqrt_free(i32 %20)    ; IR: release the %19 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %19, i32 %10, i32 3)    ; IR: uncompute %18
  call void @cqrt_free(i32 %19)    ; IR: release the %18 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %18, i32 %10, i32 %5)    ; IR: uncompute %17
  call void @cqrt_free(i32 %18)    ; IR: release the %17 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %17, i32 %9, i32 %2)    ; IR: uncompute %15
  call void @cqrt_free(i32 %17)    ; IR: release the %15 rail (|0>)
  call void @cqrt_free(i32 %15)    ; IR: release s[1].f's seed rail (never written, holds the classical c + 1)
  call void @cqrt_free(i32 %11)    ; IR: release s[0].f's seed rail (never written, holds the classical c)
  %33 = call i32 @cqrt_measure_i32(i32 %32)    ; IR: %31 = cq_measure_si32(%30)
  ret i32 %33    ; IR: ret i32 %31
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
