; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes/s1/r32_delta_s03_chain.ll'
source_filename = "src/r32_delta_s03_chain.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1, !dbg !0

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 !dbg !17 {
    #dbg_value(i32 0, !22, !DIExpression(), !29)
    #dbg_value(i32 0, !23, !DIExpression(), !29)
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !30
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !30
    #dbg_value(i32 %h, !22, !DIExpression(), !29)
  %h9 = call i32 @cqrt_alloc_i32(i32 0), !dbg !31
  call void @cqrt_ry_i32(i32 %h9, double 4.000000e-01), !dbg !31
    #dbg_value(i32 %h9, !23, !DIExpression(), !29)
    #dbg_value(i32 5, !24, !DIExpression(), !29)
    #dbg_value(i32 1, !25, !DIExpression(), !29)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5), !dbg !32
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h9, double 9.000000e-01), !dbg !34
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5), !dbg !32
  call void @cqrt_free(i32 %h_cmp), !dbg !36
    #dbg_value(i32 %h9, !23, !DIExpression(), !29)
    #dbg_value(i32 %out6, !24, !DIExpression(), !29)
    #dbg_value(i32 %out, !25, !DIExpression(), !29)
  %h_cmp3 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5), !dbg !32
  %out = call i32 @cqrt_alloc_i32(i32 0), !dbg !29
  %selop = call i32 @cqrt_alloc_i32(i32 2), !dbg !29
  call void @cqrt_copy_i32_controlled(i32 %h_cmp3, i32 %selop, i32 %out), !dbg !29
  call void @cqrt_x(i32 %h_cmp3), !dbg !29
  %selop4 = call i32 @cqrt_alloc_i32(i32 1), !dbg !29
  call void @cqrt_copy_i32_controlled(i32 %h_cmp3, i32 %selop4, i32 %out), !dbg !29
  call void @cqrt_x(i32 %h_cmp3), !dbg !29
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp3, i32 %h, i32 5), !dbg !32
  call void @cqrt_free(i32 %h_cmp3), !dbg !29
  %h_cmp5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5), !dbg !32
  %out6 = call i32 @cqrt_alloc_i32(i32 0), !dbg !29
  %selop7 = call i32 @cqrt_alloc_i32(i32 7), !dbg !29
  call void @cqrt_copy_i32_controlled(i32 %h_cmp5, i32 %selop7, i32 %out6), !dbg !29
  call void @cqrt_x(i32 %h_cmp5), !dbg !29
  %selop8 = call i32 @cqrt_alloc_i32(i32 5), !dbg !29
  call void @cqrt_copy_i32_controlled(i32 %h_cmp5, i32 %selop8, i32 %out6), !dbg !29
  call void @cqrt_x(i32 %h_cmp5), !dbg !29
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp5, i32 %h, i32 5), !dbg !32
  call void @cqrt_free(i32 %h_cmp5), !dbg !29
  call void @cqrt_ry_i32(i32 %out6, double 2.000000e-01), !dbg !37
    #dbg_value(i32 %out6, !26, !DIExpression(), !29)
  call void @cqrt_ry_i32(i32 %out6, double 0x3FE6666666666666), !dbg !38
    #dbg_value(i32 %out6, !27, !DIExpression(), !29)
  call void @cqrt_ry_i32(i32 %out6, double 6.000000e-01), !dbg !39
    #dbg_value(i32 %out6, !28, !DIExpression(), !29)
  %m = call i32 @cqrt_measure_i32(i32 %h9), !dbg !40
  %m10 = call i32 @cqrt_measure_i32(i32 %out6), !dbg !41
  %1 = add nsw i32 %m10, %m, !dbg !42
  %m11 = call i32 @cqrt_measure_i32(i32 %out6), !dbg !43
  %2 = add nsw i32 %1, %m11, !dbg !44
  %m12 = call i32 @cqrt_measure_i32(i32 %out), !dbg !45
  %3 = add nsw i32 %2, %m12, !dbg !46
  %4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %3), !dbg !47
  ret i32 0, !dbg !48
}

; Function Attrs: nofree nounwind
declare !dbg !49 noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #1

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

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
!34 = !DILocation(line: 11, column: 21, scope: !35)
!35 = distinct !DILexicalBlock(scope: !33, file: !2, line: 11, column: 15)
!36 = !DILocation(line: 11, column: 7, scope: !17)
!37 = !DILocation(line: 12, column: 12, scope: !17)
!38 = !DILocation(line: 13, column: 12, scope: !17)
!39 = !DILocation(line: 14, column: 12, scope: !17)
!40 = !DILocation(line: 15, column: 18, scope: !17)
!41 = !DILocation(line: 15, column: 34, scope: !17)
!42 = !DILocation(line: 15, column: 32, scope: !17)
!43 = !DILocation(line: 15, column: 51, scope: !17)
!44 = !DILocation(line: 15, column: 49, scope: !17)
!45 = !DILocation(line: 15, column: 68, scope: !17)
!46 = !DILocation(line: 15, column: 66, scope: !17)
!47 = !DILocation(line: 15, column: 3, scope: !17)
!48 = !DILocation(line: 16, column: 3, scope: !17)
!49 = !DISubprogram(name: "printf", scope: !50, file: !50, line: 34, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = !DIFile(filename: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/_printf.h", directory: "", checksumkind: CSK_MD5, checksum: "2d37517bd0342aa326aa1d3660ad4ab4")
!51 = !DISubroutineType(types: !52)
!52 = !{!20, !53, null}
!53 = !DIDerivedType(tag: DW_TAG_restrict_type, baseType: !54)
!54 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !55, size: 64)
!55 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
