; spec_intermediate_unc_terminal_union_forced_root.ll — ACCEPT (bd
; test_C_libtooling-p3kd.13, R11 review round 9, F2): a forced record whose other
; ancestor is a register ROOT. Reviewer probe p2 `fr2`.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int fr2(int s) {
;       int p = s & 7; cq_theta(&p, 0.5);
;       int k = (s >> 3) & 7; cq_theta(&k, 0.3);
;       int R = p + k;
;       int t = R * 5; cq_theta(&t, 0.4);
;       cq_theta(&p, -0.3);
;       int r = h(R); cq_theta(&r, 0.2);
;       return cq_measure(p); }
;     int main(int argc, char **argv) { (void)argv; return fr2(argc); }
;
; NEW ACCEPT. The template terminal t alone leaves R open (the clone call h(R)
; consumes it), so `TmplOk` is false and main DECLINES this module (rc 1, `dead
; chain would free a measured register`, cq-opt 716269bc). The union {t, r} closes
; R. Measured upstream (p, measured on every path), its first frontier borrows p;
; the whole-group retry sees p moved (`Ry(p, -0.3)`) inside R's window, and the
; fixpoint FORCES R (h(R) reads it after the move) and borrows it. That cuts R's
; ancestors: p's own Rys (exempt: p is measured on every path) and k's prep Ry —
; k is a `cqrt_alloc` register ROOT, whose own gates record no other register, so
; they do not count in `GroupProbe::Cut` either. Nothing else is cut, so the union
; is emitted: t's Ry, `mul_unc` and free, then r's Ry, twin and free; R (the
; forced record, bd 01po.8's ruled disposition) and k stay allocated.
; The all-template twin `fr2k` (probe p2, `int r = R * 7`) is main's own planner:
; main lowers it (rc 0) with this stream gate for gate, `mul_unc` where @fr2 has
; the twin `__cq_q_h_1_unc` (R11 r9 reviewer, measured).
; RED (snapshot 9be748ef, R11 r9 reviewer, measured: rc 1, main's line): r8's
; final-frontier `Cut` counted k's own Ry as a cut record. GREEN: the r9 root
; exemption; the @fr2 stream below is byte-identical to snapshot 1b5e9b82's (the
; state R11 r8 reviewed), which accepted this program. Three unlocated M-A `live derived record`
; warnings fire (R11 r3 F2's disclosed class); errors are pinned absent.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; NOERR-NOT: error

; CHECK-LABEL: define internal fastcc i32 @fr2(
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 5.000000e-01)
; CHECK:      %[[K:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[K]], double 3.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[P]], i32 %[[K]])
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[T]], double -4.000000e-01)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T]], i32 %[[R]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double -3.000000e-01)
; CHECK-NEXT: %[[RR:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[R]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[RR]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[RR]], double -2.000000e-01)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[RR]], i32 %[[R]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[RR]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[P]])
; The CHECK-NEXT chain covers every line from k's alloc to the measure; the forced
; record R and the root k stay allocated (never adjointed, un-rotated or freed):
; CHECK-NOT:  add_i32_unc
; CHECK-NOT:  call void @cqrt_ry_i32(i32 %[[K]]
; CHECK-NOT:  call void @cqrt_free(i32 %[[R]])
; CHECK-NOT:  call void @cqrt_free(i32 %[[K]])
; CHECK:      ret i32

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) #0 {
  %3 = tail call fastcc i32 @fr2(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @fr2(i32 noundef %0) unnamed_addr #1 {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #4
  %4 = lshr i32 %0, 3
  %5 = and i32 %4, 7
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 3.000000e-01) #4
  %7 = add nsw i32 %6, %3
  %8 = mul nsw i32 %7, 5
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 4.000000e-01) #4
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -3.000000e-01) #4
  %11 = tail call fastcc i32 @h(i32 noundef %7)
  %12 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 2.000000e-01) #4
  %13 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) #2

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

declare i32 @cq_measure_si32(i32 noundef) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
