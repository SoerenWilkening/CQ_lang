; taint_accept_classical_decl_literals.ll — ACCEPT (bd test_C_libtooling-3jru / xdu2.13).
;
; Rule-13 round 3 r13 (green): literals computed through DECLARATIONS
; (`abs` → `@llvm.abs`, `strlen`) and a defined CLASSICAL helper `tw`: none returns
; a register, so the 3jru refusal is silent and both mixed selects lower through
; `cq_template_and_i1_hl` literals.
;
; Source (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   #include <string.h>
;   __attribute__((noinline)) int tw(int k) { return k * 3; }
;   __attribute__((noinline)) static int slice(int m, int n, const char *s) {
;     int q = cq_theta(0, 0.5);
;     int a = 7;
;     if ((q > 1) & (abs(m) == n) ) a += 3;
;     if ((q > 2) & ((int)strlen(s) == tw(n))) a += 1;
;     return cq_measure(q) + cq_measure(a);
;   }
;   int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2]), argv[1]); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: error
; CHECK: call i32 @cq_template_and_i1_hl(i32 %{{.*}}, i1 zeroext %{{.*}})
; The second mixed `and` reaches the DATA path (`lowerOps`), whose `_hl` literal
; carries no `zeroext` (bd ix2v, unchanged by this change).
; CHECK: call i32 @cq_template_and_i1_hl(i32 %{{.*}}, i1 %{{.*}})
; CHECK-NOT: quantum value returned

; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r3/r13_ok_decl.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r3/r13_ok_decl.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @tw(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #1 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call fastcc i32 @slice(i32 noundef %5, i32 noundef %8, ptr noundef %4)
  ret i32 %9
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0, i32 noundef %1, ptr nocapture noundef readonly %2) unnamed_addr #2 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #7
  %5 = icmp sgt i32 %4, 1
  %6 = tail call i32 @llvm.abs.i32(i32 %0, i1 true)
  %7 = icmp eq i32 %6, %1
  %8 = and i1 %7, %5
  %9 = select i1 %8, i32 10, i32 7
  %10 = icmp sgt i32 %4, 2
  %11 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %2) #7
  %12 = trunc i64 %11 to i32
  %13 = tail call i32 @tw(i32 noundef %1)
  %14 = icmp eq i32 %13, %12
  %15 = and i1 %10, %14
  %16 = zext i1 %15 to i32
  %17 = add nuw nsw i32 %9, %16
  %18 = tail call i32 @cq_measure_si32(i32 noundef %4) #7
  %19 = tail call i32 @cq_measure_si32(i32 noundef %17) #7
  %20 = add nsw i32 %19, %18
  ret i32 %20
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #5

; Function Attrs: mustprogress nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr nocapture noundef) local_unnamed_addr #6

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #6 = { mustprogress nofree nounwind willreturn memory(argmem: read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { nounwind }

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
