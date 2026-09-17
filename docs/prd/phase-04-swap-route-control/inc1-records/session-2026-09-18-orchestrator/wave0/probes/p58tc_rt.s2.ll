; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_rt.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_rt.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !24)
    #dbg_value(i32 %1, !16, !DIExpression(), !24)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
    #dbg_value(i32 0, !18, !DIExpression(), !25)
  %3 = icmp sgt i32 %1, 0, !dbg !26
  br i1 %3, label %6, label %4, !dbg !27

4:                                                ; preds = %6, %2
  %5 = phi i32 [ 0, %2 ], [ %10, %6 ], !dbg !24
  ret i32 %5, !dbg !28

6:                                                ; preds = %6, %2
  %7 = phi i32 [ %10, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %11, %6 ], [ 0, %2 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !24)
    #dbg_value(i32 %8, !18, !DIExpression(), !25)
  %h = call i32 @cqrt_alloc_i32(i32 %0), !dbg !29
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01), !dbg !29
    #dbg_value(i32 %h, !20, !DIExpression(), !30)
  %h_op = call i32 @cq_template_shl_i32_hl(i32 %h, i32 1), !dbg !31
    #dbg_value(i32 %h_op, !23, !DIExpression(), !30)
  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01), !dbg !32
    #dbg_value(i32 %h_op, !23, !DIExpression(), !30)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !33
  %m1 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !34
  %9 = add i32 %m, %7, !dbg !35
  %10 = add i32 %9, %m1, !dbg !36
    #dbg_value(i32 %10, !17, !DIExpression(), !24)
  %11 = add nuw nsw i32 %8, 1, !dbg !37
    #dbg_value(i32 %11, !18, !DIExpression(), !25)
  %12 = icmp eq i32 %11, %1, !dbg !26
  br i1 %12, label %4, label %6, !dbg !27, !llvm.loop !38
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !42 {
    #dbg_value(i32 1, !15, !DIExpression(), !45)
    #dbg_value(i32 3, !16, !DIExpression(), !45)
    #dbg_value(i32 0, !17, !DIExpression(), !45)
    #dbg_value(i32 0, !18, !DIExpression(), !47)
  br label %1

1:                                                ; preds = %1, %0
  %2 = phi i32 [ %5, %1 ], [ 0, %0 ]
  %3 = phi i32 [ %6, %1 ], [ 0, %0 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !45)
    #dbg_value(i32 %3, !18, !DIExpression(), !47)
  %h = call i32 @cqrt_alloc_i32(i32 1), !dbg !48
  call void @cqrt_ry_i32(i32 %h, double 2.500000e-01), !dbg !48
    #dbg_value(i32 %h, !20, !DIExpression(), !49)
  %h_op = call i32 @cq_template_shl_i32_hl(i32 %h, i32 1), !dbg !50
    #dbg_value(i32 %h_op, !23, !DIExpression(), !49)
  call void @cqrt_ry_i32(i32 %h_op, double 5.000000e-01), !dbg !51
    #dbg_value(i32 %h_op, !23, !DIExpression(), !49)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !52
  %m1 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !53
  %4 = add i32 %m, %2, !dbg !54
  %5 = add i32 %4, %m1, !dbg !55
    #dbg_value(i32 %5, !17, !DIExpression(), !45)
  %6 = add nuw nsw i32 %3, 1, !dbg !56
    #dbg_value(i32 %6, !18, !DIExpression(), !47)
  %7 = icmp eq i32 %6, 3, !dbg !57
  br i1 %7, label %8, label %1, !dbg !58, !llvm.loop !59

8:                                                ; preds = %1
  ret i32 %5, !dbg !61
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_rt.c", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang", checksumkind: CSK_MD5, checksum: "43eeec3e3c679479d0b0bc1e384a5699")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 1, type: !11, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !20, !23}
!15 = !DILocalVariable(name: "x", arg: 1, scope: !10, file: !8, line: 1, type: !13)
!16 = !DILocalVariable(name: "n", arg: 2, scope: !10, file: !8, line: 1, type: !13)
!17 = !DILocalVariable(name: "acc", scope: !10, file: !8, line: 2, type: !13)
!18 = !DILocalVariable(name: "i", scope: !19, file: !8, line: 3, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 3)
!20 = !DILocalVariable(name: "q", scope: !21, file: !8, line: 4, type: !13)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 3, column: 31)
!22 = distinct !DILexicalBlock(scope: !19, file: !8, line: 3, column: 3)
!23 = !DILocalVariable(name: "w", scope: !21, file: !8, line: 5, type: !13)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 0, scope: !19)
!26 = !DILocation(line: 3, column: 21, scope: !22)
!27 = !DILocation(line: 3, column: 3, scope: !19)
!28 = !DILocation(line: 9, column: 3, scope: !10)
!29 = !DILocation(line: 4, column: 13, scope: !21)
!30 = !DILocation(line: 0, scope: !21)
!31 = !DILocation(line: 5, column: 15, scope: !21)
!32 = !DILocation(line: 6, column: 9, scope: !21)
!33 = !DILocation(line: 7, column: 12, scope: !21)
!34 = !DILocation(line: 7, column: 28, scope: !21)
!35 = !DILocation(line: 7, column: 26, scope: !21)
!36 = !DILocation(line: 7, column: 9, scope: !21)
!37 = !DILocation(line: 3, column: 26, scope: !22)
!38 = distinct !{!38, !27, !39, !40, !41}
!39 = !DILocation(line: 8, column: 3, scope: !19)
!40 = !{!"llvm.loop.mustprogress"}
!41 = !{!"llvm.loop.unroll.disable"}
!42 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !43, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!43 = !DISubroutineType(types: !44)
!44 = !{!13}
!45 = !DILocation(line: 0, scope: !10, inlinedAt: !46)
!46 = distinct !DILocation(line: 11, column: 25, scope: !42)
!47 = !DILocation(line: 0, scope: !19, inlinedAt: !46)
!48 = !DILocation(line: 4, column: 13, scope: !21, inlinedAt: !46)
!49 = !DILocation(line: 0, scope: !21, inlinedAt: !46)
!50 = !DILocation(line: 5, column: 15, scope: !21, inlinedAt: !46)
!51 = !DILocation(line: 6, column: 9, scope: !21, inlinedAt: !46)
!52 = !DILocation(line: 7, column: 12, scope: !21, inlinedAt: !46)
!53 = !DILocation(line: 7, column: 28, scope: !21, inlinedAt: !46)
!54 = !DILocation(line: 7, column: 26, scope: !21, inlinedAt: !46)
!55 = !DILocation(line: 7, column: 9, scope: !21, inlinedAt: !46)
!56 = !DILocation(line: 3, column: 26, scope: !22, inlinedAt: !46)
!57 = !DILocation(line: 3, column: 21, scope: !22, inlinedAt: !46)
!58 = !DILocation(line: 3, column: 3, scope: !19, inlinedAt: !46)
!59 = distinct !{!59, !58, !60, !40, !41}
!60 = !DILocation(line: 8, column: 3, scope: !19, inlinedAt: !46)
!61 = !DILocation(line: 11, column: 18, scope: !42)
