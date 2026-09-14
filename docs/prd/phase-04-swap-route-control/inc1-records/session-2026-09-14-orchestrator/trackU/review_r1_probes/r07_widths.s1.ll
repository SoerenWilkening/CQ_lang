; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r07_widths.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r07_widths.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call signext i8 @cq_theta_c(i8 noundef signext undef, double noundef 5.000000e-01) #2, !dbg !24
    #dbg_value(i8 %1, !16, !DIExpression(), !25)
  %2 = tail call signext i16 @cq_theta_si16(i16 noundef signext undef, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i16 %2, !18, !DIExpression(), !25)
  %3 = tail call i64 @cq_theta_sll(i64 noundef undef, double noundef 5.000000e-01) #2, !dbg !27
    #dbg_value(i64 %3, !20, !DIExpression(), !25)
  %4 = tail call float @cq_theta_f32(float noundef undef, double noundef 5.000000e-01) #2, !dbg !28
    #dbg_value(float %4, !22, !DIExpression(), !25)
  %5 = tail call signext i8 @cq_measure_c(i8 noundef signext %1) #2, !dbg !29
  %6 = sext i8 %5 to i32, !dbg !30
  %7 = tail call signext i16 @cq_measure_si16(i16 noundef signext %2) #2, !dbg !31
  %8 = sext i16 %7 to i32, !dbg !32
  %9 = add nsw i32 %8, %6, !dbg !33
  %10 = tail call i64 @cq_measure_sll(i64 noundef %3) #2, !dbg !34
  %11 = trunc i64 %10 to i32, !dbg !35
  %12 = add nsw i32 %9, %11, !dbg !36
  %13 = tail call float @cq_measure_f32(float noundef %4) #2, !dbg !37
  %14 = fptosi float %13 to i32, !dbg !38
  %15 = add nsw i32 %12, %14, !dbg !39
  ret i32 %15, !dbg !40
}

declare !dbg !41 signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #1

declare !dbg !46 signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr #1

declare !dbg !49 i64 @cq_theta_sll(i64 noundef, double noundef) local_unnamed_addr #1

declare !dbg !52 float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #1

declare !dbg !55 signext i8 @cq_measure_c(i8 noundef signext) local_unnamed_addr #1

declare !dbg !58 signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #1

declare !dbg !61 i64 @cq_measure_sll(i64 noundef) local_unnamed_addr #1

declare !dbg !64 float @cq_measure_f32(float noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!11}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r07_widths.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "93fcc6c51ef943544be68b37ba1cc26b")
!9 = !{!10}
!10 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "f", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!13 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r07_widths.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "93fcc6c51ef943544be68b37ba1cc26b")
!14 = !DISubroutineType(types: !9)
!15 = !{!16, !18, !20, !22}
!16 = !DILocalVariable(name: "c8", scope: !12, file: !13, line: 4, type: !17)
!17 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!18 = !DILocalVariable(name: "s16", scope: !12, file: !13, line: 4, type: !19)
!19 = !DIBasicType(name: "short", size: 16, encoding: DW_ATE_signed)
!20 = !DILocalVariable(name: "l64", scope: !12, file: !13, line: 4, type: !21)
!21 = !DIBasicType(name: "long long", size: 64, encoding: DW_ATE_signed)
!22 = !DILocalVariable(name: "f32", scope: !12, file: !13, line: 4, type: !23)
!23 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!24 = !DILocation(line: 5, column: 9, scope: !12)
!25 = !DILocation(line: 0, scope: !12)
!26 = !DILocation(line: 6, column: 9, scope: !12)
!27 = !DILocation(line: 7, column: 9, scope: !12)
!28 = !DILocation(line: 8, column: 9, scope: !12)
!29 = !DILocation(line: 9, column: 15, scope: !12)
!30 = !DILocation(line: 9, column: 10, scope: !12)
!31 = !DILocation(line: 9, column: 37, scope: !12)
!32 = !DILocation(line: 9, column: 32, scope: !12)
!33 = !DILocation(line: 9, column: 30, scope: !12)
!34 = !DILocation(line: 9, column: 60, scope: !12)
!35 = !DILocation(line: 9, column: 55, scope: !12)
!36 = !DILocation(line: 9, column: 53, scope: !12)
!37 = !DILocation(line: 9, column: 83, scope: !12)
!38 = !DILocation(line: 9, column: 78, scope: !12)
!39 = !DILocation(line: 9, column: 76, scope: !12)
!40 = !DILocation(line: 9, column: 3, scope: !12)
!41 = !DISubprogram(name: "cq_theta_c", scope: !42, file: !42, line: 33, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!43 = !DISubroutineType(types: !44)
!44 = !{!17, !17, !45}
!45 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!46 = !DISubprogram(name: "cq_theta_si16", scope: !42, file: !42, line: 36, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DISubroutineType(types: !48)
!48 = !{!19, !19, !45}
!49 = !DISubprogram(name: "cq_theta_sll", scope: !42, file: !42, line: 42, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = !DISubroutineType(types: !51)
!51 = !{!21, !21, !45}
!52 = !DISubprogram(name: "cq_theta_f32", scope: !42, file: !42, line: 44, type: !53, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!53 = !DISubroutineType(types: !54)
!54 = !{!23, !23, !45}
!55 = !DISubprogram(name: "cq_measure_c", scope: !42, file: !42, line: 78, type: !56, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!56 = !DISubroutineType(types: !57)
!57 = !{!17, !17}
!58 = !DISubprogram(name: "cq_measure_si16", scope: !42, file: !42, line: 81, type: !59, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!59 = !DISubroutineType(types: !60)
!60 = !{!19, !19}
!61 = !DISubprogram(name: "cq_measure_sll", scope: !42, file: !42, line: 87, type: !62, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!62 = !DISubroutineType(types: !63)
!63 = !{!21, !21}
!64 = !DISubprogram(name: "cq_measure_f32", scope: !42, file: !42, line: 89, type: !65, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!65 = !DISubroutineType(types: !66)
!66 = !{!23, !23}
