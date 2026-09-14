; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/vd.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/vd.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !15, !DIExpression(), !20)
    #dbg_value(i8 0, !16, !DIExpression(), !20)
    #dbg_value(i8 0, !18, !DIExpression(), !20)
    #dbg_value(i8 0, !19, !DIExpression(), !20)
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(i1 %1, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
    #dbg_value(i1 %1, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
    #dbg_value(i1 %1, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
  %2 = select i1 %1, i32 2, i32 5, !dbg !24
    #dbg_value(i32 %2, !15, !DIExpression(), !20)
  br i1 %1, label %5, label %3, !dbg !25

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i1 %4, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
  br label %5, !dbg !29

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ false, %0 ], !dbg !20
    #dbg_value(i8 poison, !18, !DIExpression(), !20)
  %7 = add nsw i32 %2, -3
  %8 = select i1 %6, i32 %7, i32 %2, !dbg !30
    #dbg_value(i32 %8, !15, !DIExpression(), !20)
  %9 = icmp sgt i32 %8, 2, !dbg !31
  br i1 %9, label %10, label %12, !dbg !33

10:                                               ; preds = %5
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !34
    #dbg_value(i1 %11, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
  br label %12, !dbg !36

12:                                               ; preds = %10, %5
  %13 = phi i1 [ %11, %10 ], [ false, %5 ], !dbg !20
    #dbg_value(i8 poison, !19, !DIExpression(), !20)
  %14 = add nsw i32 %8, -3
  %15 = select i1 %13, i32 %14, i32 %8, !dbg !37
    #dbg_value(i32 %15, !15, !DIExpression(), !20)
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !38
  %17 = zext i1 %16 to i32, !dbg !38
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !39
  %19 = zext i1 %18 to i32, !dbg !39
  %20 = add nuw nsw i32 %19, %17, !dbg !40
  %21 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13) #2, !dbg !41
  %22 = zext i1 %21 to i32, !dbg !41
  %23 = add nuw nsw i32 %20, %22, !dbg !42
  %24 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !43
  %25 = add nsw i32 %23, %24, !dbg !44
  ret i32 %25, !dbg !45
}

declare !dbg !46 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/vd.c", directory: "/Users/sorenwilkening/Desktop/CQ_f2phi", checksumkind: CSK_MD5, checksum: "a30ea6d7fe196c04b3acc1e3f104d008")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !19}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 5, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "b1", scope: !10, file: !8, line: 6, type: !17)
!19 = !DILocalVariable(name: "b2", scope: !10, file: !8, line: 7, type: !17)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 10, column: 14, scope: !22)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 9, column: 16)
!23 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 9)
!24 = !DILocation(line: 12, column: 9, scope: !10)
!25 = !DILocation(line: 14, column: 9, scope: !10)
!26 = !DILocation(line: 15, column: 14, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !8, line: 14, column: 16)
!28 = distinct !DILexicalBlock(scope: !10, file: !8, line: 14, column: 9)
!29 = !DILocation(line: 16, column: 5, scope: !27)
!30 = !DILocation(line: 17, column: 9, scope: !10)
!31 = !DILocation(line: 19, column: 11, scope: !32)
!32 = distinct !DILexicalBlock(scope: !10, file: !8, line: 19, column: 9)
!33 = !DILocation(line: 19, column: 9, scope: !10)
!34 = !DILocation(line: 20, column: 14, scope: !35)
!35 = distinct !DILexicalBlock(scope: !32, file: !8, line: 19, column: 16)
!36 = !DILocation(line: 21, column: 5, scope: !35)
!37 = !DILocation(line: 22, column: 9, scope: !10)
!38 = !DILocation(line: 24, column: 12, scope: !10)
!39 = !DILocation(line: 24, column: 29, scope: !10)
!40 = !DILocation(line: 24, column: 27, scope: !10)
!41 = !DILocation(line: 24, column: 46, scope: !10)
!42 = !DILocation(line: 24, column: 44, scope: !10)
!43 = !DILocation(line: 24, column: 63, scope: !10)
!44 = !DILocation(line: 24, column: 61, scope: !10)
!45 = !DILocation(line: 24, column: 5, scope: !10)
!46 = !DISubprogram(name: "cq_theta_i1", scope: !47, file: !47, line: 32, type: !48, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_f2phi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!48 = !DISubroutineType(types: !49)
!49 = !{!17, !17, !50}
!50 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!51 = !DISubprogram(name: "cq_measure_i1", scope: !47, file: !47, line: 77, type: !52, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!52 = !DISubroutineType(types: !53)
!53 = !{!17, !17}
!54 = !DISubprogram(name: "cq_measure_si32", scope: !47, file: !47, line: 83, type: !55, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DISubroutineType(types: !56)
!56 = !{!13, !13}
