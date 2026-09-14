; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r13_logical_select_data.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r13_logical_select_data.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #2, !dbg !21
    #dbg_value(i32 %1, !17, !DIExpression(), !22)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(i1 %2, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i8 0, !19, !DIExpression(), !22)
    #dbg_value(i32 0, !20, !DIExpression(), !22)
  br i1 %2, label %3, label %5, !dbg !24

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !25
    #dbg_value(i1 %4, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
  br label %5, !dbg !28

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ false, %0 ], !dbg !22
    #dbg_value(i8 poison, !19, !DIExpression(), !22)
  %7 = icmp sgt i32 %1, 3, !dbg !29
  %8 = select i1 %6, i1 %7, i1 false, !dbg !29
  %9 = select i1 %8, i32 2, i32 5, !dbg !30
    #dbg_value(i32 %9, !20, !DIExpression(), !22)
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2, !dbg !31
  %11 = zext i1 %10 to i32, !dbg !31
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !32
  %13 = zext i1 %12 to i32, !dbg !32
  %14 = add nuw nsw i32 %13, %11, !dbg !33
  %15 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !34
  %16 = add nsw i32 %14, %15, !dbg !35
  %17 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !36
  %18 = add nsw i32 %16, %17, !dbg !37
  ret i32 %18, !dbg !38
}

declare !dbg !39 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !44 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !47 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !50 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r13_logical_select_data.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "38f4be1da47eefa47ec22ecabe59dd21")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !13, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19, !20}
!17 = !DILocalVariable(name: "q", scope: !12, file: !8, line: 6, type: !15)
!18 = !DILocalVariable(name: "b0", scope: !12, file: !8, line: 7, type: !10)
!19 = !DILocalVariable(name: "b1", scope: !12, file: !8, line: 8, type: !10)
!20 = !DILocalVariable(name: "a", scope: !12, file: !8, line: 9, type: !15)
!21 = !DILocation(line: 6, column: 13, scope: !12)
!22 = !DILocation(line: 0, scope: !12)
!23 = !DILocation(line: 7, column: 15, scope: !12)
!24 = !DILocation(line: 10, column: 9, scope: !12)
!25 = !DILocation(line: 10, column: 20, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !8, line: 10, column: 13)
!27 = distinct !DILexicalBlock(scope: !12, file: !8, line: 10, column: 9)
!28 = !DILocation(line: 10, column: 39, scope: !26)
!29 = !DILocation(line: 11, column: 13, scope: !12)
!30 = !DILocation(line: 11, column: 9, scope: !12)
!31 = !DILocation(line: 12, column: 12, scope: !12)
!32 = !DILocation(line: 12, column: 29, scope: !12)
!33 = !DILocation(line: 12, column: 27, scope: !12)
!34 = !DILocation(line: 12, column: 46, scope: !12)
!35 = !DILocation(line: 12, column: 44, scope: !12)
!36 = !DILocation(line: 12, column: 62, scope: !12)
!37 = !DILocation(line: 12, column: 60, scope: !12)
!38 = !DILocation(line: 12, column: 5, scope: !12)
!39 = !DISubprogram(name: "cq_theta_si32", scope: !40, file: !40, line: 38, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!40 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!41 = !DISubroutineType(types: !42)
!42 = !{!15, !15, !43}
!43 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!44 = !DISubprogram(name: "cq_theta_i1", scope: !40, file: !40, line: 32, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DISubroutineType(types: !46)
!46 = !{!10, !10, !43}
!47 = !DISubprogram(name: "cq_measure_i1", scope: !40, file: !40, line: 77, type: !48, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!48 = !DISubroutineType(types: !49)
!49 = !{!10, !10}
!50 = !DISubprogram(name: "cq_measure_si32", scope: !40, file: !40, line: 83, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(types: !52)
!52 = !{!15, !15}
