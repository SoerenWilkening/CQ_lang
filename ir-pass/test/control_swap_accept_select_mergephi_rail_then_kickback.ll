; control_swap_accept_select_mergephi_rail_then_kickback.ll — ACCEPT. bd `boi6`
; D-B / Track M, round-1 finding **F-M1**; probe `r03_order_third_region.c`.
; RED ON THE ORACLE, and RED ON THE PRE-FIX SUBJECT TOO — for a DIFFERENT reason
; each time, which is the whole point of this file.
;
; THE PROGRAM adds ONE line to the flagship: `if (a == 2) { cq_phi(0.3); }` after
; the merge-φ select. That third construct is a register-free PHASE KICKBACK whose
; `Pred` IS the prep diamond's `MergeBB`, i.e. the sanctioned `hcrg`
; sequential-chain alias.
;
; ⚠ WHAT IT CAUGHT, AND IT WAS A LIVE OVER-DECLINE ON ORDINARY `-O1` C.
; `lowerControlRegions` does NOT emit in plan order — it Kahn-sorts the `hcrg`
; PRECEDENCE graph. A `SelectRegion` has all-null block fields, so it is INERT
; there: it aliases nothing, nothing aliases it, `Pending == 0` always. The
; kickback's chain alias adds `Precedes[kickback] = {prep}`, scheduling the PREP
; LAST — after the select. The select's condition re-read then found the merge φ
; still live (M-β had not run) and fired `emitSelectRegion`'s loud H-1 backstop:
; `control flow`, exit 1, nothing emitted. Safe, and wrong.
;
; THE FIX is `ControlRegion::PrepRegionIdx` — rung 0 RECORDS the admitting region,
; and `lowerControlRegions` turns that record into exactly ONE precedence edge
; (prep BEFORE select) by CALLING it, never by re-deriving the predicate (Rule 14).
; A select can only gain INCOMING edges, so it can never sit on a precedence cycle.
;
; ⚠ READ THE EMITTED ORDER, BECAUSE IT IS SOURCE ORDER AND THAT IS NOT A
; COINCIDENCE OF THE SCHEDULE. Every emitter inserts POSITIONALLY — the kickback
; before its own `Pred`'s terminator, the select's stream immediately before the
; select instruction — so the trace follows IR POSITION, not emission order. Hence
; the a-mux, then the `b1` prep, then the select (`…add_i32_hl` → the copy merge →
; `%out`), then the kickback minting its flag FROM `%out`
; (`cq_template_icmp_eq_i32_hl(%out, 2)`) and firing `cqrt_rz_i1` on it. The
; kickback reading the SELECT'S RESULT is the correctness check that matters here:
; `a` at that point in the source IS the select's value.
;
; (The one inversion, the a-mux before the `b1` prep, is the flagship's own and
; commutes: block-diagonal in `h0`'s basis, disjoint targets.)
;
; ⚠ THE H-1 BACKSTOP IS NOW UNREACHABLE AND MUST NOT BE DELETED. No hand IR can
; exercise it any more — rung 0 sets `PrepRegionIdx` for every φ it admits, so an
; admitted φ select always carries its edge. It is pinned instead by the
; COUNTERFACTUAL recorded in `FIX_M_R1.md`: revert the edge, and THIS module
; declines `control flow` again while `r18` (an inert third construct) and the
; owner's file are unaffected. It is the "a seventh emitter forgot the edge"
; tripwire.

;
; ⚠ THE STREAM PINS ARE ORDERED, NOT ADJACENT, and the reason is this module's and
; not a weakening: a `#dbg_value` record survives lowering between two of the
; gates, so no `CHECK-NEXT` chain can span the stream. ORDER is still pinned —
; which is what the X-bracket SCOPE depends on — and the count prefixes plus the
; pure negatives carry the rest.

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
; RUN: %filecheck %s --check-prefix=RZCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r03_order_third_region.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r03_order_third_region.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !21
  %2 = select i1 %1, i32 2, i32 5, !dbg !24
  br i1 %1, label %5, label %3, !dbg !25

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !26
  br label %5, !dbg !29

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ false, %0 ], !dbg !20
  %7 = add nsw i32 %2, -3
  %8 = select i1 %6, i32 %7, i32 %2, !dbg !30
  %9 = icmp eq i32 %8, 2, !dbg !31
  br i1 %9, label %10, label %11, !dbg !33

10:                                               ; preds = %5
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !34
  br label %11, !dbg !36

11:                                               ; preds = %10, %5
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !37
  %13 = zext i1 %12 to i32, !dbg !37
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !38
  %15 = zext i1 %14 to i32, !dbg !38
  %16 = add nuw nsw i32 %15, %13, !dbg !39
  %17 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !40
  %18 = add nsw i32 %16, %17, !dbg !41
  ret i32 %18, !dbg !42
}

declare !dbg !43 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !48 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !51 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !54 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r03_order_third_region.c", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "dac3bc8c3c8613e325fd0768eab26686")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 5, type: !12, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r03_order_third_region.c", directory: "", checksumkind: CSK_MD5, checksum: "dac3bc8c3c8613e325fd0768eab26686")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !19}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 6, type: !14)
!17 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 6, type: !18)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 6, type: !18)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 7, column: 24, scope: !22)
!22 = distinct !DILexicalBlock(scope: !23, file: !11, line: 7, column: 17)
!23 = distinct !DILexicalBlock(scope: !10, file: !11, line: 7, column: 9)
!24 = !DILocation(line: 8, column: 9, scope: !10)
!25 = !DILocation(line: 9, column: 9, scope: !10)
!26 = !DILocation(line: 9, column: 24, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !11, line: 9, column: 17)
!28 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 9)
!29 = !DILocation(line: 9, column: 43, scope: !27)
!30 = !DILocation(line: 10, column: 9, scope: !10)
!31 = !DILocation(line: 11, column: 11, scope: !32)
!32 = distinct !DILexicalBlock(scope: !10, file: !11, line: 11, column: 9)
!33 = !DILocation(line: 11, column: 9, scope: !10)
!34 = !DILocation(line: 11, column: 19, scope: !35)
!35 = distinct !DILexicalBlock(scope: !32, file: !11, line: 11, column: 17)
!36 = !DILocation(line: 11, column: 32, scope: !35)
!37 = !DILocation(line: 12, column: 12, scope: !10)
!38 = !DILocation(line: 12, column: 29, scope: !10)
!39 = !DILocation(line: 12, column: 27, scope: !10)
!40 = !DILocation(line: 12, column: 46, scope: !10)
!41 = !DILocation(line: 12, column: 44, scope: !10)
!42 = !DILocation(line: 12, column: 5, scope: !10)
!43 = !DISubprogram(name: "cq_theta_i1", scope: !44, file: !44, line: 32, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!45 = !DISubroutineType(types: !46)
!46 = !{!18, !18, !47}
!47 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!48 = !DISubprogram(name: "cq_phi", scope: !44, file: !44, line: 73, type: !49, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DISubroutineType(types: !50)
!50 = !{null, !47}
!51 = !DISubprogram(name: "cq_measure_i1", scope: !44, file: !44, line: 77, type: !52, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!52 = !DISubroutineType(types: !53)
!53 = !{!18, !18}
!54 = !DISubprogram(name: "cq_measure_si32", scope: !44, file: !44, line: 83, type: !55, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DISubroutineType(types: !56)
!56 = !{!14, !14}

; ---- The whole emitted stream, instruction for instruction.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK:      %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      %[[SELOP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[SELOP]], i32 %[[OUT]])
; CHECK:      call void @cqrt_x(i32 %[[BF]])
; CHECK:      %[[SELOP1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[SELOP1]], i32 %[[OUT]])
; CHECK:      call void @cqrt_x(i32 %[[BF]])
; CHECK:      call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK:      call void @cqrt_free(i32 %[[BF]])
; CHECK:      %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_ry_i1(i32 %[[H4]], double 5.000000e-01)
; CHECK:      call void @cqrt_ry_i1_controlled(i32 %[[H]], i32 %[[H4]], double -5.000000e-01)
; CHECK:      %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[OUT]], i32 -3)
; CHECK:      %[[BF2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_cnot(i32 %[[H4]], i32 %[[BF2]])
; CHECK:      %[[OUT3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[BF2]], i32 %[[H_OP]], i32 %[[OUT3]])
; CHECK:      call void @cqrt_x(i32 %[[BF2]])
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %[[BF2]], i32 %[[OUT]], i32 %[[OUT3]])
; CHECK:      call void @cqrt_x(i32 %[[BF2]])
; CHECK:      call void @cqrt_cnot(i32 %[[H4]], i32 %[[BF2]])
; CHECK:      call void @cqrt_free(i32 %[[BF2]])
; CHECK:      %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[OUT3]], i32 2)
; ---- F2-1 (round-2 review): the branch phase's TARGET and ANGLE, pinned.  This is
; the ONE gate in this increment that is a `cqrt_rz`, and the whole CORRECTNESS RISK
; §0 lesson is that a misplaced one is invisible to every other gate: it must fire on
; the MINTED FLAG %[[H_CMP]] (never on %[[H]] = b0, %[[H4]] = the prepped b1, or
; %[[OUT3]] = the user's `a`), and it must carry the SOURCE's angle 0.3.
; CHECK:      call void @cqrt_rz_i1(i32 %[[H_CMP]], double 3.000000e-01)
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[OUT3]], i32 2)
; CHECK:      call void @cqrt_free(i32 %[[H_CMP]])
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H]])
; CHECK:      %[[M5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H4]])
; CHECK:      %[[M6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT3]])

; ---- Whole-file negatives, each in its OWN pure-negative prefix (a positive
; line inside one WINDOWS every negative after it — the 3qlq F-L6-1 lesson).
; NOROUTE-NOT: cqrt_cswap
; ⚠ NO `cqrt_rz` NEGATIVE HERE, and that is this fixture's SUBJECT rather than a
; gap: the third region IS a register-free branch phase, so exactly ONE
; `cqrt_rz_i1` must appear — on the kickback's own minted FLAG, never on a user
; register or on a multi-bit register (restoring a `cqrt_rz_<W>` under control
; is what made every shipped Grover golden the identity). It is pinned
; positively by RZCNT below and — since the round-2 review's F2-1 — by a `CHECK`
; in the ordered stream above that names BOTH its target capture `%[[H_CMP]]` and
; its angle `3.000000e-01`; the `%h`/`%h4` negatives in NOX/NOFREE keep it off the
; user registers.  Before F2-1 the RZCNT count alone was satisfied by ANY rz, so
; moving the gate onto `%h`/`%h4`/`%out3` or changing 0.3→0.9 was MISSED by all 11
; prefixes of all 11 Track M accepts (`review_M_r2_probes/rz_mutation.sh`).
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
; NOFREE-NOT: call void @cqrt_free(i32 %out)
; NOFREE-NOT: call void @cqrt_free(i32 %h_op)
; The MERGE-OUT rail too (round-2 finding F2-3) — freeing the user's answer
; register is a hidden measurement (Rule 6), and it was named by no free
; negative here before.
; NOFREE-NOT: call void @cqrt_free(i32 %out3)
; XCNT-COUNT-4: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CNOTCNT-COUNT-4: call void @cqrt_cnot(
; CNOTCNT-NOT:     call void @cqrt_cnot(
; CPCNT-COUNT-4: call void @cqrt_copy_
; CPCNT-NOT:     call void @cqrt_copy_
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; RZCNT-COUNT-1: call void @cqrt_rz_i1(
; RZCNT-NOT:     call void @cqrt_rz
; ACNT-COUNT-8: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
