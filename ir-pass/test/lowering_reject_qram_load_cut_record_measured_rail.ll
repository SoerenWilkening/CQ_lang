; lowering_reject_qram_load_cut_record_measured_rail.ll — DECLINE (bd
; test_C_libtooling-r2j3.23, batch 053 unit D; the repro `q5`).
;
; SOURCE (`clang -O1` IR below):
;     static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};
;     __attribute__((noinline)) static int qk(int s) {
;       int k = s & 7; cq_theta(&k, 0.5);
;       int a = tbl[k]; int m = a >> 1; int v = m ^ 9;
;       int t = v * 5; cq_theta(&t, 0.4); int r = v * 7; cq_theta(&r, 0.2);
;       int mm = cq_measure(m); cq_theta(&k, -0.5); return mm + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return qk(argc); }
;
; main fc6ee653 (cq-opt f4379f18, measured): rc 0 with three M-A warnings, the QROM
; load `a = tbl[k]` never reversed nor freed before `cqrt_ry_i32(k, -0.5)`. The
; record is reachable from the terminals only through the MEASURED m, so the ptue
; borrow cuts it (with m = 1, k ∈ {0, 6} and a ∈ {3, 2} tell them apart).
;
; NOW: the load is a hazardous cut record (TerminalGroups.h, CUT RECORDS); no
; partition reverses it — the M-B interior partition still refuses a QRAM-load rail
; by scope (ChainWalk (I1)) — so `uncompute`'s post-M-B check fails LOUDLY at the
; load instead of compiling the wrong circuit.
; RETIREMENT TRIGGER (L7): admitting a QRAM-load rail in M-B (the batch-053 unit D
; route, prototyped and deferred: it changes the lowered output of the QROM PredMux
; family) discharges `a` right after `a >> 1`; flip this file to that ACCEPT.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function qk i32 (i32): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate


@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @qk(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @qk(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #3
  %4 = sext i32 %3 to i64
  %5 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %4
  %6 = load i32, ptr %5, align 4
  %7 = ashr i32 %6, 1
  %8 = xor i32 %7, 9
  %9 = mul nsw i32 %8, 5
  %10 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 4.000000e-01) #3
  %11 = mul nsw i32 %8, 7
  %12 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 2.000000e-01) #3
  %13 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  %14 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #3
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #4
  %16 = add nsw i32 %15, %13
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
