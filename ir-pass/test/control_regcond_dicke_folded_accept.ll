; control_regcond_dicke_folded_accept.ll — ACCEPT (bd test_C_libtooling-dm7f.77,
; dm7f.51 step 2): the reporter's dicke.c (|D^4_2>, Bärtschi–Eidenbenz SCS_{4,2},
; SCS_{3,2}, SCS_{2,1}; ~/Desktop/alg_test/dicke), its printf replaced by a
; returned bit vector. Owner ruling owner-ruling-dicke-acceptance-folded-
; 2026-10-14: the acceptance is the clang -O1 FOLDED circuit (the classical
; |0011> prep folds SCS_{4,2}'s first CRy away and its CCRy into a plain Ry), with
; an analytic D^4_2 check; no gate-count target.
;
; Each piece is a general mechanism (one fixture each beside this one): R1 is the
; negated-guard substitution (`q3 = !q2`; control_regcond_negated_guard_accept.ll),
; R2 a compare over the claimed merge φ with a fresh register select root
; (control_cmp_merge_phi_covered_accept.ll), R3 the `_Bool` narrowing D1 plus the
; register condition D3 (control_regcond_boolstorage_scs21_accept.ll), `q3 ^= q1`
; in place onto q3's derived rail (E2′) and `q2 ^= q1` in place onto R1's merge φ
; with the measured `q4 = !q2` record settled (D2(b)), all angle cones hoisted.
;
; ANALYTIC (scratch tracecheck.py on the emitted trace, and ref.py on the
; UNFOLDED textbook circuit of dicke.c, gate for gate): the final state is
; (1/sqrt6) * sum over the six weight-2 strings |q1 q2 q3 q4> = 0011, 0101, 0110,
; 1001, 1010, 1100, every amplitude +0.408248290464, every other basis state 0;
; every leftover rail is in a fixed basis state (the literal-2 select operand and
; |0> scratch), so nothing is entangled with the register file. Main 27aaf1e1
; declined `condition predates a non-diagonal gate` (dicke.c:16:17).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 16) i32 @main()
; CHECK:       %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[Q2]], double %[[A1:[a-zA-Z0-9_.]+]])
; CHECK-NEXT:  %[[Q4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1_hl(i32 %[[Q2]], i1 true)
; CHECK:       call void @cqrt_ry_i1_controlled(i32 %[[Q4]], i32 %[[Q2]], double %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT:  %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[Q2]])
; CHECK-NEXT:  %[[Q3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1(i32 %[[Q2]], i32 %[[Q4]])
; CHECK-NEXT:  %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[Q3]], i32 %[[BF]])
; CHECK:       %[[CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NEXT:  %[[Q1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[CMP]], i32 %[[Q1]], double %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT:  call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[CMP]],
; CHECK:       call void @cqrt_cnot(i32 %[[Q3]], i32 %[[BF]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[BF]])
; CHECK:       call void @cq_template_zext_i1_to_i32_unc(i32 %[[Z]], i32 %[[Q2]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[Z]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[CMP]])
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[Q1]], i32 %[[Q3]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[Q1]], i32 %[[Q2]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[Q2]], i32 %[[Q1]], double %[[A1]])
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[Q1]], i32 %[[Q2]]), !cq.inplace.qq
; CHECK-NEXT:  call i1 @cqrt_measure_i1(i32 %[[Q1]])
; CHECK:       call i1 @cqrt_measure_i1(i32 %[[Q2]])
; CHECK:       call i1 @cqrt_measure_i1(i32 %[[Q3]])
; CHECK:       call i1 @cqrt_measure_i1(i32 %[[Q4]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 16) i32 @main() local_unnamed_addr {
  %1 = tail call double @llvm.acos.f64(double 0x3FE6A09E667F3BCD)
  %2 = fmul double %1, 2.000000e+00
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %2)
  %4 = xor i1 %3, true
  br i1 %3, label %9, label %5

5:                                                ; preds = %0
  %6 = tail call double @llvm.acos.f64(double 0x3FE279A74590331C)
  %7 = fmul double %6, 2.000000e+00
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef %7)
  br label %9

9:                                                ; preds = %5, %0
  %10 = phi i1 [ %8, %5 ], [ %3, %0 ]
  %11 = zext i1 %10 to i32
  %12 = xor i1 %10, %4
  %13 = select i1 %12, i32 2, i32 0
  %14 = or disjoint i32 %13, %11
  %15 = icmp eq i32 %14, 3
  br i1 %15, label %16, label %21

16:                                               ; preds = %9
  %17 = tail call double @llvm.acos.f64(double 0x3FEA20BD700C2C3E)
  %18 = fmul double %17, 2.000000e+00
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %18)
  %20 = zext i1 %19 to i8
  br label %21

21:                                               ; preds = %16, %9
  %22 = phi i8 [ %20, %16 ], [ 0, %9 ]
  %23 = zext i1 %10 to i8
  %24 = icmp ne i8 %22, %23
  br i1 %24, label %25, label %29

25:                                               ; preds = %21
  %26 = trunc nuw i8 %22 to i1
  %27 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %26, double noundef %2)
  %28 = zext i1 %27 to i8
  br label %29

29:                                               ; preds = %25, %21
  %30 = phi i8 [ %28, %25 ], [ %22, %21 ]
  %31 = zext i1 %12 to i8
  %32 = icmp ne i8 %22, %31
  %33 = trunc nuw i8 %30 to i1
  %34 = xor i1 %24, %33
  %35 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %33)
  %36 = zext i1 %35 to i32
  %37 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %34)
  %38 = select i1 %37, i32 2, i32 0
  %39 = or disjoint i32 %38, %36
  %40 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %32)
  %41 = select i1 %40, i32 4, i32 0
  %42 = or disjoint i32 %39, %41
  %43 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4)
  %44 = select i1 %43, i32 8, i32 0
  %45 = or disjoint i32 %42, %44
  ret i32 %45
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare double @llvm.acos.f64(double)

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
