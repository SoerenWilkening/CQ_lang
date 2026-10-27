; HAND-WRITTEN. Rules: 14, 4, 9, 10, 8, 5, 7, 2.
; Checked: r + (acc > 0.0), r and acc measured.
; Clean: every trip's product rail x * c[i], u_i, break flag e_i, carried acc_i and predicate a_i (popped and uncomputed
; by the mirror), the |1> seed predicate and the 0.0 seed of acc (rule 7), and the final flag acc > 2 lim.
; Kept: the user register x; the copied-out acc rail (measured); r (rotated under control, frozen, measured).
; Rotations: Ry(th) on x; Ry(tr) on the fresh |0> rail r under (acc > 2 lim), acc the copied-out loop result.
; Three mechanisms composed: the loop-carried fp rail of 28 (one unfused multiply-add per trip, §2: an fmul_hl product
; rail x * c[i] and an fadd into u_i, both pushed on the handle stack; the mirror after the copy-out), the quantum break
; of 26, and the controlled Ry of 39 conditioned on the loop's RESULT (rule 14, classical bound with a quantum break).
; -O1 tests the break AFTER the body and folds it with the classical exit into `select i1 %17, i1 true, i1 %19`; the
; classical half %19 keeps the loop a classical loop over all n trips, the quantum half becomes the trip predicate: trip
; i's body runs iff a_{i-1} (no break before it), a_i = a_{i-1} AND NOT (u_i > lim), u_i = (c[i] * x) + acc_{i-1} (two
; roundings) computed unguarded (pure), and the carried value is acc_i = a_{i-1} ? u_i : acc_{i-1}. After the last trip
; acc_n is the exit phi %22 for every break point. WHICH-PATH RAILS: every trip predicate a_i and break flag e_i is
; entangled with x and is uncomputed by the mirror, together with u_i, its product rail and acc_i, while x still holds
; the value the trips read; nothing of the loop survives except the copied-out acc. The mirror runs BEFORE the
; controlled Ry (62/116 placement), so the Ry's flag is computed from the copy: f = acc > 2 lim, Ry(tr) on the fresh |0>
; rail r under f, f uncomputed, r and acc measured. n <= 0 takes the classical edge: acc is the seed rail (0.0), the
; same tail runs on it. The bound n is classical: no K.
source_filename = "float_accum_quantum_break.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @float_accum_break(double noundef %0, double noundef %1, ptr nocapture noundef readonly %2, i32 noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %7 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %7, double %1)    ; IR: %7 = cq_theta_f64(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: incoming 0.0 of phi %13 / %22  [acc before trip 0]
  %9 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: predicate of running trip 0 (always 1)
  %10 = icmp sgt i32 %3, 0    ; IR: %8 = icmp sgt i32 %3, 0  (classical)
  br i1 %10, label %12, label %11    ; IR: br i1 %8, label %9, label %21

11:
  call void @cqrt_not_i1(i32 %9)    ; IR: no trip: the seed predicate back to |0>
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  br label %43    ; IR: br label %21: %22 = 0.0 from %6, the seed rail

12:
  %13 = zext nneg i32 %3 to i64    ; IR: %10 = zext nneg i32 %3 to i64  (classical)
  br label %14

14:
  %15 = phi i64 [ 0, %12 ], [ %25, %14 ]    ; IR: %12 = phi i64 [ 0, %9 ], [ %18, %11 ]  (classical i)
  %16 = phi i32 [ %8, %12 ], [ %23, %14 ]    ; IR: %13 = phi double [ 0.0, %9 ], [ %16, %11 ]  [acc_{i-1}]
  %17 = phi i32 [ %9, %12 ], [ %24, %14 ]    ; IR: predicate a_{i-1}: this trip's body runs
  %18 = getelementptr inbounds double, ptr %2, i64 %15    ; IR: %14  (classical)
  %19 = load double, ptr %18, align 8    ; IR: %15 = load double  (classical c[i])
  %20 = call i32 @cq_template_fmul_f64_hl(i32 %7, double %19)    ; IR: %16 = llvm.fmuladd.f64(%15, %7, %13)  [unfused product, commuted: x * c[i]]
  %21 = call i32 @cq_template_fadd_f64(i32 %20, i32 %16)    ; IR: %16 = llvm.fmuladd.f64(%15, %7, %13)  [unfused sum + acc]
  %22 = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %21, double %4)    ; IR: %17 = fcmp ogt double %16, %4  [break condition e_i]
  %23 = call i32 @cq_template_select_f64(i32 %17, i32 %21, i32 %16)    ; IR: next %13 / %22 = a_{i-1} ? %16 : %13
  %24 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate a_i of the next trip
  call void @cqrt_not_i1(i32 %22)    ; IR: bracket: the loop continues when the break condition is false
  call void @cqrt_and_i1(i32 %17, i32 %22, i32 %24)    ; IR: %20 = select i1 %17, true, %19, quantum half: a_i = a_{i-1} & NOT e_i
  call void @cqrt_not_i1(i32 %22)    ; IR: bracket
  call void @cqrt_push(i32 %16)
  call void @cqrt_push(i32 %17)
  call void @cqrt_push(i32 %21)
  call void @cqrt_push(i32 %22)
  call void @cqrt_push(i32 %20)    ; IR: %16 [product rail, kept for the mirror]
  %25 = add nuw nsw i64 %15, 1    ; IR: %18 = add nuw nsw i64 %12, 1  (classical)
  %26 = icmp eq i64 %25, %13    ; IR: %19 = icmp eq i64 %18, %10  (classical half of %20)
  br i1 %26, label %27, label %14    ; IR: br i1 %20 on its classical half

27:
  %28 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: %22 = phi double [ %16, %11 ]  [copied-out acc]
  call void @cqrt_copy_f64(i32 %23, i32 %28)    ; IR: %22
  br label %29

29:
  %30 = phi i64 [ %15, %27 ], [ %40, %29 ]    ; IR: trip being undone, from the last down to 0
  %31 = phi i32 [ %23, %27 ], [ %37, %29 ]    ; IR: acc_j
  %32 = phi i32 [ %24, %27 ], [ %36, %29 ]    ; IR: a_j
  %33 = call i32 @cqrt_pop()    ; IR: that trip's product rail
  %34 = call i32 @cqrt_pop()
  %35 = call i32 @cqrt_pop()
  %36 = call i32 @cqrt_pop()
  %37 = call i32 @cqrt_pop()
  %38 = getelementptr inbounds double, ptr %2, i64 %30
  %39 = load double, ptr %38, align 8    ; IR: %15 of that trip (classical)
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket
  call void @cqrt_and_i1(i32 %36, i32 %34, i32 %32)    ; IR: uncompute a_j
  call void @cqrt_not_i1(i32 %34)    ; IR: bracket
  call void @cqrt_free(i32 %32)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %31, i32 %36, i32 %35, i32 %37)    ; IR: uncompute acc_j
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %34, i32 %35, double %4)    ; IR: uncompute %17
  call void @cqrt_free(i32 %34)    ; IR: release it (|0>)
  call void @cq_template_fadd_f64_unc(i32 %35, i32 %33, i32 %37)    ; IR: uncompute %16  [sum]
  call void @cqrt_free(i32 %35)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %33, i32 %7, double %39)    ; IR: uncompute %16  [product]
  call void @cqrt_free(i32 %33)    ; IR: release the product rail (|0>)
  %40 = add nsw i64 %30, -1
  %41 = icmp sge i64 %40, 0
  br i1 %41, label %29, label %42

42:
  call void @cqrt_not_i1(i32 %36)    ; IR: seed predicate back to |0>
  call void @cqrt_free(i32 %36)    ; IR: release the seed (|0>)
  call void @cqrt_free(i32 %37)    ; IR: release incoming 0.0 of phi %13 (never written; +0.0 is all-zero bits, |0>)
  br label %43

43:
  %44 = phi i32 [ %8, %11 ], [ %28, %42 ]    ; IR: %22 = phi double [ 0.0, %6 ], [ %16, %11 ]  [final acc rail]
  %45 = fmul double %4, 2.000000e+00    ; IR: %23 = fmul double %4, 2.0  (classical)
  %46 = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %44, double %45)    ; IR: %24 = fcmp ogt double %22, %23  [path predicate of block %25]
  %47 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %28 = phi i1 [ %26, %25 ], [ false, %21 ]  [register r, starts as false]
  call void @cqrt_ry_i1_controlled(i32 %46, i32 %47, double %5)    ; IR: block %25: %26 = cq_theta_i1(false, %5)  [Ry under the predicate]
  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %46, i32 %44, double %45)    ; IR: uncompute %24
  call void @cqrt_free(i32 %46)    ; IR: release the %24 rail (|0>)
  %48 = call i1 @cqrt_measure_i1(i32 %47)    ; IR: %29 = cq_measure_i1(%28)
  %49 = zext i1 %48 to i32    ; IR: %30  (classical)
  %50 = call double @cqrt_measure_f64(i32 %44)    ; IR: %31 = cq_measure_f64(%22)
  %51 = fcmp ogt double %50, 0.000000e+00    ; IR: %32  (classical)
  %52 = zext i1 %51 to i32    ; IR: %33  (classical)
  %53 = add nuw nsw i32 %52, %49    ; IR: %34  (classical)
  ret i32 %53    ; IR: ret i32 %34
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
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
