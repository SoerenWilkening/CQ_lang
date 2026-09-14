; ModuleID = 'src/r20b_vh_control_no_erase.c'
source_filename = "src/r20b_vh_control_no_erase.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !12 {
    #dbg_value(i32 %0, !17, !DIExpression(), !22)
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(i32 %2, !18, !DIExpression(), !22)
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #2, !dbg !24
    #dbg_value(i32 %3, !19, !DIExpression(), !22)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 2.500000e-01) #2, !dbg !25
    #dbg_value(i1 %4, !20, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i32 %3, !21, !DIExpression(), !22)
  br i1 %4, label %5, label %7, !dbg !26

5:                                                ; preds = %1
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666) #2, !dbg !27
    #dbg_value(i32 %6, !21, !DIExpression(), !22)
  br label %7, !dbg !30

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ %3, %1 ], !dbg !22
    #dbg_value(i32 %8, !21, !DIExpression(), !22)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !31
  ret i32 %9, !dbg !32
}

declare !dbg !33 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !38 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !41 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !42 {
    #dbg_value(i32 3, !17, !DIExpression(), !45)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #2, !dbg !47
    #dbg_value(i32 %1, !18, !DIExpression(), !45)
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2, !dbg !48
    #dbg_value(i32 %2, !19, !DIExpression(), !45)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 2.500000e-01) #2, !dbg !49
    #dbg_value(i1 %3, !20, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !45)
    #dbg_value(i32 %2, !21, !DIExpression(), !45)
  br i1 %3, label %4, label %6, !dbg !50

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666) #2, !dbg !51
    #dbg_value(i32 %5, !21, !DIExpression(), !45)
  br label %6, !dbg !52

6:                                                ; preds = %0, %4
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ], !dbg !45
    #dbg_value(i32 %7, !21, !DIExpression(), !45)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !53
  ret i32 %8, !dbg !54
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!11}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "src/r20b_vh_control_no_erase.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes", checksumkind: CSK_MD5, checksum: "a86e60c0c6b187facff3ffe0796e7cb9")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 4, type: !13, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15, !15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19, !20, !21}
!17 = !DILocalVariable(name: "u", arg: 1, scope: !12, file: !8, line: 4, type: !15)
!18 = !DILocalVariable(name: "q", scope: !12, file: !8, line: 4, type: !15)
!19 = !DILocalVariable(name: "a", scope: !12, file: !8, line: 4, type: !15)
!20 = !DILocalVariable(name: "f", scope: !12, file: !8, line: 5, type: !10)
!21 = !DILocalVariable(name: "r", scope: !12, file: !8, line: 5, type: !15)
!22 = !DILocation(line: 0, scope: !12)
!23 = !DILocation(line: 4, column: 25, scope: !12)
!24 = !DILocation(line: 4, column: 48, scope: !12)
!25 = !DILocation(line: 5, column: 10, scope: !12)
!26 = !DILocation(line: 6, column: 6, scope: !12)
!27 = !DILocation(line: 6, column: 12, scope: !28)
!28 = distinct !DILexicalBlock(scope: !29, file: !8, line: 6, column: 8)
!29 = distinct !DILexicalBlock(scope: !12, file: !8, line: 6, column: 6)
!30 = !DILocation(line: 6, column: 29, scope: !28)
!31 = !DILocation(line: 7, column: 10, scope: !12)
!32 = !DILocation(line: 7, column: 3, scope: !12)
!33 = !DISubprogram(name: "cq_theta_si32", scope: !34, file: !34, line: 38, type: !35, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!34 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!35 = !DISubroutineType(types: !36)
!36 = !{!15, !15, !37}
!37 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!38 = !DISubprogram(name: "cq_theta_i1", scope: !34, file: !34, line: 32, type: !39, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!39 = !DISubroutineType(types: !40)
!40 = !{!10, !10, !37}
!41 = !DISubprogram(name: "cq_measure_si32", scope: !34, file: !34, line: 83, type: !13, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 8, type: !43, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!43 = !DISubroutineType(types: !44)
!44 = !{!15}
!45 = !DILocation(line: 0, scope: !12, inlinedAt: !46)
!46 = distinct !DILocation(line: 8, column: 24, scope: !42)
!47 = !DILocation(line: 4, column: 25, scope: !12, inlinedAt: !46)
!48 = !DILocation(line: 4, column: 48, scope: !12, inlinedAt: !46)
!49 = !DILocation(line: 5, column: 10, scope: !12, inlinedAt: !46)
!50 = !DILocation(line: 6, column: 6, scope: !12, inlinedAt: !46)
!51 = !DILocation(line: 6, column: 12, scope: !28, inlinedAt: !46)
!52 = !DILocation(line: 6, column: 29, scope: !28, inlinedAt: !46)
!53 = !DILocation(line: 7, column: 10, scope: !12, inlinedAt: !46)
!54 = !DILocation(line: 8, column: 17, scope: !42)
