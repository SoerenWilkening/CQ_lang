; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
  br label %3, !dbg !25

2:                                                ; preds = %3
  ret i32 %7, !dbg !26

3:                                                ; preds = %3, %1
  %4 = phi i32 [ 0, %1 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %8, %3 ]
    #dbg_value(i32 %4, !16, !DIExpression(), !23)
    #dbg_value(i32 %5, !17, !DIExpression(), !24)
  %h = call i32 @cqrt_alloc_i32(i32 %0), !dbg !27
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01), !dbg !27
    #dbg_value(i32 %h, !19, !DIExpression(), !28)
  %h_op = call i32 @cq_template_shl_i32_hl(i32 %h, i32 1), !dbg !29
    #dbg_value(i32 %h_op, !22, !DIExpression(), !28)
  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01), !dbg !30
    #dbg_value(i32 %h_op, !22, !DIExpression(), !28)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !31
  %m1 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !32
  %6 = add i32 %m, %4, !dbg !33
  %7 = add i32 %6, %m1, !dbg !34
    #dbg_value(i32 %7, !16, !DIExpression(), !23)
  %8 = add nuw nsw i32 %5, 1, !dbg !35
    #dbg_value(i32 %8, !17, !DIExpression(), !24)
  %9 = icmp eq i32 %8, 3, !dbg !36
  br i1 %9, label %2, label %3, !dbg !25, !llvm.loop !37
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !41 {
    #dbg_value(i32 1, !15, !DIExpression(), !44)
    #dbg_value(i32 0, !16, !DIExpression(), !44)
    #dbg_value(i32 0, !17, !DIExpression(), !46)
  br label %1, !dbg !47

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %6, %1 ]
    #dbg_value(i32 %2, !16, !DIExpression(), !44)
    #dbg_value(i32 %3, !17, !DIExpression(), !46)
  %h = call i32 @cqrt_alloc_i32(i32 1), !dbg !48
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01), !dbg !48
    #dbg_value(i32 %h, !19, !DIExpression(), !49)
  %h_op = call i32 @cq_template_shl_i32_hl(i32 %h, i32 1), !dbg !50
    #dbg_value(i32 %h_op, !22, !DIExpression(), !49)
  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01), !dbg !51
    #dbg_value(i32 %h_op, !22, !DIExpression(), !49)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !52
  %m1 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !53
  %4 = add i32 %m, %2, !dbg !54
  %5 = add i32 %4, %m1, !dbg !55
    #dbg_value(i32 %5, !16, !DIExpression(), !44)
  %6 = add nuw nsw i32 %3, 1, !dbg !56
    #dbg_value(i32 %6, !17, !DIExpression(), !46)
  %7 = icmp eq i32 %6, 3, !dbg !57
  br i1 %7, label %8, label %1, !dbg !47, !llvm.loop !58

8:                                                ; preds = %1
  ret i32 %5, !dbg !60
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc.c", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang", checksumkind: CSK_MD5, checksum: "cd5847df6e8ae0b520cc8308e77dc44f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 1, type: !11, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19, !22}
!15 = !DILocalVariable(name: "x", arg: 1, scope: !10, file: !8, line: 1, type: !13)
!16 = !DILocalVariable(name: "acc", scope: !10, file: !8, line: 2, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 3, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 3)
!19 = !DILocalVariable(name: "q", scope: !20, file: !8, line: 4, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 3, column: 31)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 3, column: 3)
!22 = !DILocalVariable(name: "w", scope: !20, file: !8, line: 5, type: !13)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 3, column: 3, scope: !18)
!26 = !DILocation(line: 9, column: 3, scope: !10)
!27 = !DILocation(line: 4, column: 13, scope: !20)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 5, column: 15, scope: !20)
!30 = !DILocation(line: 6, column: 9, scope: !20)
!31 = !DILocation(line: 7, column: 12, scope: !20)
!32 = !DILocation(line: 7, column: 28, scope: !20)
!33 = !DILocation(line: 7, column: 26, scope: !20)
!34 = !DILocation(line: 7, column: 9, scope: !20)
!35 = !DILocation(line: 3, column: 26, scope: !21)
!36 = !DILocation(line: 3, column: 21, scope: !21)
!37 = distinct !{!37, !25, !38, !39, !40}
!38 = !DILocation(line: 8, column: 3, scope: !18)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !42, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!42 = !DISubroutineType(types: !43)
!43 = !{!13}
!44 = !DILocation(line: 0, scope: !10, inlinedAt: !45)
!45 = distinct !DILocation(line: 11, column: 25, scope: !41)
!46 = !DILocation(line: 0, scope: !18, inlinedAt: !45)
!47 = !DILocation(line: 3, column: 3, scope: !18, inlinedAt: !45)
!48 = !DILocation(line: 4, column: 13, scope: !20, inlinedAt: !45)
!49 = !DILocation(line: 0, scope: !20, inlinedAt: !45)
!50 = !DILocation(line: 5, column: 15, scope: !20, inlinedAt: !45)
!51 = !DILocation(line: 6, column: 9, scope: !20, inlinedAt: !45)
!52 = !DILocation(line: 7, column: 12, scope: !20, inlinedAt: !45)
!53 = !DILocation(line: 7, column: 28, scope: !20, inlinedAt: !45)
!54 = !DILocation(line: 7, column: 26, scope: !20, inlinedAt: !45)
!55 = !DILocation(line: 7, column: 9, scope: !20, inlinedAt: !45)
!56 = !DILocation(line: 3, column: 26, scope: !21, inlinedAt: !45)
!57 = !DILocation(line: 3, column: 21, scope: !21, inlinedAt: !45)
!58 = distinct !{!58, !47, !59, !39, !40}
!59 = !DILocation(line: 8, column: 3, scope: !18, inlinedAt: !45)
!60 = !DILocation(line: 11, column: 18, scope: !41)
