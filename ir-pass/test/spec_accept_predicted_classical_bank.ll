; spec_accept_predicted_classical_bank.ll — ACCEPT (bd test_C_libtooling-cepm (bd d88e's `a03`)).
; THE READING CALLEE. `h` READS its quantum argument — through a call to `g`, whose own
; callee `f2` is an external in `g`'s TU, so `-O1` infers no `memory(none)`/`willreturn`
; for `g` and the pass's liveness (DeadValueLiveness.h) keeps the call as a ROOT, so bd
; vsfp's dead-argument drop does NOT fire — and returns the CLASSICAL `k + 1`.
; `predictReturnTainted(h, 01)` is FALSE (the masked parameter reaches neither the
; `ret` nor a conditional terminator), so since bd cepm propagation leaves the call's
; RESULT classical (`specCallResultPredictedClassical`, SpecializeClone.h): no stage
; before `specialize()` reads it as a register, and the clone `@__cq_q_h_01` (built
; unchanged) returns the classical value. Before bd cepm the result was tainted
; CONSERVATIVELY and scrubbed only after both control rounds.
; Here each result is STORED to an ordinary array (`b[i] = h(q, i)`) and later `cq_measure`d:
; a classical store and a classical `cq_measure` (bd 21mg — the value itself, no gate). No rail
; bank is built. ⚠ stage 2b (tools/free_pairing_check.py) CANNOT adjudicate this module: it models
; every `@__cq_q_*` result as a rail and refuses a store of one to unmarked memory
; (`L1-rail-stored-to-unmarked-memory`) — an instrument gap filed with this change, not a defect
; of the stream; the traces were compared by hand.
;
; 5 TUs, each `clang -O1`, llvm-linked as tests/e2e/run_slice_multi.sh does.
; Caller TU (-include CQ.h):
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = m; cq_theta(&q, .5); int b[4]; for (int i = 0; i < 4; i++) b[i] = h(q, i); int s = 0; for (int i = 0; i < 4; i++) s += cq_measure(b[i]); return s + cq_measure(q); }
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
;
; Oracle 9a230646: DECLINE `cq rail bank: a cell parks a value that is not a rail handle`.
; Hand-inlined twin (a03T.c) is TRACE-IDENTICAL under argv `5 7` and `2 9` (compared by hand; the
; twin passes stage 2b STRICT).
; Regenerate: docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/cepm_probes/mkprobes.py + gen.sh a03C, then mkfix.py.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.bank.ll
; RUN: %filecheck %s < %t.bank.ll
; RUN: %filecheck --check-prefix=MEAS %s < %t.bank.ll
; CHECK-LABEL: define i32 @main(
; CHECK:       %[[T:[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK:       store i32 %[[T]], ptr
; CHECK-NOT:   railbank
; CHECK:       %[[L:[0-9]+]] = load i32, ptr
; CHECK-NEXT:  add nsw i32 %[[L]],
; CHECK:       ret i32
; ROUND 2 (Rule-13 r1B F-r1B-6): the property that separates right from wrong here is that
; `cq_measure(b[i])` over a loaded CLASSICAL integer lowers to the VALUE (bd 21mg) — the load feeds
; the sum directly (CHECK-NEXT above) — and that the ONLY measurement gate in the module is the one
; on `q`'s handle. MEAS is a whole-file prefix (Rule 12 (a): counts never inside a negative prefix):
; exactly one measurement CALL, and none after it (a regression that measured each loaded integer
; as a handle — the Rule-3 wire crossing — would add three).
; MEAS-COUNT-1: call i32 @cqrt_measure_i32(
; MEAS-NOT:     call i32 @cqrt_measure_i32(

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  %5 = load ptr, ptr %4, align 8, !tbaa !6
  %6 = tail call i32 @atoi(ptr nocapture noundef %5)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  br label %8

8:                                                ; preds = %8, %2
  %9 = phi i64 [ 0, %2 ], [ %13, %8 ]
  %10 = trunc nuw nsw i64 %9 to i32
  %11 = tail call i32 @h(i32 noundef %7, i32 noundef %10) #5
  %12 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %9
  store i32 %11, ptr %12, align 4, !tbaa !10
  %13 = add nuw nsw i64 %9, 1
  %14 = icmp eq i64 %13, 4
  br i1 %14, label %18, label %8, !llvm.loop !12

15:                                               ; preds = %18
  %16 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  %17 = add nsw i32 %16, %24
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret i32 %17

18:                                               ; preds = %18, %8
  %19 = phi i64 [ %25, %18 ], [ 0, %8 ]
  %20 = phi i32 [ %24, %18 ], [ 0, %8 ]
  %21 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %19
  %22 = load i32, ptr %21, align 4, !tbaa !10
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #5
  %24 = add nsw i32 %23, %20
  %25 = add nuw nsw i64 %19, 1
  %26 = icmp eq i64 %25, 4
  br i1 %26, label %15, label %18, !llvm.loop !15
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  tail call void @g(i32 noundef %0) #5
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define void @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f2(i32 noundef %0) #5
  ret void
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @f2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f3(i32 noundef %0) #5
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @f3(i32 noundef %0) local_unnamed_addr #4 {
  %2 = mul nsw i32 %0, 3
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0}
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
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
