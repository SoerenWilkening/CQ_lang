; HAND-WRITTEN. Rules: 16, 20, 5, 7, 4, 3, 2; §1.3 (the bus, __cq_mem, __cq_alloc); BACKEND_ABI §1.11 (the INPUT rows).
; Checked: buf[0] (the load copy %18, measured -> %19, returned sign-extended), read from the bus at buf's address.
; Clean: the length rail n & 7 (%14, uncomputed after the entry that copied it and freed) and the |1> predicate seed of
; the fgets entry (%15: never written, freed directly, rule 7).
; Kept: n (%10) and x (%11), the rotated registers (x is only printed, never measured by the program); the tape (%7)
; and its two write-only tape rails, the printf field (%13, a copy of x) and the fgets length field (%16, a copy of
; n & 7); the store `buf = {0}`: its tape slot (in the backend) and its value rail, the seed %12 (rules 5, 7); the
; load copy of buf[0] (%18, measured: rule 2's measured rail). The fgets entry has no result rail (the program does
; not read fgets' result: the bare form).
; Rotations: (Ry, n, tn, 1); (Ry, x, tx, 1).
; Expected: input_behind_output(3, .5, 4, .25, stdin). Ry(.5) acts on every qubit of the i32 rail n = 3, so each bit
; flips independently with probability s = sin^2(.25) = 0.0612087; the length is the low three bits of n (011 at the
; start). C's fgets(buf, len, f) stores at most len - 1 bytes of the next input line and a NUL, so with c the first
; byte of that line buf[0] = c iff len >= 2, i.e. unless bits 2 and 1 of n are both 0: the measured value is c with
; probability 1 - (1 - s) s = 0.942538 and 0 with probability 0.057462 (0 on every shot when the stream is at end of
; file: buf was zeroed). For c != 0 the measurement leaves n on the matching side of `(n & 6) != 0`. The stream loses
; the whole next line (up to K2 - 1 bytes) on every branch, not the at most 2 bytes C reads at n = 3. The output of
; the shot is the decimal of x and a newline, x from 4 with s' = sin^2(.125) = 0.0155438 per bit: "4\n" with
; probability (1 - s')^32 = 0.605738; it is printed at the end of the shot, after the input was read.
; INPUT IS NEVER HELD BEHIND A DEFERRED OUTPUT (rule 16, BACKEND_ABI §1.11). printf("%d\n", x) has a rail field: a
; format entry (47), an OUTPUT call with a quantum field, which the backend defers to the end of the shot. fgets is a
; stream call with a pointer argument and a rail argument: an EFFECT ENTRY, and it is the same ONE call it would be
; anywhere else: its three arguments as fields in order (the buffer's address as an i64 literal, the length rail as a
; tape_write_i32 field, the stream's address as an i64 literal), then cqrt_tape_effect_controlled under a
; cqrt_alloc_i1(true) seed with the host name "fgets". The lowered program does not say that the call is an input
; call, does not test what precedes it and names no K2: the backend knows by `name` that fgets is an INPUT call, which
; field is the buffer and which the length, and performs it AT THE CALL although the printf entry before it is
; unresolved: ONE host call at its own bound K2 into a temporary classical buffer, then for each value v the length
; rail can take the bytes fgets with length v would have stored from that input (the first min(v - 1, len) bytes and
; a NUL for v >= 1, nothing for v = 0), bus-stored under n & 7 = v (stores the backend makes: the cells of buf become
; QUANTUM, entangled with n). The input consumed is that of the K2 call on every branch (a stated deviation from the
; C program). Only the order of outputs is kept.
; The tape is the function's: one tape_alloc at function entry, both entries on it in call order; an entry's fields
; are those written since the previous entry. The |1> seed is read by the backend at the effect call like `name`
; (never again), so it is rule 7's seed and is freed directly after the call.
; buf. The alloca has a call among its users, so it is bus-resident (rule 20 b): __cq_alloc(8, 8) at the alloca's
; program point, no alloca remains, the lifetime markers are dropped. `char buf[8] = {0}` is -O1's one `store i64 0`:
; one kept bus store of the seed alloc_i64(0) at the block's address (rule 5 sentence 3, rule 7). The effect entry is
; a memory version change; `buf[0]` after it is a plain bus load, a rail whatever the cell holds (rule 3), measured.
source_filename = "input_behind_output.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1    ; IR: @.str
@.cq.effect.fgets = private unnamed_addr constant [6 x i8] c"fgets\00", align 1    ; IR: effect entry name for fgets (a host string): @.cq.effect.<name>, one per host callee, after the module's own globals

define i32 @input_behind_output(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, ptr noundef %4) {
  %6 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %7 = call i32 @cqrt_tape_alloc()    ; IR: the function's tape : one per function that records an entry, at function entry (the printf entry and the fgets entry, one event sequence)
  %8 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %6 = alloca [8 x i8], align 8: buf is bus-resident (it is a call argument): a zeroed block, no alloca remains
  %9 = ptrtoint ptr %8 to i64    ; IR: the address of buf as the _hl operand and as the entry's field (classical, run time)
  %10 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_ui32(%0, %1)  [register n]
  call void @cqrt_ry_i32(i32 %10, double %1)    ; IR: %7 = cq_theta_ui32(%0, %1)  [Ry]
  %11 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %8 = cq_theta_si32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %11, double %3)    ; IR: %8 = cq_theta_si32(%2, %3)  [Ry]
  %12 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: store i64 0, ptr %6: the classical value as a seed rail (rule 7; llvm.lifetime.start is dropped)
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %9, i32 %12)    ; IR: store i64 0, ptr %6: buf = {0}  (kept store at a classical address: tape slot and seed stay, no _unc)
  call void @cqrt_tape_fmt(i32 %7, ptr @.str)    ; IR: %9 = printf(@.str, %8): the format entry (no predicate in scope; the count %9 is unused)
  %13 = call i32 @cqrt_tape_write_i32(i32 %7, i32 %11)    ; IR: %9 = printf(..., %8): field 0, the rail x copied onto a fresh tape rail (kept): the backend defers the entry
  %14 = call i32 @cq_template_and_i32_hl(i32 %10, i32 7)    ; IR: %10 = and i32 %7, 7
  %15 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: %11 = fgets(%6, %10, %4): no predicate in scope, the |1> seed
  call void @cqrt_tape_write_i64_lit(i32 %7, i64 %9)    ; IR: %11 = fgets(%6, ...): argument 0, the buffer: a pointer is its address, classical: a _lit field (the buffer is not expanded into fields)
  %16 = call i32 @cqrt_tape_write_i32(i32 %7, i32 %14)    ; IR: %11 = fgets(..., %10, ...): argument 1, the length rail copied onto a fresh tape rail (kept)
  %17 = ptrtoint ptr %4 to i64    ; IR: the stream's address (a host FILE, classical)
  call void @cqrt_tape_write_i64_lit(i32 %7, i64 %17)    ; IR: %11 = fgets(..., %4): argument 2, the stream: its address, a _lit field
  call void @cqrt_tape_effect_controlled(i32 %15, i32 %7, ptr @.cq.effect.fgets, i32 3)    ; IR: %11 = fgets(%6, %10, %4): the effect entry, complete after its fields; bare form, the result %11 is unused. The backend performs the input here, one host call at its K2, behind the deferred printf, and stores what fgets with length v would have stored under %10 = v (a memory version change)
  call void @cqrt_free(i32 %15)    ; IR: release the seed (|1>, never written: freed directly, rule 7); the backend read the predicate at the effect call (BACKEND_ABI §1.11) and does not use this handle again
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %10, i32 7)    ; IR: uncompute %10 (its last consumer is the entry; the tape rail %16 keeps the copy)
  call void @cqrt_free(i32 %14)    ; IR: release the %10 rail (|0>)
  %18 = call i32 @cqrt_qram_load_i8_hl(i32 %6, i64 %9)    ; IR: %12 = load i8, ptr %6: buf[0]  (a bus load after the input: a fresh rail of the cell the backend stored)
  %19 = call i8 @cqrt_measure_i8(i32 %18)    ; IR: %13 = cq_measure_c(%12)  (the measured load copy stays allocated; llvm.lifetime.end is dropped)
  %20 = sext i8 %19 to i32    ; IR: %14 = sext i8 %13 to i32  (classical: the outcome)
  ret i32 %20    ; IR: ret i32 %14
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_tape_alloc()
declare void @cqrt_tape_fmt(i32, ptr)
declare i32 @cqrt_tape_write_i32(i32, i32)
declare void @cqrt_tape_write_i64_lit(i32, i64)
declare void @cqrt_tape_effect_controlled(i32, i32, ptr, i32)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i8 @cqrt_measure_i8(i32)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
