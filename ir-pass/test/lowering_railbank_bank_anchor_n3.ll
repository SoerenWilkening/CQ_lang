; lowering_railbank_bank_anchor_n3.ll — the `Bank` VERDICT ANCHOR (bd `test_C_libtooling-xdu2` / L-1a W1).
; STILL A DECLINE: `Bank` falls through to `kMsgStore` this increment.
;
; THE OWNER'S PROGRAM, RECOGNIZED: the bounded rail ARRAY at N=3, spelling (i).
;
; This is the customer bd `xdu2` exists for — a first-success cascade with a kept
; history, one fresh qubit per trip. At N=3 the branches are 000/001/010/100 with
; `a = 5/2/2/2` and amplitudes c³, c²s, cs, s (c = cos .25, s = sin .25).
;
; The RAW (unpromoted) shape: the cell is read TWICE per trip, through two DISTINCT
; geps (`%9` in the arm, `%15` in the merge) at the SAME index `%5` — and the second
; read is only PARTIALLY AVAILABLE, which is why a naive element-type rewrite would
; load `0` AS A HANDLE on the pred edge (SCOPE_L1a §0 H3). C4 admits that
; read-modify-write cell address deliberately, where `matchQramAccess`'s
; `GEP->hasOneUse()` would refuse it: ONE predicate then serves both the promoter
; (which sees THIS shape) and the carve (which, once the promoter lands, sees the
; one-store shape pinned by `lowering_railbank_bank_anchor_promoted.ll`).
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
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackL/probes/a_loop_n3.c`:
;   /* a_loop_n3.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
;      VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
;      Q2(i) ARRAY spelling, N=3 — byte-identical source to ../probes/ve.c. Same decline, same site, col 26.
;      ⚠ RETIREMENT TRIGGER (L8): same as a_loop_n2. */
;   #include "CQ.h"
;   int main(void) {
;       int a = 5;
;       bool b[3] = {0};
;       for (int i = 0; i < 3; ++i) {
;           if (a >= 3) cq_theta(&b[i], 0.5);
;           if (b[i]) a -= 3;
;       }
;       int s = cq_measure(a);
;       for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
;       return s;
;   }
;
;
; ⚠⚠ THE L8 RETIREMENT TRIGGER BELOW HAS FIRED — bd `xdu2` W1's SECOND HALF
; landed 2026-09-15 (the taint rule + the `[N x cell]` -> `[N x i32]` type
; rewrite + the D5 allow-list), and this file was RE-DERIVED, not deleted, in
; the same change.  READ THE NEW VERDICT AS A MOVED WALL, NOT AS AN ACCEPT:
;
;   * the bank STORE no longer declines.  `CQ_CTRL_DBG` still anchors the
;     `[Bank]` verdict on it and `--implicit-check-not='cq rail bank:'` still
;     proves no per-clause rail-bank decline fires anywhere;
;   * what declines now is the REGION — `cq controlled lowering: control flow
;     inside a loop body under quantum control`, `iterationLocalRollable`'s
;     conjunct (c3), bd `8h7d.11`.  That conjunct is BANK-INDEPENDENT: the same
;     loop with a SCALAR `bool` and no array at all declines identically
;     (`trackB/probes/b02_scalar_measure_a_outside.c`), so the rail bank cannot
;     move it and W1 never could.
;
; This is owner ruling E5 in one file: *the bank compiles; the owner's cascade
; needs (c3) + W3.*  The accept half of W1 is pinned by
; `railbank_accept_*` and by `lowering_railbank_bank_anchor_unpromoted.ll`.
;
; ⚠ NEXT L8 RETIREMENT TRIGGER: the day bd `8h7d.11` (the (c3) widening) lands,
; this file's decline moves again — to `cq loop lowering: loop-carried tainted
; value crosses iterations` (X1 / bd `ej5w` / W3), MEASURED on this module's own
; `noAmeasure` variant.  Re-derive it then; do NOT delete it.
; ⚠⚠ THE L8 RETIREMENT TRIGGER BELOW HAS FIRED — bd `test_C_libtooling-zujr`
; landed the LOOP-CARRIED HANDLE VARIABLE (8h7d.11 + ej5w + 832l together), and
; this file was RE-DERIVED, not deleted, in the same change.  READ THE VERDICT
; AS AN ACCEPT, AND READ THE TRIGGER'S OWN WORDS AGAINST IT: it predicted
; *"`cq loop lowering: loop-carried tainted value crosses iterations` (X1 / bd
; `ej5w` / W3)"*, and that is a DECLINE.  It was written when (c3) and X1 were
; expected to land separately; they landed in ONE increment, because X1 was never
; the last wall either — behind it stood `declineUnmarkedRolledIterLocal`'s
; conjunct 2 and then `declineClassicalMuxes`.  **A trigger that names the NEXT
; wall is only ever a lower bound on how many are left.**
;
; WHAT THE ACCEPT IS, in one line: `a` is a LOOP-CARRIED HANDLE VARIABLE — a
; register that crosses the back edge AND is re-minted every trip — and the four
; sites that used to refuse it now CALL `loopCarriedHandlePhi`, while
; `promoteLoopCarriedHandleSeeds` materialises the TRIP-1 register
; `%cq.carried = cqrt_alloc_i32(5)` in the preheader (the owner's ruling (1) of
; 2026-09-17).  The FLAT twin already did exactly that, as the `cqrt_alloc_i32(5)`
; copy source inside its trip-1 mux.
;
; THE STREAM BELOW IS READ BY THESE INVARIANTS: the phi muxes two HANDLES under
; the loop's CLASSICAL exit test; `%5` (the register `a` names this trip) is read
; only as a compare operand, an `add` operand and a COPY SOURCE — never
; `cqrt_x`-bracketed, never freed; every `cqrt_x` sits on an ancilla returned to
; |0> before its free; and the `a - 3` chain rail `%h_op` is LEFT ALLOCATED, which
; is what the flat twin leaves too (6 undischarged rails in each form — measured,
; `tests/e2e/slice_control_cascade_loop_carried_handle{,_unrolled}.c`).
;
; ⚠ NEXT L8 RETIREMENT TRIGGER: the day the promotion learns to hoist its
; `cqrt_alloc` ABOVE a rotated loop's zero-trip GUARD (clause (Z8) refuses that
; shape today, so a RUNTIME trip bound still declines `kMsgCrossIter`), a guarded
; spelling of this module becomes an accept too.  This one is unguarded and does
; not move.  Re-derive it then; do NOT delete it.
; RUN: env CQ_CTRL_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank:'
; RUN: env CQ_CTRL_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck --check-prefix=NOREG %s
; CHECK: CQ_CTRL_DBG: railbank [Bank] cells={{[0-9]+}} abi={{i[0-9]+}} trips={{[0-9]+}} at:
;
; THE TRIP-1 PROMOTION, in the PREHEADER and nowhere else.
; CHECK: %cq.carried = call i32 @cqrt_alloc_i32(i32 5)
;
; THE PHI IS A HANDLE MUX: the promoted preheader register, and the previous
; activation's merge `%out`.
; CHECK: = phi i32 [ %cq.carried, %{{[0-9a-zA-Z._]+}} ], [ %out{{[0-9]*}}, %{{[0-9a-zA-Z._]+}} ]
;
; ONE ACTIVATION, in order: the compare flag, the controlled prep of this trip's
; bank rail, the flag's own `_unc` strip and its proven-|0> free.
; CHECK: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[A:[0-9]+]], i32 2)
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h, double 5.000000e-01)
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %[[A]], i32 2)
; CHECK: call void @cqrt_free(i32 %h_cmp)
;
; THE VALUE ARM, merged by CONTROLLED COPY into a FRESH |0> rail.  `%h_op` (the
; `a - 3` chain) is a copy SOURCE and is LEFT ALLOCATED; the ancilla `%bf` is
; CNOT-copied from the rail, X-bracketed and freed at |0>.
; CHECK: %h_op = call i32 @cq_template_add_i32_hl(i32 %[[A]], i32 -3)
; CHECK: %bf = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_cnot(i32 %h, i32 %bf)
; CHECK: %out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_op, i32 %out)
; CHECK: call void @cqrt_x(i32 %bf)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %bf, i32 %[[A]], i32 %out)
; CHECK: call void @cqrt_x(i32 %bf)
; CHECK: call void @cqrt_cnot(i32 %h, i32 %bf)
; CHECK: call void @cqrt_free(i32 %bf)
;
; THE REGISTER IS NEVER BRACKETED AND NEVER FREED — the two facts a stream of
; this shape can get wrong, pinned as negatives in their own whole-file prefix
; (Rule 12 hygiene defect (a): a positive above a negative WINDOWS it).
; NOREG-NOT: cqrt_x(i32 %cq.carried)
; NOREG-NOT: cqrt_x(i32 %out{{[0-9]*}})
; NOREG-NOT: cqrt_free(i32 %cq.carried)
; NOREG-NOT: cqrt_free(i32 %out{{[0-9]*}})
; NOREG-NOT: cqrt_free(i32 %h)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %4

2:                                                ; preds = %14
  %3 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
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
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 5.000000e-01) #4
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
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %31

23:                                               ; preds = %2, %23
  %24 = phi i64 [ 0, %2 ], [ %32, %23 ]
  %25 = phi i32 [ %3, %2 ], [ %31, %23 ]
  %26 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %24
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %28) #4
  %30 = zext i1 %29 to i32
  %31 = add nsw i32 %25, %30
  %32 = add nuw nsw i64 %24, 1
  %33 = icmp eq i64 %32, 3
  br i1 %33, label %22, label %23, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

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
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
