; lowering_reject_qram_load_cut_record_forced.ll — DECLINE (bd
; test_C_libtooling-r2j3.23, batch 053 unit D; R11 r8 probe p4 `fk`).
;
; SOURCE (`clang -O1` IR below):
;     static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};
;     __attribute__((noinline)) static int fk(int s) {
;       int p = s & 7; cq_theta(&p, 0.5); int x = (s >> 3) & 7; cq_theta(&x, 0.5);
;       int a = tbl[x]; int R = p + (a >> 4);
;       int t = R * 5; cq_theta(&t, 0.4); cq_theta(&p, -0.3);
;       int r = R * 7; cq_theta(&r, 0.2); cq_theta(&x, -0.5);
;       return cq_measure(p) + cq_measure(x); }
;     int main(int argc, char **argv) { (void)argv; return fk(argc); }
;
; main fc6ee653 (cq-opt f4379f18, measured): rc 0 with four M-A warnings. R is FORCED
; (r reads it after p's move) and the frontier fixpoint borrows it; M-B discharges
; `Y = a >> 4`, but the QROM load `a = tbl[x]`, cut by the forced borrow, stays
; before `cqrt_ry_i32(x, -0.5)`.
;
; NOW: the cut set of the COMMITTED plans names the load (the cut is taken after
; the fixpoint, so a forced borrow's cut counts like the first frontier's); it is
; hazardous and no partition reverses it, so `uncompute`'s post-M-B check fails
; LOUDLY at the load.
; RETIREMENT TRIGGER (L7): admitting a QRAM-load rail in M-B (follow-up) discharges
; `Y` then `a` after the `add`; flip this file to that ACCEPT.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function fk i32 (i32): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate


@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @fk(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @fk(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #3
  %4 = lshr i32 %0, 3
  %5 = and i32 %4, 7
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #3
  %7 = sext i32 %6 to i64
  %8 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %7
  %9 = load i32, ptr %8, align 4
  %10 = ashr i32 %9, 4
  %11 = add nsw i32 %10, %3
  %12 = mul nsw i32 %11, 5
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 4.000000e-01) #3
  %14 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -3.000000e-01) #3
  %15 = mul nsw i32 %11, 7
  %16 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 2.000000e-01) #3
  %17 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef -5.000000e-01) #3
  %18 = tail call i32 @cq_measure_si32(i32 noundef %14) #4
  %19 = tail call i32 @cq_measure_si32(i32 noundef %17) #4
  %20 = add nsw i32 %19, %18
  ret i32 %20
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
