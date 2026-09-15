; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r4_qram_body.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r4_qram_body.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.slice.tbl = private unnamed_addr constant [8 x i32] [i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
    #dbg_declare(ptr @__const.slice.tbl, !15, !DIExpression(), !23)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !24
    #dbg_value(i32 %1, !19, !DIExpression(), !25)
    #dbg_value(i32 0, !20, !DIExpression(), !25)
    #dbg_value(i32 1, !21, !DIExpression(), !26)
  br label %6, !dbg !27

2:                                                ; preds = %6
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !28
    #dbg_value(i32 %3, !19, !DIExpression(), !25)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !29
  %5 = add nsw i32 %4, %15, !dbg !30
  ret i32 %5, !dbg !31

6:                                                ; preds = %0, %6
  %7 = phi i32 [ 1, %0 ], [ %16, %6 ]
  %8 = phi i32 [ 0, %0 ], [ %15, %6 ]
    #dbg_value(i32 %7, !21, !DIExpression(), !26)
    #dbg_value(i32 %8, !20, !DIExpression(), !25)
  %9 = ashr i32 %1, %7, !dbg !32
  %10 = and i32 %9, 7, !dbg !32
  %11 = zext nneg i32 %10 to i64, !dbg !32
  %12 = getelementptr inbounds [8 x i32], ptr @__const.slice.tbl, i64 0, i64 %11, !dbg !32
  %13 = load i32, ptr %12, align 4, !dbg !32, !tbaa !34
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !32
  %15 = add nsw i32 %14, %8, !dbg !38
    #dbg_value(i32 %15, !20, !DIExpression(), !25)
  %16 = add nuw nsw i32 %7, 1, !dbg !39
    #dbg_value(i32 %16, !21, !DIExpression(), !26)
  %17 = icmp eq i32 %16, 3, !dbg !40
  br i1 %17, label %2, label %6, !dbg !27, !llvm.loop !41
}

declare !dbg !45 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !50 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !53 {
    #dbg_declare(ptr @__const.slice.tbl, !15, !DIExpression(), !54)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !56
    #dbg_value(i32 %1, !19, !DIExpression(), !57)
    #dbg_value(i32 0, !20, !DIExpression(), !57)
    #dbg_value(i32 1, !21, !DIExpression(), !58)
  br label %2, !dbg !59

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %12, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %11, %2 ]
    #dbg_value(i32 %3, !21, !DIExpression(), !58)
    #dbg_value(i32 %4, !20, !DIExpression(), !57)
  %5 = ashr i32 %1, %3, !dbg !60
  %6 = and i32 %5, 7, !dbg !60
  %7 = zext nneg i32 %6 to i64, !dbg !60
  %8 = getelementptr inbounds [8 x i32], ptr @__const.slice.tbl, i64 0, i64 %7, !dbg !60
  %9 = load i32, ptr %8, align 4, !dbg !60, !tbaa !34
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !60
  %11 = add nsw i32 %10, %4, !dbg !61
    #dbg_value(i32 %11, !20, !DIExpression(), !57)
  %12 = add nuw nsw i32 %3, 1, !dbg !62
    #dbg_value(i32 %12, !21, !DIExpression(), !58)
  %13 = icmp eq i32 %12, 3, !dbg !63
  br i1 %13, label %14, label %2, !dbg !59, !llvm.loop !64

14:                                               ; preds = %2
  %15 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !66
    #dbg_value(i32 %15, !19, !DIExpression(), !57)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !67
  %17 = add nsw i32 %16, %11, !dbg !68
  ret i32 %17, !dbg !69
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r4_qram_body.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "32bd2c74663227bc59360fdf978f98a7")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !19, !20, !21}
!15 = !DILocalVariable(name: "tbl", scope: !10, file: !8, line: 5, type: !16)
!16 = !DICompositeType(tag: DW_TAG_array_type, baseType: !13, size: 256, elements: !17)
!17 = !{!18}
!18 = !DISubrange(count: 8)
!19 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 6, type: !13)
!20 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!21 = !DILocalVariable(name: "k", scope: !22, file: !8, line: 8, type: !13)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!23 = !DILocation(line: 5, column: 9, scope: !10)
!24 = !DILocation(line: 6, column: 13, scope: !10)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 0, scope: !22)
!27 = !DILocation(line: 8, column: 5, scope: !22)
!28 = !DILocation(line: 10, column: 9, scope: !10)
!29 = !DILocation(line: 11, column: 16, scope: !10)
!30 = !DILocation(line: 11, column: 14, scope: !10)
!31 = !DILocation(line: 11, column: 5, scope: !10)
!32 = !DILocation(line: 9, column: 14, scope: !33)
!33 = distinct !DILexicalBlock(scope: !22, file: !8, line: 8, column: 5)
!34 = !{!35, !35, i64 0}
!35 = !{!"int", !36, i64 0}
!36 = !{!"omnipotent char", !37, i64 0}
!37 = !{!"Simple C/C++ TBAA"}
!38 = !DILocation(line: 9, column: 11, scope: !33)
!39 = !DILocation(line: 8, column: 29, scope: !33)
!40 = !DILocation(line: 8, column: 23, scope: !33)
!41 = distinct !{!41, !27, !42, !43, !44}
!42 = !DILocation(line: 9, column: 14, scope: !22)
!43 = !{!"llvm.loop.mustprogress"}
!44 = !{!"llvm.loop.unroll.disable"}
!45 = !DISubprogram(name: "cq_theta_si32", scope: !46, file: !46, line: 38, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!47 = !DISubroutineType(types: !48)
!48 = !{!13, !13, !49}
!49 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!50 = !DISubprogram(name: "cq_measure_si32", scope: !46, file: !46, line: 83, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(types: !52)
!52 = !{!13, !13}
!53 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!54 = !DILocation(line: 5, column: 9, scope: !10, inlinedAt: !55)
!55 = distinct !DILocation(line: 13, column: 25, scope: !53)
!56 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !55)
!57 = !DILocation(line: 0, scope: !10, inlinedAt: !55)
!58 = !DILocation(line: 0, scope: !22, inlinedAt: !55)
!59 = !DILocation(line: 8, column: 5, scope: !22, inlinedAt: !55)
!60 = !DILocation(line: 9, column: 14, scope: !33, inlinedAt: !55)
!61 = !DILocation(line: 9, column: 11, scope: !33, inlinedAt: !55)
!62 = !DILocation(line: 8, column: 29, scope: !33, inlinedAt: !55)
!63 = !DILocation(line: 8, column: 23, scope: !33, inlinedAt: !55)
!64 = distinct !{!64, !59, !65, !43, !44}
!65 = !DILocation(line: 9, column: 14, scope: !22, inlinedAt: !55)
!66 = !DILocation(line: 10, column: 9, scope: !10, inlinedAt: !55)
!67 = !DILocation(line: 11, column: 16, scope: !10, inlinedAt: !55)
!68 = !DILocation(line: 11, column: 14, scope: !10, inlinedAt: !55)
!69 = !DILocation(line: 13, column: 18, scope: !53)
