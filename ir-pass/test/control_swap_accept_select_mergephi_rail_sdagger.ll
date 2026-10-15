; control_swap_accept_select_mergephi_rail_sdagger.ll — ACCEPT. bd `boi6` D-B /
; Track M, probe `m15`; the H-6 ADMIT ruling of 2026-09-13. RED ON THE ORACLE
; (`control flow` at the select), GREEN HERE.
;
; THE OWNER'S FILE PLUS A SECOND ROTATION OF THE SAME REGISTER AFTER THE SELECT
; (`cq_theta(&b1, 0.25);`) — the S† spelling, one construct past the flagship.
; `SCOPE_M.md` H-6 predicted this must DECLINE as "two siblings on one rail". IT
; IS NOT TWO SIBLINGS, and the IR says so: `%9 = cq_theta_i1(i1 %6, double 0.25)`
; takes the SELECT'S OWN CONDITION as its arg-0, so after M-β's RAUW it is CHAINED
; onto the hoisted gate — the same physical rail under a later name, not a second
; independent rotation of a shared parent.
;
; WHY IT IS ADMISSIBLE, AND IT IS THE SHIPPED P1 ARGUMENT VERBATIM. The merge
; reads `b1`'s BASIS LABEL at the select (`cqrt_cnot(h_b1, bf)`), and everything
; the region mints — the ancilla, both brackets, the copies — is created, used and
; discharged BEFORE the rotation: the ancilla's `cqrt_free` is line 26 of the
; stream and the `cqrt_ry_i1(·, 0x1p-2)` is line 27. Nothing of the region
; survives on the register for that gate to invalidate, and the later
; `cq_measure(b1)` correctly reads the POST-rotation state. SOURCE ORDER IS
; PRESERVED EXACTLY. Gate 2c sees the rotation on the φ's wire, answers DIRTY
; position-free, and the DT prong (which is the prong a RAIL's seeds get) re-asks
; at `EmitPoint = Sel`, finds it provably after every execution of the select, and
; answers CLEAN.
;
; ⚠ MEASURED, NOT ARGUED — the disposition is PRE-EXISTING and Rule-13-cleared.
; The frozen ORACLE accepts the IDENTICAL program in the rail-leaf spelling (the
; `b1` prep made unconditional: 29 lines, STRICT 2b clean) and accepts the minimal
; S† form `if (b) a -= 3; cq_theta(&b, -0.5);` at 16 lines. Track M did not
; invent this accept; it made a second SPELLING reach a fence that was already
; there and already answering. Sources: `probes/impl/m15u.c`, `probes/impl/s04.c`.
;
; ⚠ WHAT THIS FIXTURE DOES **NOT** LICENSE. The genuine bd `3d8q` class is TWO
; SIBLING READERS of the pre-rotation name — `bool c = b1; cq_theta(&c,.25);` with
; `b1` STILL measured afterwards, so two SSA names denote one register and the
; pass asks nothing (the stale-record guard sweeps PURE ops only). That shape also
; ACCEPTS ON THE FROZEN ORACLE in the rail-leaf spelling, so it is a pre-existing
; hole to which Track M adds customers — NOT something this increment fenced.
; Probe `probes/impl/p3d8q_sibling{,_rail}.c`; see IMPL_M.md §7.

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

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m15.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m15.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !21
  br i1 %1, label %4, label %2, !dbg !24

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !25
  br label %4, !dbg !28

4:                                                ; preds = %2, %0
  %5 = phi i32 [ 5, %2 ], [ 2, %0 ], !dbg !20
  %6 = phi i1 [ %3, %2 ], [ false, %0 ], !dbg !20
  %7 = add nsw i32 %5, -3
  %8 = select i1 %6, i32 %7, i32 %5, !dbg !29
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 2.500000e-01) #2, !dbg !30
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !31
  %11 = zext i1 %10 to i32, !dbg !31
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %9) #2, !dbg !32
  %13 = zext i1 %12 to i32, !dbg !32
  %14 = add nuw nsw i32 %13, %11, !dbg !33
  %15 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !34
  %16 = add nsw i32 %14, %15, !dbg !35
  ret i32 %16, !dbg !36
}

declare !dbg !37 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !42 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !45 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m15.c", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "62152b3d08055e3e5d99d5305132ced3")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 3, type: !12, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m15.c", directory: "", checksumkind: CSK_MD5, checksum: "62152b3d08055e3e5d99d5305132ced3")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !19}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 4, type: !14)
!17 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 5, type: !18)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 6, type: !18)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 9, column: 14, scope: !22)
!22 = distinct !DILexicalBlock(scope: !23, file: !11, line: 8, column: 16)
!23 = distinct !DILexicalBlock(scope: !10, file: !11, line: 8, column: 9)
!24 = !DILocation(line: 13, column: 9, scope: !10)
!25 = !DILocation(line: 14, column: 14, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !11, line: 13, column: 16)
!27 = distinct !DILexicalBlock(scope: !10, file: !11, line: 13, column: 9)
!28 = !DILocation(line: 15, column: 5, scope: !26)
!29 = !DILocation(line: 16, column: 9, scope: !10)
!30 = !DILocation(line: 17, column: 10, scope: !10)
!31 = !DILocation(line: 18, column: 12, scope: !10)
!32 = !DILocation(line: 18, column: 29, scope: !10)
!33 = !DILocation(line: 18, column: 27, scope: !10)
!34 = !DILocation(line: 18, column: 46, scope: !10)
!35 = !DILocation(line: 18, column: 44, scope: !10)
!36 = !DILocation(line: 18, column: 5, scope: !10)
!37 = !DISubprogram(name: "cq_theta_i1", scope: !38, file: !38, line: 32, type: !39, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!39 = !DISubroutineType(types: !40)
!40 = !{!18, !18, !41}
!41 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!42 = !DISubprogram(name: "cq_measure_i1", scope: !38, file: !38, line: 77, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DISubroutineType(types: !44)
!44 = !{!18, !18}
!45 = !DISubprogram(name: "cq_measure_si32", scope: !38, file: !38, line: 83, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DISubroutineType(types: !47)
!47 = !{!14, !14}

; ---- The whole emitted stream, instruction for instruction.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H4]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H]], i32 %[[H4]], double -5.000000e-01)
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
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H4]], double 2.500000e-01)
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
; RYCNT-COUNT-4: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; ACNT-COUNT-6: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
