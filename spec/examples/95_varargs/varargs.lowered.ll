; HAND-WRITTEN. Rules: 16 (variadic calls, allocation), 20, 21, 5, 6, 14, 9, 8, 18, 7, 3, 4, 2; §1.3 (the bus, __cq_mem, __cq_alloc), §1.4 (the variadic clone's block formal).
; Checked: sum3(1, a, x, b) = a + x + b + 1 (the clone's result rail, the last s rail updated in place to s + 1,
; measured in the caller as %6 -> %7). The cells of the two blocks are not named outputs.
; Clean: in __cq_q_sum3_00, per trip: the address chain of the register-slot arm (the zext of gp_offset, the address
; rail reg_save_area + gp_offset) and the merged slot address, each uncomputed after the un-copy of the load through
; it; the load copy of the argument (va_arg's load, un-copied in the trip: no memory version change lies between the
; load and its _unc); the old s and its rule-6 rail t (rule 6 in the body, as 27 and 204; trip 0's old s is the |0>
; seed). After the loop: nothing for the last s (rule 6's in-place update makes its rail the result s + 1); the
; gp_offset after-values (IR %24) and the overflow_arg_area after-values (IR %23) of trips 0..2, uncomputed by the reverse loop
; (rule 14) from the per-trip handles it pops.
; Kept: varargs: x (%5, the rotated register; also the value rail of the block store of slot 1) and the result rail
; (%6, measured); by rule 5 the three tape slots of the caller's block stores and the seeds a and b (their value
; rails). __cq_q_sum3_00: by rule 5 the four tape slots of va_start's stores with their seeds (48, 176, the block
; address, 0); per trip the tape slots of the two va_arg stores (gp_offset, overflow_arg_area) with their value rails
; (gp_offset + 8, overflow_arg_area + 8) and their control, the flag gp_offset < 41 (rule 8); the load copies of
; ap->gp_offset, ap->reg_save_area and ap->overflow_arg_area (rule 5 sentence 1: each is un-copied after its last
; reader, reg_save_area after the loop, gp_offset and overflow_arg_area after the reverse loop, and left allocated,
; since trip 0's store comes between the load and that point). No _unc twin: the clone writes memory (rule 18), and the caller measures its result.
; Rotations: (Ry, x, th, 1).
; Expected: the bus run is classical-valued apart from x: gp_offset reads 48, so the flag is 0 on every trip, the slot
; is the overflow area, and the three trips load a, x, b from the block at offsets 0, 8, 16. The measured value is
; a + x + b + 1 with x = x0 ^ e, each bit of x flipped independently with p = sin^2(th / 2).
; THE VARIADIC BLOCK (rule 16, §1.4). The caller stores every variadic argument into one __cq_alloc(24, 16) block in
; the SysV overflow-area layout (8-byte slots at the promoted type, here three i32 at offsets 0, 8, 16) and passes the
; block's address as the clone's last formal: __cq_q_sum3_00(i32 n, ptr block), mask digit 0 for the dead n (passed as
; poison) and digit 0 for the block pointer. No per-signature clone exists. The classical a and b are stored as seeds
; (rule 7), x as its handle; all three are kept stores (rule 5) at classical addresses.
; VA_START IS FOUR BUS STORES (rule 16). ap (the alloca of the va_list) has va_start, va_end and stores of loaded values
; among its users, so it is bus-resident (rule 20 (b)): __cq_alloc(24, 16), no alloca remains, the lifetime markers are
; dropped. va_start writes {gp_offset = 48, fp_offset = 176, overflow_arg_area = block, reg_save_area = 0} by four kept
; stores of seeds. va_arg and va_end are -O1's code as it stands: every load from ap is a bus load and its result is a
; rail (rule 3; over-taint is accepted, §0), so gp_offset and both area pointers are rails, the va_arg branch on
; gp_offset < 41 is a flag (rule 8) and its two arms are value arms (rule 9): the pure arm code (zext, the address add,
; gp_offset + 8, overflow_arg_area + 8) is hoisted, each arm's store to ap stays in its arm as the _controlled store
; under the flag (the ¬flag arm inside an X bracket), and the three phis are select templates under the flag. The
; argument slot is an address rail, so va_arg's load is qram_load_i32 at that rail (rule 20). llvm.va_end is nothing.
; THE LOOP (rule 14, classical bound: i < 3). The accumulator s' = v + s is a bijection in s whose other operand is a
; load copy, so rule 6 cleans the old s in the body (as 204) and the copy is un-copied after the clean-up that reads
; it, before the next memory version change (the next trip's first store). The carried overflow_arg_area's update is a
; select of itself and itself + 8 under a flag that does not read it, a bijection, but nothing reads its final rail
; after the loop: rule 6 does not clean it per trip (a final carried rail that nothing live reads has no clean-up
; point), so its chain is garbage like any other, pushed with the handles its select _unc reads and uncomputed by the
; reverse loop, trip 2's rail included, as in 109. The carried gp_offset is a select whose condition reads it (not a
; rule-6 bijection) and is undone the same way, after the result is formed. The result s + 1 is a plain add of a
; literal to the dead last s, so it is rule 6's in-place update: ONE core gate addc_i32(s, 1) on the last s rail, which
; is the result from there on and is returned directly (204; no template, no fresh rail, no clean-up, no free).
; SPEC GAP: rule 14 pushes only trip rails rule 5 does not keep; the reverse loop's select _uncs read the flag, the
; store value rails gp_offset + 8 and overflow_arg_area + 8 (all kept with their stores) and, for trip 0, the kept load copies. Their handles are
; pushed as per-trip classical values the _unc needs (rule 14's parenthesis); rule 22 names only two such handle
; pushes of kept rails.
; SPEC GAP: rule 20 fixes no operand order for the add of a rail base and a rail index; IR order (base, index) is used.
; SPEC GAP: rule 16 gives no alignment for the variadic block; __cq_alloc's default 16 is used (§1.3).
source_filename = "varargs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @varargs(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call ptr @__cq_alloc(i64 24, i64 16)    ; IR: %6 = call @sum3(poison, %2, %5, %3): the variadic block, three 8-byte slots (rule 16)
  %8 = ptrtoint ptr %7 to i64    ; the block's run-time address, slot 0 (rule 21)
  %9 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: variadic arg a (classical): the seed, the store's value rail, KEPT with it (rules 5, 7)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %8, i32 %9)    ; IR: block slot 0 = a  [a kept store at a classical address (rule 5)]
  %10 = getelementptr inbounds i8, ptr %7, i64 8    ; IR: block slot 1
  %11 = ptrtoint ptr %10 to i64    ; its run-time address
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %11, i32 %6)    ; IR: block slot 1 = x  [a kept store; its value rail is the register x]
  %12 = getelementptr inbounds i8, ptr %7, i64 16    ; IR: block slot 2
  %13 = ptrtoint ptr %12 to i64    ; its run-time address
  %14 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: variadic arg b (classical): the seed, the store's value rail, KEPT with it (rules 5, 7)
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %13, i32 %14)    ; IR: block slot 2 = b  [a kept store (rule 5)]
  %15 = call fastcc i32 @__cq_q_sum3_00(i32 poison, ptr %7)    ; IR: %6 = call @sum3(poison, %2, %5, %3): the variadic clone, mask 00 (n dead, the block pointer)  [it writes memory: no twin (rule 18)]
  %16 = call i32 @cqrt_measure_i32(i32 %15)    ; IR: %7 = cq_measure_si32(%6)
  ret i32 %16    ; IR: ret i32 %7
}

define internal fastcc i32 @__cq_q_sum3_00(i32 %0, ptr %1) {
  %3 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %4 = call ptr @__cq_alloc(i64 24, i64 16)    ; IR: %2 = alloca [1 x %struct.__va_list_tag]  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]; llvm.lifetime.start dropped
  %5 = ptrtoint ptr %4 to i64    ; the run-time address of ap (&ap->gp_offset)
  %6 = call i32 @cqrt_alloc_i32(i32 48)    ; IR: llvm.va_start(%2): gp_offset = 48  [the seed, KEPT with its store (rules 5, 7)]
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %5, i32 %6)    ; IR: llvm.va_start(%2): store gp_offset  [a kept store (rule 16)]
  %7 = getelementptr inbounds i8, ptr %4, i64 4    ; IR: llvm.va_start(%2): &ap->fp_offset
  %8 = ptrtoint ptr %7 to i64    ; its run-time address
  %9 = call i32 @cqrt_alloc_i32(i32 176)    ; IR: llvm.va_start(%2): fp_offset = 176  [the seed, KEPT with its store]
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %8, i32 %9)    ; IR: llvm.va_start(%2): store fp_offset  [a kept store]
  %10 = getelementptr inbounds i8, ptr %4, i64 8    ; IR: %4 = getelementptr inbounds i8, ptr %2, i64 8  (&ap->overflow_arg_area; nothing tainted: the getelementptr stays)
  %11 = ptrtoint ptr %10 to i64    ; its run-time address
  %12 = ptrtoint ptr %1 to i64    ; the block formal's run-time address
  %13 = call i32 @cqrt_alloc_i64(i64 %12)    ; IR: llvm.va_start(%2): overflow_arg_area = block  [the seed, KEPT with its store]
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %11, i32 %13)    ; IR: llvm.va_start(%2): store overflow_arg_area  [a kept store]
  %14 = getelementptr inbounds i8, ptr %4, i64 16    ; IR: %5 = getelementptr inbounds i8, ptr %2, i64 16  (&ap->reg_save_area)
  %15 = ptrtoint ptr %14 to i64    ; its run-time address
  %16 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: llvm.va_start(%2): reg_save_area = 0  [the seed, KEPT with its store]
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %15, i32 %16)    ; IR: llvm.va_start(%2): store reg_save_area  [a kept store]
  %17 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %5)    ; IR: %3 = load i32, ptr %2  (gp_offset: a bus load, a rail (rule 3); un-copied after the reverse loop, not freed: trip 0's store precedes its last reader)
  %18 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %15)    ; IR: %6 = load ptr, ptr %5  (reg_save_area: an address rail, read in every trip; un-copied after the loop, not freed)
  %19 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %11)    ; IR: %7 = load ptr, ptr %4  (overflow_arg_area: an address rail; un-copied after the reverse loop, not freed)
  %20 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %13  [s before trip 0: trip 0's old s, cleaned by rule 6 in the body]
  br label %21    ; IR: br label %10

21:
  %22 = phi i32 [ %19, %2 ], [ %31, %21 ]    ; IR: %11 = phi ptr [ %7, %1 ], [ %23, %22 ]  (overflow_arg_area: a handle)
  %23 = phi i32 [ 0, %2 ], [ %37, %21 ]    ; IR: %12 = phi i32  (i, classical)
  %24 = phi i32 [ %20, %2 ], [ %35, %21 ]    ; IR: %13 = phi i32 [ 0, %1 ], [ %27, %22 ]  (s: a handle)
  %25 = phi i32 [ %17, %2 ], [ %32, %21 ]    ; IR: %14 = phi i32 [ %3, %1 ], [ %24, %22 ]  (gp_offset: a handle)
  %26 = call i32 @cq_template_icmp_ult_i32_hl(i32 %25, i32 41)    ; IR: %15 = icmp ult i32 %14, 41  [the flag (rule 8); KEPT: it controls the two kept stores below]
  %27 = call i32 @cq_template_zext_i32_to_i64(i32 %25)    ; IR: %17 = zext nneg i32 %14 to i64  (hoisted from the arm, rule 9)
  %28 = call i32 @cq_template_add_i64(i32 %18, i32 %27)    ; IR: %18 = getelementptr i8, ptr %6, i64 %17  [the address rail reg_save_area + gp_offset (rule 20, size 1: no scale)]  ; SPEC GAP: operand order of a rail base plus a rail index not fixed; IR order
  %29 = call i32 @cq_template_add_i32_hl(i32 %25, i32 8)    ; IR: %19 = add nuw nsw i32 %14, 8  (hoisted; the value rail of the store below, KEPT with it)
  %30 = call i32 @cq_template_add_i64_hl(i32 %22, i64 8)    ; IR: %21 = getelementptr i8, ptr %11, i64 8  (hoisted; the value rail of the store below, KEPT with it)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %26, i32 %3, i64 %5, i32 %29)    ; IR: store i32 %19, ptr %2  [arm %16: a kept store under the flag (rules 5, 9)]
  call void @cqrt_not_i1(i32 %26)    ; IR: br i1 %15, label %16, label %20  [false edge: X bracket open]
  call void @cqrt_qram_store_i64_hl_controlled(i32 %26, i32 %3, i64 %11, i32 %30)    ; IR: store ptr %21, ptr %4  [arm %20: a kept store under the complement]
  call void @cqrt_not_i1(i32 %26)    ; IR: X bracket close
  %31 = call i32 @cq_template_select_i64(i32 %26, i32 %22, i32 %30)    ; IR: %23 = phi ptr [ %11, %16 ], [ %21, %20 ]  (overflow_arg_area after: a select under the flag (rule 9); nothing reads the final one after the loop, so it is no rule-6 image: uncomputed by the reverse loop)
  %32 = call i32 @cq_template_select_i32(i32 %26, i32 %29, i32 %25)    ; IR: %24 = phi i32 [ %19, %16 ], [ %14, %20 ]  (gp_offset after; uncomputed by the reverse loop)
  %33 = call i32 @cq_template_select_i64(i32 %26, i32 %28, i32 %22)    ; IR: %25 = phi ptr [ %18, %16 ], [ %11, %20 ]  (the argument slot: an address rail)
  %34 = call i32 @cqrt_qram_load_i32(i32 %3, i32 %33)    ; IR: %26 = load i32, ptr %25, align 4  [va_arg: a bus load at the address rail (rule 20)]
  %35 = call i32 @cq_template_add_i32(i32 %34, i32 %24)    ; IR: %27 = add nsw i32 %26, %13  [s after this trip: the only s rail that survives it]
  %36 = call i32 @cq_template_sub_i32(i32 %35, i32 %34)    ; IR: rule 6: t = s' - v recomputes the old s (the add is a bijection in s; the other operand is the load copy)
  call void @cqrt_copy_i32(i32 %36, i32 %24)    ; IR: rule 6: old s ^= t: |0> (trip 0: the |0> seed, unchanged)
  call void @cq_template_sub_i32_unc(i32 %36, i32 %35, i32 %34)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %36)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %24)    ; IR: rule 6: release the old s rail (|0> after the copy); it is not pushed
  call void @cqrt_qram_load_i32_unc(i32 %34, i32 %3, i32 %33)    ; IR: un-copy %26 (rule 5: its last reader, rule 6's t, is done; no memory version change since the load)
  call void @cqrt_free(i32 %34)    ; IR: release the %26 rail (|0>)
  call void @cq_template_select_i64_unc(i32 %33, i32 %26, i32 %28, i32 %22)    ; IR: uncompute %25 (the address rail outlived its load's _unc)
  call void @cqrt_free(i32 %33)    ; IR: release the %25 rail (|0>)
  call void @cq_template_add_i64_unc(i32 %28, i32 %18, i32 %27)    ; IR: uncompute %18
  call void @cqrt_free(i32 %28)    ; IR: release the %18 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %27, i32 %25)    ; IR: uncompute %17
  call void @cqrt_free(i32 %27)    ; IR: release the %17 rail (|0>)
  call void @cqrt_push(i32 %25)    ; IR: %14 of this trip (gp_offset before; trip 0: the kept load copy)  ; SPEC GAP: handles of kept rails pushed for the reverse loop's _unc
  call void @cqrt_push(i32 %26)    ; IR: %15 of this trip (the kept flag: its handle only)
  call void @cqrt_push(i32 %29)    ; IR: %19 of this trip (a kept store value rail: its handle only)
  call void @cqrt_push(i32 %22)    ; IR: %11 of this trip (overflow_arg_area before; trip 0: the kept load copy %7, its handle only)
  call void @cqrt_push(i32 %30)    ; IR: %21 of this trip (a kept store value rail: its handle only)
  %37 = add nuw nsw i32 %23, 1    ; IR: %28 = add nuw nsw i32 %12, 1  (classical)
  %38 = icmp eq i32 %37, 3    ; IR: %29 = icmp eq i32 %28, 3  (classical)
  br i1 %38, label %39, label %21    ; IR: br i1 %29, label %8, label %10

39:
  call void @cqrt_qram_load_i64_hl_unc(i32 %18, i32 %3, i64 %15)    ; IR: un-copy %6 (reg_save_area) after its last reader, trip 2's _unc of %18; trip 0's store lies between, so it stays allocated (rule 5 sentence 1)
  call void @cqrt_addc_i32(i32 %35, i32 1)    ; IR: llvm.va_end(%2): nothing; %9 = add nsw i32 %27, 1  [the result; rule 6, in-place update: the last s is dead after the add, so s + 1 IS its rail, returned directly]
  br label %40    ; IR: the reverse loop (rule 14)

40:
  %41 = phi i32 [ 0, %39 ], [ %49, %40 ]    ; reverse trip counter (classical)
  %42 = phi i32 [ %32, %39 ], [ %48, %40 ]    ; IR: %24 of the trip being undone (gp_offset after)
  %43 = phi i32 [ %31, %39 ], [ %45, %40 ]    ; IR: %23 of the trip being undone (overflow_arg_area after)
  %44 = call i32 @cqrt_pop()    ; IR: %21 of that trip
  %45 = call i32 @cqrt_pop()    ; IR: %11 of that trip
  %46 = call i32 @cqrt_pop()    ; IR: %19 of that trip
  %47 = call i32 @cqrt_pop()    ; IR: %15 of that trip
  %48 = call i32 @cqrt_pop()    ; IR: %14 of that trip
  call void @cq_template_select_i32_unc(i32 %42, i32 %47, i32 %46, i32 %48)    ; IR: uncompute %24
  call void @cqrt_free(i32 %42)    ; IR: release the %24 rail (|0>)
  call void @cq_template_select_i64_unc(i32 %43, i32 %47, i32 %45, i32 %44)    ; IR: uncompute %23 (rule 6: a final carried rail nothing reads after the loop is undone here, trip 2's included)
  call void @cqrt_free(i32 %43)    ; IR: release the %23 rail (|0>)
  %49 = add nuw nsw i32 %41, 1
  %50 = icmp eq i32 %49, 3
  br i1 %50, label %51, label %40

51:
  call void @cqrt_qram_load_i32_hl_unc(i32 %17, i32 %3, i64 %5)    ; IR: un-copy %3 (gp_offset) after its last reader, the reverse loop's _unc of trip 0's %24; it stays allocated (rule 5 sentence 1)
  call void @cqrt_qram_load_i64_hl_unc(i32 %19, i32 %3, i64 %11)    ; IR: un-copy %7 (overflow_arg_area) after its last reader, the reverse loop's _unc of trip 0's %23; trip 0's store lies between, so it stays allocated (rule 5 sentence 1)
  ret i32 %35    ; IR: ret i32 %9  (llvm.lifetime.end dropped; the rails left are the kept ones of the header: the three entry load copies (un-copied, not freed), the four va_start seeds, and per trip the flag and the two store value rails)
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_not_i1(i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)
declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i64(i32, i32, i32)
declare void @cq_template_select_i64_unc(i32, i32, i32, i32)
declare void @cqrt_addc_i32(i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
