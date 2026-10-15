; spec_intermediate_unc_terminal_union_measured_root.ll — ACCEPT (bd
; test_C_libtooling-p3kd.14, batch 053 unit D; R11 r10 probe p1, a correct accept
; that had no fixture). Register ROOTS cut under a rail measured on every path.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int cr(int s) {
;       int c = s & 7; cq_theta(&c, 0.9);
;       int k = (s >> 3) & 7; cq_theta(&k, 0.3);
;       if (c > 5) cq_theta(&k, 0.7);
;       int p = (s >> 6) & 7; cq_theta(&p, 0.5);
;       int R = p + k; int a = R + 2;
;       int t = a * 5; cq_theta(&t, 0.4); int r = h(a); cq_theta(&r, 0.2);
;       return cq_measure(R) + cq_measure(c); }
;     /* crk: the all-template twin, `int r = a * 7` */
;     int main(int argc, char **argv) { (void)argv; return cr(argc) + crk(argc + 1); }
;
; R is measured on every path, so the union's frontier borrows it and its own `add`
; is exempt; that cuts k's and p's own gates (k carries a CONTROLLED Ry), which are
; register-root gates recording no other register (R11 r9 F2) — and, since unit D,
; are also not hazardous (they read no tainted register besides their own). The
; union is emitted: t's and r's chains reversed and freed, a reversed, R, k and p
; left; @crk (main's planner) emits the same stream with `mul_unc` for the twin.
;
; bd r2j3.33 (dm7f.51 step 1): `p`'s old value is dead at `R = p + k` and R is
; measured, so R is computed IN PLACE on `p`'s rail (`k` the borrowed source); R
; is that rail from here on, and every later reader names it.
;
; ⚠ ACCEPT → LOUD by bd test_C_libtooling-dm7f.77 (dm7f.51 step 2; the file keeps
; its name, L8). `R = p + k` reads TWO dead rotated registers: `p` and `k`, whose
; SSA name is the merge φ of the `if (c > 5) cq_theta(&k, .7)` region. Step 1
; refused every φ as an in-place target (Bennett: "a φ can alias another live
; name"), so `p` was the ONLY eligible operand and this accepted in place on `p`
; — a tiebreak by φ-ness. dm7f.77 asks deadness of a φ over its whole rotation
; chain (design D2(b); `singleWirePhiDeadAfter`): `phi [Ry(%k), %k]` names one
; rail and every member is dead after the add, so BOTH operands are eligible, and
; the delegated ruling ruling-dm7f51-both-dead-loud-2026-10-15 says that fails
; LOUDLY (the overwritten register is not recoverable from -O1 SSA; the choice
; changes which register is left behind). The same φ exclusion is what made main
; 27aaf1e1 SILENTLY miscompile `if (a) cq_theta(&q, .7); q ^= x; cq_theta(&x,
; .3)` (lowering_inplace_qq_phi_target_accept.ll: P(000) 0.8293 vs textbook
; 0.8216). The p3kd.14 union-frontier subject above is therefore NOT pinned by
; this file any more (flagged to the coordinator). RETIREMENT TRIGGER: the
; owner's answer to the both-dead question (the dm7f gap issue filed with that
; ruling: recover the lvalue via -g, or loud).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq in-place lowering: both operands of a quantum reassignment are dead registers; the overwritten one is not recoverable


define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @cr(i32 noundef %0)
  %4 = add nsw i32 %0, 1
  %5 = tail call fastcc i32 @crk(i32 noundef %4)
  %6 = add nsw i32 %5, %3
  ret i32 %6
}

define internal fastcc i32 @cr(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #4
  %4 = lshr i32 %0, 3
  %5 = and i32 %4, 7
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 3.000000e-01) #4
  %7 = icmp sgt i32 %3, 5
  br i1 %7, label %8, label %10

8:
  %9 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 0x3FE6666666666666) #4
  br label %10

10:
  %11 = phi i32 [ %9, %8 ], [ %6, %1 ]
  %12 = lshr i32 %0, 6
  %13 = and i32 %12, 7
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 5.000000e-01) #4
  %15 = add nsw i32 %14, %11
  %16 = add nsw i32 %15, 2
  %17 = mul nsw i32 %16, 5
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 4.000000e-01) #4
  %19 = tail call fastcc i32 @h(i32 noundef %16)
  %20 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef 2.000000e-01) #4
  %21 = tail call i32 @cq_measure_si32(i32 noundef %15) #5
  %22 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  %23 = add nsw i32 %22, %21
  ret i32 %23
}

define internal fastcc i32 @crk(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #4
  %4 = lshr i32 %0, 3
  %5 = and i32 %4, 7
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 3.000000e-01) #4
  %7 = icmp sgt i32 %3, 5
  br i1 %7, label %8, label %10

8:
  %9 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 0x3FE6666666666666) #4
  br label %10

10:
  %11 = phi i32 [ %9, %8 ], [ %6, %1 ]
  %12 = lshr i32 %0, 6
  %13 = and i32 %12, 7
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 5.000000e-01) #4
  %15 = add nsw i32 %14, %11
  %16 = add nsw i32 %15, 2
  %17 = mul nsw i32 %16, 5
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 4.000000e-01) #4
  %19 = mul nsw i32 %16, 7
  %20 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef 2.000000e-01) #4
  %21 = tail call i32 @cq_measure_si32(i32 noundef %15) #5
  %22 = tail call i32 @cq_measure_si32(i32 noundef %3) #5
  %23 = add nsw i32 %22, %21
  ret i32 %23
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
