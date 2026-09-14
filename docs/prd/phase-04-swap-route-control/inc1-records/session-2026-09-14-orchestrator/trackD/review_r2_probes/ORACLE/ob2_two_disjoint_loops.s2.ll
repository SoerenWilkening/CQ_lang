; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/ob2_two_disjoint_loops.ll'
source_filename = "src/ob2_two_disjoint_loops.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !26)
    #dbg_value(i32 0, !16, !DIExpression(), !27)
  br label %1, !dbg !28

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %4, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %5, %1 ]
    #dbg_value(i32 %2, !15, !DIExpression(), !26)
    #dbg_value(i32 %3, !16, !DIExpression(), !27)
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !29
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !29
    #dbg_value(i32 %h, !18, !DIExpression(), !30)
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !31
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !31
  %4 = add nsw i32 %m, %2, !dbg !32
    #dbg_value(i32 %4, !15, !DIExpression(), !26)
  %5 = add nuw nsw i32 %3, 1, !dbg !33
    #dbg_value(i32 %5, !16, !DIExpression(), !27)
  %6 = icmp eq i32 %5, 3, !dbg !34
  br i1 %6, label %8, label %1, !dbg !28, !llvm.loop !35

7:                                                ; preds = %8
  ret i32 %11, !dbg !39

8:                                                ; preds = %8, %1
  %9 = phi i32 [ %11, %8 ], [ %4, %1 ]
  %10 = phi i32 [ %12, %8 ], [ 0, %1 ]
    #dbg_value(i32 %9, !15, !DIExpression(), !26)
    #dbg_value(i32 %10, !21, !DIExpression(), !40)
  %h1 = call i32 @cqrt_alloc_i32(i32 0), !dbg !41
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !41
    #dbg_value(i32 %h1, !23, !DIExpression(), !42)
  call void @cqrt_ry_i32(i32 %h1, double 2.000000e-01), !dbg !43
  %m2 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !43
  %11 = add nsw i32 %m2, %9, !dbg !44
    #dbg_value(i32 %11, !15, !DIExpression(), !26)
  %12 = add nuw nsw i32 %10, 1, !dbg !45
    #dbg_value(i32 %12, !21, !DIExpression(), !40)
  %13 = icmp eq i32 %12, 3, !dbg !46
  br i1 %13, label %7, label %8, !dbg !47, !llvm.loop !48
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
!8 = !DIFile(filename: "src/ob2_two_disjoint_loops.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "8bbf42a19d783ce0590872fbca61c048")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !21, !23}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "i", scope: !17, file: !8, line: 4, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!18 = !DILocalVariable(name: "q", scope: !19, file: !8, line: 4, type: !13)
!19 = distinct !DILexicalBlock(scope: !20, file: !8, line: 4, column: 23)
!20 = distinct !DILexicalBlock(scope: !17, file: !8, line: 4, column: 3)
!21 = !DILocalVariable(name: "j", scope: !22, file: !8, line: 5, type: !13)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 3)
!23 = !DILocalVariable(name: "r", scope: !24, file: !8, line: 5, type: !13)
!24 = distinct !DILexicalBlock(scope: !25, file: !8, line: 5, column: 23)
!25 = distinct !DILexicalBlock(scope: !22, file: !8, line: 5, column: 3)
!26 = !DILocation(line: 0, scope: !10)
!27 = !DILocation(line: 0, scope: !17)
!28 = !DILocation(line: 4, column: 3, scope: !17)
!29 = !DILocation(line: 4, column: 31, scope: !19)
!30 = !DILocation(line: 0, scope: !19)
!31 = !DILocation(line: 4, column: 51, scope: !19)
!32 = !DILocation(line: 4, column: 49, scope: !19)
!33 = !DILocation(line: 4, column: 20, scope: !20)
!34 = !DILocation(line: 4, column: 16, scope: !20)
!35 = distinct !{!35, !28, !36, !37, !38}
!36 = !DILocation(line: 4, column: 80, scope: !17)
!37 = !{!"llvm.loop.mustprogress"}
!38 = !{!"llvm.loop.unroll.disable"}
!39 = !DILocation(line: 6, column: 3, scope: !10)
!40 = !DILocation(line: 0, scope: !22)
!41 = !DILocation(line: 5, column: 31, scope: !24)
!42 = !DILocation(line: 0, scope: !24)
!43 = !DILocation(line: 5, column: 51, scope: !24)
!44 = !DILocation(line: 5, column: 49, scope: !24)
!45 = !DILocation(line: 5, column: 20, scope: !25)
!46 = !DILocation(line: 5, column: 16, scope: !25)
!47 = !DILocation(line: 5, column: 3, scope: !22)
!48 = distinct !{!48, !47, !49, !37, !38}
!49 = !DILocation(line: 5, column: 80, scope: !22)
