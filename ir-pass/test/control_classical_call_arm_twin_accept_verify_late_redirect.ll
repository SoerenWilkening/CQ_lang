; control_classical_call_arm_twin_accept_verify_late_redirect.ll — ACCEPT (bd dm7f.21, R11 round 2 F-C).
; A redirect only the VERIFICATION of `@F`'s twin can find (hand IR). `%e = add nsw
; %f, 2` is proven on the ORIGINAL body through the use-based license of `%c` (its
; later `noundef` use `K(%c)`, read through `freeze %c`). The first plan freezes
; that use, the twin is cloned without touching `@M`, and only the verification
; round, where the license is gone, sees `%e` possibly poison reaching `@M`'s
; non-`noundef` parameter, which `@M` forwards to `@K`'s `noundef` parameter. The
; builder then has to build `@M`'s twin MID-VERIFICATION (the Missing path) before
; re-planning `@F`'s (CQ_SPECSAFE_DBG: `@__cq_specsafe_M` rounds=0, then
; `@__cq_specsafe_F` rounds=1). `%b` is frozen in the same round, as in
; control_classical_call_arm_twin_accept_verify_license.ll.
; ANALYTIC (R2): on a UB-free execution of the source's `F(x, p)`, p < 32 and every
; freeze is the identity; otherwise UB in the source or never merged.
; Mutant this kills: a builder that treats a twin still missing during
; verification as "no edits" and tags the half-verified twin.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:       define internal i32 @__cq_specsafe_F(i32 noundef %x, i32 noundef %p)
; CHECK:         %b.fr = freeze i32 %b
; CHECK-NEXT:    %r2 = call i32 @K(i32 noundef %b.fr)
; CHECK-NEXT:    %e = add nsw i32 %f, 2
; CHECK-NEXT:    %k = call i32 @__cq_specsafe_M(i32 %e)
; CHECK:       define internal i32 @__cq_specsafe_M(i32 %y)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %y.fr = freeze i32 %y
; CHECK-NEXT:    %r = call i32 @K(i32 noundef %y.fr)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @K(i32 noundef %v) #0 {
entry:
  %w = xor i32 %v, 5
  ret i32 %w
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
  %e = add nsw i32 %f, 2
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
