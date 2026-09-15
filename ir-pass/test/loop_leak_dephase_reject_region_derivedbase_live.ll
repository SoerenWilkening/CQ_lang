; loop_leak_dephase_reject_region_derivedbase_live.ll — DECLINE (bd
; `test_C_libtooling-s82e`, owner ruling D4 of 2026-09-14c). The same divergence
; reached through an IN-LOOP PHASE REGION whose loop-invariant base is DERIVED
; (`p = y*3`), so `invariantRegisterRootsImpl` clause (ii) — which admits only a
; classical-arg-0 `cq_theta` root mint — refuses it and the body is never marked.
;
;     int y = cq_theta(5, 0.5);  int p = y * 3;
;     for (k = 1; k <= 2; ++k) if ((p >> k) & 1) cq_phi(0.3);
;     y = cq_theta(y, 0.9);                 // the interference
;     return cq_measure(y);
;
; MEASURED on the ORACLE: rolled 19 trace lines, hand-unrolled twin 25. The six
; missing lines are `and_i32_hl_unc`+`free` twice AND `mul_i32_hl_unc`+`free` —
; the derived base `p` itself, a full 32-qubit which-path copy of `y` — all of
; which the twin emits BEFORE its `cqrt_ry_i32(h0, 0.9)`. Same argument as
; `loop_leak_dephase_reject_noregion_live.ll`; read that file's header for it.
;
; ⚠ THIS FILE IS THE ONE THAT PINS THE REGION HALF. Its sibling has no tainted
; control flow at all, so a fix aimed only at the control path would leave this
; one silently wrong (or vice versa). Keep both.
;
; ⚠ RETIREMENT TRIGGER (L8) — **PARTIALLY FIRED, AND THIS FILE IS THE HALF THAT
; DID NOT MOVE.** bd `tu9q` landed 2026-09-15 and its sibling
; `loop_leak_dephase_reject_noregion_live.ll` IS now an ACCEPT. This one still
; DECLINES, deliberately, and the reason is the exact boundary of what was built:
; `tu9q` widened the admitted invariant reads to a ROOT MINT (at
; `markIfIterationLocal`'s slot, which had no `Roots` parameter at all) and to a
; MEASURE-OWNED template rail (clause (ii-c)). `p = y * 3` is NEITHER — it is a
; hoisted template rail read as DATA, which is exactly what
; `ChainWalk::isInteriorTerminalHandle` clause (I1) ADMITS to the interior
; partition, so admitting it as a root would put its `At` — computed from consumers
; that are all in the body — inside a K-times body against ONE preheader forward
; `cq_template_mul_i32_hl`: **K adjoints against one forward gate**, an
; over-reversed rail, a wrong unitary rather than a leak. Closing this half needs
; BOTH the real multiplicity test `Uncomputation.cpp:982-1000` specifies AND a
; loop-EXIT recovery point for a preheader-minted rail, neither of which exists.
; Filed, not built — see `$SES/trackT/IMPL_T2.md` §6 and bd
; `test_C_libtooling-1m5p`, which is the same family reached through the twin
; matrix. RE-DERIVE this file when that increment lands; do not delete it, and do
; NOT read its sibling's conversion as evidence about it.
;
; ⚠ THE DIAGNOSTIC BELOW IS OWNED BY ANOTHER FENCE
; (`declineDephasingUnmarkedLoopRails`, bd `s82e`) whose conjuncts are LIVE WORK
; (bd `c767` / bd `7845` / bd `2g52`). If that work moves the string or the
; conjuncts, this file moves with it — its VERDICT (decline) is the property, the
; string is that fence's. The boundary of `tu9q`'s clause (ii-c) is pinned
; INDEPENDENTLY, without any fence's string, by
; `loop_pairing_reject_root_hoisted_template_data.ll` and
; `loop_pairing_reject_root_invariant_read_after_loop.ll` — read those if this one
; is red after a fence edit.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq loop lowering: rolled body leaks a rail entangled with a rotated register

; ─────────────────────────────────────────────────────────────────────────────
; ⚠ RELOCATED HERE AT THE LOOP-GROUP MERGE GATE, 2026-09-15, BY THE SOURCE
; FIXTURE'S OWN L8 RETIREMENT TRIGGER — WHICH FIRED AND WHICH NAMED THIS ACTION:
;
;     "L8 RETIREMENT TRIGGER: this pin dies with the file when bd `tu9q` turns it
;      into an ACCEPT. MOVE the two `RUN`/`DEFER` blocks to whichever module still
;      declines at this fence then; do not silently drop them."
;
; It was written on `loop_leak_dephase_reject_inloop_rotation.ll` by Track D
; (branch `bbu0-warn-reorder`), based on Track S′ ALONE — a binary on which that
; module declined. Composed with Track T's bd `test_C_libtooling-tu9q` IN-LOOP
; PAIRING in this group's merge, that module became an **ACCEPT**, so its gated
; `not %cq-opt` would have gone red and the instrument's one safety pin would
; have been lost with it. This file was chosen as the new host BY MEASUREMENT on
; the merged binary `f2ee2eb69f1cdf9b7`, not by inspection: of the 16
; `loop_leak_dephase_*` / `loop_pairing_*` fixtures, 5 still decline at this
; fence, and this is the flat (non-nested) one among them, so the pin does not
; also depend on bd `test_C_libtooling-emkg`'s nesting fix.
;
; ⚠ bd `test_C_libtooling-bbu0`, owner ruling E6 (2026-09-15), option (D) — THE
; INSTRUMENT PIN, and it guards the one thing that could go catastrophically
; wrong with the instrument. Under `CQ_BBU0_DEFER_DEPHASE_FENCE=1` this fence
; RECORDS its verdict instead of emitting it, lets the pipeline run on so that
; `RotationLowering::warnLiveRecordRotations` gets to speak, and emits the
; decline afterwards. **THE GATED RUN LINE IS A `not %cq-opt`: IF THE GATE EVER
; TURNS THIS DECLINE INTO AN ACCEPT, THIS FIXTURE FAILS.** That is the
; instrument's whole safety property — pinned, not argued.
;
; The `DEFER` prefix is WHOLE-FILE and separate from `CHECK` (fixture-hygiene (a):
; a positive check above a negative windows it; these are two independent
; verdicts about two different commands, so they get two prefixes). Its lines are
; ORDERED and the order is the point: the marker can only be printed by
; `emitDeferredDephasingDecline`, which is called AFTER the warn stage in both
; entry points, so a marker standing BEFORE the decline is the proof that the
; deferral actually reached that slot. That proof is the vacuity guard for the
; whole population of `$SES/trackD/MEASUREMENT.md` — without it a "0 warnings"
; row would be measuring the harness's own reachability rather than the
; warning's silence.
;
; ⚠ AND THIS HOST MAKES THE PIN STRICTLY STRONGER THAN IT WAS, MEASURED: this
; module also WARNS (`cq rotation lowering: non-diagonal gate over a live derived
; record`, twice), and the `DEFER` prefix below pins those warnings BETWEEN the
; ungated silence and the deferred decline. So the fixture now witnesses not only
; "the gate does not lose the verdict" but "the gate actually lets the warn stage
; speak on a module the fence refuses" — which is the measurement's subject.
;
; ⚠ L8 RETIREMENT TRIGGER, CARRIED FORWARD AND RE-AIMED: this pin dies with this
; file the day anything turns THIS module into an ACCEPT (the live conjunct work
; of bd `c767` / bd `7845` / bd `2g52`, or a further pairing widening). MOVE the
; `RUN`/`DEFER` block again then, to whichever module still declines at
; `declineDephasingUnmarkedLoopRails`; do not silently drop it. The cheap way to
; find one is the loop in `$SES/loopgate/probes/fence_hosts.sh`.
;
; RUN: env CQ_BBU0_DEFER_DEPHASE_FENCE=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:     -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=DEFER
;
; DEFER: cq rotation lowering: non-diagonal gate over a live derived record
; DEFER: cq bbu0 instrument: dephasing decline DEFERRED past the warn stage
; DEFER: cq loop lowering: rolled body leaks a rail entangled with a rotated register

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
  br label %6, !dbg !24

3:                                                ; preds = %12
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !25
    #dbg_value(i32 %4, !15, !DIExpression(), !21)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !26
  ret i32 %5, !dbg !27

6:                                                ; preds = %0, %12
  %7 = phi i32 [ 1, %0 ], [ %13, %12 ]
    #dbg_value(i32 %7, !18, !DIExpression(), !23)
  %8 = shl nuw nsw i32 1, %7, !dbg !28
  %9 = and i32 %8, %2, !dbg !28
  %10 = icmp eq i32 %9, 0, !dbg !28
  br i1 %10, label %12, label %11, !dbg !31

11:                                               ; preds = %6
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !32
  br label %12, !dbg !32

12:                                               ; preds = %6, %11
  %13 = add nuw nsw i32 %7, 1, !dbg !33
    #dbg_value(i32 %13, !18, !DIExpression(), !23)
  %14 = icmp eq i32 %13, 3, !dbg !34
  br i1 %14, label %3, label %6, !dbg !24, !llvm.loop !35
}

declare !dbg !39 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !44 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !47 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !50 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !51
    #dbg_value(i32 %1, !15, !DIExpression(), !53)
  %2 = mul nsw i32 %1, 3, !dbg !54
    #dbg_value(i32 %2, !16, !DIExpression(), !53)
    #dbg_value(i32 0, !17, !DIExpression(), !53)
    #dbg_value(i32 1, !18, !DIExpression(), !55)
  br label %3, !dbg !56

3:                                                ; preds = %9, %0
  %4 = phi i32 [ 1, %0 ], [ %10, %9 ]
    #dbg_value(i32 %4, !18, !DIExpression(), !55)
  %5 = shl nuw nsw i32 1, %4, !dbg !57
  %6 = and i32 %5, %2, !dbg !57
  %7 = icmp eq i32 %6, 0, !dbg !57
  br i1 %7, label %9, label %8, !dbg !58

8:                                                ; preds = %3
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !59
  br label %9, !dbg !59

9:                                                ; preds = %8, %3
  %10 = add nuw nsw i32 %4, 1, !dbg !60
    #dbg_value(i32 %10, !18, !DIExpression(), !55)
  %11 = icmp eq i32 %10, 3, !dbg !61
  br i1 %11, label %12, label %3, !dbg !56, !llvm.loop !62

12:                                               ; preds = %9
  %13 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !64
    #dbg_value(i32 %13, !15, !DIExpression(), !53)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !65
  ret i32 %14, !dbg !66
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/s2_live_derived_region.c", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "179f5d85972a16c18b475201b41dac12")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "p", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 9, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 10, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 5)
!20 = !DILocation(line: 7, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 8, column: 15, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 10, column: 5, scope: !19)
!25 = !DILocation(line: 12, column: 9, scope: !10)
!26 = !DILocation(line: 13, column: 16, scope: !10)
!27 = !DILocation(line: 13, column: 5, scope: !10)
!28 = !DILocation(line: 11, column: 22, scope: !29)
!29 = distinct !DILexicalBlock(scope: !30, file: !8, line: 11, column: 13)
!30 = distinct !DILexicalBlock(scope: !19, file: !8, line: 10, column: 5)
!31 = !DILocation(line: 11, column: 13, scope: !30)
!32 = !DILocation(line: 11, column: 27, scope: !29)
!33 = !DILocation(line: 10, column: 29, scope: !30)
!34 = !DILocation(line: 10, column: 23, scope: !30)
!35 = distinct !{!35, !24, !36, !37, !38}
!36 = !DILocation(line: 11, column: 37, scope: !19)
!37 = !{!"llvm.loop.mustprogress"}
!38 = !{!"llvm.loop.unroll.disable"}
!39 = !DISubprogram(name: "cq_theta_si32", scope: !40, file: !40, line: 38, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!40 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!41 = !DISubroutineType(types: !42)
!42 = !{!13, !13, !43}
!43 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!44 = !DISubprogram(name: "cq_phi", scope: !40, file: !40, line: 73, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DISubroutineType(types: !46)
!46 = !{null, !43}
!47 = !DISubprogram(name: "cq_measure_si32", scope: !40, file: !40, line: 83, type: !48, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!48 = !DISubroutineType(types: !49)
!49 = !{!13, !13}
!50 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!51 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !52)
!52 = distinct !DILocation(line: 15, column: 25, scope: !50)
!53 = !DILocation(line: 0, scope: !10, inlinedAt: !52)
!54 = !DILocation(line: 8, column: 15, scope: !10, inlinedAt: !52)
!55 = !DILocation(line: 0, scope: !19, inlinedAt: !52)
!56 = !DILocation(line: 10, column: 5, scope: !19, inlinedAt: !52)
!57 = !DILocation(line: 11, column: 22, scope: !29, inlinedAt: !52)
!58 = !DILocation(line: 11, column: 13, scope: !30, inlinedAt: !52)
!59 = !DILocation(line: 11, column: 27, scope: !29, inlinedAt: !52)
!60 = !DILocation(line: 10, column: 29, scope: !30, inlinedAt: !52)
!61 = !DILocation(line: 10, column: 23, scope: !30, inlinedAt: !52)
!62 = distinct !{!62, !56, !63, !37, !38}
!63 = !DILocation(line: 11, column: 37, scope: !19, inlinedAt: !52)
!64 = !DILocation(line: 12, column: 9, scope: !10, inlinedAt: !52)
!65 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !52)
!66 = !DILocation(line: 15, column: 18, scope: !50)
