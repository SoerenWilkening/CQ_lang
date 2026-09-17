; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_obs.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_obs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !25)
    #dbg_value(i32 %1, !16, !DIExpression(), !25)
    #dbg_value(i32 0, !17, !DIExpression(), !25)
    #dbg_value(i32 0, !18, !DIExpression(), !26)
  %3 = icmp sgt i32 %1, 0, !dbg !27
  br i1 %3, label %6, label %4, !dbg !28

4:                                                ; preds = %6, %2
  %5 = phi i32 [ 0, %2 ], [ %10, %6 ], !dbg !25
  ret i32 %5, !dbg !29

6:                                                ; preds = %6, %2
  %7 = phi i32 [ %10, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %11, %6 ], [ 0, %2 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !25)
    #dbg_value(i32 %8, !18, !DIExpression(), !26)
  %h = call i32 @cqrt_alloc_i32(i32 %0), !dbg !30
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01), !dbg !30
    #dbg_value(i32 %h, !20, !DIExpression(), !31)
  %h_op = call i32 @cq_template_shl_i32_hl(i32 %h, i32 1), !dbg !32
    #dbg_value(i32 %h_op, !23, !DIExpression(), !31)
  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01), !dbg !33
    #dbg_value(i32 %h_op, !23, !DIExpression(), !31)
  %h_op1 = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3), !dbg !34
    #dbg_value(i32 %h_op1, !24, !DIExpression(), !31)
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !35
  %9 = add nsw i32 %m, %7, !dbg !36
    #dbg_value(i32 %9, !17, !DIExpression(), !25)
  %m2 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !37
  %10 = add nsw i32 %9, %m2, !dbg !38
    #dbg_value(i32 %10, !17, !DIExpression(), !25)
  %11 = add nuw nsw i32 %8, 1, !dbg !39
    #dbg_value(i32 %11, !18, !DIExpression(), !26)
  %12 = icmp eq i32 %11, %1, !dbg !27
  br i1 %12, label %4, label %6, !dbg !28, !llvm.loop !40
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !44 {
    #dbg_value(i32 1, !15, !DIExpression(), !47)
    #dbg_value(i32 3, !16, !DIExpression(), !47)
    #dbg_value(i32 0, !17, !DIExpression(), !47)
    #dbg_value(i32 0, !18, !DIExpression(), !49)
  br label %1

1:                                                ; preds = %1, %0
  %2 = phi i32 [ %5, %1 ], [ 0, %0 ]
  %3 = phi i32 [ %6, %1 ], [ 0, %0 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !47)
    #dbg_value(i32 %3, !18, !DIExpression(), !49)
  %h = call i32 @cqrt_alloc_i32(i32 1), !dbg !50
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01), !dbg !50
    #dbg_value(i32 %h, !20, !DIExpression(), !51)
  %h_op = call i32 @cq_template_shl_i32_hl(i32 %h, i32 1), !dbg !52
    #dbg_value(i32 %h_op, !23, !DIExpression(), !51)
  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01), !dbg !53
    #dbg_value(i32 %h_op, !23, !DIExpression(), !51)
  %h_op1 = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3), !dbg !54
    #dbg_value(i32 %h_op1, !24, !DIExpression(), !51)
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !55
  %4 = add nsw i32 %m, %2, !dbg !56
    #dbg_value(i32 %4, !17, !DIExpression(), !47)
  %m2 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !57
  %5 = add nsw i32 %4, %m2, !dbg !58
    #dbg_value(i32 %5, !17, !DIExpression(), !47)
  %6 = add nuw nsw i32 %3, 1, !dbg !59
    #dbg_value(i32 %6, !18, !DIExpression(), !49)
  %7 = icmp eq i32 %6, 3, !dbg !60
  br i1 %7, label %8, label %1, !dbg !61, !llvm.loop !62

8:                                                ; preds = %1
  ret i32 %5, !dbg !64
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_shl_i32_hl(i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_obs.c", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang", checksumkind: CSK_MD5, checksum: "9b0eea2821bd7a10745df5118ff4e44d")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 1, type: !11, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !20, !23, !24}
!15 = !DILocalVariable(name: "x", arg: 1, scope: !10, file: !8, line: 1, type: !13)
!16 = !DILocalVariable(name: "n", arg: 2, scope: !10, file: !8, line: 1, type: !13)
!17 = !DILocalVariable(name: "acc", scope: !10, file: !8, line: 2, type: !13)
!18 = !DILocalVariable(name: "i", scope: !19, file: !8, line: 3, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 3)
!20 = !DILocalVariable(name: "q", scope: !21, file: !8, line: 4, type: !13)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 3, column: 31)
!22 = distinct !DILexicalBlock(scope: !19, file: !8, line: 3, column: 3)
!23 = !DILocalVariable(name: "w", scope: !21, file: !8, line: 5, type: !13)
!24 = !DILocalVariable(name: "z", scope: !21, file: !8, line: 7, type: !13)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 0, scope: !19)
!27 = !DILocation(line: 3, column: 21, scope: !22)
!28 = !DILocation(line: 3, column: 3, scope: !19)
!29 = !DILocation(line: 11, column: 3, scope: !10)
!30 = !DILocation(line: 4, column: 13, scope: !21)
!31 = !DILocation(line: 0, scope: !21)
!32 = !DILocation(line: 5, column: 15, scope: !21)
!33 = !DILocation(line: 6, column: 9, scope: !21)
!34 = !DILocation(line: 7, column: 15, scope: !21)
!35 = !DILocation(line: 8, column: 12, scope: !21)
!36 = !DILocation(line: 8, column: 9, scope: !21)
!37 = !DILocation(line: 9, column: 12, scope: !21)
!38 = !DILocation(line: 9, column: 9, scope: !21)
!39 = !DILocation(line: 3, column: 26, scope: !22)
!40 = distinct !{!40, !28, !41, !42, !43}
!41 = !DILocation(line: 10, column: 3, scope: !19)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !45, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DISubroutineType(types: !46)
!46 = !{!13}
!47 = !DILocation(line: 0, scope: !10, inlinedAt: !48)
!48 = distinct !DILocation(line: 13, column: 25, scope: !44)
!49 = !DILocation(line: 0, scope: !19, inlinedAt: !48)
!50 = !DILocation(line: 4, column: 13, scope: !21, inlinedAt: !48)
!51 = !DILocation(line: 0, scope: !21, inlinedAt: !48)
!52 = !DILocation(line: 5, column: 15, scope: !21, inlinedAt: !48)
!53 = !DILocation(line: 6, column: 9, scope: !21, inlinedAt: !48)
!54 = !DILocation(line: 7, column: 15, scope: !21, inlinedAt: !48)
!55 = !DILocation(line: 8, column: 12, scope: !21, inlinedAt: !48)
!56 = !DILocation(line: 8, column: 9, scope: !21, inlinedAt: !48)
!57 = !DILocation(line: 9, column: 12, scope: !21, inlinedAt: !48)
!58 = !DILocation(line: 9, column: 9, scope: !21, inlinedAt: !48)
!59 = !DILocation(line: 3, column: 26, scope: !22, inlinedAt: !48)
!60 = !DILocation(line: 3, column: 21, scope: !22, inlinedAt: !48)
!61 = !DILocation(line: 3, column: 3, scope: !19, inlinedAt: !48)
!62 = distinct !{!62, !61, !63, !42, !43}
!63 = !DILocation(line: 10, column: 3, scope: !19, inlinedAt: !48)
!64 = !DILocation(line: 13, column: 18, scope: !44)
