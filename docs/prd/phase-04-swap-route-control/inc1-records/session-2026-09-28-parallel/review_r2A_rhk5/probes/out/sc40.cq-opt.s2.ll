; ModuleID = 'sc40.s1.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 7
  %h = call i32 @cqrt_alloc_i32(i32 %2)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
  %h_op79 = call i32 @cq_template_xor_i32(i32 %h, i32 %h_op)
  %h_cmp39 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op79, i32 10)
  call void @cqrt_rz_i1(i32 %h_cmp39, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp39, i32 %h_op79, i32 10)
  call void @cqrt_free(i32 %h_cmp39)
  %3 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op) #5
  call void @cq_template_xor_i32_unc(i32 %h_op79, i32 %h, i32 %h_op)
  call void @cqrt_free(i32 %h_op79)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
  %m = call i32 @cqrt_measure_i32(i32 %3)
  %m158 = call i32 @cqrt_measure_i32(i32 %h)
  %4 = add nsw i32 %0, 1
  %5 = and i32 %4, 7
  %h40 = call i32 @cqrt_alloc_i32(i32 %5)
  call void @cqrt_ry_i32(i32 %h40, double 5.000000e-01)
  %h_op80 = call i32 @cq_template_mul_i32_hl(i32 %h40, i32 3)
  %h_op81 = call i32 @cq_template_xor_i32(i32 %h40, i32 %h_op80)
  %h_cmp38 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op81, i32 11)
  call void @cqrt_rz_i1(i32 %h_cmp38, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp38, i32 %h_op81, i32 11)
  call void @cqrt_free(i32 %h_cmp38)
  %6 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op80) #5
  call void @cq_template_xor_i32_unc(i32 %h_op81, i32 %h40, i32 %h_op80)
  call void @cqrt_free(i32 %h_op81)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op80, i32 %h40, i32 3)
  call void @cqrt_free(i32 %h_op80)
  call void @cqrt_ry_i32(i32 %h40, double 0x3FE6666666666666)
  %m159 = call i32 @cqrt_measure_i32(i32 %6)
  %m160 = call i32 @cqrt_measure_i32(i32 %h40)
  %7 = add nsw i32 %0, 2
  %8 = and i32 %7, 7
  %h41 = call i32 @cqrt_alloc_i32(i32 %8)
  call void @cqrt_ry_i32(i32 %h41, double 5.000000e-01)
  %h_op82 = call i32 @cq_template_mul_i32_hl(i32 %h41, i32 3)
  %h_op83 = call i32 @cq_template_xor_i32(i32 %h41, i32 %h_op82)
  %h_cmp37 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op83, i32 12)
  call void @cqrt_rz_i1(i32 %h_cmp37, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp37, i32 %h_op83, i32 12)
  call void @cqrt_free(i32 %h_cmp37)
  %9 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op82) #5
  call void @cq_template_xor_i32_unc(i32 %h_op83, i32 %h41, i32 %h_op82)
  call void @cqrt_free(i32 %h_op83)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op82, i32 %h41, i32 3)
  call void @cqrt_free(i32 %h_op82)
  call void @cqrt_ry_i32(i32 %h41, double 0x3FE6666666666666)
  %m161 = call i32 @cqrt_measure_i32(i32 %9)
  %m162 = call i32 @cqrt_measure_i32(i32 %h41)
  %10 = add nsw i32 %0, 3
  %11 = and i32 %10, 7
  %h42 = call i32 @cqrt_alloc_i32(i32 %11)
  call void @cqrt_ry_i32(i32 %h42, double 5.000000e-01)
  %h_op84 = call i32 @cq_template_mul_i32_hl(i32 %h42, i32 3)
  %h_op85 = call i32 @cq_template_xor_i32(i32 %h42, i32 %h_op84)
  %h_cmp36 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op85, i32 13)
  call void @cqrt_rz_i1(i32 %h_cmp36, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp36, i32 %h_op85, i32 13)
  call void @cqrt_free(i32 %h_cmp36)
  %12 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op84) #5
  call void @cq_template_xor_i32_unc(i32 %h_op85, i32 %h42, i32 %h_op84)
  call void @cqrt_free(i32 %h_op85)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op84, i32 %h42, i32 3)
  call void @cqrt_free(i32 %h_op84)
  call void @cqrt_ry_i32(i32 %h42, double 0x3FE6666666666666)
  %m163 = call i32 @cqrt_measure_i32(i32 %12)
  %m164 = call i32 @cqrt_measure_i32(i32 %h42)
  %13 = xor i32 %2, 4
  %h43 = call i32 @cqrt_alloc_i32(i32 %13)
  call void @cqrt_ry_i32(i32 %h43, double 5.000000e-01)
  %h_op86 = call i32 @cq_template_mul_i32_hl(i32 %h43, i32 3)
  %h_op87 = call i32 @cq_template_xor_i32(i32 %h43, i32 %h_op86)
  %h_cmp35 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op87, i32 14)
  call void @cqrt_rz_i1(i32 %h_cmp35, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp35, i32 %h_op87, i32 14)
  call void @cqrt_free(i32 %h_cmp35)
  %14 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op86) #5
  call void @cq_template_xor_i32_unc(i32 %h_op87, i32 %h43, i32 %h_op86)
  call void @cqrt_free(i32 %h_op87)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op86, i32 %h43, i32 3)
  call void @cqrt_free(i32 %h_op86)
  call void @cqrt_ry_i32(i32 %h43, double 0x3FE6666666666666)
  %m165 = call i32 @cqrt_measure_i32(i32 %14)
  %m166 = call i32 @cqrt_measure_i32(i32 %h43)
  %15 = add nsw i32 %0, 5
  %16 = and i32 %15, 7
  %h44 = call i32 @cqrt_alloc_i32(i32 %16)
  call void @cqrt_ry_i32(i32 %h44, double 5.000000e-01)
  %h_op88 = call i32 @cq_template_mul_i32_hl(i32 %h44, i32 3)
  %h_op89 = call i32 @cq_template_xor_i32(i32 %h44, i32 %h_op88)
  %h_cmp34 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op89, i32 15)
  call void @cqrt_rz_i1(i32 %h_cmp34, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp34, i32 %h_op89, i32 15)
  call void @cqrt_free(i32 %h_cmp34)
  %17 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op88) #5
  call void @cq_template_xor_i32_unc(i32 %h_op89, i32 %h44, i32 %h_op88)
  call void @cqrt_free(i32 %h_op89)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op88, i32 %h44, i32 3)
  call void @cqrt_free(i32 %h_op88)
  call void @cqrt_ry_i32(i32 %h44, double 0x3FE6666666666666)
  %m167 = call i32 @cqrt_measure_i32(i32 %17)
  %m168 = call i32 @cqrt_measure_i32(i32 %h44)
  %18 = add nsw i32 %0, 6
  %19 = and i32 %18, 7
  %h45 = call i32 @cqrt_alloc_i32(i32 %19)
  call void @cqrt_ry_i32(i32 %h45, double 5.000000e-01)
  %h_op90 = call i32 @cq_template_mul_i32_hl(i32 %h45, i32 3)
  %h_op91 = call i32 @cq_template_xor_i32(i32 %h45, i32 %h_op90)
  %h_cmp33 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op91, i32 16)
  call void @cqrt_rz_i1(i32 %h_cmp33, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp33, i32 %h_op91, i32 16)
  call void @cqrt_free(i32 %h_cmp33)
  %20 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op90) #5
  call void @cq_template_xor_i32_unc(i32 %h_op91, i32 %h45, i32 %h_op90)
  call void @cqrt_free(i32 %h_op91)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op90, i32 %h45, i32 3)
  call void @cqrt_free(i32 %h_op90)
  call void @cqrt_ry_i32(i32 %h45, double 0x3FE6666666666666)
  %m169 = call i32 @cqrt_measure_i32(i32 %20)
  %m170 = call i32 @cqrt_measure_i32(i32 %h45)
  %21 = add nsw i32 %0, 7
  %22 = and i32 %21, 7
  %h46 = call i32 @cqrt_alloc_i32(i32 %22)
  call void @cqrt_ry_i32(i32 %h46, double 5.000000e-01)
  %h_op92 = call i32 @cq_template_mul_i32_hl(i32 %h46, i32 3)
  %h_op93 = call i32 @cq_template_xor_i32(i32 %h46, i32 %h_op92)
  %h_cmp32 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op93, i32 17)
  call void @cqrt_rz_i1(i32 %h_cmp32, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp32, i32 %h_op93, i32 17)
  call void @cqrt_free(i32 %h_cmp32)
  %23 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op92) #5
  call void @cq_template_xor_i32_unc(i32 %h_op93, i32 %h46, i32 %h_op92)
  call void @cqrt_free(i32 %h_op93)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op92, i32 %h46, i32 3)
  call void @cqrt_free(i32 %h_op92)
  call void @cqrt_ry_i32(i32 %h46, double 0x3FE6666666666666)
  %m171 = call i32 @cqrt_measure_i32(i32 %23)
  %m172 = call i32 @cqrt_measure_i32(i32 %h46)
  %h47 = call i32 @cqrt_alloc_i32(i32 %2)
  call void @cqrt_ry_i32(i32 %h47, double 5.000000e-01)
  %h_op94 = call i32 @cq_template_mul_i32_hl(i32 %h47, i32 3)
  %h_op95 = call i32 @cq_template_xor_i32(i32 %h47, i32 %h_op94)
  %h_cmp31 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op95, i32 18)
  call void @cqrt_rz_i1(i32 %h_cmp31, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp31, i32 %h_op95, i32 18)
  call void @cqrt_free(i32 %h_cmp31)
  %24 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op94) #5
  call void @cq_template_xor_i32_unc(i32 %h_op95, i32 %h47, i32 %h_op94)
  call void @cqrt_free(i32 %h_op95)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op94, i32 %h47, i32 3)
  call void @cqrt_free(i32 %h_op94)
  call void @cqrt_ry_i32(i32 %h47, double 0x3FE6666666666666)
  %m173 = call i32 @cqrt_measure_i32(i32 %24)
  %m174 = call i32 @cqrt_measure_i32(i32 %h47)
  %h48 = call i32 @cqrt_alloc_i32(i32 %5)
  call void @cqrt_ry_i32(i32 %h48, double 5.000000e-01)
  %h_op96 = call i32 @cq_template_mul_i32_hl(i32 %h48, i32 3)
  %h_op97 = call i32 @cq_template_xor_i32(i32 %h48, i32 %h_op96)
  %h_cmp30 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op97, i32 19)
  call void @cqrt_rz_i1(i32 %h_cmp30, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp30, i32 %h_op97, i32 19)
  call void @cqrt_free(i32 %h_cmp30)
  %25 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op96) #5
  call void @cq_template_xor_i32_unc(i32 %h_op97, i32 %h48, i32 %h_op96)
  call void @cqrt_free(i32 %h_op97)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op96, i32 %h48, i32 3)
  call void @cqrt_free(i32 %h_op96)
  call void @cqrt_ry_i32(i32 %h48, double 0x3FE6666666666666)
  %m175 = call i32 @cqrt_measure_i32(i32 %25)
  %m176 = call i32 @cqrt_measure_i32(i32 %h48)
  %h49 = call i32 @cqrt_alloc_i32(i32 %8)
  call void @cqrt_ry_i32(i32 %h49, double 5.000000e-01)
  %h_op98 = call i32 @cq_template_mul_i32_hl(i32 %h49, i32 3)
  %h_op99 = call i32 @cq_template_xor_i32(i32 %h49, i32 %h_op98)
  %h_cmp29 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op99, i32 20)
  call void @cqrt_rz_i1(i32 %h_cmp29, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp29, i32 %h_op99, i32 20)
  call void @cqrt_free(i32 %h_cmp29)
  %26 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op98) #5
  call void @cq_template_xor_i32_unc(i32 %h_op99, i32 %h49, i32 %h_op98)
  call void @cqrt_free(i32 %h_op99)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op98, i32 %h49, i32 3)
  call void @cqrt_free(i32 %h_op98)
  call void @cqrt_ry_i32(i32 %h49, double 0x3FE6666666666666)
  %m177 = call i32 @cqrt_measure_i32(i32 %26)
  %m178 = call i32 @cqrt_measure_i32(i32 %h49)
  %h50 = call i32 @cqrt_alloc_i32(i32 %11)
  call void @cqrt_ry_i32(i32 %h50, double 5.000000e-01)
  %h_op100 = call i32 @cq_template_mul_i32_hl(i32 %h50, i32 3)
  %h_op101 = call i32 @cq_template_xor_i32(i32 %h50, i32 %h_op100)
  %h_cmp28 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op101, i32 21)
  call void @cqrt_rz_i1(i32 %h_cmp28, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp28, i32 %h_op101, i32 21)
  call void @cqrt_free(i32 %h_cmp28)
  %27 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op100) #5
  call void @cq_template_xor_i32_unc(i32 %h_op101, i32 %h50, i32 %h_op100)
  call void @cqrt_free(i32 %h_op101)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op100, i32 %h50, i32 3)
  call void @cqrt_free(i32 %h_op100)
  call void @cqrt_ry_i32(i32 %h50, double 0x3FE6666666666666)
  %m179 = call i32 @cqrt_measure_i32(i32 %27)
  %m180 = call i32 @cqrt_measure_i32(i32 %h50)
  %h51 = call i32 @cqrt_alloc_i32(i32 %13)
  call void @cqrt_ry_i32(i32 %h51, double 5.000000e-01)
  %h_op102 = call i32 @cq_template_mul_i32_hl(i32 %h51, i32 3)
  %h_op103 = call i32 @cq_template_xor_i32(i32 %h51, i32 %h_op102)
  %h_cmp27 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op103, i32 22)
  call void @cqrt_rz_i1(i32 %h_cmp27, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp27, i32 %h_op103, i32 22)
  call void @cqrt_free(i32 %h_cmp27)
  %28 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op102) #5
  call void @cq_template_xor_i32_unc(i32 %h_op103, i32 %h51, i32 %h_op102)
  call void @cqrt_free(i32 %h_op103)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op102, i32 %h51, i32 3)
  call void @cqrt_free(i32 %h_op102)
  call void @cqrt_ry_i32(i32 %h51, double 0x3FE6666666666666)
  %m181 = call i32 @cqrt_measure_i32(i32 %28)
  %m182 = call i32 @cqrt_measure_i32(i32 %h51)
  %h52 = call i32 @cqrt_alloc_i32(i32 %16)
  call void @cqrt_ry_i32(i32 %h52, double 5.000000e-01)
  %h_op104 = call i32 @cq_template_mul_i32_hl(i32 %h52, i32 3)
  %h_op105 = call i32 @cq_template_xor_i32(i32 %h52, i32 %h_op104)
  %h_cmp26 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op105, i32 23)
  call void @cqrt_rz_i1(i32 %h_cmp26, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp26, i32 %h_op105, i32 23)
  call void @cqrt_free(i32 %h_cmp26)
  %29 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op104) #5
  call void @cq_template_xor_i32_unc(i32 %h_op105, i32 %h52, i32 %h_op104)
  call void @cqrt_free(i32 %h_op105)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op104, i32 %h52, i32 3)
  call void @cqrt_free(i32 %h_op104)
  call void @cqrt_ry_i32(i32 %h52, double 0x3FE6666666666666)
  %m183 = call i32 @cqrt_measure_i32(i32 %29)
  %m184 = call i32 @cqrt_measure_i32(i32 %h52)
  %h53 = call i32 @cqrt_alloc_i32(i32 %19)
  call void @cqrt_ry_i32(i32 %h53, double 5.000000e-01)
  %h_op106 = call i32 @cq_template_mul_i32_hl(i32 %h53, i32 3)
  %h_op107 = call i32 @cq_template_xor_i32(i32 %h53, i32 %h_op106)
  %h_cmp25 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op107, i32 24)
  call void @cqrt_rz_i1(i32 %h_cmp25, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp25, i32 %h_op107, i32 24)
  call void @cqrt_free(i32 %h_cmp25)
  %30 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op106) #5
  call void @cq_template_xor_i32_unc(i32 %h_op107, i32 %h53, i32 %h_op106)
  call void @cqrt_free(i32 %h_op107)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op106, i32 %h53, i32 3)
  call void @cqrt_free(i32 %h_op106)
  call void @cqrt_ry_i32(i32 %h53, double 0x3FE6666666666666)
  %m185 = call i32 @cqrt_measure_i32(i32 %30)
  %m186 = call i32 @cqrt_measure_i32(i32 %h53)
  %h54 = call i32 @cqrt_alloc_i32(i32 %22)
  call void @cqrt_ry_i32(i32 %h54, double 5.000000e-01)
  %h_op108 = call i32 @cq_template_mul_i32_hl(i32 %h54, i32 3)
  %h_op109 = call i32 @cq_template_xor_i32(i32 %h54, i32 %h_op108)
  %h_cmp24 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op109, i32 25)
  call void @cqrt_rz_i1(i32 %h_cmp24, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp24, i32 %h_op109, i32 25)
  call void @cqrt_free(i32 %h_cmp24)
  %31 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op108) #5
  call void @cq_template_xor_i32_unc(i32 %h_op109, i32 %h54, i32 %h_op108)
  call void @cqrt_free(i32 %h_op109)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op108, i32 %h54, i32 3)
  call void @cqrt_free(i32 %h_op108)
  call void @cqrt_ry_i32(i32 %h54, double 0x3FE6666666666666)
  %m187 = call i32 @cqrt_measure_i32(i32 %31)
  %m188 = call i32 @cqrt_measure_i32(i32 %h54)
  %h55 = call i32 @cqrt_alloc_i32(i32 %2)
  call void @cqrt_ry_i32(i32 %h55, double 5.000000e-01)
  %h_op110 = call i32 @cq_template_mul_i32_hl(i32 %h55, i32 3)
  %h_op111 = call i32 @cq_template_xor_i32(i32 %h55, i32 %h_op110)
  %h_cmp23 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op111, i32 26)
  call void @cqrt_rz_i1(i32 %h_cmp23, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp23, i32 %h_op111, i32 26)
  call void @cqrt_free(i32 %h_cmp23)
  %32 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op110) #5
  call void @cq_template_xor_i32_unc(i32 %h_op111, i32 %h55, i32 %h_op110)
  call void @cqrt_free(i32 %h_op111)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op110, i32 %h55, i32 3)
  call void @cqrt_free(i32 %h_op110)
  call void @cqrt_ry_i32(i32 %h55, double 0x3FE6666666666666)
  %m189 = call i32 @cqrt_measure_i32(i32 %32)
  %m190 = call i32 @cqrt_measure_i32(i32 %h55)
  %h56 = call i32 @cqrt_alloc_i32(i32 %5)
  call void @cqrt_ry_i32(i32 %h56, double 5.000000e-01)
  %h_op112 = call i32 @cq_template_mul_i32_hl(i32 %h56, i32 3)
  %h_op113 = call i32 @cq_template_xor_i32(i32 %h56, i32 %h_op112)
  %h_cmp22 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op113, i32 27)
  call void @cqrt_rz_i1(i32 %h_cmp22, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp22, i32 %h_op113, i32 27)
  call void @cqrt_free(i32 %h_cmp22)
  %33 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op112) #5
  call void @cq_template_xor_i32_unc(i32 %h_op113, i32 %h56, i32 %h_op112)
  call void @cqrt_free(i32 %h_op113)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op112, i32 %h56, i32 3)
  call void @cqrt_free(i32 %h_op112)
  call void @cqrt_ry_i32(i32 %h56, double 0x3FE6666666666666)
  %m191 = call i32 @cqrt_measure_i32(i32 %33)
  %m192 = call i32 @cqrt_measure_i32(i32 %h56)
  %h57 = call i32 @cqrt_alloc_i32(i32 %8)
  call void @cqrt_ry_i32(i32 %h57, double 5.000000e-01)
  %h_op114 = call i32 @cq_template_mul_i32_hl(i32 %h57, i32 3)
  %h_op115 = call i32 @cq_template_xor_i32(i32 %h57, i32 %h_op114)
  %h_cmp21 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op115, i32 28)
  call void @cqrt_rz_i1(i32 %h_cmp21, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp21, i32 %h_op115, i32 28)
  call void @cqrt_free(i32 %h_cmp21)
  %34 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op114) #5
  call void @cq_template_xor_i32_unc(i32 %h_op115, i32 %h57, i32 %h_op114)
  call void @cqrt_free(i32 %h_op115)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op114, i32 %h57, i32 3)
  call void @cqrt_free(i32 %h_op114)
  call void @cqrt_ry_i32(i32 %h57, double 0x3FE6666666666666)
  %m193 = call i32 @cqrt_measure_i32(i32 %34)
  %m194 = call i32 @cqrt_measure_i32(i32 %h57)
  %h58 = call i32 @cqrt_alloc_i32(i32 %11)
  call void @cqrt_ry_i32(i32 %h58, double 5.000000e-01)
  %h_op116 = call i32 @cq_template_mul_i32_hl(i32 %h58, i32 3)
  %h_op117 = call i32 @cq_template_xor_i32(i32 %h58, i32 %h_op116)
  %h_cmp20 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op117, i32 29)
  call void @cqrt_rz_i1(i32 %h_cmp20, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp20, i32 %h_op117, i32 29)
  call void @cqrt_free(i32 %h_cmp20)
  %35 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op116) #5
  call void @cq_template_xor_i32_unc(i32 %h_op117, i32 %h58, i32 %h_op116)
  call void @cqrt_free(i32 %h_op117)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op116, i32 %h58, i32 3)
  call void @cqrt_free(i32 %h_op116)
  call void @cqrt_ry_i32(i32 %h58, double 0x3FE6666666666666)
  %m195 = call i32 @cqrt_measure_i32(i32 %35)
  %m196 = call i32 @cqrt_measure_i32(i32 %h58)
  %h59 = call i32 @cqrt_alloc_i32(i32 %13)
  call void @cqrt_ry_i32(i32 %h59, double 5.000000e-01)
  %h_op118 = call i32 @cq_template_mul_i32_hl(i32 %h59, i32 3)
  %h_op119 = call i32 @cq_template_xor_i32(i32 %h59, i32 %h_op118)
  %h_cmp19 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op119, i32 30)
  call void @cqrt_rz_i1(i32 %h_cmp19, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp19, i32 %h_op119, i32 30)
  call void @cqrt_free(i32 %h_cmp19)
  %36 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op118) #5
  call void @cq_template_xor_i32_unc(i32 %h_op119, i32 %h59, i32 %h_op118)
  call void @cqrt_free(i32 %h_op119)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op118, i32 %h59, i32 3)
  call void @cqrt_free(i32 %h_op118)
  call void @cqrt_ry_i32(i32 %h59, double 0x3FE6666666666666)
  %m197 = call i32 @cqrt_measure_i32(i32 %36)
  %m198 = call i32 @cqrt_measure_i32(i32 %h59)
  %h60 = call i32 @cqrt_alloc_i32(i32 %16)
  call void @cqrt_ry_i32(i32 %h60, double 5.000000e-01)
  %h_op120 = call i32 @cq_template_mul_i32_hl(i32 %h60, i32 3)
  %h_op121 = call i32 @cq_template_xor_i32(i32 %h60, i32 %h_op120)
  %h_cmp18 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op121, i32 31)
  call void @cqrt_rz_i1(i32 %h_cmp18, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp18, i32 %h_op121, i32 31)
  call void @cqrt_free(i32 %h_cmp18)
  %37 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op120) #5
  call void @cq_template_xor_i32_unc(i32 %h_op121, i32 %h60, i32 %h_op120)
  call void @cqrt_free(i32 %h_op121)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op120, i32 %h60, i32 3)
  call void @cqrt_free(i32 %h_op120)
  call void @cqrt_ry_i32(i32 %h60, double 0x3FE6666666666666)
  %m199 = call i32 @cqrt_measure_i32(i32 %37)
  %m200 = call i32 @cqrt_measure_i32(i32 %h60)
  %h61 = call i32 @cqrt_alloc_i32(i32 %19)
  call void @cqrt_ry_i32(i32 %h61, double 5.000000e-01)
  %h_op122 = call i32 @cq_template_mul_i32_hl(i32 %h61, i32 3)
  %h_op123 = call i32 @cq_template_xor_i32(i32 %h61, i32 %h_op122)
  %h_cmp17 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op123, i32 32)
  call void @cqrt_rz_i1(i32 %h_cmp17, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp17, i32 %h_op123, i32 32)
  call void @cqrt_free(i32 %h_cmp17)
  %38 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op122) #5
  call void @cq_template_xor_i32_unc(i32 %h_op123, i32 %h61, i32 %h_op122)
  call void @cqrt_free(i32 %h_op123)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op122, i32 %h61, i32 3)
  call void @cqrt_free(i32 %h_op122)
  call void @cqrt_ry_i32(i32 %h61, double 0x3FE6666666666666)
  %m201 = call i32 @cqrt_measure_i32(i32 %38)
  %m202 = call i32 @cqrt_measure_i32(i32 %h61)
  %h62 = call i32 @cqrt_alloc_i32(i32 %22)
  call void @cqrt_ry_i32(i32 %h62, double 5.000000e-01)
  %h_op124 = call i32 @cq_template_mul_i32_hl(i32 %h62, i32 3)
  %h_op125 = call i32 @cq_template_xor_i32(i32 %h62, i32 %h_op124)
  %h_cmp16 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op125, i32 33)
  call void @cqrt_rz_i1(i32 %h_cmp16, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp16, i32 %h_op125, i32 33)
  call void @cqrt_free(i32 %h_cmp16)
  %39 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op124) #5
  call void @cq_template_xor_i32_unc(i32 %h_op125, i32 %h62, i32 %h_op124)
  call void @cqrt_free(i32 %h_op125)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op124, i32 %h62, i32 3)
  call void @cqrt_free(i32 %h_op124)
  call void @cqrt_ry_i32(i32 %h62, double 0x3FE6666666666666)
  %m203 = call i32 @cqrt_measure_i32(i32 %39)
  %m204 = call i32 @cqrt_measure_i32(i32 %h62)
  %h63 = call i32 @cqrt_alloc_i32(i32 %2)
  call void @cqrt_ry_i32(i32 %h63, double 5.000000e-01)
  %h_op126 = call i32 @cq_template_mul_i32_hl(i32 %h63, i32 3)
  %h_op127 = call i32 @cq_template_xor_i32(i32 %h63, i32 %h_op126)
  %h_cmp15 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op127, i32 34)
  call void @cqrt_rz_i1(i32 %h_cmp15, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp15, i32 %h_op127, i32 34)
  call void @cqrt_free(i32 %h_cmp15)
  %40 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op126) #5
  call void @cq_template_xor_i32_unc(i32 %h_op127, i32 %h63, i32 %h_op126)
  call void @cqrt_free(i32 %h_op127)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op126, i32 %h63, i32 3)
  call void @cqrt_free(i32 %h_op126)
  call void @cqrt_ry_i32(i32 %h63, double 0x3FE6666666666666)
  %m205 = call i32 @cqrt_measure_i32(i32 %40)
  %m206 = call i32 @cqrt_measure_i32(i32 %h63)
  %h64 = call i32 @cqrt_alloc_i32(i32 %5)
  call void @cqrt_ry_i32(i32 %h64, double 5.000000e-01)
  %h_op128 = call i32 @cq_template_mul_i32_hl(i32 %h64, i32 3)
  %h_op129 = call i32 @cq_template_xor_i32(i32 %h64, i32 %h_op128)
  %h_cmp14 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op129, i32 35)
  call void @cqrt_rz_i1(i32 %h_cmp14, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp14, i32 %h_op129, i32 35)
  call void @cqrt_free(i32 %h_cmp14)
  %41 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op128) #5
  call void @cq_template_xor_i32_unc(i32 %h_op129, i32 %h64, i32 %h_op128)
  call void @cqrt_free(i32 %h_op129)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op128, i32 %h64, i32 3)
  call void @cqrt_free(i32 %h_op128)
  call void @cqrt_ry_i32(i32 %h64, double 0x3FE6666666666666)
  %m207 = call i32 @cqrt_measure_i32(i32 %41)
  %m208 = call i32 @cqrt_measure_i32(i32 %h64)
  %h65 = call i32 @cqrt_alloc_i32(i32 %8)
  call void @cqrt_ry_i32(i32 %h65, double 5.000000e-01)
  %h_op130 = call i32 @cq_template_mul_i32_hl(i32 %h65, i32 3)
  %h_op131 = call i32 @cq_template_xor_i32(i32 %h65, i32 %h_op130)
  %h_cmp13 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op131, i32 36)
  call void @cqrt_rz_i1(i32 %h_cmp13, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp13, i32 %h_op131, i32 36)
  call void @cqrt_free(i32 %h_cmp13)
  %42 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op130) #5
  call void @cq_template_xor_i32_unc(i32 %h_op131, i32 %h65, i32 %h_op130)
  call void @cqrt_free(i32 %h_op131)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op130, i32 %h65, i32 3)
  call void @cqrt_free(i32 %h_op130)
  call void @cqrt_ry_i32(i32 %h65, double 0x3FE6666666666666)
  %m209 = call i32 @cqrt_measure_i32(i32 %42)
  %m210 = call i32 @cqrt_measure_i32(i32 %h65)
  %h66 = call i32 @cqrt_alloc_i32(i32 %11)
  call void @cqrt_ry_i32(i32 %h66, double 5.000000e-01)
  %h_op132 = call i32 @cq_template_mul_i32_hl(i32 %h66, i32 3)
  %h_op133 = call i32 @cq_template_xor_i32(i32 %h66, i32 %h_op132)
  %h_cmp12 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op133, i32 37)
  call void @cqrt_rz_i1(i32 %h_cmp12, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp12, i32 %h_op133, i32 37)
  call void @cqrt_free(i32 %h_cmp12)
  %43 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op132) #5
  call void @cq_template_xor_i32_unc(i32 %h_op133, i32 %h66, i32 %h_op132)
  call void @cqrt_free(i32 %h_op133)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op132, i32 %h66, i32 3)
  call void @cqrt_free(i32 %h_op132)
  call void @cqrt_ry_i32(i32 %h66, double 0x3FE6666666666666)
  %m211 = call i32 @cqrt_measure_i32(i32 %43)
  %m212 = call i32 @cqrt_measure_i32(i32 %h66)
  %h67 = call i32 @cqrt_alloc_i32(i32 %13)
  call void @cqrt_ry_i32(i32 %h67, double 5.000000e-01)
  %h_op134 = call i32 @cq_template_mul_i32_hl(i32 %h67, i32 3)
  %h_op135 = call i32 @cq_template_xor_i32(i32 %h67, i32 %h_op134)
  %h_cmp11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op135, i32 38)
  call void @cqrt_rz_i1(i32 %h_cmp11, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp11, i32 %h_op135, i32 38)
  call void @cqrt_free(i32 %h_cmp11)
  %44 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op134) #5
  call void @cq_template_xor_i32_unc(i32 %h_op135, i32 %h67, i32 %h_op134)
  call void @cqrt_free(i32 %h_op135)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op134, i32 %h67, i32 3)
  call void @cqrt_free(i32 %h_op134)
  call void @cqrt_ry_i32(i32 %h67, double 0x3FE6666666666666)
  %m213 = call i32 @cqrt_measure_i32(i32 %44)
  %m214 = call i32 @cqrt_measure_i32(i32 %h67)
  %h68 = call i32 @cqrt_alloc_i32(i32 %16)
  call void @cqrt_ry_i32(i32 %h68, double 5.000000e-01)
  %h_op136 = call i32 @cq_template_mul_i32_hl(i32 %h68, i32 3)
  %h_op137 = call i32 @cq_template_xor_i32(i32 %h68, i32 %h_op136)
  %h_cmp10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op137, i32 39)
  call void @cqrt_rz_i1(i32 %h_cmp10, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp10, i32 %h_op137, i32 39)
  call void @cqrt_free(i32 %h_cmp10)
  %45 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op136) #5
  call void @cq_template_xor_i32_unc(i32 %h_op137, i32 %h68, i32 %h_op136)
  call void @cqrt_free(i32 %h_op137)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op136, i32 %h68, i32 3)
  call void @cqrt_free(i32 %h_op136)
  call void @cqrt_ry_i32(i32 %h68, double 0x3FE6666666666666)
  %m215 = call i32 @cqrt_measure_i32(i32 %45)
  %m216 = call i32 @cqrt_measure_i32(i32 %h68)
  %h69 = call i32 @cqrt_alloc_i32(i32 %19)
  call void @cqrt_ry_i32(i32 %h69, double 5.000000e-01)
  %h_op138 = call i32 @cq_template_mul_i32_hl(i32 %h69, i32 3)
  %h_op139 = call i32 @cq_template_xor_i32(i32 %h69, i32 %h_op138)
  %h_cmp9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op139, i32 40)
  call void @cqrt_rz_i1(i32 %h_cmp9, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp9, i32 %h_op139, i32 40)
  call void @cqrt_free(i32 %h_cmp9)
  %46 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op138) #5
  call void @cq_template_xor_i32_unc(i32 %h_op139, i32 %h69, i32 %h_op138)
  call void @cqrt_free(i32 %h_op139)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op138, i32 %h69, i32 3)
  call void @cqrt_free(i32 %h_op138)
  call void @cqrt_ry_i32(i32 %h69, double 0x3FE6666666666666)
  %m217 = call i32 @cqrt_measure_i32(i32 %46)
  %m218 = call i32 @cqrt_measure_i32(i32 %h69)
  %h70 = call i32 @cqrt_alloc_i32(i32 %22)
  call void @cqrt_ry_i32(i32 %h70, double 5.000000e-01)
  %h_op140 = call i32 @cq_template_mul_i32_hl(i32 %h70, i32 3)
  %h_op141 = call i32 @cq_template_xor_i32(i32 %h70, i32 %h_op140)
  %h_cmp8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op141, i32 41)
  call void @cqrt_rz_i1(i32 %h_cmp8, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp8, i32 %h_op141, i32 41)
  call void @cqrt_free(i32 %h_cmp8)
  %47 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op140) #5
  call void @cq_template_xor_i32_unc(i32 %h_op141, i32 %h70, i32 %h_op140)
  call void @cqrt_free(i32 %h_op141)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op140, i32 %h70, i32 3)
  call void @cqrt_free(i32 %h_op140)
  call void @cqrt_ry_i32(i32 %h70, double 0x3FE6666666666666)
  %m219 = call i32 @cqrt_measure_i32(i32 %47)
  %m220 = call i32 @cqrt_measure_i32(i32 %h70)
  %h71 = call i32 @cqrt_alloc_i32(i32 %2)
  call void @cqrt_ry_i32(i32 %h71, double 5.000000e-01)
  %h_op142 = call i32 @cq_template_mul_i32_hl(i32 %h71, i32 3)
  %h_op143 = call i32 @cq_template_xor_i32(i32 %h71, i32 %h_op142)
  %h_cmp7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op143, i32 42)
  call void @cqrt_rz_i1(i32 %h_cmp7, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp7, i32 %h_op143, i32 42)
  call void @cqrt_free(i32 %h_cmp7)
  %48 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op142) #5
  call void @cq_template_xor_i32_unc(i32 %h_op143, i32 %h71, i32 %h_op142)
  call void @cqrt_free(i32 %h_op143)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op142, i32 %h71, i32 3)
  call void @cqrt_free(i32 %h_op142)
  call void @cqrt_ry_i32(i32 %h71, double 0x3FE6666666666666)
  %m221 = call i32 @cqrt_measure_i32(i32 %48)
  %m222 = call i32 @cqrt_measure_i32(i32 %h71)
  %h72 = call i32 @cqrt_alloc_i32(i32 %5)
  call void @cqrt_ry_i32(i32 %h72, double 5.000000e-01)
  %h_op144 = call i32 @cq_template_mul_i32_hl(i32 %h72, i32 3)
  %h_op145 = call i32 @cq_template_xor_i32(i32 %h72, i32 %h_op144)
  %h_cmp6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op145, i32 43)
  call void @cqrt_rz_i1(i32 %h_cmp6, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp6, i32 %h_op145, i32 43)
  call void @cqrt_free(i32 %h_cmp6)
  %49 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op144) #5
  call void @cq_template_xor_i32_unc(i32 %h_op145, i32 %h72, i32 %h_op144)
  call void @cqrt_free(i32 %h_op145)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op144, i32 %h72, i32 3)
  call void @cqrt_free(i32 %h_op144)
  call void @cqrt_ry_i32(i32 %h72, double 0x3FE6666666666666)
  %m223 = call i32 @cqrt_measure_i32(i32 %49)
  %m224 = call i32 @cqrt_measure_i32(i32 %h72)
  %h73 = call i32 @cqrt_alloc_i32(i32 %8)
  call void @cqrt_ry_i32(i32 %h73, double 5.000000e-01)
  %h_op146 = call i32 @cq_template_mul_i32_hl(i32 %h73, i32 3)
  %h_op147 = call i32 @cq_template_xor_i32(i32 %h73, i32 %h_op146)
  %h_cmp5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op147, i32 44)
  call void @cqrt_rz_i1(i32 %h_cmp5, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp5, i32 %h_op147, i32 44)
  call void @cqrt_free(i32 %h_cmp5)
  %50 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op146) #5
  call void @cq_template_xor_i32_unc(i32 %h_op147, i32 %h73, i32 %h_op146)
  call void @cqrt_free(i32 %h_op147)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op146, i32 %h73, i32 3)
  call void @cqrt_free(i32 %h_op146)
  call void @cqrt_ry_i32(i32 %h73, double 0x3FE6666666666666)
  %m225 = call i32 @cqrt_measure_i32(i32 %50)
  %m226 = call i32 @cqrt_measure_i32(i32 %h73)
  %h74 = call i32 @cqrt_alloc_i32(i32 %11)
  call void @cqrt_ry_i32(i32 %h74, double 5.000000e-01)
  %h_op148 = call i32 @cq_template_mul_i32_hl(i32 %h74, i32 3)
  %h_op149 = call i32 @cq_template_xor_i32(i32 %h74, i32 %h_op148)
  %h_cmp4 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op149, i32 45)
  call void @cqrt_rz_i1(i32 %h_cmp4, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp4, i32 %h_op149, i32 45)
  call void @cqrt_free(i32 %h_cmp4)
  %51 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op148) #5
  call void @cq_template_xor_i32_unc(i32 %h_op149, i32 %h74, i32 %h_op148)
  call void @cqrt_free(i32 %h_op149)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op148, i32 %h74, i32 3)
  call void @cqrt_free(i32 %h_op148)
  call void @cqrt_ry_i32(i32 %h74, double 0x3FE6666666666666)
  %m227 = call i32 @cqrt_measure_i32(i32 %51)
  %m228 = call i32 @cqrt_measure_i32(i32 %h74)
  %h75 = call i32 @cqrt_alloc_i32(i32 %13)
  call void @cqrt_ry_i32(i32 %h75, double 5.000000e-01)
  %h_op150 = call i32 @cq_template_mul_i32_hl(i32 %h75, i32 3)
  %h_op151 = call i32 @cq_template_xor_i32(i32 %h75, i32 %h_op150)
  %h_cmp3 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op151, i32 46)
  call void @cqrt_rz_i1(i32 %h_cmp3, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp3, i32 %h_op151, i32 46)
  call void @cqrt_free(i32 %h_cmp3)
  %52 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op150) #5
  call void @cq_template_xor_i32_unc(i32 %h_op151, i32 %h75, i32 %h_op150)
  call void @cqrt_free(i32 %h_op151)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op150, i32 %h75, i32 3)
  call void @cqrt_free(i32 %h_op150)
  call void @cqrt_ry_i32(i32 %h75, double 0x3FE6666666666666)
  %m229 = call i32 @cqrt_measure_i32(i32 %52)
  %m230 = call i32 @cqrt_measure_i32(i32 %h75)
  %h76 = call i32 @cqrt_alloc_i32(i32 %16)
  call void @cqrt_ry_i32(i32 %h76, double 5.000000e-01)
  %h_op152 = call i32 @cq_template_mul_i32_hl(i32 %h76, i32 3)
  %h_op153 = call i32 @cq_template_xor_i32(i32 %h76, i32 %h_op152)
  %h_cmp2 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op153, i32 47)
  call void @cqrt_rz_i1(i32 %h_cmp2, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp2, i32 %h_op153, i32 47)
  call void @cqrt_free(i32 %h_cmp2)
  %53 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op152) #5
  call void @cq_template_xor_i32_unc(i32 %h_op153, i32 %h76, i32 %h_op152)
  call void @cqrt_free(i32 %h_op153)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op152, i32 %h76, i32 3)
  call void @cqrt_free(i32 %h_op152)
  call void @cqrt_ry_i32(i32 %h76, double 0x3FE6666666666666)
  %m231 = call i32 @cqrt_measure_i32(i32 %53)
  %m232 = call i32 @cqrt_measure_i32(i32 %h76)
  %h77 = call i32 @cqrt_alloc_i32(i32 %19)
  call void @cqrt_ry_i32(i32 %h77, double 5.000000e-01)
  %h_op154 = call i32 @cq_template_mul_i32_hl(i32 %h77, i32 3)
  %h_op155 = call i32 @cq_template_xor_i32(i32 %h77, i32 %h_op154)
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op155, i32 48)
  call void @cqrt_rz_i1(i32 %h_cmp1, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op155, i32 48)
  call void @cqrt_free(i32 %h_cmp1)
  %54 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op154) #5
  call void @cq_template_xor_i32_unc(i32 %h_op155, i32 %h77, i32 %h_op154)
  call void @cqrt_free(i32 %h_op155)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op154, i32 %h77, i32 3)
  call void @cqrt_free(i32 %h_op154)
  call void @cqrt_ry_i32(i32 %h77, double 0x3FE6666666666666)
  %m233 = call i32 @cqrt_measure_i32(i32 %54)
  %m234 = call i32 @cqrt_measure_i32(i32 %h77)
  %h78 = call i32 @cqrt_alloc_i32(i32 %22)
  call void @cqrt_ry_i32(i32 %h78, double 5.000000e-01)
  %h_op156 = call i32 @cq_template_mul_i32_hl(i32 %h78, i32 3)
  %h_op157 = call i32 @cq_template_xor_i32(i32 %h78, i32 %h_op156)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op157, i32 49)
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase !6
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op157, i32 49)
  call void @cqrt_free(i32 %h_cmp)
  %55 = tail call i32 @__cq_q_h_10(i32 noundef 0, i32 noundef %h_op156) #5
  call void @cq_template_xor_i32_unc(i32 %h_op157, i32 %h78, i32 %h_op156)
  call void @cqrt_free(i32 %h_op157)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op156, i32 %h78, i32 3)
  call void @cqrt_free(i32 %h_op156)
  call void @cqrt_ry_i32(i32 %h78, double 0x3FE6666666666666)
  %m235 = call i32 @cqrt_measure_i32(i32 %55)
  %m236 = call i32 @cqrt_measure_i32(i32 %h78)
  %56 = add i32 %m158, %m
  %57 = add i32 %56, %m159
  %58 = add i32 %57, %m160
  %59 = add i32 %58, %m161
  %60 = add i32 %59, %m162
  %61 = add i32 %60, %m163
  %62 = add i32 %61, %m164
  %63 = add i32 %62, %m165
  %64 = add i32 %63, %m166
  %65 = add i32 %64, %m167
  %66 = add i32 %65, %m168
  %67 = add i32 %66, %m169
  %68 = add i32 %67, %m170
  %69 = add i32 %68, %m171
  %70 = add i32 %69, %m172
  %71 = add i32 %70, %m173
  %72 = add i32 %71, %m174
  %73 = add i32 %72, %m175
  %74 = add i32 %73, %m176
  %75 = add i32 %74, %m177
  %76 = add i32 %75, %m178
  %77 = add i32 %76, %m179
  %78 = add i32 %77, %m180
  %79 = add i32 %78, %m181
  %80 = add i32 %79, %m182
  %81 = add i32 %80, %m183
  %82 = add i32 %81, %m184
  %83 = add i32 %82, %m185
  %84 = add i32 %83, %m186
  %85 = add i32 %84, %m187
  %86 = add i32 %85, %m188
  %87 = add i32 %86, %m189
  %88 = add i32 %87, %m190
  %89 = add i32 %88, %m191
  %90 = add i32 %89, %m192
  %91 = add i32 %90, %m193
  %92 = add i32 %91, %m194
  %93 = add i32 %92, %m195
  %94 = add i32 %93, %m196
  %95 = add i32 %94, %m197
  %96 = add i32 %95, %m198
  %97 = add i32 %96, %m199
  %98 = add i32 %97, %m200
  %99 = add i32 %98, %m201
  %100 = add i32 %99, %m202
  %101 = add i32 %100, %m203
  %102 = add i32 %101, %m204
  %103 = add i32 %102, %m205
  %104 = add i32 %103, %m206
  %105 = add i32 %104, %m207
  %106 = add i32 %105, %m208
  %107 = add i32 %106, %m209
  %108 = add i32 %107, %m210
  %109 = add i32 %108, %m211
  %110 = add i32 %109, %m212
  %111 = add i32 %110, %m213
  %112 = add i32 %111, %m214
  %113 = add i32 %112, %m215
  %114 = add i32 %113, %m216
  %115 = add i32 %114, %m217
  %116 = add i32 %115, %m218
  %117 = add i32 %116, %m219
  %118 = add i32 %117, %m220
  %119 = add i32 %118, %m221
  %120 = add i32 %119, %m222
  %121 = add i32 %120, %m223
  %122 = add i32 %121, %m224
  %123 = add i32 %122, %m225
  %124 = add i32 %123, %m226
  %125 = add i32 %124, %m227
  %126 = add i32 %125, %m228
  %127 = add i32 %126, %m229
  %128 = add i32 %127, %m230
  %129 = add i32 %128, %m231
  %130 = add i32 %129, %m232
  %131 = add i32 %130, %m233
  %132 = add i32 %131, %m234
  %133 = add i32 %132, %m235
  %134 = add i32 %133, %m236
  ret i32 %134
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #1 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !7
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @slice(i32 noundef %5)
  %7 = and i32 %6, 1
  ret i32 %7
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

; Function Attrs: mustprogress norecurse nosync nounwind ssp memory(readwrite) uwtable
define internal i32 @__cq_q_h_10(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %h_op = call i32 @cq_template_add_i32_hl(i32 %1, i32 1)
  %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
  call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %1, i32 1)
  call void @cqrt_free(i32 %h_op)
  ret i32 %cqq.out
}

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_xor_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_xor_i32_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress norecurse nosync nounwind ssp memory(readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{}
!7 = !{!8, !8, i64 0}
!8 = !{!"any pointer", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
