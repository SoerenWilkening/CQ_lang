; railbank_accept_bool_prep_measureloop.ll — THE CANONICAL W1 ACCEPT.
;
; bd `xdu2` / L-1a Increment W1, THE SECOND HALF (Track B, session 2026-09-15):
; the TAINT RULE (a `load` from a `!cq.railbank` alloca is tainted), the
; `[N x cell]` -> `[N x i32]` TYPE REWRITE and the D5 consumer ALLOW-LIST.  All
; three land together; any two of them is a silent miscompile.
;
; ⚠ THE MISCOMPILE THIS FILE EXISTS AGAINST, REPRODUCED WITH A TRACE BEFORE THE
; FIX (`trackB/IMPL_B2.md` §1): with pieces 2+3 and WITHOUT piece 1, this exact
; program gives `opt` exit 0, STRICT stage 2b `0 violation(s), 0 unproven`, a
; plausible SIX-line trace of three minted and rotated rails — and its three
; `cq_measure(b0[i])` calls emit NOTHING AT ALL, because `MeasureLowering`'s
; classical split on an UNTAINTED operand emits no gate, no symbol and no trace
; line.  A GOLDEN BYTE-DIFF CANNOT SEE A MEASUREMENT THAT WAS NEVER EMITTED,
; which is why the count below is a positive `CHECK-COUNT` in its own whole-file
; prefix and not a `CHECK-NOT` anywhere.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `…/session-2026-09-15-orchestrator/trackB/probes/b12_bank_bool_measureloop.c`:
;   #include "CQ.h"
;   int main(void) {
;       bool b0[3]; int s = 0;
;       for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
;       for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
;       return s;
;   }
;
; ⚠ THE BANK IS UNINITIALISED (`bool b0[3];`, no `= {0}`) — owner ruling D1,
; admitted by C6 TOTALITY alone, NOT by bd `z9t1` (whose
; `normalizeUndefRotationSeed` does not reach a MEMORY seed).  The R2 obligation
; that the two spellings emit the same stream is discharged at the e2e layer by
; `e2e-slice-railbank-uninit-zeroinit-twin`, on TRACES, because the zero-init
; twin carries an extra `llvm.memset` that an IR diff would report and a trace
; cannot see.  MEASURED: byte-identical, equal sha256, 0 divergences.
;
; ⚠ THE EMITTED STREAM IS BYTE-IDENTICAL TO THE FLAT TWIN's.  Track I's
; `w1_flat_prep_only.c` (three scalar `_Bool`s, three preps, three measures)
; produces exactly these 9 trace lines, and the bank reproduces them at
; identical trip count — the byte-identity witness `SCOPE_L1a.md` §5 asked for.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR     --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CALLOC --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CMEAS  --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS   --input-file=%t.ll %s
; RUN: env CQ_CTRL_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:     > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG --input-file=%t.dbg %s \
; RUN:     --implicit-check-not='railbank [BankRaw]' --implicit-check-not='cq rail bank:'

; The carve owns the store (it no longer falls through to `kMsgStore`).
; DBG: CQ_CTRL_DBG: railbank [Bank] cells=3 abi=i8 trips=3 at:

; THE OBJECT is retyped to runtime handles and carries the membership record;
; the storage cast is GONE on BOTH sides (the write's `zext i1 -> i8` and the
; read's `trunc i8 -> i1`), so nothing reaches `lowerOps` to mint a second rail;
; and `lowerMeasures` gets the `i32` handle its quantum branch requires.
; IR: alloca [3 x i32], align 4, !cq.railbank
; IR: %h = call i32 @cqrt_alloc_i1(i1 false)
; IR: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; IR: store i32 %h, ptr %cq.bank.addr, align 4
; IR: load i32, ptr %{{.*}}, align 4
; IR: call i1 @cqrt_measure_i1(i32 %{{.*}})

; ⚠ ONE WHOLE-FILE PREFIX PER COUNTED SYMBOL.  (a) A positive count inside a
; NEGATIVE prefix windows every negative after it (Rule 12 hygiene defect (a)).
; (b) Two counts in ONE prefix are ORDERED, which would make them depend on
; block layout.  ROLLED, so ONE mint site and ONE measure site in the IR — the
; three-per-run rails are the trip count's, not the IR's.
; CALLOC-COUNT-1: call i32 @cqrt_alloc_i1(
; CMEAS-COUNT-1: call i1 @cqrt_measure_i1(

; PURE NEGATIVES.
; NOTS-NOT: cq_template_zext
; NOTS-NOT: cq_template_trunc
; NOTS-NOT: cqrt_free
; NOTS-NOT: 3 x i8

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #3
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]
  %4 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 5.000000e-01) #3
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %4, align 1, !tbaa !6
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 3
  br i1 %10, label %12, label %2, !llvm.loop !12

11:                                               ; preds = %12
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #3
  ret i32 %20

12:                                               ; preds = %2, %12
  %13 = phi i64 [ %21, %12 ], [ 0, %2 ]
  %14 = phi i32 [ %20, %12 ], [ 0, %2 ]
  %15 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %13
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %17) #3
  %19 = zext i1 %18 to i32
  %20 = add nuw nsw i32 %14, %19
  %21 = add nuw nsw i64 %13, 1
  %22 = icmp eq i64 %21, 3
  br i1 %22, label %11, label %12, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

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
