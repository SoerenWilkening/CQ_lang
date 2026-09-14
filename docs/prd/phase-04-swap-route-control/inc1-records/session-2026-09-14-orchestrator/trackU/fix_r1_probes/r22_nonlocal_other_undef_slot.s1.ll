; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/r22_nonlocal_other_undef_slot.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/r22_nonlocal_other_undef_slot.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @f() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i8 0, !19, !DIExpression(), !20)
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext undef, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(i1 %1, !15, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef undef) #2, !dbg !22
    #dbg_value(i1 %2, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
  %3 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !23
  %4 = zext i1 %3 to i32, !dbg !23
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2, !dbg !24
  %6 = zext i1 %5 to i32, !dbg !24
  %7 = add nuw nsw i32 %6, %4, !dbg !25
  ret i32 %7, !dbg !26
}

declare !dbg !27 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !31 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/r22_nonlocal_other_undef_slot.c", directory: "/Users/sorenwilkening/Desktop/CQ_undef", checksumkind: CSK_MD5, checksum: "7f761e1b41d87ce0ab817a84c8357c68")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "f", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !17, !19}
!15 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 7, type: !16)
!16 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!17 = !DILocalVariable(name: "th", scope: !10, file: !8, line: 8, type: !18)
!18 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!19 = !DILocalVariable(name: "c", scope: !10, file: !8, line: 9, type: !16)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 10, column: 7, scope: !10)
!22 = !DILocation(line: 11, column: 7, scope: !10)
!23 = !DILocation(line: 12, column: 10, scope: !10)
!24 = !DILocation(line: 12, column: 26, scope: !10)
!25 = !DILocation(line: 12, column: 24, scope: !10)
!26 = !DILocation(line: 12, column: 3, scope: !10)
!27 = !DISubprogram(name: "cq_theta_i1", scope: !28, file: !28, line: 32, type: !29, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!28 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_undef", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!29 = !DISubroutineType(types: !30)
!30 = !{!16, !16, !18}
!31 = !DISubprogram(name: "cq_measure_i1", scope: !28, file: !28, line: 77, type: !32, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!32 = !DISubroutineType(types: !33)
!33 = !{!16, !16}
