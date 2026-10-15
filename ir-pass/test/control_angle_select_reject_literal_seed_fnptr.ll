; control_angle_select_reject_literal_seed_fnptr.ll — DECLINE (bd
; test_C_libtooling-dm7f.54, item A2; the bd 4e4p function-pointer route, plain C
; at -O1):
;
;     typedef int (*thf)(int, double);
;     bool b = 0; cq_theta(&b, .4); thf f = cq_theta_si32;
;     int r = f(6, b ? .7 : .3);
;
; `-O1` devirtualizes the call to `cq_theta_si32`, but the CALL SITE carries no
; `nomerge` (attribute group `#3 = { nounwind }`; clang puts `nomerge` on direct
; call sites only, and this one was indirect when SimplifyCFG ran). The
; declaration-carries-it case is `..._reject_literal_seed_callee_nomerge.ll`. The literal seed is
; therefore refused (`angleSelectLiteralSeedAdmissible` reads the call-site list
; only), with the drbq.13 string.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation angle under quantum control

define i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #2
  %2 = select i1 %1, double 0x3FE6666666666666, double 3.000000e-01
  %3 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef %2) #3
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #3
  %6 = zext i1 %5 to i32
  %7 = add nsw i32 %4, %6
  ret i32 %7
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
