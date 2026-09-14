; lowering_railbank_bank_anchor_uninit.ll — the `Bank` VERDICT ANCHOR (bd `test_C_libtooling-xdu2` / L-1a W1).
; STILL A DECLINE: `Bank` falls through to `kMsgStore` this increment.
;
; OWNER RULING D1 — `bool b[3];` with NO initializer at all is a rail bank.
;
; The owner's file writes `bool b0[3];` with no `= {0}`, so a C1 clause that required
; a proven constant-zero initializer would OVER-DECLINE the very program the increment
; exists to compile. RULED 2026-09-14 (`DECISIONS.md` D1): extend bd `z9t1`'s
; undef-seed rule to the bank's per-cell seed — an uninitialized cell's seed
; normalizes to the type's concrete zero AT THE ALLOCATION, the same rule
; `normalizeUndefRotationSeed` already ships for a scalar `undef` seed at a SOURCE
; `cq_theta`.
;
; ⚠ THIS IS A DELIBERATE COMPOSITION WITH bd `z9t1`, AND IT INHERITS THAT RULING'S
; DISCLOSURE: a program that was LOUDLY REFUSED compiles SILENTLY, no fence can
; separate the readings after `-O1`, and NO WARNING IS ADDED (owner, 2026-09-14:
; "both codes are supposed to compie!! also no warnings."). The disclosure in the
; two-halves form `CLAUDE.md` §4c requires — the rival reading stated as a PROGRAM,
; and why it has NO LOWERING TO BE ROBBED OF — is `IMPL_A.md` §6. Its three
; retirement triggers now have a SECOND customer; re-read them before touching this.
;
; ⚠ ITS COMPLEMENT is `lowering_reject_railbank_nonzero_init.ll`: a NON-zero
; initializer still declines. Read the two together.
;
; ⚠ THIS IS THE `Bank`-VERDICT ANCHOR, AND IT EXISTS BECAUSE THE VERDICT'S
; OBSERVABLE BEHAVIOUR IS TODAY IDENTICAL TO DOING NOTHING AT ALL. Rule 12 hygiene
; defect (c) — "a decline fixture that goes green because its subject no longer
; exists pins nothing" — is the live hazard for this path: the module still declines
; `cq taint escape: tainted value stored to memory`, exactly as it does on the
; ORACLE, so a fixture checking only that string would pin NOTHING. What makes it
; non-vacuous is the env-gated `CQ_CTRL_DBG` line, which is byte-ABSENT on the
; ORACLE (`cq-opt` sha256 5c6f7490…) and present on the subject (bc886235…). MEASURED both
; ways; the `--implicit-check-not` on the RUN line closes the other direction.
;
; ⚠ THE `Bank` VERDICT STILL DECLINES, AND THAT IS A CORRECTNESS REQUIREMENT, NOT A
; SCOPE PREFERENCE. The taint rule (a `load` from a bank cell is tainted), the
; `[N x i1]` → `[N x i32]` type rewrite and the D5 consumer allow-list are the
; second half of L-1a. Until they land, an ACCEPTED bank is a SILENT MISCOMPILE by a
; named mechanism (`SCOPE_L1a.md` §4.4(D)): `cq_measure(b[i])` on an UNTAINTED load
; takes `MeasureLowering`'s classical split and emits no gate, no symbol and NO TRACE
; LINE — and the golden byte-diff cannot see a measurement that was never emitted.
; This is a STAGED LANDING of one capability, not Rule 17's punt.
;
; ⚠ L8 RETIREMENT TRIGGER, character-for-character as the thing that will fire:
;   "When the L-1a taint rule + type rewrite + D5 allow-list land (bd `xdu2`, the
;   second half), the `Bank` verdict stops falling through to `kMsgStore` and this
;   file's RUN line becomes an ACCEPT whose emitted stream is the per-trip
;   `cqrt_alloc_<W>` / `cqrt_ry_<W>` cascade with one `cqrt_measure_<W>` per cell.
;   Re-derive it then; do NOT delete it."
;
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackL/probes/L7_array_uninit.c`:
;   /* the array with NO initializer — the Track U (z9t1) undef-seed interaction */
;   #include "CQ.h"
;   int main(void){ int a=5; bool b[3];
;     for(int i=0;i<3;++i){ if(a>=3) b[i]=cq_theta(b[i],0.5); if(b[i]) a-=3; }
;     int s=cq_measure(a); for(int i=0;i<3;++i) s+=cq_measure(b[i]); return s; }
;
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank:'
; CHECK: CQ_CTRL_DBG: railbank [Bank] cells=3 abi=i8 trips=3 at:
; CHECK: cq taint escape: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #3
  br label %4

2:                                                ; preds = %14
  %3 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  br label %23

4:                                                ; preds = %0, %14
  %5 = phi i64 [ 0, %0 ], [ %20, %14 ]
  %6 = phi i32 [ 5, %0 ], [ %19, %14 ]
  %7 = icmp sgt i32 %6, 2
  br i1 %7, label %8, label %14

8:                                                ; preds = %4
  %9 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 5.000000e-01) #3
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %9, align 1, !tbaa !6
  br label %14

14:                                               ; preds = %8, %4
  %15 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = add nsw i32 %6, -3
  %19 = select i1 %17, i32 %18, i32 %6
  %20 = add nuw nsw i64 %5, 1
  %21 = icmp eq i64 %20, 3
  br i1 %21, label %2, label %4, !llvm.loop !12

22:                                               ; preds = %23
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #3
  ret i32 %31

23:                                               ; preds = %2, %23
  %24 = phi i64 [ 0, %2 ], [ %32, %23 ]
  %25 = phi i32 [ %3, %2 ], [ %31, %23 ]
  %26 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %24
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %28) #3
  %30 = zext i1 %29 to i32
  %31 = add nsw i32 %25, %30
  %32 = add nuw nsw i64 %24, 1
  %33 = icmp eq i64 %32, 3
  br i1 %33, label %22, label %23, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
