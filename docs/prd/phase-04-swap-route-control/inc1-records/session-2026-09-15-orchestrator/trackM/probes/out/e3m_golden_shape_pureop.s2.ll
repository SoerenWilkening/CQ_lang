; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/out/e3m_golden_shape_pureop.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3m_golden_shape_pureop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !18
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !18
    #dbg_value(i32 %h, !15, !DIExpression(), !19)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !20
    #dbg_value(i32 %m, !16, !DIExpression(), !19)
  %h_cmp = call i32 @cq_template_icmp_ne_i32_hl(i32 %h, i32 0), !dbg !21
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp), !dbg !21
    #dbg_value(i32 %h_cast, !17, !DIExpression(), !19)
  call void @cq_template_icmp_ne_i32_hl_unc(i32 %h_cmp, i32 %h, i32 0), !dbg !21
  call void @cqrt_free(i32 %h_cmp), !dbg !21
  call void @cqrt_addc_i32(i32 %h_cast, i32 %m), !dbg !22
  ret i32 %h_cast, !dbg !23
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_addc_i32(i32, i32)

declare i32 @cq_template_icmp_ne_i32_hl(i32, i32)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_icmp_ne_i32_hl_unc(i32, i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3m_golden_shape_pureop.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "c529b8f4ae94b22714bfc5bbc7d68b19")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "keep", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "x", scope: !10, file: !8, line: 4, type: !13)
!18 = !DILocation(line: 4, column: 23, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 4, column: 49, scope: !10)
!21 = !DILocation(line: 4, column: 72, scope: !10)
!22 = !DILocation(line: 4, column: 89, scope: !10)
!23 = !DILocation(line: 4, column: 78, scope: !10)
