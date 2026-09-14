; ModuleID = 'src/oa1u_inbody_later_use.c'
source_filename = "src/oa1u_inbody_later_use.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !24
    #dbg_value(i32 %1, !15, !DIExpression(), !25)
    #dbg_value(i32 0, !16, !DIExpression(), !25)
    #dbg_value(i32 0, !17, !DIExpression(), !26)
  br label %3, !dbg !27

2:                                                ; preds = %3
  ret i32 %13, !dbg !28

3:                                                ; preds = %0, %3
  %4 = phi i32 [ %1, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %13, %3 ]
  %6 = phi i32 [ 0, %0 ], [ %14, %3 ]
    #dbg_value(i32 %4, !15, !DIExpression(), !25)
    #dbg_value(i32 %5, !16, !DIExpression(), !25)
    #dbg_value(i32 %6, !17, !DIExpression(), !26)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 1.000000e-01) #2, !dbg !29
    #dbg_value(i32 %7, !19, !DIExpression(), !30)
  %8 = add nsw i32 %7, 1, !dbg !31
    #dbg_value(i32 %8, !22, !DIExpression(), !30)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !32
  %10 = add nsw i32 %9, %5, !dbg !33
    #dbg_value(i32 %10, !16, !DIExpression(), !25)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 2.000000e-01) #2, !dbg !34
    #dbg_value(i32 %11, !23, !DIExpression(), !30)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !35
  %13 = add nsw i32 %10, %12, !dbg !36
    #dbg_value(i32 %13, !16, !DIExpression(), !25)
    #dbg_value(i32 %7, !15, !DIExpression(), !25)
  %14 = add nuw nsw i32 %6, 1, !dbg !37
    #dbg_value(i32 %14, !17, !DIExpression(), !26)
  %15 = icmp eq i32 %14, 3, !dbg !38
  br i1 %15, label %2, label %3, !dbg !27, !llvm.loop !39
}

declare !dbg !43 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !48 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/oa1u_inbody_later_use.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "57f5a86bb5b6706e0bc68b484a20ab84")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19, !22, !23}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 5, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 6, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 3)
!19 = !DILocalVariable(name: "a", scope: !20, file: !8, line: 6, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 6, column: 23)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 6, column: 3)
!22 = !DILocalVariable(name: "d", scope: !20, file: !8, line: 6, type: !13)
!23 = !DILocalVariable(name: "e", scope: !20, file: !8, line: 7, type: !13)
!24 = !DILocation(line: 5, column: 23, scope: !10)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 0, scope: !18)
!27 = !DILocation(line: 6, column: 3, scope: !18)
!28 = !DILocation(line: 8, column: 3, scope: !10)
!29 = !DILocation(line: 6, column: 31, scope: !20)
!30 = !DILocation(line: 0, scope: !20)
!31 = !DILocation(line: 6, column: 55, scope: !20)
!32 = !DILocation(line: 6, column: 62, scope: !20)
!33 = !DILocation(line: 6, column: 60, scope: !20)
!34 = !DILocation(line: 7, column: 11, scope: !20)
!35 = !DILocation(line: 7, column: 31, scope: !20)
!36 = !DILocation(line: 7, column: 29, scope: !20)
!37 = !DILocation(line: 6, column: 20, scope: !21)
!38 = !DILocation(line: 6, column: 16, scope: !21)
!39 = distinct !{!39, !27, !40, !41, !42}
!40 = !DILocation(line: 7, column: 51, scope: !18)
!41 = !{!"llvm.loop.mustprogress"}
!42 = !{!"llvm.loop.unroll.disable"}
!43 = !DISubprogram(name: "cq_theta_si32", scope: !44, file: !44, line: 38, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!45 = !DISubroutineType(types: !46)
!46 = !{!13, !13, !47}
!47 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!48 = !DISubprogram(name: "cq_measure_si32", scope: !44, file: !44, line: 83, type: !49, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DISubroutineType(types: !50)
!50 = !{!13, !13}
