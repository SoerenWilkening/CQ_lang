; ModuleID = 'src/r30_delta_routing.c'
source_filename = "src/r30_delta_routing.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !22)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(i32 %2, !16, !DIExpression(), !22)
    #dbg_value(i32 5, !17, !DIExpression(), !22)
  %3 = icmp sgt i32 %2, 5, !dbg !24
  br i1 %3, label %4, label %6, !dbg !26

4:                                                ; preds = %1
  %5 = tail call i32 @ext_f(i32 noundef 7) #2, !dbg !27
    #dbg_value(i32 %5, !17, !DIExpression(), !22)
  br label %6, !dbg !28

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ 5, %1 ], !dbg !29
    #dbg_value(i32 %7, !17, !DIExpression(), !22)
  %8 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 4.000000e-01) #2, !dbg !30
    #dbg_value(i32 %8, !18, !DIExpression(), !22)
  %9 = icmp eq i32 %0, 0, !dbg !31
  %10 = select i1 %9, i32 %8, i32 %7, !dbg !31
    #dbg_value(i32 %10, !19, !DIExpression(), !22)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 2.500000e-01) #2, !dbg !32
    #dbg_value(i32 %11, !20, !DIExpression(), !22)
  %12 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 6.000000e-01) #2, !dbg !33
    #dbg_value(i32 %12, !21, !DIExpression(), !22)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !34
  %14 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !35
  %15 = add nsw i32 %14, %13, !dbg !36
  %16 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !37
  %17 = add nsw i32 %15, %16, !dbg !38
  ret i32 %17, !dbg !39
}

declare !dbg !40 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !45 i32 @ext_f(i32 noundef) local_unnamed_addr #1

declare !dbg !46 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !47 {
  %1 = tail call i32 @slice(i32 noundef 1), !dbg !50
  ret i32 %1, !dbg !51
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
!8 = !DIFile(filename: "src/r30_delta_routing.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes", checksumkind: CSK_MD5, checksum: "c3d634e3cf7e1674f533d433ab524943")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 7, type: !11, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !19, !20, !21}
!15 = !DILocalVariable(name: "u", arg: 1, scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 9, type: !13)
!18 = !DILocalVariable(name: "w", scope: !10, file: !8, line: 10, type: !13)
!19 = !DILocalVariable(name: "Z", scope: !10, file: !8, line: 11, type: !13)
!20 = !DILocalVariable(name: "rec", scope: !10, file: !8, line: 12, type: !13)
!21 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 13, type: !13)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 8, column: 11, scope: !10)
!24 = !DILocation(line: 9, column: 20, scope: !25)
!25 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 18)
!26 = !DILocation(line: 9, column: 18, scope: !10)
!27 = !DILocation(line: 9, column: 29, scope: !25)
!28 = !DILocation(line: 9, column: 25, scope: !25)
!29 = !DILocation(line: 9, scope: !10)
!30 = !DILocation(line: 10, column: 11, scope: !10)
!31 = !DILocation(line: 11, column: 11, scope: !10)
!32 = !DILocation(line: 12, column: 13, scope: !10)
!33 = !DILocation(line: 13, column: 13, scope: !10)
!34 = !DILocation(line: 14, column: 10, scope: !10)
!35 = !DILocation(line: 14, column: 28, scope: !10)
!36 = !DILocation(line: 14, column: 26, scope: !10)
!37 = !DILocation(line: 14, column: 44, scope: !10)
!38 = !DILocation(line: 14, column: 42, scope: !10)
!39 = !DILocation(line: 14, column: 3, scope: !10)
!40 = !DISubprogram(name: "cq_theta_si32", scope: !41, file: !41, line: 38, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!42 = !DISubroutineType(types: !43)
!43 = !{!13, !13, !44}
!44 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!45 = !DISubprogram(name: "ext_f", scope: !8, file: !8, line: 6, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DISubprogram(name: "cq_measure_si32", scope: !41, file: !41, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 16, type: !48, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!48 = !DISubroutineType(types: !49)
!49 = !{!13}
!50 = !DILocation(line: 16, column: 24, scope: !47)
!51 = !DILocation(line: 16, column: 17, scope: !47)
