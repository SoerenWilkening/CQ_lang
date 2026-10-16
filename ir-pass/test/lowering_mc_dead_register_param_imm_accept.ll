; lowering_mc_dead_register_param_imm_accept.ll — ACCEPT, in place (bd
; test_C_libtooling-dm7f.83.1). `int t = q + m; cq_theta(&t, .2)` with `q` a
; dead rotated register and `m` a function PARAMETER. WAS (main ef72239c):
; out of place, `q`'s old rail beside the kept `t`, then Ry on `t` (the r2j3.33
; wrong unitary, warning only); (5df5cd77, dm7f.83): loud, G4 refused the
; parameter immediate. NOW G4 is retired for a classical parameter: the pass
; claims `!cq.classical.params` and stage 2b vouches after CHECKING it
; (free_pairing_check.py `vouched_params`), so `t = q + m` is `cqrt_addc_i32(q, m)`
; on q's own rail and the Ry follows on it — the textbook circuit
; alloc; Ry(.5); addc(m); Ry(.2); measure. The twin cell closes: the lifted
; `t = h(q, m)` (spec_accept_consume_param_imm.ll) is in place too.
;
; Source: n1.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @slice(
; CHECK-SAME:  !cq.classical.params [[MD:![0-9]+]]
; CHECK:      [[H:%[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[H]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 [[H]], i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[H]], double 2.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 [[H]])
; CHECK-NOT:  cq_template_add_i32_hl
; CHECK:      [[MD]] = !{i32 0}
source_filename = "n1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = add nsw i32 %2, %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.000000e-01) #3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #4
  ret i32 %5
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #2 {
  %3 = add nsw i32 %0, 4
  %4 = tail call i32 @slice(i32 noundef %3)
  ret i32 0
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
