; HAND-WRITTEN. Rules: 21, 20, 16, 9, 5, 7, 4, 2.
; Checked: *q + v, q = (int *)((uintptr_t)((x & 1) ? a : b) ^ (x & 4)) (measured, %19 -> %20):
; (x & 1 ? a : b)[(x & 4) >> 2] + v.
; Clean: the pointer rails (the flag x & 1 == 0 %13 and its operand %12, the pointer select p %14, x & 4 %15, its
; zext %16, the address rail u' = q %17), uncomputed and freed in reverse; the load copy *q (%18), un-copied right
; after its last reader, the add: no memory version change follows the load.
; Kept: the user register x (%7); the result rail (%19, measured); by rule 5, for the shot: the tape slots of the two
; initializer stores (a = {1, 2}, b = {3, 4}) and their seed value rails %9 and %11 (classical-valued, no qubit, §0).
; Rotations: (Ry, x, th, 1).
; Expected: ptr_roundtrip(0, .5, 3). Ry(.5) acts on every qubit of x = 0 and everything after it is a basis permutation:
; bit 0 and bit 2 of x are each 1 with p = sin^2(.25) = 0.061209. bit 0 = 0 selects b, bit 2 the cell [1]: the
; measured value is b[0] + 3 = 6 with probability 0.881329, b[1] + 3 = 7 and a[0] + 3 = 4 with 0.057462 each, and
; a[1] + 3 = 5 with 0.003747.
; A POINTER IS AN INTEGER (rule 21). a and b are BUS-RESIDENT (rule 20 (b)): a select of their addresses is among
; their users, which no host-resident alloca allows, so each is __cq_alloc(8, 8) at its alloca's program point (rule
; 16; 8-aligned, as the -O1 alloca) and the lifetime markers are dropped. Their -O1 initializers are each one i64 bus
; store at the block's classical address, its value the i64 seed of the constant (rule 7): kept stores (rule 5). The
; pointer select p = (x & 1) ? a : b is under a quantum flag, so it is select_i64_ll over the two run-time addresses
; as classical i64 arms (rule 21, Merge; rule 9): ONE 64-bit address rail, with nothing else attached (no object,
; tag or base). ptrtoint and inttoptr are identities at 64 bits (rule 21, Arithmetic): they emit nothing and u, u'
; and q are that same kind of rail. The `or disjoint` that -O1 made of the C xor is the ordinary i64 template (rule 4)
; on the address rail and the zext of x & 4. The deref *q is ONE qram_load_i32 at the address rail q (rule 21,
; Dereference): no guard, no bounds check and no decoding of which object q lies in. Because the blocks are 8-aligned
; and 8 bytes long, q is &a[0], &a[1], &b[0] or &b[1] on every branch, but the lowering never asks. The load copy is
; read only by the add, whose result is measured (no _unc to wait for), and no memory version change follows, so it is
; un-copied right after the add (rule 5, sentence 1); the address rail outlives that un-copy and is then uncomputed
; with the rest of the pointer chain, in reverse, before the measurement.
source_filename = "ptrtoint_inttoptr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @ptr_roundtrip(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (called once, at function entry)
  %5 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %4 = alloca [2 x i32], align 8: a is bus-resident (its address is selected under a quantum flag)
  %6 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %5 = alloca [2 x i32], align 8: b is bus-resident
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = ptrtoint ptr %5 to i64    ; IR: the run-time address of a (classical)
  %9 = call i32 @cqrt_alloc_i64(i64 8589934593)    ; IR: store i64 8589934593, ptr %4: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %8, i32 %9)    ; IR: store i64 8589934593, ptr %4: a = {1, 2}  (kept store, classical address)
  %10 = ptrtoint ptr %6 to i64    ; IR: the run-time address of b (classical)
  %11 = call i32 @cqrt_alloc_i64(i64 17179869187)    ; IR: store i64 17179869187, ptr %5: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %10, i32 %11)    ; IR: store i64 17179869187, ptr %5: b = {3, 4}  (kept store, classical address)
  %12 = call i32 @cq_template_and_i32_hl(i32 %7, i32 1)    ; IR: %7 = and i32 %6, 1
  %13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %12, i32 0)    ; IR: %8 = icmp eq i32 %7, 0
  %14 = call i32 @cq_template_select_i64_ll(i32 %13, i64 %10, i64 %8)    ; IR: %9 = select i1 %8, ptr %5, ptr %4: p, a 64-bit address rail (&b or &a as i64 arms)
  %15 = call i32 @cq_template_and_i32_hl(i32 %7, i32 4)    ; IR: %11 = and i32 %6, 4  (%10 = ptrtoint ptr %9 to i64 is the identity: u is the rail %9)
  %16 = call i32 @cq_template_zext_i32_to_i64(i32 %15)    ; IR: %12 = zext nneg i32 %11 to i64
  %17 = call i32 @cq_template_or_i64(i32 %14, i32 %16)    ; IR: %13 = or disjoint i64 %10, %12  [the address rail u' = q]
  %18 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %17)    ; IR: %15 = load i32, ptr %14: *q, one bus load at the address rail (%14 = inttoptr i64 %13 to ptr is the identity)
  %19 = call i32 @cq_template_add_i32_hl(i32 %18, i32 %2)    ; IR: %16 = add nsw i32 %15, %2  [result rail]
  call void @cqrt_qram_load_i32_unc(i32 %18, i32 %4, i32 %17)    ; IR: un-copy %15 (no memory version change since the load; its reader %16 is measured)
  call void @cqrt_free(i32 %18)    ; IR: release the %15 rail (|0>)
  call void @cq_template_or_i64_unc(i32 %17, i32 %14, i32 %16)    ; IR: uncompute %13 (the address rail outlived its load's un-copy)
  call void @cqrt_free(i32 %17)    ; IR: release the %13 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %16, i32 %15)    ; IR: uncompute %12
  call void @cqrt_free(i32 %16)    ; IR: release the %12 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %7, i32 4)    ; IR: uncompute %11
  call void @cqrt_free(i32 %15)    ; IR: release the %11 rail (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %14, i32 %13, i64 %10, i64 %8)    ; IR: uncompute the pointer %9
  call void @cqrt_free(i32 %14)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %13, i32 %12, i32 0)    ; IR: uncompute %8
  call void @cqrt_free(i32 %13)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %7, i32 1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %12)    ; IR: release the %7 rail (|0>)
  %20 = call i32 @cqrt_measure_i32(i32 %19)    ; IR: %17 = cq_measure_si32(%16)
  ret i32 %20    ; IR: ret i32 %17
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_or_i64(i32, i32)
declare void @cq_template_or_i64_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
