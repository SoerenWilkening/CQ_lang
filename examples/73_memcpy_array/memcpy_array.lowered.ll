; HAND-WRITTEN. Rules: 20, 22, 21, 16, 14, 5, 6, 7, 4, 2.
; Checked: memcpy_classical: a[0] + a[3] (the add rail %33, measured -> %34) after memcpy(a, src) and a[x & 3] += 1;
; the cells of a at exit, read from the bus at the block's address: a[i] = src[i] + (i == (x & 3)).
; memcpy_quantum: a[1] + b[1] (the add rail %47, measured -> %48) with a[i] = x + i, b a byte copy of a and
; b[y & 3] = c; the cells at exit: a[i] = x + i, b[i] = (i == (y & 3)) ? c : x + i.
; Clean: memcpy_classical: the address chain of &a[x & 3] (and / zext / mul / add, %22..%25), uncomputed and freed
; right after the second swap of the in-place form; the three rails of the in-place form (the swap rail %26, the
; rule-6 inverse %28, the updated rail %27); the load copies a[0] and a[3] (%29, %32), un-copied after the add: no
; memory version change follows them. memcpy_quantum: the old x rail (%11, rule 6 In a
; rolled loop: the fill a[i] = x + i is a bijection in x read by every trip, so x is cleaned on the fill loop's exit
; edge from the last trip's image, t = (x + 3) - 3 (%22), copy into x, t uncomputed, both freed; the loop runs 4 trips,
; so no zero-trip path exists); the address chain of &b[y & 3] (%36..%39), uncomputed and freed right after the store;
; the load copies a[1] and b[1] (%43, %46), un-copied after the add.
; Kept: memcpy_classical: x (%8, the rotated register); the 16 byte load copies of src (%12 per trip), each the value
; rail of a kept byte store (rule 5, sentences 1 and 3; classical-valued, so no qubit, §0); the tape slots of the 16
; byte stores; the sum (%33, measured). The in-place form itself keeps nothing. memcpy_quantum: y (%12, the rotated
; register); the four fill rails x + i (%16 per trip), each the value rail of a kept store (rule 5 sentence
; 3), so the fill loop pushes nothing and has no reverse loop (rule 14); the 16 byte load copies of a (%26 per trip),
; each the value rail of a kept byte store into b; the seed c (%40), the value rail of the kept store b[y & 3] = c;
; the tape slots of the 4 + 16 + 1 stores; the sum (%47, measured).
; Rotations: memcpy_classical: (Ry, x, th, 1). memcpy_quantum: (Ry, x, tx, 1); (Ry, y, ty, 1).
; Expected: memcpy_classical(0, .5, icoef) with icoef = {1, 2, 3, 4}: each bit of x flips with p = sin^2(.25) =
; 0.061209, so x & 3 is 0 or 3 with 0.885076 and the measured value is 1 + 4 + 1 = 6, otherwise (0.114924) 5.
; memcpy_quantum(0, 1, .5, .25, 9): y & 3 = 1 with (1 - sin^2(.125))^2 = 0.969154 and then the value is (x + 1) + 9
; (10 when x stays 0, cos^2(.25)^32 = 0.132498 of that branch); otherwise it is 2 * (x + 1).
; ONE BUS (rule 20). Every alloca here is BUS-RESIDENT: memcpy_classical's a is the destination of a copy from a
; pointer argument (not a host-resident source) and is indexed by a rail; memcpy_quantum's a takes stores of rails
; (x + i) and is the source of a copy into a bus-resident b; b is indexed by a rail. Each is __cq_alloc(16, 16) at the
; alloca's program point (rule 16), no alloca remains, and the lifetime markers are dropped. m = __cq_mem() is called
; once at function entry (§5); a pointer argument's run-time address (src) is its ptrtoint, placed once after it (206).
; Nothing is known about an address: the bases are run-time i64s, and a getelementptr with a tainted index is 64-bit
; template arithmetic into an address rail (the index rail, -O1's zext, mul_i64_hl by 4, add_i64_hl of the run-time
; base); a getelementptr with constant indices stays and its ptrtoint is the _hl address. Every other word load is
; one qram_load_i32[_hl] and every other word store one qram_store_i32[_hl]; the load/store pair of a[x & 3] += 1 is
; the in-place swap pair below, a memcpy is byte accesses (below), and a classical stored value is first its seed
; (rule 7).
; MEMCPY (rule 22): each llvm.memcpy of 16 bytes into a bus-resident destination is a byte copy on the bus, a host
; loop of 16 qram_load_i8_hl at the source address that pushes each byte's load copy on cqrt_push, then a host loop of
; 16 qram_store_i8_hl at the destination that pops them (bytes 15 down to 0; a copy has no direction), never widened
; into word accesses and never unrolled. Each byte store is a kept store: its tape slot and its value rail (the load
; copy) stay. In memcpy_classical the source src is the host array the caller passed (HOST cells through the overlay,
; nothing seeded); in memcpy_quantum the source cells of a are QUANTUM (x + i) and the byte copies carry them into b.
; IN-PLACE FORM (rules 5, 6): a[x & 3] += 1 is load; add 1; store through the same SSA pointer with no memory version
; change between, so it is emitted at the store's position as swap-out into a fresh |0> rail, the add with rule 6's
; clean of the old rail (t = y' - 1, copy, _unc), swap-in; the address rail is template garbage, uncomputed right after
; the second swap. No copy of the cell, tape slot or old value remains. b[y & 3] = c is a plain kept store at an
; address rail: its seed and tape slot stay. The loads a[0], a[3], a[1], b[1] are bus loads at classical addresses,
; each un-copied after the add that reads it (its last reader), before the measurement of the sum.
source_filename = "memcpy_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @memcpy_classical(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %5 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %4 = alloca [4 x i32], align 16  [a is bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %6 = ptrtoint ptr %5 to i64    ; IR: (no instruction) the run-time address of a, a classical i64 (rule 21)
  %7 = ptrtoint ptr %2 to i64    ; IR: (no instruction) src: the run-time address in %2, a classical i64 (rule 21)
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  br label %9    ; IR: llvm.lifetime.start(16, %4) dropped (rule 16); llvm.memcpy(%4, %2, 16)  [rule 22: load all 16 source bytes, then store all 16]

9:
  %10 = phi i64 [ 0, %3 ], [ %13, %9 ]    ; IR: llvm.memcpy: byte index of the load loop (classical)
  %11 = add i64 %7, %10    ; IR: llvm.memcpy: the source byte's address src + j (classical)
  %12 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %11)    ; IR: llvm.memcpy: source byte j (a bus load of a HOST cell; the copy is the value rail of byte j's store, KEPT, rule 5)
  call void @cqrt_push(i32 %12)    ; IR: llvm.memcpy: hand the byte rail to the store loop (rule 22)
  %13 = add nuw nsw i64 %10, 1
  %14 = icmp eq i64 %13, 16
  br i1 %14, label %15, label %9

15:
  %16 = phi i64 [ 16, %9 ], [ %17, %15 ]    ; IR: llvm.memcpy: bytes left to store (classical)
  %17 = add nsw i64 %16, -1    ; IR: llvm.memcpy: byte index of this store, 15 down to 0 (the pop order)
  %18 = call i32 @cqrt_pop()    ; IR: llvm.memcpy: the load copy of byte %17
  %19 = add i64 %6, %17    ; IR: llvm.memcpy: the destination byte's address a + j (classical)
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %19, i32 %18)    ; IR: llvm.memcpy: destination byte j  (a kept store, rule 5; classical-valued, the cell stays HOST)
  %20 = icmp eq i64 %17, 0
  br i1 %20, label %21, label %15

21:
  %22 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)    ; IR: %6 = and i32 %5, 3
  %23 = call i32 @cq_template_zext_i32_to_i64(i32 %22)    ; IR: %7 = zext nneg i32 %6 to i64
  %24 = call i32 @cq_template_mul_i64_hl(i32 %23, i64 4)    ; IR: %8 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %7  [the tainted index scaled by the element size (rule 20)]
  %25 = call i32 @cq_template_add_i64_hl(i32 %24, i64 %6)    ; IR: %8 = getelementptr  [+ the run-time base: the address rail of &a[x & 3]]
  %26 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %9 = load i32, ptr %8 ... store i32 %10, ptr %8: the in-place form (rule 5), a fresh |0> rail
  call void @cqrt_qram_swap_i32(i32 %4, i32 %25, i32 %26)    ; IR: %9 = load i32, ptr %8: swap out: the rail holds a[x & 3], the cell |0>
  %27 = call i32 @cq_template_add_i32_hl(i32 %26, i32 1)    ; IR: %10 = add nsw i32 %9, 1
  %28 = call i32 @cq_template_sub_i32_hl(i32 %27, i32 1)    ; IR: rule 6: t = y' - 1 recomputes the old value (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %28, i32 %26)    ; IR: rule 6: the old rail ^= t: now |0>
  call void @cq_template_sub_i32_hl_unc(i32 %28, i32 %27, i32 1)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %28)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %26)    ; IR: release the old rail (|0> after the copy)
  call void @cqrt_qram_swap_i32(i32 %4, i32 %25, i32 %27)    ; IR: store i32 %10, ptr %8: swap in: the cell holds a[x & 3] + 1, the rail |0>
  call void @cqrt_free(i32 %27)    ; IR: release the %10 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %25, i32 %24, i64 %6)    ; IR: uncompute %8  [the second swap was the address rail's last reader (rule 20)]
  call void @cqrt_free(i32 %25)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %24, i32 %23, i64 4)    ; IR: uncompute %8 (the scaled index)
  call void @cqrt_free(i32 %24)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %23, i32 %22)    ; IR: uncompute %7
  call void @cqrt_free(i32 %23)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %22, i32 %8, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %22)    ; IR: release the %6 rail (|0>)
  %29 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %6)    ; IR: %11 = load i32, ptr %4: a[0]  (bus load at a classical address: a rail)
  %30 = getelementptr inbounds i8, ptr %5, i64 12    ; IR: %12 = getelementptr inbounds i8, ptr %4, i64 12  (classical)
  %31 = ptrtoint ptr %30 to i64    ; IR: (no instruction) the run-time address of a[3] (classical)
  %32 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %31)    ; IR: %13 = load i32, ptr %12: a[3]
  %33 = call i32 @cq_template_add_i32(i32 %32, i32 %29)    ; IR: %14 = add nsw i32 %13, %11  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %32, i32 %4, i64 %31)    ; IR: un-copy %13 (no memory version change since the load)
  call void @cqrt_free(i32 %32)    ; IR: release the %13 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %29, i32 %4, i64 %6)    ; IR: un-copy %11
  call void @cqrt_free(i32 %29)    ; IR: release the %11 rail (|0>)
  %34 = call i32 @cqrt_measure_i32(i32 %33)    ; IR: %15 = cq_measure_si32(%14)
  ret i32 %34    ; IR: llvm.lifetime.end(16, %4) dropped (rule 16); ret i32 %15
}

define i32 @memcpy_quantum(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %7 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %6 = alloca [4 x i32], align 16  [a is bus-resident: it takes stores of rails (rules 16, 20)]
  %8 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %7 = alloca [4 x i32], align 16  [b is bus-resident: indexed by a rail]
  %9 = ptrtoint ptr %7 to i64    ; IR: (no instruction) the run-time address of a (classical)
  %10 = ptrtoint ptr %8 to i64    ; IR: (no instruction) the run-time address of b (classical)
  %11 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_ui32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %11, double %2)    ; IR: %8 = cq_theta_ui32(%0, %2)  [Ry]
  %12 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %9 = cq_theta_ui32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %12, double %3)    ; IR: %9 = cq_theta_ui32(%1, %3)  [Ry]
  br label %13    ; IR: llvm.lifetime.start of %6 and %7 dropped (rule 16); br label %20

13:
  %14 = phi i64 [ 0, %5 ], [ %19, %13 ]    ; IR: %21 = phi i64 [ 0, %5 ], [ %25, %20 ]  (classical i)
  %15 = trunc nuw nsw i64 %14 to i32    ; IR: %22 = trunc nuw nsw i64 %21 to i32  (classical)
  %16 = call i32 @cq_template_add_i32_hl(i32 %11, i32 %15)    ; IR: %23 = add i32 %8, %22  [a[i]'s value rail: the value rail of a kept store, so not pushed (rule 14)]
  %17 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %14    ; IR: %24 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %21  (classical)
  %18 = ptrtoint ptr %17 to i64    ; IR: (no instruction) the run-time address of a[i] (classical)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %18, i32 %16)    ; IR: store i32 %23, ptr %24: a[i] = x + i  (a kept store: its tape slot and value rail stay, rule 5)
  %19 = add nuw nsw i64 %14, 1    ; IR: %25 = add nuw nsw i64 %21, 1  (classical)
  %20 = icmp eq i64 %19, 4    ; IR: %26 = icmp eq i64 %25, 4  (classical bound)
  br i1 %20, label %21, label %13    ; IR: br i1 %26, label %10, label %20  [no reverse loop: every trip rail is kept]

21:
  %22 = call i32 @cq_template_sub_i32_hl(i32 %16, i32 %15)    ; IR: rule 6 on the exit edge: t = (x + i) - i of the last trip (i = 3) recomputes x
  call void @cqrt_copy_i32(i32 %22, i32 %11)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_sub_i32_hl_unc(i32 %22, i32 %16, i32 %15)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %22)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %11)    ; IR: release the old x rail (|0> after the copy)
  br label %23    ; IR: br i1 %26, label %10  (the loop exit)

23:
  %24 = phi i64 [ 0, %21 ], [ %27, %23 ]    ; IR: llvm.memcpy(%7, %6, 16): byte index of the load loop (classical)  [rule 22: load all 16 source bytes, then store all 16]
  %25 = add i64 %9, %24    ; IR: llvm.memcpy: the source byte's address a + j (classical)
  %26 = call i32 @cqrt_qram_load_i8_hl(i32 %6, i64 %25)    ; IR: llvm.memcpy: source byte j of a (a QUANTUM cell; the copy is the value rail of byte j's store, KEPT, rule 5)
  call void @cqrt_push(i32 %26)    ; IR: llvm.memcpy: hand the byte rail to the store loop (rule 22)
  %27 = add nuw nsw i64 %24, 1
  %28 = icmp eq i64 %27, 16
  br i1 %28, label %29, label %23

29:
  %30 = phi i64 [ 16, %23 ], [ %31, %29 ]    ; IR: llvm.memcpy: bytes left to store (classical)
  %31 = add nsw i64 %30, -1    ; IR: llvm.memcpy: byte index of this store, 15 down to 0 (the pop order)
  %32 = call i32 @cqrt_pop()    ; IR: llvm.memcpy: the load copy of byte %31
  %33 = add i64 %10, %31    ; IR: llvm.memcpy: the destination byte's address b + j (classical)
  call void @cqrt_qram_store_i8_hl(i32 %6, i64 %33, i32 %32)    ; IR: llvm.memcpy: destination byte j of b  (a kept store, rule 5)
  %34 = icmp eq i64 %31, 0
  br i1 %34, label %35, label %29

35:
  %36 = call i32 @cq_template_and_i32_hl(i32 %12, i32 3)    ; IR: %11 = and i32 %9, 3
  %37 = call i32 @cq_template_zext_i32_to_i64(i32 %36)    ; IR: %12 = zext nneg i32 %11 to i64
  %38 = call i32 @cq_template_mul_i64_hl(i32 %37, i64 4)    ; IR: %13 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %12  [the tainted index scaled by the element size (rule 20)]
  %39 = call i32 @cq_template_add_i64_hl(i32 %38, i64 %10)    ; IR: %13 = getelementptr  [+ the run-time base: the address rail of &b[y & 3]]
  %40 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: store i32 %4, ptr %13: the value seed c (rule 7; kept with the store)
  call void @cqrt_qram_store_i32(i32 %6, i32 %39, i32 %40)    ; IR: store i32 %4, ptr %13: b[y & 3] = c  (a kept store at an address rail, rule 5)
  call void @cq_template_add_i64_hl_unc(i32 %39, i32 %38, i64 %10)    ; IR: uncompute %13  [the store was the address rail's last reader (rules 5, 20)]
  call void @cqrt_free(i32 %39)    ; IR: release the %13 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %38, i32 %37, i64 4)    ; IR: uncompute %13 (the scaled index)
  call void @cqrt_free(i32 %38)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %37, i32 %36)    ; IR: uncompute %12
  call void @cqrt_free(i32 %37)    ; IR: release the %12 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %36, i32 %12, i32 3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %36)    ; IR: release the %11 rail (|0>)
  %41 = getelementptr inbounds i8, ptr %7, i64 4    ; IR: %14 = getelementptr inbounds i8, ptr %6, i64 4  (classical)
  %42 = ptrtoint ptr %41 to i64    ; IR: (no instruction) the run-time address of a[1] (classical)
  %43 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %42)    ; IR: %15 = load i32, ptr %14: a[1]  (bus load at a classical address: a rail)
  %44 = getelementptr inbounds i8, ptr %8, i64 4    ; IR: %16 = getelementptr inbounds i8, ptr %7, i64 4  (classical)
  %45 = ptrtoint ptr %44 to i64    ; IR: (no instruction) the run-time address of b[1] (classical)
  %46 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %45)    ; IR: %17 = load i32, ptr %16: b[1]
  %47 = call i32 @cq_template_add_i32(i32 %46, i32 %43)    ; IR: %18 = add nsw i32 %17, %15  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %46, i32 %6, i64 %45)    ; IR: un-copy %17 (no memory version change since the load)
  call void @cqrt_free(i32 %46)    ; IR: release the %17 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %43, i32 %6, i64 %42)    ; IR: un-copy %15
  call void @cqrt_free(i32 %43)    ; IR: release the %15 rail (|0>)
  %48 = call i32 @cqrt_measure_i32(i32 %47)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %48    ; IR: llvm.lifetime.end of %7 and %6 dropped (rule 16); ret i32 %19
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_swap_i32(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
