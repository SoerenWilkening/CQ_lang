; control_swap_accept_select_mergephi_rail_prep_true_edge.ll — ACCEPT. bd `boi6`
; D-B / Track M, probe `m10`. RED ON THE ORACLE (`control flow` at the select).
;
; THE OTHER POLARITY. The flagship (`..._rail_negated.ll`) is an ORIENTATION-B
; diamond whose prep arm is the FALSE successor, so M-β's RAUW target is a CHAINED
; cancelling clone and the stream carries TWO `cqrt_ry_i1` on the prepped rail.
; Here the prep sits on the TRUE edge, so there is nothing to cancel: M-β's target
; is the SINGLE hoisted theta and the stream carries ONE `cqrt_ry_i1`.
;
; Both polarities must lower, and pinning them separately is what stops a future
; edit from silently making one of them mean the other — the `ArmNegated` /
; Rule-9 branch-polarity hazard, where `clang -O1` swaps successors and the gate
; arm is often the FALSE one. Compare the `RYCNT`-equivalent counts in the two
; files: the negated twin has one more `cqrt_ry_`.

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

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m10.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m10.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !21
  br i1 %1, label %2, label %4, !dbg !24

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !25
  br label %4, !dbg !28

4:                                                ; preds = %2, %0
  %5 = phi i32 [ 2, %2 ], [ 5, %0 ], !dbg !20
  %6 = phi i1 [ %3, %2 ], [ false, %0 ], !dbg !20
  %7 = add nsw i32 %5, -3
  %8 = select i1 %6, i32 %7, i32 %5, !dbg !29
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !30
  %10 = zext i1 %9 to i32, !dbg !30
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !31
  %12 = zext i1 %11 to i32, !dbg !31
  %13 = add nuw nsw i32 %12, %10, !dbg !32
  %14 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !33
  %15 = add nsw i32 %13, %14, !dbg !34
  ret i32 %15, !dbg !35
}

declare !dbg !36 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !41 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !44 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m10.c", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "cabb08e8752a83652af0996eb2013111")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 3, type: !12, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m10.c", directory: "", checksumkind: CSK_MD5, checksum: "cabb08e8752a83652af0996eb2013111")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !19}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 4, type: !14)
!17 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 5, type: !18)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 6, type: !18)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 7, column: 23, scope: !22)
!22 = distinct !DILexicalBlock(scope: !23, file: !11, line: 7, column: 16)
!23 = distinct !DILexicalBlock(scope: !10, file: !11, line: 7, column: 9)
!24 = !DILocation(line: 9, column: 9, scope: !10)
!25 = !DILocation(line: 9, column: 22, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !11, line: 9, column: 15)
!27 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 9)
!28 = !DILocation(line: 9, column: 41, scope: !26)
!29 = !DILocation(line: 10, column: 9, scope: !10)
!30 = !DILocation(line: 11, column: 12, scope: !10)
!31 = !DILocation(line: 11, column: 29, scope: !10)
!32 = !DILocation(line: 11, column: 27, scope: !10)
!33 = !DILocation(line: 11, column: 46, scope: !10)
!34 = !DILocation(line: 11, column: 44, scope: !10)
!35 = !DILocation(line: 11, column: 5, scope: !10)
!36 = !DISubprogram(name: "cq_theta_i1", scope: !37, file: !37, line: 32, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!38 = !DISubroutineType(types: !39)
!39 = !{!18, !18, !40}
!40 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!41 = !DISubprogram(name: "cq_measure_i1", scope: !37, file: !37, line: 77, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DISubroutineType(types: !43)
!43 = !{!18, !18}
!44 = !DISubprogram(name: "cq_measure_si32", scope: !37, file: !37, line: 83, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DISubroutineType(types: !46)
!46 = !{!14, !14}

; ---- The whole emitted stream, instruction for instruction.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H]], i32 %[[H4]], double 5.000000e-01)
; CHECK-NEXT: %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[BF]], i32 %[[OUT]], i32 2)
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[BF]], i32 %[[OUT]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[OUT]], i32 -3)
; CHECK-NEXT: %[[BF2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H4]], i32 %[[BF2]])
; CHECK-NEXT: %[[OUT3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF2]], i32 %[[H_OP]], i32 %[[OUT3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF2]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF2]], i32 %[[OUT]], i32 %[[OUT3]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF2]])
; bd r2j3.32: the FIRST merge rail `%out` is the second merge's copy source
; and has no LATER reader, so once that core has read it it is reversed --
; its own core re-emitted in reverse under the SAME flag, its flag strip
; DEFERRED to after that, then `%out` freed (it used to leak). The second merge's strip follows.
; NOT a full disentangle (R11 round 1, R9/L9): `%h_op = add(%out, -3)`, minted
; from `%out` before this reversal, is never `_unc`'d and stays entangled with
; the condition, so a later non-diagonal gate on the condition register would
; still dephase against it (the chain-final leak, unchanged here; r2j3.7 is
; its dead-op twin).
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[BF]], i32 %[[OUT]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[BF]], i32 %[[OUT]], i32 2)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H4]], i32 %[[BF2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF2]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H]])
; CHECK:      %[[M5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H4]])
; CHECK:      %[[M6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT3]])

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
; NOX-NOT: call void @cqrt_x(i32 %h)
; NOX-NOT: call void @cqrt_x(i32 %h4)
; The MERGE-OUT rail too (round-2 finding F2-3): it is the register the
; source's variable ends up in and the one this fixture MEASURES, so an X
; landing on it is a basis flip of the user's answer.  An EXTRA x is caught
; by the count prefix and a SUBSTITUTED one by the ordered positive stream;
; this closes the gap where neither is looking.
; NOX-NOT: call void @cqrt_x(i32 %out3)
; NO USER REGISTER IS FREED — `Ry(θ)|0⟩ ≠ |0⟩` (Rule 6). Only ancillas and
; stripped compare flags are.
; NOFREE-NOT: call void @cqrt_free(i32 %h)
; NOFREE-NOT: call void @cqrt_free(i32 %h4)
; `%out` (the first merge rail) IS freed since bd r2j3.32 -- after its core is
; reversed, at a proven |0>; the positive stream pins where.
; NOFREE-NOT: call void @cqrt_free(i32 %h_op)
; The MERGE-OUT rail too (round-2 finding F2-3) — freeing the user's answer
; register is a hidden measurement (Rule 6), and it was named by no free
; negative here before.
; NOFREE-NOT: call void @cqrt_free(i32 %out3)
; XCNT-COUNT-6: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CNOTCNT-COUNT-4: call void @cqrt_cnot(
; CNOTCNT-NOT:     call void @cqrt_cnot(
; (bd dm7f.81: a constant or classical merge arm is a literal operand of cqrt_xorc_<W>_controlled, no longer an alloc'd rail + cqrt_copy_<W>_controlled; a zero arm emits no gate and no bracket. Counts below re-measured.)
; CPCNT-COUNT-2: call void @cqrt_copy_
; CPCNT-NOT:     call void @cqrt_copy_
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; ACNT-COUNT-6: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
