; lowering_reject_uncompute_partial_measure_cut_record.ll — DECLINE (bd
; test_C_libtooling-r2j3.24, batch 053 unit D; the repro `cmk`).
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int cmk(int s) {
;       int x = s & 7; cq_theta(&x, 0.5);
;       int q = x * 3; int a = q + 2;
;       int t = a * 5; cq_theta(&t, 0.4);
;       int r = a * 7; cq_theta(&r, 0.2);
;       int acc = 0; if (s > 100) acc = cq_measure(q);
;       cq_theta(&x, -0.5);
;       return acc + cq_measure(x); }
;     int main(int argc, char **argv) { return cmk(argc); }
;
; main fc6ee653 (cq-opt f4379f18, measured): rc 0 with three M-A warnings. q has a
; measurement user, so the ptue frontier borrowed it as "a measured register, never
; touched": a is reversed and freed, q's `mul` is never `_unc`'d nor freed, and on
; s <= 100 (q never measured) `cqrt_ry_i32(x, -0.5)` runs while q = 3x is a live dead
; record of x — Ry(-.5)Ry(.5) no longer cancels.
;
; NOW: q stays borrowed (the plans read its label only), but a rail measured on SOME
; paths is not exempt from the CUT SET (`measuredOnEveryPath`: no measurement
; post-dominates it and the measured arm does not cover the s <= 100 path), so its
; `mul` is a cut record, hazardous (x is moved later, and q is not used after the
; move). No partition reverses it (M-B does not own a measured rail), so
; `uncompute`'s post-M-B check fails LOUDLY at the `mul`. The joint-cover twin
; (each arm measures q) lowers: lowering_uncompute_joint_measure_cut_record.ll; the
; no-move twin lowers too (@partial of lowering_uncompute_cut_record_benign.ll).
; RETIREMENT TRIGGER (L7): a schedule that uncomputes q on the unmeasured arm only
; (a reversal after the partial measurement reads q's collapsed label, which an
; `_unc` may — the 2026-10-05 ruling) would make this an ACCEPT.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function cmk i32 (i32): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate


define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @cmk(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @cmk(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #3
  %4 = mul nsw i32 %3, 3
  %5 = add nsw i32 %4, 2
  %6 = mul nsw i32 %5, 5
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 4.000000e-01) #3
  %8 = mul nsw i32 %5, 7
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #3
  %10 = icmp sgt i32 %0, 100
  br i1 %10, label %11, label %13

11:
  %12 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  br label %13

13:
  %14 = phi i32 [ %12, %11 ], [ 0, %1 ]
  %15 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #3
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #4
  %17 = add nsw i32 %16, %14
  ret i32 %17
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
