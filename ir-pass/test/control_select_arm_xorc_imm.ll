; control_select_arm_xorc_imm.ll — ACCEPT: a 4.4 select merge's CLASSICAL arm
; is a literal operand of `cqrt_xorc_<W>_controlled(flag, out, imm)`, never a
; rail; an all-zero classical arm emits nothing (bd test_C_libtooling-dm7f.81;
; owner ruling ruling-dm7f81-constant-arm-xorc-imm-fp-and-runtime-2026-10-15).
;
; BEFORE: every classical arm was loaded into its own never-freed rail,
; `%selop = cqrt_alloc_<W>(v)`, only to be the source of
; `cqrt_copy_<W>_controlled(f, %selop, out)` — dicke.c's `2*q4` (`select q4, 2,
; 0`) spent 64 qubits on the constants 2 and 0. R13: a classical operand is a
; literal, never `cqrt_alloc`'d.
;
; Analytic (R2): out is born |0>. The TRUE write fires on f=1 only, the FALSE
; write (X-bracketed) on f=0 only, so out = f ? a : b; a skipped all-zero write
; is XOR with 0 on its branch. A classical write is a CNOT from f onto each set
; bit of the literal (Bennett.jl @824458d src/lowering/operand.jl:31-41 NOTs on
; set bits, promoted to CNOTs under a control by src/controlled.jl:162-164).
;
; Clang -O1 source of every function but the last two:
; /scratchpad/f81/arms.c (recorded in bd dm7f.81).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

; SILENT-NOT: {{.}}

; No arm constant is ever a rail, in any function (the owner's CHECK-NOT), and
; the old materialized-source name is gone.
; NEG-NOT: @cqrt_alloc_{{[a-z0-9]+}}({{i[0-9]+|double}} {{2|7|-3|5|9|-1|4|-300|6|-5|8|-0.000000e\+00|31337}})
; NEG-NOT: %selop
; NEG-NOT: @cqrt_alloc_i32(i32 ptrtoint
; NEG-NOT: @cqrt_alloc_i32(i32 undef)

; ── 1. dicke's `2*a` = `select a, 2, 0`: ONE controlled xor of 2, nothing for
;       the 0 arm (no bracket), and the merge discharge REPLAYS the xor right
;       after its one reader (the measured `or`), strips the flag, then frees
;       the out rail provably |0> — all before the user's later Ry on `a`.
; CHECK-LABEL: define i32 @two_q(
; CHECK:      %[[A:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_ry_i1(i32 %{{[0-9a-zA-Z_.]+}}, double 6.000000e-01)
; CHECK-NEXT: %[[F:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[F]])
; CHECK-NEXT: %[[OUT:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[OUT]], i32 2)
; CHECK-NOT:  call void @cqrt_x(i32 %[[F]])
; CHECK:      call i32 @cq_template_or_i32(i32 %[[OUT]], i32 %{{[0-9a-zA-Z_.]+}})
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[OUT]], i32 2)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK:      call void @cqrt_ry_i1(i32 %[[A]], double -5.000000e-01)
; CHECK:      ret i32

; ── 2. Both arms nonzero: TRUE on f, FALSE inside the ¬f bracket only.
; CHECK-LABEL: define i32 @both_const(
; CHECK:      %[[F2:[0-9a-zA-Z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK-NEXT: %[[O2:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F2]], i32 %[[O2]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F2]], i32 %[[O2]], i32 -3)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]],
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[O2]])

; ── 3. TRUE arm zero: no TRUE write, the FALSE write fires on ¬f (POLARITY).
; CHECK-LABEL: define i32 @true_zero(
; CHECK:      %[[F3:[0-9a-zA-Z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK-NEXT: %[[O3:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F3]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F3]], i32 %[[O3]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F3]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F3]],

; ── 3b. The same TRUE-zero merge, DISCHARGED: the core OPENS with the ¬f
;       bracket, so the replay must take it too (MergeStreamPlan's backward
;       extension); x/xorc/x reversed is x/xorc/x, then the moved strip.
; CHECK-LABEL: define i32 @true_zero_disch(
; CHECK:      %[[F3B:[0-9a-zA-Z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK-NEXT: %[[O3B:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F3B]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F3B]], i32 %[[O3B]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F3B]])
; CHECK-NEXT: call i32 @cq_template_or_i32(i32 %[[O3B]],
; CHECK-NEXT: call void @cqrt_x(i32 %[[F3B]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F3B]], i32 %[[O3B]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F3B]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F3B]],
; CHECK-NEXT: call void @cqrt_free(i32 %[[F3B]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[O3B]])

; ── 4. One quantum arm (a controlled copy of the register) + one constant.
; CHECK-LABEL: define i32 @one_reg(
; CHECK:      %[[P4:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK:      %[[F4:[0-9a-zA-Z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK-NEXT: %[[O4:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F4]], i32 %[[P4]], i32 %[[O4]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F4]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F4]], i32 %[[O4]], i32 9)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F4]])

; ── 5. Sign-extended narrow / wide literals keep their width and value.
; CHECK-LABEL: define signext i8 @i8_arm(
; CHECK:      call void @cqrt_xorc_i8_controlled(i32 %[[F5:[0-9a-zA-Z_.]+]], i32 %[[O5:[0-9a-zA-Z_.]+]], i8 -1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F5]])
; CHECK-NEXT: call void @cqrt_xorc_i8_controlled(i32 %[[F5]], i32 %[[O5]], i8 4)
; CHECK-LABEL: define signext i16 @i16_arm(
; CHECK:      call void @cqrt_xorc_i16_controlled(i32 %[[F6:[0-9a-zA-Z_.]+]], i32 %[[O6:[0-9a-zA-Z_.]+]], i16 6)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F6]])
; CHECK-NEXT: call void @cqrt_xorc_i16_controlled(i32 %[[F6]], i32 %[[O6]], i16 -300)
; CHECK-LABEL: define i64 @i64_arm(
; CHECK:      call void @cqrt_xorc_i64_controlled(i32 %[[F7:[0-9a-zA-Z_.]+]], i32 %[[O7:[0-9a-zA-Z_.]+]], i64 -5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F7]])
; CHECK-NEXT: call void @cqrt_xorc_i64_controlled(i32 %[[F7]], i32 %[[O7]], i64 8)

; ── 6. fp: -0.0 is NOT all-zero bits, so it fires; +0.0 emits nothing.
; CHECK-LABEL: define double @fp_negzero(
; CHECK:      %[[O8:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_xorc_f64_controlled(i32 %[[F8:[0-9a-zA-Z_.]+]], i32 %[[O8]], double -0.000000e+00)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F8]],

; ── 7. A runtime CLASSICAL arm is a classical operand too (owner ruling Q2).
; CHECK-LABEL: define i32 @runtime_arm(
; CHECK:      call void @cqrt_xorc_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %{{[0-9a-zA-Z_.]+}}, i32 %1)
; CHECK-NOT:  call void @cqrt_x(

; ── 8. A constant EXPRESSION folded only at link time is still a literal.
; CHECK-LABEL: define i32 @constexpr_arm(
; CHECK:      call void @cqrt_xorc_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %{{[0-9a-zA-Z_.]+}}, i32 ptrtoint (ptr @g to i32))
; CHECK-NEXT: call void @cqrt_x(
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %{{[0-9a-zA-Z_.]+}}, i32 31337)

; ── 9. An `undef` arm is REFINED to zero: no gate (a literal undef would be read
;       per use, so a replayed write would not undo the forward one —
;       LiteralIntegrity guard 1). The other arm fires on ¬f.
; CHECK-LABEL: define i32 @undef_arm(
; CHECK:      %[[F9:[0-9a-zA-Z_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK-NEXT: %[[O9:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F9]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F9]], i32 %[[O9]], i32 4)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F9]])
; NEG-NOT: {{ undef[,)]}}

@g = global i32 0

define i32 @two_q(i32 noundef %0) {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01)
  %4 = select i1 %2, i32 2, i32 0
  %5 = zext i1 %3 to i32
  %6 = or disjoint i32 %4, %5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef -5.000000e-01)
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8)
  %10 = zext i1 %9 to i32
  %11 = add nsw i32 %7, %10
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3)
  %13 = zext i1 %12 to i32
  %14 = add nsw i32 %11, %13
  ret i32 %14
}

define i32 @both_const(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %3 = icmp sgt i32 %2, 5
  %4 = select i1 %3, i32 7, i32 -3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %5
}

define i32 @true_zero(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %3 = icmp sgt i32 %2, 5
  %4 = select i1 %3, i32 0, i32 5
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %5
}

define i32 @true_zero_disch(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 4.000000e-01)
  %5 = icmp sgt i32 %3, 5
  %6 = select i1 %5, i32 0, i32 5
  %7 = or i32 %6, %4
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %10 = add nsw i32 %8, %9
  ret i32 %10
}

define i32 @one_reg(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 4.000000e-01)
  %5 = icmp sgt i32 %3, 5
  %6 = select i1 %5, i32 %4, i32 9
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

define signext i8 @i8_arm(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %3 = icmp sgt i32 %2, 5
  %4 = select i1 %3, i8 -1, i8 4
  %5 = tail call signext i8 @cq_measure_si8(i8 noundef signext %4)
  ret i8 %5
}

define signext i16 @i16_arm(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %3 = icmp slt i32 %2, 6
  %4 = select i1 %3, i16 6, i16 -300
  %5 = tail call signext i16 @cq_measure_si16(i16 noundef signext %4)
  ret i16 %5
}

define i64 @i64_arm(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %3 = icmp sgt i32 %2, 5
  %4 = select i1 %3, i64 -5, i64 8
  %5 = tail call i64 @cq_measure_sll(i64 noundef %4)
  ret i64 %5
}

define double @fp_negzero(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %3 = icmp sgt i32 %2, 5
  %4 = select i1 %3, double -0.000000e+00, double 0.000000e+00
  %5 = tail call double @cq_measure_f64(double noundef %4)
  ret double %5
}

define i32 @runtime_arm(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %4 = icmp sgt i32 %3, 5
  %5 = select i1 %4, i32 %1, i32 0
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  ret i32 %6
}

define i32 @constexpr_arm(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %3 = icmp sgt i32 %2, 5
  %4 = select i1 %3, i32 ptrtoint (ptr @g to i32), i32 31337
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %5
}

define i32 @undef_arm(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01)
  %3 = icmp sgt i32 %2, 5
  %4 = select i1 %3, i32 undef, i32 4
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %5
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
declare signext i8 @cq_measure_si8(i8 noundef signext)
declare signext i16 @cq_measure_si16(i16 noundef signext)
declare i64 @cq_measure_sll(i64 noundef)
declare double @cq_measure_f64(double noundef)
