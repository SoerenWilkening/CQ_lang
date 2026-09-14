; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/fix_r1_probes/cust/w3_runtime_a_base.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/w3_runtime_a.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !18, !DIExpression(), !25)
    #dbg_value(ptr %1, !19, !DIExpression(), !25)
    #dbg_value(i32 %0, !20, !DIExpression(DW_OP_plus_uconst, 4, DW_OP_stack_value), !25)
    #dbg_value(i8 0, !21, !DIExpression(), !25)
    #dbg_value(i8 0, !23, !DIExpression(), !25)
    #dbg_value(i8 0, !24, !DIExpression(), !25)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !26
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !26
    #dbg_value(i32 %h, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !25)
  %bf = call i32 @cqrt_alloc_i1(i1 false), !dbg !27
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !27
  %out = call i32 @cqrt_alloc_i32(i32 0), !dbg !27
  %selop = call i32 @cqrt_alloc_i32(i32 1), !dbg !27
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out), !dbg !27
  call void @cqrt_x(i32 %bf), !dbg !27
  %selop1 = call i32 @cqrt_alloc_i32(i32 4), !dbg !27
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out), !dbg !27
  call void @cqrt_x(i32 %bf), !dbg !27
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !27
  call void @cqrt_free(i32 %bf), !dbg !27
  %h_op = call i32 @cq_template_add_i32_hl(i32 %out, i32 %0), !dbg !27
    #dbg_value(i32 %h_op, !20, !DIExpression(), !25)
  %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h_op, i32 2), !dbg !28
  %h5 = call i32 @cqrt_alloc_i1(i1 false), !dbg !30
  call void @cqrt_ry_i1_controlled(i32 %h_cmp2, i32 %h5, double 5.000000e-01), !dbg !30
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp2, i32 %h_op, i32 2), !dbg !28
  call void @cqrt_free(i32 %h_cmp2), !dbg !32
    #dbg_value(i8 poison, !23, !DIExpression(), !25)
  %h_op7 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 -3)
  %bf3 = call i32 @cqrt_alloc_i1(i1 false), !dbg !33
  call void @cqrt_cnot(i32 %h5, i32 %bf3), !dbg !33
  %out4 = call i32 @cqrt_alloc_i32(i32 0), !dbg !33
  call void @cqrt_copy_i32_controlled(i32 %bf3, i32 %h_op7, i32 %out4), !dbg !33
  call void @cqrt_x(i32 %bf3), !dbg !33
  call void @cqrt_copy_i32_controlled(i32 %bf3, i32 %h_op, i32 %out4), !dbg !33
  call void @cqrt_x(i32 %bf3), !dbg !33
  call void @cqrt_cnot(i32 %h5, i32 %bf3), !dbg !33
  call void @cqrt_free(i32 %bf3), !dbg !33
    #dbg_value(i32 %out4, !20, !DIExpression(), !25)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %out4, i32 2), !dbg !34
  %h6 = call i32 @cqrt_alloc_i1(i1 false), !dbg !36
  call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h6, double 5.000000e-01), !dbg !36
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %out4, i32 2), !dbg !34
  call void @cqrt_free(i32 %h_cmp), !dbg !38
    #dbg_value(i8 poison, !24, !DIExpression(), !25)
  %m = call i1 @cqrt_measure_i1(i32 %h), !dbg !39
  %3 = zext i1 %m to i32, !dbg !39
  %m8 = call i1 @cqrt_measure_i1(i32 %h5), !dbg !40
  %4 = zext i1 %m8 to i32, !dbg !40
  %5 = add nuw nsw i32 %4, %3, !dbg !41
  %m9 = call i1 @cqrt_measure_i1(i32 %h6), !dbg !42
  %6 = zext i1 %m9 to i32, !dbg !42
  %7 = add nuw nsw i32 %5, %6, !dbg !43
  %m10 = call i32 @cqrt_measure_i32(i32 %out4), !dbg !44
  %8 = add nsw i32 %7, %m10, !dbg !45
  ret i32 %8, !dbg !46
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/w3_runtime_a.c", directory: "/Users/sorenwilkening/Desktop/CQ_f2phi", checksumkind: CSK_MD5, checksum: "eaba654824f53b9a8e143d34c6ecd121")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13, !14}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !16, size: 64)
!16 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!17 = !{!18, !19, !20, !21, !23, !24}
!18 = !DILocalVariable(name: "argc", arg: 1, scope: !10, file: !8, line: 6, type: !13)
!19 = !DILocalVariable(name: "argv", arg: 2, scope: !10, file: !8, line: 6, type: !14)
!20 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 8, type: !13)
!21 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 9, type: !22)
!22 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!23 = !DILocalVariable(name: "b1", scope: !10, file: !8, line: 9, type: !22)
!24 = !DILocalVariable(name: "b2", scope: !10, file: !8, line: 9, type: !22)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 10, column: 10, scope: !10)
!27 = !DILocation(line: 11, column: 9, scope: !10)
!28 = !DILocation(line: 12, column: 11, scope: !29)
!29 = distinct !DILexicalBlock(scope: !10, file: !8, line: 12, column: 9)
!30 = !DILocation(line: 12, column: 24, scope: !31)
!31 = distinct !DILexicalBlock(scope: !29, file: !8, line: 12, column: 17)
!32 = !DILocation(line: 12, column: 9, scope: !10)
!33 = !DILocation(line: 13, column: 9, scope: !10)
!34 = !DILocation(line: 14, column: 11, scope: !35)
!35 = distinct !DILexicalBlock(scope: !10, file: !8, line: 14, column: 9)
!36 = !DILocation(line: 14, column: 24, scope: !37)
!37 = distinct !DILexicalBlock(scope: !35, file: !8, line: 14, column: 17)
!38 = !DILocation(line: 14, column: 9, scope: !10)
!39 = !DILocation(line: 15, column: 12, scope: !10)
!40 = !DILocation(line: 15, column: 29, scope: !10)
!41 = !DILocation(line: 15, column: 27, scope: !10)
!42 = !DILocation(line: 15, column: 46, scope: !10)
!43 = !DILocation(line: 15, column: 44, scope: !10)
!44 = !DILocation(line: 15, column: 63, scope: !10)
!45 = !DILocation(line: 15, column: 61, scope: !10)
!46 = !DILocation(line: 15, column: 5, scope: !10)
