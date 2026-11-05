; HAND-WRITTEN. Rules: 20 (b) (the union is a bus-resident alloca; union views and bit-fields need no rule), 16 (__cq_alloc),
; 5 (kept stores, the load un-copy), 2, 3, 4, 21, 25; §1.3 (the bus, __cq_mem, __cq_alloc).
; Checked: u.e after the exponent write-back (the load copy %17 of the 10 cells at &u, measured -> %18), and the cells of u
; read from the bus at exit: bytes 0..9 = the x87 pattern of x with bits 64..78 replaced by (exp(x) - k) & 0x7fff, bytes
; 10..11 = 0.
; Clean: the exponent arithmetic (%11 the sub, %12 the & 0x7fff, %13 the & -0x8000), uncomputed in LIFO order right after
; the or that reads them, and the load copy of the word at byte 8 (%10), un-copied after them, before the store of the new
; word (the next memory version change).
; Kept: x (%7, the rotated register, also the value rail of the kept store u.e = x); the new word (%14, the value rail of
; the kept store u.bits.exp = ...); the tape slots of the two stores (no handle: in the backend, holding the displaced
; cells); the load copy u.e (%17, measured).
; Rotations: (Ry, x, th, 1).
; Expected for f80_union_slot(0, .5, 1): x starts as the all-zero x87 pattern and Ry(.5) flips each of its 80 bits
; independently with probability sin^2(.25) = 0.061209. The stored word at byte 8 is bits 64..79 of x zero-extended
; (bytes 10, 11 of the fresh block are 0); its low 15 bits (the exponent) are replaced by exp - 1 mod 2^15, the sign and
; the zero high half are kept. With probability cos^2(.25)^80 = 0.006390 no bit flipped: exp 0 - 1 = 0x7fff, sign 0,
; mantissa 0 (integer bit 0: the x87 pseudo-infinity pattern 0x7fff_0000000000000000, returned as it stands).
; THE UNION IS MEMORY (rule 20). The alloca of u has a store of a rail among its users (u.e = x), so it is bus-resident by
; rule 20 (b): __cq_alloc(12, 16) at the alloca's program point (rule 16; one zeroed block), no alloca remains and the
; lifetime markers are dropped. Every access is one bus access of the type and at the address its instruction names
; (union views and bit-fields need no rule): store x86_fp80 is qram_store_f80_hl (10 cells at &u), the word load at
; byte 8 is qram_load_i32_hl (cells 8..11: bits 64..79 of the long double and two zero bytes of the block), the
; write-back is qram_store_i32_hl at the same address and the final read is qram_load_f80_hl at &u. The two
; getelementptrs have nothing tainted and stay; each address is the run-time ptrtoint of its pointer (classical).
; The word store is not rule 5's in-place form: its pointer (IR %12) is not the load's SSA pointer (IR %6), and the & 0x7fff step
; is no bijection. So the store is a KEPT store (rule 5 sentence 3): its tape slot and its value rail, the or %14, stay
; for the shot. The garbage under the or (sub, both ands) is uncomputed right after it, and the load copy, whose last
; reader is then the and's _unc, is un-copied before the store (sentence 1). The final f80 load is a fresh copy after
; the store; it is measured and stays allocated (rule 2). Nothing in the lowering asks whether the two accesses at byte 8
; and the accesses at &u overlap.
source_filename = "f80_union_slot.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @f80_union_slot(x86_fp80 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @__cq_mem()    ; IR: (none)  [m: the one bus, fetched once at function entry]
  %5 = call ptr @__cq_alloc(i64 12, i64 16)    ; IR: %4 = alloca [12 x i8], align 16: u is bus-resident (a rail is stored through it): a zeroed block, no alloca remains
  %6 = ptrtoint ptr %5 to i64    ; IR: the run-time address of u (classical)
  %7 = call i32 @cqrt_alloc_f80(x86_fp80 %0)    ; IR: %5 = cq_theta_f80(%0, %1)  [register x]
  call void @cqrt_ry_f80(i32 %7, double %1)    ; IR: %5 = cq_theta_f80(%0, %1)  [Ry]
  call void @cqrt_qram_store_f80_hl(i32 %4, i64 %6, i32 %7)    ; IR: store x86_fp80 %5, ptr %4: u.e = x  (kept store of 10 cells; llvm.lifetime.start is dropped)
  %8 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %6 = getelementptr inbounds i8, ptr %4, i64 8  (classical)
  %9 = ptrtoint ptr %8 to i64    ; IR: the run-time address of the word at byte 8 (classical)
  %10 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %9)    ; IR: %7 = load i32, ptr %6  (bus load of cells 8..11: a rail)
  %11 = call i32 @cq_template_sub_i32_hl(i32 %10, i32 %2)    ; IR: %8 = sub i32 %7, %2
  %12 = call i32 @cq_template_and_i32_hl(i32 %11, i32 32767)    ; IR: %9 = and i32 %8, 32767
  %13 = call i32 @cq_template_and_i32_hl(i32 %10, i32 -32768)    ; IR: %10 = and i32 %7, -32768
  %14 = call i32 @cq_template_or_i32(i32 %12, i32 %13)    ; IR: %11 = or disjoint i32 %9, %10  [the new word: the value rail of the kept store]
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %10, i32 -32768)    ; IR: uncompute %10
  call void @cqrt_free(i32 %13)    ; IR: release the %10 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %11, i32 32767)    ; IR: uncompute %9
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %11, i32 %10, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %11)    ; IR: release the %8 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %10, i32 %4, i64 %9)    ; IR: un-copy %7 (rule 5 sentence 1: its last reader precedes the store, the next memory version change)
  call void @cqrt_free(i32 %10)    ; IR: release the %7 rail (|0>)
  %15 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %12 = getelementptr inbounds i8, ptr %4, i64 8  (classical)
  %16 = ptrtoint ptr %15 to i64    ; IR: the run-time address of the word at byte 8 (classical)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %16, i32 %14)    ; IR: store i32 %11, ptr %12: u.bits.exp = ...  (kept store: tape slot and value rail %11 stay, no _unc)
  %17 = call i32 @cqrt_qram_load_f80_hl(i32 %4, i64 %6)    ; IR: %13 = load x86_fp80, ptr %4: u.e  (a fresh copy of the 10 cells after the store)
  %18 = call x86_fp80 @cqrt_measure_f80(i32 %17)    ; IR: %14 = cq_measure_f80(%13)  (the measured load copy stays allocated; llvm.lifetime.end is dropped)
  ret x86_fp80 %18    ; IR: ret x86_fp80 %14
}

declare i32 @__cq_mem()

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_f80(x86_fp80)

declare void @cqrt_ry_f80(i32, double)

declare void @cqrt_qram_store_f80_hl(i32, i64, i32)

declare i32 @cqrt_qram_load_i32_hl(i32, i64)

declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)

declare void @cqrt_qram_store_i32_hl(i32, i64, i32)

declare i32 @cqrt_qram_load_f80_hl(i32, i64)

declare i32 @cq_template_sub_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_or_i32(i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)

declare x86_fp80 @cqrt_measure_f80(i32)

declare void @cqrt_free(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
