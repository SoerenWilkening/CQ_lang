; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r24_deep_tree_phi.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r24_deep_tree_phi.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #2, !dbg !21
    #dbg_value(i32 %1, !17, !DIExpression(), !22)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 9.000000e-01) #2, !dbg !23
    #dbg_value(i32 %2, !18, !DIExpression(), !22)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !24
    #dbg_value(i1 %3, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i8 0, !20, !DIExpression(), !22)
  br i1 %3, label %4, label %6, !dbg !25

4:                                                ; preds = %0
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i1 %5, !20, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
  br label %6, !dbg !29

6:                                                ; preds = %4, %0
  %7 = phi i1 [ %5, %4 ], [ false, %0 ], !dbg !22
    #dbg_value(i8 poison, !20, !DIExpression(), !22)
  %8 = icmp sgt i32 %1, 3, !dbg !30
  %9 = icmp sgt i32 %2, 5
  %10 = select i1 %8, i1 %7, i1 false, !dbg !32
  %11 = select i1 %10, i1 %9, i1 false, !dbg !32
  br i1 %11, label %12, label %13, !dbg !32

12:                                               ; preds = %6
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !33
  br label %13, !dbg !33

13:                                               ; preds = %12, %6
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #2, !dbg !34
  %15 = zext i1 %14 to i32, !dbg !34
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #2, !dbg !35
  %17 = zext i1 %16 to i32, !dbg !35
  %18 = add nuw nsw i32 %17, %15, !dbg !36
  %19 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !37
  %20 = add nsw i32 %18, %19, !dbg !38
  %21 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !39
  %22 = add nsw i32 %20, %21, !dbg !40
  ret i32 %22, !dbg !41
}

declare !dbg !42 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !47 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !50 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !53 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !56 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r24_deep_tree_phi.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "71ba7377217fcb5f74887d57cbf85bc9")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !13, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19, !20}
!17 = !DILocalVariable(name: "q", scope: !12, file: !8, line: 5, type: !15)
!18 = !DILocalVariable(name: "r", scope: !12, file: !8, line: 6, type: !15)
!19 = !DILocalVariable(name: "b0", scope: !12, file: !8, line: 7, type: !10)
!20 = !DILocalVariable(name: "b1", scope: !12, file: !8, line: 8, type: !10)
!21 = !DILocation(line: 5, column: 13, scope: !12)
!22 = !DILocation(line: 0, scope: !12)
!23 = !DILocation(line: 6, column: 13, scope: !12)
!24 = !DILocation(line: 7, column: 15, scope: !12)
!25 = !DILocation(line: 9, column: 9, scope: !12)
!26 = !DILocation(line: 9, column: 20, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !8, line: 9, column: 13)
!28 = distinct !DILexicalBlock(scope: !12, file: !8, line: 9, column: 9)
!29 = !DILocation(line: 9, column: 39, scope: !27)
!30 = !DILocation(line: 10, column: 11, scope: !31)
!31 = distinct !DILexicalBlock(scope: !12, file: !8, line: 10, column: 9)
!32 = !DILocation(line: 10, column: 15, scope: !31)
!33 = !DILocation(line: 10, column: 33, scope: !31)
!34 = !DILocation(line: 11, column: 12, scope: !12)
!35 = !DILocation(line: 11, column: 29, scope: !12)
!36 = !DILocation(line: 11, column: 27, scope: !12)
!37 = !DILocation(line: 11, column: 46, scope: !12)
!38 = !DILocation(line: 11, column: 44, scope: !12)
!39 = !DILocation(line: 11, column: 62, scope: !12)
!40 = !DILocation(line: 11, column: 60, scope: !12)
!41 = !DILocation(line: 11, column: 5, scope: !12)
!42 = !DISubprogram(name: "cq_theta_si32", scope: !43, file: !43, line: 38, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!44 = !DISubroutineType(types: !45)
!45 = !{!15, !15, !46}
!46 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!47 = !DISubprogram(name: "cq_theta_i1", scope: !43, file: !43, line: 32, type: !48, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!48 = !DISubroutineType(types: !49)
!49 = !{!10, !10, !46}
!50 = !DISubprogram(name: "cq_phi", scope: !43, file: !43, line: 73, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(types: !52)
!52 = !{null, !46}
!53 = !DISubprogram(name: "cq_measure_i1", scope: !43, file: !43, line: 77, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!54 = !DISubroutineType(types: !55)
!55 = !{!10, !10}
!56 = !DISubprogram(name: "cq_measure_si32", scope: !43, file: !43, line: 83, type: !57, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!57 = !DISubroutineType(types: !58)
!58 = !{!15, !15}
