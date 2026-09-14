; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/r5e_nested_invariant.ll'
source_filename = "src/r5e_nested_invariant.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !27
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !27
    #dbg_value(i32 %h, !15, !DIExpression(), !28)
    #dbg_value(i32 0, !16, !DIExpression(), !28)
    #dbg_value(i32 0, !17, !DIExpression(), !29)
  br label %1, !dbg !30

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %4, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %5, %1 ]
    #dbg_value(i32 %2, !16, !DIExpression(), !28)
    #dbg_value(i32 %3, !17, !DIExpression(), !29)
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !31
    #dbg_value(i32 %h, !19, !DIExpression(), !32)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !33
  %4 = add nsw i32 %m, %2, !dbg !34
    #dbg_value(i32 %4, !16, !DIExpression(), !28)
  %5 = add nuw nsw i32 %3, 1, !dbg !35
    #dbg_value(i32 %5, !17, !DIExpression(), !29)
  %6 = icmp eq i32 %3, 0, !dbg !36
  br i1 %6, label %1, label %8, !dbg !30, !llvm.loop !37

7:                                                ; preds = %8
  ret i32 %11, !dbg !41

8:                                                ; preds = %8, %1
  %9 = phi i32 [ %11, %8 ], [ %4, %1 ]
  %10 = phi i32 [ %12, %8 ], [ 0, %1 ]
    #dbg_value(i32 %9, !16, !DIExpression(), !28)
    #dbg_value(i32 %10, !22, !DIExpression(), !42)
  call void @cqrt_ry_i32(i32 %h, double 2.000000e-01), !dbg !43
    #dbg_value(i32 %h, !24, !DIExpression(), !44)
  %m1 = call i32 @cqrt_measure_i32(i32 %h), !dbg !45
  %11 = add nsw i32 %m1, %9, !dbg !46
    #dbg_value(i32 %11, !16, !DIExpression(), !28)
  %12 = add nuw nsw i32 %10, 1, !dbg !47
    #dbg_value(i32 %12, !22, !DIExpression(), !42)
  %13 = icmp eq i32 %10, 0, !dbg !48
  br i1 %13, label %8, label %7, !dbg !49, !llvm.loop !50
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
!8 = !DIFile(filename: "src/r5e_nested_invariant.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "157ecd5b582d58202207e87a8067d73c")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19, !22, !24}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 4, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!19 = !DILocalVariable(name: "b", scope: !20, file: !8, line: 4, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 4, column: 23)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 4, column: 3)
!22 = !DILocalVariable(name: "j", scope: !23, file: !8, line: 5, type: !13)
!23 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 3)
!24 = !DILocalVariable(name: "c", scope: !25, file: !8, line: 5, type: !13)
!25 = distinct !DILexicalBlock(scope: !26, file: !8, line: 5, column: 23)
!26 = distinct !DILexicalBlock(scope: !23, file: !8, line: 5, column: 3)
!27 = !DILocation(line: 3, column: 23, scope: !10)
!28 = !DILocation(line: 0, scope: !10)
!29 = !DILocation(line: 0, scope: !18)
!30 = !DILocation(line: 4, column: 3, scope: !18)
!31 = !DILocation(line: 4, column: 31, scope: !20)
!32 = !DILocation(line: 0, scope: !20)
!33 = !DILocation(line: 4, column: 51, scope: !20)
!34 = !DILocation(line: 4, column: 49, scope: !20)
!35 = !DILocation(line: 4, column: 20, scope: !21)
!36 = !DILocation(line: 4, column: 16, scope: !21)
!37 = distinct !{!37, !30, !38, !39, !40}
!38 = !DILocation(line: 4, column: 66, scope: !18)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = !DILocation(line: 5, column: 68, scope: !10)
!42 = !DILocation(line: 0, scope: !23)
!43 = !DILocation(line: 5, column: 31, scope: !25)
!44 = !DILocation(line: 0, scope: !25)
!45 = !DILocation(line: 5, column: 51, scope: !25)
!46 = !DILocation(line: 5, column: 49, scope: !25)
!47 = !DILocation(line: 5, column: 20, scope: !26)
!48 = !DILocation(line: 5, column: 16, scope: !26)
!49 = !DILocation(line: 5, column: 3, scope: !23)
!50 = distinct !{!50, !49, !51, !39, !40}
!51 = !DILocation(line: 5, column: 66, scope: !23)
