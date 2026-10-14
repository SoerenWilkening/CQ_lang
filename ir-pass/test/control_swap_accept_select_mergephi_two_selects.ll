; control_swap_accept_select_mergephi_two_selects.ll — ACCEPT. bd `boi6` D-B /
; Track M. RED ON THE ORACLE (`control flow` at the first select).
;
; TWO INDEPENDENT SELECTS READ THE SAME PREP MERGE φ (`if (b1) a -= 3;
; if (b1) c -= 7;` over two different variables, so `-O1` cannot fuse them into
; one). Each is classified on its own and each emits its own complete merge, so
; the register `%h4` is read as a CONTROL by two separate `cqrt_cnot` pairs.
;
; THAT IS SOUND FOR THE REASON THE r9e5 header gives and it is worth stating: a
; rail leaf's other users are ORDINARY. Nothing is minted FROM the register that
; could outlive a region — each merge writes only its own `%out` and its own
; ancilla, both brackets act on that ancilla, and each ancilla returns to
; `x ⊕ x = 0` independently. So there is no `hasOneUse` fence to owe, and the
; three `cqrt_free` here (the a-mux ancilla plus one per select) are each
; proven-|0>.
;
; ⚠ Do NOT read this as licensing two selects on one MINT in general — it licenses
; two read-only CONTROL reads. A second WRITER of the register between the two
; selects is the `sdagger` fixture's question, and two SIBLING readers of the
; pre-rotation name is bd `3d8q` (neither is this file).

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

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/impl/a_two_selects.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/impl/a_two_selects.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !22
  br i1 %1, label %4, label %2, !dbg !25

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !26
  br label %4, !dbg !29

4:                                                ; preds = %2, %0
  %5 = phi i32 [ 5, %2 ], [ 2, %0 ], !dbg !21
  %6 = phi i1 [ %3, %2 ], [ false, %0 ], !dbg !21
  %7 = add nsw i32 %5, -3
  %8 = select i1 %6, i32 %7, i32 %5, !dbg !30
  %9 = select i1 %6, i32 2, i32 9, !dbg !31
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !32
  %11 = zext i1 %10 to i32, !dbg !32
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !33
  %13 = zext i1 %12 to i32, !dbg !33
  %14 = add nuw nsw i32 %13, %11, !dbg !34
  %15 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !35
  %16 = add nsw i32 %14, %15, !dbg !36
  %17 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !37
  %18 = add nsw i32 %16, %17, !dbg !38
  ret i32 %18, !dbg !39
}

declare !dbg !40 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !45 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !48 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/impl/a_two_selects.c", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "aaca4d928f730d1f53f227110bf55b37")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 2, type: !12, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/impl/a_two_selects.c", directory: "", checksumkind: CSK_MD5, checksum: "aaca4d928f730d1f53f227110bf55b37")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18, !20}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 3, type: !14)
!17 = !DILocalVariable(name: "c", scope: !10, file: !11, line: 3, type: !14)
!18 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 3, type: !19)
!19 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!20 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 3, type: !19)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 4, column: 23, scope: !23)
!23 = distinct !DILexicalBlock(scope: !24, file: !11, line: 4, column: 16)
!24 = distinct !DILexicalBlock(scope: !10, file: !11, line: 4, column: 9)
!25 = !DILocation(line: 6, column: 9, scope: !10)
!26 = !DILocation(line: 6, column: 23, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !11, line: 6, column: 16)
!28 = distinct !DILexicalBlock(scope: !10, file: !11, line: 6, column: 9)
!29 = !DILocation(line: 6, column: 42, scope: !27)
!30 = !DILocation(line: 7, column: 9, scope: !10)
!31 = !DILocation(line: 8, column: 9, scope: !10)
!32 = !DILocation(line: 9, column: 12, scope: !10)
!33 = !DILocation(line: 9, column: 29, scope: !10)
!34 = !DILocation(line: 9, column: 27, scope: !10)
!35 = !DILocation(line: 9, column: 46, scope: !10)
!36 = !DILocation(line: 9, column: 44, scope: !10)
!37 = !DILocation(line: 9, column: 62, scope: !10)
!38 = !DILocation(line: 9, column: 60, scope: !10)
!39 = !DILocation(line: 9, column: 5, scope: !10)
!40 = !DISubprogram(name: "cq_theta_i1", scope: !41, file: !41, line: 32, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!42 = !DISubroutineType(types: !43)
!43 = !{!19, !19, !44}
!44 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!45 = !DISubprogram(name: "cq_measure_i1", scope: !41, file: !41, line: 77, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DISubroutineType(types: !47)
!47 = !{!19, !19}
!48 = !DISubprogram(name: "cq_measure_si32", scope: !41, file: !41, line: 83, type: !49, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DISubroutineType(types: !50)
!50 = !{!14, !14}

; ---- The whole emitted stream, instruction for instruction.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H8:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H8]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H]], i32 %[[H8]], double -5.000000e-01)
; CHECK-NEXT: %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[SELOP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: %[[SELOP1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[SELOP1]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[OUT]], i32 -3)
; CHECK-NEXT: %[[BF2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H8]], i32 %[[BF2]])
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
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[SELOP1]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[SELOP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H8]], i32 %[[BF2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF2]])
; CHECK-NEXT: %[[BF4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H8]], i32 %[[BF4]])
; CHECK-NEXT: %[[OUT5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF4]], i32 %[[SELOP6]], i32 %[[OUT5]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF4]])
; CHECK-NEXT: %[[SELOP7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 9)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF4]], i32 %[[SELOP7]], i32 %[[OUT5]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF4]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H8]], i32 %[[BF4]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF4]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H]])
; CHECK:      %[[M9:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H8]])
; CHECK:      %[[M10:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT3]])
; CHECK:      %[[M11:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT5]])

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
; NOX-NOT: call void @cqrt_x(i32 %h8)
; The MERGE-OUT rail too (round-2 finding F2-3): it is the register the
; source's variable ends up in and the one this fixture MEASURES, so an X
; landing on it is a basis flip of the user's answer.  An EXTRA x is caught
; by the count prefix and a SUBSTITUTED one by the ordered positive stream;
; this closes the gap where neither is looking.
; NOX-NOT: call void @cqrt_x(i32 %out3)
; NOX-NOT: call void @cqrt_x(i32 %out5)
; NO USER REGISTER IS FREED — `Ry(θ)|0⟩ ≠ |0⟩` (Rule 6). Only ancillas and
; stripped compare flags are.
; NOFREE-NOT: call void @cqrt_free(i32 %h)
; NOFREE-NOT: call void @cqrt_free(i32 %h8)
; `%out` (the first merge rail) IS freed since bd r2j3.32 -- after its core is
; reversed, at a proven |0>; the positive stream pins where.
; NOFREE-NOT: call void @cqrt_free(i32 %h_op)
; The MERGE-OUT rail too (round-2 finding F2-3) — freeing the user's answer
; register is a hidden measurement (Rule 6), and it was named by no free
; negative here before.
; NOFREE-NOT: call void @cqrt_free(i32 %out3)
; NOFREE-NOT: call void @cqrt_free(i32 %out5)
; XCNT-COUNT-8: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CNOTCNT-COUNT-6: call void @cqrt_cnot(
; CNOTCNT-NOT:     call void @cqrt_cnot(
; CPCNT-COUNT-8: call void @cqrt_copy_
; CPCNT-NOT:     call void @cqrt_copy_
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; ACNT-COUNT-12: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
