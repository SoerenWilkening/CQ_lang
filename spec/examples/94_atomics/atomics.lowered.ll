; HAND-WRITTEN. Rules: 24, 20, 4, 5, 6, 7, 9, 2, 16, 26; §1.3 (the bus, __cq_mem, __cq_alloc).
; Checked: now + ok + expected (measured): the cell after the cmpxchg (the load copy %16, measured -> %17), the
; cmpxchg success flag (the zext %15, measured -> %18) and the loaded value (the load copy %12, measured -> %20); and the
; cell `cell` on the bus at exit: equal ? x : x + c, equal = (x + c == e).
; Clean: the swap rail of the atomicrmw's in-place form (%11: the cell, then old + c by rule 6's in-place update, |0>
; after the swap-in); the cmpxchg equality flag %13 (uncomputed against the measured copy %12).
; Kept: x (%8: rotated register, and the value rail of the kept store `store atomic i32 %6, ptr %5`, rule 5 sentence 3,
; so rule 6 does not clean it); by rule 5, for the shot: the tape slots of the three bus stores (`store i32 %2, ptr %5`,
; `store atomic i32 %6, ptr %5`, and the cmpxchg's store of the select %14); the seed %9 holding c (rule 7: the value rail of the
; kept store `int cell = c`); the load copy old = %10 (the atomicrmw's result, read after the in-place form, which
; overtakes it: sentence 1 un-copies it right after its last reader, the select %14, and does not free it); the
; cmpxchg's select %14 (the value rail of its kept store). Rule 2: the load copies %12
; (expected) and %16 (now) and the zext %15 (ok), measured.
; Rotations: (Ry, x, th, 1).
; Expected for the driver atomics(0, .5, 3, 5): Ry(.5) flips each of the 32 bits of x = 0 independently with
; probability s = sin^2(.25) = 0.0612087. The cell holds x + 3 after the fetch-add, so expected = x + 3 and the exchange
; succeeds iff x + 3 == 5, i.e. x == 2: then now = old = x = 2, ok = 1, expected = 5, result 8 (probability
; s (1 - s)^31 = 0.008639). Otherwise now = expected = x + 3, ok = 0, result 2x + 6: x = 0 gives 6 with probability
; (1 - s)^32 = 0.132498; each other single-bit flip x = 2^i (i != 1, 30, 31) gives 2^(i+1) + 6 with probability
; 0.008639 (i = 0 also gives 8, so 8 has probability 0.017278 in all). i = 30 and i = 31 overflow the final signed add
; %21 (nsw: undefined in C): under the trace's wraparound i = 30 gives -2^31 + 6 and i = 31 (x = INT_MIN) gives 6, so
; the trace's 6 has probability 0.132498 + 0.008639 = 0.141137.
; THREADS ARE OUT OF THE MODEL (rule 24): a reversible circuit is sequential, so every atomic op has single-thread
; semantics and lowers as the plain op it wraps: store atomic = store, load atomic = load, atomicrmw add = load + add +
; store returning the old value, cmpxchg = load + icmp eq + select + store returning { loaded, equal } as two rails
; (rule 26's aggregate), fence = nothing (no gate, no host call).
; ONE BUS (rule 20). cell's alloca has a store of a rail among its users, so it is bus-resident (rule 20 (b)): one
; zeroed block __cq_alloc(4, 4) at the alloca's program point, no alloca remains and the lifetime markers are dropped
; (rule 16). Its run-time address %7 is the _hl operand of every access; nothing asks what the cell holds. `int cell =
; c` stores the seed alloc_i32(c) (rule 7), and it and the store atomic of x are KEPT stores (rule 5 sentence 3).
; atomicrmw add is `y = load; y' = y + c; store y'` on the same pointer with nothing between: rule 5's IN-PLACE FORM with
; a rule-6 bijection as its step (rule 6, "a memory cell"), at the store's position: swap-out into a fresh |0> rail,
; y' = h + c as rule 6's in-place update (ONE core gate addc_i32(h, c) on the swap rail), swap-in, free. Its result, the old value y, has another reader (the cmpxchg's new
; value), so it is a plain load taken before the swap-out (rule 5, Readers); the form is a memory version change before
; that reader, so the copy is overtaken (sentence 1): un-copied after the select, left allocated.
; SPEC GAP (rule 4): `cmpxchg` and `atomicrmw` are first read as a bus load, the compare and `select` (or the
; operation's) templates and a bus store on the same pointer (rules 20, 24); that expansion is then lowered by rule 5
; like any written load/update/store, so an `atomicrmw` whose operation is a rule-6 bijection in the cell (`add`, `sub`,
; `xor`) is rule 5's in-place form, and its result, the old value, is the Readers clause's plain load taken before the
; swap-out.
; cmpxchg is not the in-place form (the select's condition reads the cell and its true arm is not an update of it, rule
; 6): a plain load (element 0, measured as `expected`), the compare (element 1), the select and a kept store of it. The
; load atomic of `now` is a plain load at the classical address, measured. The flag %13 is uncomputed after its last
; consumer (the zext); its _unc reads the measured copy %12, which stays allocated.
source_filename = "atomics.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @atomics(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %6 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %5 = alloca i32, align 4: cell is bus-resident (a rail is stored through it): a zeroed block, no alloca remains
  %7 = ptrtoint ptr %6 to i64    ; IR: the run-time address of cell as the _hl operand (classical)
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %5: the value seed c (rule 7; kept with the store; llvm.lifetime.start is dropped)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %7, i32 %9)    ; IR: store i32 %2, ptr %5: int cell = c  (kept store, classical address)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %7, i32 %8)    ; IR: store atomic i32 %6, ptr %5 seq_cst: single-thread, a kept store of x
  %10 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %7)    ; IR: %7 = atomicrmw add ptr %5, i32 %2: the old value, a plain load before the swap-out (rule 5, Readers; the form overtakes it: un-copied after the select, not freed)
  %11 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %7 = atomicrmw add: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %5, i64 %7, i32 %11)    ; IR: %7 = atomicrmw add: swap-out: the rail holds the cell, the cell |0>
  call void @cqrt_addc_i32(i32 %11, i32 %2)    ; IR: %7 = atomicrmw add: old + %2  [rule 6, in-place update: the swapped-out old value is dead after the add, so old + c IS the swap rail]
  call void @cqrt_qram_swap_i32_hl(i32 %5, i64 %7, i32 %11)    ; IR: %7 = atomicrmw add: swap-in: the cell holds old + c, the rail the cell's |0>
  call void @cqrt_free(i32 %11)    ; IR: release the rail (|0>): nothing remains of the update
  ; IR: fence seq_cst: no gate (single thread)
  %12 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %7)    ; IR: %8 = cmpxchg ptr %5, i32 %3, i32 %7: the loaded value, element 0 (%10)  [measured]
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 %3)    ; IR: %8: element 1 (%9), loaded == expected
  %14 = call i32 @cq_template_select_i32(i32 %13, i32 %10, i32 %12)    ; IR: %8: cell = equal ? %7 (the old value) : loaded  [the new cell]
  call void @cqrt_qram_load_i32_hl_unc(i32 %10, i32 %5, i64 %7)    ; IR: un-copy %7 (the old value) after its last reader, the select; the in-place form came between, so it stays allocated (overtaken, rule 5 sentence 1)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %7, i32 %14)    ; IR: %8: the store of the new cell (kept store: its tape slot and its value rail %8's select stay)
  %15 = call i32 @cq_template_zext_i1_to_i32(i32 %13)    ; IR: %11 = zext i1 %9 to i32  [measured]
  %16 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %7)    ; IR: %12 = load atomic i32, ptr %5 seq_cst: a plain bus load  [measured]
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %12, i32 %3)    ; IR: uncompute %9 (its last consumer, the zext, is done; the select is kept)
  call void @cqrt_free(i32 %13)    ; IR: release the %9 rail (|0>)
  %17 = call i32 @cqrt_measure_i32(i32 %16)    ; IR: %13 = cq_measure_si32(%12)
  %18 = call i32 @cqrt_measure_i32(i32 %15)    ; IR: %14 = cq_measure_si32(%11)
  %19 = add nsw i32 %18, %17    ; IR: %15 = add nsw i32 %14, %13  (classical)
  %20 = call i32 @cqrt_measure_i32(i32 %12)    ; IR: %16 = cq_measure_si32(%10)
  %21 = add nsw i32 %19, %20    ; IR: %17 = add nsw i32 %15, %16  (classical)
  ret i32 %21    ; IR: ret i32 %17  (llvm.lifetime.end is dropped, rule 16)
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare void @cqrt_addc_i32(i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
