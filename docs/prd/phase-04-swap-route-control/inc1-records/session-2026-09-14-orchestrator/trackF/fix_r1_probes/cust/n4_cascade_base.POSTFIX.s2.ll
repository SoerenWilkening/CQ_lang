; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/fix_r1_probes/cust/n4_cascade_base.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/n4_cascade.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !15, !DIExpression(), !21)
    #dbg_value(i8 0, !16, !DIExpression(), !21)
    #dbg_value(i8 0, !18, !DIExpression(), !21)
    #dbg_value(i8 0, !19, !DIExpression(), !21)
    #dbg_value(i8 0, !20, !DIExpression(), !21)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !22
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
  %bf = call i32 @cqrt_alloc_i1(i1 false), !dbg !23
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !23
  %out = call i32 @cqrt_alloc_i32(i32 0), !dbg !23
  %selop = call i32 @cqrt_alloc_i32(i32 2), !dbg !23
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out), !dbg !23
  call void @cqrt_x(i32 %bf), !dbg !23
  %selop1 = call i32 @cqrt_alloc_i32(i32 5), !dbg !23
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out), !dbg !23
  call void @cqrt_x(i32 %bf), !dbg !23
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !23
  call void @cqrt_free(i32 %bf), !dbg !23
    #dbg_value(i32 %out, !15, !DIExpression(), !21)
  %h7 = call i32 @cqrt_alloc_i1(i1 false), !dbg !24
  call void @cqrt_ry_i1(i32 %h7, double 5.000000e-01), !dbg !24
  call void @cqrt_ry_i1_controlled(i32 %h, i32 %h7, double -5.000000e-01), !dbg !27
    #dbg_value(i8 poison, !18, !DIExpression(), !21)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %out, i32 -3)
  %bf5 = call i32 @cqrt_alloc_i1(i1 false), !dbg !28
  call void @cqrt_cnot(i32 %h7, i32 %bf5), !dbg !28
  %out6 = call i32 @cqrt_alloc_i32(i32 0), !dbg !28
  call void @cqrt_copy_i32_controlled(i32 %bf5, i32 %h_op, i32 %out6), !dbg !28
  call void @cqrt_x(i32 %bf5), !dbg !28
  call void @cqrt_copy_i32_controlled(i32 %bf5, i32 %out, i32 %out6), !dbg !28
  call void @cqrt_x(i32 %bf5), !dbg !28
  call void @cqrt_cnot(i32 %h7, i32 %bf5), !dbg !28
  call void @cqrt_free(i32 %bf5), !dbg !28
    #dbg_value(i32 %out6, !15, !DIExpression(), !21)
  %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %out6, i32 2), !dbg !29
  %h8 = call i32 @cqrt_alloc_i1(i1 false), !dbg !31
  call void @cqrt_ry_i1_controlled(i32 %h_cmp2, i32 %h8, double 5.000000e-01), !dbg !31
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp2, i32 %out6, i32 2), !dbg !29
  call void @cqrt_free(i32 %h_cmp2), !dbg !33
    #dbg_value(i8 poison, !19, !DIExpression(), !21)
  %h_op10 = call i32 @cq_template_add_i32_hl(i32 %out6, i32 -3)
  %bf3 = call i32 @cqrt_alloc_i1(i1 false), !dbg !34
  call void @cqrt_cnot(i32 %h8, i32 %bf3), !dbg !34
  %out4 = call i32 @cqrt_alloc_i32(i32 0), !dbg !34
  call void @cqrt_copy_i32_controlled(i32 %bf3, i32 %h_op10, i32 %out4), !dbg !34
  call void @cqrt_x(i32 %bf3), !dbg !34
  call void @cqrt_copy_i32_controlled(i32 %bf3, i32 %out6, i32 %out4), !dbg !34
  call void @cqrt_x(i32 %bf3), !dbg !34
  call void @cqrt_cnot(i32 %h8, i32 %bf3), !dbg !34
  call void @cqrt_free(i32 %bf3), !dbg !34
    #dbg_value(i32 %out4, !15, !DIExpression(), !21)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %out4, i32 2), !dbg !35
  %h9 = call i32 @cqrt_alloc_i1(i1 false), !dbg !37
  call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h9, double 5.000000e-01), !dbg !37
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %out4, i32 2), !dbg !35
  call void @cqrt_free(i32 %h_cmp), !dbg !39
    #dbg_value(i8 poison, !20, !DIExpression(), !21)
  %m = call i1 @cqrt_measure_i1(i32 %h), !dbg !40
  %1 = zext i1 %m to i32, !dbg !40
  %m11 = call i1 @cqrt_measure_i1(i32 %h7), !dbg !41
  %2 = zext i1 %m11 to i32, !dbg !41
  %3 = add nuw nsw i32 %2, %1, !dbg !42
  %m12 = call i1 @cqrt_measure_i1(i32 %h8), !dbg !43
  %4 = zext i1 %m12 to i32, !dbg !43
  %5 = add nuw nsw i32 %3, %4, !dbg !44
  %m13 = call i1 @cqrt_measure_i1(i32 %h9), !dbg !45
  %6 = zext i1 %m13 to i32, !dbg !45
  %7 = add nuw nsw i32 %5, %6, !dbg !46
  %m14 = call i32 @cqrt_measure_i32(i32 %out4), !dbg !47
  %8 = add nsw i32 %7, %m14, !dbg !48
  ret i32 %8, !dbg !49
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i1(i32, double)

declare void @cqrt_ry_i1_controlled(i32, i32, double)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i1 @cqrt_measure_i1(i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/n4_cascade.c", directory: "/Users/sorenwilkening/Desktop/CQ_f2phi", checksumkind: CSK_MD5, checksum: "0032d4df21244a83f2871f0253aa0467")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !19, !20}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 5, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "b1", scope: !10, file: !8, line: 5, type: !17)
!19 = !DILocalVariable(name: "b2", scope: !10, file: !8, line: 5, type: !17)
!20 = !DILocalVariable(name: "b3", scope: !10, file: !8, line: 5, type: !17)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 6, column: 10, scope: !10)
!23 = !DILocation(line: 7, column: 9, scope: !10)
!24 = !DILocation(line: 8, column: 24, scope: !25)
!25 = distinct !DILexicalBlock(scope: !26, file: !8, line: 8, column: 17)
!26 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 9)
!27 = !DILocation(line: 8, column: 9, scope: !10)
!28 = !DILocation(line: 9, column: 9, scope: !10)
!29 = !DILocation(line: 10, column: 11, scope: !30)
!30 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 9)
!31 = !DILocation(line: 10, column: 24, scope: !32)
!32 = distinct !DILexicalBlock(scope: !30, file: !8, line: 10, column: 17)
!33 = !DILocation(line: 10, column: 9, scope: !10)
!34 = !DILocation(line: 11, column: 9, scope: !10)
!35 = !DILocation(line: 12, column: 11, scope: !36)
!36 = distinct !DILexicalBlock(scope: !10, file: !8, line: 12, column: 9)
!37 = !DILocation(line: 12, column: 24, scope: !38)
!38 = distinct !DILexicalBlock(scope: !36, file: !8, line: 12, column: 17)
!39 = !DILocation(line: 12, column: 9, scope: !10)
!40 = !DILocation(line: 13, column: 12, scope: !10)
!41 = !DILocation(line: 13, column: 29, scope: !10)
!42 = !DILocation(line: 13, column: 27, scope: !10)
!43 = !DILocation(line: 13, column: 46, scope: !10)
!44 = !DILocation(line: 13, column: 44, scope: !10)
!45 = !DILocation(line: 13, column: 63, scope: !10)
!46 = !DILocation(line: 13, column: 61, scope: !10)
!47 = !DILocation(line: 13, column: 80, scope: !10)
!48 = !DILocation(line: 13, column: 78, scope: !10)
!49 = !DILocation(line: 13, column: 5, scope: !10)
