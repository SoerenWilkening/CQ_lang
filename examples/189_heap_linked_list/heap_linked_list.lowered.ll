; HAND-WRITTEN. Rules: 2, 3, 4, 5, 7, 8, 9, 14, 16, 20, 21.
; Checked: list_search: p ? i : -1, the index of the first node whose v equals key, else -1 (the copied-out result,
; measured). calloc_aligned: r = s[j & 1] + 1 (measured).
; Clean: list_search: every trip rail (the load copy of p->v, the found flag, the body predicate, the address rail
; p + 8, the load copy of p->next, the null flag, the trip's exit value, the carried result and pointer selects, the
; predicates A[1]..A[K-1]) popped and uncomputed by the reverse loop (no memory version change follows the stores, so
; both loads of every trip are un-copied, rule 5 sentence 1), plus the three seeds (p = the address of a, the result
; 0, the |1> predicate) freed directly. calloc_aligned: the address chain of a[k & 3] (k & 3, its zext, the scaling by
; 4, the add of a's address), uncomputed right after its store; the load copy s[j & 1], un-copied after its last
; reader (no memory version change follows it).
; Kept: list_search: x and y (rotated; also the value rails of the kept stores a->v = x, b->v = y); the seed value
; rails of the kept stores a->next = b, b->next = c, c->v = 7, c->next = NULL (rule 7) and the tape slots of all six
; stores (rule 5 sentence 3); the result (measured) and the output predicate A[K] (rule 14: LLVM knows no bound of
; the trip count, the loop ends on a 0 read from memory; A[K] is 0 on every branch here, since the list has three
; nodes, but the compiler cannot prove it). calloc_aligned: k and x (rotated; x is also the value rail of the kept
; store a[k & 3] = x); the load copy a[1] (the value rail of the kept store s[0] = a[1]: overtaken by it, rule 5);
; the rail x + 1 (the value rail of the kept store s[1] = x + 1); the tape slots of the three stores; r (measured).
; Rotations: list_search: (Ry, x, tx, 1); (Ry, y, ty, 1). calloc_aligned: (Ry, k, tk, 1); (Ry, x, tx, 1).
; Driver: list_search(3, .5, 4, .25, 4): on the all-unflipped branch x = 3, y = 4, the key sits in b and the
; measured value is 1; list_search(3, .5, 4, .25, 9): no node holds 9, c->next = NULL ends the scan and the value is
; -1; calloc_aligned(1, .5, 7, .25, 1): r = s[1] + 1 = x + 2 = 9 on that branch.
; list_search. ALLOCATION (rule 16): each malloc(16) is __cq_alloc(16, 16) at its program point (zeroed, never
; reused, alignment 16: the call names none); nothing is known about the three blocks at compile time, and nothing in
; the lowering asks which node a pointer addresses. A pointer is its run-time i64 (rule 21): a, b, c are classical
; addresses (ptrtoint). Every store is a bus store (rule 20; heap blocks are never host-resident): p->v at the block
; address, p->next at address + 8 (the classical getelementptr spelled as the add of its byte offset), a classical
; value first minted as a seed (alloc_i32(7), alloc_i64 of b's and c's addresses, alloc_i64(0) for NULL: a pointer in
; memory is an i64 cell value, rule 21) and kept with its store (rules 5, 7).
; LOOP: the exit p->v != key reads a value loaded from the bus, and p itself is loaded from the bus after trip 0, so
; the loop is a K-loop (rule 14, cutoff K = 4: no range bound B exists) and p is ONE 64-bit address rail (rule 21),
; carried by select on the next-trip predicate. A trip is one execution of the header %14; trip j runs under A[j]
; (A[0] = |1> seed), the body %19 under B[j] = A[j] & NOT found[j], and the next header under A[j+1] = B[j] & NOT
; null[j]. Trip 0's p is a classical start and enters as the seed alloc_i64(a) (rule 14). Each dereference is ONE bus
; access at the address rail, with no guard and no bounds check (rule 21): p->v is qram_load_i32 at p, p->next is
; qram_load_i64 at the address rail add_i64_hl(p, 8), and the loaded i64 is the next p as it stands. Both loads are
; read by an exit test, so each is _controlled under the predicate of REACHING that test (rule 14): p->v under A[j],
; p->next under B[j]; a trip C would not run touches no cell. The NULL test is icmp_eq_i64_hl(next, 0) (rule 21:
; NULL is the literal 0). i is the induction variable %16 = j (SCEV), a classical trip index. The exit phi %25 is
; carried as the result rail r: trip j sets r = found[j] ? j : -1 under A[j] (an exit at %14 yields j, a continue sets
; the provisional -1 that the NULL exit at %19 keeps). After K trips r is copied out, and the reverse loop pops each
; trip: the selects, the null flag, the p->next load (un-copied under B[j], which is still allocated), its address
; rail (it outlives the load's _unc, rule 20), B[j], the found flag and the p->v load (un-copied under A[j]); on
; reverse index 0 (trip K-1) it keeps A[K] (rule 14: the test that would admit a (K+1)-th trip). free is never
; called by the program; it would be nothing (rule 16).
; SPEC GAP (rule 14, two exit tests per trip): rule 14 spells a_K for one exit test per trip. Chosen, as before the
; memory regeneration: a trip is header test, body, latch test; A[K] is the predicate of reaching the header after
; the K-th latch test (the latch test after the K-th body, under B[K-1]); no header test of a (K+1)-th trip is made.
; calloc_aligned. calloc(4, 4) is __cq_alloc(16, 16) (size n·s, zeroed, so nothing is written for calloc's zero fill)
; and aligned_alloc(16, 16) is __cq_alloc(16, 16) (rule 16). a[k & 3] = x: the getelementptr has a tainted index, so
; it is 64-bit template arithmetic into an address rail (zext of k & 3, mul by 4, add of a's address; rule 20) and the
; store is qram_store_i32 at that rail, a kept store; the address chain is uncomputed right after it. s[0] = a[1]: the
; load qram_load_i32_hl at the classical address a + 4 and a kept store qram_store_i32_hl at s; the load copy is the
; store's value rail and is kept. s[1] = x + 1: the template, then a kept store at s + 4; the rail x + 1 is kept with
; it. s[j & 1]: the getelementptr has a classical run-time index, so it stays and its address is the _hl operand of
; qram_load_i32_hl; its copy is un-copied right after its last reader, the add r = s[j & 1] + 1 (rule 5 sentence 1:
; no memory version change follows). free(a) and free(s) are nothing (rule 16).
source_filename = "heap_linked_list.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @list_search(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @__cq_mem()    ; IR: the bus M (called once, at function entry)
  %7 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %6 = malloc(16): c  [rule 16: zeroed, never reused, the size 16 at c - 8]
  %8 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %7 = malloc(16): b
  %9 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %8 = malloc(16): a
  %10 = ptrtoint ptr %7 to i64    ; IR: %6 as its run-time address (classical)
  %11 = ptrtoint ptr %8 to i64    ; IR: %7 as its run-time address (classical)
  %12 = ptrtoint ptr %9 to i64    ; IR: %8 as its run-time address (classical)
  %13 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %13, double %1)    ; IR: %9 = cq_theta_si32(%0, %1)  [Ry]
  %14 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %10 = cq_theta_si32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %14, double %3)    ; IR: %10 = cq_theta_si32(%2, %3)  [Ry]
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %12, i32 %13)    ; IR: store i32 %9, ptr %8: a->v = x  [kept store: its slot and its value rail x stay]
  %15 = add i64 %12, 8    ; IR: %11 = getelementptr inbounds i8, ptr %8, i64 8  (classical)
  %16 = call i32 @cqrt_alloc_i64(i64 %11)    ; IR: store ptr %7, ptr %11: the stored address of b as a seed rail, kept with its store (rule 7)
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %15, i32 %16)    ; IR: store ptr %7, ptr %11: a->next = b  [kept store]
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %11, i32 %14)    ; IR: store i32 %10, ptr %7: b->v = y  [kept store]
  %17 = add i64 %11, 8    ; IR: %12 = getelementptr inbounds i8, ptr %7, i64 8  (classical)
  %18 = call i32 @cqrt_alloc_i64(i64 %10)    ; IR: store ptr %6, ptr %12: the address of c as a seed rail (rule 7)
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %17, i32 %18)    ; IR: store ptr %6, ptr %12: b->next = c  [kept store]
  %19 = call i32 @cqrt_alloc_i32(i32 7)    ; IR: store i32 7, ptr %6: the seed 7 (rule 7)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %10, i32 %19)    ; IR: store i32 7, ptr %6: c->v = 7  [kept store]
  %20 = add i64 %10, 8    ; IR: %13 = getelementptr inbounds i8, ptr %6, i64 8  (classical)
  %21 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: store ptr null, ptr %13: NULL as the seed 0 (rules 7, 21)
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %20, i32 %21)    ; IR: store ptr null, ptr %13: c->next = NULL  [kept store]
  %22 = call i32 @cqrt_alloc_i64(i64 %12)    ; IR: %15 = phi ptr [ %8, %5 ]: p before trip 0, the classical start a as a seed (rule 14)
  %23 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: the result before trip 0 (never read: A[0] = 1)  [seed]
  %24 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the header in trip 0 (always 1)
  br label %25

25:
  %26 = phi i32 [ 0, %5 ], [ %40, %25 ]    ; IR: %16 = phi i32 [ 0, %5 ], [ %20, %19 ]: i = the trip index (SCEV), bounded by K  [K]
  %27 = phi i32 [ %22, %5 ], [ %39, %25 ]    ; IR: %15 = phi ptr [ %8, %5 ], [ %22, %19 ]: p, a 64-bit address rail
  %28 = phi i32 [ %23, %5 ], [ %38, %25 ]    ; IR: the exit value %25 so far
  %29 = phi i32 [ %24, %5 ], [ %36, %25 ]    ; IR: predicate of reaching the header %14 in this trip
  %30 = call i32 @cqrt_qram_load_i32_controlled(i32 %29, i32 %6, i32 %27)    ; IR: %17 = load i32, ptr %15: p->v at the address rail, under the predicate of reaching the test %18
  %31 = call i32 @cq_template_icmp_eq_i32_hl(i32 %30, i32 %4)    ; IR: %18 = icmp eq i32 %17, %4  [found]
  %32 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %19 in this trip
  call void @cqrt_not_i1(i32 %31)    ; IR: bracket: the body runs when p->v != key
  call void @cqrt_and_i1(i32 %29, i32 %31, i32 %32)    ; IR: br i1 %18 not taken: B = A & NOT found
  call void @cqrt_not_i1(i32 %31)    ; IR: bracket
  %33 = call i32 @cq_template_add_i64_hl(i32 %27, i64 8)    ; IR: %21 = getelementptr inbounds i8, ptr %15, i64 8  [address rail p + 8]
  %34 = call i32 @cqrt_qram_load_i64_controlled(i32 %32, i32 %6, i32 %33)    ; IR: %22 = load ptr, ptr %21: p->next at the address rail, under B (the predicate of reaching the test %23)
  %35 = call i32 @cq_template_icmp_eq_i64_hl(i32 %34, i64 0)    ; IR: %23 = icmp eq ptr %22, null  [null is the literal 0]
  %36 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of reaching the header in the next trip
  call void @cqrt_not_i1(i32 %35)    ; IR: bracket: the loop continues when p->next != NULL
  call void @cqrt_and_i1(i32 %32, i32 %35, i32 %36)    ; IR: br i1 %23 not taken: A' = B & NOT null
  call void @cqrt_not_i1(i32 %35)    ; IR: bracket
  %37 = call i32 @cq_template_select_i32_ll(i32 %31, i32 %26, i32 -1)    ; IR: %25 = phi i32 [ -1, %19 ], [ %16, %14 ]: this trip's exit value, found ? i : -1
  %38 = call i32 @cq_template_select_i32(i32 %29, i32 %37, i32 %28)    ; IR: next exit value = A ? (found ? i : -1) : r
  %39 = call i32 @cq_template_select_i64(i32 %36, i32 %34, i32 %27)    ; IR: next %15 = A' ? %22 : p
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %29)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %34)
  call void @cqrt_push(i32 %35)
  call void @cqrt_push(i32 %37)
  %40 = add nuw nsw i32 %26, 1    ; IR: %20 = add nuw nsw i32 %16, 1  (classical)
  %41 = icmp ult i32 %40, 4    ; IR: K-bounded br i1 %18 / br i1 %23  [K]
  br i1 %41, label %25, label %42

42:
  %43 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %25 = phi i32 [ -1, %19 ], [ %16, %14 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %38, i32 %43)    ; IR: %25
  br label %44

44:
  %45 = phi i32 [ 0, %42 ], [ %63, %62 ]    ; IR: reverse index (trip K-1-k)
  %46 = phi i32 [ %39, %42 ], [ %58, %62 ]    ; IR: p written by this trip
  %47 = phi i32 [ %38, %42 ], [ %57, %62 ]    ; IR: the exit value written by this trip
  %48 = phi i32 [ %36, %42 ], [ %56, %62 ]    ; IR: the next-trip predicate written by this trip
  %49 = call i32 @cqrt_pop()    ; IR: this trip's exit value
  %50 = call i32 @cqrt_pop()    ; IR: the null flag
  %51 = call i32 @cqrt_pop()    ; IR: the load copy of p->next
  %52 = call i32 @cqrt_pop()    ; IR: the address rail p + 8
  %53 = call i32 @cqrt_pop()    ; IR: the body predicate B
  %54 = call i32 @cqrt_pop()    ; IR: the found flag
  %55 = call i32 @cqrt_pop()    ; IR: the load copy of p->v
  %56 = call i32 @cqrt_pop()    ; IR: the trip's predicate A
  %57 = call i32 @cqrt_pop()    ; IR: the exit value before the trip
  %58 = call i32 @cqrt_pop()    ; IR: p of the trip
  %59 = sub nsw i32 3, %45    ; IR: i of that trip (classical)  [K]
  call void @cq_template_select_i64_unc(i32 %46, i32 %48, i32 %51, i32 %58)    ; IR: uncompute next %15
  call void @cqrt_free(i32 %46)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %47, i32 %56, i32 %49, i32 %57)    ; IR: uncompute the next exit value
  call void @cqrt_free(i32 %47)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %49, i32 %54, i32 %59, i32 -1)    ; IR: uncompute the trip's exit value
  call void @cqrt_free(i32 %49)    ; IR: release it (|0>)
  %60 = icmp eq i32 %45, 0    ; IR: reverse index 0 is trip K-1: its A' = A[K] is the output rail (rule 14)
  br i1 %60, label %62, label %61

61:
  call void @cqrt_not_i1(i32 %50)    ; IR: bracket
  call void @cqrt_and_i1(i32 %53, i32 %50, i32 %48)    ; IR: uncompute the next-trip predicate (A[1]..A[K-1])
  call void @cqrt_not_i1(i32 %50)    ; IR: bracket
  call void @cqrt_free(i32 %48)    ; IR: release it (|0>)
  br label %62

62:
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %50, i32 %51, i64 0)    ; IR: uncompute %23
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i64_controlled_unc(i32 %51, i32 %53, i32 %6, i32 %52)    ; IR: un-copy %22 under the control it was loaded with (rule 5: no memory version change since the load)
  call void @cqrt_free(i32 %51)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %52, i32 %58, i64 8)    ; IR: uncompute %21 (the address rail, after its load's _unc)
  call void @cqrt_free(i32 %52)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %54)    ; IR: bracket
  call void @cqrt_and_i1(i32 %56, i32 %54, i32 %53)    ; IR: uncompute the body predicate
  call void @cqrt_not_i1(i32 %54)    ; IR: bracket
  call void @cqrt_free(i32 %53)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %54, i32 %55, i32 %4)    ; IR: uncompute %18
  call void @cqrt_free(i32 %54)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %55, i32 %56, i32 %6, i32 %58)    ; IR: un-copy %17 under the control it was loaded with (rule 5)
  call void @cqrt_free(i32 %55)    ; IR: release it (|0>)
  %63 = add nuw nsw i32 %45, 1
  %64 = icmp ult i32 %63, 4    ; IR: K  [K]
  br i1 %64, label %44, label %65

65:
  call void @cqrt_free(i32 %56)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %57)    ; IR: release the result seed (never written, |0>)
  call void @cqrt_free(i32 %58)    ; IR: release p's seed (never written, the basis state a)
  %66 = call i32 @cqrt_measure_i32(i32 %43)    ; IR: %26 = cq_measure_si32(%25)
  ret i32 %66    ; IR: ret i32 %26
}

define i32 @calloc_aligned(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @__cq_mem()    ; IR: the bus M (called once, at function entry)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %7 = cq_theta_si32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %3)    ; IR: %7 = cq_theta_si32(%2, %3)  [Ry]
  %9 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %8 = calloc(4, 4)  [rule 16: size 4 * 4, zeroed = calloc's zero fill, alignment 16]
  %10 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %9 = aligned_alloc(16, 16)  [rule 16]
  %11 = ptrtoint ptr %9 to i64    ; IR: %8 as its run-time address (classical)
  %12 = ptrtoint ptr %10 to i64    ; IR: %9 as its run-time address (classical)
  %13 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)    ; IR: %10 = and i32 %6, 3
  %14 = call i32 @cq_template_zext_i32_to_i64(i32 %13)    ; IR: %11 = zext nneg i32 %10 to i64
  %15 = call i32 @cq_template_mul_i64_hl(i32 %14, i64 4)    ; IR: %12 = getelementptr inbounds i32, ptr %8, i64 %11  [the index scaled by sizeof(i32)]
  %16 = call i32 @cq_template_add_i64_hl(i32 %15, i64 %11)    ; IR: %12  [address rail = a + 4 * (k & 3)]
  call void @cqrt_qram_store_i32(i32 %6, i32 %16, i32 %8)    ; IR: store i32 %7, ptr %12: a[k & 3] = x  [kept store at an address rail: its slot and its value rail x stay]
  call void @cq_template_add_i64_hl_unc(i32 %16, i32 %15, i64 %11)    ; IR: uncompute %12 (the address rail, after its store)
  call void @cqrt_free(i32 %16)    ; IR: release the %12 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %15, i32 %14, i64 4)    ; IR: uncompute the scaled index of %12
  call void @cqrt_free(i32 %15)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %14, i32 %13)    ; IR: uncompute %11
  call void @cqrt_free(i32 %14)    ; IR: release the %11 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %7, i32 3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %13)    ; IR: release the %10 rail (|0>)
  %17 = add i64 %11, 4    ; IR: %13 = getelementptr inbounds i8, ptr %8, i64 4  (classical)
  %18 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %17)    ; IR: %14 = load i32, ptr %13: a[1]  [load copy; the value rail of the next store, so kept]
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %12, i32 %18)    ; IR: store i32 %14, ptr %9: s[0] = a[1]  [kept store; the load copy is overtaken by it]
  %19 = call i32 @cq_template_add_i32_hl(i32 %8, i32 1)    ; IR: %15 = add nsw i32 %7, 1
  %20 = add i64 %12, 4    ; IR: %16 = getelementptr inbounds i8, ptr %9, i64 4  (classical)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %20, i32 %19)    ; IR: store i32 %15, ptr %16: s[1] = x + 1  [kept store: its slot and its value rail %15 stay]
  %21 = and i32 %4, 1    ; IR: %17 = and i32 %4, 1  (classical)
  %22 = zext nneg i32 %21 to i64    ; IR: %18 = zext nneg i32 %17 to i64
  %23 = getelementptr inbounds i32, ptr %10, i64 %22    ; IR: %19 = getelementptr inbounds i32, ptr %9, i64 %18  [untainted: stays]
  %24 = ptrtoint ptr %23 to i64    ; IR: %19 as its run-time address (classical)
  %25 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %24)    ; IR: %20 = load i32, ptr %19: s[j & 1]  [a bus load at a classical run-time address: a rail]
  %26 = call i32 @cq_template_add_i32_hl(i32 %25, i32 1)    ; IR: %21 = add nsw i32 %20, 1  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %25, i32 %6, i64 %24)    ; IR: un-copy %20 after its last reader %21 (rule 5 sentence 1: no memory version change follows)
  call void @cqrt_free(i32 %25)    ; IR: release the %20 rail (|0>)
  %27 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: free(%8) and free(%9) are nothing (rule 16); %22 = cq_measure_si32(%21)
  ret i32 %27    ; IR: ret i32 %22
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i32_controlled(i32, i32, i32)
declare void @cqrt_qram_load_i32_controlled_unc(i32, i32, i32, i32)
declare i32 @cqrt_qram_load_i64_controlled(i32, i32, i32)
declare void @cqrt_qram_load_i64_controlled_unc(i32, i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i64(i32, i32, i32)
declare void @cq_template_select_i64_unc(i32, i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32_hl(i32, i32)
