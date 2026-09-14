; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.3NSgjbrNcQ/s1.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i32(i32 3), !dbg !21
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !21
    #dbg_value(i32 %h, !18, !DIExpression(), !22)
    #dbg_value(i32 5, !19, !DIExpression(), !22)
  %1 = tail call i32 @ext_f(i32 noundef 7) #2, !dbg !23
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5), !dbg !25
  %out = call i32 @cqrt_alloc_i32(i32 0), !dbg !25
  %selop = call i32 @cqrt_alloc_i32(i32 %1), !dbg !25
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out), !dbg !25
  call void @cqrt_x(i32 %h_cmp), !dbg !25
  %selop1 = call i32 @cqrt_alloc_i32(i32 5), !dbg !25
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out), !dbg !25
  call void @cqrt_x(i32 %h_cmp), !dbg !25
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5), !dbg !25
  call void @cqrt_free(i32 %h_cmp), !dbg !25
    #dbg_value(i32 %out, !19, !DIExpression(), !22)
  %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %out, i32 50), !dbg !26
  call void @cqrt_rz_i1(i32 %h_cmp2, double 3.000000e-01), !dbg !28, !cq.branchphase !29
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp2, i32 %out, i32 50), !dbg !26
  call void @cqrt_free(i32 %h_cmp2), !dbg !28
  call void @cqrt_ry_i32(i32 %out, double 2.000000e-01), !dbg !30
    #dbg_value(i32 %out, !20, !DIExpression(), !22)
  %m = call i32 @cqrt_measure_i32(i32 %out), !dbg !31
  %m3 = call i32 @cqrt_measure_i32(i32 %h), !dbg !32
  %2 = add nsw i32 %m3, %m, !dbg !33
  ret i32 %2, !dbg !34
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !35 {
  %h = call i32 @cqrt_alloc_i32(i32 3), !dbg !36
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !36
    #dbg_value(i32 %h, !18, !DIExpression(), !38)
    #dbg_value(i32 5, !19, !DIExpression(), !38)
  %1 = tail call i32 @ext_f(i32 noundef 7) #2, !dbg !39
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5), !dbg !40
  %out = call i32 @cqrt_alloc_i32(i32 0), !dbg !40
  %selop = call i32 @cqrt_alloc_i32(i32 %1), !dbg !40
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out), !dbg !40
  call void @cqrt_x(i32 %h_cmp), !dbg !40
  %selop1 = call i32 @cqrt_alloc_i32(i32 5), !dbg !40
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out), !dbg !40
  call void @cqrt_x(i32 %h_cmp), !dbg !40
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5), !dbg !40
  call void @cqrt_free(i32 %h_cmp), !dbg !40
    #dbg_value(i32 %out, !19, !DIExpression(), !38)
  %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %out, i32 50), !dbg !41
  call void @cqrt_rz_i1(i32 %h_cmp2, double 3.000000e-01), !dbg !42, !cq.branchphase !29
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp2, i32 %out, i32 50), !dbg !41
  call void @cqrt_free(i32 %h_cmp2), !dbg !42
  call void @cqrt_ry_i32(i32 %out, double 2.000000e-01), !dbg !43
    #dbg_value(i32 %out, !20, !DIExpression(), !38)
  %m = call i32 @cqrt_measure_i32(i32 %out), !dbg !44
  %m3 = call i32 @cqrt_measure_i32(i32 %h), !dbg !45
  %2 = add nsw i32 %m3, %m, !dbg !46
  ret i32 %2, !dbg !47
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #1 !dbg !48 {
    #dbg_value(i32 %0, !53, !DIExpression(), !54)
  %2 = add nsw i32 %0, 100, !dbg !55
  ret i32 %2, !dbg !56
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_rz_i1(i32, double)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.dbg.cu = !{!0, !2}
!llvm.ident = !{!4, !4}
!llvm.module.flags = !{!5, !6, !7, !8, !9, !10, !11}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!1 = !DIFile(filename: "w2i4_flat_2c.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "a71d2fcb38213b2ca5cba8fa5af81f47")
!2 = distinct !DICompileUnit(language: DW_LANG_C11, file: !3, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!3 = !DIFile(filename: "w2i2_lib.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "ef205ba37df11bbd7a40528f9ff9887c")
!4 = !{!"Homebrew clang version 19.1.7"}
!5 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!6 = !{i32 7, !"Dwarf Version", i32 5}
!7 = !{i32 2, !"Debug Info Version", i32 3}
!8 = !{i32 1, !"wchar_size", i32 4}
!9 = !{i32 8, !"PIC Level", i32 2}
!10 = !{i32 7, !"uwtable", i32 2}
!11 = !{i32 7, !"frame-pointer", i32 2}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 5, type: !14, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !17)
!13 = !DIFile(filename: "./w2i4_flat_2c.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "a71d2fcb38213b2ca5cba8fa5af81f47")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20}
!18 = !DILocalVariable(name: "q", scope: !12, file: !13, line: 6, type: !16)
!19 = !DILocalVariable(name: "y", scope: !12, file: !13, line: 7, type: !16)
!20 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 10, type: !16)
!21 = !DILocation(line: 6, column: 13, scope: !12)
!22 = !DILocation(line: 0, scope: !12)
!23 = !DILocation(line: 8, column: 20, scope: !24)
!24 = distinct !DILexicalBlock(scope: !12, file: !13, line: 8, column: 9)
!25 = !DILocation(line: 8, column: 11, scope: !24)
!26 = !DILocation(line: 9, column: 11, scope: !27)
!27 = distinct !DILexicalBlock(scope: !12, file: !13, line: 9, column: 9)
!28 = !DILocation(line: 9, column: 17, scope: !27)
!29 = !{}
!30 = !DILocation(line: 10, column: 13, scope: !12)
!31 = !DILocation(line: 11, column: 12, scope: !12)
!32 = !DILocation(line: 11, column: 28, scope: !12)
!33 = !DILocation(line: 11, column: 26, scope: !12)
!34 = !DILocation(line: 11, column: 5, scope: !12)
!35 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 13, type: !14, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!36 = !DILocation(line: 6, column: 13, scope: !12, inlinedAt: !37)
!37 = distinct !DILocation(line: 13, column: 25, scope: !35)
!38 = !DILocation(line: 0, scope: !12, inlinedAt: !37)
!39 = !DILocation(line: 8, column: 20, scope: !24, inlinedAt: !37)
!40 = !DILocation(line: 8, column: 11, scope: !24, inlinedAt: !37)
!41 = !DILocation(line: 9, column: 11, scope: !27, inlinedAt: !37)
!42 = !DILocation(line: 9, column: 17, scope: !27, inlinedAt: !37)
!43 = !DILocation(line: 10, column: 13, scope: !12, inlinedAt: !37)
!44 = !DILocation(line: 11, column: 12, scope: !12, inlinedAt: !37)
!45 = !DILocation(line: 11, column: 28, scope: !12, inlinedAt: !37)
!46 = !DILocation(line: 11, column: 26, scope: !12, inlinedAt: !37)
!47 = !DILocation(line: 13, column: 18, scope: !35)
!48 = distinct !DISubprogram(name: "ext_f", scope: !49, file: !49, line: 2, type: !50, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !52)
!49 = !DIFile(filename: "./w2i2_lib.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "ef205ba37df11bbd7a40528f9ff9887c")
!50 = !DISubroutineType(types: !51)
!51 = !{!16, !16}
!52 = !{!53}
!53 = !DILocalVariable(name: "a", arg: 1, scope: !48, file: !49, line: 2, type: !16)
!54 = !DILocation(line: 0, scope: !48)
!55 = !DILocation(line: 2, column: 29, scope: !48)
!56 = !DILocation(line: 2, column: 20, scope: !48)
