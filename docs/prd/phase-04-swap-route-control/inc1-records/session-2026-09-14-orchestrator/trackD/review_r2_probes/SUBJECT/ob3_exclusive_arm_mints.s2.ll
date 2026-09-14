; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/ob3_exclusive_arm_mints.ll'
source_filename = "src/ob3_exclusive_arm_mints.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !25)
    #dbg_value(i32 0, !16, !DIExpression(), !26)
  br label %2, !dbg !27

1:                                                ; preds = %2
  ret i32 %9, !dbg !28

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %9, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %10, %2 ]
    #dbg_value(i32 %3, !15, !DIExpression(), !25)
    #dbg_value(i32 %4, !16, !DIExpression(), !26)
  %5 = and i32 %4, 1, !dbg !29
  %6 = icmp eq i32 %5, 0, !dbg !29
    #dbg_value(!DIArgList(i32 %3, i32 %m), !15, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !25)
    #dbg_value(!DIArgList(i32 %3, i32 %m), !15, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !25)
  %7 = select i1 %6, double 4.000000e-01, double 3.000000e-01
  %8 = select i1 %6, double 2.000000e-01, double 1.000000e-01
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !30
  call void @cqrt_ry_i32(i32 %h, double %7), !dbg !30
  call void @cqrt_ry_i32(i32 %h, double %8), !dbg !30
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !30
  %9 = add nsw i32 %m, %3, !dbg !30
    #dbg_value(i32 %9, !15, !DIExpression(), !25)
  %10 = add nuw nsw i32 %4, 1, !dbg !31
    #dbg_value(i32 %10, !16, !DIExpression(), !26)
  %11 = icmp eq i32 %10, 4, !dbg !32
  br i1 %11, label %1, label %2, !dbg !27, !llvm.loop !33
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

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
!8 = !DIFile(filename: "src/ob3_exclusive_arm_mints.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "95030e8c0f2efd2aa6925477829a8d49")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !23}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "i", scope: !17, file: !8, line: 4, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!18 = !DILocalVariable(name: "q", scope: !19, file: !8, line: 4, type: !13)
!19 = distinct !DILexicalBlock(scope: !20, file: !8, line: 4, column: 32)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 4, column: 28)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 4, column: 23)
!22 = distinct !DILexicalBlock(scope: !17, file: !8, line: 4, column: 3)
!23 = !DILocalVariable(name: "r", scope: !24, file: !8, line: 5, type: !13)
!24 = distinct !DILexicalBlock(scope: !20, file: !8, line: 5, column: 32)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 0, scope: !17)
!27 = !DILocation(line: 4, column: 3, scope: !17)
!28 = !DILocation(line: 6, column: 3, scope: !10)
!29 = !DILocation(line: 4, column: 29, scope: !20)
!30 = !DILocation(line: 0, scope: !20)
!31 = !DILocation(line: 4, column: 20, scope: !22)
!32 = !DILocation(line: 4, column: 16, scope: !22)
!33 = distinct !{!33, !27, !34, !35, !36}
!34 = !DILocation(line: 5, column: 91, scope: !17)
!35 = !{!"llvm.loop.mustprogress"}
!36 = !{!"llvm.loop.unroll.disable"}
