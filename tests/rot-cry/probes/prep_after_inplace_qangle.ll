; rot-cry probes (cq-t3rd, rules 10 and 15): a quantum-angle cq_theta in place under a quantum predicate
; (ry_i32_qangle_controlled on the register of r) locks the register as the classical-angle in-place
; rotation does: the later disjoint prep of r would otherwise xorc 5 and Ry onto the rotated state
; (Ry(b) X^5 Ry(A)|0> where C has Ry(b)|5>). Not built: it stops loudly.
; int f(double a, double b){ int x=0; cq_theta(&x,1.0); int r = 0;
;   if (x == 1) { r = 7; cq_theta(&r, a); }
;   if (x > 1) cq_theta(&r, 0.1 * (double)x);
;   if (x != 1) { r = 5; cq_theta(&r, b); }
;   return r; }
; cq-a63l (CR rule 10, cq-oa67): a prep of a register rotated in place since: a fresh rail seeded with v,
; the old one frozen, rule 9 merges over the handles.
; CHECK f: call i32 @cq_template_select_
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare i32 @cq_theta_si32(i32 noundef, double noundef)

define i32 @f(double noundef %0, double noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00)
  %4 = icmp eq i32 %3, 1
  br i1 %4, label %5, label %7

5:
  %6 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef %0)
  br label %7

7:
  %8 = phi i32 [ %6, %5 ], [ 0, %2 ]
  %9 = icmp sgt i32 %3, 1
  br i1 %9, label %10, label %14

10:
  %11 = uitofp nneg i32 %3 to double
  %12 = fmul double %11, 1.000000e-01
  %13 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef %12)
  br label %14

14:
  %15 = phi i32 [ %13, %10 ], [ %8, %7 ]
  br i1 %4, label %18, label %16

16:
  %17 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef %1)
  br label %18

18:
  %19 = phi i32 [ %17, %16 ], [ %15, %14 ]
  ret i32 %19
}
