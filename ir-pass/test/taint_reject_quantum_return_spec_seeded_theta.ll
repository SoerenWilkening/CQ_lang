; taint_reject_quantum_return_spec_seeded_theta.ll — DECLINE (bd test_C_libtooling-9bhg).
;
; Pins that a `cq_theta` result is a KEEP root of `returnTaintIsSpecProvisional`'s
; counterfactual cone — i.e. that the predicate asks "does this return's taint
; derive ONLY from specialization sites?", not "is a specialization site anywhere
; upstream?". A TWO-TU module (caller TU `-include CQ.h`, llvm-linked with a
; plain-C library TU, as tests/e2e/run_slice_multi.sh builds one).
;
; `f` returns `cq_theta(t, .3)` where `t = h(q, m)` is a specialization site whose
; clone proves the classical `k + 1`: the SEED of the returned rotation is
; classical, the returned value is a fresh REGISTER regardless. The return is
; NOT provisional, so it crosses at propagation, `main`'s `G = f(m)` stores a
; tainted value, and the store-escape guard — an owner ABOVE both 3jru slots —
; speaks first, exactly as on 983f9361.
;
; The verdict is a decline either way; what this pins is the SLOT. If the theta
; stopped being a keep root, the return would be deferred as provisional, `main`
; would see `f(m)` as classical, no store escape would fire, and the module would
; be refused only by the LATE `declineQuantumReturnCalls` with the 3jru string —
; still safe (the late ask is total), but the predicate would have stopped meaning
; what it says.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int G;
;   __attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return cq_theta(t, .3); }
;   int main(int argc, char **argv) { int m = atoi(argv[1]); G = f(m); return 0; }
;
; Regenerate: clang -O1 -emit-llvm -S each TU as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='quantum value returned'
; CHECK: in function main {{.*}}: cq taint escape: tainted value stored to memory

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@G = local_unnamed_addr global i32 0, align 4

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #5
  %3 = tail call i32 @h(i32 noundef %2, i32 noundef %0) #5
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #5
  ret i32 %4
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @f(i32 noundef %5)
  store i32 %6, ptr @G, align 4, !tbaa !10
  ret i32 0
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
