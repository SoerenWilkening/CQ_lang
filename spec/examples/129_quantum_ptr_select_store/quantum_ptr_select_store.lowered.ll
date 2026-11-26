; HAND-WRITTEN. Rules: 2, 3, 4, 5, 6, 7, 8, 9, 16, 18, 19, 20, 21; §1.3 (the bus, __cq_mem, __cq_alloc), §1.4.
; Checked: ptr_select_rmw: the cells a and b at exit (read from the bus): a = a' + 2*[x > k], b = b' + 2*[x <= k], a' and b'
; the rotated cells; the two load copies of a and b after the call (%45, %47), measured and summed classically.
; guarded_field_store: s[0].f + s[1].f + s[i].g (the add rail %39, measured -> %40); the cells of s at exit: s[0] = {c, 7},
; s[1] = {c + 1, 8}, then s[i].f = (x > k) ? ((y > c) ? 3y : y - c) : s[i].f.
; Clean: ptr_select_rmw: the swap rails of the in-place forms of cq_theta(&a, ta) and cq_theta(&b, tb) (%35, %39);
; the flag x > k (%42) and the address rail p (%43), uncomputed after p's last reader, the call; the one rail of the
; in-place form of *p += 1 (the swap rail %44, updated in place by rule 6, |0> after the swap-in); the swap rail of
; __cq_q_bump_1 (its own in-place form). guarded_field_store: the hoisted arm chain y > c (%25), 3y (%26), y - c (%27),
; uncomputed after their last consumer, the in-arm select; the post-merge add %34; the load copies of s[0].f (%32),
; s[1].f (%33) and s[i].g (%38), un-copied after their last reader: no memory version change follows them.
; Kept: ptr_select_rmw: x (%24), the rotated register; the cells a and b, rotated in place; by rule 5, for the shot: the
; tape slots of the stores a = a0, b = b0 and the seed value rails a0 (%12) and b0 (%23); on the OVERLAP paths only
; (d = 0, never taken at run time: a and b are distinct blocks), the rotated load copies %22 and %33 (frozen, rule 2)
; as the value rails of the kept stores a = a', b = b' with their tape slots; the load copies of a (%45) and b (%47),
; measured (rule 2).
; guarded_field_store: x (%11) and y (%12), the rotated registers; the result rail %39 (measured); by rule 5, for the
; shot: the tape slots of the five stores (s[0].f = c, s[0].g = 7, s[1].f = c + 1, s[1].g = 8, the guarded s[i].f), the
; seed value rails c (%13), 7 (%16), c + 1 (%20), 8 (%23), and the guarded store's value rail, the in-arm select (%28),
; and its control rail, the predicate B = x > k (%24) (rules 5, 8).
; Rotations: (Ry, x, th, 1); (Ry, cell a, ta, 1); (Ry, cell b, tb, 1) in ptr_select_rmw; (Ry, x, th, 1); (Ry, y, ty, 1) in
; guarded_field_store.
; ONE BUS (rules 20, 21). Every memory access is a bus access of m = __cq_mem() at the pointer's run-time address; no
; object, tag, table, slot or cell count exists anywhere.
; ptr_select_rmw: the allocas of a and b have a rail stored through them and a select among their users, so both are
; bus-resident (rule 20 (b)): each is __cq_alloc(4, 4) at its program point, no alloca remains and the lifetime markers
; are dropped (rule 16). `int a = a0` is a kept store of the seed a0 (rule 7); cq_theta(&a, ta) reads the value -O1
; forwarded from that store, so by rule 5's Readers clause it is the IN-PLACE FORM on the cell a (swap-out, Ry,
; swap-in, free), closed by `store %11, ptr %8`; likewise b. The pointer `(x > k) ? &a : &b` is a select under a quantum flag: ONE 64-bit address rail
; select_i64_ll(flag, &a, &b), the two classical addresses entering as their run-time i64 (rule 21). `*p += 1` is load,
; add, store through that SSA pointer with nothing between: rule 5's IN-PLACE FORM at the address rail (the plain swaps),
; with rule 6's in-place update (addc_i32 on the swap rail) as its step; nothing remains of it. bump(p) passes the address rail as one scalar: the clone
; __cq_q_bump_1 (mask digit 1, nothing about the pointee), whose body is the same in-place form at its formal. bump
; writes memory, so the clone has no twin (rule 18), and the caller uncomputes the address rail, a template result, after
; the call as after its own store (rule 5, sentence 3), then the flag. bump's own symbol has no caller left and is
; dropped (§1.4). The loads of a and b after the call are fresh bus loads at classical addresses, measured.
; guarded_field_store: the alloca of s has a store of a rail under a quantum predicate among its users, so it is
; bus-resident: __cq_alloc(16, 16). The four initializing stores are kept stores of seeds at classical addresses (the
; cells stay HOST). The arm's chain (%17..%20) is pure and hoisted unguarded (rule 9); its address s[i].f is classical
; (a classical base and the classical index i), so the guarded store is ONE qram_store_i32_hl_controlled under B: a
; kept store, so its value rail (the in-arm select) and its control rail B stay for the shot (rules 5, 8); the select's
; operands are garbage and are uncomputed. After the join every load is a bus load and its result a rail (rule 3), the
; g cell s[i].g included, so the last add is the template on two handles. The two adds have only garbage operands
; (load copies and a template result), so rule 6 has no trigger (198); the load copies are un-copied after their last
; reader, before the measurement.
; cq_theta(&a, ta) after `int a = a0` reaches the -O1 IR as cq_theta_si32(%3, %4) on the classical parameter forwarded
; from `store i32 %3, ptr %8` (no load). a's interval (store a0 .. store a') contains the store b0 at the classical
; address &b, and b's interval (store b0 .. store b') contains a's form at &a: each is the Readers clause's test with
; one change (p and q classical, S = 4): d computed before the change, br d around a plain load of the cell (the copy,
; taken when d = 0), the change, then br d at the store's position: d = 1 the form on the cell, d = 0 the Ry on the copy
; and a kept store (as 121's strcmp).
; SPEC GAP: rule 5 sentence 1 un-copies a load after its last reader's uncompute; the consumer of s[i].g's copy (%38), the add %39,
; is measured and has none. Un-copied right after it, before the measurement, as in 198 and 200.
source_filename = "quantum_ptr_select_store.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.pair = type { i32, i32 }

define i32 @ptr_select_rmw(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, double noundef %6) {
  %8 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %9 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %8 = alloca i32, align 4: a is bus-resident (rule 20 (b)); llvm.lifetime.start dropped
  %10 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %9 = alloca i32, align 4: b is bus-resident
  %11 = ptrtoint ptr %9 to i64    ; IR: %8 as its run-time address (classical): p of a's form
  %12 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: store i32 %3, ptr %8: the value seed a0 (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %11, i32 %12)    ; IR: store i32 %3, ptr %8: a = a0  (kept store at a classical address; the interval of a's form runs from here)
  %13 = ptrtoint ptr %10 to i64    ; IR: %9 as its run-time address (classical): q, the address of the change in a's interval
  %14 = sub i64 %13, %11    ; IR: (no instruction) Readers, a's interval, change 1 (store b0 at &b): q - p mod 2^64
  %15 = icmp uge i64 %14, 4    ; IR: (no instruction) q - p >= S_p, S_p = 4 cells
  %16 = sub i64 %11, %13    ; IR: (no instruction) p - q mod 2^64
  %17 = icmp uge i64 %16, 4    ; IR: (no instruction) p - q >= S_q, S_q = 4 cells
  %18 = and i1 %15, %17    ; IR: (no instruction) d_a: a's cell is disjoint from the change in its interval (classical, run time), computed before the change
  br i1 %18, label %21, label %19    ; IR: (no instruction) Readers: d_a = 1 DISJOINT: no copy; d_a = 0 OVERLAP: the copy below

19:
  %20 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %11)    ; IR: the forwarded %3 as a rail: a plain load of a taken before the change (rule 5, Readers)  [OVERLAP path only]
  br label %21    ; IR: (no instruction)

21:
  %22 = phi i32 [ poison, %7 ], [ %20, %19 ]    ; IR: (no instruction) the copy's handle on the OVERLAP path (classical phi; poison, never read, on the DISJOINT path)
  %23 = call i32 @cqrt_alloc_i32(i32 %5)    ; IR: store i32 %5, ptr %9: the value seed b0 (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %13, i32 %23)    ; IR: store i32 %5, ptr %9: b = b0  (kept store; change 1 of a's interval; the interval of b's form runs from here)
  %24 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %10 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %24, double %1)    ; IR: %10 = cq_theta_si32(%0, %1)  [Ry]
  %25 = sub i64 %11, %13    ; IR: (no instruction) Readers, b's interval, change 1 (a's form or kept store at &a): q - p mod 2^64
  %26 = icmp uge i64 %25, 4    ; IR: (no instruction) q - p >= S_p
  %27 = sub i64 %13, %11    ; IR: (no instruction) p - q mod 2^64
  %28 = icmp uge i64 %27, 4    ; IR: (no instruction) p - q >= S_q
  %29 = and i1 %26, %28    ; IR: (no instruction) d_b, computed before the change
  br i1 %29, label %32, label %30    ; IR: (no instruction) Readers: d_b = 1 DISJOINT: no copy; d_b = 0 OVERLAP: the copy below

30:
  %31 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %13)    ; IR: the forwarded %5 as a rail: a plain load of b taken before the change (rule 5, Readers)  [OVERLAP path only]
  br label %32    ; IR: (no instruction)

32:
  %33 = phi i32 [ poison, %21 ], [ %31, %30 ]    ; IR: (no instruction) the copy's handle on the OVERLAP path (poison on the DISJOINT path)
  br i1 %18, label %34, label %36    ; IR: (no instruction) Readers: the same d_a, at the store's position: DISJOINT: a's form stands; OVERLAP: the step acts on the copy

34:
  %35 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %11 = cq_theta_si32(%3, %4): in-place form on a (the %3 forwarded from its store, rule 5 Readers), the swap rail (|0>)  [DISJOINT path]
  call void @cqrt_qram_swap_i32_hl(i32 %8, i64 %11, i32 %35)    ; IR: %11 = cq_theta_si32(%3, %4): swap-out: the rail holds a (a0), the cell |0>
  call void @cqrt_ry_i32(i32 %35, double %4)    ; IR: %11 = cq_theta_si32(%3, %4)  [Ry in place on a's content]
  call void @cqrt_qram_swap_i32_hl(i32 %8, i64 %11, i32 %35)    ; IR: store i32 %11, ptr %8: swap-in: the cell holds a'
  call void @cqrt_free(i32 %35)    ; IR: release the swap rail (|0>)
  br label %37    ; IR: (no instruction)

36:
  call void @cqrt_ry_i32(i32 %22, double %4)    ; IR: %11 = cq_theta_si32(%3, %4)  [Ry on the load copy: a frozen register from here on, rule 2]  [OVERLAP path]
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %11, i32 %22)    ; IR: store i32 %11, ptr %8  (a kept store: its tape slot and its value rail stay, rule 5 sentence 3)
  br label %37    ; IR: (no instruction)

37:
  br i1 %29, label %38, label %40    ; IR: (no instruction) Readers: the same d_b, at the store's position

38:
  %39 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %12 = cq_theta_si32(%5, %6): in-place form on b (the forwarded %5), the swap rail (|0>)  [DISJOINT path]
  call void @cqrt_qram_swap_i32_hl(i32 %8, i64 %13, i32 %39)    ; IR: %12 = cq_theta_si32(%5, %6): swap-out: the rail holds b (b0), the cell |0>
  call void @cqrt_ry_i32(i32 %39, double %6)    ; IR: %12 = cq_theta_si32(%5, %6)  [Ry in place on b's content]
  call void @cqrt_qram_swap_i32_hl(i32 %8, i64 %13, i32 %39)    ; IR: store i32 %12, ptr %9: swap-in: the cell holds b'
  call void @cqrt_free(i32 %39)    ; IR: release the swap rail (|0>)
  br label %41    ; IR: (no instruction)

40:
  call void @cqrt_ry_i32(i32 %33, double %6)    ; IR: %12 = cq_theta_si32(%5, %6)  [Ry on the load copy: frozen, rule 2]  [OVERLAP path]
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %13, i32 %33)    ; IR: store i32 %12, ptr %9  (a kept store, rule 5 sentence 3)
  br label %41    ; IR: (no instruction)

41:
  %42 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %24, i32 %2)    ; IR: %13 = icmp sgt i32 %10, %2
  %43 = call i32 @cq_template_select_i64_ll(i32 %42, i64 %11, i64 %13)    ; IR: %14 = select i1 %13, ptr %8, ptr %9  [rule 21: the address rail p = flag ? &a : &b]
  %44 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %15 = load i32, ptr %14 ... store i32 %16, ptr %14: the in-place form (rule 5), the swap rail (|0>)
  call void @cqrt_qram_swap_i32(i32 %8, i32 %43, i32 %44)    ; IR: %15 = load i32, ptr %14: swap-out at the address rail: the rail holds *p, the cell |0>
  call void @cqrt_addc_i32(i32 %44, i32 1)    ; IR: %16 = add nsw i32 %15, 1  [rule 6, in-place update: the old *p is dead after the add, so *p + 1 IS the swap rail]
  call void @cqrt_qram_swap_i32(i32 %8, i32 %43, i32 %44)    ; IR: store i32 %16, ptr %14: swap-in: the cell holds *p + 1, the rail the cell's |0>
  call void @cqrt_free(i32 %44)    ; IR: release the swap rail (|0>): nothing remains of the update
  call fastcc void @__cq_q_bump_1(i32 %43)    ; IR: call fastcc void @bump(ptr %14): the clone of mask 1, the pointer as ONE address rail (§1.4); it writes memory, so it has no twin (rule 18)
  call void @cq_template_select_i64_ll_unc(i32 %43, i32 %42, i64 %11, i64 %13)    ; IR: uncompute %14 (the address rail: its last reader was the call, rule 5 sentence 3)
  call void @cqrt_free(i32 %43)    ; IR: release the %14 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %42, i32 %24, i32 %2)    ; IR: uncompute %13
  call void @cqrt_free(i32 %42)    ; IR: release the %13 rail (|0>)
  %45 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %11)    ; IR: %17 = load i32, ptr %8  (a bus load at a classical address: a fresh rail)
  %46 = call i32 @cqrt_measure_i32(i32 %45)    ; IR: %18 = cq_measure_si32(%17)  (the measured load copy stays allocated, rule 2)
  %47 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %13)    ; IR: %19 = load i32, ptr %9
  %48 = call i32 @cqrt_measure_i32(i32 %47)    ; IR: %20 = cq_measure_si32(%19)
  %49 = add nsw i32 %48, %46    ; IR: %21 = add nsw i32 %20, %18  (classical; llvm.lifetime.end dropped)
  ret i32 %49    ; IR: ret i32 %21
}

define internal fastcc void @__cq_q_bump_1(i32 noundef %0) unnamed_addr {
  %2 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %3 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %2 = load i32, ptr %0 ... store i32 %3, ptr %0: the in-place form (rule 5), the swap rail (|0>)
  call void @cqrt_qram_swap_i32(i32 %2, i32 %0, i32 %3)    ; IR: %2 = load i32, ptr %0: swap-out at the address rail %0: the rail holds *p, the cell |0>
  call void @cqrt_addc_i32(i32 %3, i32 1)    ; IR: %3 = add nsw i32 %2, 1  [rule 6, in-place update: the old *p is dead after the add, so *p + 1 IS the swap rail]
  call void @cqrt_qram_swap_i32(i32 %2, i32 %0, i32 %3)    ; IR: store i32 %3, ptr %0: swap-in: the cell holds *p + 1, the rail the cell's |0>
  call void @cqrt_free(i32 %3)    ; IR: release the swap rail (|0>): nothing remains (the address rail is the caller's)
  ret void    ; IR: ret void
}

define i32 @guarded_field_store(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, i32 noundef %5, i32 noundef %6) {
  %8 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %9 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %8 = alloca [2 x %struct.pair], align 16: s is bus-resident (a rail is stored into it under a quantum predicate, rule 20 (b))
  %10 = ptrtoint ptr %9 to i64    ; IR: %8 as its run-time address (classical)
  %11 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %11, double %1)    ; IR: %9 = cq_theta_si32(%0, %1)  [Ry]
  %12 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %10 = cq_theta_si32(%3, %4)  [register y]
  call void @cqrt_ry_i32(i32 %12, double %4)    ; IR: %10 = cq_theta_si32(%3, %4)  [Ry]
  %13 = call i32 @cqrt_alloc_i32(i32 %5)    ; IR: store i32 %5, ptr %8: the value seed c (rule 7; kept with the store); llvm.lifetime.start dropped
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %10, i32 %13)    ; IR: store i32 %5, ptr %8: s[0].f = c  (kept store)
  %14 = getelementptr inbounds i8, ptr %9, i64 4    ; IR: %11 = getelementptr inbounds i8, ptr %8, i64 4  (nothing tainted: the gep stays)
  %15 = ptrtoint ptr %14 to i64    ; IR: %11 as its run-time address
  %16 = call i32 @cqrt_alloc_i32(i32 7)    ; IR: store i32 7, ptr %11: the value seed 7
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %15, i32 %16)    ; IR: store i32 7, ptr %11: s[0].g = 7  (kept store)
  %17 = getelementptr inbounds i8, ptr %9, i64 8    ; IR: %12 = getelementptr inbounds i8, ptr %8, i64 8
  %18 = ptrtoint ptr %17 to i64    ; IR: %12 as its run-time address
  %19 = add nsw i32 %5, 1    ; IR: %13 = add nsw i32 %5, 1  (classical)
  %20 = call i32 @cqrt_alloc_i32(i32 %19)    ; IR: store i32 %13, ptr %12: the value seed c + 1
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %18, i32 %20)    ; IR: store i32 %13, ptr %12: s[1].f = c + 1  (kept store)
  %21 = getelementptr inbounds i8, ptr %9, i64 12    ; IR: %14 = getelementptr inbounds i8, ptr %8, i64 12
  %22 = ptrtoint ptr %21 to i64    ; IR: %14 as its run-time address
  %23 = call i32 @cqrt_alloc_i32(i32 8)    ; IR: store i32 8, ptr %14: the value seed 8
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %22, i32 %23)    ; IR: store i32 8, ptr %14: s[1].g = 8  (kept store)
  %24 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %11, i32 %2)    ; IR: %15 = icmp sgt i32 %9, %2  [predicate B of block %16; it controls a kept store: kept]
  %25 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %12, i32 %5)    ; IR: %17 = icmp sgt i32 %10, %5  (block %16, hoisted: pure)
  %26 = call i32 @cq_template_mul_i32_hl(i32 %12, i32 3)    ; IR: %18 = mul nsw i32 %10, 3  (hoisted)
  %27 = call i32 @cq_template_sub_i32_hl(i32 %12, i32 %5)    ; IR: %19 = sub nsw i32 %10, %5  (hoisted)
  %28 = call i32 @cq_template_select_i32(i32 %25, i32 %26, i32 %27)    ; IR: %20 = select i1 %17, i32 %18, i32 %19  [the in-arm select; the value rail of the guarded store: kept]
  call void @cq_template_sub_i32_hl_unc(i32 %27, i32 %12, i32 %5)    ; IR: uncompute %19 (its last consumer, the select, is kept and never uncomputed)
  call void @cqrt_free(i32 %27)    ; IR: release the %19 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %26, i32 %12, i32 3)    ; IR: uncompute %18
  call void @cqrt_free(i32 %26)    ; IR: release the %18 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %25, i32 %12, i32 %5)    ; IR: uncompute %17
  call void @cqrt_free(i32 %25)    ; IR: release the %17 rail (|0>)
  %29 = sext i32 %6 to i64    ; IR: %21 = sext i32 %6 to i64  (classical)
  %30 = getelementptr inbounds [2 x %struct.pair], ptr %9, i64 0, i64 %29    ; IR: %22 = getelementptr inbounds [2 x %struct.pair], ptr %8, i64 0, i64 %21  (nothing tainted: the gep stays)
  %31 = ptrtoint ptr %30 to i64    ; IR: %22 as its run-time address (the classical address of s[i].f)
  call void @cqrt_qram_store_i32_hl_controlled(i32 %24, i32 %8, i64 %31, i32 %28)    ; IR: store i32 %20, ptr %22 under B  (never hoisted: the _controlled form; kept store: its tape slot, value rail %20 and control rail %15 stay, rule 5)
  %32 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %10)    ; IR: %24 = load i32, ptr %8  [s[0].f, a rail]
  %33 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %18)    ; IR: %25 = load i32, ptr %12  [s[1].f]
  %34 = call i32 @cq_template_add_i32(i32 %33, i32 %32)    ; IR: %26 = add nsw i32 %25, %24
  %35 = sext i32 %6 to i64    ; IR: %27 = sext i32 %6 to i64  (classical)
  %36 = getelementptr inbounds [2 x %struct.pair], ptr %9, i64 0, i64 %35, i32 1    ; IR: %28 = getelementptr inbounds [2 x %struct.pair], ptr %8, i64 0, i64 %27, i32 1  (nothing tainted: the gep stays)
  %37 = ptrtoint ptr %36 to i64    ; IR: %28 as its run-time address (the classical address of s[i].g)
  %38 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %37)    ; IR: %29 = load i32, ptr %28  [s[i].g: every load is a bus load, a rail (rule 3)]
  %39 = call i32 @cq_template_add_i32(i32 %34, i32 %38)    ; IR: %30 = add nsw i32 %26, %29  [result rail]
  call void @cq_template_add_i32_unc(i32 %34, i32 %33, i32 %32)    ; IR: uncompute %26
  call void @cqrt_free(i32 %34)    ; IR: release the %26 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %38, i32 %8, i64 %37)    ; IR: un-copy %29 (no memory version change since the load, rule 5)  ; SPEC GAP: its consumer %30 is measured and has no _unc (header)
  call void @cqrt_free(i32 %38)    ; IR: release the %29 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %33, i32 %8, i64 %18)    ; IR: un-copy %25 (its last reader was the _unc of %26)
  call void @cqrt_free(i32 %33)    ; IR: release the %25 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %32, i32 %8, i64 %10)    ; IR: un-copy %24
  call void @cqrt_free(i32 %32)    ; IR: release the %24 rail (|0>)
  %40 = call i32 @cqrt_measure_i32(i32 %39)    ; IR: %31 = cq_measure_si32(%30)  (llvm.lifetime.end dropped)
  ret i32 %40    ; IR: ret i32 %31
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)
declare void @cqrt_qram_swap_i32(i32, i32, i32)
declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare void @cqrt_addc_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
