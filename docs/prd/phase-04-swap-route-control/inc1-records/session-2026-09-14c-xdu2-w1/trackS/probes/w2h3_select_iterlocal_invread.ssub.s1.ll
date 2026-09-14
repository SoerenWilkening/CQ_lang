; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/w2h3_select_iterlocal_invread.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/w2h3_select_iterlocal_invread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i32 %1, !17, !DIExpression(), !27)
    #dbg_value(i32 0, !18, !DIExpression(), !27)
    #dbg_value(i32 0, !19, !DIExpression(), !28)
  %2 = and i32 %1, 1
  br label %6, !dbg !29

3:                                                ; preds = %6
  %4 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !30
  %5 = add nsw i32 %4, %19, !dbg !31
  ret i32 %5, !dbg !32

6:                                                ; preds = %0, %6
  %7 = phi i32 [ 0, %0 ], [ %19, %6 ]
  %8 = phi i32 [ 0, %0 ], [ %20, %6 ]
    #dbg_value(i32 %7, !18, !DIExpression(), !27)
    #dbg_value(i32 %8, !19, !DIExpression(), !28)
  %9 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !33
    #dbg_value(i32 %9, !21, !DIExpression(), !34)
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !35
    #dbg_value(i1 %10, !24, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !34)
  %11 = select i1 %10, i32 2, i32 5, !dbg !36
    #dbg_value(i32 %11, !25, !DIExpression(), !34)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !37
  %13 = lshr i32 %9, 1, !dbg !38
  %14 = and i32 %13, 1, !dbg !38
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2, !dbg !38
  %16 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !39
  %17 = add i32 %12, %7, !dbg !40
  %18 = add i32 %17, %15, !dbg !41
  %19 = add i32 %18, %16, !dbg !42
    #dbg_value(i32 %19, !18, !DIExpression(), !27)
  %20 = add nuw nsw i32 %8, 1, !dbg !43
    #dbg_value(i32 %20, !19, !DIExpression(), !28)
  %21 = icmp eq i32 %8, 0, !dbg !44
  br i1 %21, label %6, label %3, !dbg !29, !llvm.loop !45
}

declare !dbg !49 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !54 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !57 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !60 {
  %1 = tail call i32 @slice(), !dbg !61
  ret i32 %1, !dbg !62
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/w2h3_select_iterlocal_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "8d5bb3b2c162a7bb479b626e2b78950e")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !13, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19, !21, !24, !25}
!17 = !DILocalVariable(name: "y", scope: !12, file: !8, line: 6, type: !15)
!18 = !DILocalVariable(name: "s", scope: !12, file: !8, line: 7, type: !15)
!19 = !DILocalVariable(name: "k", scope: !20, file: !8, line: 8, type: !15)
!20 = distinct !DILexicalBlock(scope: !12, file: !8, line: 8, column: 5)
!21 = !DILocalVariable(name: "u", scope: !22, file: !8, line: 9, type: !15)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 8, column: 33)
!23 = distinct !DILexicalBlock(scope: !20, file: !8, line: 8, column: 5)
!24 = !DILocalVariable(name: "b", scope: !22, file: !8, line: 10, type: !10)
!25 = !DILocalVariable(name: "a", scope: !22, file: !8, line: 11, type: !15)
!26 = !DILocation(line: 6, column: 13, scope: !12)
!27 = !DILocation(line: 0, scope: !12)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 8, column: 5, scope: !20)
!30 = !DILocation(line: 14, column: 16, scope: !12)
!31 = !DILocation(line: 14, column: 14, scope: !12)
!32 = !DILocation(line: 14, column: 5, scope: !12)
!33 = !DILocation(line: 9, column: 18, scope: !22)
!34 = !DILocation(line: 0, scope: !22)
!35 = !DILocation(line: 10, column: 18, scope: !22)
!36 = !DILocation(line: 11, column: 18, scope: !22)
!37 = !DILocation(line: 12, column: 14, scope: !22)
!38 = !DILocation(line: 12, column: 30, scope: !22)
!39 = !DILocation(line: 12, column: 57, scope: !22)
!40 = !DILocation(line: 12, column: 28, scope: !22)
!41 = !DILocation(line: 12, column: 55, scope: !22)
!42 = !DILocation(line: 12, column: 11, scope: !22)
!43 = !DILocation(line: 8, column: 28, scope: !23)
!44 = !DILocation(line: 8, column: 23, scope: !23)
!45 = distinct !{!45, !29, !46, !47, !48}
!46 = !DILocation(line: 13, column: 5, scope: !20)
!47 = !{!"llvm.loop.mustprogress"}
!48 = !{!"llvm.loop.unroll.disable"}
!49 = !DISubprogram(name: "cq_theta_si32", scope: !50, file: !50, line: 38, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!51 = !DISubroutineType(types: !52)
!52 = !{!15, !15, !53}
!53 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!54 = !DISubprogram(name: "cq_theta_i1", scope: !50, file: !50, line: 32, type: !55, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DISubroutineType(types: !56)
!56 = !{!10, !10, !53}
!57 = !DISubprogram(name: "cq_measure_si32", scope: !50, file: !50, line: 83, type: !58, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!58 = !DISubroutineType(types: !59)
!59 = !{!15, !15}
!60 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 16, type: !13, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!61 = !DILocation(line: 16, column: 25, scope: !60)
!62 = !DILocation(line: 16, column: 18, scope: !60)
