; HAND-WRITTEN. Rules: 14, 3, 20, 21, 5, 4, 9, 10, 8, 7, 2; §1.3 (the bus, __cq_mem).
; Checked: r + (acc > 0.0), r and acc measured.
; Clean: every trip's load copy c[i] (un-copied by the mirror after the product's _unc, under the predicate it was loaded
; with: no memory version change follows any load, rule 5 sentence 1), product rail c[i] * x, u_i, break flag e_i,
; carried acc_i and predicate a_i (popped and uncomputed by the mirror), the |1> seed predicate (minted after the
; zero-trip test, never on the skip path; rule 14) and the 0.0 seed of acc (rule 7), and the final flag acc > 2 lim.
; Kept: the user register x; the copied-out acc rail (measured); r (rotated under control, frozen, measured). No store,
; no tape slot: the function never writes the bus.
; Rotations: Ry(th) on x; Ry(tr) on the fresh |0> rail r under (acc > 2 lim), acc the copied-out loop result.
; Three mechanisms composed: the loop-carried fp rail of 28 (one unfused multiply-add per trip, §2: an fmul product
; rail c[i] * x and an fadd into u_i, both pushed on the handle stack; the mirror after the copy-out), the quantum break
; of 26, and the controlled Ry of 39 conditioned on the loop's RESULT (rule 14, classical bound with a quantum break).
; MEMORY. c is a host pointer parameter: nothing is known about what it points to (rule 21), so the load c[i] is a BUS
; LOAD and its value a rail (rule 3; the cells are HOST, so the copy is c[i] when trip i runs and +0.0 when it does
; not: under a_{i-1} it is a which-path copy entangled with x, a 64-qubit rail un-copied by the mirror), and the
; product is the two-rail fmul (IR order: c[i], x). m = __cq_mem() once at function entry. The gep has
; an untainted base and the classical induction i, so it stays and its ptrtoint is the classical _hl address (rule 20).
; The load sits in trip i's body, which runs iff a_{i-1}: it is _hl_controlled under a_{i-1} (rule 5: a trip C would not
; run touches no cell and no host byte; the exit test reads it, and a_{i-1} is the predicate of reaching that test,
; rule 14). The load copy is trip-local garbage that rule 5 un-copies (the loop has no memory version change), so it
; is pushed with the trip's other rails; the mirror recomputes the address from the trip index and un-copies it after
; the product's _unc (its last reader), under the same control a_{j-1}, still live at that point.
; -O1 tests the break AFTER the body and folds it with the classical exit into `select i1 %17, i1 true, i1 %19`; the
; classical half %19 keeps the loop a classical loop over all n trips, the quantum half becomes the trip predicate: trip
; i's body runs iff a_{i-1} (no break before it), a_i = a_{i-1} AND NOT (u_i > lim), u_i = (c[i] * x) + acc_{i-1} (two
; roundings) computed unguarded (pure; on a trip that does not run the load is |0> = +0.0 and u_i is discarded by the
; select), and the carried value is acc_i = a_{i-1} ? u_i : acc_{i-1}. After the last trip acc_n is the exit phi %22 for
; every break point. WHICH-PATH RAILS: every trip predicate a_i and break flag e_i is entangled with x and is
; uncomputed by the mirror, together with u_i, its product rail, the load copy and acc_i, while x still holds the value
; the trips read; nothing of the loop survives except the copied-out acc. The mirror runs BEFORE the controlled Ry
; (62/116 placement), so the Ry's flag is computed from the copy: f = acc > 2 lim, Ry(tr) on the fresh |0> rail r under
; f, f uncomputed, r and acc measured. n <= 0 takes the classical edge: acc is the seed rail (0.0), the same tail runs
; on it, and no cell is read. The bound n is classical: no K.
source_filename = "float_accum_quantum_break.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @float_accum_break(double noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @__cq_mem()    ; IR: the bus m (once, at function entry)
  %8 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %7 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %8, double %1)    ; IR: %7 = cq_theta_f64(%0, %1)  [Ry]
  %9 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: incoming 0.0 of phi %13 / %22  [acc before trip 0]
  %10 = icmp sgt i32 %3, 0    ; IR: %8 = icmp sgt i32 %3, 0  (classical)
  br i1 %10, label %12, label %11    ; IR: br i1 %8, label %9, label %21

11:
  br label %46    ; IR: br label %21: %22 = 0.0 from %6, the seed rail

12:
  %13 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of running trip 0 (always 1), minted after the zero-trip test (rule 14)
  %14 = zext nneg i32 %3 to i64    ; IR: %10 = zext nneg i32 %3 to i64  (classical)
  br label %15

15:
  %16 = phi i64 [ 0, %12 ], [ %27, %15 ]    ; IR: %12 = phi i64 [ 0, %9 ], [ %18, %11 ]  (classical i)
  %17 = phi i32 [ %9, %12 ], [ %25, %15 ]    ; IR: %13 = phi double [ 0.0, %9 ], [ %16, %11 ]  [acc_{i-1}]
  %18 = phi i32 [ %13, %12 ], [ %26, %15 ]    ; IR: predicate a_{i-1}: this trip's body runs
  %19 = getelementptr inbounds double, ptr %2, i64 %16    ; IR: %14  (classical)
  %20 = ptrtoint ptr %19 to i64    ; IR: %14 as its run-time address, the _hl literal (rule 20)
  %21 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %18, i32 %7, i64 %20)    ; IR: %15 = load double, ptr %14  [bus load c[i], a rail (rule 3); under a_{i-1}, the predicate of reaching this trip's test]
  %22 = call i32 @cq_template_fmul_f64(i32 %21, i32 %8)    ; IR: %16 = llvm.fmuladd.f64(%15, %7, %13)  [unfused product c[i] * x, two rails]
  %23 = call i32 @cq_template_fadd_f64(i32 %22, i32 %17)    ; IR: %16 = llvm.fmuladd.f64(%15, %7, %13)  [unfused sum + acc]
  %24 = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %23, double %4)    ; IR: %17 = fcmp ogt double %16, %4  [break condition e_i]
  %25 = call i32 @cq_template_select_f64(i32 %18, i32 %23, i32 %17)    ; IR: next %13 / %22 = a_{i-1} ? %16 : %13
  %26 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate a_i of the next trip
  call void @cqrt_not_i1(i32 %24)    ; IR: bracket: the loop continues when the break condition is false
  call void @cqrt_and_i1(i32 %18, i32 %24, i32 %26)    ; IR: %20 = select i1 %17, true, %19, quantum half: a_i = a_{i-1} & NOT e_i
  call void @cqrt_not_i1(i32 %24)    ; IR: bracket
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %18)
  call void @cqrt_push(i32 %23)
  call void @cqrt_push(i32 %24)
  call void @cqrt_push(i32 %22)    ; IR: %16 [product rail, kept for the mirror]
  call void @cqrt_push(i32 %21)    ; IR: %15 [load copy, un-copied by the mirror (rule 5 sentence 1)]
  %27 = add nuw nsw i64 %16, 1    ; IR: %18 = add nuw nsw i64 %12, 1  (classical)
  %28 = icmp eq i64 %27, %14    ; IR: %19 = icmp eq i64 %18, %10  (classical half of %20)
  br i1 %28, label %29, label %15    ; IR: br i1 %20 on its classical half

29:
  %30 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: %22 = phi double [ %16, %11 ]  [copied-out acc]
  call void @cqrt_copy_f64(i32 %25, i32 %30)    ; IR: %22
  br label %31

31:
  %32 = phi i64 [ %16, %29 ], [ %43, %31 ]    ; IR: trip being undone, from the last down to 0
  %33 = phi i32 [ %25, %29 ], [ %40, %31 ]    ; IR: acc_j
  %34 = phi i32 [ %26, %29 ], [ %39, %31 ]    ; IR: a_j
  %35 = call i32 @cqrt_pop()    ; IR: that trip's load copy
  %36 = call i32 @cqrt_pop()    ; IR: that trip's product rail
  %37 = call i32 @cqrt_pop()
  %38 = call i32 @cqrt_pop()
  %39 = call i32 @cqrt_pop()
  %40 = call i32 @cqrt_pop()
  %41 = getelementptr double, ptr %2, i64 %32    ; IR: %14 of that trip, recomputed from the trip index
  %42 = ptrtoint ptr %41 to i64    ; IR: its address
  call void @cqrt_not_i1(i32 %37)    ; IR: bracket
  call void @cqrt_and_i1(i32 %39, i32 %37, i32 %34)    ; IR: uncompute a_j
  call void @cqrt_not_i1(i32 %37)    ; IR: bracket
  call void @cqrt_free(i32 %34)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %33, i32 %39, i32 %38, i32 %40)    ; IR: uncompute acc_j
  call void @cqrt_free(i32 %33)    ; IR: release it (|0>)
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %37, i32 %38, double %4)    ; IR: uncompute %17
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  call void @cq_template_fadd_f64_unc(i32 %38, i32 %36, i32 %40)    ; IR: uncompute %16  [sum]
  call void @cqrt_free(i32 %38)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_unc(i32 %36, i32 %35, i32 %8)    ; IR: uncompute %16  [product]
  call void @cqrt_free(i32 %36)    ; IR: release the product rail (|0>)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %35, i32 %39, i32 %7, i64 %42)    ; IR: un-copy %15 under a_{j-1}, its load control (rule 5: no memory version change since the load)
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  %43 = add nsw i64 %32, -1
  %44 = icmp sge i64 %43, 0
  br i1 %44, label %31, label %45

45:
  call void @cqrt_not_i1(i32 %39)    ; IR: seed predicate back to |0>
  call void @cqrt_free(i32 %39)    ; IR: release the seed (|0>)
  call void @cqrt_free(i32 %40)    ; IR: release incoming 0.0 of phi %13 (never written; +0.0 is all-zero bits, |0>)
  br label %46

46:
  %47 = phi i32 [ %9, %11 ], [ %30, %45 ]    ; IR: %22 = phi double [ 0.0, %6 ], [ %16, %11 ]  [final acc rail]
  %48 = fmul double %4, 2.000000e+00    ; IR: %23 = fmul double %4, 2.0  (classical)
  %49 = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %47, double %48)    ; IR: %24 = fcmp ogt double %22, %23  [path predicate of block %25]
  %50 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %28 = phi i1 [ %26, %25 ], [ false, %21 ]  [register r, starts as false]
  call void @cqrt_ry_i1_controlled(i32 %49, i32 %50, double %5)    ; IR: block %25: %26 = cq_theta_i1(false, %5)  [Ry under the predicate]
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %49, i32 %47, double %48)    ; IR: uncompute %24
  call void @cqrt_free(i32 %49)    ; IR: release the %24 rail (|0>)
  %51 = call i1 @cqrt_measure_i1(i32 %50)    ; IR: %29 = cq_measure_i1(%28)
  %52 = zext i1 %51 to i32    ; IR: %30  (classical)
  %53 = call double @cqrt_measure_f64(i32 %47)    ; IR: %31 = cq_measure_f64(%22)
  %54 = fcmp ogt double %53, 0.000000e+00    ; IR: %32  (classical)
  %55 = zext i1 %54 to i32    ; IR: %33  (classical)
  %56 = add nuw nsw i32 %55, %52    ; IR: %34  (classical)
  ret i32 %56    ; IR: ret i32 %34
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_fmul_f64(i32, i32)
declare void @cq_template_fmul_f64_unc(i32, i32, i32)
declare i32 @__cq_mem()
declare i32 @cqrt_qram_load_f64_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_f64_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
declare i32 @cq_template_fcmp_ogt_f64_hl(i32, double)
declare void @cq_template_fcmp_ogt_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_select_f64(i32, i32, i32)
declare void @cq_template_select_f64_unc(i32, i32, i32, i32)
declare void @cqrt_copy_f64(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare double @cqrt_measure_f64(i32)
