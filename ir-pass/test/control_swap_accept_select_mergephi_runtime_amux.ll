; control_swap_accept_select_mergephi_runtime_amux.ll — ACCEPT, and it is the most
; GENERAL form of the owner's cascade: nothing constant-folds. bd `boi6` D-B /
; Track M, probe `m16`. RED ON THE ORACLE (`control flow` at the select).
;
; `volatile int av = 5; int a = av;` makes `a` a run-time value, so the owner's
; guards stay REAL quantum compares instead of folding away. The result is the
; whole chain in one module: the `b0` rail, then `if (b0 == 1) a -= 3` as a
; rail-root CNOT-copy merge producing a QUANTUM `a`, then `if (a >= 3)` as a
; genuine compare ON THAT QUANTUM `a` (`-O1` canonicalizes it to `icmp sgt .. 2`)
; whose flag controls the `b1` state prep, and finally line 99's select on the
; prep's merge φ.
;
; WHY IT IS HERE. It is the joint witness for the two things Track M changed: the
; φ admitted as a leaf, AND rung 0 accepting a region whose ladder was the COMPARE
; one (ruling item 2 — this program's prep is guarded by a compare over a quantum
; register, so `RailLadderProven` is false for it). Before item 2 this module
; declined even with the φ admitted.
;
; THREE `cqrt_free`, ALL proven-|0>: the a-mux ancilla, the compare flag (returned
; to |0> by its own `_unc` strip), and the select's ancilla. The two USER
; REGISTERS — `%h` (b0) and `%h6` (b1) — appear ONLY at arg 0 of `cqrt_cnot` or as
; the CONTROL of `cqrt_ry_i1_controlled`: read-only, never `cqrt_x`-bracketed,
; never freed (Rule 6).

;
; ⚠ THE STREAM PINS BELOW ARE ORDERED, NOT ADJACENT, and the reason is a property
; of THIS module rather than a weakening: the `volatile` load leaves real basic
; blocks that `RegionFlatten` does not collapse, so the gate stream is interrupted
; by `br label` terminators. ORDER is still pinned — which is what the X-bracket
; SCOPE depends on — and the count prefixes plus the pure negatives below carry
; the rest. Every other accept in this family pins adjacency as well.

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

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m16.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m16.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1), !dbg !22
    #dbg_declare(ptr %1, !16, !DIExpression(), !23)
  store volatile i32 5, ptr %1, align 4, !dbg !23, !tbaa !24
  %2 = load volatile i32, ptr %1, align 4, !dbg !28, !tbaa !24
  %3 = icmp sgt i32 %2, 2, !dbg !30
  br i1 %3, label %4, label %6, !dbg !32

4:                                                ; preds = %0
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #3, !dbg !33
  br label %6, !dbg !35

6:                                                ; preds = %4, %0
  %7 = phi i1 [ %5, %4 ], [ false, %0 ], !dbg !29
  %8 = add nsw i32 %2, -3
  %9 = select i1 %7, i32 %8, i32 %2, !dbg !36
  %10 = icmp sgt i32 %9, 2, !dbg !37
  br i1 %10, label %11, label %13, !dbg !39

11:                                               ; preds = %6
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #3, !dbg !40
  br label %13, !dbg !42

13:                                               ; preds = %11, %6
  %14 = phi i1 [ %12, %11 ], [ false, %6 ], !dbg !29
  %15 = add nsw i32 %9, -3
  %16 = select i1 %14, i32 %15, i32 %9, !dbg !43
  %17 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #3, !dbg !44
  %18 = zext i1 %17 to i32, !dbg !44
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %14) #3, !dbg !45
  %20 = zext i1 %19 to i32, !dbg !45
  %21 = add nuw nsw i32 %20, %18, !dbg !46
  %22 = tail call i32 @cq_measure_si32(i32 noundef %16) #3, !dbg !47
  %23 = add nsw i32 %21, %22, !dbg !48
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1), !dbg !49
  ret i32 %23, !dbg !50
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare !dbg !51 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare !dbg !56 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

declare !dbg !59 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m16.c", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "659ca9244cfc0cf6413e349647d6435d")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 3, type: !12, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m16.c", directory: "", checksumkind: CSK_MD5, checksum: "659ca9244cfc0cf6413e349647d6435d")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !18, !19, !21}
!16 = !DILocalVariable(name: "av", scope: !10, file: !11, line: 4, type: !17)
!17 = !DIDerivedType(tag: DW_TAG_volatile_type, baseType: !14)
!18 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 5, type: !14)
!19 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 6, type: !20)
!20 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!21 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 7, type: !20)
!22 = !DILocation(line: 4, column: 5, scope: !10)
!23 = !DILocation(line: 4, column: 18, scope: !10)
!24 = !{!25, !25, i64 0}
!25 = !{!"int", !26, i64 0}
!26 = !{!"omnipotent char", !27, i64 0}
!27 = !{!"Simple C/C++ TBAA"}
!28 = !DILocation(line: 5, column: 13, scope: !10)
!29 = !DILocation(line: 0, scope: !10)
!30 = !DILocation(line: 8, column: 11, scope: !31)
!31 = distinct !DILexicalBlock(scope: !10, file: !11, line: 8, column: 9)
!32 = !DILocation(line: 8, column: 9, scope: !10)
!33 = !DILocation(line: 8, column: 23, scope: !34)
!34 = distinct !DILexicalBlock(scope: !31, file: !11, line: 8, column: 16)
!35 = !DILocation(line: 8, column: 42, scope: !34)
!36 = !DILocation(line: 9, column: 9, scope: !10)
!37 = !DILocation(line: 10, column: 11, scope: !38)
!38 = distinct !DILexicalBlock(scope: !10, file: !11, line: 10, column: 9)
!39 = !DILocation(line: 10, column: 9, scope: !10)
!40 = !DILocation(line: 10, column: 23, scope: !41)
!41 = distinct !DILexicalBlock(scope: !38, file: !11, line: 10, column: 16)
!42 = !DILocation(line: 10, column: 42, scope: !41)
!43 = !DILocation(line: 11, column: 9, scope: !10)
!44 = !DILocation(line: 12, column: 12, scope: !10)
!45 = !DILocation(line: 12, column: 29, scope: !10)
!46 = !DILocation(line: 12, column: 27, scope: !10)
!47 = !DILocation(line: 12, column: 46, scope: !10)
!48 = !DILocation(line: 12, column: 44, scope: !10)
!49 = !DILocation(line: 13, column: 1, scope: !10)
!50 = !DILocation(line: 12, column: 5, scope: !10)
!51 = !DISubprogram(name: "cq_theta_i1", scope: !52, file: !52, line: 32, type: !53, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!52 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!53 = !DISubroutineType(types: !54)
!54 = !{!20, !20, !55}
!55 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!56 = !DISubprogram(name: "cq_measure_i1", scope: !52, file: !52, line: 77, type: !57, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!57 = !DISubroutineType(types: !58)
!58 = !{!20, !20}
!59 = !DISubprogram(name: "cq_measure_si32", scope: !52, file: !52, line: 83, type: !60, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!60 = !DISubroutineType(types: !61)
!61 = !{!14, !14}

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
; CHECK:      %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[OUT]], i32 2)
; CHECK:      %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      call void @cqrt_ry_i1_controlled(i32 %[[H_CMP]], i32 %[[H4]], double 5.000000e-01)
; CHECK:      call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP]], i32 %[[OUT]], i32 2)
; CHECK:      call void @cqrt_free(i32 %[[H_CMP]])
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
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H]])
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
;   ⚠ EVERY HANDLE NAMED IN A PURE-NEGATIVE PREFIX IS DERIVED FROM THE PASS
;     OUTPUT AND RE-CHECKED. A `-NOT` naming a handle the module never defines is
;     VACUOUS — it passes for the wrong reason, the same way a bare `NOT: phi`
;     passed by matching the module PATH. Five such negatives shipped in this
;     family's first cut and were caught by the injection matrix (an injected
;     `cqrt_x` on the SECOND user register reddened XCNT but not NOX); a
;     name-existence check now runs over every accept (`probes/impl/vacuity.py`).
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
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; ACNT-COUNT-8: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
