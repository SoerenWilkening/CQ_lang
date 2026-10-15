; spec_reject_gate_sub_indirect_nonI32.ll — DECLINE (bd test_C_libtooling-p3kd.21).
; A gate subroutine reached only through a FUNCTION POINTER, returning its
; register as a `_Bool`:
;
;   __attribute__((noinline)) static bool rot(bool t) { cq_theta(&t, 0.2); return t; }
;   bool (*volatile pick)(bool) = rot;
;   cq_theta(&q, 0.5);  bool r = pick(q);
;
; Call-site compilation (SpecializeGateInline.h) inlines direct calls only, and
; `rot` has a use (its address), so it is not an export whose return may become
; its i32 handle (`isQuantumReturnExport`): the non-i32 tainted `ret` keeps the
; escape guard's decline. This is the fixture that pins `kMsgNonI32Return` since
; the export admission retired the three `lowering_reject_taint_escape_return_*`
; pins. An indirect quantum call is a goal-1 gap (follow-up filed from bd
; p3kd.21), not a physics decline. Mirrors the diagnostic character-for-character.
; `clang -O1 -include CQ.h` output verbatim.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq taint escape: tainted value returned at non-i32 width

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@pick = global ptr @rot, align 8
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: noinline nounwind ssp uwtable
define internal zeroext i1 @rot(i1 noundef zeroext %0) #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %0, double noundef 2.000000e-01) #4
  ret i1 %2
}

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  %2 = load volatile ptr, ptr @pick, align 8, !tbaa !6
  %3 = tail call zeroext i1 %2(i1 noundef zeroext %1) #5
  %4 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #5
  %5 = zext i1 %4 to i32
  %6 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %5)
  ret i32 0
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
