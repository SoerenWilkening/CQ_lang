; ModuleID = 'src/r32_delta_s03_chain.c'
source_filename = "src/r32_delta_s03_chain.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1, !dbg !0

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 !dbg !17 {
    #dbg_value(i32 0, !22, !DIExpression(), !29)
    #dbg_value(i32 0, !23, !DIExpression(), !29)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #3, !dbg !30
    #dbg_value(i32 %1, !22, !DIExpression(), !29)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01) #3, !dbg !31
    #dbg_value(i32 %2, !23, !DIExpression(), !29)
    #dbg_value(i32 5, !24, !DIExpression(), !29)
    #dbg_value(i32 1, !25, !DIExpression(), !29)
  %3 = icmp eq i32 %1, 5, !dbg !32
  br i1 %3, label %4, label %6, !dbg !34

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #3, !dbg !35
    #dbg_value(i32 %5, !23, !DIExpression(), !29)
    #dbg_value(i32 7, !24, !DIExpression(), !29)
    #dbg_value(i32 2, !25, !DIExpression(), !29)
  br label %6, !dbg !37

6:                                                ; preds = %4, %0
  %7 = phi i32 [ 2, %4 ], [ 1, %0 ], !dbg !29
  %8 = phi i32 [ 7, %4 ], [ 5, %0 ], !dbg !29
  %9 = phi i32 [ %5, %4 ], [ %2, %0 ], !dbg !29
    #dbg_value(i32 %9, !23, !DIExpression(), !29)
    #dbg_value(i32 %8, !24, !DIExpression(), !29)
    #dbg_value(i32 %7, !25, !DIExpression(), !29)
  %10 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #3, !dbg !38
    #dbg_value(i32 %10, !26, !DIExpression(), !29)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 0x3FE6666666666666) #3, !dbg !39
    #dbg_value(i32 %11, !27, !DIExpression(), !29)
  %12 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 6.000000e-01) #3, !dbg !40
    #dbg_value(i32 %12, !28, !DIExpression(), !29)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %9) #3, !dbg !41
  %14 = tail call i32 @cq_measure_si32(i32 noundef %11) #3, !dbg !42
  %15 = add nsw i32 %14, %13, !dbg !43
  %16 = tail call i32 @cq_measure_si32(i32 noundef %12) #3, !dbg !44
  %17 = add nsw i32 %15, %16, !dbg !45
  %18 = tail call i32 @cq_measure_si32(i32 noundef %7) #3, !dbg !46
  %19 = add nsw i32 %17, %18, !dbg !47
  %20 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %19), !dbg !48
  ret i32 0, !dbg !49
}

declare !dbg !50 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare !dbg !55 noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

declare !dbg !62 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.module.flags = !{!7, !8, !9, !10, !11, !12, !13}
!llvm.dbg.cu = !{!14}
!llvm.ident = !{!16}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 15, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "src/r32_delta_s03_chain.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes", checksumkind: CSK_MD5, checksum: "793b2987038940f9fa50f0dcf9ba40e5")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 32, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 4)
!7 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!8 = !{i32 7, !"Dwarf Version", i32 5}
!9 = !{i32 2, !"Debug Info Version", i32 3}
!10 = !{i32 1, !"wchar_size", i32 4}
!11 = !{i32 8, !"PIC Level", i32 2}
!12 = !{i32 7, !"uwtable", i32 2}
!13 = !{i32 7, !"frame-pointer", i32 2}
!14 = distinct !DICompileUnit(language: DW_LANG_C11, file: !2, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, globals: !15, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!15 = !{!0}
!16 = !{!"Homebrew clang version 19.1.7"}
!17 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 6, type: !18, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !14, retainedNodes: !21)
!18 = !DISubroutineType(types: !19)
!19 = !{!20}
!20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!21 = !{!22, !23, !24, !25, !26, !27, !28}
!22 = !DILocalVariable(name: "q", scope: !17, file: !2, line: 7, type: !20)
!23 = !DILocalVariable(name: "a", scope: !17, file: !2, line: 7, type: !20)
!24 = !DILocalVariable(name: "m", scope: !17, file: !2, line: 10, type: !20)
!25 = !DILocalVariable(name: "n", scope: !17, file: !2, line: 10, type: !20)
!26 = !DILocalVariable(name: "r1", scope: !17, file: !2, line: 12, type: !20)
!27 = !DILocalVariable(name: "r3", scope: !17, file: !2, line: 13, type: !20)
!28 = !DILocalVariable(name: "r2", scope: !17, file: !2, line: 14, type: !20)
!29 = !DILocation(line: 0, scope: !17)
!30 = !DILocation(line: 8, column: 7, scope: !17)
!31 = !DILocation(line: 9, column: 7, scope: !17)
!32 = !DILocation(line: 11, column: 9, scope: !33)
!33 = distinct !DILexicalBlock(scope: !17, file: !2, line: 11, column: 7)
!34 = !DILocation(line: 11, column: 7, scope: !17)
!35 = !DILocation(line: 11, column: 21, scope: !36)
!36 = distinct !DILexicalBlock(scope: !33, file: !2, line: 11, column: 15)
!37 = !DILocation(line: 11, column: 53, scope: !36)
!38 = !DILocation(line: 12, column: 12, scope: !17)
!39 = !DILocation(line: 13, column: 12, scope: !17)
!40 = !DILocation(line: 14, column: 12, scope: !17)
!41 = !DILocation(line: 15, column: 18, scope: !17)
!42 = !DILocation(line: 15, column: 34, scope: !17)
!43 = !DILocation(line: 15, column: 32, scope: !17)
!44 = !DILocation(line: 15, column: 51, scope: !17)
!45 = !DILocation(line: 15, column: 49, scope: !17)
!46 = !DILocation(line: 15, column: 68, scope: !17)
!47 = !DILocation(line: 15, column: 66, scope: !17)
!48 = !DILocation(line: 15, column: 3, scope: !17)
!49 = !DILocation(line: 16, column: 3, scope: !17)
!50 = !DISubprogram(name: "cq_theta_si32", scope: !51, file: !51, line: 38, type: !52, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!52 = !DISubroutineType(types: !53)
!53 = !{!20, !20, !54}
!54 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!55 = !DISubprogram(name: "printf", scope: !56, file: !56, line: 34, type: !57, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!56 = !DIFile(filename: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/_printf.h", directory: "", checksumkind: CSK_MD5, checksum: "2d37517bd0342aa326aa1d3660ad4ab4")
!57 = !DISubroutineType(types: !58)
!58 = !{!20, !59, null}
!59 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !60)
!60 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !61, size: 64)
!61 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
!62 = !DISubprogram(name: "cq_measure_si32", scope: !51, file: !51, line: 83, type: !63, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!63 = !DISubroutineType(types: !64)
!64 = !{!20, !20}
