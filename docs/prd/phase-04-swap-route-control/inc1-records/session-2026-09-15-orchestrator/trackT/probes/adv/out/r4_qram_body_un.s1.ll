; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r4_qram_body_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r4_qram_body_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.slice.tbl = private unnamed_addr constant [8 x i32] [i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
    #dbg_declare(ptr @__const.slice.tbl, !15, !DIExpression(), !21)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i32 %1, !19, !DIExpression(), !23)
    #dbg_value(i32 0, !20, !DIExpression(), !23)
  %2 = lshr i32 %1, 1, !dbg !24
  %3 = and i32 %2, 7, !dbg !24
  %4 = zext nneg i32 %3 to i64, !dbg !24
  %5 = getelementptr inbounds [8 x i32], ptr @__const.slice.tbl, i64 0, i64 %4, !dbg !24
  %6 = load i32, ptr %5, align 4, !dbg !24, !tbaa !25
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !24
    #dbg_value(i32 %7, !20, !DIExpression(), !23)
  %8 = lshr i32 %1, 2, !dbg !29
  %9 = and i32 %8, 7, !dbg !29
  %10 = zext nneg i32 %9 to i64, !dbg !29
  %11 = getelementptr inbounds [8 x i32], ptr @__const.slice.tbl, i64 0, i64 %10, !dbg !29
  %12 = load i32, ptr %11, align 4, !dbg !29, !tbaa !25
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !29
  %14 = add nsw i32 %13, %7, !dbg !30
    #dbg_value(i32 %14, !20, !DIExpression(), !23)
  %15 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !31
    #dbg_value(i32 %15, !19, !DIExpression(), !23)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !32
  %17 = add nsw i32 %14, %16, !dbg !33
  ret i32 %17, !dbg !34
}

declare !dbg !35 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !40 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !43 {
    #dbg_declare(ptr @__const.slice.tbl, !15, !DIExpression(), !44)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !46
    #dbg_value(i32 %1, !19, !DIExpression(), !47)
    #dbg_value(i32 0, !20, !DIExpression(), !47)
  %2 = lshr i32 %1, 1, !dbg !48
  %3 = and i32 %2, 7, !dbg !48
  %4 = zext nneg i32 %3 to i64, !dbg !48
  %5 = getelementptr inbounds [8 x i32], ptr @__const.slice.tbl, i64 0, i64 %4, !dbg !48
  %6 = load i32, ptr %5, align 4, !dbg !48, !tbaa !25
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !48
    #dbg_value(i32 %7, !20, !DIExpression(), !47)
  %8 = lshr i32 %1, 2, !dbg !49
  %9 = and i32 %8, 7, !dbg !49
  %10 = zext nneg i32 %9 to i64, !dbg !49
  %11 = getelementptr inbounds [8 x i32], ptr @__const.slice.tbl, i64 0, i64 %10, !dbg !49
  %12 = load i32, ptr %11, align 4, !dbg !49, !tbaa !25
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !49
  %14 = add nsw i32 %13, %7, !dbg !50
    #dbg_value(i32 %14, !20, !DIExpression(), !47)
  %15 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !51
    #dbg_value(i32 %15, !19, !DIExpression(), !47)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !52
  %17 = add nsw i32 %14, %16, !dbg !53
  ret i32 %17, !dbg !54
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r4_qram_body_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e390512ea4e5633142d6cd62d0241c01")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !19, !20}
!15 = !DILocalVariable(name: "tbl", scope: !10, file: !8, line: 3, type: !16)
!16 = !DICompositeType(tag: DW_TAG_array_type, baseType: !13, size: 256, elements: !17)
!17 = !{!18}
!18 = !DISubrange(count: 8)
!19 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!20 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!21 = !DILocation(line: 3, column: 9, scope: !10)
!22 = !DILocation(line: 4, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 6, column: 10, scope: !10)
!25 = !{!26, !26, i64 0}
!26 = !{!"int", !27, i64 0}
!27 = !{!"omnipotent char", !28, i64 0}
!28 = !{!"Simple C/C++ TBAA"}
!29 = !DILocation(line: 7, column: 10, scope: !10)
!30 = !DILocation(line: 7, column: 7, scope: !10)
!31 = !DILocation(line: 8, column: 9, scope: !10)
!32 = !DILocation(line: 9, column: 16, scope: !10)
!33 = !DILocation(line: 9, column: 14, scope: !10)
!34 = !DILocation(line: 9, column: 5, scope: !10)
!35 = !DISubprogram(name: "cq_theta_si32", scope: !36, file: !36, line: 38, type: !37, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!36 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!37 = !DISubroutineType(types: !38)
!38 = !{!13, !13, !39}
!39 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!40 = !DISubprogram(name: "cq_measure_si32", scope: !36, file: !36, line: 83, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DISubroutineType(types: !42)
!42 = !{!13, !13}
!43 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !11, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!44 = !DILocation(line: 3, column: 9, scope: !10, inlinedAt: !45)
!45 = distinct !DILocation(line: 11, column: 25, scope: !43)
!46 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !45)
!47 = !DILocation(line: 0, scope: !10, inlinedAt: !45)
!48 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !45)
!49 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !45)
!50 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !45)
!51 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !45)
!52 = !DILocation(line: 9, column: 16, scope: !10, inlinedAt: !45)
!53 = !DILocation(line: 9, column: 14, scope: !10, inlinedAt: !45)
!54 = !DILocation(line: 11, column: 18, scope: !43)
