; HAND-WRITTEN. Rules: 20, 16, 14, 18, 5, 6, 7, 9, 21, 3, 8, 19, 4, 2.
; Checked: bus_scope_reuse: s = sum over i < n of a[0] + a[1] after trip i's stores (the carried rail, measured). With
; b_i = (k >> i) & 1: a[0] = b_i ? i : x, and a[1] = x when b_j = 1 for some j <= i, else 0 (never written: the zeroed
; block). bus_recursion: walk(k, x, d) = sum over levels j = d..0 of ((k >> (d - j)) & 1) ? j : x (the outermost
; clone's result rail, measured). The cells of the blocks are not named outputs.
; Clean: bus_scope_reuse, per trip: the address chain lshr / and / zext / mul / add (uncomputed and freed right after
; the store), the load copies of a[0] and a[1] (un-copied and freed in the trip: no memory version change lies between
; a load and its _unc), the old s, the intermediate image s + a[0] and the two rule-6 rails t (rule 6 in the body, as
; 27; trip 0's old s is the |0> seed). __cq_q_walk_110, per activation: the address chain and / zext / mul / add, the
; argument rail k >> 1 (after the call) and the load copy of a[0] (un-copied before the return). The inner
; activation's result below (on the d == 0 path the |0> seed that stands for it) is not freed: a[0] + below is rule 6's
; in-place update on its rail, which is returned.
; Kept: bus_scope_reuse: k and x (rotated; x is also the value rail of every trip's address-rail store, rule 5); per
; trip the seed i (value rail of the classical-address store, rule 5: a basis state, no qubit) and the two tape slots
; (backend rails, rule 5); s (measured: the last trip's image, or the seed itself when n <= 0).
; bus_recursion: k and x (rotated; x is the value rail of every activation's address-rail store); per activation the
; two seeds d and 0 and the three tape slots (rule 5); the outermost result (measured). No result rail of an inner
; activation stays apart: each is updated in place by its caller into the caller's own result (rule 6).
; Rotations: bus_scope_reuse: (Ry, k, tk, 1); (Ry, x, tx, 1). bus_recursion: (Ry, k, tk, 1); (Ry, x, tx, 1).
; Expected: each Ry acts on all 32 qubits of its register and everything after the rotations is a basis permutation,
; so the measured value is the C program on independent bit flips: a bit of k flips with p = sin^2(.25) = 0.061209,
; a bit of x with q = sin^2(.125) = 0.015544 (x = 9 ^ e with q^|e| (1 - q)^(32 - |e|); x = 9: 0.605738).
; bus_scope_reuse(1, .5, 9, .25, 2): trip 0 adds x on either branch of b_0 (x lands in a[0] or in a[1], the other cell
; is 0). Trip 1 adds 1 + x when b_1 = 1 and x + a[1] when b_1 = 0, where a[1] is what trip 0 left: x when b_0 = 1, else
; 0. Bits (b_0, b_1) = (1, 0), (1, 1), (0, 0), (0, 1) with 0.881329, 0.057462, 0.057462, 0.003747 give s = 3x, 2x + 1,
; 2x, 2x + 1 (at x = 9: 27, 19, 18, 19).
; bus_recursion(1, .5, 9, .25, 2): bits (k0, k1, k2) of k; the levels d = 2, 1, 0 read a[0] = k0 ? 2 : x, k1 ? 1 : x,
; k2 ? 0 : x. (1,0,0): 2x + 2 with 0.827379 (x = 9: 20); (1,0,1): x + 2, (1,1,0): x + 3, (0,0,0): 3x with 0.053945
; each; (1,1,1): 3, (0,0,1): 2x, (0,1,0): 2x + 1 with 0.003517 each; (0,1,1): x + 1 with 0.000229.
; LIFETIME MARKERS ARE DROPPED (rules 16, 20). bus_scope_reuse: a[] is declared in the loop body, but -O1 has ONE
; alloca outside the loop with llvm.lifetime.start/end inside it. A getelementptr with a tainted index is among its
; users, so the alloca is BUS-RESIDENT: it is ONE __cq_alloc(8, 4) block at the alloca's program point, no alloca
; remains, and the markers emit nothing. The cells therefore carry over from trip to trip: nothing is undone at the
; end of a trip. Trip i's store a[0] = i is an ordinary kept store whose tape slot takes whatever trip i - 1 left in
; a[0] (x on one branch of k); its address and value are classical-valued, but the cell may be QUANTUM from the trip
; before: nothing is asked, it is the same qram_store_i32_hl of a seed. a[1] is written by no initializer, so its load
; reads what the block holds.
; THE CARRY-OVER IS A NAMED-OUTPUT DIFFERENCE: on the branch (b_0, b_1) = (1, 0), the dominant one of the driver call,
; trip 1 reads in a[1] the x that trip 0 stored there and s = 3x. A compiler that allocates a fresh zeroed block per
; trip (or zeroes the block at a lifetime marker) gives 2x there. C calls that read indeterminate; the reference takes
; the value the cell holds on the bus (SPEC GAP below).
; THE LOOP (rule 14, classical bound): it stays the classical loop. Every trip rail is either kept by rule 5 or
; uncomputed in the trip, so nothing is pushed and there is no reverse loop: the address chain goes right after its
; store; s1 = a[0] + s is a bijection in s and s' = s1 + a[1] one in s1, the other operand of each is a load copy, so
; rule 6 cleans the old s and then s1 in the body (as 27), each right after its update, and each copy is un-copied
; after the clean-up that reads it, before the next memory version change, which is the next trip's first store. The
; carried s is measured directly.
; THE RECURSION (rules 14, 18): the depth d is classical, so the recursive call is an ordinary call of the ONE clone
; __cq_q_walk_110 (mask left to right: k, x quantum, d classical) under the classical branch d != 0; no predicate, no
; _ctl clone, hence no activation counter (§1.4) and no cutoff. Every activation runs __cq_alloc(8, 4) once: its own
; zeroed block at an address never reused, so the inner activation's stores cannot reach the cells the outer one
; loads after the call. The clone writes memory, so it has NO twin and no caller calls one. Its result a[0] + below is
; a rule-6 bijection in below whose other operand is the load copy: below (the inner activation's result, dead after
; the add) is updated in place, add_i32(copy, below), and that rail, the rule-6 image, is returned directly with no
; copy-out (a copy could not be followed by the image's uncompute, which would read the old below). The phi of the call's result against
; the literal 0 is a classical phi over handles (rule 9), the 0 a seed (rule 7) minted on its edge and updated in place
; by the same gate as the call path's below. The unlifted walk has no caller
; left and is dropped (§1.4).
; SPEC GAP: rule 6 names no exception for a call result, rule 18 says the result of a callee without a twin is KEPT
; by the caller and gives the clone the copy-out form. Read here: KEPT only means that no twin is called, so rule 6
; updates below in place like any other rail; a clone whose result is a rule-6 image returns the image rail directly;
; a seed that is a classical phi incoming of the updated value is updated by the same gate, not under a second
; classical branch.
; SPEC GAP: §6 says an indeterminate value the C program reads is 0 for the reference. By rule 20 a block-scoped
; bus-resident object is one block whose cells carry over, so from trip 1 on a[1] holds what the trip before left
; (x). Read here: the reference takes what the cell holds on the bus, 0 only for a cell never written.
; SPEC GAP: rule 5 sentence 1 asks for the uncompute of the load's last consumer. In both functions the consumer (an
; add) is a rule-6 image (the carried s, the clone's result), which has none; read as for a template operand (27's
; g): the copy is un-copied after its last reader (rule 6's t; in the clone the in-place add), before the next memory
; version change.
; SPEC GAP: rule 6 "both operands dead" does not say that a bus load copy is "garbage that rule 5 uncomputes anyway".
; It is read so (the copy's un-copy is possible here), so rule 6 applies to the other operand (the old s, below)
; although the copy is operand 0.
; SPEC GAP: rule 9 says a classical phi over handles needs no gate; where its literal incoming is minted is not
; stated. The seed is minted in a block on its edge (in the pred it would stay allocated on the call path).
; SPEC GAP: rule 19 / §1.3 ask for a __cq_clone_register row (the _t clone, _t_ctl and their twins) per externally
; visible function. The corpus emits a row only for an address-taken function (212); no example registers a function
; that is only externally visible, and this module follows that: nothing is registered for bus_scope_reuse and
; bus_recursion.
; SPEC GAP: CR fixes no calling convention or linkage for a clone called by name; the clone keeps the callee's
; (internal fastcc), as the corpus does (07, 33).
source_filename = "bus_lifetime_reuse.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @bus_scope_reuse(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %7 = call ptr @__cq_alloc(i64 8, i64 4)    ; IR: %6 = alloca [2 x i32], align 4  [bus-resident: ONE zeroed block for all trips, no alloca remains (rules 16, 20)]
  %8 = ptrtoint ptr %7 to i64    ; the block's run-time address, a classical i64 (rule 21)
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %7 = cq_theta_ui32(%0, %1)  [Ry]
  %10 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %8 = cq_theta_si32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %10, double %3)    ; IR: %8 = cq_theta_si32(%2, %3)  [Ry]
  %11 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %17 / %13  [s before trip 0: trip 0's old s, cleaned by rule 6 in the body; measured itself when no trip runs]
  %12 = icmp sgt i32 %4, 0    ; IR: %9 = icmp sgt i32 %4, 0
  br i1 %12, label %13, label %16    ; IR: br i1 %9, label %10, label %12

13:
  %14 = getelementptr inbounds i8, ptr %7, i64 4    ; IR: %11 = getelementptr inbounds i8, ptr %6, i64 4  (nothing tainted: the getelementptr stays, rule 20)
  %15 = ptrtoint ptr %14 to i64    ; the run-time address of a[1], a classical i64 (rule 21)
  br label %19    ; IR: br label %15

16:
  %17 = phi i32 [ %11, %5 ], [ %32, %19 ]    ; IR: %13 = phi i32 [ 0, %5 ], [ %25, %15 ]  (a classical phi over handles, rule 9)
  %18 = call i32 @cqrt_measure_i32(i32 %17)    ; IR: %14 = cq_measure_si32(%13)  [the carried s: rule 6 left no other s rail, so no copy-out and no reverse loop]
  ret i32 %18    ; IR: ret i32 %14

19:
  %20 = phi i32 [ 0, %13 ], [ %34, %19 ]    ; IR: %16 = phi i32 [ 0, %10 ], [ %26, %15 ]  (classical)
  %21 = phi i32 [ %11, %13 ], [ %32, %19 ]    ; IR: %17 = phi i32 [ 0, %10 ], [ %25, %15 ]
  %22 = call i32 @cqrt_alloc_i32(i32 %20)    ; IR: llvm.lifetime.start(8, %6) dropped (rule 16); store i32 %16, ptr %6  [the seed of the classical value i: the store's value rail, KEPT with it (rules 5, 7)]
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %8, i32 %22)    ; IR: store i32 %16, ptr %6, align 4  [a kept store at a classical address: its tape slot takes what the trip before left in a[0] (rule 5)]
  %23 = call i32 @cq_template_lshr_i32_hl(i32 %9, i32 %20)    ; IR: %18 = lshr i32 %7, %16
  %24 = call i32 @cq_template_and_i32_hl(i32 %23, i32 1)    ; IR: %19 = and i32 %18, 1
  %25 = call i32 @cq_template_zext_i32_to_i64(i32 %24)    ; IR: %20 = zext nneg i32 %19 to i64
  %26 = call i32 @cq_template_mul_i64_hl(i32 %25, i64 4)    ; IR: %21 = getelementptr inbounds [2 x i32], ptr %6, i64 0, i64 %20  [the tainted index scaled by the element size (rule 20)]
  %27 = call i32 @cq_template_add_i64_hl(i32 %26, i64 %8)    ; IR: %21 = getelementptr  [+ the classical part, the run-time base: the address rail of &a[(k >> i) & 1]]
  call void @cqrt_qram_store_i32(i32 %6, i32 %27, i32 %10)    ; IR: store i32 %8, ptr %21, align 4  [a kept store at an address rail: its tape slot and its value rail x stay (rule 5)]
  call void @cq_template_add_i64_hl_unc(i32 %27, i32 %26, i64 %8)    ; IR: uncompute %21  [the address rail follows its producer: a template result, uncomputed after the store (rule 5)]
  call void @cqrt_free(i32 %27)    ; IR: release the %21 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %26, i32 %25, i64 4)    ; IR: uncompute %21 (the scaled index)
  call void @cqrt_free(i32 %26)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %25, i32 %24)    ; IR: uncompute %20
  call void @cqrt_free(i32 %25)    ; IR: release the %20 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %24, i32 %23, i32 1)    ; IR: uncompute %19
  call void @cqrt_free(i32 %24)    ; IR: release the %19 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %23, i32 %9, i32 %20)    ; IR: uncompute %18
  call void @cqrt_free(i32 %23)    ; IR: release the %18 rail (|0>)
  %28 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %8)    ; IR: %22 = load i32, ptr %6, align 4  [a bus load at a classical address: a rail (rule 3)]
  %29 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %15)    ; IR: %23 = load i32, ptr %11, align 4  [a[1] has no initializer: the load reads what the block holds, 0 from __cq_alloc or the x a trip before stored (rule 20: the cells carry over)]
  %30 = call i32 @cq_template_add_i32(i32 %28, i32 %21)    ; IR: %24 = add i32 %22, %17  [s1 = a[0] + s]
  %31 = call i32 @cq_template_sub_i32(i32 %30, i32 %28)    ; IR: rule 6: t = s1 - a[0] recomputes the old s (the add is a bijection in s; the other operand is the load copy, rule-5 garbage)  ; SPEC GAP: rule 6 'both operands dead' does not name a bus load copy as garbage that rule 5 uncomputes anyway; read so
  call void @cqrt_copy_i32(i32 %31, i32 %21)    ; IR: rule 6: old s ^= t: |0> (trip 0: the |0> seed, unchanged)
  call void @cq_template_sub_i32_unc(i32 %31, i32 %30, i32 %28)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %31)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %21)    ; IR: rule 6: release the old s rail (|0> after the copy); it is not pushed
  call void @cqrt_qram_load_i32_hl_unc(i32 %28, i32 %6, i64 %8)    ; IR: un-copy %22 (rule 5: no memory version change since the load; the cells hold the loaded value)  ; SPEC GAP: sentence 1 asks for the last consumer's uncompute, and the consumer %24 is a rule-6 image (never uncomputed); read as for a template operand
  call void @cqrt_free(i32 %28)    ; IR: release the %22 rail (|0>)
  %32 = call i32 @cq_template_add_i32(i32 %30, i32 %29)    ; IR: %25 = add i32 %24, %23  [s after this trip: the only s rail that survives it]
  %33 = call i32 @cq_template_sub_i32(i32 %32, i32 %29)    ; IR: rule 6: t = s' - a[1] recomputes s1 (operand 0 of the add; the other operand is the load copy)
  call void @cqrt_copy_i32(i32 %33, i32 %30)    ; IR: rule 6: s1 ^= t: |0>
  call void @cq_template_sub_i32_unc(i32 %33, i32 %32, i32 %29)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %33)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %30)    ; IR: rule 6: release the s1 rail (|0> after the copy)
  call void @cqrt_qram_load_i32_hl_unc(i32 %29, i32 %6, i64 %15)    ; IR: un-copy %23 (rule 5: no memory version change since the load)
  call void @cqrt_free(i32 %29)    ; IR: release the %23 rail (|0>); llvm.lifetime.end(8, %6) dropped (rule 16): the cells keep their content for the next trip
  %34 = add nuw nsw i32 %20, 1    ; IR: %26 = add nuw nsw i32 %16, 1
  %35 = icmp eq i32 %34, %4    ; IR: %27 = icmp eq i32 %26, %4
  br i1 %35, label %16, label %19    ; IR: br i1 %27, label %12, label %15
}

define i32 @bus_recursion(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %7 = cq_theta_si32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %7 = cq_theta_si32(%2, %3)  [Ry]
  %8 = call fastcc i32 @__cq_q_walk_110(i32 %6, i32 %7, i32 %4)    ; IR: %8 = call fastcc @walk(%6, %7, %4), quantum clone (k, x quantum; the depth classical)  [walk writes memory: no twin is called; the result rail is measured]
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %9    ; IR: ret i32 %9
}

define internal fastcc i32 @__cq_q_walk_110(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %5 = call ptr @__cq_alloc(i64 8, i64 4)    ; IR: %4 = alloca [2 x i32], align 4  [bus-resident: one zeroed block PER ACTIVATION at an address never reused, no alloca remains (rules 14, 16, 20); llvm.lifetime.start(8, %4) dropped]
  %6 = ptrtoint ptr %5 to i64    ; the block's run-time address, a classical i64 (rule 21)
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %4  [the seed of the classical value d: the store's value rail, KEPT with it (rules 5, 7)]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %6, i32 %7)    ; IR: store i32 %2, ptr %4, align 4  [a kept store at a classical address (rule 5)]
  %8 = getelementptr inbounds i8, ptr %5, i64 4    ; IR: %5 = getelementptr inbounds i8, ptr %4, i64 4  (nothing tainted: the getelementptr stays, rule 20)
  %9 = ptrtoint ptr %8 to i64    ; the run-time address of a[1], a classical i64 (rule 21)
  %10 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: store i32 0, ptr %5  [the seed of the literal 0: the store's value rail, KEPT with it (rules 5, 7)]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %9, i32 %10)    ; IR: store i32 0, ptr %5, align 4  [a kept store (rule 5)]
  %11 = call i32 @cq_template_and_i32_hl(i32 %0, i32 1)    ; IR: %6 = and i32 %0, 1
  %12 = call i32 @cq_template_zext_i32_to_i64(i32 %11)    ; IR: %7 = zext nneg i32 %6 to i64
  %13 = call i32 @cq_template_mul_i64_hl(i32 %12, i64 4)    ; IR: %8 = getelementptr inbounds [2 x i32], ptr %4, i64 0, i64 %7  [the tainted index scaled by the element size (rule 20)]
  %14 = call i32 @cq_template_add_i64_hl(i32 %13, i64 %6)    ; IR: %8 = getelementptr  [+ the classical part, the run-time base: the address rail of &a[k & 1]]
  call void @cqrt_qram_store_i32(i32 %4, i32 %14, i32 %1)    ; IR: store i32 %1, ptr %8, align 4  [a kept store at an address rail: its tape slot stays; the value rail x is the caller's argument (rule 5)]
  call void @cq_template_add_i64_hl_unc(i32 %14, i32 %13, i64 %6)    ; IR: uncompute %8  [the address rail follows its producer: a template result, uncomputed after the store (rule 5)]
  call void @cqrt_free(i32 %14)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %13, i32 %12, i64 4)    ; IR: uncompute %8 (the scaled index)
  call void @cqrt_free(i32 %13)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %12, i32 %11)    ; IR: uncompute %7
  call void @cqrt_free(i32 %12)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %0, i32 1)    ; IR: uncompute %6
  call void @cqrt_free(i32 %11)    ; IR: release the %6 rail (|0>)
  %15 = icmp eq i32 %2, 0    ; IR: %9 = icmp eq i32 %2, 0  (classical)
  br i1 %15, label %20, label %16    ; IR: br i1 %9, label %14, label %10  [a classical branch: the depth is classical (rules 8, 14)]

16:
  %17 = call i32 @cq_template_lshr_i32_hl(i32 %0, i32 1)    ; IR: %11 = lshr i32 %0, 1
  %18 = add nsw i32 %2, -1    ; IR: %12 = add nsw i32 %2, -1  (classical)
  %19 = call fastcc i32 @__cq_q_walk_110(i32 %17, i32 %1, i32 %18)    ; IR: %13 = call fastcc @walk(%11, %1, %12)  [an ordinary call of the ONE clone: classical depth (rule 18); it writes memory, so no twin is called; the result is cleaned by rule 6 below]
  call void @cq_template_lshr_i32_hl_unc(i32 %17, i32 %0, i32 1)    ; IR: uncompute %11 (its last consumer is the call)
  call void @cqrt_free(i32 %17)    ; IR: release the %11 rail (|0>)
  br label %22    ; IR: br label %14

20:
  %21 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %15 on the edge %3 -> %14  [a seed, rule 7]  ; SPEC GAP: where the literal incoming of a classical phi over handles is minted is not stated; on its edge
  br label %22

22:
  %23 = phi i32 [ %19, %16 ], [ %21, %20 ]    ; IR: %15 = phi i32 [ %13, %10 ], [ 0, %3 ]  (a classical phi over handles, no gate, rule 9)
  %24 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %6)    ; IR: %16 = load i32, ptr %4, align 4  [a bus load at a classical address, after the inner activation returned: this activation's own block]
  call void @cqrt_add_i32(i32 %24, i32 %23)    ; IR: %17 = add nsw i32 %16, %15  [rule 6, in-place update: below is dead after the add (the other operand is the load copy, rule-5 garbage), so the result IS below's rail (d == 0: the seed's)]  ; SPEC GAP: rule 6 against rule 18's 'KEPT by the caller' for a result without a twin; rule 6 is taken
  call void @cqrt_qram_load_i32_hl_unc(i32 %24, i32 %4, i64 %6)    ; IR: un-copy %16 (rule 5: no memory version change since the load)  ; SPEC GAP: sentence 1 asks for the last consumer's uncompute, and the consumer %17 is the returned rule-6 image; read as for a template operand
  call void @cqrt_free(i32 %24)    ; IR: release the %16 rail (|0>); llvm.lifetime.end(8, %4) dropped (rule 16)
  ret i32 %23    ; IR: ret i32 %17  [the rule-6 image, below's rail updated in place, is returned directly, no copy-out]  ; SPEC GAP: rule 18's clone form copies each result out; a result that is a rule-6 image cannot be uncomputed after a copy
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_add_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
