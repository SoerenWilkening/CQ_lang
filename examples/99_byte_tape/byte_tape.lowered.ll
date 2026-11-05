; HAND-WRITTEN. Rules: 16, 20, 21, 5, 7, 8, 4, 2; §1.3 (the bus, __cq_mem, __cq_alloc); BACKEND_ABI §1.11.
; Checked: x (%8, measured -> %22, returned zero-extended).
; Clean: the zext of x (%9) and the predicate flag x > k (%19), uncomputed after the fputs entry; the |1> predicate seed
; of the fwrite entry (%17: never written, freed directly, rule 7); both load copies of stdout (%16, %20: un-copied
; right after their tape field, before their entry, the next memory version change: rule 5 sentence 1).
; Kept: the user register x (%8: rotated, measured, and the value rail of the kept store buf[0] = x); the rail x + 1
; (%10, the value rail of the kept store buf[1] = x + 1, rule 5 sentence 3); the seed 'z' (%13, the value rail of the
; kept store buf[2] = 'z', rule 7); the tape slots of those three stores (in the backend); the tape (%5) and its two
; write-only tape rails, the stream fields of the fwrite (%18) and fputs (%21) entries. Neither entry has a result rail
; (the program reads neither result: the bare form).
; Rotations: (Ry, x, th, 1).
; Expected: byte_tape(0, .5, 1): Ry(.5) acts on every qubit of the i8 rail x = 0, so each bit flips independently with
; probability s = sin^2(.25) = 0.061209; the measured value v is 0 with probability (1 - s)^8 = 0.603326. The output
; of the shot is the three bytes v, v + 1 (mod 256), 'z' (the fwrite), then "hi\n" iff v > 1, i.e. iff one of bits
; 1..7 of v is set: probability 1 - (1 - s)^7 = 0.357337. Both entries are deferred and performed at the end of the
; shot in sequence order; the bytes of buf the backend captured at the fwrite entry are copies of x and x + 1, so the
; printed bytes agree with the returned v on every shot.
; BUF (rule 20). The alloca [3 x i8] has stores of tainted values and a call among its users, so it is bus-resident
; (rule 20 b): __cq_alloc(3, 1) at the alloca's program point (align 1, the alloca's), no alloca remains, and the
; lifetime markers are dropped (rule 16). Its three byte stores are bus stores at classical addresses
; (qram_store_i8_hl; the getelementptrs have nothing tainted and stay, the address is the ptrtoint): buf[0] = x and
; buf[1] = x + 1 with their rails as values, buf[2] = 'z' with the seed alloc_i8(122). Every one is a KEPT store (rule 5
; sentence 3): its tape slot stays and so does its value rail, so the rail x + 1 is never uncomputed.
; STDOUT (rules 20, 21). `stdout` is `load ptr, ptr @__stdoutp`: @__stdoutp is a global that is not constant, so the
; load is a bus load at its host address ptrtoint (ptr @__stdoutp to i64) (nothing is allocated or seeded for it) and
; its result is a rail, the stream's address (a 64-bit rail, rule 21), although the cells are HOST. The load in block
; %13 lies under the quantum predicate x > k and is the _hl_controlled load; its un-copy takes the same control.
; HOST EFFECTS (rule 16). fwrite and fputs are stream calls with pointer arguments, so neither is an ordinary host
; call: each is ONE effect entry on the function's tape (one tape_alloc at entry). Its fields are its arguments in
; order: a pointer is its address (buf's run-time i64 and the constant @.str as _lit fields; the stream rail as a
; tape_write_i64 field), the classical sizes as i64 _lit fields. A buffer or string is never expanded into fields:
; what the backend reads from buf (two QUANTUM cells, one HOST cell holding 'z') and from @.str is BACKEND_ABI §1.11's
; capture at the entry. fwrite has no predicate in scope: a cqrt_alloc_i1(true) seed, freed right after the effect
; call. fputs is in block %13: its entry is under the flag x > k, which is uncomputed after the entry like any flag.
; SPEC GAP (rule 16, effect entry name): the -O1 callees are @"\01_fwrite" and @"\01_fputs" (Darwin's asm-label
; spellings), and "the callee's symbol name" does not say which spelling. Used: the C identifier the callee is declared
; by, i.e. the LLVM name with the leading "\01" asm-label marker and the target's global symbol prefix ("_" on Mach-O)
; removed: @.cq.effect.fwrite = "fwrite", @.cq.effect.fputs = "fputs".
source_filename = "byte_tape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdoutp = external local_unnamed_addr global ptr, align 8    ; IR: @__stdoutp  (stdout: a host global, on the bus at its host address)
@.str = private unnamed_addr constant [4 x i8] c"hi\0A\00", align 1    ; IR: @.str
@.cq.effect.fwrite = private unnamed_addr constant [7 x i8] c"fwrite\00", align 1    ; IR: effect entry name for fwrite (a host string): @.cq.effect.<name>, one per host callee, after the module's own globals  ; SPEC GAP: name of @"\01_fwrite" (header)
@.cq.effect.fputs = private unnamed_addr constant [6 x i8] c"fputs\00", align 1    ; IR: effect entry name for fputs  ; SPEC GAP: name of @"\01_fputs" (header)

define i32 @byte_tape(i8 noundef zeroext %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus m (once, at function entry)
  %5 = call i32 @cqrt_tape_alloc()    ; IR: the function's tape: one per function that records an entry, at function entry (the fwrite and fputs entries, one event sequence)
  %6 = call ptr @__cq_alloc(i64 3, i64 1)    ; IR: %4 = alloca [3 x i8], align 1: buf is bus-resident (tainted stores, a call argument): a zeroed block, no alloca remains (llvm.lifetime.start is dropped)
  %7 = ptrtoint ptr %6 to i64    ; IR: %4 as its run-time address: the _hl operand of buf[0] and the fwrite buffer field (classical)
  %8 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %5 = cq_theta_ui8(%0, %1)  [register x]
  call void @cqrt_ry_i8(i32 %8, double %1)    ; IR: %5 = cq_theta_ui8(%0, %1)  [Ry]
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %7, i32 %8)    ; IR: store i8 %5, ptr %4: buf[0] = x  (kept store at a classical address: tape slot and value rail x stay, no _unc)
  %9 = call i32 @cq_template_zext_i8_to_i32(i32 %8)    ; IR: %7 = zext i8 %5 to i32
  %10 = call i32 @cq_template_add_i8_hl(i32 %8, i8 1)    ; IR: %8 = add i8 %5, 1
  %11 = getelementptr inbounds i8, ptr %6, i64 1    ; IR: %6 = getelementptr inbounds i8, ptr %4, i64 1  [nothing tainted: the gep stays]
  %12 = ptrtoint ptr %11 to i64    ; IR: store i8 %8, ptr %6  [the classical address as its run-time i64]
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %12, i32 %10)    ; IR: store i8 %8, ptr %6: buf[1] = x + 1  (kept store: tape slot and value rail %8 stay, so %8 is never uncomputed)
  %13 = call i32 @cqrt_alloc_i8(i8 122)    ; IR: store i8 122, ptr %9: the classical value as a seed rail (rule 7), kept with its store
  %14 = getelementptr inbounds i8, ptr %6, i64 2    ; IR: %9 = getelementptr inbounds i8, ptr %4, i64 2  [nothing tainted: the gep stays]
  %15 = ptrtoint ptr %14 to i64    ; IR: store i8 122, ptr %9  [the classical address as its run-time i64]
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %15, i32 %13)    ; IR: store i8 122, ptr %9: buf[2] = 'z'  (kept store; classical-valued address and content: the cell stays HOST)
  %16 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 ptrtoint (ptr @__stdoutp to i64))    ; IR: %10 = load ptr, ptr @__stdoutp: stdout  (a bus load at the global's host address: a rail, the stream's address)
  %17 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: %11 = fwrite(%4, 1, 3, %10): no predicate in scope, the |1> seed
  call void @cqrt_tape_write_i64_lit(i32 %5, i64 %7)    ; IR: %11 = fwrite(%4, ...): argument 0, the buffer: a pointer is its address, classical: a _lit field (the buffer is not expanded into fields)
  call void @cqrt_tape_write_i64_lit(i32 %5, i64 1)    ; IR: %11 = fwrite(..., 1, ...): argument 1, the size: a classical i64 _lit field
  call void @cqrt_tape_write_i64_lit(i32 %5, i64 3)    ; IR: %11 = fwrite(..., 3, ...): argument 2, the count: a classical i64 _lit field
  %18 = call i32 @cqrt_tape_write_i64(i32 %5, i32 %16)    ; IR: %11 = fwrite(..., %10): argument 3, the stream: the address rail copied onto a fresh tape rail (kept)
  call void @cqrt_qram_load_i64_hl_unc(i32 %16, i32 %4, i64 ptrtoint (ptr @__stdoutp to i64))    ; IR: un-copy %10 (rule 5 sentence 1: its last reader is the tape field, before the entry, the next memory version change)
  call void @cqrt_free(i32 %16)    ; IR: release the %10 rail (|0>)
  call void @cqrt_tape_effect_controlled(i32 %17, i32 %5, ptr @.cq.effect.fwrite)    ; IR: %11 = fwrite(%4, 1, 3, %10): the effect entry, complete after its fields; bare form, the result %11 is unused. The backend captures buf's cells here (BACKEND_ABI §1.11)
  call void @cqrt_free(i32 %17)    ; IR: release the seed (|1>, never written: freed directly, rule 7); the backend read the predicate at the effect call
  %19 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %9, i32 %2)    ; IR: %12 = icmp sgt i32 %7, %2  [path predicate of block %13]
  %20 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %19, i32 %4, i64 ptrtoint (ptr @__stdoutp to i64))    ; IR: block %13: %14 = load ptr, ptr @__stdoutp: stdout  (a bus load under the predicate)
  call void @cqrt_tape_write_i64_lit(i32 %5, i64 ptrtoint (ptr @.str to i64))    ; IR: %15 = fputs(@.str, ...): argument 0, the string: its address, a _lit field (the string is not expanded into fields)
  %21 = call i32 @cqrt_tape_write_i64_controlled(i32 %19, i32 %5, i32 %20)    ; IR: %15 = fputs(..., %14): argument 1, the stream rail copied under the predicate onto a fresh tape rail (kept)
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %20, i32 %19, i32 %4, i64 ptrtoint (ptr @__stdoutp to i64))    ; IR: un-copy %14 under the predicate it was loaded with (rule 5 sentence 1: before the entry)
  call void @cqrt_free(i32 %20)    ; IR: release the %14 rail (|0>)
  call void @cqrt_tape_effect_controlled(i32 %19, i32 %5, ptr @.cq.effect.fputs)    ; IR: block %13: %15 = fputs(@.str, %14): the effect entry under the predicate; bare form, the result %15 is unused
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %19, i32 %9, i32 %2)    ; IR: uncompute %12 (the backend captured it at the entry)
  call void @cqrt_free(i32 %19)    ; IR: release the %12 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %9, i32 %8)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  %22 = call i8 @cqrt_measure_i8(i32 %8)    ; IR: %17 = cq_measure_ui8(%5)
  %23 = zext i8 %22 to i32    ; IR: %18 = zext i8 %17 to i32  (classical; llvm.lifetime.end is dropped)
  ret i32 %23    ; IR: ret i32 %18
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i64(i32, i32)
declare i32 @cqrt_tape_write_i64_controlled(i32, i32, i32)
declare void @cqrt_tape_write_i64_lit(i32, i64)
declare void @cqrt_tape_effect_controlled(i32, i32, ptr)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i8(i32, double)
declare i8 @cqrt_measure_i8(i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_add_i8_hl(i32, i8)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}
!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
