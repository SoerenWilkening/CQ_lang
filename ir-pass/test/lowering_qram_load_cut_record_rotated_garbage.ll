; lowering_qram_load_cut_record_rotated_garbage.ll — ACCEPT WITH WARNINGS, the
; record LEFT ALLOCATED (bd test_C_libtooling-r2j3.23, batch 053 unit D; owner
; ruling 2026-10-03, owner-ruling-garbage-realizable-compiles). Unit D probe q5r:
; the r2j3.23 repro with the cut QROM record itself rotated before its reader.
;
; SOURCE (`clang -O1` IR below):
;     static const int tbl[8] = {3,1,4,1,5,9,2,6};
;     __attribute__((noinline)) static int qk(int s) {
;       int k = s & 7; cq_theta(&k, 0.5);
;       int a = tbl[k]; cq_theta(&a, 0.3); int m = a >> 1; int v = m ^ 9;
;       int t = v * 5; cq_theta(&t, 0.4);
;       int mm = cq_measure(m);
;       cq_theta(&k, -0.5);
;       return mm + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return qk(argc); }
;
; WHY THIS IS NOT r2j3.23's HAZARD. The load record `a` is cut by the measured m
; (the ptue borrow), and k is moved later — but `a` carries an Ry that its reader
; `m = a >> 1` then recorded. No schedule returns `a` to |0⟩: un-rotating it acts on
; m's copy of the rotated label (the conjugation the 2026-10-05 ruling excludes), and
; m is the user's measured register. The program's only realization leaves `a`
; allocated and entangled, and the 2026-10-03 ruling's fallback for exactly that is
; to keep it and WARN (the M-A `non-diagonal gate over a live derived record` guard
; does, twice), never to decline. So `isHazardousCutRecord` exempts a rail carrying a
; non-permutation gate a later reader recorded (TerminalGroups.h), and this module
; lowers as main fc6ee653 lowered it (rc 0, the same two warnings). The unrotated
; twin is a hazardous cut record and fails loudly (no partition reverses a QRAM
; load yet): lowering_reject_qram_load_cut_record_measured_rail.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; WARN-NOT: error
; WARN: warning: {{.*}}in function qk i32 (i32): cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: error
; CHECK-LABEL: define internal fastcc i32 @qk(
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[A]], double 3.000000e-01)
; CHECK-NOT:  cqrt_qram_load_i32_unc
; CHECK-NOT:  call void @cqrt_free(i32 %[[A]])
; CHECK:      ret i32


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
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 3.000000e-01) #3
  %8 = ashr i32 %7, 1
  %9 = xor i32 %8, 9
  %10 = mul nsw i32 %9, 5
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 4.000000e-01) #3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  %13 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  %15 = add nsw i32 %14, %12
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
