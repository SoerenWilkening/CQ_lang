; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r01_two_objects.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r01_two_objects.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @f(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !16, !DIExpression(), !21)
  %2 = icmp eq i32 %0, 0, !dbg !22
  br i1 %2, label %5, label %3, !dbg !24

3:                                                ; preds = %1
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext undef, double noundef 5.000000e-01) #2, !dbg !25
    #dbg_value(i1 %4, !20, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
  br label %5, !dbg !26

5:                                                ; preds = %1, %3
  %6 = phi i1 [ %4, %3 ], [ false, %1 ], !dbg !27
    #dbg_value(i8 poison, !20, !DIExpression(), !21)
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !28
  %8 = zext i1 %7 to i32, !dbg !28
  ret i32 %8, !dbg !29
}

declare !dbg !30 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !35 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r01_two_objects.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "2b77beab24d070939d2daa393f436ce9")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "f", scope: !11, file: !11, line: 6, type: !12, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r01_two_objects.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "2b77beab24d070939d2daa393f436ce9")
!12 = !DISubroutineType(types: !13)
!13 = !{!14, !14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !19, !20}
!16 = !DILocalVariable(name: "c", arg: 1, scope: !10, file: !11, line: 6, type: !14)
!17 = !DILocalVariable(name: "x", scope: !10, file: !11, line: 7, type: !18)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !DILocalVariable(name: "y", scope: !10, file: !11, line: 8, type: !18)
!20 = !DILocalVariable(name: "r", scope: !10, file: !11, line: 9, type: !18)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 10, column: 7, scope: !23)
!23 = distinct !DILexicalBlock(scope: !10, file: !11, line: 10, column: 7)
!24 = !DILocation(line: 10, column: 7, scope: !10)
!25 = !DILocation(line: 10, column: 14, scope: !23)
!26 = !DILocation(line: 10, column: 10, scope: !23)
!27 = !DILocation(line: 10, scope: !23)
!28 = !DILocation(line: 11, column: 10, scope: !10)
!29 = !DILocation(line: 11, column: 3, scope: !10)
!30 = !DISubprogram(name: "cq_theta_i1", scope: !31, file: !31, line: 32, type: !32, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!31 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!32 = !DISubroutineType(types: !33)
!33 = !{!18, !18, !34}
!34 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!35 = !DISubprogram(name: "cq_measure_i1", scope: !31, file: !31, line: 77, type: !36, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!36 = !DISubroutineType(types: !37)
!37 = !{!18, !18}
