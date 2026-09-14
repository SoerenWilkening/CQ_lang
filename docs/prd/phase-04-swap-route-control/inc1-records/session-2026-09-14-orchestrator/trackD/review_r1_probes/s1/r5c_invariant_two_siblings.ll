; ModuleID = 'src/r5c_invariant_two_siblings.c'
source_filename = "src/r5c_invariant_two_siblings.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !25)
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i32 %2, !16, !DIExpression(), !25)
  %3 = and i32 %2, 1, !dbg !27
    #dbg_value(i32 %3, !17, !DIExpression(), !25)
    #dbg_value(i32 0, !18, !DIExpression(), !25)
    #dbg_value(i32 0, !19, !DIExpression(), !28)
  br label %5, !dbg !29

4:                                                ; preds = %5
  ret i32 %13, !dbg !30

5:                                                ; preds = %1, %5
  %6 = phi i32 [ 0, %1 ], [ %13, %5 ]
  %7 = phi i32 [ 0, %1 ], [ %14, %5 ]
    #dbg_value(i32 %6, !18, !DIExpression(), !25)
    #dbg_value(i32 %7, !19, !DIExpression(), !28)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #2, !dbg !31
    #dbg_value(i32 %8, !21, !DIExpression(), !32)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 9.000000e-01) #2, !dbg !33
    #dbg_value(i32 %9, !24, !DIExpression(), !32)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !34
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !35
  %12 = add i32 %10, %6, !dbg !36
  %13 = add i32 %12, %11, !dbg !37
    #dbg_value(i32 %13, !18, !DIExpression(), !25)
  %14 = add nuw nsw i32 %7, 1, !dbg !38
    #dbg_value(i32 %14, !19, !DIExpression(), !28)
  %15 = icmp eq i32 %14, 3, !dbg !39
  br i1 %15, label %4, label %5, !dbg !29, !llvm.loop !40
}

declare !dbg !44 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !49 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !50 {
    #dbg_value(i32 3, !15, !DIExpression(), !53)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #2, !dbg !55
    #dbg_value(i32 %1, !16, !DIExpression(), !53)
  %2 = and i32 %1, 1, !dbg !56
    #dbg_value(i32 %2, !17, !DIExpression(), !53)
    #dbg_value(i32 0, !18, !DIExpression(), !53)
    #dbg_value(i32 0, !19, !DIExpression(), !57)
  br label %3, !dbg !58

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %11, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %12, %3 ]
    #dbg_value(i32 %4, !18, !DIExpression(), !53)
    #dbg_value(i32 %5, !19, !DIExpression(), !57)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #2, !dbg !59
    #dbg_value(i32 %6, !21, !DIExpression(), !60)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2, !dbg !61
    #dbg_value(i32 %7, !24, !DIExpression(), !60)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !62
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !63
  %10 = add i32 %8, %4, !dbg !64
  %11 = add i32 %10, %9, !dbg !65
    #dbg_value(i32 %11, !18, !DIExpression(), !53)
  %12 = add nuw nsw i32 %5, 1, !dbg !66
    #dbg_value(i32 %12, !19, !DIExpression(), !57)
  %13 = icmp eq i32 %12, 3, !dbg !67
  br i1 %13, label %14, label %3, !dbg !58, !llvm.loop !68

14:                                               ; preds = %3
  ret i32 %11, !dbg !70
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
!8 = !DIFile(filename: "src/r5c_invariant_two_siblings.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes", checksumkind: CSK_MD5, checksum: "45cb0b3c908d85d7635f7a70a25e6297")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !19, !21, !24}
!15 = !DILocalVariable(name: "u", arg: 1, scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "t", scope: !10, file: !8, line: 3, type: !13)
!18 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!19 = !DILocalVariable(name: "i", scope: !20, file: !8, line: 4, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!21 = !DILocalVariable(name: "b", scope: !22, file: !8, line: 4, type: !13)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 4, column: 23)
!23 = distinct !DILexicalBlock(scope: !20, file: !8, line: 4, column: 3)
!24 = !DILocalVariable(name: "c", scope: !22, file: !8, line: 4, type: !13)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 3, column: 25, scope: !10)
!27 = !DILocation(line: 3, column: 49, scope: !10)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 4, column: 3, scope: !20)
!30 = !DILocation(line: 4, column: 105, scope: !10)
!31 = !DILocation(line: 4, column: 31, scope: !22)
!32 = !DILocation(line: 0, scope: !22)
!33 = !DILocation(line: 4, column: 54, scope: !22)
!34 = !DILocation(line: 4, column: 74, scope: !22)
!35 = !DILocation(line: 4, column: 88, scope: !22)
!36 = !DILocation(line: 4, column: 87, scope: !22)
!37 = !DILocation(line: 4, column: 72, scope: !22)
!38 = !DILocation(line: 4, column: 20, scope: !23)
!39 = !DILocation(line: 4, column: 16, scope: !23)
!40 = distinct !{!40, !29, !41, !42, !43}
!41 = !DILocation(line: 4, column: 103, scope: !20)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = !DISubprogram(name: "cq_theta_si32", scope: !45, file: !45, line: 38, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!46 = !DISubroutineType(types: !47)
!47 = !{!13, !13, !48}
!48 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!49 = !DISubprogram(name: "cq_measure_si32", scope: !45, file: !45, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !51, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!51 = !DISubroutineType(types: !52)
!52 = !{!13}
!53 = !DILocation(line: 0, scope: !10, inlinedAt: !54)
!54 = distinct !DILocation(line: 5, column: 24, scope: !50)
!55 = !DILocation(line: 3, column: 25, scope: !10, inlinedAt: !54)
!56 = !DILocation(line: 3, column: 49, scope: !10, inlinedAt: !54)
!57 = !DILocation(line: 0, scope: !20, inlinedAt: !54)
!58 = !DILocation(line: 4, column: 3, scope: !20, inlinedAt: !54)
!59 = !DILocation(line: 4, column: 31, scope: !22, inlinedAt: !54)
!60 = !DILocation(line: 0, scope: !22, inlinedAt: !54)
!61 = !DILocation(line: 4, column: 54, scope: !22, inlinedAt: !54)
!62 = !DILocation(line: 4, column: 74, scope: !22, inlinedAt: !54)
!63 = !DILocation(line: 4, column: 88, scope: !22, inlinedAt: !54)
!64 = !DILocation(line: 4, column: 87, scope: !22, inlinedAt: !54)
!65 = !DILocation(line: 4, column: 72, scope: !22, inlinedAt: !54)
!66 = !DILocation(line: 4, column: 20, scope: !23, inlinedAt: !54)
!67 = !DILocation(line: 4, column: 16, scope: !23, inlinedAt: !54)
!68 = distinct !{!68, !58, !69, !42, !43}
!69 = !DILocation(line: 4, column: 103, scope: !20, inlinedAt: !54)
!70 = !DILocation(line: 5, column: 17, scope: !50)
