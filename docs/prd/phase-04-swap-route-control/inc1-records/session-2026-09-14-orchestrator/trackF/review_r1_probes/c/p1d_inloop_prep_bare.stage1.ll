; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1d_inloop_prep_bare.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1d_inloop_prep_bare.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i8 0, !16, !DIExpression(), !24)
    #dbg_value(i32 0, !18, !DIExpression(), !24)
    #dbg_value(i32 0, !19, !DIExpression(), !25)
    #dbg_value(i32 undef, !19, !DIExpression(), !25)
    #dbg_value(i32 poison, !18, !DIExpression(), !24)
    #dbg_value(i8 0, !16, !DIExpression(), !24)
  %1 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext false) #2, !dbg !26
  %2 = select i1 %1, i32 4, i32 3, !dbg !27
  ret i32 %2, !dbg !28
}

declare !dbg !29 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1d_inloop_prep_bare.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "7c1c2010007d7ab5a7077cae109c9599")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 4, type: !12, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1d_inloop_prep_bare.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "7c1c2010007d7ab5a7077cae109c9599")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !18, !19, !21}
!16 = !DILocalVariable(name: "q", scope: !10, file: !11, line: 5, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 6, type: !14)
!19 = !DILocalVariable(name: "i", scope: !20, file: !11, line: 7, type: !14)
!20 = distinct !DILexicalBlock(scope: !10, file: !11, line: 7, column: 5)
!21 = !DILocalVariable(name: "b", scope: !22, file: !11, line: 8, type: !17)
!22 = distinct !DILexicalBlock(scope: !23, file: !11, line: 7, column: 33)
!23 = distinct !DILexicalBlock(scope: !20, file: !11, line: 7, column: 5)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 0, scope: !20)
!26 = !DILocation(line: 13, column: 16, scope: !10)
!27 = !DILocation(line: 13, column: 14, scope: !10)
!28 = !DILocation(line: 13, column: 5, scope: !10)
!29 = !DISubprogram(name: "cq_measure_i1", scope: !30, file: !30, line: 77, type: !31, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!30 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!31 = !DISubroutineType(types: !32)
!32 = !{!17, !17}
