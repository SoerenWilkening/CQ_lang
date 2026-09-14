; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b9_guarded_loop_dom_un.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b9_guarded_loop_dom_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !18)
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !19
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !19
    #dbg_value(i32 %h, !16, !DIExpression(), !18)
    #dbg_value(i32 0, !17, !DIExpression(), !18)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !20
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !20
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !20
  call void @cqrt_free(i32 %h_op), !dbg !20
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !20
    #dbg_value(i32 %m, !17, !DIExpression(), !18)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !21
    #dbg_value(i32 %h, !16, !DIExpression(), !18)
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !22
  %2 = add nsw i32 %m2, %m, !dbg !23
  ret i32 %2, !dbg !24
}

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !25 {
    #dbg_value(i32 %0, !32, !DIExpression(), !34)
    #dbg_value(ptr %1, !33, !DIExpression(), !34)
    #dbg_value(i32 %0, !15, !DIExpression(), !35)
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !37
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !37
    #dbg_value(i32 %h, !16, !DIExpression(), !35)
    #dbg_value(i32 0, !17, !DIExpression(), !35)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !38
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !38
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !38
  call void @cqrt_free(i32 %h_op), !dbg !38
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !38
    #dbg_value(i32 %m, !17, !DIExpression(), !35)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !39
    #dbg_value(i32 %h, !16, !DIExpression(), !35)
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !40
  %3 = add nsw i32 %m2, %m, !dbg !41
  ret i32 %3, !dbg !42
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

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
!25 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !26, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !31)
!26 = !DISubroutineType(types: !27)
!27 = !{!13, !13, !28}
!28 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !29, size: 64)
!29 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !30, size: 64)
!30 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!31 = !{!32, !33}
!32 = !DILocalVariable(name: "argc", arg: 1, scope: !25, file: !8, line: 11, type: !13)
!33 = !DILocalVariable(name: "argv", arg: 2, scope: !25, file: !8, line: 11, type: !28)
!34 = !DILocation(line: 0, scope: !25)
!35 = !DILocation(line: 0, scope: !10, inlinedAt: !36)
!36 = distinct !DILocation(line: 11, column: 54, scope: !25)
!37 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !36)
!38 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !36)
!39 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !36)
!40 = !DILocation(line: 9, column: 16, scope: !10, inlinedAt: !36)
!41 = !DILocation(line: 9, column: 14, scope: !10, inlinedAt: !36)
!42 = !DILocation(line: 11, column: 47, scope: !25)
