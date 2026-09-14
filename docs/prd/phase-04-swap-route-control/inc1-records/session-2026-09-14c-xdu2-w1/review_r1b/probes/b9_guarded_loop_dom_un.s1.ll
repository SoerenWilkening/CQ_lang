; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b9_guarded_loop_dom_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b9_guarded_loop_dom_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !18)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !19
    #dbg_value(i32 %2, !16, !DIExpression(), !18)
    #dbg_value(i32 0, !17, !DIExpression(), !18)
  %3 = lshr i32 %2, 1, !dbg !20
  %4 = and i32 %3, 1, !dbg !20
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !20
    #dbg_value(i32 %5, !17, !DIExpression(), !18)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2, !dbg !21
    #dbg_value(i32 %6, !16, !DIExpression(), !18)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !22
  %8 = add nsw i32 %7, %5, !dbg !23
  ret i32 %8, !dbg !24
}

declare !dbg !25 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !30 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !31 {
    #dbg_value(i32 %0, !38, !DIExpression(), !40)
    #dbg_value(ptr %1, !39, !DIExpression(), !40)
    #dbg_value(i32 %0, !15, !DIExpression(), !41)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !43
    #dbg_value(i32 %3, !16, !DIExpression(), !41)
    #dbg_value(i32 0, !17, !DIExpression(), !41)
  %4 = lshr i32 %3, 1, !dbg !44
  %5 = and i32 %4, 1, !dbg !44
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !44
    #dbg_value(i32 %6, !17, !DIExpression(), !41)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 9.000000e-01) #2, !dbg !45
    #dbg_value(i32 %7, !16, !DIExpression(), !41)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !46
  %9 = add nsw i32 %8, %6, !dbg !47
  ret i32 %9, !dbg !48
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b9_guarded_loop_dom_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "9905c8dcf84f573ff4f8eed1b0dfe337")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "n", arg: 1, scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 4, column: 13, scope: !10)
!20 = !DILocation(line: 7, column: 10, scope: !10)
!21 = !DILocation(line: 8, column: 9, scope: !10)
!22 = !DILocation(line: 9, column: 16, scope: !10)
!23 = !DILocation(line: 9, column: 14, scope: !10)
!24 = !DILocation(line: 9, column: 5, scope: !10)
!25 = !DISubprogram(name: "cq_theta_si32", scope: !26, file: !26, line: 38, type: !27, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!26 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!27 = !DISubroutineType(types: !28)
!28 = !{!13, !13, !29}
!29 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!30 = !DISubprogram(name: "cq_measure_si32", scope: !26, file: !26, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!31 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !32, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !37)
!32 = !DISubroutineType(types: !33)
!33 = !{!13, !13, !34}
!34 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !35, size: 64)
!35 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !36, size: 64)
!36 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!37 = !{!38, !39}
!38 = !DILocalVariable(name: "argc", arg: 1, scope: !31, file: !8, line: 11, type: !13)
!39 = !DILocalVariable(name: "argv", arg: 2, scope: !31, file: !8, line: 11, type: !34)
!40 = !DILocation(line: 0, scope: !31)
!41 = !DILocation(line: 0, scope: !10, inlinedAt: !42)
!42 = distinct !DILocation(line: 11, column: 54, scope: !31)
!43 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !42)
!44 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !42)
!45 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !42)
!46 = !DILocation(line: 9, column: 16, scope: !10, inlinedAt: !42)
!47 = !DILocation(line: 9, column: 14, scope: !10, inlinedAt: !42)
!48 = !DILocation(line: 11, column: 47, scope: !31)
