; HAND-WRITTEN. Rules: 2, 4, 5, 7, 8, 9, 14, 16, 20, 21.
; Checked: list_search: p ? i : -1, the index of the first node whose v equals key, else -1 (the copied-out result,
; measured). calloc_aligned: r = s[j & 1] + 1 (measured).
; Clean: list_search: every trip rail (the object flags tag == 1, tag == 2, the merged v and its inner select, the found
; flag, the body predicate, the merged next tag and its inner select, the null flag, the trip's exit value, the next
; tag and result selects, the predicates A[1]..A[K-1]) popped and uncomputed by the reverse loop, plus the three seeds
; (p = tag 1, the result 0, the |1> predicate) freed directly. calloc_aligned: the index rail k & 3, the copy-out a[1],
; the rail x + 1; the store a[k & 3] = x is popped and the QRAM released at free(a).
; Kept: list_search: x and y (rotated), the result (measured) and the output predicate A[K] (rule 14: LLVM knows no
; bound of the trip count, the loop ends on a NULL read from memory; A[K] is 0 on every branch here, since the list has
; three nodes, but the compiler cannot prove it). calloc_aligned: k and x (rotated) and r (measured).
; Rotations: list_search: (Ry, x, tx, 1); (Ry, y, ty, 1). calloc_aligned: (Ry, k, tk, 1); (Ry, x, tx, 1).
; list_search. HEAP RECORDS: the three malloc'd nodes are objects 1 = a (%8), 2 = b (%7), 3 = c (%6); no access to them
; has a quantum offset (p->v is cell 0, p->next the field at byte 8, both CLASSICAL offsets), so none is a QRAM. Each
; is a host record block of the same 16-byte layout {i32 v, ptr next}: the v field of a and b holds a HANDLE (a slot
; cell: the handle replaces the int, both 4 bytes), the v field of c only ever holds the classical 7 and stays a
; classical cell (rule 20, homogeneous per cell), and every next field holds a CLASSICAL host pointer, stored as written.
; LOOP: the exit p->v != key reads quantum data, so the loop is a K-loop (rule 14, cutoff K = 4: no range bound B
; exists). A trip is one execution of the header %14; trip j runs under A[j] (A[0] = |1> seed), the body %19 under
; B[j] = A[j] & NOT found[j], and the next header under A[j+1] = B[j] & NOT null[j]. The carried pointer p is a FAT
; POINTER (rule 21): its tag rail, idx always 0 (the record start); trip 0's p = a is the seed tag 1. A deref is one
; classical-offset access per object of the provenance {a, b, c} merged by select on the guards tag == 1, tag == 2,
; with c the complement innermost (rule 9); the NULL tag 0 also falls to c, which is never observable: a NULL p never
; runs a trip. The loads stay where -O1 has them, in every trip (%17 in the header, %22 in the body); the reverse loop
; reloads the v cells its uncomputes read (nothing in the function writes them after the loop starts).
; p->next is a POINTER LOADED THROUGH A FAT POINTER (rule 21): one unguarded host load of each object's next field, kept
; where -O1 has it (block %19, every trip). The loaded values are host pointers whose origin the compiler does not
; resolve from the stores: each is decoded AT RUN TIME to a tag by range tests over the function's object table
; (base[o] = the malloc'd host address, cell count 1 = one 16-byte record; base[o] <= addr <= base[o] + 16, one-past
; included; an address in no object, NULL among them, is tag 0), a classical select chain. The three decoded tags are
; merged by select on the same guards (run-time classical operands of select_ll/select_lh); they are pushed per trip
; and popped for the merges' _unc. idx is not carried: a pointer this loop dereferences has idx 0 in every defined
; execution (C never dereferences a one-past or misaligned node pointer), and the only other use, the NULL test, is
; tag == 0 (rule 21: distinct allocations of this function and NULL compare by tags; a one-past address is non-NULL
; and decodes to a nonzero tag). Here a->next decodes to 2, b->next to 3, c->next to 0. i is the
; induction variable %16 = j (SCEV), a classical trip index. The exit phi %25 is carried as the result rail r: trip j
; sets r = found[j] ? j : -1 under A[j] (an exit at %14 yields j, a continue sets the provisional -1 that the NULL exit
; at %19 keeps). After K trips r is copied out, and the reverse loop pops each trip; on reverse index 0 (trip K-1) it
; keeps A[K] (rule 14: the test that would admit a (K+1)-th trip). The blocks are never freed by the program (host
; memory, no rail).
; calloc_aligned. a: a[k & 3] = x is a QUANTUM-OFFSET store, so the calloc block is a QRAM (rule 20, rule 16): calloc(4,
; 4) is cqrt_qram_alloc_i32(4) and nothing else, because a fresh QRAM cell is |0>, exactly calloc's zero fill (no host
; block, no gate); calloc(n, size) maps to n cells of the accessed element type (here size = sizeof(int), one i32 cell
; per element; a quantum n allocates at its upper bound). s: aligned_alloc(16, 16) is accessed only at classical offsets
; (0, 1 and the runtime j & 1), so it is a SLOT ARRAY and stays a host call: 4 int cells = 4 handle slots of 4 bytes =
; the same 16 bytes at the same alignment. s[0] = a[1] stores the fixed-index copy-out of the QRAM cell 1 into slot 0;
; s[1] = x + 1 stores the fresh rail; s[j & 1] is a slot load (the handle, no gate). free(a) under no predicate is a
; lifetime end (rule 16): the copy-out a[1] is un-copied (cell 1 unchanged since the load), the store is popped (x and
; the index rail hold their forward values) and the QRAM is released. free(s) is the ordinary host call.
source_filename = "heap_linked_list.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @list_search(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call ptr @malloc(i64 16)    ; IR: %6 = malloc(16): c, object 3, a host record block {i32 v, ptr next}
  %7 = call ptr @malloc(i64 16)    ; IR: %7 = malloc(16): b, object 2
  %8 = call ptr @malloc(i64 16)    ; IR: %8 = malloc(16): a, object 1
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %9 = cq_theta_si32(%0, %1)  [Ry]
  %10 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %10 = cq_theta_si32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %10, double %3)    ; IR: %10 = cq_theta_si32(%2, %3)  [Ry]
  store i32 %9, ptr %8, align 8    ; IR: store i32 %9, ptr %8: a->v = x  (slot store: the cell takes the handle, no gate)
  %11 = getelementptr inbounds i8, ptr %8, i64 8    ; IR: %11 = gep %8, 8
  store ptr %7, ptr %11, align 8    ; IR: store ptr %7, ptr %11: a->next = b  (classical host pointer)
  store i32 %10, ptr %7, align 8    ; IR: store i32 %10, ptr %7: b->v = y  (slot store)
  %12 = getelementptr inbounds i8, ptr %7, i64 8    ; IR: %12 = gep %7, 8
  store ptr %6, ptr %12, align 8    ; IR: store ptr %6, ptr %12: b->next = c  (classical)
  store i32 7, ptr %6, align 8    ; IR: store i32 7, ptr %6: c->v = 7  (a classical cell)
  %13 = getelementptr inbounds i8, ptr %6, i64 8    ; IR: %13 = gep %6, 8
  store ptr null, ptr %13, align 8    ; IR: store ptr null, ptr %13: c->next = NULL  (classical)
  %14 = ptrtoint ptr %8 to i64    ; IR: object table: base[1] = a's host address (cell count 1: one 16-byte record)
  %15 = ptrtoint ptr %7 to i64    ; IR: object table: base[2] = b
  %16 = ptrtoint ptr %6 to i64    ; IR: object table: base[3] = c
  %17 = call i32 @cqrt_alloc_i32(i32 1)    ; IR: %15 = phi ptr [ %8, %5 ]: p's tag before trip 0 (object 1 = a)  [seed]
  %18 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: the result before trip 0 (never read: A[0] = 1)  [seed]
  %19 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the header in trip 0 (always 1)
  br label %20
20:
  %21 = phi i32 [ 0, %5 ], [ %74, %20 ]    ; IR: %16 = phi i32 [ 0, %5 ], [ %20, %19 ]: i = the trip index (SCEV), bounded by K  [K]
  %22 = phi i32 [ %17, %5 ], [ %73, %20 ]    ; IR: %15 = phi ptr [ %8, %5 ], [ %22, %19 ]: p's tag
  %23 = phi i32 [ %18, %5 ], [ %72, %20 ]    ; IR: the exit value %25 so far
  %24 = phi i32 [ %19, %5 ], [ %70, %20 ]    ; IR: predicate of reaching the header %14 in this trip
  %25 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 1)    ; IR: %17 = load i32, ptr %15: object 1 addressed iff tag == 1
  %26 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 2)    ; IR: %17: object 2 addressed iff tag == 2 (object 3 is the complement)
  %27 = load i32, ptr %8, align 8    ; IR: %17: object 1's v cell (the handle of x, no gate)
  %28 = load i32, ptr %7, align 8    ; IR: %17: object 2's v cell (the handle of y)
  %29 = load i32, ptr %6, align 8    ; IR: %17: object 3's v cell (classical host load: 7)
  %30 = call i32 @cq_template_select_i32_hl(i32 %26, i32 %28, i32 %29)    ; IR: %17: tag == 2 ? b->v : c->v  (innermost: the complement)
  %31 = call i32 @cq_template_select_i32(i32 %25, i32 %27, i32 %30)    ; IR: %17 = load i32, ptr %15: tag == 1 ? a->v : ...
  %32 = call i32 @cq_template_icmp_eq_i32_hl(i32 %31, i32 %4)    ; IR: %18 = icmp eq i32 %17, %4  [found]
  %33 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %19 in this trip
  call void @cqrt_not_i1(i32 %32)    ; IR: bracket: the body runs when p->v != key
  call void @cqrt_and_i1(i32 %24, i32 %32, i32 %33)    ; IR: br i1 %18 not taken: B = A & NOT found
  call void @cqrt_not_i1(i32 %32)    ; IR: bracket
  %34 = load ptr, ptr %11, align 8    ; IR: %22 = load ptr, ptr %21: object 1's next field (host load, unguarded)
  %35 = load ptr, ptr %12, align 8    ; IR: %22: object 2's next field (host load)
  %36 = load ptr, ptr %13, align 8    ; IR: %22: object 3's next field (host load)
  %37 = ptrtoint ptr %34 to i64    ; IR: decode a->next at run time (rule 21, unknown origin): range tests over the object table
  %38 = sub i64 %37, %14
  %39 = icmp ule i64 %38, 16    ; IR: base[1] <= addr <= base[1] + 16 (one-past included)
  %40 = sub i64 %37, %15
  %41 = icmp ule i64 %40, 16    ; IR: in object 2
  %42 = sub i64 %37, %16
  %43 = icmp ule i64 %42, 16    ; IR: in object 3
  %44 = select i1 %43, i32 3, i32 0    ; IR: no object: tag 0 (null lies in no object)
  %45 = select i1 %41, i32 2, i32 %44
  %46 = select i1 %39, i32 1, i32 %45    ; IR: the decoded tag of a->next (classical)
  %47 = ptrtoint ptr %35 to i64    ; IR: decode b->next at run time (rule 21, unknown origin): range tests over the object table
  %48 = sub i64 %47, %14
  %49 = icmp ule i64 %48, 16    ; IR: base[1] <= addr <= base[1] + 16 (one-past included)
  %50 = sub i64 %47, %15
  %51 = icmp ule i64 %50, 16    ; IR: in object 2
  %52 = sub i64 %47, %16
  %53 = icmp ule i64 %52, 16    ; IR: in object 3
  %54 = select i1 %53, i32 3, i32 0    ; IR: no object: tag 0 (null lies in no object)
  %55 = select i1 %51, i32 2, i32 %54
  %56 = select i1 %49, i32 1, i32 %55    ; IR: the decoded tag of b->next (classical)
  %57 = ptrtoint ptr %36 to i64    ; IR: decode c->next at run time (rule 21, unknown origin): range tests over the object table
  %58 = sub i64 %57, %14
  %59 = icmp ule i64 %58, 16    ; IR: base[1] <= addr <= base[1] + 16 (one-past included)
  %60 = sub i64 %57, %15
  %61 = icmp ule i64 %60, 16    ; IR: in object 2
  %62 = sub i64 %57, %16
  %63 = icmp ule i64 %62, 16    ; IR: in object 3
  %64 = select i1 %63, i32 3, i32 0    ; IR: no object: tag 0 (null lies in no object)
  %65 = select i1 %61, i32 2, i32 %64
  %66 = select i1 %59, i32 1, i32 %65    ; IR: the decoded tag of c->next (classical)
  %67 = call i32 @cq_template_select_i32_ll(i32 %26, i32 %56, i32 %66)    ; IR: %22: tag == 2 ? tag(b->next) : tag(c->next)  (run-time classical operands)
  %68 = call i32 @cq_template_select_i32_lh(i32 %25, i32 %46, i32 %67)    ; IR: %22 = load ptr, ptr %21: tag == 1 ? tag(a->next) : ...
  %69 = call i32 @cq_template_icmp_eq_i32_hl(i32 %68, i32 0)    ; IR: %23 = icmp eq ptr %22, null: tag == 0
  %70 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of reaching the header in the next trip
  call void @cqrt_not_i1(i32 %69)    ; IR: bracket: the loop continues when p->next != NULL
  call void @cqrt_and_i1(i32 %33, i32 %69, i32 %70)    ; IR: br i1 %23 not taken: A' = B & NOT null
  call void @cqrt_not_i1(i32 %69)    ; IR: bracket
  %71 = call i32 @cq_template_select_i32_ll(i32 %32, i32 %21, i32 -1)    ; IR: %25 = phi i32 [ -1, %19 ], [ %16, %14 ]: this trip's exit value, found ? i : -1
  %72 = call i32 @cq_template_select_i32(i32 %24, i32 %71, i32 %23)    ; IR: next exit value = A ? (found ? i : -1) : r
  %73 = call i32 @cq_template_select_i32(i32 %70, i32 %68, i32 %22)    ; IR: next %15 = A' ? %22 : p
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %25)
  call void @cqrt_push(i32 %26)
  call void @cqrt_push(i32 %30)
  call void @cqrt_push(i32 %31)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %67)
  call void @cqrt_push(i32 %68)
  call void @cqrt_push(i32 %69)
  call void @cqrt_push(i32 %71)
  call void @cqrt_push(i32 %46)    ; IR: the decoded tags are classical per-trip values the _unc needs (rule 14)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %66)
  %74 = add nuw nsw i32 %21, 1    ; IR: %20 = add nuw nsw i32 %16, 1  (classical)
  %75 = icmp ult i32 %74, 4    ; IR: K-bounded br i1 %18 / br i1 %23  [K]
  br i1 %75, label %20, label %76
76:
  %77 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %25 = phi i32 [ -1, %19 ], [ %16, %14 ]  [copied-out result]
  call void @cqrt_copy_i32(i32 %72, i32 %77)    ; IR: %25
  br label %78
78:
  %79 = phi i32 [ 0, %76 ], [ %106, %102 ]    ; IR: reverse index (trip K-1-k)
  %80 = phi i32 [ %73, %76 ], [ %98, %102 ]    ; IR: p's tag written by this trip
  %81 = phi i32 [ %72, %76 ], [ %97, %102 ]    ; IR: the exit value written by this trip
  %82 = phi i32 [ %70, %76 ], [ %96, %102 ]    ; IR: the next-trip predicate written by this trip
  %83 = call i32 @cqrt_pop()    ; IR: tag(c->next) of this trip
  %84 = call i32 @cqrt_pop()    ; IR: tag(b->next)
  %85 = call i32 @cqrt_pop()    ; IR: tag(a->next)
  %86 = call i32 @cqrt_pop()
  %87 = call i32 @cqrt_pop()
  %88 = call i32 @cqrt_pop()
  %89 = call i32 @cqrt_pop()
  %90 = call i32 @cqrt_pop()
  %91 = call i32 @cqrt_pop()
  %92 = call i32 @cqrt_pop()
  %93 = call i32 @cqrt_pop()
  %94 = call i32 @cqrt_pop()
  %95 = call i32 @cqrt_pop()
  %96 = call i32 @cqrt_pop()
  %97 = call i32 @cqrt_pop()
  %98 = call i32 @cqrt_pop()
  %99 = sub nsw i32 3, %79    ; IR: i of that trip (classical)  [K]
  call void @cq_template_select_i32_unc(i32 %80, i32 %82, i32 %88, i32 %98)    ; IR: uncompute next %15
  call void @cqrt_free(i32 %80)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %81, i32 %96, i32 %86, i32 %97)    ; IR: uncompute the next exit value
  call void @cqrt_free(i32 %81)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %86, i32 %91, i32 %99, i32 -1)    ; IR: uncompute the trip's exit value
  call void @cqrt_free(i32 %86)    ; IR: release it (|0>)
  %100 = icmp eq i32 %79, 0    ; IR: reverse index 0 is trip K-1: its A' = A[K] is the output rail (rule 14)
  br i1 %100, label %102, label %101
101:
  call void @cqrt_not_i1(i32 %87)    ; IR: bracket
  call void @cqrt_and_i1(i32 %90, i32 %87, i32 %82)    ; IR: uncompute the next-trip predicate (A[1]..A[K-1])
  call void @cqrt_not_i1(i32 %87)    ; IR: bracket
  call void @cqrt_free(i32 %82)    ; IR: release it (|0>)
  br label %102
102:
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %87, i32 %88, i32 0)    ; IR: uncompute %23
  call void @cqrt_free(i32 %87)    ; IR: release it (|0>)
  call void @cq_template_select_i32_lh_unc(i32 %88, i32 %95, i32 %85, i32 %89)    ; IR: uncompute %22
  call void @cqrt_free(i32 %88)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %89, i32 %94, i32 %84, i32 %83)    ; IR: uncompute the inner select of %22
  call void @cqrt_free(i32 %89)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %91)    ; IR: bracket
  call void @cqrt_and_i1(i32 %96, i32 %91, i32 %90)    ; IR: uncompute the body predicate
  call void @cqrt_not_i1(i32 %91)    ; IR: bracket
  call void @cqrt_free(i32 %90)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %91, i32 %92, i32 %4)    ; IR: uncompute %18
  call void @cqrt_free(i32 %91)    ; IR: release it (|0>)
  %103 = load i32, ptr %8, align 8    ; IR: %17 of that trip: object 1's v cell again (unchanged)
  %104 = load i32, ptr %7, align 8    ; IR: object 2's v cell again
  %105 = load i32, ptr %6, align 8    ; IR: object 3's v cell again (classical 7)
  call void @cq_template_select_i32_unc(i32 %92, i32 %95, i32 %103, i32 %93)    ; IR: uncompute %17
  call void @cqrt_free(i32 %92)    ; IR: release it (|0>)
  call void @cq_template_select_i32_hl_unc(i32 %93, i32 %94, i32 %104, i32 %105)    ; IR: uncompute the inner select of %17
  call void @cqrt_free(i32 %93)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %94, i32 %98, i32 2)    ; IR: uncompute the object-2 flag
  call void @cqrt_free(i32 %94)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %95, i32 %98, i32 1)    ; IR: uncompute the object-1 flag
  call void @cqrt_free(i32 %95)    ; IR: release it (|0>)
  %106 = add nuw nsw i32 %79, 1
  %107 = icmp ult i32 %106, 4    ; IR: K  [K]
  br i1 %107, label %78, label %108
108:
  call void @cqrt_free(i32 %96)    ; IR: release the |1> seed directly (rule 7: known basis state)
  call void @cqrt_free(i32 %97)    ; IR: release the result seed (never written, |0>)
  call void @cqrt_free(i32 %98)    ; IR: release p's seed tag (never written, basis state 1)
  %109 = call i32 @cqrt_measure_i32(i32 %77)    ; IR: %26 = cq_measure_si32(%25)
  ret i32 %109    ; IR: ret i32 %26
}

define i32 @calloc_aligned(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %7 = cq_theta_si32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %7 = cq_theta_si32(%2, %3)  [Ry]
  %8 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %8 = calloc(4, 4): object 1, a QRAM of 4 int cells, all |0> = calloc's zero fill (no host block, no gate)
  %9 = call ptr @aligned_alloc(i64 16, i64 16)    ; IR: %9 = aligned_alloc(16, 16): a slot array of 4 handle cells (host call)
  %10 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %10 = and i32 %6, 3  [the index rail; %11 zext and %12 gep are not emitted]
  call void @cqrt_qram_store_i32(i32 %8, i32 %10, i32 %7)    ; IR: store i32 %7, ptr %12: a[k & 3] = x  (the register's handle is the value)
  %11 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i32 1)    ; IR: %13 = gep %8, 4; %14 = load i32, ptr %13: a[1]  (fixed-index copy-out)
  store i32 %11, ptr %9, align 16    ; IR: store i32 %14, ptr %9: s[0] = a[1]  (slot store, no gate)
  %12 = call i32 @cq_template_add_i32_hl(i32 %7, i32 1)    ; IR: %15 = add nsw i32 %7, 1
  %13 = getelementptr inbounds i8, ptr %9, i64 4    ; IR: %16 = gep %9, 4
  store i32 %12, ptr %13, align 4    ; IR: store i32 %15, ptr %16: s[1] = x + 1  (slot store)
  %14 = and i32 %4, 1    ; IR: %17 = and i32 %4, 1  (classical)
  %15 = zext nneg i32 %14 to i64    ; IR: %18 = zext nneg i32 %17 to i64
  %16 = getelementptr inbounds i32, ptr %9, i64 %15    ; IR: %19 = gep i32, %9, %18
  %17 = load i32, ptr %16, align 4    ; IR: %20 = load i32, ptr %19: s[j & 1]  (slot load at a classical offset: the handle, no gate)
  %18 = call i32 @cq_template_add_i32_hl(i32 %17, i32 1)    ; IR: %21 = add nsw i32 %20, 1  [result rail]
  call void @cq_template_add_i32_hl_unc(i32 %12, i32 %7, i32 1)    ; IR: uncompute %15 (its last reader was %21)
  call void @cqrt_free(i32 %12)    ; IR: release the %15 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %11, i32 %8, i32 1)    ; IR: free(%8): un-copy %14 (cell 1 unchanged since the load)
  call void @cqrt_free(i32 %11)    ; IR: release the %14 rail (|0>)
  call void @cqrt_qram_store_i32_unc(i32 %8, i32 %10, i32 %7)    ; IR: free(%8): pop the store a[k & 3] = x (every cell |0> again)
  call void @cqrt_qram_free(i32 %8)    ; IR: free(%8): release object 1's QRAM
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %6, i32 3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @free(ptr %9)    ; IR: free(%9): a slot block is host memory, an ordinary call
  %19 = call i32 @cqrt_measure_i32(i32 %18)    ; IR: %22 = cq_measure_si32(%21)
  ret i32 %19    ; IR: ret i32 %22
}

declare ptr @malloc(i64)
declare ptr @aligned_alloc(i64, i64)
declare void @free(ptr)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_free(i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_hl(i32, i32, i32)
declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
