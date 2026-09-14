; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes/s1/r5a_while_runtime_trip.ll'
source_filename = "src/r5a_while_runtime_trip.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !23)
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !24
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !24
    #dbg_value(i32 %h, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !23)
    #dbg_value(i32 0, !18, !DIExpression(), !25)
  %2 = icmp sgt i32 %0, 0, !dbg !26
  br i1 %2, label %5, label %3, !dbg !27

3:                                                ; preds = %5, %1
  %4 = phi i32 [ 0, %1 ], [ %8, %5 ], !dbg !28
  ret i32 %4, !dbg !29

5:                                                ; preds = %5, %1
  %6 = phi i32 [ %8, %5 ], [ 0, %1 ]
  %7 = phi i32 [ %9, %5 ], [ 0, %1 ]
    #dbg_value(i32 %6, !17, !DIExpression(), !23)
    #dbg_value(i32 %7, !18, !DIExpression(), !25)
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !30
    #dbg_value(i32 %h, !20, !DIExpression(), !31)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !32
  %8 = add nsw i32 %m, %6, !dbg !33
    #dbg_value(i32 %8, !17, !DIExpression(), !23)
  %9 = add nuw nsw i32 %7, 1, !dbg !34
    #dbg_value(i32 %9, !18, !DIExpression(), !25)
  %10 = icmp eq i32 %9, %0, !dbg !26
  br i1 %10, label %3, label %5, !dbg !27, !llvm.loop !35
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !39 {
    #dbg_value(i32 3, !15, !DIExpression(), !42)
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !44
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !44
    #dbg_value(i32 %h, !16, !DIExpression(), !42)
    #dbg_value(i32 0, !17, !DIExpression(), !42)
    #dbg_value(i32 0, !18, !DIExpression(), !45)
  br label %1

1:                                                ; preds = %1, %0
  %2 = phi i32 [ %4, %1 ], [ 0, %0 ]
  %3 = phi i32 [ %5, %1 ], [ 0, %0 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !42)
    #dbg_value(i32 %3, !18, !DIExpression(), !45)
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !46
    #dbg_value(i32 %h, !20, !DIExpression(), !47)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !48
  %4 = add nsw i32 %m, %2, !dbg !49
    #dbg_value(i32 %4, !17, !DIExpression(), !42)
  %5 = add nuw nsw i32 %3, 1, !dbg !50
    #dbg_value(i32 %5, !18, !DIExpression(), !45)
  %6 = icmp eq i32 %5, 3, !dbg !51
  br i1 %6, label %7, label %1, !dbg !52, !llvm.loop !53

7:                                                ; preds = %1
  ret i32 %4, !dbg !55
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
!8 = !DIFile(filename: "src/r5a_while_runtime_trip.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes", checksumkind: CSK_MD5, checksum: "6fb911af9df2b3a7e0a5bd064a75b7f0")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !20}
!15 = !DILocalVariable(name: "n", arg: 1, scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!18 = !DILocalVariable(name: "i", scope: !19, file: !8, line: 3, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 51)
!20 = !DILocalVariable(name: "b", scope: !21, file: !8, line: 3, type: !13)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 3, column: 71)
!22 = distinct !DILexicalBlock(scope: !19, file: !8, line: 3, column: 51)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 3, column: 25, scope: !10)
!25 = !DILocation(line: 0, scope: !19)
!26 = !DILocation(line: 3, column: 64, scope: !22)
!27 = !DILocation(line: 3, column: 51, scope: !19)
!28 = !DILocation(line: 3, scope: !10)
!29 = !DILocation(line: 3, column: 116, scope: !10)
!30 = !DILocation(line: 3, column: 79, scope: !21)
!31 = !DILocation(line: 0, scope: !21)
!32 = !DILocation(line: 3, column: 99, scope: !21)
!33 = !DILocation(line: 3, column: 97, scope: !21)
!34 = !DILocation(line: 3, column: 68, scope: !22)
!35 = distinct !{!35, !27, !36, !37, !38}
!36 = !DILocation(line: 3, column: 114, scope: !19)
!37 = !{!"llvm.loop.mustprogress"}
!38 = !{!"llvm.loop.unroll.disable"}
!39 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !40, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!40 = !DISubroutineType(types: !41)
!41 = !{!13}
!42 = !DILocation(line: 0, scope: !10, inlinedAt: !43)
!43 = distinct !DILocation(line: 4, column: 24, scope: !39)
!44 = !DILocation(line: 3, column: 25, scope: !10, inlinedAt: !43)
!45 = !DILocation(line: 0, scope: !19, inlinedAt: !43)
!46 = !DILocation(line: 3, column: 79, scope: !21, inlinedAt: !43)
!47 = !DILocation(line: 0, scope: !21, inlinedAt: !43)
!48 = !DILocation(line: 3, column: 99, scope: !21, inlinedAt: !43)
!49 = !DILocation(line: 3, column: 97, scope: !21, inlinedAt: !43)
!50 = !DILocation(line: 3, column: 68, scope: !22, inlinedAt: !43)
!51 = !DILocation(line: 3, column: 64, scope: !22, inlinedAt: !43)
!52 = !DILocation(line: 3, column: 51, scope: !19, inlinedAt: !43)
!53 = distinct !{!53, !52, !54, !37, !38}
!54 = !DILocation(line: 3, column: 114, scope: !19, inlinedAt: !43)
!55 = !DILocation(line: 4, column: 17, scope: !39)
