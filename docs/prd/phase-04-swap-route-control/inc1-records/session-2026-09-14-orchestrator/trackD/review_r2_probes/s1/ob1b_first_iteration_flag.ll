; ModuleID = 'src/ob1b_first_iteration_flag.c'
source_filename = "src/ob1b_first_iteration_flag.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !25
    #dbg_value(i32 %1, !15, !DIExpression(), !26)
    #dbg_value(i32 0, !16, !DIExpression(), !26)
    #dbg_value(i32 1, !17, !DIExpression(), !26)
    #dbg_value(i32 0, !18, !DIExpression(), !27)
    #dbg_value(i32 poison, !17, !DIExpression(), !26)
  br label %3, !dbg !28

2:                                                ; preds = %10
  ret i32 %12, !dbg !29

3:                                                ; preds = %0, %10
  %4 = phi i32 [ 0, %0 ], [ %12, %10 ]
  %5 = phi i32 [ 0, %0 ], [ %13, %10 ]
  %6 = phi i1 [ false, %0 ], [ true, %10 ]
    #dbg_value(i32 %4, !16, !DIExpression(), !26)
    #dbg_value(i32 %5, !18, !DIExpression(), !27)
  br i1 %6, label %10, label %7, !dbg !30

7:                                                ; preds = %3
  %8 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e-01) #2, !dbg !31
    #dbg_value(i32 %8, !20, !DIExpression(), !32)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !33
    #dbg_value(!DIArgList(i32 %4, i32 %9), !16, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !26)
    #dbg_value(i32 0, !17, !DIExpression(), !26)
  br label %10, !dbg !34

10:                                               ; preds = %3, %7
  %11 = phi i32 [ %9, %7 ], [ 1, %3 ]
  %12 = add nsw i32 %11, %4, !dbg !35
    #dbg_value(i32 %12, !16, !DIExpression(), !26)
    #dbg_value(i32 0, !17, !DIExpression(), !26)
  %13 = add nuw nsw i32 %5, 1, !dbg !36
    #dbg_value(i32 %13, !18, !DIExpression(), !27)
    #dbg_value(i32 poison, !17, !DIExpression(), !26)
  %14 = icmp eq i32 %13, 3, !dbg !37
  br i1 %14, label %2, label %3, !dbg !28, !llvm.loop !38
}

declare !dbg !42 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !47 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/ob1b_first_iteration_flag.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "fa05fc3c09f74e9a4fc80f3219a932de")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !20}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "first", scope: !10, file: !8, line: 4, type: !13)
!18 = !DILocalVariable(name: "i", scope: !19, file: !8, line: 5, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 3)
!20 = !DILocalVariable(name: "b", scope: !21, file: !8, line: 5, type: !13)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 5, column: 34)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 5, column: 28)
!23 = distinct !DILexicalBlock(scope: !24, file: !8, line: 5, column: 23)
!24 = distinct !DILexicalBlock(scope: !19, file: !8, line: 5, column: 3)
!25 = !DILocation(line: 4, column: 23, scope: !10)
!26 = !DILocation(line: 0, scope: !10)
!27 = !DILocation(line: 0, scope: !19)
!28 = !DILocation(line: 5, column: 3, scope: !19)
!29 = !DILocation(line: 6, column: 3, scope: !10)
!30 = !DILocation(line: 5, column: 28, scope: !23)
!31 = !DILocation(line: 5, column: 42, scope: !21)
!32 = !DILocation(line: 0, scope: !21)
!33 = !DILocation(line: 5, column: 62, scope: !21)
!34 = !DILocation(line: 5, column: 86, scope: !21)
!35 = !DILocation(line: 5, scope: !22)
!36 = !DILocation(line: 5, column: 20, scope: !24)
!37 = !DILocation(line: 5, column: 16, scope: !24)
!38 = distinct !{!38, !28, !39, !40, !41}
!39 = !DILocation(line: 5, column: 99, scope: !19)
!40 = !{!"llvm.loop.mustprogress"}
!41 = !{!"llvm.loop.unroll.disable"}
!42 = !DISubprogram(name: "cq_theta_si32", scope: !43, file: !43, line: 38, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!44 = !DISubroutineType(types: !45)
!45 = !{!13, !13, !46}
!46 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!47 = !DISubprogram(name: "cq_measure_si32", scope: !43, file: !43, line: 83, type: !48, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!48 = !DISubroutineType(types: !49)
!49 = !{!13, !13}
