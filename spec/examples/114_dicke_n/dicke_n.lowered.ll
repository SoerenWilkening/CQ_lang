; HAND-WRITTEN. Rules: 20 (`bool q[n]` is a runtime-sized bus-resident alloca: one __cq_alloc(n, 16) block of n byte
; cells, every address classical), 16 (the allocation), 5 (every `q[m-1] ^= q[..]` and every controlled rotation of a
; cell is the in-place form: swap out, update or gate, swap in; every other store is kept, every load copy the form
; overtakes is un-copied after its last reader and left allocated), 6 (the update y' = y ^ x inside the form cleans the swapped-out rail: t = y' ^ x fresh, copy, _unc,
; free), 10 (CRy / CCRy are ry_i1_controlled on the swapped-out rail under the flag, the swaps _controlled), 2 (the
; rotated register is the cell; the measured cells are plain load copies), 14 (classical-bound loops: the m-loop and the
; l-loop stay rolled; every trip-local rail is cleaned or kept inside its trip, so nothing is pushed and there is no
; reverse loop), 21 (addresses are ptrtoint of the classical getelementptrs), 7, 8, 9, 3.
; Checked: the cells q[0..n-1] (the n measured cells: each trip of the measure loop takes a plain load copy of q[i] and
; measures it, IR %101; q[i] in bit i of the returned int, n <= 31).
; Clean: per m-trip, the two swap rails of q[m-1] (IR %36 -> %37, %52 -> %53), their rule-6 temporaries and the two
; rails the cell's |0> went to, and the swap rail of the CRy form on q[m-2] (IR %40 -> %48); per l-trip, the same for
; the two forms on q[m-1] (IR %65 -> %66, %88 -> %89) and the CCRy form on q[m-1-l] (IR %76 -> %84), and the CCRy flag
; chain (IR %68, %72, %73, %74); all uncomputed and freed inside the trip that minted them.
; Kept: the init loop's n seeds (alloc_i8 of `i >= n - k`, IR %19) as the value rails of the n kept stores `store i8 %19`
; and their n tape slots (rule 5); the n measured load copies (rule 2). Left allocated, un-copied (rule 5 sentence 1:
; overtaken, a memory version change lies between the load and its un-copy): per m-trip three load copies, the copy of
; q[m-2] the first xor reads (IR %34), the copy of q[m-1] that is the CRy flag (IR %37, read after the swap-in), the
; copy of q[m-2] the second xor reads (IR %51); per l-trip four: the copy of q[m-1-l] the first xor reads (IR %64), the
; copy of q[m-1] the select reads (IR %66, read after the swap-in), the i8 copy of q[m-l] (IR %71), the copy of q[m-1-l]
; the second xor reads (IR %87). Each is un-copied right after its last reader (the rule-6 _unc of t, the controlled
; swap-in, or the flag chain's _unc).
; Rotations: per trip m = n .. 2: (CRy, the cell q[m-2], 2*acos(sqrt(1/m)), q[m-1] ^ q[m-2]) (the copy of q[m-1] after
; its first xor); then per l = 2 .. min(k, m-1): (CCRy, the cell q[m-1-l], 2*acos(sqrt(l/m)), 2*(q[m-1] ^ q[m-1-l]) +
; q[m-l] == 3) (the flag over the copies of q[m-1] after the block's first xor and of q[m-l]). All angles are computed at
; run time from the classical trip counters m and l.
; Bärtschi–Eidenbenz |D^n_k> with n and k function inputs (113 is the fixed-size N = 4, K = 2 instance, whose classical
; prefix -O1 folded). `bool q[n]` is a VLA: -O1's `alloca i8, i64 %3` has tainted stores among its users, so it is
; BUS-RESIDENT (rule 20) and becomes __cq_alloc(n, 16) at its program point (rule 16: zeroed, never reused, no alloca
; remains); -O1's byte getelementptrs over it are classical and stay, and each address is its ptrtoint, the `_hl`
; operand of every access. The init loop stores the classical start value `i >= n - k` into each cell: a kept store
; of the seed alloc_i8 (rules 5, 7; its tape slot takes the zeroed byte). Nothing folds, so every gate appears. Both
; loops have classical bounds and stay rolled exactly as -O1 shaped them: the m-loop (header %28, latch %22) and the
; inner l-loop (header %60, do-while latch `l < kk` %92, entered unless kk < 2 %55).
; Each `q[m-1] ^= q[..]` is `load i8 q[..]; load i8 q[m-1]; icmp ne i8; zext; store i8 q[m-1]` on one SSA pointer with
; no memory version change between its load and its store: rule 5's in-place form at width i1 (Width casts: the loads
; carry !range [0, 2), so the step is xor_i1, SPEC GAP 1). The operand q[..] is a plain load at its own program point
; before the swap-out, overtaken by the form: un-copied after its last reader, not freed. Inside the form the xor into a fresh rail is a rule-6 bijection
; in the swapped-out rail, which is cleaned at once; the result is swapped in and the rail the cell's |0> went to is
; freed. A later reader of the new q[m-1] (the 2-qubit block's `if (q[m-1])`, the 3-qubit block's select) reads a plain
; load taken after the swap-in (rule 5, Readers). The 2-qubit block's arm (block %39: load q[m-2], cq_theta, store
; q[m-2]) is the in-place form on q[m-2] under the flag = that copy (rule 10): the swaps are _controlled, the Ry is
; ry_i1_controlled on the swapped-out rail; the arm's classical angle is hoisted. The 3-qubit block's `s == 3` is the
; strict-Bennett flag chain (select, zext, or, icmp) over two plain load copies into fresh rails, the CCRy is the same
; controlled in-place form on q[m-1-l] under the flag, then the chain is uncomputed and freed and its two copies
; un-copied (untouched by the rotation; l >= 2 keeps the three cells distinct, but nothing is asked). The measured bits
; are packed classically (`r |= bit << i`).
; Per call: n seeds and n tape slots; 2 xor forms and a CRy form per m, 2 xor forms and a CCRy form per l, each xor form
; with its rule-6 clean-up. Each overtaken copy's cell is disjoint from the overtaking form's cell (q[m-2] vs q[m-1],
; q[m-1-l] vs q[m-1], q[m-l] vs q[m-1-l]), so its un-copy reads the value it copied and leaves the rail |0>; rule 5
; never asks this, so the rail is not freed. Every copy is thus disentangled from the cells, which hold the pure
; |D^n_k> before the measure loop (the fixed-model lowering's state); the measured distribution of dicke_n(4,2), (5,2),
; (5,3) is uniform over the weight-k strings (1/C(n,k) each).
; SPEC GAP (marked at its lines; the choice is the one that needs least from an implementer):
;  1. Rule 5's Width-casts clause names `trunc T y to U`; -O1 instead compares the two _Bool cells as `icmp ne i8` over
;     loads with !range [0, 2) and stores `zext i1 to i8` (no trunc). Chosen: a load of T whose range fact
;     (!range [0, 2)) makes it a 0/1 value counts as `trunc nuw T y to i1`, and `zext (icmp ne T y, x) to T` with x
;     also such a load is the step xor_i1(x, y), so `*p ^= *q` on _Bool cells is the in-place form at U = i1
;     (qram_swap_i1_hl; the template the fixed-width lowering already used).
source_filename = "dicke_n.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @dicke_n(i32 noundef %0, i32 noundef %1) {
  %3 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %4 = zext i32 %0 to i64    ; IR: %3  (classical n)
  %5 = call ptr @__cq_alloc(i64 %4, i64 16)    ; IR: %4 = alloca i8, i64 %3, align 16  [bus-resident VLA: one zeroed block of n byte cells, no alloca remains (rules 16, 20)]
  %6 = icmp sgt i32 %0, 0    ; IR: %5  (classical)
  br i1 %6, label %7, label %11    ; IR: br i1 %5

7:
  %8 = sub nsw i32 %0, %1    ; IR: %7 = n - k  (classical)
  %9 = sext i32 %8 to i64    ; IR: %8  (classical)
  %10 = zext nneg i32 %0 to i64    ; IR: %9  (classical)
  br label %16    ; IR: br label %15

11:
  %12 = getelementptr i8, ptr %5, i64 -2    ; IR: %11 = getelementptr i8, ptr %4, i64 -2  (classical: base of q[m-2] = q - 2 + m; the getelementptr stays, rule 20)
  %13 = icmp sgt i32 %0, 1    ; IR: %12  (classical)
  br i1 %13, label %14, label %27    ; IR: br i1 %12

14:
  %15 = zext nneg i32 %0 to i64    ; IR: %14  (classical: m starts at n)
  br label %31    ; IR: br label %28

16:
  %17 = phi i64 [ 0, %7 ], [ %23, %16 ]    ; IR: %16  (classical i)
  %18 = icmp sge i64 %17, %9    ; IR: %17 = i >= n - k  (classical: the cell's start value)
  %19 = getelementptr inbounds i8, ptr %5, i64 %17    ; IR: %18  (&q[i], classical)
  %20 = ptrtoint ptr %19 to i64    ; the run-time address of q[i], a classical i64 (rule 21)
  %21 = zext i1 %18 to i8    ; IR: %19 = zext i1 %17 to i8  (classical)
  %22 = call i32 @cqrt_alloc_i8(i8 %21)    ; IR: store i8 %19, ptr %18  [the seed of the classical value: the store's value rail, KEPT with it (rules 5, 7)]
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %20, i32 %22)    ; IR: store i8 %19, ptr %18, align 1  [a kept store at a classical address: its tape slot takes the zeroed byte (rule 5)]
  %23 = add nuw nsw i64 %17, 1    ; IR: %20  (classical)
  %24 = icmp eq i64 %23, %10    ; IR: %21  (classical)
  br i1 %24, label %11, label %16    ; IR: br i1 %21

25:
  %26 = icmp sgt i64 %32, 2    ; IR: %23 = m > 2  (classical)
  br i1 %26, label %31, label %27    ; IR: br i1 %23

27:
  %28 = icmp sgt i32 %0, 0    ; IR: %25  (classical)
  br i1 %28, label %29, label %92    ; IR: br i1 %25

29:
  %30 = zext nneg i32 %0 to i64    ; IR: %27  (classical)
  br label %94    ; IR: br label %95

31:
  %32 = phi i64 [ %15, %14 ], [ %33, %25 ]    ; IR: %29  (classical m)
  %33 = add nsw i64 %32, -1    ; IR: %30 = m - 1  (classical)
  %34 = trunc nuw nsw i64 %33 to i32    ; IR: %31  (classical)
  %35 = call i32 @llvm.smin.i32(i32 %34, i32 %1)    ; IR: %32 = kk = min(k, m - 1)  (classical)
  %36 = getelementptr i8, ptr %12, i64 %32    ; IR: %33  (&q[m-2], classical)
  %37 = ptrtoint ptr %36 to i64    ; the run-time address of q[m-2] (rule 21)
  %38 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %37)    ; IR: %34 = load i8, ptr %33  (a plain load of q[m-2] before the swap-out; overtaken by the form: un-copied after its last reader, not freed, rule 5)  SPEC GAP 1
  %39 = getelementptr inbounds i8, ptr %5, i64 %33    ; IR: %35  (&q[m-1], classical)
  %40 = ptrtoint ptr %39 to i64    ; the run-time address of q[m-1] (rule 21)
  %41 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %36 = load i8, ptr %35: in-place form at width i1 on q[m-1], the swap rail (|0>)  SPEC GAP 1
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %40, i32 %41)    ; IR: %36 = load i8, ptr %35: swap-out: the rail holds q[m-1], the cell's bit |0>
  %42 = call i32 @cq_template_xor_i1(i32 %38, i32 %41)    ; IR: %37 = icmp ne i8 %36, %34: q[m-1] ^= q[m-2], into a fresh rail  [the step: a rule-6 bijection in the swapped-out value]
  %43 = call i32 @cq_template_xor_i1(i32 %42, i32 %38)    ; IR: rule 6: t = y' ^ q[m-2] recomputes the swapped-out value
  call void @cqrt_copy_i1(i32 %43, i32 %41)    ; IR: rule 6: the swap rail ^= t -> |0>
  call void @cq_template_xor_i1_unc(i32 %43, i32 %42, i32 %38)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %43)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %41)    ; IR: release the swap rail (|0> after the copy)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %40, i32 %42)    ; IR: %38 = zext i1 %37 to i8; store i8 %38, ptr %35: swap-in: the cell holds the new q[m-1], the rail the cell's |0>
  call void @cqrt_free(i32 %42)    ; IR: release the rail (|0>): nothing remains of the update
  call void @cqrt_qram_load_i1_hl_unc(i32 %38, i32 %3, i64 %37)    ; IR: un-copy %34 (q[m-2]) after its last reader (rule 6's _unc of t), placed after the form's swap-in (no bus access inside the form): a memory version change lies between (the form on q[m-1]), so it is not freed (rule 5 sentence 1)
  %44 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %40)    ; IR: br i1 %37  (the reader of %37 after the store: a plain load of q[m-1] taken after the swap-in, rule 5 Readers; the CRy flag, overtaken by the CRy form: un-copied after the controlled swap-in, not freed)
  %45 = trunc nuw nsw i64 %32 to i32    ; IR: %42  (classical)
  %46 = uitofp nneg i32 %45 to double    ; IR: %43  (classical)
  %47 = fdiv double 1.000000e+00, %46    ; IR: %44 = 1 / m  (classical)
  %48 = call double @llvm.sqrt.f64(double %47)    ; IR: %45  (classical)
  %49 = call double @llvm.acos.f64(double %48)    ; IR: %46  (classical)
  %50 = fmul double %49, 2.000000e+00    ; IR: %47  (classical angle; the arm's classical code hoisted)
  %51 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: block %39: %40 = load i8, ptr %33; %41 = trunc nuw: the in-place form on q[m-2] under the flag (rule 10), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %44, i32 %3, i64 %37, i32 %51)    ; IR: %40 = load i8, ptr %33: swap-out under the flag
  call void @cqrt_ry_i1_controlled(i32 %44, i32 %51, double %50)    ; IR: %48 = cq_theta_i1(%41, %47): the condition is q[m-1]'s copy, the target q[m-2]  [CRy]
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %44, i32 %3, i64 %37, i32 %51)    ; IR: %49 = zext; store i8 %49, ptr %33: swap-in under the flag: the cell holds the rotated q[m-2]
  call void @cqrt_qram_load_i1_hl_unc(i32 %44, i32 %3, i64 %40)    ; IR: un-copy the flag copy of q[m-1] after its last reader (the controlled swap-in): a memory version change lies between (the form on q[m-2]), so it is not freed (rule 5 sentence 1)
  call void @cqrt_free(i32 %51)    ; IR: release the swap rail (|0> on both branches of the flag)
  %52 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %37)    ; IR: %51 = load i8, ptr %33  (a plain load of q[m-2] before the swap-out; overtaken by the form: un-copied after its last reader, not freed)  SPEC GAP 1
  %53 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %52 = load i8, ptr %35: in-place form at width i1 on q[m-1], the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %40, i32 %53)    ; IR: %52 = load i8, ptr %35: swap-out
  %54 = call i32 @cq_template_xor_i1(i32 %52, i32 %53)    ; IR: %53 = icmp ne i8 %52, %51: q[m-1] ^= q[m-2], into a fresh rail  [the step]
  %55 = call i32 @cq_template_xor_i1(i32 %54, i32 %52)    ; IR: rule 6: t = y' ^ q[m-2] recomputes the swapped-out value
  call void @cqrt_copy_i1(i32 %55, i32 %53)    ; IR: rule 6: the swap rail ^= t -> |0>
  call void @cq_template_xor_i1_unc(i32 %55, i32 %54, i32 %52)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %55)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %53)    ; IR: release the swap rail (|0> after the copy)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %40, i32 %54)    ; IR: %54 = zext; store i8 %54, ptr %35: swap-in
  call void @cqrt_free(i32 %54)    ; IR: release the rail (|0>)
  call void @cqrt_qram_load_i1_hl_unc(i32 %52, i32 %3, i64 %37)    ; IR: un-copy %51 (q[m-2]) after its last reader (rule 6's _unc of t), placed after the form's swap-in (no bus access inside the form): a memory version change lies between (the form on q[m-1]), so it is not freed (rule 5 sentence 1)
  %56 = icmp slt i32 %35, 2    ; IR: %55 = kk < 2  (classical: no 3-qubit block)
  br i1 %56, label %25, label %57    ; IR: br i1 %55

57:
  %58 = trunc nuw nsw i64 %32 to i32    ; IR: %57  (classical)
  %59 = uitofp nneg i32 %58 to double    ; IR: %58 = (double)m  (classical)
  %60 = zext nneg i32 %35 to i64    ; IR: %59  (classical)
  br label %61    ; IR: br label %60

61:
  %62 = phi i64 [ 2, %57 ], [ %90, %61 ]    ; IR: %61  (classical l)
  %63 = sub nsw i64 %33, %62    ; IR: %62 = m - 1 - l  (classical)
  %64 = getelementptr inbounds i8, ptr %5, i64 %63    ; IR: %63  (&q[m-1-l], classical)
  %65 = ptrtoint ptr %64 to i64    ; the run-time address of q[m-1-l] (rule 21)
  %66 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %65)    ; IR: %64 = load i8, ptr %63  (a plain load of q[m-1-l] before the swap-out; overtaken by the form: un-copied after its last reader, not freed)  SPEC GAP 1
  %67 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %65 = load i8, ptr %35: in-place form at width i1 on q[m-1], the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %40, i32 %67)    ; IR: %65 = load i8, ptr %35: swap-out
  %68 = call i32 @cq_template_xor_i1(i32 %66, i32 %67)    ; IR: %66 = icmp ne i8 %65, %64: q[m-1] ^= q[m-1-l], into a fresh rail  [the step]
  %69 = call i32 @cq_template_xor_i1(i32 %68, i32 %66)    ; IR: rule 6: t = y' ^ q[m-1-l] recomputes the swapped-out value
  call void @cqrt_copy_i1(i32 %69, i32 %67)    ; IR: rule 6: the swap rail ^= t -> |0>
  call void @cq_template_xor_i1_unc(i32 %69, i32 %68, i32 %66)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %69)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %67)    ; IR: release the swap rail (|0> after the copy)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %40, i32 %68)    ; IR: %67 = zext; store i8 %67, ptr %35: swap-in
  call void @cqrt_free(i32 %68)    ; IR: release the rail (|0>)
  call void @cqrt_qram_load_i1_hl_unc(i32 %66, i32 %3, i64 %65)    ; IR: un-copy %64 (q[m-1-l]) after its last reader (rule 6's _unc of t), placed after the form's swap-in (no bus access inside the form): a memory version change lies between (the form on q[m-1]), so it is not freed (rule 5 sentence 1)
  %70 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %40)    ; IR: the reader %68 of %66 after the store: a plain load of q[m-1] taken after the swap-in (rule 5, Readers); a flag-chain source, overtaken by the CCRy form: un-copied after its reader's _unc, not freed
  %71 = call i32 @cq_template_select_i32_ll(i32 %70, i32 2, i32 0)    ; IR: %68 = select i1 %66, i32 2, i32 0  (2 * q[m-1])
  %72 = sub nsw i64 %32, %62    ; IR: %69 = m - l  (classical)
  %73 = getelementptr inbounds i8, ptr %5, i64 %72    ; IR: %70  (&q[m-l], classical)
  %74 = ptrtoint ptr %73 to i64    ; the run-time address of q[m-l] (rule 21)
  %75 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %74)    ; IR: %71 = load i8, ptr %70  (a plain load of q[m-l] at i8: its user is a zext, not a trunc to i1, so the access width is the loaded type, as 176/178/179/185; a flag-chain source, overtaken by the CCRy form: un-copied after its reader's _unc, not freed)
  %76 = call i32 @cq_template_zext_i8_to_i32(i32 %75)    ; IR: %72 = zext nneg i8 %71 to i32
  %77 = call i32 @cq_template_or_i32(i32 %71, i32 %76)    ; IR: %73 = or disjoint i32 %68, %72  (s)
  %78 = call i32 @cq_template_icmp_eq_i32_hl(i32 %77, i32 3)    ; IR: %74 = icmp eq i32 %73, 3  [the CCRy flag]
  %79 = trunc nuw nsw i64 %62 to i32    ; IR: %78  (classical)
  %80 = uitofp nneg i32 %79 to double    ; IR: %79  (classical)
  %81 = fdiv double %80, %59    ; IR: %80 = l / m  (classical)
  %82 = call double @llvm.sqrt.f64(double %81)    ; IR: %81  (classical)
  %83 = call double @llvm.acos.f64(double %82)    ; IR: %82  (classical)
  %84 = fmul double %83, 2.000000e+00    ; IR: %83  (classical angle; the arm's classical code hoisted)
  %85 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: block %75: %76 = load i8, ptr %63; %77 = trunc nuw: the in-place form on q[m-1-l] under the flag (rule 10), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %78, i32 %3, i64 %65, i32 %85)    ; IR: %76 = load i8, ptr %63: swap-out under the flag
  call void @cqrt_ry_i1_controlled(i32 %78, i32 %85, double %84)    ; IR: %84 = cq_theta_i1(%77, %83)  [CCRy on q[m-1-l] under the flag]
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %78, i32 %3, i64 %65, i32 %85)    ; IR: %85 = zext; store i8 %85, ptr %63: swap-in under the flag
  call void @cqrt_free(i32 %85)    ; IR: release the swap rail (|0> on both branches of the flag)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %78, i32 %77, i32 3)    ; IR: uncompute %74 after its last controlled gate (its sources are load copies, untouched by the form)
  call void @cqrt_free(i32 %78)    ; IR: release the %74 rail (|0>)
  call void @cq_template_or_i32_unc(i32 %77, i32 %71, i32 %76)    ; IR: uncompute %73
  call void @cqrt_free(i32 %77)    ; IR: release the %73 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %76, i32 %75)    ; IR: uncompute %72
  call void @cqrt_qram_load_i8_hl_unc(i32 %75, i32 %3, i64 %74)    ; IR: un-copy %71 (q[m-l]) after its last reader (the zext's _unc): a memory version change lies between (the CCRy form on q[m-1-l]), so it is not freed (rule 5 sentence 1)
  call void @cqrt_free(i32 %76)    ; IR: release the %72 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %71, i32 %70, i32 2, i32 0)    ; IR: uncompute %68
  call void @cqrt_qram_load_i1_hl_unc(i32 %70, i32 %3, i64 %40)    ; IR: un-copy the copy of q[m-1] after its last reader (the select's _unc): a memory version change lies between (the CCRy form on q[m-1-l]), so it is not freed (rule 5 sentence 1)
  call void @cqrt_free(i32 %71)    ; IR: release the %68 rail (|0>)
  %86 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %65)    ; IR: %87 = load i8, ptr %63  (a plain load of q[m-1-l] before the swap-out; overtaken by the form: un-copied after its last reader, not freed)  SPEC GAP 1
  %87 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %88 = load i8, ptr %35: in-place form at width i1 on q[m-1], the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %40, i32 %87)    ; IR: %88 = load i8, ptr %35: swap-out
  %88 = call i32 @cq_template_xor_i1(i32 %86, i32 %87)    ; IR: %89 = icmp ne i8 %88, %87: q[m-1] ^= q[m-1-l], into a fresh rail  [the step]
  %89 = call i32 @cq_template_xor_i1(i32 %88, i32 %86)    ; IR: rule 6: t = y' ^ q[m-1-l] recomputes the swapped-out value
  call void @cqrt_copy_i1(i32 %89, i32 %87)    ; IR: rule 6: the swap rail ^= t -> |0>
  call void @cq_template_xor_i1_unc(i32 %89, i32 %88, i32 %86)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %89)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %87)    ; IR: release the swap rail (|0> after the copy)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %40, i32 %88)    ; IR: %90 = zext; store i8 %90, ptr %35: swap-in
  call void @cqrt_free(i32 %88)    ; IR: release the rail (|0>)
  call void @cqrt_qram_load_i1_hl_unc(i32 %86, i32 %3, i64 %65)    ; IR: un-copy %87 (q[m-1-l]) after its last reader (rule 6's _unc of t), placed after the form's swap-in (no bus access inside the form): a memory version change lies between (the form on q[m-1]), so it is not freed (rule 5 sentence 1)
  %90 = add nuw nsw i64 %62, 1    ; IR: %91  (classical)
  %91 = icmp ult i64 %62, %60    ; IR: %92 = l < kk  (classical)
  br i1 %91, label %61, label %25    ; IR: br i1 %92

92:
  %93 = phi i32 [ 0, %27 ], [ %104, %94 ]    ; IR: %94  (classical r)
  ret i32 %93    ; IR: ret i32 %94

94:
  %95 = phi i64 [ 0, %29 ], [ %105, %94 ]    ; IR: %96  (classical i)
  %96 = phi i32 [ 0, %29 ], [ %104, %94 ]    ; IR: %97  (classical r)
  %97 = getelementptr inbounds i8, ptr %5, i64 %95    ; IR: %98  (&q[i], classical)
  %98 = ptrtoint ptr %97 to i64    ; the run-time address of q[i] (rule 21)
  %99 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %98)    ; IR: %99 = load i8, ptr %98; %100 = trunc nuw i8 %99 to i1  (a plain load copy of q[i], measured: it stays, rule 2)  (rule 5 Width casts: a reader's plain load is taken at U)
  %100 = call i1 @cqrt_measure_i1(i32 %99)    ; IR: %101 = cq_measure_i1(%100)
  %101 = zext i1 %100 to i32    ; IR: %102  (classical)
  %102 = trunc nuw nsw i64 %95 to i32    ; IR: %103  (classical)
  %103 = shl nuw i32 %101, %102    ; IR: %104 = bit << i  (classical)
  %104 = or i32 %103, %96    ; IR: %105 = r | (bit << i)  (classical)
  %105 = add nuw nsw i64 %95, 1    ; IR: %106  (classical)
  %106 = icmp eq i64 %105, %30    ; IR: %107  (classical)
  br i1 %106, label %92, label %94    ; IR: br i1 %107
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @llvm.smin.i32(i32, i32)
declare double @llvm.sqrt.f64(double)
declare double @llvm.acos.f64(double)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare void @cqrt_qram_load_i1_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i1_hl_controlled(i32, i32, i64, i32)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare void @cqrt_copy_i1(i32, i32)
declare i32 @cq_template_xor_i1(i32, i32)
declare void @cq_template_xor_i1_unc(i32, i32, i32)
declare i1 @cqrt_measure_i1(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
