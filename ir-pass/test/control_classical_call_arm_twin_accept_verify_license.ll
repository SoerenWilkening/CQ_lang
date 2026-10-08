; control_classical_call_arm_twin_accept_verify_license.ll — ACCEPT (bd dm7f.21, R11 round 2 F-C).
; The reviewer's probe p4, verbatim below the header (hand IR). Two facts the
; ORIGINAL body licenses and the twin does not:
;  (a) use-based self-licensing: LLVM treats `%c` as not poison because of its later
;      `noundef` use `K(%c)`, reads through `freeze %c`, and proves `add nsw %f, 1`.
;      The twin freezes that use, which removes the license, so verification must
;      freeze `%b` (`%b.fr`).
;  (b) an `nsw` proven through `@G`'s `returned` on the original body only: in the
;      twin `@G` reads a frozen `%c`, so `%e` becomes possibly poison and reaches
;      `@M`'s NON-`noundef` parameter, which `@M` passes to `@K`'s `noundef`
;      parameter: `@M` is twinned (`%y.fr`). Since round 2 the plan sees (b) in its
;      first pass (a frozen `returned` argument); the late, mid-verification
;      redirect is pinned by control_classical_call_arm_twin_accept_verify_late_redirect.ll.
; The `ret` is frozen because the redirected `%k` reaches it (`%t.fr`).
; ANALYTIC (R2): on a UB-free execution of the source's `F(x, p)`, p < 32, `%c` is
; defined and every freeze is the identity; otherwise UB or never merged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:       define internal i32 @__cq_specsafe_M(i32 %y)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %y.fr = freeze i32 %y
; CHECK-NEXT:    %r = call i32 @K(i32 noundef %y.fr)
; CHECK:       define internal i32 @__cq_specsafe_F(i32 noundef %x, i32 noundef %p)
; CHECK:         %b = add nsw i32 %f, 1
; CHECK-NEXT:    %b.fr = freeze i32 %b
; CHECK-NEXT:    %r2 = call i32 @K(i32 noundef %b.fr)
; CHECK:         %k = call i32 @__cq_specsafe_M(i32 %e)
; CHECK:         %t.fr = freeze i32 %t
; CHECK-NEXT:    ret i32 %t.fr

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @K(i32 noundef %v) #0 {
entry:
  %w = xor i32 %v, 5
  ret i32 %w
}

define noundef i32 @G(i32 noundef returned %x) #0 {
entry:
  ret i32 %x
}

define internal i32 @M(i32 %y) #0 {
entry:
  %r = call i32 @K(i32 noundef %y)
  ret i32 %r
}

define internal i32 @F(i32 noundef %x, i32 noundef %p) #0 {
entry:
  %a = lshr i32 %x, %p
  %c = and i32 %a, 255
  %f = freeze i32 %c
  %r1 = call i32 @K(i32 noundef %c)
  %b = add nsw i32 %f, 1
  %r2 = call i32 @K(i32 noundef %b)
  %g = call i32 @G(i32 noundef %c)
  %e = add nsw i32 %g, 1
  %k = call i32 @M(i32 %e)
  %s = add i32 %r1, %r2
  %t = add i32 %s, %k
  ret i32 %t
}

define i32 @example(i32 noundef %u0, i32 noundef %x, i32 noundef %p) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %cnd = icmp sgt i32 %q, 3
  br i1 %cnd, label %arm, label %merge
arm:
  %r = call i32 @F(i32 %x, i32 %p)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
