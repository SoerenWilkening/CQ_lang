; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.4ngSTiMm7J/s1.ll'
source_filename = "./w2c_noregion_inplace.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !20
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !20
    #dbg_value(i32 %h, !16, !DIExpression(), !21)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
    #dbg_value(i32 0, !18, !DIExpression(), !22)
  br label %2, !dbg !23

1:                                                ; preds = %2
  ret i32 %5, !dbg !24

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %6, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %5, %2 ]
    #dbg_value(i32 %3, !18, !DIExpression(), !22)
    #dbg_value(i32 %4, !17, !DIExpression(), !21)
    #dbg_value(i32 %h, !16, !DIExpression(), !21)
  call void @cqrt_addc_i32(i32 %h, i32 3), !dbg !25
    #dbg_value(i32 %h, !16, !DIExpression(), !21)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !28
  %5 = add nsw i32 %m, %4, !dbg !29
    #dbg_value(i32 %5, !17, !DIExpression(), !21)
  %6 = add nuw nsw i32 %3, 1, !dbg !30
    #dbg_value(i32 %6, !18, !DIExpression(), !22)
  %7 = icmp eq i32 %3, 0, !dbg !31
  br i1 %7, label %2, label %1, !dbg !23, !llvm.loop !32
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !36 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !37
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !37
    #dbg_value(i32 %h, !16, !DIExpression(), !39)
    #dbg_value(i32 0, !17, !DIExpression(), !39)
    #dbg_value(i32 0, !18, !DIExpression(), !40)
  br label %1, !dbg !41

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !18, !DIExpression(), !40)
    #dbg_value(i32 %3, !17, !DIExpression(), !39)
    #dbg_value(i32 %h, !16, !DIExpression(), !39)
  call void @cqrt_addc_i32(i32 %h, i32 3), !dbg !42
    #dbg_value(i32 %h, !16, !DIExpression(), !39)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !43
  %4 = add nsw i32 %m, %3, !dbg !44
    #dbg_value(i32 %4, !17, !DIExpression(), !39)
  %5 = add nuw nsw i32 %2, 1, !dbg !45
    #dbg_value(i32 %5, !18, !DIExpression(), !40)
  %6 = icmp eq i32 %2, 0, !dbg !46
  br i1 %6, label %1, label %7, !dbg !41, !llvm.loop !47

7:                                                ; preds = %1
  ret i32 %4, !dbg !49
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_addc_i32(i32, i32)

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
!8 = !DIFile(filename: "w2c_noregion_inplace.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "a95e095735e2670e358740c52f458d6f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !11, file: !11, line: 5, type: !12, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "./w2c_noregion_inplace.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "a95e095735e2670e358740c52f458d6f")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18}
!16 = !DILocalVariable(name: "q", scope: !10, file: !11, line: 6, type: !14)
!17 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 7, type: !14)
!18 = !DILocalVariable(name: "k", scope: !19, file: !11, line: 8, type: !14)
!19 = distinct !DILexicalBlock(scope: !10, file: !11, line: 8, column: 5)
!20 = !DILocation(line: 6, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 0, scope: !19)
!23 = !DILocation(line: 8, column: 5, scope: !19)
!24 = !DILocation(line: 9, column: 5, scope: !10)
!25 = !DILocation(line: 8, column: 41, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !11, line: 8, column: 33)
!27 = distinct !DILexicalBlock(scope: !19, file: !11, line: 8, column: 5)
!28 = !DILocation(line: 8, column: 51, scope: !26)
!29 = !DILocation(line: 8, column: 48, scope: !26)
!30 = !DILocation(line: 8, column: 28, scope: !27)
!31 = !DILocation(line: 8, column: 23, scope: !27)
!32 = distinct !{!32, !23, !33, !34, !35}
!33 = !DILocation(line: 8, column: 66, scope: !19)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
!36 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 11, type: !12, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!37 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !38)
!38 = distinct !DILocation(line: 11, column: 25, scope: !36)
!39 = !DILocation(line: 0, scope: !10, inlinedAt: !38)
!40 = !DILocation(line: 0, scope: !19, inlinedAt: !38)
!41 = !DILocation(line: 8, column: 5, scope: !19, inlinedAt: !38)
!42 = !DILocation(line: 8, column: 41, scope: !26, inlinedAt: !38)
!43 = !DILocation(line: 8, column: 51, scope: !26, inlinedAt: !38)
!44 = !DILocation(line: 8, column: 48, scope: !26, inlinedAt: !38)
!45 = !DILocation(line: 8, column: 28, scope: !27, inlinedAt: !38)
!46 = !DILocation(line: 8, column: 23, scope: !27, inlinedAt: !38)
!47 = distinct !{!47, !41, !48, !34, !35}
!48 = !DILocation(line: 8, column: 66, scope: !19, inlinedAt: !38)
!49 = !DILocation(line: 11, column: 18, scope: !36)
