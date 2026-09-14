; ModuleID = 'src/r5a_while_runtime_trip.c'
source_filename = "src/r5a_while_runtime_trip.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !23)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !24
    #dbg_value(i32 %2, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !23)
    #dbg_value(i32 0, !18, !DIExpression(), !25)
  %3 = icmp sgt i32 %0, 0, !dbg !26
  br i1 %3, label %6, label %4, !dbg !27

4:                                                ; preds = %6, %1
  %5 = phi i32 [ 0, %1 ], [ %11, %6 ], !dbg !28
  ret i32 %5, !dbg !29

6:                                                ; preds = %1, %6
  %7 = phi i32 [ %11, %6 ], [ 0, %1 ]
  %8 = phi i32 [ %12, %6 ], [ 0, %1 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !23)
    #dbg_value(i32 %8, !18, !DIExpression(), !25)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 1.000000e-01) #2, !dbg !30
    #dbg_value(i32 %9, !20, !DIExpression(), !31)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !32
  %11 = add nsw i32 %10, %7, !dbg !33
    #dbg_value(i32 %11, !17, !DIExpression(), !23)
  %12 = add nuw nsw i32 %8, 1, !dbg !34
    #dbg_value(i32 %12, !18, !DIExpression(), !25)
  %13 = icmp eq i32 %12, %0, !dbg !26
  br i1 %13, label %4, label %6, !dbg !27, !llvm.loop !35
}

declare !dbg !39 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !44 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !45 {
    #dbg_value(i32 3, !15, !DIExpression(), !48)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !50
    #dbg_value(i32 %1, !16, !DIExpression(), !48)
    #dbg_value(i32 0, !17, !DIExpression(), !48)
    #dbg_value(i32 0, !18, !DIExpression(), !51)
  br label %2

2:                                                ; preds = %2, %0
  %3 = phi i32 [ %7, %2 ], [ 0, %0 ]
  %4 = phi i32 [ %8, %2 ], [ 0, %0 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !48)
    #dbg_value(i32 %4, !18, !DIExpression(), !51)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e-01) #2, !dbg !52
    #dbg_value(i32 %5, !20, !DIExpression(), !53)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !54
  %7 = add nsw i32 %6, %3, !dbg !55
    #dbg_value(i32 %7, !17, !DIExpression(), !48)
  %8 = add nuw nsw i32 %4, 1, !dbg !56
    #dbg_value(i32 %8, !18, !DIExpression(), !51)
  %9 = icmp eq i32 %8, 3, !dbg !57
  br i1 %9, label %10, label %2, !dbg !58, !llvm.loop !59

10:                                               ; preds = %2
  ret i32 %7, !dbg !61
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
!8 = !DIFile(filename: "src/r5a_while_runtime_trip.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes", checksumkind: CSK_MD5, checksum: "6fb911af9df2b3a7e0a5bd064a75b7f0")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !20}
!15 = !DILocalVariable(name: "n", arg: 1, scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!18 = !DILocalVariable(name: "i", scope: !19, file: !8, line: 3, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 51)
!20 = !DILocalVariable(name: "b", scope: !21, file: !8, line: 3, type: !13)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 3, column: 71)
!22 = distinct !DILexicalBlock(scope: !19, file: !8, line: 3, column: 51)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 3, column: 25, scope: !10)
!25 = !DILocation(line: 0, scope: !19)
!26 = !DILocation(line: 3, column: 64, scope: !22)
!27 = !DILocation(line: 3, column: 51, scope: !19)
!28 = !DILocation(line: 3, scope: !10)
!29 = !DILocation(line: 3, column: 116, scope: !10)
!30 = !DILocation(line: 3, column: 79, scope: !21)
!31 = !DILocation(line: 0, scope: !21)
!32 = !DILocation(line: 3, column: 99, scope: !21)
!33 = !DILocation(line: 3, column: 97, scope: !21)
!34 = !DILocation(line: 3, column: 68, scope: !22)
!35 = distinct !{!35, !27, !36, !37, !38}
!36 = !DILocation(line: 3, column: 114, scope: !19)
!37 = !{!"llvm.loop.mustprogress"}
!38 = !{!"llvm.loop.unroll.disable"}
!39 = !DISubprogram(name: "cq_theta_si32", scope: !40, file: !40, line: 38, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!40 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!41 = !DISubroutineType(types: !42)
!42 = !{!13, !13, !43}
!43 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!44 = !DISubprogram(name: "cq_measure_si32", scope: !40, file: !40, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !46, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!46 = !DISubroutineType(types: !47)
!47 = !{!13}
!48 = !DILocation(line: 0, scope: !10, inlinedAt: !49)
!49 = distinct !DILocation(line: 4, column: 24, scope: !45)
!50 = !DILocation(line: 3, column: 25, scope: !10, inlinedAt: !49)
!51 = !DILocation(line: 0, scope: !19, inlinedAt: !49)
!52 = !DILocation(line: 3, column: 79, scope: !21, inlinedAt: !49)
!53 = !DILocation(line: 0, scope: !21, inlinedAt: !49)
!54 = !DILocation(line: 3, column: 99, scope: !21, inlinedAt: !49)
!55 = !DILocation(line: 3, column: 97, scope: !21, inlinedAt: !49)
!56 = !DILocation(line: 3, column: 68, scope: !22, inlinedAt: !49)
!57 = !DILocation(line: 3, column: 64, scope: !22, inlinedAt: !49)
!58 = !DILocation(line: 3, column: 51, scope: !19, inlinedAt: !49)
!59 = distinct !{!59, !58, !60, !37, !38}
!60 = !DILocation(line: 3, column: 114, scope: !19, inlinedAt: !49)
!61 = !DILocation(line: 4, column: 17, scope: !45)
