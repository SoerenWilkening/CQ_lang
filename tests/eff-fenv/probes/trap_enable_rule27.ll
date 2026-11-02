; cq-a63l (CR rule 23 at f684858, cq-hzji): feenableexcept/fedisableexcept are not C17 and have no musl
; body: rule 27 callees (a declared clone when handed a quantum argument), never rule 23 state; the
; quantum flags after a classical feenableexcept are the ordinary rule 23 construction. Source:
; trap_enable_rule27.c (clang 19.1.7 -O1).
; CHECK traps_then_flags: tail call i32 @feenableexcept(i32 noundef 4)
; CHECK traps_then_flags: call i32 @cq_template_fdiv_f64_hl_rm_exc(
; CHECK trap_quantum_arg: call i32 @__cq_q_feenableexcept_1(i32 %{{x}}, i32 4)
source_filename = "/tmp/traps.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @traps_then_flags(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @feenableexcept(i32 noundef 4) #3
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef 1.000000e+00) #4
  %5 = tail call double @llvm.experimental.constrained.fdiv.f64(double %4, double %1, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  %6 = tail call i32 @fetestexcept(i32 noundef 4) #3
  %7 = icmp ne i32 %6, 0
  %8 = zext i1 %7 to i32
  %9 = tail call double @cq_measure_f64(double noundef %5) #3
  %10 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %9, metadata !"fpexcept.strict") #5
  %11 = add nsw i32 %10, %8
  ret i32 %11
}

declare i32 @feenableexcept(i32 noundef) local_unnamed_addr #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #2

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @trap_quantum_arg(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 63
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 1.000000e+00) #4
  %4 = tail call i32 @feenableexcept(i32 noundef %3) #3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  ret i32 %5
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { nounwind strictfp }
attributes #4 = { nomerge nounwind strictfp }
attributes #5 = { strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
