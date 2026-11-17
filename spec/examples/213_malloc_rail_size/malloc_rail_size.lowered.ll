; HAND-WRITTEN. Rules: 16, 20, 21, 5, 2, 3.
; Checked: r = a[j & 1] (the load copy at the classical run-time address p + 4 * (j & 1), measured): x for j & 1 == 0
; (the cell a[0] the store wrote), 0 for j & 1 == 1 (zeroed __cq_alloc memory, never written: CR §6); the overflow
; predicate o = (n > K2).
; Clean: nothing is computed that has to be cleaned: the address of both accesses is classical (no address chain).
; Kept: n (rotated); x (rotated; also the value rail of the kept store a[0] = x) and that store's tape slot (rule 5
; sentence 3); o = icmp_ugt_i64_hl(n, K2), the overflow predicate, an output rail (rule 16, §0, §6); r (the load
; copy, measured: rule 2).
; Rotations: (Ry, n, tn, 1); (Ry, x, tx, 1).
; Drivers malloc_rail_size(8, .5, 9, .25, 1) and (8, .5, 9, .25, 0): Ry acts on every qubit of a register, so each of
; the 64 bits of n flips with probability p = sin^2(.25) = 0.061209 and each of the 32 bits of x with
; q = sin^2(.125) = 0.015544, independently. First call, j & 1 = 1: the load reads the cells P0+4..P0+7, which
; nothing wrote: measured r = 0 with probability 1, whatever n and x hold. Second call, j & 1 = 0: the load reads the
; stored cells P0..P0+3, so r = x: 9 with (1 - q)^32 = 0.605738, each single-bit neighbour of 9 with
; q (1 - q)^31 = 0.009564; x collapses with r, as in C. In both calls the kept rail o reads 1 iff n > 4096: a flipped
; bit among bits 13..63 (1 - (1 - p)^51 = 0.960096), or none of those, bit 12 flipped and the low 12 bits not all 0
; ((1 - p)^51 p (1 - p (1 - p)^11) = 0.002368): P(o = 1) = 0.962463. n is 8 with (1 - p)^64 = 0.017556.
; ALLOCATION AT A RAIL SIZE (rule 16, §0 K2). malloc(n) with n a rail is __cq_alloc(K2, 16): the block is K2 bytes
; whatever n holds, its header (the i64 at p - 8, written by __cq_alloc) holds K2, and the address is classical host
; code's result, so every later access through it is the _hl form. K2 is the built-in default 4096 here (no
; CQ_K2(malloc_rail_size, k) line, no flag); the lines that carry it are tagged [K2]. No range fact bounds n by K2,
; so the overflow predicate icmp_ugt_i64_hl(n, K2) is computed and KEPT: it is never uncomputed and never freed. n is
; not consumed otherwise: on the o = 1 branches the program differs from C only in that the block is K2 bytes.
; The store a[0] = x is a kept store at a classical address (the cells P0..P0+3 become QUANTUM, the rest of the
; block stays HOST zeros); the getelementptr of the load has no tainted operand and stays (rule 20), its run-time
; address is the _hl operand. free(a) emits nothing.
; SPEC GAP (rule 16): the position of the overflow predicate relative to __cq_alloc is not stated. Chosen: at the
; allocation's program point, right before the __cq_alloc call (it reads only n; nothing orders the two).
; SPEC GAP (§5, _tools/README.txt): only the loop cutoff K has a line tag; the tag of a K2 line is not stated. Chosen: [K2].
source_filename = "malloc_rail_size.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @malloc_rail_size(i64 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %7 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %6 = cq_theta_ul(%0, %1)  [register n]
  call void @cqrt_ry_i64(i32 %7, double %1)    ; IR: %6 = cq_theta_ul(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %7 = cq_theta_si32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %3)    ; IR: %7 = cq_theta_si32(%2, %3)  [Ry]
  %9 = call i32 @cq_template_icmp_ugt_i64_hl(i32 %7, i64 4096)    ; IR: %8 = call ptr @malloc(i64 %6)  [K2] [rule 16: the overflow predicate n > K2, a KEPT output rail]
  %10 = call ptr @__cq_alloc(i64 4096, i64 16)    ; IR: %8 = call ptr @malloc(i64 %6)  [K2] [rule 16: a rail size is allocated at K2 bytes; zeroed, never reused, K2 at p - 8]
  %11 = ptrtoint ptr %10 to i64    ; IR: %8 as its run-time address (classical)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %11, i32 %8)    ; IR: store i32 %7, ptr %8  [kept store at a classical address: its slot and its value rail x stay]
  %12 = and i32 %4, 1    ; IR: %9 = and i32 %4, 1  (classical)
  %13 = zext nneg i32 %12 to i64    ; IR: %10 = zext nneg i32 %9 to i64  (classical)
  %14 = getelementptr inbounds i32, ptr %10, i64 %13    ; IR: %11 = getelementptr inbounds i32, ptr %8, i64 %10  (nothing tainted: the getelementptr stays, rule 20)
  %15 = ptrtoint ptr %14 to i64    ; IR: %11 as its run-time address (classical)
  %16 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %15)    ; IR: %12 = load i32, ptr %11  [load copy at a classical run-time address; measured, so never un-copied]
  %17 = call i32 @cqrt_measure_i32(i32 %16)    ; IR: call void @free(ptr %8) is nothing (rule 16); %13 = cq_measure_si32(%12)
  ret i32 %17    ; IR: ret i32 %13
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i64(i32, double)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_icmp_ugt_i64_hl(i32, i64)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare i32 @cqrt_measure_i32(i32)
