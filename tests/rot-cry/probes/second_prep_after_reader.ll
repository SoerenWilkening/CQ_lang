; rot-cry probes (cq-sx24): a second prep of a register whose predicate overlaps the first (133
; prep_twice) while the first prep's merge %13 is still read after it (-O1 sank %19 past the second
; prep). Rule 10 undoes the first prep by its adjoint only when nothing read the register in between,
; and %19 reads it in between in program order: cq::unimplemented with the reader printed.
; int overl(int x0, double th, int k1, int k2, int r0, double t1, double t2) {
;   int x = x0; cq_theta(&x, th); int r = r0;
;   if (x > k1) { r = 0; cq_theta(&r, t1); }
;   int z = (r != 0);
;   if (x < k2) { r = 0; cq_theta(&r, t2); }
;   return cq_measure(r) + cq_measure(x) + 4 * cq_measure(z); }
; cq-a63l (CR rule 10, ruling 2026-11-02 cq-oa67): the first prep's value is read after the second prep, so the
; first cannot be undone: the second prep is a prep of a fresh rail seeded with v, the old rail stays
; (frozen), and the merges are rule 9 selects over the two handles.
; CHECK overl: call i32 @cq_template_select_
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @overl(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, double noundef %6) {
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %9 = icmp sgt i32 %8, %2
  br i1 %9, label %10, label %12

10:
  %11 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %5)
  br label %12

12:
  %13 = phi i32 [ %11, %10 ], [ %4, %7 ]
  %14 = icmp slt i32 %8, %3
  br i1 %14, label %15, label %17

15:
  %16 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %6)
  br label %17

17:
  %18 = phi i32 [ %16, %15 ], [ %13, %12 ]
  %19 = icmp ne i32 %13, 0
  %20 = zext i1 %19 to i32
  %21 = tail call i32 @cq_measure_si32(i32 noundef %18)
  %22 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %23 = add nsw i32 %22, %21
  %24 = tail call i32 @cq_measure_si32(i32 noundef %20)
  %25 = shl nsw i32 %24, 2
  %26 = add nsw i32 %23, %25
  ret i32 %26
}
