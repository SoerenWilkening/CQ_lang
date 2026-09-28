; spec_reject_predicted_classical_inner_clone.ll — DECLINE (bd test_C_libtooling-cepm (residual)).
; The predictor OVER-approximates through an INNER call's result: `h2(a,k) = h(a,k) * 2` with `h`
; the reading callee (classical return). `predictReturnTainted(h2, 01)` follows `a` into `h(a, k)`
; and on through its result to `h2`'s `ret` — TRUE — so `t = h2(q, m)` is tainted conservatively
; as before bd cepm, the 4.4 emitter mints a flag on it, `specialize()` proves the clone classical,
; and bd l3oi's fence refuses the integer read as a register. A SAFE over-decline that bd cepm does
; not remove (the predictor is not recursive). RETIREMENT TRIGGER (L8): a predictor that asks the
; inner callee's own prediction turns this into an ACCEPT — re-derive it (its twin, in2T.c,
; accepts), do not delete it; the l3oi fence then needs another subject.
;
; 6 TUs, each `clang -O1`, llvm-linked as tests/e2e/run_slice_multi.sh does.
; Caller TU (-include CQ.h):
;   int h(int a, int k);
;   int h2(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int t = h2(q, m); int r = m; if (t > 3) r = m + 5; return cq_measure(r) + cq_measure(q); }
; Library TU 1 (plain C):
;   /* h READS a (a call to g, an external here) and returns the CLASSICAL k + 1. */
;   void g(int a);
;   int h(int a, int k) { g(a); return k + 1; }
; Library TU 2 (plain C):
;   /* f2 is an external here: -O1 keeps the unused call and infers nothing. */
;   int f2(int a);
;   void g(int a) { f2(a); }
; Library TU 3 (plain C):
;   /* f3 is an external here: f2 gets no memory(none)/willreturn, so a call to f2
;      is a liveness ROOT of the pass. */
;   int f3(int a);
;   int f2(int a) { return f3(a) + 1; }
; Library TU 4 (plain C):
;   int f3(int a) { return a * 3; }
; Library TU 5 (plain C):
;   int h(int a, int k);
;   int h2(int a, int k) { int u = h(a, k); return u * 2; }
;
; Oracle 9a230646: the same DECLINE (byte-identical first error line).
; Hand-inlined twin (in2T.c) ACCEPTS: an over-decline, filed on bd cepm.
; Regenerate: docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/mkprobes.py + gen.sh in2C, then mkfix.py.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq taint escape: classical call result used as a quantum register

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call i32 @h2(i32 noundef %6, i32 noundef %5) #4
  %8 = icmp sgt i32 %7, 3
  %9 = add nsw i32 %5, 5
  %10 = select i1 %8, i32 %9, i32 %5
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  %12 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %13 = add nsw i32 %12, %11
  ret i32 %13
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  tail call void @g(i32 noundef %0) #4
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define void @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f2(i32 noundef %0) #4
  ret void
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @f2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f3(i32 noundef %0) #4
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @f3(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @h2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @h(i32 noundef %0, i32 noundef %1) #4
  %4 = shl nsw i32 %3, 1
  ret i32 %4
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0, !0}
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
