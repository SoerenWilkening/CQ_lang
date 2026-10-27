; HAND-WRITTEN. Rules: 2, 4, 5, 7, 8, 9, 14, 20.
; Checked: quantum_strlen's n (the copied-out result %56 -> %57, measured); quantum_strcmp's `i < cap ? a[i] - b[i] : 0`
; (the copied-out result %86 -> %87, measured).
; Clean: every trip rail (the trip predicates, exit flags, per-trip selects, strcmp's difference and its sexts), popped
; and uncomputed by the reverse loop; the |1> seed and the chain's |0> seed rail (%11; %20), freed directly; the |0>
; cell rails replaced by the 'a' seeds, freed directly.
; Kept: the cells s[i] (strlen) and a[i], b[i] (strcmp), user registers (the 'a' seeds %19; %31, %30 rotated in place),
; and the measured result rail. No predicate is kept: the bound cap is classical, so every trip and exit predicate,
; the last trip's a_last included, is a function of the inputs and is uncomputed by the mirror (rule 14, classical
; bound with a quantum exit).
; Rotations: (Ry, s[i], th[i], 1) per trip i of the fill loop; (Ry, a[i], ta[i], 1), (Ry, b[i], tb[i], 1) per trip i.
; A STRING SEARCH OVER QUANTUM CHARS: -O1 turns `while (n < cap && s[n] != 0) n++` into a classical counted loop over
; cap (the buffer bound) with a quantum EARLY EXIT, and computes n from the classical induction variable in the exit
; block (%28 = trunc %20) merged by the exit phi %30 [0 (cap <= 0), %28 (NUL at trip i), %1 (no NUL)]. So n is never a
; loop-carried quantum value: which EXIT is taken is quantum. The loop stays a classical loop of cap trips (26's shape)
; under the trip predicate a_i = a_(i-1) & NOT z_i (seed |1>), and each exit gets its own predicate: e_i = a_(i-1) & z_i
; for the NUL exit at trip i, a_last for the fall-through exit. These predicates are MUTUALLY EXCLUSIVE and exactly one is
; 1. The exit phi is merged per rule 9: one cq_template_select_i32 per incoming, chained with the complement arm innermost
; into fresh rails: r_i = select(e_i, i, r_(i-1)) in trip i (the literal incoming %28 is the trip index: _lh), seeded by
; a |0> rail (the incoming 0 of the cap <= 0 edge; a seed, rule 7), and after the loop r = select(a_last, cap, r_last),
; the result. Each trip pushes its predicates and r_(i-1); a reverse loop pops them, uncomputes r_i by its select's _unc,
; then the predicates (the result does not depend on them staying alive).
; quantum_strcmp has two quantum exits from one trip into the same exit block %37 (NUL in a, or a[i] != b[i]): the exit
; flag of the trip is x_i = e1_i | e2_i (or_i1 into a fresh flag, rule 8; e1, e2 exclusive), the block's value
; d = a[i] - b[i] (classical trip index i, quantum chars) is computed unconditionally (pure), merged by
; r_i = select(x_i, d, r_(i-1)); d and its two sexts stay alive (pushed with the trip) and the reverse trip uncomputes
; r_i, x_i, d and the sexts in exact LIFO order (rule 5);
; the fall-through exit and the cap <= 0 edge contribute 0, the value of the |0> seed, so no select is spent on them. The
; last trip's r is copied out (alloc + copy, rule 14) and the reverse loop uncomputes every trip's r.
; Cells: `char s[4]` is an array of classical SLOTS (58), one i8 rail per cell, |0> from the punned zero store; the
; classical store 'a' into a cell replaces the cell's handle by a fresh basis-state seed cqrt_alloc_i8(97) (rule 4: no
; in-place write on a rail; the |0> rail it replaces was never written and is freed directly, rule 7), then cq_theta
; rotates the seed in place. The cells are user registers and stay allocated.
source_filename = "quantum_strlen.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @quantum_strlen(ptr nocapture noundef readonly %0, i32 noundef %1) {
  %3 = alloca [4 x i32], align 4    ; IR: %3 = alloca [4 x i8]  (classical slots: one handle per cell)
  %4 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %3: cell 0 = 0  [register cell 0]
  %5 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %3: cell 1 = 0  [register cell 1]
  %6 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %3: cell 2 = 0  [register cell 2]
  %7 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %3: cell 3 = 0  [register cell 3]
  store i32 %4, ptr %3, align 4    ; IR: (slot 0)
  %8 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 1
  store i32 %5, ptr %8, align 4    ; IR: (slot 1)
  %9 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 2
  store i32 %6, ptr %9, align 4    ; IR: (slot 2)
  %10 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 3
  store i32 %7, ptr %10, align 4    ; IR: (slot 3)
  %11 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %30 = phi i32 [ 0, %7 ], [ %28, %27 ], [ %1, %24 ]: the innermost arm of the exit select chain, the incoming 0 of the cap <= 0 edge  [seed rail]
  %12 = icmp sgt i32 %1, 0    ; IR: %4 / %8  (classical; -O1 tests it twice)
  br i1 %12, label %13, label %55    ; IR: br i1 %4

13:
  %14 = zext nneg i32 %1 to i64    ; IR: %6 / %10  (classical)
  br label %15

15:
  %16 = phi i64 [ 0, %13 ], [ %22, %15 ]    ; IR: %12  (classical i)
  %17 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %16    ; IR: %13  (slot of s[i])
  %18 = load i32, ptr %17, align 4    ; IR: (handle of s[i]: the |0> rail of the zero initializer, never written)
  call void @cqrt_free(i32 %18)    ; IR: store i8 97, ptr %13: the cell's old rail is released (a seed in a known basis state)
  %19 = call i32 @cqrt_alloc_i8(i8 97)    ; IR: store i8 97, ptr %13  [the classical 'a' as a fresh basis-state seed: register s[i]]
  store i32 %19, ptr %17, align 4    ; IR: (the slot takes the seed's handle)
  %20 = getelementptr inbounds double, ptr %0, i64 %16    ; IR: %14  (classical)
  %21 = load double, ptr %20, align 8    ; IR: %15  (classical angle)
  call void @cqrt_ry_i8(i32 %19, double %21)    ; IR: %16 = cq_theta_c(97, %15)  [Ry in place on s[i]]; store i8 %16: handle unchanged
  %22 = add nuw nsw i64 %16, 1    ; IR: %17  (classical)
  %23 = icmp eq i64 %22, %14    ; IR: %18  (classical)
  br i1 %23, label %24, label %15    ; IR: br i1 %18

24:
  %25 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the first test in %19 (always 1)
  br label %26

26:
  %27 = phi i64 [ 0, %24 ], [ %37, %26 ]    ; IR: %20  (classical trip i)
  %28 = phi i32 [ %25, %24 ], [ %36, %26 ]    ; IR: predicate of reaching this trip's test
  %29 = phi i32 [ %11, %24 ], [ %35, %26 ]    ; IR: %30: the exit select chain so far (r_(i-1))
  %30 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %27    ; IR: %21  (slot of s[i])
  %31 = load i32, ptr %30, align 4    ; IR: %22 = load i8, ptr %21  (handle of s[i])
  %32 = call i32 @cq_template_icmp_eq_i8_hl(i32 %31, i8 0)    ; IR: %23 = icmp eq i8 %22, 0
  %33 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %27 at this trip (the NUL exit)
  call void @cqrt_and_i1(i32 %28, i32 %32, i32 %33)    ; IR: br i1 %23, label %27  taken
  %34 = trunc nuw nsw i64 %27 to i32    ; IR: %28 = trunc nuw nsw i64 %20 to i32  (classical)
  %35 = call i32 @cq_template_select_i32_lh(i32 %33, i32 %34, i32 %29)    ; IR: %30 incoming %28 from %27: r_i = e_i ? i : r_(i-1)  [fresh rail]
  call void @cqrt_not_i1(i32 %32)    ; IR: NOT %23
  %36 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %24 at this trip (continue)
  call void @cqrt_and_i1(i32 %28, i32 %32, i32 %36)    ; IR: br i1 %23, ..., label %24  taken
  call void @cqrt_not_i1(i32 %32)    ; IR: restore %23
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %32)
  call void @cqrt_push(i32 %33)
  call void @cqrt_push(i32 %29)
  %37 = add nuw nsw i64 %27, 1    ; IR: %25  (classical)
  %38 = icmp eq i64 %37, %14    ; IR: %26  (classical bound: the buffer size)
  br i1 %38, label %39, label %26    ; IR: br i1 %26

39:
  %40 = call i32 @cq_template_select_i32_lh(i32 %36, i32 %1, i32 %35)    ; IR: %30 incoming %1 from %24 (no NUL in the buffer): r = a_last ? cap : r_last  [result rail; exclusive with every e_i]
  br label %41

41:
  %42 = phi i64 [ %14, %39 ], [ %45, %41 ]    ; IR: reverse trip index (counts down)
  %43 = phi i32 [ %36, %39 ], [ %49, %41 ]    ; IR: continue-predicate of this trip
  %44 = phi i32 [ %35, %39 ], [ %46, %41 ]    ; IR: r_i of this trip
  %45 = add nsw i64 %42, -1    ; IR: the trip being undone
  %46 = call i32 @cqrt_pop()    ; IR: r_(i-1)
  %47 = call i32 @cqrt_pop()    ; IR: e_i
  %48 = call i32 @cqrt_pop()    ; IR: %23 of that trip
  %49 = call i32 @cqrt_pop()    ; IR: a_(i-1)
  %50 = trunc nuw nsw i64 %45 to i32    ; IR: %28 of that trip (classical)
  call void @cq_template_select_i32_lh_unc(i32 %44, i32 %47, i32 %50, i32 %46)    ; IR: uncompute r_i
  call void @cqrt_free(i32 %44)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %48)
  call void @cqrt_and_i1(i32 %49, i32 %48, i32 %43)    ; IR: uncompute the continue-predicate
  call void @cqrt_not_i1(i32 %48)
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %49, i32 %48, i32 %47)    ; IR: uncompute the exit predicate
  call void @cqrt_free(i32 %47)    ; IR: release it (|0>)
  %51 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %45    ; IR: %21 of that trip
  %52 = load i32, ptr %51, align 4    ; IR: (handle of s[i])
  call void @cq_template_icmp_eq_i8_hl_unc(i32 %48, i32 %52, i8 0)    ; IR: uncompute %23
  call void @cqrt_free(i32 %48)    ; IR: release the %23 rail (|0>)
  %53 = icmp eq i64 %45, 0
  br i1 %53, label %54, label %41

54:
  call void @cqrt_not_i1(i32 %49)    ; IR: seed predicate back to |0>
  call void @cqrt_free(i32 %49)    ; IR: release the seed (|0>)
  call void @cqrt_free(i32 %11)    ; IR: release the chain's seed rail (never written, |0>)
  br label %55

55:
  %56 = phi i32 [ %11, %2 ], [ %40, %54 ]    ; IR: %30: the seed itself when cap <= 0 (incoming 0), else the chain's result
  %57 = call i32 @cqrt_measure_i32(i32 %56)    ; IR: %31 = cq_measure_si32(%30)
  ret i32 %57    ; IR: ret i32 %31
}

define i32 @quantum_strcmp(ptr nocapture noundef readonly %0, ptr nocapture noundef readonly %1, i32 noundef %2) {
  %4 = alloca [4 x i32], align 4    ; IR: %4 = alloca [4 x i8]  (classical slots: one handle per cell)
  %5 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %4: cell 0 = 0  [register cell 0]
  %6 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %4: cell 1 = 0  [register cell 1]
  %7 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %4: cell 2 = 0  [register cell 2]
  %8 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %4: cell 3 = 0  [register cell 3]
  store i32 %5, ptr %4, align 4    ; IR: (slot 0)
  %9 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 1
  store i32 %6, ptr %9, align 4    ; IR: (slot 1)
  %10 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 2
  store i32 %7, ptr %10, align 4    ; IR: (slot 2)
  %11 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 3
  store i32 %8, ptr %11, align 4    ; IR: (slot 3)
  %12 = alloca [4 x i32], align 4    ; IR: %5 = alloca [4 x i8]  (classical slots: one handle per cell)
  %13 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %5: cell 0 = 0  [register cell 0]
  %14 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %5: cell 1 = 0  [register cell 1]
  %15 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %5: cell 2 = 0  [register cell 2]
  %16 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i32 0, ptr %5: cell 3 = 0  [register cell 3]
  store i32 %13, ptr %12, align 4    ; IR: (slot 0)
  %17 = getelementptr inbounds [4 x i32], ptr %12, i64 0, i64 1
  store i32 %14, ptr %17, align 4    ; IR: (slot 1)
  %18 = getelementptr inbounds [4 x i32], ptr %12, i64 0, i64 2
  store i32 %15, ptr %18, align 4    ; IR: (slot 2)
  %19 = getelementptr inbounds [4 x i32], ptr %12, i64 0, i64 3
  store i32 %16, ptr %19, align 4    ; IR: (slot 3)
  %20 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %44 = phi i32 [ %42, %37 ], [ 0, %9 ], [ 0, %25 ]: the innermost arm of the exit select chain; both 0 incomings are its value  [seed rail]
  %21 = icmp sgt i32 %2, 0    ; IR: %6 / %10  (classical)
  br i1 %21, label %22, label %85    ; IR: br i1 %6

22:
  %23 = zext nneg i32 %2 to i64    ; IR: %8 / %12  (classical)
  br label %24

24:
  %25 = phi i64 [ 0, %22 ], [ %36, %24 ]    ; IR: %14  (classical i)
  %26 = getelementptr inbounds [4 x i32], ptr %12, i64 0, i64 %25    ; IR: %15  (slot of b[i])
  %27 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %25    ; IR: %16  (slot of a[i])
  %28 = load i32, ptr %27, align 4    ; IR: (handle of a[i]: the |0> rail of the zero initializer, never written)
  %29 = load i32, ptr %26, align 4    ; IR: (handle of b[i]: likewise)
  call void @cqrt_free(i32 %29)    ; IR: store i8 97, ptr %15: b[i]'s old rail is released (a seed in a known basis state)
  %30 = call i32 @cqrt_alloc_i8(i8 97)    ; IR: store i8 97, ptr %15  [the classical 'a' as a fresh basis-state seed: register b[i]]
  store i32 %30, ptr %26, align 4    ; IR: (the slot takes the seed's handle)
  call void @cqrt_free(i32 %28)    ; IR: store i8 97, ptr %16: a[i]'s old rail is released
  %31 = call i32 @cqrt_alloc_i8(i8 97)    ; IR: store i8 97, ptr %16  [register a[i]]
  store i32 %31, ptr %27, align 4    ; IR: (the slot takes the seed's handle)
  %32 = getelementptr inbounds double, ptr %0, i64 %25    ; IR: %17  (classical)
  %33 = load double, ptr %32, align 8    ; IR: %18  (classical angle)
  call void @cqrt_ry_i8(i32 %31, double %33)    ; IR: %19 = cq_theta_c(97, %18)  [Ry in place on a[i]]
  %34 = getelementptr inbounds double, ptr %1, i64 %25    ; IR: %20  (classical)
  %35 = load double, ptr %34, align 8    ; IR: %21  (classical angle)
  call void @cqrt_ry_i8(i32 %30, double %35)    ; IR: %22 = cq_theta_c(97, %21)  [Ry in place on b[i]]
  %36 = add nuw nsw i64 %25, 1    ; IR: %23  (classical)
  %37 = icmp eq i64 %36, %23    ; IR: %24  (classical)
  br i1 %37, label %38, label %24    ; IR: br i1 %24

38:
  %39 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of reaching the first test in %28 (always 1)
  br label %40

40:
  %41 = phi i64 [ 0, %38 ], [ %59, %40 ]    ; IR: %29  (classical trip i)
  %42 = phi i32 [ %39, %38 ], [ %52, %40 ]    ; IR: predicate of block %28 at this trip
  %43 = phi i32 [ %20, %38 ], [ %58, %40 ]    ; IR: %44: the exit select chain so far (r_(i-1))
  %44 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %41    ; IR: %30  (slot of a[i])
  %45 = load i32, ptr %44, align 4    ; IR: %31 = load i8, ptr %30  (handle of a[i])
  %46 = call i32 @cq_template_icmp_eq_i8_hl(i32 %45, i8 0)    ; IR: %32 = icmp eq i8 %31, 0
  %47 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of %28 -> %37 (NUL in a)
  call void @cqrt_and_i1(i32 %42, i32 %46, i32 %47)    ; IR: br i1 %32, label %37  taken
  call void @cqrt_not_i1(i32 %46)    ; IR: NOT %32
  %48 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %33
  call void @cqrt_and_i1(i32 %42, i32 %46, i32 %48)    ; IR: br i1 %32, ..., label %33  taken
  call void @cqrt_not_i1(i32 %46)    ; IR: restore %32
  %49 = getelementptr inbounds [4 x i32], ptr %12, i64 0, i64 %41    ; IR: %34  (slot of b[i])
  %50 = load i32, ptr %49, align 4    ; IR: %35 = load i8, ptr %34  (handle of b[i])
  %51 = call i32 @cq_template_icmp_eq_i8(i32 %45, i32 %50)    ; IR: %36 = icmp eq i8 %31, %35  (computed unconditionally: pure)
  %52 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %25 (continue)
  call void @cqrt_and_i1(i32 %48, i32 %51, i32 %52)    ; IR: br i1 %36, label %25  taken
  call void @cqrt_not_i1(i32 %51)    ; IR: NOT %36
  %53 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of %33 -> %37 (a[i] != b[i])
  call void @cqrt_and_i1(i32 %48, i32 %51, i32 %53)    ; IR: br i1 %36, ..., label %37  taken
  call void @cqrt_not_i1(i32 %51)    ; IR: restore %36
  %54 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: block %37's edge flag at this trip: x_i = e1_i | e2_i
  call void @cqrt_or_i1(i32 %47, i32 %53, i32 %54)    ; IR: the disjunction of the two exit predicates (exclusive)
  %55 = call i32 @cq_template_sext_i8_to_i32(i32 %45)    ; IR: %38 = sext i8 %31 to i32  (block %37, computed unconditionally: pure)
  %56 = call i32 @cq_template_sext_i8_to_i32(i32 %50)    ; IR: %39/%40 reload b[i] (same handle as %35); %41 = sext i8 %40 to i32
  %57 = call i32 @cq_template_sub_i32(i32 %55, i32 %56)    ; IR: %42 = sub nsw i32 %38, %41
  %58 = call i32 @cq_template_select_i32(i32 %54, i32 %57, i32 %43)    ; IR: %44 incoming %42 from %37: r_i = x_i ? d : r_(i-1)  [fresh rail]
  call void @cqrt_push(i32 %42)
  call void @cqrt_push(i32 %46)
  call void @cqrt_push(i32 %47)
  call void @cqrt_push(i32 %48)
  call void @cqrt_push(i32 %51)
  call void @cqrt_push(i32 %53)
  call void @cqrt_push(i32 %54)
  call void @cqrt_push(i32 %43)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %56)
  call void @cqrt_push(i32 %57)
  %59 = add nuw nsw i64 %41, 1    ; IR: %26  (classical)
  %60 = icmp eq i64 %59, %23    ; IR: %27  (classical bound)
  br i1 %60, label %61, label %40    ; IR: br i1 %27  (the fall-through exit contributes 0: the seed's value, no select)

61:
  %62 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %44  [result rail: the last trip's r copied out]
  call void @cqrt_copy_i32(i32 %58, i32 %62)    ; IR: %44 = r_last
  br label %63

63:
  %64 = phi i64 [ %23, %61 ], [ %67, %63 ]    ; IR: reverse trip index (counts down)
  %65 = phi i32 [ %52, %61 ], [ %78, %63 ]    ; IR: continue-predicate of this trip
  %66 = phi i32 [ %58, %61 ], [ %71, %63 ]    ; IR: r_i of this trip
  %67 = add nsw i64 %64, -1    ; IR: the trip being undone
  %68 = call i32 @cqrt_pop()    ; IR: %42 of that trip (d, kept alive for the select's _unc)
  %69 = call i32 @cqrt_pop()    ; IR: %41 of that trip
  %70 = call i32 @cqrt_pop()    ; IR: %38 of that trip
  %71 = call i32 @cqrt_pop()    ; IR: r_(i-1)
  %72 = call i32 @cqrt_pop()    ; IR: x_i
  %73 = call i32 @cqrt_pop()    ; IR: e2_i
  %74 = call i32 @cqrt_pop()    ; IR: %36 of that trip
  %75 = call i32 @cqrt_pop()    ; IR: predicate of %33
  %76 = call i32 @cqrt_pop()    ; IR: e1_i
  %77 = call i32 @cqrt_pop()    ; IR: %32 of that trip
  %78 = call i32 @cqrt_pop()    ; IR: predicate of %28
  %79 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %67    ; IR: %30 of that trip
  %80 = load i32, ptr %79, align 4    ; IR: (handle of a[i])
  %81 = getelementptr inbounds [4 x i32], ptr %12, i64 0, i64 %67    ; IR: %34 of that trip
  %82 = load i32, ptr %81, align 4    ; IR: (handle of b[i])
  call void @cq_template_select_i32_unc(i32 %66, i32 %72, i32 %68, i32 %71)    ; IR: uncompute r_i
  call void @cqrt_free(i32 %66)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_unc(i32 %68, i32 %70, i32 %69)    ; IR: uncompute %42
  call void @cqrt_free(i32 %68)    ; IR: release the %42 rail (|0>)
  call void @cq_template_sext_i8_to_i32_unc(i32 %69, i32 %82)    ; IR: uncompute %41
  call void @cqrt_free(i32 %69)    ; IR: release the %41 rail (|0>)
  call void @cq_template_sext_i8_to_i32_unc(i32 %70, i32 %80)    ; IR: uncompute %38
  call void @cqrt_free(i32 %70)    ; IR: release the %38 rail (|0>)
  call void @cqrt_or_i1(i32 %76, i32 %73, i32 %72)    ; IR: uncompute x_i (t ^= e1 | e2 is an involution)
  call void @cqrt_free(i32 %72)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %74)
  call void @cqrt_and_i1(i32 %75, i32 %74, i32 %73)    ; IR: uncompute the mismatch-exit predicate
  call void @cqrt_not_i1(i32 %74)
  call void @cqrt_free(i32 %73)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %75, i32 %74, i32 %65)    ; IR: uncompute the continue-predicate
  call void @cqrt_free(i32 %65)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i8_unc(i32 %74, i32 %80, i32 %82)    ; IR: uncompute %36
  call void @cqrt_free(i32 %74)    ; IR: release the %36 rail (|0>)
  call void @cqrt_not_i1(i32 %77)
  call void @cqrt_and_i1(i32 %78, i32 %77, i32 %75)    ; IR: uncompute the predicate of %33
  call void @cqrt_not_i1(i32 %77)
  call void @cqrt_free(i32 %75)    ; IR: release it (|0>)
  call void @cqrt_and_i1(i32 %78, i32 %77, i32 %76)    ; IR: uncompute the NUL-exit predicate
  call void @cqrt_free(i32 %76)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i8_hl_unc(i32 %77, i32 %80, i8 0)    ; IR: uncompute %32
  call void @cqrt_free(i32 %77)    ; IR: release the %32 rail (|0>)
  %83 = icmp eq i64 %67, 0
  br i1 %83, label %84, label %63

84:
  call void @cqrt_not_i1(i32 %78)    ; IR: seed predicate back to |0>
  call void @cqrt_free(i32 %78)    ; IR: release the seed (|0>)
  call void @cqrt_free(i32 %20)    ; IR: release the chain's seed rail (never written, |0>)
  br label %85

85:
  %86 = phi i32 [ %20, %3 ], [ %62, %84 ]    ; IR: %44: the seed itself when cap <= 0 (incoming 0), else the copied-out result
  %87 = call i32 @cqrt_measure_i32(i32 %86)    ; IR: %45 = cq_measure_si32(%44)
  ret i32 %87    ; IR: ret i32 %45
}

declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i8(i32, double)
declare i32 @cq_template_icmp_eq_i8_hl(i32, i8)
declare void @cq_template_icmp_eq_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_icmp_eq_i8(i32, i32)
declare void @cq_template_icmp_eq_i8_unc(i32, i32, i32)
declare i32 @cq_template_sext_i8_to_i32(i32)
declare void @cq_template_sext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_or_i1(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
