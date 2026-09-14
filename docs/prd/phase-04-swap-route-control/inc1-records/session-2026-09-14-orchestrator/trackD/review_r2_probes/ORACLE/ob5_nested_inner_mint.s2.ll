; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/ob5_nested_inner_mint.ll'
source_filename = "src/ob5_nested_inner_mint.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !25)
    #dbg_value(i32 0, !16, !DIExpression(), !26)
  br label %1, !dbg !27

1:                                                ; preds = %5, %0
  %2 = phi i32 [ 0, %0 ], [ %6, %5 ]
  %3 = phi i32 [ 0, %0 ], [ %11, %5 ]
    #dbg_value(i32 %2, !16, !DIExpression(), !26)
    #dbg_value(i32 %3, !15, !DIExpression(), !25)
    #dbg_value(i32 0, !18, !DIExpression(), !28)
    #dbg_value(i32 %3, !15, !DIExpression(), !25)
  br label %8, !dbg !29

4:                                                ; preds = %5
  ret i32 %11, !dbg !30

5:                                                ; preds = %8
  %6 = add nuw nsw i32 %2, 1, !dbg !31
    #dbg_value(i32 %6, !16, !DIExpression(), !26)
    #dbg_value(i32 %11, !15, !DIExpression(), !25)
  %7 = icmp eq i32 %2, 0, !dbg !32
  br i1 %7, label %1, label %4, !dbg !27, !llvm.loop !33

8:                                                ; preds = %8, %1
  %9 = phi i32 [ 0, %1 ], [ %12, %8 ]
  %10 = phi i32 [ %3, %1 ], [ %11, %8 ]
    #dbg_value(i32 %9, !18, !DIExpression(), !28)
    #dbg_value(i32 %10, !15, !DIExpression(), !25)
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !37
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !37
    #dbg_value(i32 %h, !22, !DIExpression(), !38)
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !39
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !39
  %11 = add nsw i32 %m, %10, !dbg !40
    #dbg_value(i32 %11, !15, !DIExpression(), !25)
  %12 = add nuw nsw i32 %9, 1, !dbg !41
    #dbg_value(i32 %12, !18, !DIExpression(), !28)
  %13 = icmp eq i32 %9, 0, !dbg !42
  br i1 %13, label %8, label %5, !dbg !29, !llvm.loop !43
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
!8 = !DIFile(filename: "src/ob5_nested_inner_mint.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "44744efe454cc74eec71f8de6edb6ef9")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !22}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "i", scope: !17, file: !8, line: 3, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 26)
!18 = !DILocalVariable(name: "j", scope: !19, file: !8, line: 3, type: !13)
!19 = distinct !DILexicalBlock(scope: !20, file: !8, line: 3, column: 48)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 3, column: 46)
!21 = distinct !DILexicalBlock(scope: !17, file: !8, line: 3, column: 26)
!22 = !DILocalVariable(name: "q", scope: !23, file: !8, line: 4, type: !13)
!23 = distinct !DILexicalBlock(scope: !24, file: !8, line: 3, column: 68)
!24 = distinct !DILexicalBlock(scope: !19, file: !8, line: 3, column: 48)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 0, scope: !17)
!27 = !DILocation(line: 3, column: 26, scope: !17)
!28 = !DILocation(line: 0, scope: !19)
!29 = !DILocation(line: 3, column: 48, scope: !19)
!30 = !DILocation(line: 4, column: 72, scope: !10)
!31 = !DILocation(line: 3, column: 43, scope: !21)
!32 = !DILocation(line: 3, column: 39, scope: !21)
!33 = distinct !{!33, !27, !34, !35, !36}
!34 = !DILocation(line: 4, column: 60, scope: !17)
!35 = !{!"llvm.loop.mustprogress"}
!36 = !{!"llvm.loop.unroll.disable"}
!37 = !DILocation(line: 4, column: 9, scope: !23)
!38 = !DILocation(line: 0, scope: !23)
!39 = !DILocation(line: 4, column: 29, scope: !23)
!40 = !DILocation(line: 4, column: 27, scope: !23)
!41 = !DILocation(line: 3, column: 65, scope: !24)
!42 = !DILocation(line: 3, column: 61, scope: !24)
!43 = distinct !{!43, !29, !44, !35, !36}
!44 = !DILocation(line: 4, column: 58, scope: !19)
