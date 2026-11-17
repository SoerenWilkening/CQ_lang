; HAND-WRITTEN. Rules: 2, 3, 4, 5, 7, 16, 18, 20, 21, 26; §1.3 (the bus, __cq_mem, __cq_alloc), §1.4.
; Checked: r.a + r.b + r.c (the add rail %16, measured -> %17) = ((x + c) + (x * c) + c) mod 2^64; the cells of r on
; the bus at exit: r.a = x + c, r.b = x * c, r.c = c (8 bytes each at offsets 0, 8, 16).
; Clean: sret_return: the three load copies r.a, r.b, r.c (%8, %11, %15; un-copied, no memory version change follows
; the loads) and the partial sum r.b + r.a (%12). __cq_q_mk_010: nothing (every rail it makes is the value rail of a
; kept store).
; Kept: x (%6, the rotated register), the sum rail %16 (measured); by rule 5 sentence 3 the three tape slots of the
; clone's stores `store i64 %4, ptr %0`, `store i64 %6, ptr %5`, `store i64 %2, ptr %7` and their value rails: the add
; rail x + c (%6 in the clone), the mul rail x * c (%9 in the clone) and the seed c (%12 in the clone, rule 7).
; Rotations: (Ry, x, tx, 1).
; Expected for the driver sret_return(0, .5, 3): Ry(.5) flips each of the 64 bits of x independently with probability
; s = sin^2(.25) = 0.0612087; x unchanged (= 0, probability (1 - s)^64 = 0.0176) measures (0 + 3) + 0 * 3 + 3 = 6.
; SRET IS A POINTER FORMAL LIKE ANY OTHER (rule 26, §1.4): mk(sret &r, x, c) is the clone of mask 010 (the sret pointer
; a classical ptr, x a rail, c classical), __cq_q_mk_010(ptr, i32, i64); nothing about the pointee (its fields, their
; kinds, the struct type) appears in the name or the parameter list and no handle crosses the call through memory.
; The sret attribute stays on the formal and the call, an ABI note, spelled with the literal type { i64, i64, i64 }
; (renumber_locals.py would read a named %struct.big as a local value). mk's own symbol has no caller left: dropped.
; THE ALLOCA IS BUS-RESIDENT (rule 20 b): r is a call argument, so it is __cq_alloc(24, 8) at the alloca's program point,
; no alloca remains and the lifetime markers are dropped (rule 16). -O1's byte-offset geps (8, 16) have nothing tainted
; and stay as they are: the struct keeps its C layout in memory, and every field access is ONE i64 bus access at the
; classical address (rule 20 store size; S = 8 cells).
; WHAT THE CLONE STORES IS KEPT (rules 5, 18). Each of the three stores is a kept bus store at a classical address
; (qram_store_i64_hl): its tape slot stays for the shot and so does its value rail. r.a = x + c and r.b = x * c are
; therefore not uncomputed in the clone, and the classical c is stored as a seed alloc_i64(c) kept with its store
; (rule 7): every store is a bus store and its value always a handle (§1.3). mk writes memory, so __cq_q_mk_010 has NO
; twin and returns nothing (void). The caller's loads come after the call (a memory version change) and are bus loads
; whose results are rails (rule 3), r.c included: the last add is rail + rail (cq_template_add_i64), not _hl.
; LOAD COPIES (rule 5 sentence 1): r.c's copy (%15) is un-copied right after its last reader, the measured add %16,
; which is never uncomputed and so has no _unc to wait for; then the partial sum %12 is uncomputed and the copies of
; r.b and r.a are un-copied after its _unc, all before the measurement (the sentence's convention), with no memory
; version change after the loads.
; SPEC GAP: CR fixes no calling convention, linkage or attributes for a clone called by name; it keeps the callee's
; (internal fastcc, unnamed_addr) as 31, 195 and 200 do, and the memory, capture and nullness facts of mk (noalias,
; nocapture, writable, writeonly, dead_on_unwind, memory(argmem: write), nofree, willreturn) are dropped (§1.4).
; Regenerated 2026-11-05 for the flat memory model: the previous version (one handle cell per quantum field, a twin
; that zeroed copy rails through the slot) belonged to the retired model.
source_filename = "sret_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @sret_return(i64 noundef %0, double noundef %1, i64 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %5 = call ptr @__cq_alloc(i64 24, i64 8)    ; IR: %4 = alloca %struct.big, align 8: r is bus-resident (a call argument, rule 20 b): one zeroed block, no alloca remains
  %6 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %5 = cq_theta_sl(%0, %1)  [register x]
  call void @cqrt_ry_i64(i32 %6, double %1)    ; IR: %5 = cq_theta_sl(%0, %1)  [Ry]
  %7 = ptrtoint ptr %5 to i64    ; IR: the run-time address of r (classical; llvm.lifetime.start dropped)
  call fastcc void @__cq_q_mk_010(ptr sret({ i64, i64, i64 }) %5, i32 %6, i64 %2)    ; IR: call fastcc void @mk(ptr sret %4, i64 %5, i64 %2): the clone of mask 010 (classical ptr, rail, classical int); it stores, so it has no twin (rule 18)
  %8 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %7)    ; IR: %6 = load i64, ptr %4  [r.a, written by the clone: a bus load, a rail]
  %9 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %7 = getelementptr inbounds i8, ptr %4, i64 8  (nothing tainted: the gep stays)
  %10 = ptrtoint ptr %9 to i64    ; IR: %7 as its run-time address
  %11 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %10)    ; IR: %8 = load i64, ptr %7  [r.b]
  %12 = call i32 @cq_template_add_i64(i32 %11, i32 %8)    ; IR: %9 = add nsw i64 %8, %6
  %13 = getelementptr inbounds i8, ptr %5, i64 16    ; IR: %10 = getelementptr inbounds i8, ptr %4, i64 16  (nothing tainted: the gep stays)
  %14 = ptrtoint ptr %13 to i64    ; IR: %10 as its run-time address
  %15 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %14)    ; IR: %11 = load i64, ptr %10  [r.c: a bus load, a rail (rule 3), though the clone stored a classical value]
  %16 = call i32 @cq_template_add_i64(i32 %12, i32 %15)    ; IR: %12 = add nsw i64 %9, %11  [result rail]
  call void @cqrt_qram_load_i64_hl_unc(i32 %15, i32 %4, i64 %14)    ; IR: un-copy %11 (its last reader %12 is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %15)    ; IR: release the %11 rail (|0>)
  call void @cq_template_add_i64_unc(i32 %12, i32 %11, i32 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %11, i32 %4, i64 %10)    ; IR: un-copy %8 (its last reader, the _unc of %9, is done)
  call void @cqrt_qram_load_i64_hl_unc(i32 %8, i32 %4, i64 %7)    ; IR: un-copy %6
  call void @cqrt_free(i32 %11)    ; IR: release the %8 rail (|0>)
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  %17 = call i64 @cqrt_measure_i64(i32 %16)    ; IR: %13 = cq_measure_sl(%12)  [the sum rail stays allocated]
  ret i64 %17    ; IR: ret i64 %13  (llvm.lifetime.end dropped)
}

define internal fastcc void @__cq_q_mk_010(ptr sret({ i64, i64, i64 }) %0, i32 %1, i64 %2) unnamed_addr {
  %4 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %5 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address (mask digit 0: the sret formal is the C ptr)
  %6 = call i32 @cq_template_add_i64_hl(i32 %1, i64 %2)    ; IR: %4 = add nsw i64 %2, %1  (commutative: handle first)  [r.a]
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %5, i32 %6)    ; IR: store i64 %4, ptr %0  [kept store at a classical address: no _unc; its value rail %4 is kept with it]
  %7 = getelementptr inbounds i8, ptr %0, i64 8    ; IR: %5 = getelementptr inbounds i8, ptr %0, i64 8  (nothing tainted: the gep stays)
  %8 = ptrtoint ptr %7 to i64    ; IR: %5 as its run-time address
  %9 = call i32 @cq_template_mul_i64_hl(i32 %1, i64 %2)    ; IR: %6 = mul nsw i64 %2, %1  (commutative: handle first)  [r.b]
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %8, i32 %9)    ; IR: store i64 %6, ptr %5  [kept store; its value rail %6 is kept with it]
  %10 = getelementptr inbounds i8, ptr %0, i64 16    ; IR: %7 = getelementptr inbounds i8, ptr %0, i64 16  (nothing tainted: the gep stays)
  %11 = ptrtoint ptr %10 to i64    ; IR: %7 as its run-time address
  %12 = call i32 @cqrt_alloc_i64(i64 %2)    ; IR: store i64 %2, ptr %7: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %11, i32 %12)    ; IR: store i64 %2, ptr %7  [kept store at a classical address]
  ret void    ; IR: ret void  (mk writes memory: no twin, rule 18; every rail above stays with its store)
}

declare i32 @__cq_mem()

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_ry_i64(i32, double)

declare void @cqrt_free(i32)

declare i64 @cqrt_measure_i64(i32)

declare i32 @cqrt_qram_load_i64_hl(i32, i64)

declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)

declare void @cqrt_qram_store_i64_hl(i32, i64, i32)

declare i32 @cq_template_add_i64_hl(i32, i64)

declare i32 @cq_template_mul_i64_hl(i32, i64)

declare i32 @cq_template_add_i64(i32, i32)

declare void @cq_template_add_i64_unc(i32, i32, i32)
