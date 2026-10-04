; ⚠⚠⚠ 2026-09-15 — THE NAME IS HISTORY: THIS FILE IS NOW AN **ACCEPT**, AND ITS
; OWN L8 RETIREMENT TRIGGER (below, unedited) NAMED THE EVENT BY BEAD ID AND WAS
; CHARACTER-FOR-CHARACTER CORRECT:
;
;     "when `tu9q` lands this file becomes an ACCEPT whose stream is the 24-line
;      hand-unrolled twin's, rolled — re-derive it then; do not delete it."
;
; bd `test_C_libtooling-tu9q` (the IN-LOOP `_unc` + `cqrt_free` PAIRING) landed in
; the loop-group merge of 2026-09-15. The re-derivation is below, and it is the
; one place this file's claim is WEAKER than its sibling's.
;
; ⚠ FOUND AT THE MERGE, BY NEITHER TRACK AND BY NO REVIEW — see the sibling
; `loop_leak_dephase_reject_cmp_rail_data.ll`'s banner for the four-binary
; measurement and why a composition is not cleared by clearing its parts.
;
; ⚠ IT IS NOT RENAMED, DELIBERATELY (bd `test_C_libtooling-gahu`, `CLAUDE.md` L8).
;
; THE RE-DERIVATION. MEASURED on the merged binary `9dd81edb9f949bb5` against the
; hand-unrolled twin (`loopfix/probes/c2_inloop_rotation{,_un}.c`): ROLLED **24
; trace lines against the twin's 24**, where the ORACLE emitted 20 against 24.
; The four lines that were missing — `cq_template_lshr_i32_hl_unc` + `cqrt_free`,
; twice — are now emitted IN THE BODY, once per trip.
;
; ⚠ **THE TWO TRACES ARE NOT BYTE-IDENTICAL, AND THE CLAIM IS THEREFORE A
; MULTISET-PLUS-COMMUTATION ONE, NOT AN IDENTITY ONE.** Saying it the weaker way
; is the point: `CLAUDE.md` §5 records a shipped fixture family whose header read
; a STABILITY measurement as a CORRECTNESS one, and the cure is to state exactly
; what was compared. What was compared, and what came back:
;   * gate-symbol MULTISET, rolled vs twin: **delta EMPTY** (`diff` of
;     `sed 's/(.*//' | sort | uniq -c` over both traces);
;   * the ONE positional difference: `-O1` LICM-hoists the loop-invariant `y & 1`
;     to trace line 3 in the ROLLED spelling and CSEs the twin's two copies into
;     one at trace line 10. The gates between those two positions are
;     `cqrt_alloc_i32(6)`, `cqrt_ry_i32`, `lshr`, `and`, `lshr_unc`, `cqrt_free`
;     and one `cqrt_measure_i32` — EVERY ONE of them on the per-trip register `u`
;     and its own ancilla, a support DISJOINT from `%h` and from the `y & 1`
;     rail's fresh ancilla. Disjoint supports commute EXACTLY, so the reorder is
;     not an approximation;
;   * handle NUMBERING differs as a consequence of the reorder (the `y & 1` rail
;     is `h1` rolled and `h4` unrolled) — a relabelling, not a circuit;
;   * the `y & 1` rail is MEASURE-OWNED (both its users are `cq_measure`) and is
;     LEFT ALLOCATED by BOTH forms — identical disposition, Rule 6's accepted leak,
;     and clause (ii-c)'s subject.
; A BYTE-IDENTICAL twin is NOT available for this program at any `-O` level this
; project uses, because the hoist/CSE decision is made in STAGE 1, before the pass
; runs. That is a fact about `clang -O1`, not about the lowering.
;
; ⚠ 2b IS BLIND HERE and was blind on the leaking form too (`0 violation(s)` on
; both halves): it counts `cqrt_alloc` SITES and these rails are TEMPLATE-minted.
;
; ⚠ NEW L8 RETIREMENT TRIGGER, TWO BRANCHES: (a) if this file goes red with
; `rolled body leaks a rail entangled with a rotated register`, the pairing has
; stopped marking this loop — re-derive from `c2_inloop_rotation.c` and its twin
; BEFORE touching the fence. (b) If anything ever makes the two spellings agree
; POSITIONALLY, upgrade the claim above from multiset-plus-commutation to byte
; identity and say which stage-1 change did it.
;
; ── THE HISTORICAL HEADER FOLLOWS, UNEDITED. Read it as the record of WHY the
; ── decline existed; its verdict line is superseded by the banner above.
;
; loop_leak_dephase_reject_inloop_rotation.ll — DECLINE (bd
; `test_C_libtooling-c767`, P1, closed 2026-09-15). THE DEPHASING CLASS WITH THE
; INTERFERING ROTATION **INSIDE** THE BODY. Until this fixture existed, conjunct
; (2) of `declineDephasingUnmarkedLoopRails` skipped every in-loop `@cq_theta_*`
; (`if (L->contains(&BB) || ...) continue;`), so `Rots` came back EMPTY and the
; loop was passed over — an ACCEPT on a program whose rolled and hand-unrolled
; forms compute DIFFERENT UNITARIES.
;
;     int y = 5; cq_theta(&y, 0.5);
;     for (k = 0; k < 2; ++k) {
;         int u = 6; cq_theta(&u, 0.4);                 // SOURCE theta, per trip
;         s += cq_measure((u >> 1) & 1) + cq_measure(y & 1);
;         cq_theta(&u, 0.9);                         // CHAINED — the interference
;         s += cq_measure(u);
;     }
;     return s + cq_measure(y);
;
; ⚠ ITS PROVENANCE IS THE POINT. This is bd `s82e`'s own exhibit
; `w2k_noregion_invread` — the program owner ruling D4 of 2026-09-14c ruled
; BENIGN and which `loop_leak_dephase_accept_pertrip_dead.ll` pins as an ACCEPT —
; WITH ONE LINE ADDED. The invariant read of `y` still leaves the body UNMARKED,
; so the per-trip rails still leak; what changes is that `u` is now interfered
; before the trip ends. Two of bd `s82e`'s three "benign" exhibits cross the line
; under that one line, which is why D4's scope sentence ("a register live AFTER
; THE LOOP") was corrected to a description of the old conjuncts and not of the
; class.
;
; MEASURED, ORACLE `cq-opt` 0e280fc62a91cec2… (the pre-fix binary): `opt` exit 0,
; verify-clean, rolled 20 trace lines against the hand-unrolled twin's 24. The
; four missing lines are `cq_template_lshr_i32_hl_unc` + `cqrt_free`, twice — the
; adjoint that returns the which-path copy of `u`'s qubits to |0> and the
; proven-|0> free after it. The rolled form therefore applies the TENSORED
; `cqrt_ry_i32(…, 0.9)` to a register entangled with an ancilla nobody touches
; again (a DECOHERED mixture) where the twin applies it to the pure state, and
; `cqrt_measure_i32` is the observable: `CLAUDE.md` Rule 8.
;
; ⚠ RULE 17. The refused program receives an INVALID circuit today, so refusing
; it is the Prime Directive and the 2026-09-11 over-decline ruling does not reach
; it. The decline is the INTERIM; bd `tu9q` (the in-loop `_unc` + `cqrt_free`
; pairing) is the END STATE. L8 RETIREMENT TRIGGER: when `tu9q` lands this file
; becomes an ACCEPT whose stream is the 24-line hand-unrolled twin's, rolled —
; re-derive it then; do not delete it.
;
; ⚠ STRICT stage 2b is BLIND here (`0 violation(s), 0 unproven` on both halves):
; it counts `cqrt_alloc` SITES and a template-minted rail has none. The
; rolled-vs-hand-unrolled trace pair is the only instrument that sees this class.
;
; ⚠ FIXTURE HYGIENE (b): a `DS_Error` decline writes 0 BYTES to stdout, so an
; IR-text `CHECK-NOT` here would be VACUOUS. The property is pinned by the `not`
; inversion on the RUN line plus the message match, and this file was validated by
; BINARY MUTATION (it does not match on the pre-fix oracle, where `opt` exits 0).
;
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UNCCOUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FREECOUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; THE ORDERED STREAM, ROLLED — the per-trip group is mint, mint, ADJOINT, FREE,
; measure, ALL IN ONE BODY BLOCK, which is what makes it atomic per trip.
; CHECK-LABEL: define i32 @slice
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; the LICM-hoisted, MEASURE-OWNED `y & 1` rail — minted once, never freed:
; CHECK: %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
; the per-trip body group:
; CHECK: %h1 = call i32 @cqrt_alloc_i32(i32 6)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01)
; CHECK: %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h1, i32 1)
; CHECK-NEXT: %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1)
; CHECK-NEXT: call void @cq_template_lshr_i32_hl_unc(i32 %h_op2, i32 %h1, i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %h_op2)
; CHECK-NEXT: %m{{[0-9]*}} = call i32 @cqrt_measure_i32(i32 %h_op3)
;
; ⚠ NO SECOND `CHECK-LABEL` HERE, AND THAT IS A MEASURED DIFFERENCE FROM THE
; SIBLING, NOT AN OMISSION: `-O1` does NOT inline `@slice` into `@main` in this
; module (the loop survives), so there is exactly ONE copy of the stream and the
; bd `test_C_libtooling-1yeu` decoy hazard does not arise. The counts below are
; the check on that claim — if `@slice` is ever inlined they double and the
; `*COUNT-NOT` lines fire.
;
; WHOLE-FILE COUNTS, ONE COUNTED SYMBOL PER PREFIX, NEGATIVES SOMEWHERE ELSE
; ENTIRELY (Rule 12 fixture-hygiene defect (a)). ROLLED, so exactly one of each
; in the IR however many trips run.
; UNCCOUNT-COUNT-1: call void @cq_template_lshr_i32_hl_unc(
; UNCCOUNT-NOT: call void @cq_template_lshr_i32_hl_unc(
;
; FREECOUNT-COUNT-1: call void @cqrt_free(
; FREECOUNT-NOT: call void @cqrt_free(
;
; PURE NEGATIVES — never a free of the user's register, never a free of either
; measure-owned rail, never an adjoint of the measured `and`, and no decline text.
; NEG-NOT: call void @cqrt_free(i32 %h)
; NEG-NOT: call void @cqrt_free(i32 %h1)
; NEG-NOT: call void @cqrt_free(i32 %h_op)
; NEG-NOT: call void @cqrt_free(i32 %h_op3)
; NEG-NOT: call void @cq_template_and_i32_hl_unc(
; NEG-NOT: rolled body leaks a rail

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i32 %1, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
  %2 = and i32 %1, 1
  br label %6, !dbg !25

3:                                                ; preds = %6
  %4 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !26
  %5 = add nsw i32 %4, %18, !dbg !27
  ret i32 %5, !dbg !28

6:                                                ; preds = %0, %6
  %7 = phi i32 [ 0, %0 ], [ %18, %6 ]
  %8 = phi i32 [ 0, %0 ], [ %19, %6 ]
    #dbg_value(i32 %7, !16, !DIExpression(), !23)
    #dbg_value(i32 %8, !17, !DIExpression(), !24)
  %9 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !29
    #dbg_value(i32 %9, !19, !DIExpression(), !30)
  %10 = lshr i32 %9, 1, !dbg !31
  %11 = and i32 %10, 1, !dbg !31
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !31
  %13 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !32
    #dbg_value(i32 %17, !16, !DIExpression(), !23)
  %14 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 9.000000e-01) #2, !dbg !33
    #dbg_value(i32 %14, !19, !DIExpression(), !30)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2, !dbg !34
  %16 = add i32 %12, %7, !dbg !35
  %17 = add i32 %16, %13, !dbg !36
  %18 = add nsw i32 %17, %15, !dbg !37
    #dbg_value(i32 %18, !16, !DIExpression(), !23)
  %19 = add nuw nsw i32 %8, 1, !dbg !38
    #dbg_value(i32 %19, !17, !DIExpression(), !24)
  %20 = icmp eq i32 %8, 0, !dbg !39
  br i1 %20, label %6, label %3, !dbg !25, !llvm.loop !40
}

declare !dbg !44 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !49 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !52 {
  %1 = tail call i32 @slice(), !dbg !53
  ret i32 %1, !dbg !54
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
!8 = !DIFile(filename: "b7b_w2k_interfered.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "d5bad600e3eb9d72672cf5cb8e68fc0b")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 7, type: !11, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 8, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 9, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 10, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 11, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 10, column: 33)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 10, column: 5)
!22 = !DILocation(line: 8, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 10, column: 5, scope: !18)
!26 = !DILocation(line: 16, column: 16, scope: !10)
!27 = !DILocation(line: 16, column: 14, scope: !10)
!28 = !DILocation(line: 16, column: 5, scope: !10)
!29 = !DILocation(line: 11, column: 17, scope: !20)
!30 = !DILocation(line: 0, scope: !20)
!31 = !DILocation(line: 12, column: 14, scope: !20)
!32 = !DILocation(line: 12, column: 41, scope: !20)
!33 = !DILocation(line: 13, column: 13, scope: !20)
!34 = !DILocation(line: 14, column: 14, scope: !20)
!35 = !DILocation(line: 12, column: 39, scope: !20)
!36 = !DILocation(line: 12, column: 11, scope: !20)
!37 = !DILocation(line: 14, column: 11, scope: !20)
!38 = !DILocation(line: 10, column: 28, scope: !21)
!39 = !DILocation(line: 10, column: 23, scope: !21)
!40 = distinct !{!40, !25, !41, !42, !43}
!41 = !DILocation(line: 15, column: 5, scope: !18)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = !DISubprogram(name: "cq_theta_si32", scope: !45, file: !45, line: 38, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_S", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!46 = !DISubroutineType(types: !47)
!47 = !{!13, !13, !48}
!48 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!49 = !DISubprogram(name: "cq_measure_si32", scope: !45, file: !45, line: 83, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = !DISubroutineType(types: !51)
!51 = !{!13, !13}
!52 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 18, type: !11, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!53 = !DILocation(line: 18, column: 25, scope: !52)
!54 = !DILocation(line: 18, column: 18, scope: !52)
