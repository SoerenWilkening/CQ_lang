; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/r5c_invariant_two_siblings.ll'
source_filename = "src/r5c_invariant_two_siblings.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !25)
  %h = call i32 @cqrt_alloc_i32(i32 %0), !dbg !26
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !26
    #dbg_value(i32 %h, !16, !DIExpression(), !25)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !27
    #dbg_value(i32 %h_op, !17, !DIExpression(), !25)
    #dbg_value(i32 0, !18, !DIExpression(), !25)
    #dbg_value(i32 0, !19, !DIExpression(), !28)
  br label %3, !dbg !29

2:                                                ; preds = %3
  ret i32 %7, !dbg !30

3:                                                ; preds = %3, %1
  %4 = phi i32 [ 0, %1 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %8, %3 ]
    #dbg_value(i32 %4, !18, !DIExpression(), !25)
    #dbg_value(i32 %5, !19, !DIExpression(), !28)
  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01), !dbg !31
    #dbg_value(i32 %h_op, !21, !DIExpression(), !32)
  call void @cqrt_ry_i32(i32 %h_op, double 9.000000e-01), !dbg !33
    #dbg_value(i32 %h_op, !24, !DIExpression(), !32)
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !34
  %m1 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !35
  %6 = add i32 %m, %4, !dbg !36
  %7 = add i32 %6, %m1, !dbg !37
    #dbg_value(i32 %7, !18, !DIExpression(), !25)
  %8 = add nuw nsw i32 %5, 1, !dbg !38
    #dbg_value(i32 %8, !19, !DIExpression(), !28)
  %9 = icmp eq i32 %8, 3, !dbg !39
  br i1 %9, label %2, label %3, !dbg !29, !llvm.loop !40
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !44 {
    #dbg_value(i32 3, !15, !DIExpression(), !47)
  %h = call i32 @cqrt_alloc_i32(i32 3), !dbg !49
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !49
    #dbg_value(i32 %h, !16, !DIExpression(), !47)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !50
    #dbg_value(i32 %h_op, !17, !DIExpression(), !47)
    #dbg_value(i32 0, !18, !DIExpression(), !47)
    #dbg_value(i32 0, !19, !DIExpression(), !51)
  br label %1, !dbg !52

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %6, %1 ]
    #dbg_value(i32 %2, !18, !DIExpression(), !47)
    #dbg_value(i32 %3, !19, !DIExpression(), !51)
  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01), !dbg !53
    #dbg_value(i32 %h_op, !21, !DIExpression(), !54)
  call void @cqrt_ry_i32(i32 %h_op, double 9.000000e-01), !dbg !55
    #dbg_value(i32 %h_op, !24, !DIExpression(), !54)
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !56
  %m1 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !57
  %4 = add i32 %m, %2, !dbg !58
  %5 = add i32 %4, %m1, !dbg !59
    #dbg_value(i32 %5, !18, !DIExpression(), !47)
  %6 = add nuw nsw i32 %3, 1, !dbg !60
    #dbg_value(i32 %6, !19, !DIExpression(), !51)
  %7 = icmp eq i32 %6, 3, !dbg !61
  br i1 %7, label %8, label %1, !dbg !52, !llvm.loop !62

8:                                                ; preds = %1
  ret i32 %5, !dbg !64
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
!8 = !DIFile(filename: "src/r5c_invariant_two_siblings.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "45cb0b3c908d85d7635f7a70a25e6297")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !19, !21, !24}
!15 = !DILocalVariable(name: "u", arg: 1, scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "t", scope: !10, file: !8, line: 3, type: !13)
!18 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!19 = !DILocalVariable(name: "i", scope: !20, file: !8, line: 4, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!21 = !DILocalVariable(name: "b", scope: !22, file: !8, line: 4, type: !13)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 4, column: 23)
!23 = distinct !DILexicalBlock(scope: !20, file: !8, line: 4, column: 3)
!24 = !DILocalVariable(name: "c", scope: !22, file: !8, line: 4, type: !13)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 3, column: 25, scope: !10)
!27 = !DILocation(line: 3, column: 49, scope: !10)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 4, column: 3, scope: !20)
!30 = !DILocation(line: 4, column: 105, scope: !10)
!31 = !DILocation(line: 4, column: 31, scope: !22)
!32 = !DILocation(line: 0, scope: !22)
!33 = !DILocation(line: 4, column: 54, scope: !22)
!34 = !DILocation(line: 4, column: 74, scope: !22)
!35 = !DILocation(line: 4, column: 88, scope: !22)
!36 = !DILocation(line: 4, column: 87, scope: !22)
!37 = !DILocation(line: 4, column: 72, scope: !22)
!38 = !DILocation(line: 4, column: 20, scope: !23)
!39 = !DILocation(line: 4, column: 16, scope: !23)
!40 = distinct !{!40, !29, !41, !42, !43}
!41 = !DILocation(line: 4, column: 103, scope: !20)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !45, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DISubroutineType(types: !46)
!46 = !{!13}
!47 = !DILocation(line: 0, scope: !10, inlinedAt: !48)
!48 = distinct !DILocation(line: 5, column: 24, scope: !44)
!49 = !DILocation(line: 3, column: 25, scope: !10, inlinedAt: !48)
!50 = !DILocation(line: 3, column: 49, scope: !10, inlinedAt: !48)
!51 = !DILocation(line: 0, scope: !20, inlinedAt: !48)
!52 = !DILocation(line: 4, column: 3, scope: !20, inlinedAt: !48)
!53 = !DILocation(line: 4, column: 31, scope: !22, inlinedAt: !48)
!54 = !DILocation(line: 0, scope: !22, inlinedAt: !48)
!55 = !DILocation(line: 4, column: 54, scope: !22, inlinedAt: !48)
!56 = !DILocation(line: 4, column: 74, scope: !22, inlinedAt: !48)
!57 = !DILocation(line: 4, column: 88, scope: !22, inlinedAt: !48)
!58 = !DILocation(line: 4, column: 87, scope: !22, inlinedAt: !48)
!59 = !DILocation(line: 4, column: 72, scope: !22, inlinedAt: !48)
!60 = !DILocation(line: 4, column: 20, scope: !23, inlinedAt: !48)
!61 = !DILocation(line: 4, column: 16, scope: !23, inlinedAt: !48)
!62 = distinct !{!62, !52, !63, !42, !43}
!63 = !DILocation(line: 4, column: 103, scope: !20, inlinedAt: !48)
!64 = !DILocation(line: 5, column: 17, scope: !44)
