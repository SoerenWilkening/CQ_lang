; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3f_twin_bool_reseed.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3f_twin_bool_reseed.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !19
  %2 = icmp ne i32 %1, 0, !dbg !19
    #dbg_value(i1 %2, !15, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
  %3 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2, !dbg !21
    #dbg_value(i1 %3, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i1 %4, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
  %5 = zext i1 %3 to i32, !dbg !23
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #2, !dbg !24
  %7 = zext i1 %6 to i32, !dbg !24
  %8 = add nuw nsw i32 %7, %5, !dbg !25
  ret i32 %8, !dbg !26
}

declare !dbg !27 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !32 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !35 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3f_twin_bool_reseed.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "b649be88a2f25b229182668c5a834c74")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !17, !18}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 4, type: !16)
!16 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!17 = !DILocalVariable(name: "m", scope: !10, file: !8, line: 4, type: !16)
!18 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 4, type: !16)
!19 = !DILocation(line: 4, column: 25, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 4, column: 50, scope: !10)
!22 = !DILocation(line: 4, column: 73, scope: !10)
!23 = !DILocation(line: 4, column: 97, scope: !10)
!24 = !DILocation(line: 4, column: 99, scope: !10)
!25 = !DILocation(line: 4, column: 98, scope: !10)
!26 = !DILocation(line: 4, column: 90, scope: !10)
!27 = !DISubprogram(name: "cq_theta_si32", scope: !28, file: !28, line: 38, type: !29, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!28 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!29 = !DISubroutineType(types: !30)
!30 = !{!13, !13, !31}
!31 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!32 = !DISubprogram(name: "cq_measure_i1", scope: !28, file: !28, line: 77, type: !33, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!33 = !DISubroutineType(types: !34)
!34 = !{!16, !16}
!35 = !DISubprogram(name: "cq_theta_i1", scope: !28, file: !28, line: 32, type: !36, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!36 = !DISubroutineType(types: !37)
!37 = !{!16, !16, !31}
