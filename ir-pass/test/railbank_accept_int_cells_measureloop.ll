; railbank_accept_int_cells_measureloop.ll — W1's SECOND HALF, THE WIDTH AXIS.
;
; bd `xdu2` / L-1a Increment W1 (Track B, session 2026-09-15).  Same program as
; `railbank_accept_bool_prep_measureloop.ll` with `int` cells instead of `bool`.
;
; ⚠ WHY THE AXIS IS NOT COSMETIC.  An `int` cell's C storage type IS the rail
; type, so `abi=i32` and there is NO storage cast anywhere: neither the write's
; `zext` nor the read's `trunc` exists, and the type rewrite's PASS 4 takes its
; "the stored value is already the handle" arm instead of its cast arm.  The
; `_Bool` spelling exercises the other arm.  Both must produce a `[N x i32]`
; bank; a rewrite that only ever saw one of them would pass half the suite.
;
; ⚠ AND THE MEASURES MUST BE IN A LOOP, NOT AT CONSTANT INDICES.  MEASURED
; (`trackB/probes/b10_bank_int_cells_uncond.c`): at `-O1` clang emits the
; constant-index reads of a `[3 x i32]` array as BYTE-OFFSET geps
; (`getelementptr inbounds i8, ptr %b, i64 4`), which `railBankCellAddress`'
; cell-type agreement refuses — `cq rail bank: array mixes a rail cell access
; with an unrecognized one`.  The `_Bool` bank escapes that only because its
; cell type IS `i8`.  Whether the byte-offset gep is worth admitting is a
; separate, costed question and this increment did NOT widen it.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `…/trackB/probes/b11_bank_int_measureloop.c`:
;   #include "CQ.h"
;   int main(void) {
;       int b0[3]; int s = 0;
;       for (int i = 0; i < 3; ++i) cq_theta(&b0[i], 0.5);
;       for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
;       return s;
;   }
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

; DBG: CQ_CTRL_DBG: railbank [Bank] cells=3 abi=i32 trips=3 at:

; IR: alloca [3 x i32], align 4, !cq.railbank
; IR: %h = call i32 @cqrt_alloc_i32(i32 0)
; IR: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; IR: store i32 %h, ptr %cq.bank.addr, align 4
; IR: load i32, ptr %{{.*}}, align 4
; IR: call i32 @cqrt_measure_i32(i32 %{{.*}})

; ⚠ ONE WHOLE-FILE PREFIX PER COUNTED SYMBOL (Rule 12 hygiene defect (a), and
; the ORDERING trap that shares a prefix).
; CALLOC-COUNT-1: call i32 @cqrt_alloc_i32(
; CMEAS-COUNT-1: call i32 @cqrt_measure_i32(

; PURE NEGATIVES.  There was never a cast here, and the rewrite must not invent
; one; the parked rail is left allocated, not freed (Rule 6).
; NOTS-NOT: cq_template_zext
; NOTS-NOT: cq_template_trunc
; NOTS-NOT: cqrt_free

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %1) #3
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %3
  %5 = load i32, ptr %4, align 4, !tbaa !6
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #3
  store i32 %6, ptr %4, align 4, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 3
  br i1 %8, label %10, label %2, !llvm.loop !10

9:                                                ; preds = %10
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %1) #3
  ret i32 %16

10:                                               ; preds = %2, %10
  %11 = phi i64 [ %17, %10 ], [ 0, %2 ]
  %12 = phi i32 [ %16, %10 ], [ 0, %2 ]
  %13 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %11
  %14 = load i32, ptr %13, align 4, !tbaa !6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  %16 = add nsw i32 %15, %12
  %17 = add nuw nsw i64 %11, 1
  %18 = icmp eq i64 %17, 3
  br i1 %18, label %9, label %10, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
