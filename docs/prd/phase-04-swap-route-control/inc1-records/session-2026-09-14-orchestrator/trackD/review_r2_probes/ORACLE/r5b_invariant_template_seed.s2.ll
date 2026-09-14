; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/r5b_invariant_template_seed.ll'
source_filename = "src/r5b_invariant_template_seed.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !24)
  %h = call i32 @cqrt_alloc_i32(i32 %0), !dbg !25
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !25
    #dbg_value(i32 %h, !16, !DIExpression(), !24)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !26
    #dbg_value(i32 %h_op, !17, !DIExpression(), !24)
    #dbg_value(i32 0, !18, !DIExpression(), !24)
    #dbg_value(i32 0, !19, !DIExpression(), !27)
  br label %3, !dbg !28

2:                                                ; preds = %3
  ret i32 %6, !dbg !29

3:                                                ; preds = %3, %1
  %4 = phi i32 [ 0, %1 ], [ %6, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %7, %3 ]
    #dbg_value(i32 %4, !18, !DIExpression(), !24)
    #dbg_value(i32 %5, !19, !DIExpression(), !27)
  call void @cqrt_ry_i32(i32 %h_op, double 1.000000e-01), !dbg !30
    #dbg_value(i32 %h_op, !21, !DIExpression(), !31)
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !32
  %6 = add nsw i32 %m, %4, !dbg !33
    #dbg_value(i32 %6, !18, !DIExpression(), !24)
  %7 = add nuw nsw i32 %5, 1, !dbg !34
    #dbg_value(i32 %7, !19, !DIExpression(), !27)
  %8 = icmp eq i32 %7, 3, !dbg !35
  br i1 %8, label %2, label %3, !dbg !28, !llvm.loop !36
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !40 {
    #dbg_value(i32 3, !15, !DIExpression(), !43)
  %h = call i32 @cqrt_alloc_i32(i32 3), !dbg !45
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !45
    #dbg_value(i32 %h, !16, !DIExpression(), !43)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !46
    #dbg_value(i32 %h_op, !17, !DIExpression(), !43)
    #dbg_value(i32 0, !18, !DIExpression(), !43)
    #dbg_value(i32 0, !19, !DIExpression(), !47)
  br label %1, !dbg !48

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %4, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %5, %1 ]
    #dbg_value(i32 %2, !18, !DIExpression(), !43)
    #dbg_value(i32 %3, !19, !DIExpression(), !47)
  call void @cqrt_ry_i32(i32 %h_op, double 1.000000e-01), !dbg !49
    #dbg_value(i32 %h_op, !21, !DIExpression(), !50)
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !51
  %4 = add nsw i32 %m, %2, !dbg !52
    #dbg_value(i32 %4, !18, !DIExpression(), !43)
  %5 = add nuw nsw i32 %3, 1, !dbg !53
    #dbg_value(i32 %5, !19, !DIExpression(), !47)
  %6 = icmp eq i32 %5, 3, !dbg !54
  br i1 %6, label %7, label %1, !dbg !48, !llvm.loop !55

7:                                                ; preds = %1
  ret i32 %4, !dbg !57
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

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
!8 = !DIFile(filename: "src/r5b_invariant_template_seed.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "a9c7a3db807f062dc6de69d9025048e1")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !19, !21}
!15 = !DILocalVariable(name: "u", arg: 1, scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "t", scope: !10, file: !8, line: 3, type: !13)
!18 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!19 = !DILocalVariable(name: "i", scope: !20, file: !8, line: 4, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!21 = !DILocalVariable(name: "b", scope: !22, file: !8, line: 4, type: !13)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 4, column: 23)
!23 = distinct !DILexicalBlock(scope: !20, file: !8, line: 4, column: 3)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 3, column: 25, scope: !10)
!26 = !DILocation(line: 3, column: 49, scope: !10)
!27 = !DILocation(line: 0, scope: !20)
!28 = !DILocation(line: 4, column: 3, scope: !20)
!29 = !DILocation(line: 4, column: 68, scope: !10)
!30 = !DILocation(line: 4, column: 31, scope: !22)
!31 = !DILocation(line: 0, scope: !22)
!32 = !DILocation(line: 4, column: 51, scope: !22)
!33 = !DILocation(line: 4, column: 49, scope: !22)
!34 = !DILocation(line: 4, column: 20, scope: !23)
!35 = !DILocation(line: 4, column: 16, scope: !23)
!36 = distinct !{!36, !28, !37, !38, !39}
!37 = !DILocation(line: 4, column: 66, scope: !20)
!38 = !{!"llvm.loop.mustprogress"}
!39 = !{!"llvm.loop.unroll.disable"}
!40 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !41, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!41 = !DISubroutineType(types: !42)
!42 = !{!13}
!43 = !DILocation(line: 0, scope: !10, inlinedAt: !44)
!44 = distinct !DILocation(line: 5, column: 24, scope: !40)
!45 = !DILocation(line: 3, column: 25, scope: !10, inlinedAt: !44)
!46 = !DILocation(line: 3, column: 49, scope: !10, inlinedAt: !44)
!47 = !DILocation(line: 0, scope: !20, inlinedAt: !44)
!48 = !DILocation(line: 4, column: 3, scope: !20, inlinedAt: !44)
!49 = !DILocation(line: 4, column: 31, scope: !22, inlinedAt: !44)
!50 = !DILocation(line: 0, scope: !22, inlinedAt: !44)
!51 = !DILocation(line: 4, column: 51, scope: !22, inlinedAt: !44)
!52 = !DILocation(line: 4, column: 49, scope: !22, inlinedAt: !44)
!53 = !DILocation(line: 4, column: 20, scope: !23, inlinedAt: !44)
!54 = !DILocation(line: 4, column: 16, scope: !23, inlinedAt: !44)
!55 = distinct !{!55, !48, !56, !38, !39}
!56 = !DILocation(line: 4, column: 66, scope: !20, inlinedAt: !44)
!57 = !DILocation(line: 5, column: 17, scope: !40)
