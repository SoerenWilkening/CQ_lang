; control_swap_accept_select_mergephi_cmp_cond_region.ll — ACCEPT. bd `boi6` D-B /
; Track M, orchestrator ruling item 2 (2026-09-13). RED ON THE ORACLE
; (`control flow` at the select), GREEN HERE.
;
; THE PREP REGION IS GUARDED BY A **COMPARE**, NOT BY A BARE RAIL:
; `int b0 = 0; cq_theta(&b0,.5); bool b1 = 0; if (b0 == 1) cq_theta(&b1,.5);
; if (b1) a -= 3;`. The merge block carries a SINGLE phi, so `MergePhiPeel` never
; runs and F2 (bd `rb9x`) is not reached — this is the compare spelling in its
; cleanest form.
;
; ⚠ THIS FILE EXISTS BECAUSE IT WAS A DECLINE FIXTURE FOR ONE AFTERNOON, and the
; history is the lesson. Track M's rung 0 first required `RailLadderProven` as
; "defence in depth". That flag is set by `classifyArms` ONLY when the REGION'S
; OWN condition is a bare rail, so the conjunct silently refused every
; compare-guarded prep — MEASURED: this exact program reached rung 0 and was
; refused by that conjunct ALONE. The flag answers "did the RAIL ladder run?",
; which is not the question the select needs answered. The select needs "will this
; φ become ONE physical register?", and that is precisely what the
; `InPlaceRotation` class verdict means — its emitter hoists the arm's theta and
; RAUWs the φ to it (M-β). A compare-guarded region reached the SAME committed
; verdict through `condWireDisposition`'s ladder instead. Requiring the rail
; SPELLING of the proof was a claim about HOW the region was proved, not about
; WHAT was proved, and an over-decline of a valid circuit is a defect rather than
; a safety margin (owner ruling 2026-09-11). The class conjunct still fires on any
; OTHER claimed class — `control_swap_reject_select_mergephi_other_class.ll`.
;
; READ THE STREAM: the compare mints a flag (`cq_template_icmp_eq_i32_hl(h0, 1)`),
; the prep fires as `cqrt_ry_i1_controlled` on a FRESH rail, the flag is stripped
; by its `_unc` and freed at a proven |0>; only THEN does the select's rail-root
; CNOT-copy merge read the prepped register as a control. Two `cqrt_free`, both
; proven-|0>: the compare flag and the copy ancilla. Neither user register
; (`%h` = b0, `%h2` = b1) is bracketed or freed.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNOTCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/impl/i2_cmpladder.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/impl/i2_cmpladder.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2, !dbg !21
  %2 = icmp eq i32 %1, 1, !dbg !22
  br i1 %2, label %3, label %5, !dbg !24

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !25
  br label %5, !dbg !26

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ false, %0 ], !dbg !20
  %7 = select i1 %6, i32 2, i32 5, !dbg !27
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !28
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !29
  %10 = zext i1 %9 to i32, !dbg !29
  %11 = add nsw i32 %8, %10, !dbg !30
  %12 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !31
  %13 = add nsw i32 %11, %12, !dbg !32
  ret i32 %13, !dbg !33
}

declare !dbg !34 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !39 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !42 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !45 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/impl/i2_cmpladder.c", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "b2f5385eed01aee23cb60b569b3122cd")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 6, type: !12, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/impl/i2_cmpladder.c", directory: "", checksumkind: CSK_MD5, checksum: "b2f5385eed01aee23cb60b569b3122cd")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 7, type: !14)
!17 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 8, type: !14)
!18 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 9, type: !19)
!19 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 8, column: 14, scope: !10)
!22 = !DILocation(line: 10, column: 12, scope: !23)
!23 = distinct !DILexicalBlock(scope: !10, file: !11, line: 10, column: 9)
!24 = !DILocation(line: 10, column: 9, scope: !10)
!25 = !DILocation(line: 10, column: 23, scope: !23)
!26 = !DILocation(line: 10, column: 18, scope: !23)
!27 = !DILocation(line: 11, column: 9, scope: !10)
!28 = !DILocation(line: 12, column: 12, scope: !10)
!29 = !DILocation(line: 12, column: 29, scope: !10)
!30 = !DILocation(line: 12, column: 27, scope: !10)
!31 = !DILocation(line: 12, column: 46, scope: !10)
!32 = !DILocation(line: 12, column: 44, scope: !10)
!33 = !DILocation(line: 12, column: 5, scope: !10)
!34 = !DISubprogram(name: "cq_theta_si32", scope: !35, file: !35, line: 38, type: !36, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!35 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!36 = !DISubroutineType(types: !37)
!37 = !{!14, !14, !38}
!38 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!39 = !DISubprogram(name: "cq_theta_i1", scope: !35, file: !35, line: 32, type: !40, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!40 = !DISubroutineType(types: !41)
!41 = !{!19, !19, !38}
!42 = !DISubprogram(name: "cq_measure_si32", scope: !35, file: !35, line: 83, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DISubroutineType(types: !44)
!44 = !{!14, !14}
!45 = !DISubprogram(name: "cq_measure_i1", scope: !35, file: !35, line: 77, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DISubroutineType(types: !47)
!47 = !{!19, !19}

; ---- The whole emitted stream, instruction for instruction.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H_CMP]], i32 %[[H2]], double 5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H2]], i32 %[[BF]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[SELOP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: %[[SELOP1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[SELOP1]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H2]], i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK:      %[[M3:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
; CHECK:      %[[M4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])

; ---- Whole-file negatives, each in its OWN pure-negative prefix (a positive
; line inside one WINDOWS every negative after it — the 3qlq F-L6-1 lesson).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_rz
; NOROUTE-NOT: cqrt_toffoli
; NOROUTE-NOT: call i1 @cq_theta_i1(
; NOROUTE-NOT: cq_phi
; NOROUTE-NOT: {{= phi }}
;   ^ the region was flattened and its merge phi dissolved. The anchor
;     `= phi ` is load-bearing: a bare `phi` also matches the module PATH
;     in cq-opt's `ModuleID` preamble (bd Track M 2026-09-13).
; NO `cqrt_x` ON A USER REGISTER, EVER — the two `cqrt_x` per merge are on
; the copy ancilla. The handles are named because a pure-negative prefix
; cannot bind a capture; they are DERIVED from the pass output.
;   ⚠ EVERY HANDLE NAMED IN A PURE-NEGATIVE PREFIX IS DERIVED FROM THE PASS
;     OUTPUT AND RE-CHECKED. A `-NOT` naming a handle the module never defines is
;     VACUOUS — it passes for the wrong reason, the same way a bare `NOT: phi`
;     passed by matching the module PATH. Five such negatives shipped in this
;     family's first cut and were caught by the injection matrix (an injected
;     `cqrt_x` on the SECOND user register reddened XCNT but not NOX); a
;     name-existence check now runs over every accept (`probes/impl/vacuity.py`).
; NOX-NOT: call void @cqrt_x(i32 %h)
; NOX-NOT: call void @cqrt_x(i32 %h2)
; The MERGE-OUT rail too (round-2 finding F2-3): it is the register the
; source's variable ends up in and the one this fixture MEASURES, so an X
; landing on it is a basis flip of the user's answer.  An EXTRA x is caught
; by the count prefix and a SUBSTITUTED one by the ordered positive stream;
; this closes the gap where neither is looking.
; NOX-NOT: call void @cqrt_x(i32 %out)
; NO USER REGISTER IS FREED — `Ry(θ)|0⟩ ≠ |0⟩` (Rule 6). Only ancillas and
; stripped compare flags are.
; NOFREE-NOT: call void @cqrt_free(i32 %h)
; NOFREE-NOT: call void @cqrt_free(i32 %h2)
; NOFREE-NOT: call void @cqrt_free(i32 %out)
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CNOTCNT-COUNT-2: call void @cqrt_cnot(
; CNOTCNT-NOT:     call void @cqrt_cnot(
; CPCNT-COUNT-2: call void @cqrt_copy_
; CPCNT-NOT:     call void @cqrt_copy_
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; ACNT-COUNT-6: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
