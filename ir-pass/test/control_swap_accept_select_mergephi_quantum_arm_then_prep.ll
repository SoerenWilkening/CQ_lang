; control_swap_accept_select_mergephi_quantum_arm_then_prep.ll — ACCEPT. bd `boi6`
; D-B / Track M, round-1 finding **F-M1**, SECOND customer. RED ON THE ORACLE and
; RED ON THE PRE-FIX SUBJECT, for the two different reasons F-M1 is about.
;
; ⚠ THIS MODULE IS NOT MINE. It is `G6_quantum_mux_values.c` from the 2026-09-11
; INTEGRATION review's probe set, written for a different increment, and the
; whole-corpus sweep is what found it: it was the ONE row whose verdict moved
; between the pre-fix and post-fix binaries besides `r03`. Independent evidence
; that F-M1's precedence edge is the right fix and not a fix shaped to its own
; reproducer.
;
; IT IS THE SAME ORDER SHAPE AS `..._rail_then_kickback.ll` WITH A DIFFERENT THIRD
; CONSTRUCT: there the construct following the merge-φ select is a register-free
; PHASE KICKBACK; here it is another compare-guarded controlled STATE PREP
; (`if (a >= 3) cq_theta(&b1, .5)`, where `a` is the select's own output).
; Both take the sanctioned `hcrg` `sequentialChainAlias` edge — their `Pred` IS
; the first prep's `MergeBB` — so both scheduled the first prep AFTER the inert
; select and both hit the H-1 backstop. Two constructs, one cause, one edge.
;
; ⚠ AND ITS SELECT ARM IS A QUANTUM REGISTER, which the flagship's is not.
; `if (b0 == 1) a = p;` with `p = 0; cq_theta(&p, .3)` makes the true operand the LIVE
; rail `%h`, so the merge is `copy_i32_controlled(bf, h, out)` — a controlled
; basis COPY out of a register that STAYS LIVE and is measured at the end, into a
; fresh |0> out rail. Rule 8 has no subject: nothing is freed by copy+uncompute
; and nothing is moved; `%h` is left allocated and entangled, the accepted Rule-6
; leak. (`materializeCopySource` passes a tainted operand through unchanged rather
; than `cqrt_alloc`-ing it — the §5.2 prohibition on promoting a classical operand
; to a handle, read in the other direction.)
;
; THE THREE `cqrt_free` ARE ALL PROVEN-|0>: two compare flags returned by their own
; `_unc` strips, and the copy ancilla returned by its second `cqrt_cnot`
; (`x ^ x = 0` on every branch). NEITHER user register — `%h` (p) nor the prepped
; `%h2`/`%h7` — is ever `cqrt_x`-bracketed or freed; each is read only as a copy
; SOURCE, a compare operand, or a control.

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

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-11-orchestrator/review_integration_probes/G6_quantum_mux_values.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-11-orchestrator/review_integration_probes/G6_quantum_mux_values.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !21
  %2 = icmp sgt i32 %1, -1, !dbg !23
  br i1 %2, label %3, label %5, !dbg !25

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !26
  br label %5, !dbg !28

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ false, %0 ], !dbg !22
  %7 = select i1 %6, i32 %1, i32 5, !dbg !29
  %8 = icmp sgt i32 %7, 2, !dbg !30
  br i1 %8, label %9, label %11, !dbg !32

9:                                                ; preds = %5
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !33
  br label %11, !dbg !35

11:                                               ; preds = %9, %5
  %12 = phi i1 [ %10, %9 ], [ false, %5 ], !dbg !22
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !36
  %14 = zext i1 %13 to i32, !dbg !36
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %12) #2, !dbg !37
  %16 = zext i1 %15 to i32, !dbg !37
  %17 = add nuw nsw i32 %16, %14, !dbg !38
  %18 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !39
  %19 = add nsw i32 %17, %18, !dbg !40
  %20 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !41
  %21 = add nsw i32 %19, %20, !dbg !42
  ret i32 %21, !dbg !43
}

declare !dbg !44 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !49 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !52 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !55 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-11-orchestrator/review_integration_probes/G6_quantum_mux_values.c", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "ced14e1ce78e0d337704a974ed9656fa")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 2, type: !12, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-11-orchestrator/review_integration_probes/G6_quantum_mux_values.c", directory: "", checksumkind: CSK_MD5, checksum: "ced14e1ce78e0d337704a974ed9656fa")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18, !20}
!16 = !DILocalVariable(name: "p", scope: !10, file: !11, line: 3, type: !14)
!17 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 4, type: !14)
!18 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 4, type: !19)
!19 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!20 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 4, type: !19)
!21 = !DILocation(line: 3, column: 13, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 5, column: 11, scope: !24)
!24 = distinct !DILexicalBlock(scope: !10, file: !11, line: 5, column: 9)
!25 = !DILocation(line: 5, column: 9, scope: !10)
!26 = !DILocation(line: 5, column: 23, scope: !27)
!27 = distinct !DILexicalBlock(scope: !24, file: !11, line: 5, column: 16)
!28 = !DILocation(line: 5, column: 42, scope: !27)
!29 = !DILocation(line: 6, column: 9, scope: !10)
!30 = !DILocation(line: 7, column: 11, scope: !31)
!31 = distinct !DILexicalBlock(scope: !10, file: !11, line: 7, column: 9)
!32 = !DILocation(line: 7, column: 9, scope: !10)
!33 = !DILocation(line: 7, column: 23, scope: !34)
!34 = distinct !DILexicalBlock(scope: !31, file: !11, line: 7, column: 16)
!35 = !DILocation(line: 7, column: 42, scope: !34)
!36 = !DILocation(line: 8, column: 12, scope: !10)
!37 = !DILocation(line: 8, column: 27, scope: !10)
!38 = !DILocation(line: 8, column: 26, scope: !10)
!39 = !DILocation(line: 8, column: 42, scope: !10)
!40 = !DILocation(line: 8, column: 41, scope: !10)
!41 = !DILocation(line: 8, column: 56, scope: !10)
!42 = !DILocation(line: 8, column: 55, scope: !10)
!43 = !DILocation(line: 8, column: 5, scope: !10)
!44 = !DISubprogram(name: "cq_theta_si32", scope: !45, file: !45, line: 38, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!46 = !DISubroutineType(types: !47)
!47 = !{!14, !14, !48}
!48 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!49 = !DISubprogram(name: "cq_theta_i1", scope: !45, file: !45, line: 32, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = !DISubroutineType(types: !51)
!51 = !{!19, !19, !48}
!52 = !DISubprogram(name: "cq_measure_i1", scope: !45, file: !45, line: 77, type: !53, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!53 = !DISubroutineType(types: !54)
!54 = !{!19, !19}
!55 = !DISubprogram(name: "cq_measure_si32", scope: !45, file: !45, line: 83, type: !56, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!56 = !DISubroutineType(types: !57)
!57 = !{!14, !14}

; ---- The whole emitted stream, instruction for instruction.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 -1)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H_CMP1]], i32 %[[H2]], double 5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], i32 -1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H2]], i32 %[[BF]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[H]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: %[[SELOP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[SELOP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H2]], i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF]])
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[OUT]], i32 2)
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H_CMP]], i32 %[[H3]], double 5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP]], i32 %[[OUT]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
; CHECK:      %[[M4:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H3]])
; CHECK:      %[[M5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK:      %[[M6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])

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
; NOX-NOT: call void @cqrt_x(i32 %h2)
; NOX-NOT: call void @cqrt_x(i32 %h3)
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
; NOFREE-NOT: call void @cqrt_free(i32 %h3)
; NOFREE-NOT: call void @cqrt_free(i32 %out)
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CNOTCNT-COUNT-2: call void @cqrt_cnot(
; CNOTCNT-NOT:     call void @cqrt_cnot(
; CPCNT-COUNT-2: call void @cqrt_copy_
; CPCNT-NOT:     call void @cqrt_copy_
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; ACNT-COUNT-6: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
