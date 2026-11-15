; HAND-WRITTEN. Rules: 4, 18, 20, 16, 22, 14, 3, 7, 8, 9, 5, 6, 2, 21, §1.3, §1.4.
; Checked: smin_q: min(x, c) (measured, %5 -> %6); bswap_q: bswap(x) (measured, %4 -> %6); usub_sat_q: x > c ? x - c : 0
; (measured, %5 -> %6); va_copy_q: sum_twice(2, x, a) = 2 * (x + a) (measured: the clone's returned rule-6 image s + t,
; %10 -> %11 in the caller); vla_loop_q: acc = sum over i < m of x + i (measured: the carried rail, rule 6 left no other
; acc rail; the never-written |0> seed when m <= 0). The bus cells (the variadic block, ap, bp, the VLAs) are no named
; output.
; Clean: in bswap_q the old x rail (%3, rule 6: bswap is a bijection, its own inverse) and t = bswap(r) (%5), both
; freed. In __cq_q_sum_twice_00, per trip of each walk: the slot-address chain (the zext of gp_offset, reg_save_area +
; gp_offset, the select of the slot address), un-copied/uncomputed after the slot's load; the slot's load copy (IR %31 /
; %53, un-copied in the trip: no memory version change between the load and its _unc); the old s / t (rule 6 in the
; body, trip 0's the |0> seed) and its inverse; every carried gp_offset rail (IR %29 / %51) and every carried
; overflow_arg_area rail (IR %28 / %50, the last trip's included): popped and uncomputed by the reverse loop, trip 0's
; against the load copy; after the walks
; t (rule 6: operand 0 of s + t, cleaned from the sum) and its inverse; un-copied but left allocated (rule 5 sentence 1:
; each overtaken by trip 0's stores): the load copies of ap.gp_offset, ap.reg_save_area, ap.overflow_arg_area (IR %4,
; %7, %8), un-copied after the first walk's last undo, and of the same three bp fields (IR %10, %13, %14), un-copied
; after the second walk's. In vla_loop_q, per trip: x + i (IR %17,
; uncomputed after the call it was passed to), the load copy of v[0] (IR %18, un-copied in the trip), the old acc (rule 6
; in the body; trip 0's the |0> seed) and its inverse.
; Kept: x in the other four functions (%4 of smin_q, %4 of usub_sat_q, %5 of va_copy_q, %6 of vla_loop_q: rotated user
; registers whose results have no inverse in them); bswap_q's measured result %4. va_copy_q (rule 5): the tape slots of
; the two stores into the variadic block, the seed of a (the second store's value rail; x is the first's). In
; __cq_q_sum_twice_00 (rule 5 unless named): the four seeds 48, 176, the block address and 0 of va_start and their four
; tape slots; the 24 byte load copies of va_copy (the value rails of its 24 byte stores into bp) and their 24 tape
; slots (rule 22); per trip of each walk the flag
; gp_offset < 41 (control rail of both of its stores), gp_offset + 8 and overflow_arg_area + 8 (value rails) and the two
; tape slots; s (IR %32 of the last trip, rule 6: the operand of s + t that is not cleaned). The result s + t is returned
; (no twin: the clone writes memory, rule 18) and measured. vla_loop_q: per trip the tape slot of put's store (its value
; rail x + i is the caller's, uncomputed); the carried acc (measured).
; Rotations: (Ry, x, th, 1) in each of the five functions.
; The last intrinsics of the musl census
; (LIBC_COVERAGE.md), each the width/op variant of an existing family: llvm.smin is 56's smax/umin family
; (cq_template_smin_<W>[_hl]); llvm.bswap is a unary bit permutation like 56's ctlz (cq_template_bswap_<W>, no classical
; operand); llvm.usub.sat is 92's uadd.sat family (cq_template_usub_sat_<W>[_hl|_lh]).
; THE VARIADIC CALL (rule 16, §1.4). va_copy_q stores the two variadic actuals into ONE __cq_alloc(16, 16) block in the
; SysV overflow-area layout (8-byte slots, the promoted i32 at its slot's address): x's rail at block + 0 (a kept store,
; the value rail the user register), a's seed at block + 8 (a kept store with its seed). It calls the block form
; __cq_q_sum_twice_00(i32 poison, ptr block): the fixed formal n (dead, poison, digit 0), then the block address (digit
; 0); no handle and no per-signature clone. The clone keeps sum_twice's linkage and calling convention (internal, C).
; In the clone ap and bp are BUS-RESIDENT (rule 20 (b): va_start and va_copy are users no host-resident case allows):
; __cq_alloc(24, 16) each, the lifetime markers dropped. va_start(ap) is the four kept bus stores {gp_offset = 48,
; fp_offset = 176, overflow_arg_area = block, reg_save_area = 0}; va_copy(bp, ap) of the bus-resident ap is rule 22's
; copy of its 24 bytes (a host loop of 24 byte loads at ap + j, each pushed, then 24 byte stores at bp + i popped, i = 23
; down to 0, all kept; SPEC GAP below); va_end is the -O1 code as it stands (the intrinsic, a no-op on x86-64).
; Every load of a va_list field is a bus load and its value a rail (rule 3: over-taint, a classical-valued rail costs no
; qubit), so each va_arg is quantum control: gp_offset < 41 is a flag (rule 8, always 0 here: gp_offset
; is 48 and every argument is read from the overflow area), the arms' address and offset arithmetic is hoisted and
; computed unguarded, the two field stores stay in their arms as _hl_controlled stores under f and NOT f (X bracket),
; and the three phis are select templates (rule 9): the slot address, the next gp_offset, the next overflow_arg_area.
; The slot is read by a bus load at that address rail. Each walk is a classically bounded loop (n = 2 propagated by
; -O1, the latch tests i == 0). Rule 6 cleans in the body (as 27, 204): s (or t), whose other operand is the slot's load
; copy. The overflow_arg_area's update f ? ovf : ovf + 8 is a bijection in ovf, but nothing reads its final rail after
; the walk, so rule 6 does not clean it per trip: its chain is garbage, undone by the reverse loop. gp_offset's update
; f ? gp + 8 : gp has a condition that reads gp: no rule-6 bijection. So each trip pushes its kept flag, gp + 8 and
; ovf + 8 and (trips i != 0) its old gp and old ovf, and the reverse loop after the walk pops them and uncomputes the
; two selects (trip 0's against the load copies). After both walks s + t is formed and rule 6 cleans operand 0, t;
; the sum is returned directly (an image is never copied out, rule 6). The second walk reads the same block through
; bp's copied overflow_arg_area, so x and a are loaded twice: sum = 2x + 2a.
; THE VLA (rules 16, 20). v is passed to put, a user no host-resident case allows, so the VLA is bus-resident: every trip
; allocates __cq_alloc(4 n, 16) at the alloca's program point; llvm.stacksave/stackrestore are dropped for it. put(v, x +
; i) is the clone __cq_q_put_01(ptr, i32): a classical pointer (digit 0, the ptr itself) and a value rail; put stores the
; rail at the classical address (a kept store), so put writes memory and has no twin. The caller uncomputes x + i after
; the call (a template result it passed, rule 5 sentence 3); trace_check reports that _unc and free as "a value rail
; freed": its docstring names this case legal by rule 5, read by hand. v[0] is a bus load (a rail); acc' = v[0] + acc
; is rule 6 in the body (as 204), the load copy is un-copied before the next trip's __cq_alloc, and the final acc is
; measured directly: no push, no reverse loop.
; SPEC GAP: rule 16 says va_copy is "the -O1 code as it stands", the llvm.va_copy intrinsic, a host copy of ap's 24
; bytes. That reads unspecified bytes wherever ap's cells are QUANTUM (a va_copy after a va_arg's controlled stores),
; and the compiler may never ask whether a cell is HOST (rule 20). Read here: va_copy of a bus-resident va_list is rule
; 22's copy of its 24 bytes from ap to bp (the intrinsic stays only when both are host-resident); va_end stays.
; The reverse loop needs the trip's flag, gp + 8 and ovf + 8, which rule 5 keeps: each trip pushes the three handles
; and the reverse loop pops them (nothing is recomputed). The pushes of the old gp and the old ovf are made on trips
; i != 0 only (trip 0's are the load copies), under a classical branch on the trip index (i == 0, the same compare -O1
; uses as the latch test; no loop peeling); the last undo, against those load copies, follows the reverse loop, and the
; three field load copies are un-copied right after it.
source_filename = "intrinsic_variants.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @smin_q(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_smin_i32_hl(i32 %4, i32 %2)    ; IR: %5 = llvm.smin.i32(%4, %2)  [result rail]
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

define i32 @bswap_q(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %3, double %1)    ; IR: %3 = cq_theta_ui32(%0, %1)  [Ry]
  %4 = call i32 @cq_template_bswap_i32(i32 %3)    ; IR: %4 = llvm.bswap.i32(%3)  [result rail]
  %5 = call i32 @cq_template_bswap_i32(i32 %4)    ; IR: rule 6: t = bswap(r) recomputes the old x (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %5, i32 %3)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_bswap_i32_unc(i32 %5, i32 %4)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %5)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %3)    ; IR: release the old x rail (|0> after the copy)
  %6 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %5 = cq_measure_ui32(%4)
  ret i32 %6    ; IR: ret i32 %5
}

define i32 @usub_sat_q(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_usub_sat_i32_hl(i32 %4, i32 %2)    ; IR: %5 = llvm.usub.sat.i32(%4, %2)  [result rail]
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_ui32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

define i32 @va_copy_q(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %5 = call @sum_twice(poison, %4, %2): the variadic block, two 8-byte slots (rule 16)
  %7 = ptrtoint ptr %6 to i64    ; the block's run-time address, a classical i64 (rule 21)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %7, i32 %5)    ; IR: variadic actual 1, x (%4), at block + 0  [kept store, rule 5: its tape slot stays; the value rail is the user register]
  %8 = add i64 %7, 8    ; slot 2 at block + 8 (classical)
  %9 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: variadic actual 2, a (%2): the classical value as a seed (rule 7), the store's value rail, KEPT with it
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %8, i32 %9)    ; IR: variadic actual 2 at block + 8  [kept store, rule 5]
  %10 = call i32 @__cq_q_sum_twice_00(i32 poison, ptr %6)    ; IR: %5 = call @sum_twice(poison, %4, %2): the block form (§1.4: n dead and classical, digit 0; the block ptr, digit 0); it writes memory, so no twin (rule 18)
  %11 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %11    ; IR: ret i32 %6
}

define internal i32 @__cq_q_sum_twice_00(i32 %0, ptr %1) unnamed_addr {
  %3 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %4 = call ptr @__cq_alloc(i64 24, i64 16)    ; IR: %2 = alloca va_list ap  [bus-resident (va_start, va_copy: rule 20 (b)): one zeroed block, no alloca remains; llvm.lifetime.start dropped]
  %5 = ptrtoint ptr %4 to i64    ; ap's run-time address (classical)
  %6 = call ptr @__cq_alloc(i64 24, i64 16)    ; IR: %3 = alloca va_list bp  [bus-resident; llvm.lifetime.start dropped]
  %7 = call i32 @cqrt_alloc_i32(i32 48)    ; IR: va_start(%2): gp_offset = 48 (rule 16), a seed (rule 7) kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %5, i32 %7)    ; IR: va_start: ap.gp_offset  [kept store, rule 5]
  %8 = add i64 %5, 4    ; &ap.fp_offset (classical)
  %9 = call i32 @cqrt_alloc_i32(i32 176)    ; IR: va_start: fp_offset = 176, a seed kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %8, i32 %9)    ; IR: va_start: ap.fp_offset  [kept store]
  %10 = add i64 %5, 8    ; &ap.overflow_arg_area (classical)
  %11 = ptrtoint ptr %1 to i64    ; the block's address (the last formal)
  %12 = call i32 @cqrt_alloc_i64(i64 %11)    ; IR: va_start: overflow_arg_area = block, a seed kept with its store
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %10, i32 %12)    ; IR: va_start: ap.overflow_arg_area  [kept store]
  %13 = add i64 %5, 16    ; &ap.reg_save_area (classical)
  %14 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: va_start: reg_save_area = 0, a seed kept with its store
  call void @cqrt_qram_store_i64_hl(i32 %3, i64 %13, i32 %14)    ; IR: va_start: ap.reg_save_area  [kept store]
  %15 = ptrtoint ptr %6 to i64    ; bp's run-time address (classical)
  br label %16    ; IR: llvm.va_copy(%3, %2): a bus-resident va_list, so rule 22's copy of its 24 bytes from ap to bp (load all, then store all)  ; SPEC GAP: rule 16 reads "as it stands"

16:
  %17 = phi i64 [ 0, %2 ], [ %20, %16 ]    ; byte index of the load loop (classical)
  %18 = add i64 %5, %17    ; the source byte's address, ap + j (classical)
  %19 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %18)    ; IR: va_copy  [byte j of ap: a bus load; the copy is the value rail of byte j's store, KEPT (rule 22)]
  call void @cqrt_push(i32 %19)    ; the handle outlives its SSA value (§1.1, rule 22)
  %20 = add nuw nsw i64 %17, 1
  %21 = icmp eq i64 %20, 24
  br i1 %21, label %22, label %16

22:
  %23 = phi i64 [ 24, %16 ], [ %24, %22 ]    ; bytes left to store (classical)
  %24 = add nsw i64 %23, -1    ; byte index of this store: 23 down to 0 (the pop order)
  %25 = call i32 @cqrt_pop()    ; the load copy of byte %vki
  %26 = add i64 %15, %24    ; the destination byte's address, bp + i (classical)
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %26, i32 %25)    ; IR: va_copy  [byte i of bp: a kept store (rule 22): its tape slot and value rail stay]
  %27 = icmp eq i64 %24, 0
  br i1 %27, label %28, label %22

28:
  %29 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %5)    ; IR: %4 = load i32, ptr %2  [ap.gp_offset: a bus load, a rail (rule 3); overtaken by trip 0's store, un-copied after the walk]
  %30 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %13)    ; IR: %6 = gep %2, 16; %7 = load ptr, ptr %6  [ap.reg_save_area: an address rail (rule 21); overtaken, un-copied after the walk]
  %31 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %10)    ; IR: %5 = gep %2, 8; %8 = load ptr, ptr %5  [ap.overflow_arg_area: an address rail; overtaken, un-copied after the walk]
  %32 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %18  [s before trip 0: trip 0's old s, cleaned by rule 6]
  br label %33    ; IR: br label %15

33:
  %34 = phi i32 [ %31, %28 ], [ %43, %51 ]    ; IR: %16 = phi ptr  (overflow_arg_area: a handle)
  %35 = phi i32 [ 0, %28 ], [ %52, %51 ]    ; IR: %17 = phi i32  (i, classical)
  %36 = phi i32 [ %32, %28 ], [ %47, %51 ]    ; IR: %18 = phi i32 [ 0, %1 ], [ %32, %27 ]  (s: a handle)
  %37 = phi i32 [ %29, %28 ], [ %44, %51 ]    ; IR: %19 = phi i32  (gp_offset: a handle)
  %38 = call i32 @cq_template_icmp_ult_i32_hl(i32 %37, i32 41)    ; IR: %20 = icmp ult i32 %19, 41  [the arm flag (rule 8); KEPT: control rail of both stores below]
  %39 = call i32 @cq_template_zext_i32_to_i64(i32 %37)    ; IR: %22 = zext nneg i32 %19 to i64  (arm %21, hoisted: rule 9)
  %40 = call i32 @cq_template_add_i64(i32 %30, i32 %39)    ; IR: %23 = getelementptr i8, ptr %7, i64 %22  (arm %21, hoisted)  [reg_save_area + gp_offset]
  %41 = call i32 @cq_template_add_i32_hl(i32 %37, i32 8)    ; IR: %24 = add nuw nsw i32 %19, 8  (arm %21, hoisted)  [KEPT: the value rail of the store below]
  %42 = call i32 @cq_template_add_i64_hl(i32 %34, i64 8)    ; IR: %26 = getelementptr i8, ptr %16, i64 8  (arm %25, hoisted)  [KEPT: the value rail of the store below]
  call void @cqrt_qram_store_i32_hl_controlled(i32 %38, i32 %3, i64 %5, i32 %41)    ; IR: store i32 %24, ptr %2  (arm %21: under f, never hoisted; kept store, rule 5)
  call void @cqrt_not_i1(i32 %38)    ; IR: arm %25: the false edge (rule 8)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %38, i32 %3, i64 %10, i32 %42)    ; IR: store ptr %26, ptr %5  (arm %25: under NOT f; kept store)
  call void @cqrt_not_i1(i32 %38)    ; IR: close the X bracket
  %43 = call i32 @cq_template_select_i64(i32 %38, i32 %34, i32 %42)    ; IR: %28 = phi ptr [ %16, %21 ], [ %26, %25 ]  [the next overflow_arg_area (rule 9)]
  %44 = call i32 @cq_template_select_i32(i32 %38, i32 %41, i32 %37)    ; IR: %29 = phi i32 [ %24, %21 ], [ %19, %25 ]  [the next gp_offset]
  %45 = call i32 @cq_template_select_i64(i32 %38, i32 %40, i32 %34)    ; IR: %30 = phi ptr [ %23, %21 ], [ %16, %25 ]  [the argument slot: an address rail]
  %46 = call i32 @cqrt_qram_load_i32(i32 %3, i32 %45)    ; IR: %31 = load i32, ptr %30  [va_arg(ap, int): a bus load at the address rail]
  %47 = call i32 @cq_template_add_i32(i32 %46, i32 %36)    ; IR: %32 = add nsw i32 %31, %18
  %48 = call i32 @cq_template_sub_i32(i32 %47, i32 %46)    ; IR: rule 6: t = s' - v recomputes the old s (the other operand is the load copy, rule-5 garbage)
  call void @cqrt_copy_i32(i32 %48, i32 %36)    ; IR: rule 6: old s ^= t: |0> (trip 0: the |0> seed, unchanged)
  call void @cq_template_sub_i32_unc(i32 %48, i32 %47, i32 %46)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %48)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %36)    ; IR: rule 6: release the old s rail (|0> after the copy); it is not pushed
  call void @cqrt_qram_load_i32_unc(i32 %46, i32 %3, i32 %45)    ; IR: un-copy %31 (rule 5: no memory version change since the load)
  call void @cqrt_free(i32 %46)    ; IR: release the %31 rail (|0>)
  call void @cq_template_select_i64_unc(i32 %45, i32 %38, i32 %40, i32 %34)    ; IR: uncompute %30 (the address rail outlived its load's _unc)
  call void @cqrt_free(i32 %45)    ; IR: release the %30 rail (|0>)
  call void @cq_template_add_i64_unc(i32 %40, i32 %30, i32 %39)    ; IR: uncompute %23
  call void @cqrt_free(i32 %40)    ; IR: release the %23 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %39, i32 %37)    ; IR: uncompute %22
  call void @cqrt_free(i32 %39)    ; IR: release the %22 rail (|0>)
  call void @cqrt_push(i32 %38)    ; IR: %20 of this trip (kept: only its handle), for the reverse loop (rule 14)
  call void @cqrt_push(i32 %41)    ; IR: %24 of this trip (kept: only its handle), for the reverse loop
  call void @cqrt_push(i32 %42)    ; IR: %26 of this trip (kept: only its handle), for the reverse loop
  %49 = icmp eq i32 %35, 0    ; IR: %34 = icmp eq i32 %17, 0  (classical: trip 0, and the latch test of 2 trips)
  br i1 %49, label %51, label %50

50:
  call void @cqrt_push(i32 %37)    ; IR: %19 of this trip, for the reverse loop (trip 0's is the kept load copy %4: not pushed)
  call void @cqrt_push(i32 %34)    ; IR: %16 of this trip, for the reverse loop (trip 0's is the kept load copy %8: not pushed)
  br label %51

51:
  %52 = add nuw nsw i32 %35, 1    ; IR: %33 = add nuw nsw i32 %17, 1  (classical)
  br i1 %49, label %33, label %53    ; IR: br i1 %34, label %15, label %9

53:
  %54 = phi i32 [ 0, %51 ], [ %62, %53 ]
  %55 = phi i32 [ %44, %51 ], [ %58, %53 ]    ; IR: %29 of the trip being undone
  %56 = phi i32 [ %43, %51 ], [ %57, %53 ]    ; IR: %28 of the trip being undone
  %57 = call i32 @cqrt_pop()    ; IR: %16 of that trip
  %58 = call i32 @cqrt_pop()    ; IR: %19 of that trip
  %59 = call i32 @cqrt_pop()    ; IR: %26 of that trip (kept: its handle)
  %60 = call i32 @cqrt_pop()    ; IR: %24 of that trip (kept: its handle)
  %61 = call i32 @cqrt_pop()    ; IR: %20 of that trip (kept: its handle)
  call void @cq_template_select_i32_unc(i32 %55, i32 %61, i32 %60, i32 %58)    ; IR: uncompute %29
  call void @cqrt_free(i32 %55)    ; IR: release the %29 rail (|0>)
  call void @cq_template_select_i64_unc(i32 %56, i32 %61, i32 %57, i32 %59)    ; IR: uncompute %28 (rule 6: a final carried rail nothing reads after the loop is undone here, the last trip's included)
  call void @cqrt_free(i32 %56)    ; IR: release the %28 rail (|0>)
  %62 = add nuw nsw i32 %54, 1
  %63 = icmp eq i32 %62, 1    ; the trips i != 0 (one: n = 2)
  br i1 %63, label %64, label %53

64:
  %65 = call i32 @cqrt_pop()    ; IR: %26 of trip 0 (kept: its handle)
  %66 = call i32 @cqrt_pop()    ; IR: %24 of trip 0 (kept: its handle)
  %67 = call i32 @cqrt_pop()    ; IR: %20 of trip 0 (kept: its handle)
  call void @cq_template_select_i32_unc(i32 %58, i32 %67, i32 %66, i32 %29)    ; IR: uncompute %29 of trip 0 (against the load copy %4)
  call void @cqrt_free(i32 %58)    ; IR: release that rail (|0>)
  call void @cq_template_select_i64_unc(i32 %57, i32 %67, i32 %31, i32 %65)    ; IR: uncompute %28 of trip 0 (against the load copy %8)
  call void @cqrt_free(i32 %57)    ; IR: release that rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %29, i32 %3, i64 %5)    ; IR: un-copy %4 (after its last reader; overtaken by trip 0's store, so it stays allocated: rule 5 sentence 1)
  call void @cqrt_qram_load_i64_hl_unc(i32 %30, i32 %3, i64 %13)    ; IR: un-copy %7 (its last reader was the last trip's slot-address _unc; overtaken, stays allocated)
  call void @cqrt_qram_load_i64_hl_unc(i32 %31, i32 %3, i64 %10)    ; IR: un-copy %8 (its last reader was the undo of trip 0's %28 above; overtaken, stays allocated)
  %68 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 %15)    ; IR: %10 = load i32, ptr %3  [bp.gp_offset: a rail; overtaken, un-copied after the walk]
  %69 = add i64 %15, 8    ; IR: %11 = getelementptr inbounds i8, ptr %3, i64 8
  %70 = add i64 %15, 16    ; IR: %12 = getelementptr inbounds i8, ptr %3, i64 16
  %71 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %70)    ; IR: %13 = load ptr, ptr %12  [bp.reg_save_area: an address rail; overtaken, un-copied after the walk]
  %72 = call i32 @cqrt_qram_load_i64_hl(i32 %3, i64 %69)    ; IR: %14 = load ptr, ptr %11  [bp.overflow_arg_area: the copied block address, an address rail; overtaken, un-copied after the walk]
  %73 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %40  [t before trip 0: trip 0's old t, cleaned by rule 6]
  br label %74    ; IR: br label %37

74:
  %75 = phi i32 [ %72, %64 ], [ %84, %92 ]    ; IR: %38 = phi ptr  (a handle)
  %76 = phi i32 [ 0, %64 ], [ %93, %92 ]    ; IR: %39 = phi i32  (i, classical)
  %77 = phi i32 [ %73, %64 ], [ %88, %92 ]    ; IR: %40 = phi i32 [ 0, %9 ], [ %54, %49 ]  (t: a handle)
  %78 = phi i32 [ %68, %64 ], [ %85, %92 ]    ; IR: %41 = phi i32  (a handle)
  %79 = call i32 @cq_template_icmp_ult_i32_hl(i32 %78, i32 41)    ; IR: %42 = icmp ult i32 %41, 41  [the arm flag; KEPT: control rail of both stores]
  %80 = call i32 @cq_template_zext_i32_to_i64(i32 %78)    ; IR: %44 = zext nneg i32 %41 to i64  (hoisted)
  %81 = call i32 @cq_template_add_i64(i32 %71, i32 %80)    ; IR: %45 = getelementptr i8, ptr %13, i64 %44  (hoisted)
  %82 = call i32 @cq_template_add_i32_hl(i32 %78, i32 8)    ; IR: %46 = add nuw nsw i32 %41, 8  (hoisted)  [KEPT: value rail]
  %83 = call i32 @cq_template_add_i64_hl(i32 %75, i64 8)    ; IR: %48 = getelementptr i8, ptr %38, i64 8  (hoisted)  [KEPT: value rail]
  call void @cqrt_qram_store_i32_hl_controlled(i32 %79, i32 %3, i64 %15, i32 %82)    ; IR: store i32 %46, ptr %3  (arm %43: under g; kept store)
  call void @cqrt_not_i1(i32 %79)    ; IR: arm %47: the false edge
  call void @cqrt_qram_store_i64_hl_controlled(i32 %79, i32 %3, i64 %69, i32 %83)    ; IR: store ptr %48, ptr %11  (arm %47: under NOT g; kept store)
  call void @cqrt_not_i1(i32 %79)    ; IR: close the X bracket
  %84 = call i32 @cq_template_select_i64(i32 %79, i32 %75, i32 %83)    ; IR: %50 = phi ptr [ %38, %43 ], [ %48, %47 ]
  %85 = call i32 @cq_template_select_i32(i32 %79, i32 %82, i32 %78)    ; IR: %51 = phi i32 [ %46, %43 ], [ %41, %47 ]
  %86 = call i32 @cq_template_select_i64(i32 %79, i32 %81, i32 %75)    ; IR: %52 = phi ptr [ %45, %43 ], [ %38, %47 ]  [the argument slot: the same cells as the first walk's]
  %87 = call i32 @cqrt_qram_load_i32(i32 %3, i32 %86)    ; IR: %53 = load i32, ptr %52  [va_arg(bp, int)]
  %88 = call i32 @cq_template_add_i32(i32 %87, i32 %77)    ; IR: %54 = add nsw i32 %53, %40
  %89 = call i32 @cq_template_sub_i32(i32 %88, i32 %87)    ; IR: rule 6: t' - w recomputes the old t
  call void @cqrt_copy_i32(i32 %89, i32 %77)    ; IR: rule 6: old t ^= that: |0>
  call void @cq_template_sub_i32_unc(i32 %89, i32 %88, i32 %87)
  call void @cqrt_free(i32 %89)
  call void @cqrt_free(i32 %77)    ; IR: rule 6: release the old t rail (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %87, i32 %3, i32 %86)    ; IR: un-copy %53 (rule 5)
  call void @cqrt_free(i32 %87)    ; IR: release the %53 rail (|0>)
  call void @cq_template_select_i64_unc(i32 %86, i32 %79, i32 %81, i32 %75)    ; IR: uncompute %52
  call void @cqrt_free(i32 %86)
  call void @cq_template_add_i64_unc(i32 %81, i32 %71, i32 %80)    ; IR: uncompute %45
  call void @cqrt_free(i32 %81)
  call void @cq_template_zext_i32_to_i64_unc(i32 %80, i32 %78)    ; IR: uncompute %44
  call void @cqrt_free(i32 %80)
  call void @cqrt_push(i32 %79)    ; IR: %42 of this trip (kept: only its handle), for the reverse loop
  call void @cqrt_push(i32 %82)    ; IR: %46 of this trip (kept: only its handle), for the reverse loop
  call void @cqrt_push(i32 %83)    ; IR: %48 of this trip (kept: only its handle), for the reverse loop
  %90 = icmp eq i32 %76, 0    ; IR: %56 = icmp eq i32 %39, 0  (classical: trip 0, and the latch test)
  br i1 %90, label %92, label %91

91:
  call void @cqrt_push(i32 %78)    ; IR: %41 of this trip, for the reverse loop (trip 0's is the kept load copy %10: not pushed)
  call void @cqrt_push(i32 %75)    ; IR: %38 of this trip, for the reverse loop (trip 0's is the kept load copy %14: not pushed)
  br label %92

92:
  %93 = add nuw nsw i32 %76, 1    ; IR: %55 = add nuw nsw i32 %39, 1  (classical)
  br i1 %90, label %74, label %94    ; IR: br i1 %56, label %37, label %35

94:
  %95 = phi i32 [ 0, %92 ], [ %103, %94 ]
  %96 = phi i32 [ %85, %92 ], [ %99, %94 ]    ; IR: %51 of the trip being undone
  %97 = phi i32 [ %84, %92 ], [ %98, %94 ]    ; IR: %50 of the trip being undone
  %98 = call i32 @cqrt_pop()    ; IR: %38 of that trip
  %99 = call i32 @cqrt_pop()    ; IR: %41 of that trip
  %100 = call i32 @cqrt_pop()    ; IR: %48 of that trip (kept: its handle)
  %101 = call i32 @cqrt_pop()    ; IR: %46 of that trip (kept: its handle)
  %102 = call i32 @cqrt_pop()    ; IR: %42 of that trip (kept: its handle)
  call void @cq_template_select_i32_unc(i32 %96, i32 %102, i32 %101, i32 %99)    ; IR: uncompute %51
  call void @cqrt_free(i32 %96)
  call void @cq_template_select_i64_unc(i32 %97, i32 %102, i32 %98, i32 %100)    ; IR: uncompute %50 (rule 6: undone by the reverse loop, the last trip's included)
  call void @cqrt_free(i32 %97)
  %103 = add nuw nsw i32 %95, 1
  %104 = icmp eq i32 %103, 1
  br i1 %104, label %105, label %94

105:
  %106 = call i32 @cqrt_pop()    ; IR: %48 of trip 0 (kept: its handle)
  %107 = call i32 @cqrt_pop()    ; IR: %46 of trip 0 (kept: its handle)
  %108 = call i32 @cqrt_pop()    ; IR: %42 of trip 0 (kept: its handle)
  call void @cq_template_select_i32_unc(i32 %99, i32 %108, i32 %107, i32 %68)    ; IR: uncompute %51 of trip 0 (against the load copy %10)
  call void @cqrt_free(i32 %99)
  call void @cq_template_select_i64_unc(i32 %98, i32 %108, i32 %72, i32 %106)    ; IR: uncompute %50 of trip 0 (against the load copy %14)
  call void @cqrt_free(i32 %98)
  call void @cqrt_qram_load_i32_hl_unc(i32 %68, i32 %3, i64 %15)    ; IR: un-copy %10 (after its last reader; overtaken by trip 0's store, so it stays allocated: rule 5 sentence 1)
  call void @cqrt_qram_load_i64_hl_unc(i32 %71, i32 %3, i64 %70)    ; IR: un-copy %13 (overtaken, stays allocated)
  call void @cqrt_qram_load_i64_hl_unc(i32 %72, i32 %3, i64 %69)    ; IR: un-copy %14 (overtaken, stays allocated)
  call void @llvm.va_end.p0(ptr %6)    ; IR: va_end(%3), as it stands (rule 16)
  call void @llvm.va_end.p0(ptr %4)    ; IR: va_end(%2), as it stands
  %109 = call i32 @cq_template_add_i32(i32 %88, i32 %47)    ; IR: %36 = add nsw i32 %54, %32  [the result: llvm.lifetime.end dropped]
  %110 = call i32 @cq_template_sub_i32(i32 %109, i32 %47)    ; IR: rule 6: (s + t) - s recomputes t (operand 0; neither operand is garbage, so s is kept)
  call void @cqrt_copy_i32(i32 %110, i32 %88)    ; IR: rule 6: t ^= that: |0>
  call void @cq_template_sub_i32_unc(i32 %110, i32 %109, i32 %47)
  call void @cqrt_free(i32 %110)
  call void @cqrt_free(i32 %88)    ; IR: rule 6: release the %54 rail (|0>)
  ret i32 %109    ; IR: ret i32 %36  [the rule-6 image is returned directly, no copy-out]
}

define i32 @vla_loop_q(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr {
  %5 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %13 / %10  [acc before trip 0: trip 0's old acc, cleaned by rule 6; measured itself when no trip runs]
  %8 = icmp sgt i32 %3, 0    ; IR: %6 = icmp sgt i32 %3, 0  (classical)
  br i1 %8, label %9, label %11    ; IR: br i1 %6, label %7, label %9

9:
  %10 = zext i32 %2 to i64    ; IR: %8 = zext i32 %2 to i64  (classical element count)
  br label %14    ; IR: br label %12

11:
  %12 = phi i32 [ %7, %4 ], [ %22, %14 ]    ; IR: %10 = phi i32 [ 0, %4 ], [ %19, %12 ]  (a classical phi over handles, rule 9)
  %13 = call i32 @cqrt_measure_i32(i32 %12)    ; IR: %11 = cq_measure_si32(%10)  [the carried acc: rule 6 left no other acc rail, so no copy-out and no reverse loop]
  ret i32 %13    ; IR: ret i32 %11

14:
  %15 = phi i32 [ %7, %9 ], [ %22, %14 ]    ; IR: %13 = phi i32 [ 0, %7 ], [ %19, %12 ]  (acc: a handle)
  %16 = phi i32 [ 0, %9 ], [ %24, %14 ]    ; IR: %14 = phi i32  (i, classical)
  %17 = mul i64 %10, 4    ; IR: %16 = alloca i32, i64 %8, align 16  [the VLA's size in bytes, 4 n (classical); %15 = llvm.stacksave() dropped (rule 16)]
  %18 = call ptr @__cq_alloc(i64 %17, i64 16)    ; IR: %16 = alloca i32, i64 %8, align 16  [bus-resident (passed to put): a zeroed block every trip, no alloca remains (rules 16, 20)]
  %19 = ptrtoint ptr %18 to i64    ; IR: %16 as its run-time address (classical)
  %20 = call i32 @cq_template_add_i32_hl(i32 %6, i32 %16)    ; IR: %17 = add nsw i32 %14, %5  (commutative: the _hl form)
  call fastcc void @__cq_q_put_01(ptr noundef %18, i32 noundef %20)    ; IR: call fastcc @put(%16, %17): the clone of mask 01 (the classical ptr stays a ptr, a value rail); it stores, so no twin (rule 18)
  call void @cq_template_add_i32_hl_unc(i32 %20, i32 %6, i32 %16)    ; IR: uncompute %17 (a template result the caller passed to a storing clone: its own rule, rule 5 sentence 3)
  call void @cqrt_free(i32 %20)    ; IR: release the %17 rail (|0>; the cell keeps its copy)
  %21 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %19)    ; IR: %18 = load i32, ptr %16  [v[0]: a bus load, a rail (rule 3)]
  %22 = call i32 @cq_template_add_i32(i32 %21, i32 %15)    ; IR: %19 = add nsw i32 %18, %13
  %23 = call i32 @cq_template_sub_i32(i32 %22, i32 %21)    ; IR: rule 6: t = acc' - v[0] recomputes the old acc (the other operand is the load copy, rule-5 garbage)
  call void @cqrt_copy_i32(i32 %23, i32 %15)    ; IR: rule 6: old acc ^= t: |0> (trip 0: the |0> seed, unchanged)
  call void @cq_template_sub_i32_unc(i32 %23, i32 %22, i32 %21)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %23)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %15)    ; IR: rule 6: release the old acc rail (|0> after the copy); it is not pushed
  call void @cqrt_qram_load_i32_hl_unc(i32 %21, i32 %5, i64 %19)    ; IR: un-copy %18 (rule 5: before the next trip's __cq_alloc)
  call void @cqrt_free(i32 %21)    ; IR: release the %18 rail (|0>); llvm.stackrestore(%15) dropped (rule 16)
  %24 = add nuw nsw i32 %16, 1    ; IR: %20 = add nuw nsw i32 %14, 1  (classical)
  %25 = icmp eq i32 %24, %3    ; IR: %21 = icmp eq i32 %20, %3  (classical bound)
  br i1 %25, label %11, label %14    ; IR: br i1 %21, label %9, label %12
}

define internal fastcc void @__cq_q_put_01(ptr noundef %0, i32 noundef %1) unnamed_addr {
  %3 = call i32 @__cq_mem()    ; the bus M
  %4 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address (mask digit 0: the formal is the C ptr)
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 %4, i32 %1)    ; IR: store i32 %1, ptr %0  [the value rail at a classical address; kept store: no _unc, the clone has no twin]
  ret void    ; IR: ret void
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)
declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cq_template_smin_i32_hl(i32, i32)
declare i32 @cq_template_bswap_i32(i32)
declare void @cq_template_bswap_i32_unc(i32, i32)
declare i32 @cq_template_usub_sat_i32_hl(i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)
declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i64(i32, i32, i32)
declare void @cq_template_select_i64_unc(i32, i32, i32, i32)
declare void @llvm.va_end.p0(ptr)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}
!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
