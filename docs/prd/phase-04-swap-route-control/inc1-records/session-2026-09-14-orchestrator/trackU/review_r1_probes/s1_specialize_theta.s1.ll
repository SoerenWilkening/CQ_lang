; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/s1_specialize_theta.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/s1_specialize_theta.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call fastcc zeroext i1 @helper(), !dbg !18
    #dbg_value(i1 %1, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
  %2 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #3, !dbg !20
  %3 = zext i1 %2 to i32, !dbg !20
  ret i32 %3, !dbg !21
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc zeroext i1 @helper() unnamed_addr #1 !dbg !22 {
    #dbg_value(i32 3, !26, !DIExpression(), !28)
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext undef, double noundef 5.000000e-01) #3, !dbg !29
    #dbg_value(i1 %1, !27, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !28)
  ret i1 %1, !dbg !30
}

declare !dbg !31 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

declare !dbg !35 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/s1_specialize_theta.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "35cbf4c8b51ee8e4a603123e03b81bf0")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 11, type: !12, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/s1_specialize_theta.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "35cbf4c8b51ee8e4a603123e03b81bf0")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16}
!16 = !DILocalVariable(name: "r", scope: !10, file: !11, line: 12, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocation(line: 12, column: 14, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 13, column: 12, scope: !10)
!21 = !DILocation(line: 13, column: 5, scope: !10)
!22 = distinct !DISubprogram(name: "helper", scope: !11, file: !11, line: 6, type: !23, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !25)
!23 = !DISubroutineType(cc: DW_CC_nocall, types: !24)
!24 = !{!17, !14}
!25 = !{!26, !27}
!26 = !DILocalVariable(name: "k", arg: 1, scope: !22, file: !11, line: 6, type: !14)
!27 = !DILocalVariable(name: "b", scope: !22, file: !11, line: 7, type: !17)
!28 = !DILocation(line: 0, scope: !22)
!29 = !DILocation(line: 8, column: 9, scope: !22)
!30 = !DILocation(line: 9, column: 5, scope: !22)
!31 = !DISubprogram(name: "cq_measure_i1", scope: !32, file: !32, line: 77, type: !33, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!32 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!33 = !DISubroutineType(types: !34)
!34 = !{!17, !17}
!35 = !DISubprogram(name: "cq_theta_i1", scope: !32, file: !32, line: 32, type: !36, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!36 = !DISubroutineType(types: !37)
!37 = !{!17, !17, !38}
!38 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
