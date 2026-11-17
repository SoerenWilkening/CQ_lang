; HAND-WRITTEN. Rules: 17, 2, 5 (in-place form; Memory, sentences 1 and 3), 18, 10, 20, 21, 16, 7, 8; §1.3 (the bus, qram_swap), §1.4.
; Checked: invert_theta: x (%4 -> %5). invert_call: x (the 4 cells at P, the address of the bus-resident x; read by
; the load copy %12 -> %13) and y (%11 -> %14), summed classically. The cells at P at exit hold x after both calls.
; Clean: in __cq_q_prep_01000: the swap rail of each in-place form (%8, %10: |0> after its swap-in) and the flag
; f = (y > k) (%9), uncomputed and freed after its last controlled gate (in the bracketed activation the backend
; recomputes and uncomputes it as the reversed list runs, rule 17).
; Kept: the user registers x (the cell at P) and y (rotated, measured). Rule 5 sentence 3: the tape slot of the store
; x = x0 and its value rail, the seed alloc_i32(x0) (%10 of invert_call). Rule 2: the load copy of x (%12), measured.
; Rotations: invert_theta: (Ry, x, th, 1); then the region as the backend emits it: (Ry, x, -t2, 1).
; invert_call: (Ry, y, ty, 1); (Ry, x, t1, 1); (Ry, x, t2, y > k); then the region: (Ry, x, -t2, y > k); (Ry, x, -t1, 1).
; cq_invert is the run-time pair cqrt_invert_begin()/cqrt_invert_end() (rule 17, §1.3): the code between the markers is
; lowered as anywhere else, and the backend emits the gates recorded between the two calls reversed with each gate
; inverted. invert_theta: the recorded list is [Ry(x, t2)], emitted as Ry(x, -t2).
; invert_call: `prep(&x, ...)` takes x's ADDRESS, a call user, so the alloca of x is bus-resident (rule 20 (b)):
; __cq_alloc(4, 4) at its program point, P = its run-time address (a classical i64), no alloca remains and the lifetime
; markers are dropped (rule 16). `x = x0` is a bus store of the seed alloc_i32(x0) at P, a kept store (rules 5, 7).
; THE CLONE (§1.4, rules 18, 21): a pointer is one scalar. &x is a classical ptr (not computed from a rail), digit 0,
; and the formal stays the C ptr; y is a quantum scalar, digit 1; the angles and k are classical: __cq_q_prep_01000.
; Nothing about the pointee crosses the call. In the clone, `*x = cq_theta(*x, t1)` is rule 5's in-place form at the
; classical address p = ptrtoint %0 (swap-out into a |0> rail, Ry, swap-in, free): the cell is the register. The
; conditional `*x = cq_theta(%7, t2)` rotates the value -O1 forwarded from the first store to the same SSA pointer
; (rule 5, Readers): its interval runs from that store and holds no memory version change (only the compare template),
; so it is a second in-place form, under the flag f = (y > k) read from the OTHER register y (rule 10 on a memory cell):
; the swaps are qram_swap_i32_hl_controlled(f, ...) and the gate ry_i32_controlled(f, ...). The clone's body is
; [swap; Ry(t1); swap; f = (y > k); swap|f; cRy(f, t2); swap|f; unc f; free f]. It writes memory (two in-place forms),
; so it has no twin and its calls are memory version changes (rules 5, 18); it has no result.
; The bracketed call is the SAME clone (no `_adj` kind exists, §1.4): rule 17's "Memory": an in-place form inverts
; exactly, so the backend's reversal of the gates it records is [unc f (= compute f); swap|f; cRy(f, -t2); swap|f;
; f's uncompute; swap; Ry(-t1); swap], with the frees performed after the reversed list. Had the condition read x
; itself (`if (*x > k) cq_theta(x, t2)`), the flag could not be uncomputed after the rotation changed x; that shape is
; example 66, where the flag stays allocated. After the region, `cq_measure(x)` reads x through a plain bus load at P
; (rule 3): the copy is the measured rail (rule 2, never un-copied).
; SPEC GAP (corpus convention, §5): §1.3 / rule 19 ask for a __cq_clone_register row (the _t clone, _t_ctl and their
; twins) per externally visible function. As in 200, 204, 211 and 212 nothing is registered for invert_theta and
; invert_call (their addresses are never taken here); the compiler emits the rows, and the omission is not part of the
; pinned lowering.
; Regenerated 2026-11-05 for the flat bus (the 2026-11-02 version kept x's handle in a classical slot, passed the slot
; to __cq_q_prep_11000 with a pointee digit and rotated the handle it loaded; the first version constructed
; __cq_q_prep_11000_adj at compile time).
source_filename = "invert_theta_and_call.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @invert_theta(i32 noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  call void @cqrt_invert_begin()    ; IR: call @__cq_invert_begin(); fence consumed (rule 17)
  call void @cqrt_ry_i32(i32 %4, double %2)    ; IR: %5 = cq_theta_si32(%4, %2)  [Ry in place; the backend emits it as Ry(-%2) when the region closes]
  call void @cqrt_invert_end()    ; IR: call @__cq_invert_end(); fence consumed
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %5    ; IR: ret i32 %6
}

define i32 @invert_call(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, double noundef %4, i32 noundef %5) {
  %7 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %8 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %7 = alloca i32, align 4: bus-resident (rule 20 (b): its address is a call argument), one zeroed block (rule 16); llvm.lifetime.start dropped
  %9 = ptrtoint ptr %8 to i64    ; IR: %7 as its run-time address P (classical i64)
  %10 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: store i32 %0, ptr %7: the classical value x0 as a seed (rule 7), the store's value rail, kept with it
  call void @cqrt_qram_store_i32_hl(i32 %7, i64 %9, i32 %10)    ; IR: store i32 %0, ptr %7  [x = x0: kept store at P, rule 5 sentence 3]
  %11 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %8 = cq_theta_ui32(%1, %2)  [register y]
  call void @cqrt_ry_i32(i32 %11, double %2)    ; IR: %8 = cq_theta_ui32(%1, %2)  [Ry]
  call fastcc void @__cq_q_prep_01000(ptr noundef %8, i32 noundef %11, double noundef %3, double noundef %4, i32 noundef %5)    ; IR: call fastcc void @prep(%7, %8, %3, %4, %5): the clone of mask 01000 (classical ptr, y quantum); it writes memory, no twin (rule 18)
  call void @cqrt_invert_begin()    ; IR: call @__cq_invert_begin(); fence consumed (rule 17)
  call fastcc void @__cq_q_prep_01000(ptr noundef %8, i32 noundef %11, double noundef %3, double noundef %4, i32 noundef %5)    ; IR: bracketed call @prep(%7, %8, %3, %4, %5): the same clone; the backend reverses and inverts the gates it records
  call void @cqrt_invert_end()    ; IR: call @__cq_invert_end(); fence consumed
  %12 = call i32 @cqrt_qram_load_i32_hl(i32 %7, i64 %9)    ; IR: %9 = load i32, ptr %7  [x: a bus load at P, a rail (rule 3)]
  %13 = call i32 @cqrt_measure_i32(i32 %12)    ; IR: %10 = cq_measure_ui32(%9)  [the load copy is the measured rail, rule 2: never un-copied, stays allocated]
  %14 = call i32 @cqrt_measure_i32(i32 %11)    ; IR: %11 = cq_measure_ui32(%8)
  %15 = add i32 %14, %13    ; IR: %12 = add i32 %11, %10  (classical)
  ret i32 %15    ; IR: ret i32 %12  (llvm.lifetime.end dropped)
}

define internal fastcc void @__cq_q_prep_01000(ptr noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4) unnamed_addr {
  %6 = call i32 @__cq_mem()    ; IR: the bus M
  %7 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address p (mask digit 0: the formal is the C ptr)
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %6 = load i32, ptr %0: in-place form (1), the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %6, i64 %7, i32 %8)    ; IR: %6 = load i32, ptr %0: swap-out: the rail holds *x, the cell |0>
  call void @cqrt_ry_i32(i32 %8, double %2)    ; IR: %7 = cq_theta_ui32(%6, %2)  [Ry on the cell's content]
  call void @cqrt_qram_swap_i32_hl(i32 %6, i64 %7, i32 %8)    ; IR: store i32 %7, ptr %0: swap-in: the cell holds %7; the store closes form (1)
  call void @cqrt_free(i32 %8)    ; IR: release the swap rail (|0>)
  %9 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %1, i32 %4)    ; IR: %8 = icmp ugt i32 %1, %4  [path predicate of block %9]
  %10 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: block %9: %10 = cq_theta_ui32(%7, %3): in-place form (2) on the forwarded %7 (rule 5, Readers: no memory version change since store (1)), the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %9, i32 %6, i64 %7, i32 %10)    ; IR: block %9: swap-out under the predicate (f = 0: nothing touched, the rail stays |0>)
  call void @cqrt_ry_i32_controlled(i32 %9, i32 %10, double %3)    ; IR: block %9: %10 = cq_theta_ui32(%7, %3)  [Ry under the predicate, rule 10 on a memory cell]
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %9, i32 %6, i64 %7, i32 %10)    ; IR: block %9: store i32 %10, ptr %0: swap-in under the predicate: the cell holds %10, the rail |0> on both branches
  call void @cqrt_free(i32 %10)    ; IR: release the swap rail (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %9, i32 %1, i32 %4)    ; IR: uncompute %8 (after its last controlled gate)
  call void @cqrt_free(i32 %9)    ; IR: release the %8 rail (|0>)
  ret void    ; IR: ret void
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_invert_begin()
declare void @cqrt_invert_end()
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i32_hl_controlled(i32, i32, i64, i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
