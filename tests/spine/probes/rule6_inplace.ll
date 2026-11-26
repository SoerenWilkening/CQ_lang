; /* tests/spine probe (CR rule 6, in-place update; owner 2026-11-25, cq-2h7xa): an add or xor of a dead value is one
;  * core gate on the old rail (add_<W>, addc_<W>, copy_<W>, xorc_<W>); the old form stays where the old value is read
;  * later and for y + y; a select of an update is `y + select(c, o, 0)` (cq-6wef6). */
; int add_reg(int x0, double tx, int y0, double ty) {
;   int x = x0, y = y0;
;   cq_theta(&x, tx);
;   cq_theta(&y, ty);
;   x += y;
;   return cq_measure(x) + cq_measure(y);
; }
; int xor_reg(int x0, double tx, int y0, double ty) {
;   int x = x0, y = y0;
;   cq_theta(&x, tx);
;   cq_theta(&y, ty);
;   x ^= y;
;   return cq_measure(x) + cq_measure(y);
; }
; int add_lit(int x0, double tx) {
;   int x = x0;
;   cq_theta(&x, tx);
;   x += 7;
;   return cq_measure(x);
; }
; int xor_lit(int x0, double tx, int c) {
;   int x = x0;
;   cq_theta(&x, tx);
;   x ^= c;
;   return cq_measure(x);
; }
; int chain(int x0, double tx, int a0, int b0, double ta) {
;   int x = x0, a = a0, b = b0;
;   cq_theta(&x, tx);
;   cq_theta(&a, ta);
;   cq_theta(&b, ta);
;   x += a;
;   x ^= b;
;   x += 3;
;   return cq_measure(x) + cq_measure(a) + cq_measure(b);
; }
; int cell;
; int mem_add(int q0, double tq) {
;   int q = q0;
;   cq_theta(&q, tq);
;   int *p = &cell;
;   *p += q;
;   return cq_measure(*p) + cq_measure(q);
; }
; char arr[4];
; int mem_xor(int i, int b0, double tb) {
;   char b = (char)b0;
;   cq_theta(&b, tb);
;   arr[i & 3] ^= b;
;   return cq_measure(arr[i & 3]) + cq_measure(b);
; }
; int g1, g2, g3;
; int arm(int x0, double tx, int c0, double tc) {
;   int x = x0, c = c0;
;   cq_theta(&x, tx);
;   cq_theta(&c, tc);
;   if (c > 5) {
;     int t = x * 3;
;     t += c;
;     g1 = t;
;   }
;   return cq_measure(x) + cq_measure(c);
; }
; int arm_dead_everywhere(int x0, double tx, int c0, double tc) {
;   int x = x0, c = c0;
;   cq_theta(&x, tx);
;   cq_theta(&c, tc);
;   int t = x * 3;
;   if (c > 5) {
;     t ^= 12;
;     g2 = t;
;   }
;   return cq_measure(x) + cq_measure(c);
; }
; int inverted(int x0, double tx, int y0, double ty) {
;   int x = x0, y = y0;
;   cq_theta(&x, tx);
;   cq_theta(&y, ty);
;   cq_invert_begin();
;   int t = x * 3;
;   t += y;
;   g3 = t;
;   cq_invert_end();
;   return cq_measure(x) + cq_measure(y);
; }
; __attribute__((noinline)) int bump(int v) {
;   int t = v * 5;
;   t ^= 9;
;   return cq_measure(t);
; }
; int callee_update(int x0, double tx) {
;   int x = x0;
;   cq_theta(&x, tx);
;   int r = bump(x);
;   return r + cq_measure(x);
; }
; int both_dead(int s0, int t0, double th) {
;   int s = s0, t = t0;
;   cq_theta(&s, th);
;   cq_theta(&t, th);
;   int sum = s + t;
;   return cq_measure(sum);
; }
; int read_later(int x0, double tx, int y0, double ty) {
;   int x = x0, y = y0;
;   cq_theta(&x, tx);
;   cq_theta(&y, ty);
;   int z = x + y;
;   int w = x * 3;
;   return cq_measure(z) + cq_measure(w) + cq_measure(y);
; }
; int doubled(int x0, double tx) {
;   int x = x0;
;   cq_theta(&x, tx);
;   x = x + x;
;   return cq_measure(x);
; }
; int merged(int x0, double tx, int c0, double tc) {
;   int x = x0, c = c0;
;   cq_theta(&x, tx);
;   cq_theta(&c, tc);
;   int y = c > 3 ? x + 5 : x;
;   return cq_measure(y) + cq_measure(c);
; }
source_filename = "tests/spine/probes/rule6_inplace.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cell = local_unnamed_addr global i32 0, align 4
@arr = local_unnamed_addr global [4 x i8] zeroinitializer, align 1
@g1 = local_unnamed_addr global i32 0, align 4
@g2 = local_unnamed_addr global i32 0, align 4
@g3 = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @add_reg(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4
  %7 = add nsw i32 %6, %5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  %10 = add nsw i32 %9, %8
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @xor_reg(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4
  %7 = xor i32 %6, %5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  %10 = add nsw i32 %9, %8
  ret i32 %10
}

; Function Attrs: nounwind ssp uwtable
define i32 @add_lit(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = add nsw i32 %3, 7
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @xor_lit(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %5 = xor i32 %4, %2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @chain(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %4) #4
  %8 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #4
  %9 = add nsw i32 %7, %6
  %10 = xor i32 %9, %8
  %11 = add nsw i32 %10, 3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #5
  %13 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %14 = add nsw i32 %13, %12
  %15 = tail call i32 @cq_measure_si32(i32 noundef %8) #5
  %16 = add nsw i32 %14, %15
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @mem_add(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = load i32, ptr @cell, align 4, !tbaa !6
  %5 = add nsw i32 %4, %3
  store i32 %5, ptr @cell, align 4, !tbaa !6
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -256, 255) i32 @mem_xor(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = trunc i32 %1 to i8
  %5 = tail call signext i8 @cq_theta_c(i8 noundef signext %4, double noundef %2) #4
  %6 = and i32 %0, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x i8], ptr @arr, i64 0, i64 %7
  %9 = load i8, ptr %8, align 1, !tbaa !10
  %10 = xor i8 %9, %5
  store i8 %10, ptr %8, align 1, !tbaa !10
  %11 = tail call signext i8 @cq_measure_c(i8 noundef signext %10) #5
  %12 = sext i8 %11 to i32
  %13 = tail call signext i8 @cq_measure_c(i8 noundef signext %5) #5
  %14 = sext i8 %13 to i32
  %15 = add nsw i32 %14, %12
  ret i32 %15
}

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #1

declare signext i8 @cq_measure_c(i8 noundef signext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @arm(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4
  %7 = icmp sgt i32 %6, 5
  br i1 %7, label %8, label %11

8:                                                ; preds = %4
  %9 = mul nsw i32 %5, 3
  %10 = add nsw i32 %9, %6
  store i32 %10, ptr @g1, align 4, !tbaa !6
  br label %11

11:                                               ; preds = %8, %4
  %12 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  %13 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @arm_dead_everywhere(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4
  %7 = icmp sgt i32 %6, 5
  br i1 %7, label %8, label %11

8:                                                ; preds = %4
  %9 = mul nsw i32 %5, 3
  %10 = xor i32 %9, 12
  store i32 %10, ptr @g2, align 4, !tbaa !6
  br label %11

11:                                               ; preds = %8, %4
  %12 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  %13 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @inverted(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4
  tail call void @__cq_invert_begin() #6
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !11
  %7 = mul nsw i32 %5, 3
  %8 = add nsw i32 %7, %6
  store i32 %8, ptr @g3, align 4, !tbaa !6
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !12
  tail call void @__cq_invert_end() #6
  %9 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  %10 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  %11 = add nsw i32 %10, %9
  ret i32 %11
}

; Function Attrs: noduplicate
declare void @__cq_invert_begin() local_unnamed_addr #2

; Function Attrs: noduplicate
declare void @__cq_invert_end() local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define i32 @bump(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 5
  %3 = xor i32 %2, 9
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @callee_update(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = tail call i32 @bump(i32 noundef %3)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  %6 = add nsw i32 %5, %4
  ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @both_dead(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #4
  %6 = add nsw i32 %5, %4
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @read_later(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4
  %7 = add nsw i32 %6, %5
  %8 = mul nsw i32 %5, 3
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8) #5
  %11 = add nsw i32 %10, %9
  %12 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  %13 = add nsw i32 %11, %12
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @doubled(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = shl nsw i32 %3, 1
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @merged(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4
  %7 = icmp sgt i32 %6, 3
  %8 = add nsw i32 %5, 5
  %9 = select i1 %7, i32 %8, i32 %5
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noduplicate "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
attributes #6 = { noduplicate nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!8, !8, i64 0}
!11 = !{i64 2147542545}
!12 = !{i64 2147542601}
; USERCHECK chain
; USERCHECK mem_add
; USERCHECK arm
; USERCHECK inverted
; USERCHECK callee_update
; USERCHECK both_dead
; USERCHECK merged
; CHECK add_reg: call void @cqrt_add_i32(i32 %{{y}}, i32 %{{x}})
; CHECK-COUNT add_reg: @cq_template_ 0
; CHECK-COUNT add_reg: @cqrt_free( 0
; CHECK xor_reg: call void @cqrt_copy_i32(i32 %{{y}}, i32 %{{x}})
; CHECK-COUNT xor_reg: @cq_template_ 0
; CHECK-COUNT xor_reg: @cqrt_free( 0
; CHECK add_lit: call void @cqrt_addc_i32(i32 %{{x}}, i32 7)
; CHECK-COUNT add_lit: @cq_template_ 0
; CHECK-COUNT add_lit: @cqrt_free( 0
; CHECK xor_lit: call void @cqrt_xorc_i32(i32 %{{x}}, i32 %{{c}})
; CHECK-COUNT xor_lit: @cq_template_ 0
; CHECK-COUNT xor_lit: @cqrt_free( 0
; CHECK chain: call void @cqrt_add_i32(i32 %{{a}}, i32 %{{x}})
; CHECK chain: call void @cqrt_copy_i32(i32 %{{b}}, i32 %{{x}})
; CHECK chain: call void @cqrt_addc_i32(i32 %{{x}}, i32 3)
; CHECK-COUNT chain: @cq_template_ 0
; CHECK-COUNT chain: @cqrt_free( 0
; CHECK mem_add: call void @cqrt_add_i32(i32 %{{q}}, i32 %{{h}})
; CHECK-COUNT mem_add: @cq_template_ 0
; CHECK-COUNT mem_add: @cqrt_free( 1
; CHECK mem_xor: call void @cqrt_copy_i8(i32 %{{b}}, i32 %{{h}})
; CHECK-COUNT mem_xor: @cq_template_ 0
; CHECK-COUNT mem_xor: @cqrt_free( 1
; CHECK arm: call void @cqrt_add_i32(i32 %{{c}}, i32 %{{t}})
; CHECK-COUNT arm: @cq_template_add 0
; CHECK-COUNT arm: @cq_template_sub 0
; CHECK-COUNT arm: @cqrt_copy 0
; CHECK arm_dead_everywhere: call void @cqrt_xorc_i32(i32 %{{t}}, i32 12)
; CHECK-COUNT arm_dead_everywhere: @cq_template_xor 0
; CHECK-COUNT arm_dead_everywhere: @cqrt_copy 0
; CHECK inverted: call void @cqrt_add_i32(i32 %{{y}}, i32 %{{t}})
; CHECK-COUNT inverted: @cq_template_add 0
; CHECK-COUNT inverted: @cq_template_sub 0
; CHECK __cq_q_bump_1: call void @cqrt_xorc_i32(i32 %{{t}}, i32 9)
; CHECK-COUNT __cq_q_bump_1: @cq_template_xor 0
; CHECK both_dead: call void @cqrt_add_i32(i32 %{{s}}, i32 %{{t}})
; CHECK-COUNT both_dead: @cq_template_ 0
; CHECK read_later: call i32 @cq_template_add_i32(
; CHECK-COUNT read_later: @cqrt_add_ 0
; CHECK doubled: call i32 @cq_template_shl_i32_hl(
; CHECK-COUNT doubled: @cqrt_add 0
; CHECK merged: call i32 @cq_template_select_i32_ll(i32 %{{c}}, i32 5, i32 0)
; CHECK merged: call void @cqrt_add_i32(i32 %{{s}}, i32 %{{x}})
; CHECK-COUNT merged: @cq_template_add 0
; CHECK-COUNT merged: @cq_template_sub 0
