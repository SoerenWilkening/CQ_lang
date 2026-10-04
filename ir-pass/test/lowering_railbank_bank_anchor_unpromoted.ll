; lowering_railbank_bank_anchor_unpromoted.ll — the `Bank` VERDICT ANCHOR on a
; module the PROMOTER NEVER TOUCHES (bd `test_C_libtooling-de8n`, 2026-09-15).
; STILL A DECLINE: `Bank` falls through to `kMsgStore` this increment.
;
; ⚠ THIS IS THE CONTROL THAT KEEPS CLAUSE C7 FROM BEING A BLANKET DECLINE, AND IT
; IS THE REASON THE CLAUSE IS SPELLED AS TWO PROPERTIES OF THE SHAPE RATHER THAN AS
; "THE PROMOTER RAN". Rule 17 and the owner's 2026-09-11 ruling both apply: an
; over-decline of a valid circuit is a DEFECT, not a safety margin. The program
;
;   for (i = 0; i < 3; ++i) { b[i] = z; cq_theta(&b[i], 0.5); }
;   ...  s += cq_measure(b[i]);
;
; writes every cell UNCONDITIONALLY and never reads one inside the loop, so it is
; ALREADY in the shape the deferred type rewrite can serve — and the promoter
; correctly does nothing (its B8: no in-`L` load, nothing to forward; MEASURED
; `promo=0` on BOTH binaries). C7(a) holds because there is no in-loop read; C7(b)
; holds because the store's block dominates the latch and the latch is the only
; exiting block. Verdict `Bank`, with no promotion anywhere in the module.
;
; ⚠ SO "`Bank`" DOES NOT MEAN "THE PROMOTER RAN" AND MUST NOT BE RESTATED THAT WAY.
; It means the two properties C7 names. The INVARIANT the tree relies on is the
; other direction only — *the promoter's INPUT is `BankRaw`, its OUTPUT is `Bank`*
; (`RailBankPromote.cpp` B6) — and this file is the witness that the implication
; does not run backwards. `railbank_promote_reject_already_ssa.ll` pins the same
; program's promoter half (the stage ran and did not fire); this file pins the
; CARVE half, which that fixture does not check.
;
; MEASURED, ORACLE `0e280fc6…` vs SUBJECT `b6554935…`, same stage-1 file:
;   BOTH -> carve=[Bank] promo=0. This fixture is GREEN ON BOTH BINARIES BY
;   DESIGN — it is a no-movement control, and its value is that it goes RED the
;   day C7 is tightened into a promotion test.
;
; ⚠ L8 RETIREMENT TRIGGER: when the L-1a taint rule + type rewrite + D5 allow-list
;   land, `Bank` stops falling through to `kMsgStore` and THIS file's RUN line
;   becomes an ACCEPT — a per-trip `cqrt_alloc_i1`/`cqrt_ry_i1` cascade with one
;   `cqrt_measure_i1` per cell and NO promotion in the module. Re-derive it then;
;   do NOT delete it. It is the cheapest possible end-to-end check that the type
;   rewrite does not secretly depend on the promoter having run.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackA/probes/p2_uncond_store_no_read.c`.
;
; ⚠⚠ THE L8 RETIREMENT TRIGGER ABOVE HAS FIRED, AND ITS PREDICTION WAS
; CHARACTER-FOR-CHARACTER RIGHT.  bd `xdu2` W1's SECOND HALF landed 2026-09-15
; and this file is now an ACCEPT: a per-trip `cqrt_alloc_i1`/`cqrt_ry_i1`
; cascade, one `cqrt_measure_i1` per cell, and NO PROMOTION ANYWHERE IN THE
; MODULE.  Re-derived, not deleted, in the same change.
;
; ⚠ AND IT IS STILL THE CONTROL IT WAS BUILT TO BE, now from the other side: it
; is the cheapest end-to-end check that the TYPE REWRITE does not secretly
; depend on the promoter having run.  `CQ_RAILBANK_DBG` prints NO
; `promote bank` line for this module (B8: no in-`L` load, nothing to forward)
; and it compiles anyway.
;
; ⚠ IT IS ALSO THE NON-`main` WITNESS FOR THE D1 SPINE DOOR.  `@slice` is not
; `main`, so `FreePoint`'s `main` short-circuit does NOT apply: without
; `isTerminalHandle` refusing a rail parked in a bank cell (`railStoredToRailBank`,
; `ChainWalk.cpp`), the surviving store falls to `FirstUnrecognized` and this
; module LOUD-DECLINES `cq uncompute: tainted handle reaches an unrecognized
; user`.  Measured over an 80-slice sample, **76 of 80** `tests/e2e/slice_*.c`
; carry quantum work outside `main`, so that door is the common case and not an
; edge.  The negative on `cqrt_free` below is the other half: the rail is LEFT ALLOCATED
; (Rule 6), never adjointed and never freed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR    --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CALLOC --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CMEAS  --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS  --input-file=%t.ll %s
; RUN: env CQ_CTRL_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:     > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG --input-file=%t.dbg %s \
; RUN:     --implicit-check-not='railbank [BankRaw]' --implicit-check-not='cq rail bank:'
; RUN: %filecheck --check-prefix=NOPROMO --input-file=%t.dbg %s

; The carve still anchors `Bank` on the store, and the store is now OWNED rather
; than declined.
; DBG: CQ_CTRL_DBG: railbank [Bank] cells=3 abi=i8 trips=3 at:

; The promoter never ran on this module — that is the whole point of the file.
; NOPROMO-NOT: CQ_RAILBANK_DBG: promote bank

; The cells are RUNTIME HANDLES after the type rewrite (Rule 15: always i32),
; the record is minted on the object, and the storage casts are GONE — the
; per-cell `zext i1 -> i8` never reaches `lowerOps`, so no second rail is minted.
; IR: %{{.*}} = alloca [3 x i32], align 4, !cq.railbank
; IR: call i32 @cqrt_alloc_i1(i1 false)
; IR: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; IR: store i32 %h, ptr %{{.*}}, align 4
; IR: load i32, ptr %{{.*}}, align 4
; IR: call i1 @cqrt_measure_i1(i32 %{{.*}})

; ⚠ ONE WHOLE-FILE PREFIX PER COUNTED SYMBOL, AND THAT IS TWO RULES AT ONCE.
; (a) A positive `CHECK-COUNT` inside a NEGATIVE prefix WINDOWS every negative
; after it (Rule 12 hygiene defect (a)), so the counts are not in `NOTS`.
; (b) Two `*-COUNT-2` directives in ONE prefix are ORDERED — the second scans
; only from where the first stopped — and this module interleaves two functions,
; so `@slice`'s measure sits ABOVE `@main`'s alloc.  MEASURED: sharing a prefix
; makes the measure count fail `(2 out of 2)` on a correct module.  Two of each
; because the module defines TWO functions (`@slice` and `@main`), each with one
; ROLLED per-trip mint site.
; CALLOC-COUNT-2: call i32 @cqrt_alloc_i1(
; CMEAS-COUNT-2: call i1 @cqrt_measure_i1(

; PURE NEGATIVES.  No storage cast survived to `lowerOps` (either direction), no
; cell is still a byte, and the parked rail is left allocated rather than freed.
; NOTS-NOT: cq_template_zext
; NOTS-NOT: cq_template_trunc
; NOTS-NOT: cqrt_free
; NOTS-NOT: 3 x i8

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %2) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %2, i8 0, i64 3, i1 false)
  br label %3

3:                                                ; preds = %1, %3
  %4 = phi i64 [ 0, %1 ], [ %8, %3 ]
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  %6 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %4
  %7 = zext i1 %5 to i8
  store i8 %7, ptr %6, align 1, !tbaa !6
  %8 = add nuw nsw i64 %4, 1
  %9 = icmp eq i64 %8, 3
  br i1 %9, label %12, label %3, !llvm.loop !10

10:                                               ; preds = %12
  %11 = add nsw i32 %20, %0
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %2) #4
  ret i32 %11

12:                                               ; preds = %3, %12
  %13 = phi i64 [ %21, %12 ], [ 0, %3 ]
  %14 = phi i32 [ %20, %12 ], [ 0, %3 ]
  %15 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %13
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !13, !noundef !14
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %17) #4
  %19 = zext i1 %18 to i32
  %20 = add nuw nsw i32 %14, %19
  %21 = add nuw nsw i64 %13, 1
  %22 = icmp eq i64 %21, 3
  br i1 %22, label %10, label %12, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %2

2:                                                ; preds = %2, %0
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  %5 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %3
  %6 = zext i1 %4 to i8
  store i8 %6, ptr %5, align 1, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 3
  br i1 %8, label %9, label %2, !llvm.loop !10

9:                                                ; preds = %2, %9
  %10 = phi i64 [ %18, %9 ], [ 0, %2 ]
  %11 = phi i32 [ %17, %9 ], [ 0, %2 ]
  %12 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %10
  %13 = load i8, ptr %12, align 1, !tbaa !6, !range !13, !noundef !14
  %14 = trunc nuw i8 %13 to i1
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %14) #4
  %16 = zext i1 %15 to i32
  %17 = add nuw nsw i32 %11, %16
  %18 = add nuw nsw i64 %10, 1
  %19 = icmp eq i64 %18, 3
  br i1 %19, label %20, label %9, !llvm.loop !15

20:                                               ; preds = %9
  %21 = add nuw nsw i32 %17, 2
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %21
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !11, !12}
