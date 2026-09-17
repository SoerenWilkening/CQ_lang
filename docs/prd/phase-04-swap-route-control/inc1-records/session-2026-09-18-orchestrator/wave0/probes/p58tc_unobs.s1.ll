; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_unobs.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_unobs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !25)
    #dbg_value(i32 %1, !16, !DIExpression(), !25)
    #dbg_value(i32 0, !17, !DIExpression(), !25)
    #dbg_value(i32 0, !18, !DIExpression(), !26)
  %3 = icmp sgt i32 %1, 0, !dbg !27
  br i1 %3, label %6, label %4, !dbg !28

4:                                                ; preds = %6, %2
  %5 = phi i32 [ 0, %2 ], [ %13, %6 ], !dbg !25
  ret i32 %5, !dbg !29

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %13, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %14, %6 ], [ 0, %2 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !25)
    #dbg_value(i32 %8, !18, !DIExpression(), !26)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2, !dbg !30
    #dbg_value(i32 %9, !20, !DIExpression(), !31)
  %10 = shl nsw i32 %9, 1, !dbg !32
    #dbg_value(i32 %10, !23, !DIExpression(), !31)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 5.000000e-01) #2, !dbg !33
    #dbg_value(i32 %11, !23, !DIExpression(), !31)
    #dbg_value(i32 %9, !24, !DIExpression(DW_OP_constu, 3, DW_OP_mul, DW_OP_stack_value), !31)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !34
  %13 = add nsw i32 %12, %7, !dbg !35
    #dbg_value(i32 %13, !17, !DIExpression(), !25)
  %14 = add nuw nsw i32 %8, 1, !dbg !36
    #dbg_value(i32 %14, !18, !DIExpression(), !26)
  %15 = icmp eq i32 %14, %1, !dbg !27
  br i1 %15, label %4, label %6, !dbg !28, !llvm.loop !37
}

declare !dbg !41 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !46 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !49 {
    #dbg_value(i32 1, !15, !DIExpression(), !52)
    #dbg_value(i32 3, !16, !DIExpression(), !52)
    #dbg_value(i32 0, !17, !DIExpression(), !52)
    #dbg_value(i32 0, !18, !DIExpression(), !54)
  br label %1

1:                                                ; preds = %1, %0
  %2 = phi i32 [ %8, %1 ], [ 0, %0 ]
  %3 = phi i32 [ %9, %1 ], [ 0, %0 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !52)
    #dbg_value(i32 %3, !18, !DIExpression(), !54)
  %4 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 2.500000e-01) #2, !dbg !55
    #dbg_value(i32 %4, !20, !DIExpression(), !56)
  %5 = shl nsw i32 %4, 1, !dbg !57
    #dbg_value(i32 %5, !23, !DIExpression(), !56)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #2, !dbg !58
    #dbg_value(i32 %6, !23, !DIExpression(), !56)
    #dbg_value(i32 %4, !24, !DIExpression(DW_OP_constu, 3, DW_OP_mul, DW_OP_stack_value), !56)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !59
  %8 = add nsw i32 %7, %2, !dbg !60
    #dbg_value(i32 %8, !17, !DIExpression(), !52)
  %9 = add nuw nsw i32 %3, 1, !dbg !61
    #dbg_value(i32 %9, !18, !DIExpression(), !54)
  %10 = icmp eq i32 %9, 3, !dbg !62
  br i1 %10, label %11, label %1, !dbg !63, !llvm.loop !64

11:                                               ; preds = %1
  ret i32 %8, !dbg !66
}

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_unobs.c", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang", checksumkind: CSK_MD5, checksum: "bb344eb151a0c29518d949791d347224")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 1, type: !11, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !20, !23, !24}
!15 = !DILocalVariable(name: "x", arg: 1, scope: !10, file: !8, line: 1, type: !13)
!16 = !DILocalVariable(name: "n", arg: 2, scope: !10, file: !8, line: 1, type: !13)
!17 = !DILocalVariable(name: "acc", scope: !10, file: !8, line: 2, type: !13)
!18 = !DILocalVariable(name: "i", scope: !19, file: !8, line: 3, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 3)
!20 = !DILocalVariable(name: "q", scope: !21, file: !8, line: 4, type: !13)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 3, column: 31)
!22 = distinct !DILexicalBlock(scope: !19, file: !8, line: 3, column: 3)
!23 = !DILocalVariable(name: "w", scope: !21, file: !8, line: 5, type: !13)
!24 = !DILocalVariable(name: "z", scope: !21, file: !8, line: 7, type: !13)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 0, scope: !19)
!27 = !DILocation(line: 3, column: 21, scope: !22)
!28 = !DILocation(line: 3, column: 3, scope: !19)
!29 = !DILocation(line: 11, column: 3, scope: !10)
!30 = !DILocation(line: 4, column: 13, scope: !21)
!31 = !DILocation(line: 0, scope: !21)
!32 = !DILocation(line: 5, column: 15, scope: !21)
!33 = !DILocation(line: 6, column: 9, scope: !21)
!34 = !DILocation(line: 9, column: 12, scope: !21)
!35 = !DILocation(line: 9, column: 9, scope: !21)
!36 = !DILocation(line: 3, column: 26, scope: !22)
!37 = distinct !{!37, !28, !38, !39, !40}
!38 = !DILocation(line: 10, column: 3, scope: !19)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = !DISubprogram(name: "cq_theta_si32", scope: !42, file: !42, line: 38, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!43 = !DISubroutineType(types: !44)
!44 = !{!13, !13, !45}
!45 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!46 = !DISubprogram(name: "cq_measure_si32", scope: !42, file: !42, line: 83, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DISubroutineType(types: !48)
!48 = !{!13, !13}
!49 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !50, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!50 = !DISubroutineType(types: !51)
!51 = !{!13}
!52 = !DILocation(line: 0, scope: !10, inlinedAt: !53)
!53 = distinct !DILocation(line: 13, column: 25, scope: !49)
!54 = !DILocation(line: 0, scope: !19, inlinedAt: !53)
!55 = !DILocation(line: 4, column: 13, scope: !21, inlinedAt: !53)
!56 = !DILocation(line: 0, scope: !21, inlinedAt: !53)
!57 = !DILocation(line: 5, column: 15, scope: !21, inlinedAt: !53)
!58 = !DILocation(line: 6, column: 9, scope: !21, inlinedAt: !53)
!59 = !DILocation(line: 9, column: 12, scope: !21, inlinedAt: !53)
!60 = !DILocation(line: 9, column: 9, scope: !21, inlinedAt: !53)
!61 = !DILocation(line: 3, column: 26, scope: !22, inlinedAt: !53)
!62 = !DILocation(line: 3, column: 21, scope: !22, inlinedAt: !53)
!63 = !DILocation(line: 3, column: 3, scope: !19, inlinedAt: !53)
!64 = distinct !{!64, !63, !65, !39, !40}
!65 = !DILocation(line: 10, column: 3, scope: !19, inlinedAt: !53)
!66 = !DILocation(line: 13, column: 18, scope: !49)
