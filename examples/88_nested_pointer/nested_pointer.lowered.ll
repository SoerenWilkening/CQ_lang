; HAND-WRITTEN. Rules: 21, 20, 9, 4, 5, 7, 2.
; Checked: a[0] + b[1] + *q after p[(x >> 1) & 1] = v through p = tab[x & 1] and tab[(x >> 2) & 1] = &s.g,
; q = tab[1] (measured).
; Clean: every index rail (x & 1, (x >> 1) & 1, (x >> 2) & 1 and their shifts), p's tag and idx copy-outs, p's cell
; idx, the object guards of the store and of *q, the QRAM load of b, the QROM load of s and their merge select, q's two
; halves, the a[0] and b[1] copy-outs and their sum, every basis-state handle (initializers, v, the fat constant (3, 1);
; rule 7), and the four QRAMs a, b, tab.tag, tab.idx (every store popped, then cqrt_qram_free).
; Kept: the user register x; the result rail (measured).
; Rotations: Ry(th) on x.
; NESTED POINTERS (rule 21): a cell that holds a pointer holds a fat pointer (84), i.e. two values, tag and idx, each
; classical or a handle. Object table: 1 = a (%4), 2 = b (%5), 3 = s (%6, fields f = cell 0 and g = cell 1), 4 = tab
; (%7, two pointer cells). Classification per object (rule 20, over every access): tab is written at the QUANTUM cell
; index k = (x >> 2) & 1, so it is a QRAM; a and b are written through p + j, whose idx (tab's idx half + (x >> 1) & 1)
; is QUANTUM, so both are QRAMs (a quantum-offset store); s is only READ, at q's idx, a handle loaded from tab, i.e. at a
; quantum offset, and only ever holds the classical 5, 6, so it is classical memory read by a QROM
; (cq_template_qrom_load_i32, length 2), never a QRAM. A QRAM's classical initializer is one
; cqrt_qram_store_i32_hl(arr, j, cqrt_alloc_i32(v)) per nonzero cell. tab, whose cells hold TWO values, is modelled as
; TWO i32 QRAMs over the same cell index, one for the tags and one for the idxs (a pointer cell is written and read as
; the pair; a single wider QRAM would pack two logical values into one bit pattern and need shifts on every access). Its
; initializer stores the tags (1, 2); the idx halves are 0, and a |0> cell needs no store. Every idx is a CELL index:
; -O1's zext to i64 and the gep scaling (8 bytes into tab, 4 bytes into a/b) are not emitted, so &s.g is the classical
; fat constant (3, 1) (byte 4 = cell 1 of s). pp = tab + i is the fat pointer (4, i) with a classical tag, so p = *pp is
; an UNGUARDED one-call load of each half: cqrt_qram_load_i32(tab_tag, i), cqrt_qram_load_i32(tab_idx, i) -> the p.tag
; and p.idx rails. The store through p + j reaches p's provenance, every pointer tab held when it was loaded, objects a
; and b: ONE cqrt_qram_store_i32_controlled(g_o, arr_o, idx, v) per object under g_o = tag == o (block predicate:
; none), v a basis-state handle shared by both origins. Storing &s.g at tab + k is one unconditional cqrt_qram_store_i32
; per half (tag 3, idx 1 as handles). q = tab[1] is a fixed-index copy-out of both halves (cqrt_qram_load_i32_hl). *q
; is a deref over cell 1's provenance, the union of what was stored into it, b (the initial constant) and s: one pure,
; unguarded quantum-offset read per object (cqrt_qram_load_i32(b, q.idx) for the QRAM b, the QROM of s), merged by ONE
; select on g_b = q.tag == 2 with the complement s innermost (rule 9; the provenance {b, s} is exhaustive). The address
; decoding is the backend's circuit. Everything is uncomputed in reverse, each array's stores popped LIFO (tab_tag: the
; k store, then the initializer), then cqrt_qram_free releases the arrays.
source_filename = "nested_pointer.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.S = type { i32, i32 }

define i32 @nested_pointer(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_qram_alloc_i32(i32 2)    ; IR: %4 = alloca [2 x i32]  (object 1: a, a 2-cell QRAM: p's provenance)
  %5 = call i32 @cqrt_qram_alloc_i32(i32 2)    ; IR: %5 = alloca [2 x i32]  (object 2: b, a 2-cell QRAM: p's and q's provenance)
  %6 = alloca %struct.S, align 8    ; IR: %6 = alloca %struct.S  (object 3: s, classical memory: holds only classical values, read at a quantum offset: a QROM)
  %7 = call i32 @cqrt_qram_alloc_i32(i32 2)    ; IR: %7 = alloca [2 x ptr]  (object 4: tab, two pointer cells; this QRAM holds the TAG half of each cell)
  %8 = call i32 @cqrt_qram_alloc_i32(i32 2)    ; IR: %7 = alloca [2 x ptr]  (tab: the IDX half of each cell, same cell index)
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %8 = cq_theta_ui32(%0, %1)  [Ry]
  %10 = call i32 @cqrt_alloc_i32(i32 1)    ; IR: store i64 8589934593, ptr %4  (a = {1, 2}: the classical initializer, cell by cell, values as basis-state handles)
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 0, i32 %10)    ; IR: a[0] = 1
  %11 = call i32 @cqrt_alloc_i32(i32 2)    ; IR: a[1] = 2
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 1, i32 %11)    ; IR: a[1] = 2
  %12 = call i32 @cqrt_alloc_i32(i32 3)    ; IR: store i64 17179869187, ptr %5  (b = {3, 4})
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 0, i32 %12)    ; IR: b[0] = 3
  %13 = call i32 @cqrt_alloc_i32(i32 4)    ; IR: b[1] = 4
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 1, i32 %13)    ; IR: b[1] = 4
  store i64 25769803781, ptr %6, align 8    ; IR: store i64 25769803781, ptr %6  (s = {5, 6}, classical)
  %14 = call i32 @cqrt_alloc_i32(i32 1)    ; IR: store ptr %4, ptr %7  (tab[0] = the fat constant (1, 0): the tag 1 as a handle; the idx half 0 is the |0> cell, no store)
  call void @cqrt_qram_store_i32_hl(i32 %7, i32 0, i32 %14)    ; IR: tab[0].tag = 1
  %15 = call i32 @cqrt_alloc_i32(i32 2)    ; IR: store ptr %5, ptr %9  (tab[1] = the fat constant (2, 0); %9 = &tab[1] is cell 1)
  call void @cqrt_qram_store_i32_hl(i32 %7, i32 1, i32 %15)    ; IR: tab[1].tag = 2
  %16 = call i32 @cq_template_and_i32_hl(i32 %9, i32 1)    ; IR: %10 = and i32 %8, 1  [pp.idx, the cell index into tab; %11 zext and the gep %12's 8-byte scaling are not emitted; pp.tag is the classical 4]
  %17 = call i32 @cqrt_qram_load_i32(i32 %7, i32 %16)    ; IR: %13 = load ptr, ptr %12: p.tag = tab[pp.idx].tag  (provenance {tab}, tag classical: one unguarded copy-out)
  %18 = call i32 @cqrt_qram_load_i32(i32 %8, i32 %16)    ; IR: %13: p.idx = tab[pp.idx].idx
  %19 = call i32 @cq_template_lshr_i32_hl(i32 %9, i32 1)    ; IR: %14 = lshr i32 %8, 1
  %20 = call i32 @cq_template_and_i32_hl(i32 %19, i32 1)    ; IR: %15 = and i32 %14, 1  [the element index; %16 zext and the gep %17's 4-byte scaling are not emitted]
  %21 = call i32 @cq_template_add_i32(i32 %18, i32 %20)    ; IR: %17 = getelementptr i32, ptr %13, i64 %16: idx = p.idx + index, a CELL index (a and b are i32 arrays; tag stays p.tag)
  %22 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %17: the classical value v as a basis-state handle, shared by both origins
  %23 = call i32 @cq_template_icmp_eq_i32_hl(i32 %17, i32 1)    ; IR: store i32 %2, ptr %17: guard g_a = tag == 1 (object a; block predicate: none)
  call void @cqrt_qram_store_i32_controlled(i32 %23, i32 %4, i32 %21, i32 %22)    ; IR: store into a: a[idx] = v under g_a (one access; the backend fans out over the cells)
  %24 = call i32 @cq_template_icmp_eq_i32_hl(i32 %17, i32 2)    ; IR: guard g_b = tag == 2 (object b)
  call void @cqrt_qram_store_i32_controlled(i32 %24, i32 %5, i32 %21, i32 %22)    ; IR: store into b: b[idx] = v under g_b
  %25 = call i32 @cq_template_lshr_i32_hl(i32 %9, i32 2)    ; IR: %19 = lshr i32 %8, 2  (%18 = &s.g is the classical fat constant (3, 1): object 3, cell 1)
  %26 = call i32 @cq_template_and_i32_hl(i32 %25, i32 1)    ; IR: %20 = and i32 %19, 1  [k, the cell index into tab; %21 zext and the gep %22's 8-byte scaling are not emitted]
  %27 = call i32 @cqrt_alloc_i32(i32 3)    ; IR: store ptr %18, ptr %22: the tag 3 (s) as a basis-state handle
  call void @cqrt_qram_store_i32(i32 %7, i32 %26, i32 %27)    ; IR: store ptr %18, ptr %22: tab[k].tag = 3 (one access; the displaced cell goes on the backend's tape)
  %28 = call i32 @cqrt_alloc_i32(i32 1)    ; IR: store ptr %18, ptr %22: the idx 1 (cell of s.g; was byte 4) as a basis-state handle
  call void @cqrt_qram_store_i32(i32 %8, i32 %26, i32 %28)    ; IR: store ptr %18, ptr %22: tab[k].idx = 1
  %29 = call i32 @cqrt_qram_load_i32_hl(i32 %7, i32 1)    ; IR: %23 = load ptr, ptr %9: q.tag = tab[1].tag  (fixed index: copy-out)
  %30 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i32 1)    ; IR: %23: q.idx = tab[1].idx
  %31 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i32 0)    ; IR: %24 = load i32, ptr %4: a[0]  (fixed index into the quantum array: copy-out)
  %32 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i32 1)    ; IR: %26 = load i32, ptr %25: b[1]  (%25 = &b[1] is cell 1)
  %33 = call i32 @cq_template_add_i32(i32 %32, i32 %31)    ; IR: %27 = add nsw i32 %26, %24
  %34 = call i32 @cq_template_icmp_eq_i32_hl(i32 %29, i32 2)    ; IR: %28 = load i32, ptr %23: guard g_b = q.tag == 2 (cell 1's provenance: b, the initial constant, and s)
  %35 = call i32 @cqrt_qram_load_i32(i32 %5, i32 %30)    ; IR: %28 in b: b[q.idx], one QRAM access at the quantum index (pure: unguarded)
  %36 = call i32 @cq_template_qrom_load_i32(ptr %6, i64 2, i32 %30)    ; IR: %28 in s: s[q.idx], a QROM over the classical struct
  %37 = call i32 @cq_template_select_i32(i32 %34, i32 %35, i32 %36)    ; IR: %28 = load i32, ptr %23: g_b ? b[q.idx] : s[q.idx]  [the load *q: the per-object merge]
  %38 = call i32 @cq_template_add_i32(i32 %33, i32 %37)    ; IR: %29 = add nsw i32 %27, %28  [result rail]
  call void @cq_template_select_i32_unc(i32 %37, i32 %34, i32 %35, i32 %36)    ; IR: uncompute the merged load %28
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %36, ptr %6, i64 2, i32 %30)    ; IR: uncompute s's read
  call void @cqrt_free(i32 %36)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %35, i32 %5, i32 %30)    ; IR: uncompute b's read (un-copy)
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %34, i32 %29, i32 2)    ; IR: uncompute g_b of *q
  call void @cqrt_free(i32 %34)    ; IR: release it (|0>)
  call void @cq_template_add_i32_unc(i32 %33, i32 %32, i32 %31)    ; IR: uncompute %27
  call void @cqrt_free(i32 %33)    ; IR: release the %27 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %32, i32 %5, i32 1)    ; IR: uncompute %26 (b[1])
  call void @cqrt_free(i32 %32)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %31, i32 %4, i32 0)    ; IR: uncompute %24 (a[0])
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %30, i32 %8, i32 1)    ; IR: uncompute q.idx
  call void @cqrt_free(i32 %30)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %29, i32 %7, i32 1)    ; IR: uncompute q.tag
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_unc(i32 %8, i32 %26, i32 %28)    ; IR: pop tab[k].idx = 1 (LIFO on tab's idx half: its only store)
  call void @cqrt_free(i32 %28)    ; IR: release the basis-state handle 1
  call void @cqrt_qram_store_i32_unc(i32 %7, i32 %26, i32 %27)    ; IR: pop tab[k].tag = 3 (LIFO on tab's tag half: the last store)
  call void @cqrt_free(i32 %27)    ; IR: release the basis-state handle 3
  call void @cq_template_and_i32_hl_unc(i32 %26, i32 %25, i32 1)    ; IR: uncompute %20
  call void @cqrt_free(i32 %26)    ; IR: release the %20 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %25, i32 %9, i32 2)    ; IR: uncompute %19
  call void @cqrt_free(i32 %25)    ; IR: release the %19 rail (|0>)
  call void @cqrt_qram_store_i32_controlled_unc(i32 %24, i32 %5, i32 %21, i32 %22)    ; IR: pop the store into b
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %24, i32 %17, i32 2)    ; IR: uncompute g_b
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_controlled_unc(i32 %23, i32 %4, i32 %21, i32 %22)    ; IR: pop the store into a
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %23, i32 %17, i32 1)    ; IR: uncompute g_a
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  call void @cqrt_free(i32 %22)    ; IR: release the value handle (basis state v)
  call void @cq_template_add_i32_unc(i32 %21, i32 %18, i32 %20)    ; IR: uncompute %17's idx
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %20, i32 %19, i32 1)    ; IR: uncompute %15
  call void @cqrt_free(i32 %20)    ; IR: release the %15 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %19, i32 %9, i32 1)    ; IR: uncompute %14
  call void @cqrt_free(i32 %19)    ; IR: release the %14 rail (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %18, i32 %8, i32 %16)    ; IR: uncompute p.idx (un-copy)
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %17, i32 %7, i32 %16)    ; IR: uncompute p.tag (un-copy)
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %9, i32 1)    ; IR: uncompute %10
  call void @cqrt_free(i32 %16)    ; IR: release the %10 rail (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %7, i32 1, i32 %15)    ; IR: pop the initializer of tab's tag half (LIFO): tab[1].tag
  call void @cqrt_free(i32 %15)    ; IR: release the basis-state handle 2
  call void @cqrt_qram_store_i32_hl_unc(i32 %7, i32 0, i32 %14)    ; IR: tab[0].tag
  call void @cqrt_free(i32 %14)    ; IR: release the basis-state handle 1
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 1, i32 %13)    ; IR: pop the initializer of b: b[1]
  call void @cqrt_free(i32 %13)    ; IR: release the basis-state handle 4
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 0, i32 %12)    ; IR: b[0]
  call void @cqrt_free(i32 %12)    ; IR: release the basis-state handle 3
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 1, i32 %11)    ; IR: pop the initializer of a: a[1]
  call void @cqrt_free(i32 %11)    ; IR: release the basis-state handle 2
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 0, i32 %10)    ; IR: a[0]
  call void @cqrt_free(i32 %10)    ; IR: release the basis-state handle 1
  call void @cqrt_qram_free(i32 %8)    ; IR: llvm.lifetime.end %7: release tab's idx half (all cells |0>)
  call void @cqrt_qram_free(i32 %7)    ; IR: llvm.lifetime.end %7: release tab's tag half
  call void @cqrt_qram_free(i32 %5)    ; IR: llvm.lifetime.end %5: release object b
  call void @cqrt_qram_free(i32 %4)    ; IR: llvm.lifetime.end %4: release object a
  %39 = call i32 @cqrt_measure_i32(i32 %38)    ; IR: %30 = cq_measure_si32(%29)
  ret i32 %39    ; IR: ret i32 %30
}

declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare void @cq_template_qrom_load_i32_unc(i32, ptr, i64, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_free(i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32_controlled(i32, i32, i32, i32)
declare void @cqrt_qram_store_i32_controlled_unc(i32, i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
