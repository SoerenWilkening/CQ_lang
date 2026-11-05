; HAND-WRITTEN. Rules: 20, 3, 14, 16, 5, 6, 7, 8, 4, 2.
; Checked: plain_local: x + c[j & 3] (measured, %12 -> %14). overtaint_kloop: x after the scan, x0 + the sum of the leading
; nonzero cells of c (measured: the carried rail x_K, %18 -> %41; rule 6 leaves it the only x rail).
; Clean: plain_local: the old x rail (%6, rule 6: |0> after the copy) and the inverse t (%13), both freed.
; overtaint_kloop: every trip's load copy (%14), exit test (%15) and trip predicate a_0..a_{K-1} (%16, the K-th body's
; included), popped and uncomputed by the reverse loop (no memory version change follows ext_fill, so every load is
; un-copied, rule 5 sentence 1); the after-trip-K load and test (%26, %27, undone at once); the |1> seed (%7, freed
; directly, rule 7); the OLD x of every trip (rule 6 in a rolled loop: x' = a ? x + v : x is a bijection in x and the
; trip predicate reads only memory, so the arm's garbage x + v is uncomputed first and t = a ? x' - v : x' is copied
; onto the old x; trip 0's old x is the rotated rail %6 itself, |0> after the copy and freed).
; Kept: plain_local: the sum (%12, measured). overtaint_kloop: x_K (%18 of the last trip, measured: the rotated
; register's rule-6 image) and a_K (%28, rule 14: the exit test c[K] != 0 evaluated after the K-th body, ANDed with the
; predicate of trip K; no bound of the trip count is known: the loop ends on a 0 read from memory, and the array's
; extent [4 x i32], the inbounds gep and the undefined behaviour of a fifth read are never a bound, rule 21). No store,
; no tape slot: neither function writes the bus (plain_local's stores are plain host stores, ext_fill writes host
; bytes).
; Rotations: plain_local: (Ry, x, tx, 1). overtaint_kloop: (Ry, x, tx, 1).
; plain_local. c is a HOST-RESIDENT alloca (rule 20 (b)): its size is untainted and its every transitive user, through
; getelementptrs with untainted indices (the induction %15, the classical j & 3), is a load with no quantum predicate
; in scope, a store through it of an untainted value (n * i + 1) with no quantum predicate in scope, or a lifetime
; marker. So the alloca, the store loop, the gep and the load stay the plain LLVM instructions, the lifetime markers
; stay with them, the loaded c[j & 3] is CLASSICAL (rule 3) and the function never calls __cq_mem. x + c[j & 3] is
; then example 01: a mixed add with the run-time classical value as the _hl literal, and rule 6 cleans the old x.
; overtaint_kloop. The same array is passed to a bodiless callee: a call is no user rule 20 (b) allows, so c is
; BUS-RESIDENT: __cq_alloc(16, 16) at the alloca's program point (rules 16, 20: zeroed, no alloca remains, the
; lifetime markers are dropped). ext_fill has classical arguments, no quantum predicate in scope and no tape or abort
; event before it: an ORDINARY HOST CALL (rule 16), made as it stands with the block's address. It writes host bytes,
; which the bus sees through the overlay (the cells stay HOST; nothing is seeded or copied). It is a memory version
; change, the last one of the function. Every load of c is a bus load and its value a rail, whatever ext_fill wrote
; (rule 3: over-taint is accepted, such a rail costs no qubit), so the exit test c[i] != 0 reads a rail and the loop
; is a K-LOOP (rule 14, K = 4; the literal 4 below is K). Re-rolled: -O1's pre-header guard (load c[0], == 0) is the
; latch test (load c[i + 1], == 0) one trip earlier, the same load at the affine address {c,+,4}, so it is trip 0.
; Trip j loads c[j] under the predicate of REACHING its test (a_{j-1}; the |1> seed for trip 0), forms
; a_j = a_{j-1} & (c[j] != 0) (the IR's flag is the == 0 exit edge, so the conjunction sits in an X bracket, rule 8)
; and runs the body x += c[j] under a_j through the select merge. The address is an AFFINE INDUCTION with a classical
; start: &c[j] is the classical i64 of the gep at the classical trip index, so every access is _hl; it is
; _hl_controlled because a trip C would not run must touch no cell and no host byte, and its _unc takes the same
; control. Nothing is loaded before the loop on its behalf. After the K-th body the test is evaluated once more
; (c[K], under a_{K-1}: one cell past the block, read only on the branch where C reads it too; no bound is checked,
; rule 21) and a_K is kept. The reverse loop recomputes each address from its trip index and pops the load copy, the
; test and the reach predicate of each trip.
; Basis check (driver: plain_local(3, .5, 2, 1); overtaint_kloop(3, .5, 2) with a host ext_fill that writes
; c = {n, n + 1, 0}, i.e. {2, 3, 0, 0}): Ry(.5) acts on each of the 32 qubits of x0 = 3, so x = 3 ^ e with
; P(e) = p^|e| (1 - p)^(32 - |e|), p = sin^2(.25) = 0.061209, |e| the number of flipped bits. plain_local: c = {1, 3,
; 5, 7}, c[1] = 3, the measured value is (3 ^ e) + 3 mod 2^32: 6 with probability (1 - p)^32 = 0.132498, each of the
; 32 one-flip values (5, 4, 10, 14, 22, ...) with 0.008639. overtaint_kloop: the tests read 2, 3, 0, so a_0 = a_1 = 1,
; a_2 = a_3 = 0 (trip 3's load is under a_2 = 0 and touches nothing), a_K = 0 on every branch, and the measured value
; is (3 ^ e) + 5 mod 2^32: 8 with probability 0.132498, each one-flip value (7, 6, 12, 16, 24, ...) with 0.008639.
; The memory is classical-valued throughout, so every load copy, test and predicate is a classical-valued rail.
source_filename = "bus_plain_and_overtaint.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @plain_local(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = alloca [4 x i32], align 16    ; IR: %5 = alloca [4 x i32], align 16  [host-resident (rule 20 (b)): the alloca stays]
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_si32(%0, %1)  [Ry]
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5)    ; IR: call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5)  [kept: host-resident]
  br label %15    ; IR: br label %14

7:
  %8 = and i32 %3, 3    ; IR: %8 = and i32 %3, 3
  %9 = zext nneg i32 %8 to i64    ; IR: %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %9    ; IR: %10 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %9  [untainted index: stays]
  %11 = load i32, ptr %10, align 4    ; IR: %11 = load i32, ptr %10  [plain load of a host-resident object: CLASSICAL (rule 3)]
  %12 = call i32 @cq_template_add_i32_hl(i32 %6, i32 %11)    ; IR: %12 = add nsw i32 %11, %6  [commutative: handle first, the classical load is the literal]
  %13 = call i32 @cq_template_sub_i32_hl(i32 %12, i32 %11)    ; IR: rule 6: t = y - c[j & 3] recomputes the old x (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %13, i32 %6)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_sub_i32_hl_unc(i32 %13, i32 %12, i32 %11)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %13)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %6)    ; IR: release the old x rail (|0> after the copy)
  %14 = call i32 @cqrt_measure_i32(i32 %12)    ; IR: %13 = cq_measure_si32(%12)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5)    ; IR: call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5)  [kept: host-resident]
  ret i32 %14    ; IR: ret i32 %13

15:
  %16 = phi i64 [ 0, %4 ], [ %21, %15 ]    ; IR: %15 = phi i64 [ 0, %4 ], [ %20, %14 ]
  %17 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %16    ; IR: %16 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %15
  %18 = trunc i64 %16 to i32    ; IR: %17 = trunc i64 %15 to i32
  %19 = mul i32 %18, %2    ; IR: %18 = mul i32 %17, %2
  %20 = add i32 %19, 1    ; IR: %19 = add i32 %18, 1
  store i32 %20, ptr %17, align 4    ; IR: store i32 %19, ptr %16  [plain store of an untainted value: a host store, no bus call]
  %21 = add nuw nsw i64 %16, 1    ; IR: %20 = add nuw nsw i64 %15, 1
  %22 = icmp eq i64 %21, 4    ; IR: %21 = icmp eq i64 %20, 4  [the source's own bound, not K]
  br i1 %22, label %7, label %15    ; IR: br i1 %21, label %7, label %14
}

define i32 @overtaint_kloop(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus handle m (once, at function entry)
  %5 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %4 = alloca [4 x i32], align 16  [bus-resident (passed to ext_fill): one zeroed block, no alloca]
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  call void @ext_fill(ptr noundef nonnull %5, i32 noundef %2)    ; IR: call void @ext_fill(ptr %4, i32 %2)  [ordinary host call (rule 16): as it stands; host bytes, seen through the overlay; a memory version change]
  %7 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the loop guard in %3 (always 1)
  br label %8

8:
  %9 = phi i64 [ 0, %3 ], [ %21, %8 ]    ; IR: trip index j, bounded by K (%12 = phi i64, the induction i)  [K]
  %10 = phi i32 [ %6, %3 ], [ %18, %8 ]    ; IR: %14 = phi i32 [ %15, %11 ], [ %5, %3 ]  [x]
  %11 = phi i32 [ %7, %3 ], [ %16, %8 ]    ; IR: predicate of reaching this trip's test
  %12 = getelementptr [4 x i32], ptr %5, i64 0, i64 %9    ; IR: &c[j]: %4 (trip 0) / %17 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %16  [affine induction, classical start: not carried]
  %13 = ptrtoint ptr %12 to i64    ; IR: its address, the _hl literal
  %14 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %11, i32 %4, i64 %13)    ; IR: %6 = load i32, ptr %4 (trip 0) / %18 = load i32, ptr %17  [a rail (rule 3); %13 = phi of the loaded value]
  %15 = call i32 @cq_template_icmp_eq_i32_hl(i32 %14, i32 0)    ; IR: %7 = icmp eq i32 %6, 0 (trip 0) / %19 = icmp eq i32 %18, 0
  %16 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of this trip
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket: the loop continues on the false edge (c[j] != 0)
  call void @cqrt_and_i1(i32 %11, i32 %15, i32 %16)    ; IR: br i1 %7 (trip 0) / br i1 %19 not taken to %8
  call void @cqrt_not_i1(i32 %15)    ; IR: bracket
  %17 = call i32 @cq_template_add_i32(i32 %14, i32 %10)    ; IR: %15 = add nsw i32 %13, %14
  %18 = call i32 @cq_template_select_i32(i32 %16, i32 %17, i32 %10)    ; IR: next %14 / %9 = a ? %15 : %14  [x_{j+1}: the only x rail after this trip]
  call void @cq_template_add_i32_unc(i32 %17, i32 %14, i32 %10)    ; IR: rule 6: the arm's garbage %15 is uncomputed first (its _unc reads the old x)
  call void @cqrt_free(i32 %17)    ; IR: release %15 (|0>)
  %19 = call i32 @cq_template_sub_i32(i32 %18, i32 %14)    ; IR: rule 6: x' - c[j]
  %20 = call i32 @cq_template_select_i32(i32 %16, i32 %19, i32 %18)    ; IR: rule 6: t = a ? x' - c[j] : x' recomputes the old x (the composite update is a bijection in x)
  call void @cqrt_copy_i32(i32 %20, i32 %10)    ; IR: rule 6: old x ^= t: |0> (trip 0: the rotated rail %6)
  call void @cq_template_select_i32_unc(i32 %20, i32 %16, i32 %19, i32 %18)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %20)    ; IR: release t (|0>)
  call void @cq_template_sub_i32_unc(i32 %19, i32 %18, i32 %14)    ; IR: rule 6: uncompute x' - c[j]
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %10)    ; IR: rule 6: release the old x rail (|0> after the copy); it is not pushed
  call void @cqrt_push(i32 %14)
  call void @cqrt_push(i32 %11)
  call void @cqrt_push(i32 %15)
  %21 = add nuw nsw i64 %9, 1    ; IR: %16 = add nuw nsw i64 %12, 1
  %22 = icmp ult i64 %21, 4    ; IR: K-bounded br i1 %19, label %8, label %11  [K]
  br i1 %22, label %8, label %23

23:
  %24 = getelementptr [4 x i32], ptr %5, i64 0, i64 4    ; IR: &c[K]: %17 = getelementptr after trip K  [K]
  %25 = ptrtoint ptr %24 to i64    ; IR: its address
  %26 = call i32 @cqrt_qram_load_i32_hl_controlled(i32 %16, i32 %4, i64 %25)    ; IR: %18 = load i32, ptr %17 after trip K, under the predicate of trip K
  %27 = call i32 @cq_template_icmp_eq_i32_hl(i32 %26, i32 0)    ; IR: %19 = icmp eq i32 %18, 0 after trip K: the exit test that would admit a (K+1)-th trip
  %28 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: a_K = predicate of trip K & that test  [output rail, kept]
  call void @cqrt_not_i1(i32 %27)    ; IR: bracket
  call void @cqrt_and_i1(i32 %16, i32 %27, i32 %28)    ; IR: br i1 %19 not taken once more (rule 14)
  call void @cqrt_not_i1(i32 %27)    ; IR: bracket
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %27, i32 %26, i32 0)    ; IR: uncompute that test
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %26, i32 %16, i32 %4, i64 %25)    ; IR: un-copy that load under the same control (rule 5)
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  br label %29

29:
  %30 = phi i64 [ 0, %23 ], [ %38, %29 ]    ; IR: reverse trip index
  %31 = phi i32 [ %16, %23 ], [ %33, %29 ]    ; IR: predicate of this trip
  %32 = call i32 @cqrt_pop()
  %33 = call i32 @cqrt_pop()
  %34 = call i32 @cqrt_pop()
  %35 = sub nuw nsw i64 3, %30    ; IR: this trip's index j = K - 1 - reverse index  [K]
  %36 = getelementptr [4 x i32], ptr %5, i64 0, i64 %35    ; IR: &c[j], recomputed from the trip index
  %37 = ptrtoint ptr %36 to i64    ; IR: its address
  call void @cqrt_not_i1(i32 %32)    ; IR: bracket
  call void @cqrt_and_i1(i32 %33, i32 %32, i32 %31)    ; IR: uncompute the predicate of this trip (every trip 1..K; a_K is a separate rail)
  call void @cqrt_not_i1(i32 %32)    ; IR: bracket
  call void @cqrt_free(i32 %31)    ; IR: release the predicate (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %32, i32 %34, i32 0)    ; IR: uncompute %7 / %19
  call void @cqrt_free(i32 %32)    ; IR: release %7 / %19 (|0>)
  call void @cqrt_qram_load_i32_hl_controlled_unc(i32 %34, i32 %33, i32 %4, i64 %37)    ; IR: un-copy %6 / %18 under the control it was loaded with (rule 5: no memory version change since the load)
  call void @cqrt_free(i32 %34)    ; IR: release %6 / %18 (|0>)
  %38 = add nuw nsw i64 %30, 1
  %39 = icmp ult i64 %38, 4    ; IR: K  [K]
  br i1 %39, label %29, label %40

40:
  call void @cqrt_free(i32 %33)    ; IR: release the |1> seed directly (rule 7: known basis state)
  %41 = call i32 @cqrt_measure_i32(i32 %18)    ; IR: %10 = cq_measure_si32(%9)  [x_K, the carried rail: rule 6 left no other x rail, so no copy-out]
  ret i32 %41    ; IR: ret i32 %10
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
declare void @ext_fill(ptr noundef, i32 noundef)
declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_qram_load_i32_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i32_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
