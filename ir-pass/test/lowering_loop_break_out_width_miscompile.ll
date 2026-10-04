; lowering_loop_break_out_width_miscompile.ll — ADVERSARIAL (bd
; test_C_libtooling-01po.3 audit). The break's escaping answer `%cq.brk.out` is an
; i32 HANDLE standing for a rail of the loop rail's width. Two width consumers read
; that width off the handle, and BOTH silently picked the laundered "i32" while the
; break rails were minted without a `taint.HandleWidth` record (MEASURED on the
; pre-fix build, opt rc 0, no diagnostic):
;
;   (1) `lowerOps`' up-front cast FROM-width capture (OpcodeLowering.cpp,
;       `taint.HandleWidth.lookup(Cast->getOperand(0))`, else `getSrcTy()` = the
;       laundered i32): an 8-bit break rail widened to `long long`
;           @sext_i8:  `(long long)q`             was cq_template_sext_i32_to_i64
;           @zext_u8:  `(unsigned long long)q`    was cq_template_zext_i32_to_i64
;       — a 32-bit source template on an 8-qubit rail.
;   (2) `qqSelectLeafWidth` (CompareLowering.cpp, via `logicalOperandWidth`), the
;       Q+Q leaf width of a tainted select condition: two break answers compared
;           @sel_two_i64:  `(q == q2) ? r + 3 : r ^ 6` over two i64 break rails
;           @sel_two_i8:   the same over two signed-char break rails
;       — both operands fell back to "i32", AGREED, and minted
;       `cq_template_icmp_eq_i32(%cq.brk.out, %cq.brk.out<N>)` (+ `_unc`) on 64-bit
;       / 8-bit rails.
; With the record each consumer reads the rail's real logical width.
;
; Each function is the clang -O1 IR of the C in its comment (attributes trimmed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WRONGW < %t.cqd0.ll
;
; WRONGW has only NOT directives (whole-output scan): no 32-bit-source cast and no
; i32 Q+Q compare may ever take a break answer as an operand in this module (every
; break rail here is 8- or 64-bit).
; WRONGW-NOT: cq_template_{{(sext|zext)}}_i32_to_i64(i32 %cq.brk.out
; WRONGW-NOT: cq_template_icmp_eq_i32{{(_unc)?}}({{(i32 %[a-zA-Z0-9_.]+, )?}}i32 %cq.brk.out

; signed char p = pseed, q = seed; cq_theta(&p,.5); cq_theta(&q,.25);
; for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
; return cq_measure((long long)q);
define i64 @sext_i8(i8 noundef signext %0, i8 noundef signext %1, i32 noundef %2) {
  %4 = tail call signext i8 @cq_theta_si8(i8 noundef signext %1, double noundef 5.000000e-01) #0
  %5 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 2.500000e-01) #0
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %15

7:
  %8 = phi i32 [ %12, %7 ], [ 0, %3 ]
  %9 = phi i8 [ %10, %7 ], [ %5, %3 ]
  %10 = xor i8 %9, 5
  %11 = icmp eq i8 %10, %4
  %12 = add nuw nsw i32 %8, 1
  %13 = icmp eq i32 %12, %2
  %14 = select i1 %11, i1 true, i1 %13
  br i1 %14, label %15, label %7

15:
  %16 = phi i8 [ %5, %3 ], [ %10, %7 ]
  %17 = sext i8 %16 to i64
  %18 = tail call i64 @cq_measure_sll(i64 noundef %17) #1
  ret i64 %18
}
; CHECK-LABEL: define i64 @sext_i8(
; CHECK:      %[[SO:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK:      cq.brk.tail:
; CHECK:      %[[SC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i8_to_i64(i32 %[[SO]])
; CHECK:      call i64 @cqrt_measure_i64(i32 %[[SC]])

; unsigned char p = pseed, q = seed; cq_theta(&p,.5); cq_theta(&q,.25);
; for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
; return cq_measure((unsigned long long)q);
define i64 @zext_u8(i8 noundef zeroext %0, i8 noundef zeroext %1, i32 noundef %2) {
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %1, double noundef 5.000000e-01) #0
  %5 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef 2.500000e-01) #0
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %15

7:
  %8 = phi i32 [ %12, %7 ], [ 0, %3 ]
  %9 = phi i8 [ %10, %7 ], [ %5, %3 ]
  %10 = xor i8 %9, 5
  %11 = icmp eq i8 %10, %4
  %12 = add nuw nsw i32 %8, 1
  %13 = icmp eq i32 %12, %2
  %14 = select i1 %11, i1 true, i1 %13
  br i1 %14, label %15, label %7

15:
  %16 = phi i8 [ %5, %3 ], [ %10, %7 ]
  %17 = zext i8 %16 to i64
  %18 = tail call i64 @cq_measure_ull(i64 noundef %17) #1
  ret i64 %18
}
; CHECK-LABEL: define i64 @zext_u8(
; CHECK:      %[[ZO:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK:      cq.brk.tail:
; CHECK:      %[[ZC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i8_to_i64(i32 %[[ZO]])
; CHECK:      call i64 @cqrt_measure_i64(i32 %[[ZC]])

; long long p = pseed, q = seed; cq_theta(&p,.5); cq_theta(&q,.25);
; for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
; long long p2 = p2s, q2 = s2; cq_theta(&p2,.5); cq_theta(&q2,.25);
; for (int j = 0; j < n; j++) { q2 = q2 ^ 3; if (q2 == p2) break; }
; long long r = rseed; cq_theta(&r,.75);
; return cq_measure((q == q2) ? r + 3 : r ^ 6);
define i64 @sel_two_i64(i64 noundef %0, i64 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i32 noundef %5) {
  %7 = tail call i64 @cq_theta_sll(i64 noundef %1, double noundef 5.000000e-01) #0
  %8 = tail call i64 @cq_theta_sll(i64 noundef %0, double noundef 2.500000e-01) #0
  %9 = icmp sgt i32 %5, 0
  br i1 %9, label %10, label %18

10:
  %11 = phi i64 [ %13, %10 ], [ %8, %6 ]
  %12 = phi i32 [ %15, %10 ], [ 0, %6 ]
  %13 = xor i64 %11, 5
  %14 = icmp eq i64 %13, %7
  %15 = add nuw nsw i32 %12, 1
  %16 = icmp eq i32 %15, %5
  %17 = select i1 %14, i1 true, i1 %16
  br i1 %17, label %18, label %10

18:
  %19 = phi i64 [ %8, %6 ], [ %13, %10 ]
  %20 = tail call i64 @cq_theta_sll(i64 noundef %3, double noundef 5.000000e-01) #0
  %21 = tail call i64 @cq_theta_sll(i64 noundef %2, double noundef 2.500000e-01) #0
  %22 = icmp sgt i32 %5, 0
  br i1 %22, label %23, label %31

23:
  %24 = phi i32 [ %28, %23 ], [ 0, %18 ]
  %25 = phi i64 [ %26, %23 ], [ %21, %18 ]
  %26 = xor i64 %25, 3
  %27 = icmp eq i64 %26, %20
  %28 = add nuw nsw i32 %24, 1
  %29 = icmp eq i32 %28, %5
  %30 = select i1 %27, i1 true, i1 %29
  br i1 %30, label %31, label %23

31:
  %32 = phi i64 [ %21, %18 ], [ %26, %23 ]
  %33 = tail call i64 @cq_theta_sll(i64 noundef %4, double noundef 7.500000e-01) #0
  %34 = icmp eq i64 %19, %32
  %35 = add nsw i64 %33, 3
  %36 = xor i64 %33, 6
  %37 = select i1 %34, i64 %35, i64 %36
  %38 = tail call i64 @cq_measure_sll(i64 noundef %37) #1
  ret i64 %38
}
; CHECK-LABEL: define i64 @sel_two_i64(
; CHECK:      %[[A1:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      %[[A2:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      %[[AF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i64(i32 %[[A1]], i32 %[[A2]])
; CHECK:      call void @cq_template_icmp_eq_i64_unc(i32 %[[AF]], i32 %[[A1]], i32 %[[A2]])
; CHECK:      ret i64

; The same as @sel_two_i64 over signed char rails, `int r`.
define i32 @sel_two_i8(i8 noundef signext %0, i8 noundef signext %1, i8 noundef signext %2, i8 noundef signext %3, i32 noundef %4, i32 noundef %5) {
  %7 = tail call signext i8 @cq_theta_si8(i8 noundef signext %1, double noundef 5.000000e-01) #0
  %8 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 2.500000e-01) #0
  %9 = icmp sgt i32 %5, 0
  br i1 %9, label %10, label %18

10:
  %11 = phi i8 [ %13, %10 ], [ %8, %6 ]
  %12 = phi i32 [ %15, %10 ], [ 0, %6 ]
  %13 = xor i8 %11, 5
  %14 = icmp eq i8 %13, %7
  %15 = add nuw nsw i32 %12, 1
  %16 = icmp eq i32 %15, %5
  %17 = select i1 %14, i1 true, i1 %16
  br i1 %17, label %18, label %10

18:
  %19 = phi i8 [ %8, %6 ], [ %13, %10 ]
  %20 = tail call signext i8 @cq_theta_si8(i8 noundef signext %3, double noundef 5.000000e-01) #0
  %21 = tail call signext i8 @cq_theta_si8(i8 noundef signext %2, double noundef 2.500000e-01) #0
  %22 = icmp sgt i32 %5, 0
  br i1 %22, label %23, label %31

23:
  %24 = phi i32 [ %28, %23 ], [ 0, %18 ]
  %25 = phi i8 [ %26, %23 ], [ %21, %18 ]
  %26 = xor i8 %25, 3
  %27 = icmp eq i8 %26, %20
  %28 = add nuw nsw i32 %24, 1
  %29 = icmp eq i32 %28, %5
  %30 = select i1 %27, i1 true, i1 %29
  br i1 %30, label %31, label %23

31:
  %32 = phi i8 [ %21, %18 ], [ %26, %23 ]
  %33 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 7.500000e-01) #0
  %34 = icmp eq i8 %19, %32
  %35 = add nsw i32 %33, 3
  %36 = xor i32 %33, 6
  %37 = select i1 %34, i32 %35, i32 %36
  %38 = tail call i32 @cq_measure_si32(i32 noundef %37) #1
  ret i32 %38
}
; CHECK-LABEL: define i32 @sel_two_i8(
; CHECK:      %[[B1:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK:      %[[B2:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK:      %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i8(i32 %[[B1]], i32 %[[B2]])
; CHECK:      call void @cq_template_icmp_eq_i8_unc(i32 %[[BF]], i32 %[[B1]], i32 %[[B2]])
; CHECK:      ret i32

declare i8 @cq_theta_si8(i8 noundef signext, double noundef)
declare i8 @cq_theta_ui8(i8 noundef zeroext, double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i64 @cq_theta_sll(i64 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare i64 @cq_measure_sll(i64 noundef)
declare i64 @cq_measure_ull(i64 noundef)

attributes #0 = { nomerge nounwind }
attributes #1 = { nounwind }
