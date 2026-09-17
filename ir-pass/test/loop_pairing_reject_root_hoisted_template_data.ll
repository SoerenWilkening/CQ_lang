; loop_pairing_reject_root_hoisted_template_data.ll — ACCEPT-THAT-STILL-LEAKS
; (bd `test_C_libtooling-tu9q`, 2026-09-15). THE BOUNDARY OF CLAUSE (ii-c), PINNED
; POSITIVELY — and deliberately WITHOUT a post-loop rotation, so no fence's string
; is involved and this file cannot move when bd `test_C_libtooling-s82e`'s
; conjuncts are widened (bd `c767` / bd `7845` / bd `2g52` are live work on the
; SAME function; a boundary pinned by someone else's diagnostic is a boundary that
; moves when they edit it).
;
;     int y = cq_theta(5, .5);
;     int p = y * 3;                                  // hoisted TEMPLATE rail
;     for (k = 1; k <= 2; ++k)
;         s += cq_measure(y & 1) + cq_measure((p >> k) & 1);
;     return s + cq_measure(y);
;
; TWO loop-invariant tainted values are read in the body. `y & 1` is a hoisted
; template rail every one of whose users is a `cq_measure` — MEASURE-OWNED, and
; clause (ii-c) admits it. `p = y * 3` is a hoisted template rail read as DATA, and
; clause (ii) must REFUSE it, so `invariantRegisterRoots` returns false, NOTHING is
; marked, and the body's per-trip rails LEAK. That leak is the pre-existing
; disposition and it is what this file pins.
;
; ⚠ WHY REFUSING IT IS NOT A MISSED OPPORTUNITY BUT A UNITARY. `%p`'s forward gate
; (`cq_template_mul_i32_hl`) sits in the PREHEADER and runs ONCE, while a marked
; body's discharge point runs K times. `Uncomputation.cpp`'s §4/§2.9 pair asks each
; endpoint SEPARATELY whether it repeats and never whether the two repeat EQUALLY
; (`Uncomputation.cpp:982-1000` says so in those words), so admitting `%p` as a
; root would emit **K adjoints against ONE forward gate** — an over-reversed rail,
; i.e. a wrong unitary, not a leak. Clause (ii)'s root-mint restriction and clause
; (ii-c)'s measure-ownership are two DIFFERENT structural proofs that the rail can
; never be given an `At`; `%p` has neither. Closing this half needs the real
; multiplicity test AND a loop-EXIT recovery point for a preheader-minted rail, and
; is filed, not built.
;
; ⚠ IF A `_unc` OR A `cqrt_free` EVER APPEARS IN THIS FILE, clause (ii-c) has
; over-widened and the multiplicity miscompile above is LIVE — with `opt` exit 0,
; verify-clean, and STRICT stage 2b reporting `0 violation(s)` (2b counts
; `cqrt_alloc` sites and every rail here is template-minted). Nothing else in the
; tree would go red. L8 RETIREMENT TRIGGER: when the hoisted-template half of bd
; `tu9q` is built, this file becomes an ACCEPT that DISCHARGES — re-derive its
; stream then; do not delete it.
;
; ── the historical header ENDS here; what follows is the CONVERSION ───────────
;
; ⚠⚠ **THE TRIGGER ABOVE FIRED ON 2026-09-18 AND THE FILE IS CONVERTED IN PLACE**
; (bd `test_C_libtooling-tu9q`, the hoisted-template half, piece P2). It is NOT
; renamed: a `git mv`'d fixture can be resurrected by a merge, leaving one module
; under two names with contradictory verdicts (`CLAUDE.md` L8, bd `gahu`).
;
; ⚠ **AND THE TRIGGER NAMED THE WRONG MECHANISM, WHICH IS THE PART WORTH
; CARRYING.** The header above predicts the flip comes from widening the ROOT
; admission (clause (ii-c)/(ii-d)). It does not. The `mul` rail below discharges
; with clause (ii) UNCHANGED and the loop body UNMARKED, because the flip is a
; PLACEMENT: `Uncomputation::anchorForConsumer` now anchors a rail minted OUTSIDE
; the cycle its consumer runs in at that cycle's unique EXIT, instead of at the
; consumer's own `getNextNode()` — a point that repeats while the forward gate
; does not. Nothing marks anything, and the `At` at the exit does not repeat, so
; §2.9 passes without the iteration-local exception. **A retirement trigger can
; be right about the verdict and wrong about the cause; re-derive, do not assume.**
;
; WHAT IS PINNED NOW, and the distinction is the whole file: the HOISTED rail
; (`%h_op`, minted once in the preheader) is discharged ONCE at the loop exit,
; while the PER-TRIP rails (`lshr`, `and`) are STILL LEAKED — the body is not
; marked, so `planInteriorComponent` §2.9 refuses an in-body `At` for them. That
; residual is the P0/P3 half of the same increment and is deliberately visible
; here rather than hidden: this file is the boundary between the two pieces.
;
; ⚠ RULE 6 IS NOT WEAKENED BY THE NEW FREE. `%h_op`'s only in-loop users READ it
; (`lshr`, and a hoisted `and`), so the `mul_unc` at the exit returns it to |0⟩ on
; every branch and the `cqrt_free` is a proven-|0⟩ one. `%h` carries no gate
; between the mint and the exit, so the adjoint reads the basis the forward gate
; read (clause (d)'s LEFT disjunct).
;
; ⚠ NEW L8 RETIREMENT TRIGGER: when the P0/P3 half lands, the per-trip `lshr`/`and`
; rails gain an IN-BODY `_unc` + `cqrt_free` each and `LEAKBODY` below becomes
; wrong. Re-derive this file then against the hand-unrolled twin's MULTISET (owner
; ruling S3, 2026-09-17: byte identity is the instrument, not the claim); do not
; delete it, and do not restore the whole-file `LEAK` prefix, which pinned a
; stream where the HOISTED rail leaked too.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=EXITD < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=LEAKBODY < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @slice
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK: call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
; CHECK: call i32 @cq_template_lshr_i32_hl(
; CHECK-LABEL: define i32 @main
;
; THE HOISTED RAIL'S DISCHARGE, in its own prefix, and it must be the loop-EXIT
; block: the `_unc`/`free` pair is IMMEDIATELY followed by the post-loop measure
; of `%h`, which no in-body placement could produce.
; EXITD: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; EXITD-NEXT: call void @cqrt_free(i32 %h_op)
; EXITD-NEXT: %m = call i32 @cqrt_measure_i32(i32 %h)
;
; THE PER-TRIP RAILS STILL LEAK — a PURE negative prefix (Rule 12
; fixture-hygiene (a): no positive above it, so nothing windows these):
; LEAKBODY-NOT: call void @cq_template_lshr_i32_hl_unc(
; LEAKBODY-NOT: call void @cq_template_and_i32_hl_unc(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !20
    #dbg_value(i32 %1, !15, !DIExpression(), !21)
  %2 = mul nsw i32 %1, 3, !dbg !22
    #dbg_value(i32 %2, !16, !DIExpression(), !21)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
    #dbg_value(i32 1, !18, !DIExpression(), !23)
  %3 = and i32 %1, 1
    #dbg_value(i32 1, !18, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
  br label %7, !dbg !24

4:                                                ; preds = %7
  %5 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !25
  %6 = add nsw i32 %5, %15, !dbg !26
  ret i32 %6, !dbg !27

7:                                                ; preds = %0, %7
  %8 = phi i32 [ 1, %0 ], [ %16, %7 ]
  %9 = phi i32 [ 0, %0 ], [ %15, %7 ]
    #dbg_value(i32 %8, !18, !DIExpression(), !23)
    #dbg_value(i32 %9, !17, !DIExpression(), !21)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !28
  %11 = lshr i32 %2, %8, !dbg !30
  %12 = and i32 %11, 1, !dbg !30
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !30
  %14 = add i32 %10, %9, !dbg !31
  %15 = add i32 %14, %13, !dbg !32
    #dbg_value(i32 %15, !17, !DIExpression(), !21)
  %16 = add nuw nsw i32 %8, 1, !dbg !33
    #dbg_value(i32 %16, !18, !DIExpression(), !23)
  %17 = icmp eq i32 %16, 3, !dbg !34
  br i1 %17, label %4, label %7, !dbg !24, !llvm.loop !35
}

declare !dbg !39 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !44 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !47 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !48
    #dbg_value(i32 %1, !15, !DIExpression(), !50)
  %2 = mul nsw i32 %1, 3, !dbg !51
    #dbg_value(i32 %2, !16, !DIExpression(), !50)
    #dbg_value(i32 0, !17, !DIExpression(), !50)
    #dbg_value(i32 1, !18, !DIExpression(), !52)
  %3 = and i32 %1, 1
    #dbg_value(i32 1, !18, !DIExpression(), !52)
    #dbg_value(i32 0, !17, !DIExpression(), !50)
  br label %4, !dbg !53

4:                                                ; preds = %4, %0
  %5 = phi i32 [ 1, %0 ], [ %13, %4 ]
  %6 = phi i32 [ 0, %0 ], [ %12, %4 ]
    #dbg_value(i32 %5, !18, !DIExpression(), !52)
    #dbg_value(i32 %6, !17, !DIExpression(), !50)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !54
  %8 = lshr i32 %2, %5, !dbg !55
  %9 = and i32 %8, 1, !dbg !55
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !55
  %11 = add i32 %7, %6, !dbg !56
  %12 = add i32 %11, %10, !dbg !57
    #dbg_value(i32 %12, !17, !DIExpression(), !50)
  %13 = add nuw nsw i32 %5, 1, !dbg !58
    #dbg_value(i32 %13, !18, !DIExpression(), !52)
  %14 = icmp eq i32 %13, 3, !dbg !59
  br i1 %14, label %15, label %4, !dbg !53, !llvm.loop !60

15:                                               ; preds = %4
  %16 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !62
  %17 = add nsw i32 %16, %12, !dbg !63
  ret i32 %17, !dbg !64
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!9}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "b1_mixed_nonlive.c", directory: "/Users/sorenwilkening/Desktop/CQ_T/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv", checksumkind: CSK_MD5, checksum: "6abea90301e70a264e6846b645ae6aa6")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 9, type: !11, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 10, type: !13)
!16 = !DILocalVariable(name: "p", scope: !10, file: !8, line: 11, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 12, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 13, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 13, column: 5)
!20 = !DILocation(line: 10, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 11, column: 15, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 13, column: 5, scope: !19)
!25 = !DILocation(line: 15, column: 16, scope: !10)
!26 = !DILocation(line: 15, column: 14, scope: !10)
!27 = !DILocation(line: 15, column: 5, scope: !10)
!28 = !DILocation(line: 14, column: 14, scope: !29)
!29 = distinct !DILexicalBlock(scope: !19, file: !8, line: 13, column: 5)
!30 = !DILocation(line: 14, column: 34, scope: !29)
!31 = !DILocation(line: 14, column: 32, scope: !29)
!32 = !DILocation(line: 14, column: 11, scope: !29)
!33 = !DILocation(line: 13, column: 29, scope: !29)
!34 = !DILocation(line: 13, column: 23, scope: !29)
!35 = distinct !{!35, !24, !36, !37, !38}
!36 = !DILocation(line: 14, column: 34, scope: !19)
!37 = !{!"llvm.loop.mustprogress"}
!38 = !{!"llvm.loop.unroll.disable"}
!39 = !DISubprogram(name: "cq_theta_si32", scope: !40, file: !40, line: 38, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!40 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!41 = !DISubroutineType(types: !42)
!42 = !{!13, !13, !43}
!43 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!44 = !DISubprogram(name: "cq_measure_si32", scope: !40, file: !40, line: 83, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DISubroutineType(types: !46)
!46 = !{!13, !13}
!47 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 17, type: !11, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!48 = !DILocation(line: 10, column: 13, scope: !10, inlinedAt: !49)
!49 = distinct !DILocation(line: 17, column: 25, scope: !47)
!50 = !DILocation(line: 0, scope: !10, inlinedAt: !49)
!51 = !DILocation(line: 11, column: 15, scope: !10, inlinedAt: !49)
!52 = !DILocation(line: 0, scope: !19, inlinedAt: !49)
!53 = !DILocation(line: 13, column: 5, scope: !19, inlinedAt: !49)
!54 = !DILocation(line: 14, column: 14, scope: !29, inlinedAt: !49)
!55 = !DILocation(line: 14, column: 34, scope: !29, inlinedAt: !49)
!56 = !DILocation(line: 14, column: 32, scope: !29, inlinedAt: !49)
!57 = !DILocation(line: 14, column: 11, scope: !29, inlinedAt: !49)
!58 = !DILocation(line: 13, column: 29, scope: !29, inlinedAt: !49)
!59 = !DILocation(line: 13, column: 23, scope: !29, inlinedAt: !49)
!60 = distinct !{!60, !53, !61, !37, !38}
!61 = !DILocation(line: 14, column: 34, scope: !19, inlinedAt: !49)
!62 = !DILocation(line: 15, column: 16, scope: !10, inlinedAt: !49)
!63 = !DILocation(line: 15, column: 14, scope: !10, inlinedAt: !49)
!64 = !DILocation(line: 17, column: 18, scope: !47)
