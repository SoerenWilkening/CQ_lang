; ModuleID = 'v05_f2_zero_collision.c'
source_filename = "v05_f2_zero_collision.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !15, !DIExpression(), !19)
    #dbg_value(i8 0, !16, !DIExpression(), !19)
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #3, !dbg !20
    #dbg_value(i1 %1, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
    #dbg_value(i1 %1, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
    #dbg_value(i1 %1, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
  %2 = xor i1 %1, true, !dbg !23
  tail call void @llvm.assume(i1 %2), !dbg !23
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext undef, double noundef 2.500000e-01) #3, !dbg !24
    #dbg_value(i1 %3, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
    #dbg_value(i8 poison, !18, !DIExpression(), !19)
  %4 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #3, !dbg !27
  %5 = zext i1 %4 to i32, !dbg !27
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #3, !dbg !28
  %7 = zext i1 %6 to i32, !dbg !28
  %8 = add nuw nsw i32 %7, %5, !dbg !29
  ret i32 %8, !dbg !30
}

declare !dbg !31 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !36 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
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
!8 = !DIFile(filename: "v05_f2_zero_collision.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r2_probes", checksumkind: CSK_MD5, checksum: "0451c1f52af8e55b61b65f1e0df79614")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "g", scope: !10, file: !8, line: 8, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 10, type: !17)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 9, column: 23, scope: !21)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 9, column: 17)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 9)
!23 = !DILocation(line: 11, column: 9, scope: !10)
!24 = !DILocation(line: 11, column: 19, scope: !25)
!25 = distinct !DILexicalBlock(scope: !26, file: !8, line: 11, column: 13)
!26 = distinct !DILexicalBlock(scope: !10, file: !8, line: 11, column: 9)
!27 = !DILocation(line: 12, column: 12, scope: !10)
!28 = !DILocation(line: 12, column: 28, scope: !10)
!29 = !DILocation(line: 12, column: 26, scope: !10)
!30 = !DILocation(line: 12, column: 5, scope: !10)
!31 = !DISubprogram(name: "cq_theta_i1", scope: !32, file: !32, line: 32, type: !33, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!32 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!33 = !DISubroutineType(types: !34)
!34 = !{!17, !17, !35}
!35 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!36 = !DISubprogram(name: "cq_measure_i1", scope: !32, file: !32, line: 77, type: !37, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DISubroutineType(types: !38)
!38 = !{!17, !17}
